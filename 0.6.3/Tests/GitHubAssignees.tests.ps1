# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

<#
.Synopsis
   Tests for GitHubAssignees.ps1 module
#>

[String] $root = Split-Path -Parent (Split-Path -Parent $Script:MyInvocation.MyCommand.Path)
. (Join-Path -Path $root -ChildPath 'Tests\Config\Settings.ps1')
Import-Module -Name $root -Force

function Initialize-AppVeyor
{
<#
    .SYNOPSIS
        Configures the tests to run with the authentication information stored in AppVeyor
        (if that information exists in the environment).

    .DESCRIPTION
        Configures the tests to run with the authentication information stored in AppVeyor
        (if that information exists in the environment).

        The Git repo for this module can be found here: http://aka.ms/PowerShellForGitHub

    .NOTES
        Internal-only helper method.

        The only reason this exists is so that we can leverage CodeAnalysis.SuppressMessageAttribute,
        which can only be applied to functions.

        We call this immediately after the declaration so that AppVeyor initialization can happen
        (if applicable).

#>
    [CmdletBinding()]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingConvertToSecureStringWithPlainText", "", Justification="Needed to configure with the stored, encrypted string value in AppVeyor.")]
    param()

    if ($env:AppVeyor)
    {
        $secureString = $env:avAccessToken | ConvertTo-SecureString -AsPlainText -Force
        $cred = New-Object System.Management.Automation.PSCredential "<username is ignored>", $secureString
        Set-GitHubAuthentication -Credential $cred

        $script:ownerName = $env:avOwnerName
        $script:organizationName = $env:avOrganizationName

        $message = @(
            'This run is executed in the AppVeyor environment.',
            'The GitHub Api Token won''t be decrypted in PR runs causing some tests to fail.',
            '403 errors possible due to GitHub hourly limit for unauthenticated queries.',
            'Use Set-GitHubAuthentication manually. modify the values in Tests\Config\Settings.ps1,',
            'and run tests on your machine first.')
        Write-Warning -Message ($message -join [Environment]::NewLine)
    }
}

Initialize-AppVeyor

$script:accessTokenConfigured = Test-GitHubAuthenticationConfigured
if (-not $script:accessTokenConfigured)
{
    $message = @(
        'GitHub API Token not defined, some of the tests will be skipped.',
        '403 errors possible due to GitHub hourly limit for unauthenticated queries.')
    Write-Warning -Message ($message -join [Environment]::NewLine)
}

# Backup the user's configuration before we begin, and ensure we're at a pure state before running
# the tests.  We'll restore it at the end.
$configFile = New-TemporaryFile

try
{
    Backup-GitHubConfiguration -Path $configFile
    Reset-GitHubConfiguration
    Set-GitHubConfiguration -DisableTelemetry # We don't want UT's to impact telemetry
    Set-GitHubConfiguration -LogRequestBody # Make it easier to debug UT failures

    $repo = New-GitHubRepository -RepositoryName ([Guid]::NewGuid().Guid) -AutoInit
    $issue = New-GitHubIssue -Uri $repo.svn_url -Title "Test issue"

    Describe 'Getting a valid assignee' {

        Context 'For getting a valid assignee' {
            $assigneeList = @(Get-GitHubAssignee -Uri $repo.svn_url)

            It 'Should have returned the one assignee' {
                $assigneeList.Count | Should be 1
            }

            $assigneeUserName = $assigneeList[0].login

            It 'Should have returned an assignee with a login'{
                $assigneeUserName | Should not be $null
            }

            $hasPermission = Test-GitHubAssignee -Uri $repo.svn_url -Assignee $assigneeUserName

            It 'Should have returned an assignee with permission to be assigned to an issue'{
                $hasPermission | Should be $true
            }

        }
    }

    Describe 'Adding and removing an assignee to an issue'{

        Context 'For adding an assignee to an issue'{
            $assigneeList = @(Get-GitHubAssignee -Uri $repo.svn_url)
            $assigneeUserName = $assigneeList[0].login
            $assignees = @($assigneeUserName)
            New-GithubAssignee -Uri $repo.svn_url -Issue $issue.number -Assignee $assignees
            $issue = Get-GitHubIssue -Uri $repo.svn_url -Issue $issue.number

            It 'Should have assigned the user to the issue' {
                $issue.assignee.login | Should be $assigneeUserName
            }

            Remove-GithubAssignee -Uri $repo.svn_url -Issue $issue.number -Assignee $assignees
            $issue = Get-GitHubIssue -Uri $repo.svn_url -Issue $issue.number

            It 'Should have removed the user from issue' {
                $issue.assignees.Count | Should be 0
            }
        }
    }

    Remove-GitHubRepository -Uri $repo.svn_url
}
finally
{
    # Restore the user's configuration to its pre-test state
    Restore-GitHubConfiguration -Path $configFile
}
