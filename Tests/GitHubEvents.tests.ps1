# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

<#
.Synopsis
   Tests for GitHubEvents.ps1 module
#>

[String] $root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
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

        We call this immediately after the declaration so that AppVeyor initialization can heppen
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

$accessTokenConfigured = Test-GitHubAuthenticationConfigured
if (-not $accessTokenConfigured)
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

    if ($accessTokenConfigured)
    {
        Describe 'Getting events from repository' {
            $repositoryName = [Guid]::NewGuid()
            $null = New-GitHubRepository -RepositoryName $repositoryName

            Context 'For getting events from a new repository' {
                $events = @(Get-GitHubEvent -OwnerName $ownerName -RepositoryName $repositoryName)

                It 'Should have no events' {
                    $events.Count | Should be 0
                }
            }

            $issue = New-GithubIssue -OwnerName $ownerName -RepositoryName $repositoryName -Title "New Issue"
            Update-GitHubIssue -OwnerName $ownerName -RepositoryName $repositoryName -Issue $issue.number -State closed

            Context 'For getting events from a repository' {
                $events = @(Get-GitHubEvent -OwnerName $ownerName -RepositoryName $repositoryName)

                It 'Should have an event from closing an issue' {
                    $events.Count | Should be 1
                }
            }

            $null = Remove-GitHubRepository -OwnerName $ownerName -RepositoryName $repositoryName
        }

        Describe 'Getting events from an issue' {
            $repositoryName = [Guid]::NewGuid()
            $null = New-GitHubRepository -RepositoryName $repositoryName
            $issue = New-GithubIssue -OwnerName $ownerName -RepositoryName $repositoryName -Title "New Issue"

            Context 'For getting events from a new issue' {
                $events = @(Get-GitHubEvent -OwnerName $ownerName -RepositoryName $repositoryName -Issue $issue.number)

                It 'Should have no events' {
                    $events.Count | Should be 0
                }
            }

            Context 'For getting events from an issue' {
                Update-GitHubIssue -OwnerName $ownerName -RepositoryName $repositoryName -Issue $issue.number -State closed
                Update-GitHubIssue -OwnerName $ownerName -RepositoryName $repositoryName -Issue $issue.number -State open
                $events = @(Get-GitHubEvent -OwnerName $ownerName -RepositoryName $repositoryName)

                It 'Should have two events from closing and opening the issue' {
                    $events.Count | Should be 2
                }
            }

            $null = Remove-GitHubRepository -OwnerName $ownerName -RepositoryName $repositoryName
        }

        Describe 'Getting an event directly' {
            $repositoryName = [Guid]::NewGuid()
            $null = New-GitHubRepository -RepositoryName $repositoryName
            $issue = New-GithubIssue -OwnerName $ownerName -RepositoryName $repositoryName -Title "New Issue"
            Update-GitHubIssue -OwnerName $ownerName -RepositoryName $repositoryName -Issue $issue.number -State closed
            Update-GitHubIssue -OwnerName $ownerName -RepositoryName $repositoryName -Issue $issue.number -State open
            $events = @(Get-GitHubEvent -OwnerName $ownerName -RepositoryName $repositoryName)

            Context 'For getting an event directly'{
                $singleEvent = Get-GitHubEvent -OwnerName $ownerName -RepositoryName $repositoryName -EventID $events[0].id
                
                It 'Should have the correct event type'{
                    $singleEvent.event | Should be 'reopened'
                }
            }

            $null = Remove-GitHubRepository -OwnerName $ownerName -RepositoryName $repositoryName
        }
    }
}
catch
{
    # Restore the user's configuration to its pre-test state
    Restore-GitHubConfiguration -Path $configFile
}

