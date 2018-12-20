# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

<#
.Synopsis
   Tests for GitHubMilestones.ps1 module
#>

$root = Split-Path -Parent $PSScriptRoot
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

    # Define Script-scoped, readonly, hidden variables.

    @{
        defaultIssueTitle = "This is a test issue."
        defaultMilestoneTitle1 = "This is a test milestone title #1."
        defaultMilestoneTitle2 = "This is a test milestone title #2."
        defaultEditedMilestoneTitle = "This is an edited milestone title."
        defaultMilestoneDescription = "This is a test milestone description."
        defaultEditedMilestoneDescription = "This is an edited milestone description."
        defaultMilestoneDueOn = (Get-Date).AddYears(1).ToUniversalTime()
    }.GetEnumerator() | ForEach-Object {
        Set-Variable -Force -Scope Script -Option ReadOnly -Visibility Private -Name $_.Key -Value $_.Value
    }

    Describe 'Creating, modifying and deleting milestones' {
        $repo = New-GitHubRepository -RepositoryName ([Guid]::NewGuid().Guid) -AutoInit
        $issue = New-GitHubIssue -Uri $repo.svn_url -Title $defaultIssueTitle

        Context 'For creating a new milestone' {
            $newMilestone = New-GitHubMilestone -Uri $repo.svn_url -Title $defaultMilestoneTitle1 -State "Closed" -DueOn $defaultMilestoneDueOn
            $existingMilestone = Get-GitHubMilestone -Uri $repo.svn_url -Milestone $newMilestone.number

            It "Should have the expected title text" {
                $existingMilestone.title | Should be $defaultMilestoneTitle1
            }

            It "Should have the expected state" {
                $existingMilestone.state | Should be "closed"
            }

            It "Should have the expected due_on date" {
                Get-Date -Date $existingMilestone.due_on | Should be $defaultMilestoneDueOn.Date
            }

            It "Should allow the addition of an existing issue" {
                Update-GitHubIssue -Uri $repo.svn_url -Issue $issue.number -Milestone $existingMilestone.number
            }
        }

        Context 'For getting milestones from a repo' {
            $existingMilestones = @(Get-GitHubMilestone -Uri $repo.svn_url -State "Closed")
            $issue = Get-GitHubIssue -Uri $repo.svn_url -Issue $issue.number

            It 'Should have the expected number of milestones' {
                $existingMilestones.Count | Should be 1
            }

            It 'Should have the expected title text on the first milestone' {
                $existingMilestones[0].title | Should be $defaultMilestoneTitle1
            }

            It 'Should have the expected issue in the first milestone' {
                $existingMilestones[0].open_issues | should be 1
                $issue.milestone.number | Should be 1
            }
        }

        Context 'For editing a milestone' {
            $newMilestone = New-GitHubMilestone -Uri $repo.svn_url -Title $defaultMilestoneTitle2 -Description $defaultMilestoneDescription
            $editedMilestone = Set-GitHubMilestone -Uri $repo.svn_url -Milestone $newMilestone.number -Title $defaultEditedMilestoneTitle -Description $defaultEditedMilestoneDescription

            It 'Should have a title/description that is not equal to the original title/description' {
                $editedMilestone.title | Should not be $newMilestone.title
                $editedMilestone.description | Should not be $newMilestone.description
            }

            It 'Should have the edited content' {
                $editedMilestone.title | Should be $defaultEditedMilestoneTitle
                $editedMilestone.description | Should be $defaultEditedMilestoneDescription
            }
        }

        Context 'For getting milestones from a repository and deleting them' {
            $existingMilestones = @(Get-GitHubMilestone -Uri $repo.svn_url -State "All" -Sort "Completeness" -Direction "Descending")

            It 'Should have the expected number of milestones' {
                $existingMilestones.Count | Should be 2
            }

            foreach($milestone in $existingMilestones) {
                Remove-GitHubMilestone -Uri $repo.svn_url -Milestone $milestone.number
            }

            $existingMilestones = @(Get-GitHubMilestone -Uri $repo.svn_url)
            $issue = Get-GitHubIssue -Uri $repo.svn_url -Issue $issue.number

            It 'Should have no milestones' {
                $existingMilestones.Count | Should be 0
                $issue.milestone | Should be $null
            }
        }

        Remove-GitHubRepository -Uri $repo.svn_url
    }
}
finally
{
    # Restore the user's configuration to its pre-test state
    Restore-GitHubConfiguration -Path $configFile
}