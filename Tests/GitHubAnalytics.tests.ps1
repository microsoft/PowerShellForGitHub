# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

<#
.Synopsis
   Tests for GitHubAnalytics.ps1 module
#>

[CmdletBinding()]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '',
    Justification='Suppress false positives in Pester code blocks')]
param()

# This is common test code setup logic for all Pester test files
$moduleRootPath = Split-Path -Path $PSScriptRoot -Parent
. (Join-Path -Path $moduleRootPath -ChildPath 'Tests\Common.ps1')

try
{
    # TODO: Re-enable these tests once the module has sufficient support getting the repository into the
    # required state for testing, and to recover back to the original state at the conclusion of the test.

    # Describe 'Obtaining pull requests for repository' {
    #     Context 'When no additional conditions specified' {
    #         $pullRequests = Get-GitHubPullRequest -Uri $script:repositoryUrl

    #         It 'Should return expected number of PRs' {
    #             @($pullRequests).Count | Should -Be 2
    #         }
    #     }

    #     Context 'When state and time range specified' {
    #         $mergedStartDate = Get-Date -Date '2016-04-10'
    #         $mergedEndDate = Get-Date -Date '2016-05-07'
    #         $pullRequests = Get-GitHubPullRequest -Uri $script:repositoryUrl -State Closed |
    #             Where-Object { ($_.merged_at -ge $mergedStartDate) -and ($_.merged_at -le $mergedEndDate) }

    #         It 'Should return expected number of PRs' {
    #             @($pullRequests).Count | Should -Be 3
    #         }
    #     }
    # }

    # Describe 'Obtaining repository with biggest number of pull requests' {
    #     Context 'When no additional conditions specified' {
    #         @($script:repositoryUrl, $script:repositoryUrl2) |
    #             ForEach-Object {
    #                 $pullRequestCounts += ([PSCustomObject]@{
    #                     'Uri' = $_;
    #                     'Count' = (Get-GitHubPullRequest -Uri $_).Count }) }
    #         $pullRequestCounts = $pullRequestCounts | Sort-Object -Property Count -Descending

    #         It 'Should return expected number of pull requests for each repository' {
    #             @($pullRequestCounts[0].Count) | Should -Be 2
    #             @($pullRequestCounts[1].Count) | Should -Be 0
    #         }

    #         It 'Should return expected repository names' {
    #             @($pullRequestCounts[0].Uri) | Should -Be $script:repositoryUrl
    #             @($pullRequestCounts[1].Uri) | Should -Be $script:repositoryUrl2
    #         }
    #     }

    #     Context 'When state and time range specified' {
    #         $mergedDate = Get-Date -Date '2015-04-20'
    #         $repos = @($script:repositoryUrl, $script:repositoryUrl2)
    #         $pullRequestCounts = @()
    #         $pullRequestSearchParams = @{
    #             'State' = 'closed'
    #         }
    #         $repos |
    #             ForEach-Object {
    #                 $pullRequestCounts += ([PSCustomObject]@{
    #                     'Uri' = $_;
    #                     'Count' = (
    #                         (Get-GitHubPullRequest -Uri $_ @pullRequestSearchParams) |
    #                             Where-Object { $_.merged_at -ge $mergedDate }
    #                     ).Count
    #                 }) }

    #         $pullRequestCounts = $pullRequestCounts | Sort-Object -Property Count -Descending
    #         $pullRequests = Get-GitHubTopPullRequestRepository -Uri @($script:repositoryUrl, $script:repositoryUrl2) -State Closed -MergedOnOrAfter

    #         It 'Should return expected number of pull requests for each repository' {
    #             @($pullRequests[0].Count) | Should -Be 3
    #             @($pullRequests[1].Count) | Should -Be 0
    #         }

    #         It 'Should return expected repository names' {
    #             @($pullRequests[0].Uri) | Should -Be $script:repositoryUrl
    #             @($pullRequests[1].Uri) | Should -Be $script:repositoryUrl2
    #         }
    #     }
    # }

    # TODO: Re-enable these tests once the module has sufficient support getting the Organization
    # and repository into the required state for testing, and to recover back to the original state
    # at the conclusion of the test.

    # Describe 'Obtaining organization members' {
    #     $members = Get-GitHubOrganizationMember -OrganizationName $script:organizationName

    #     It 'Should return expected number of organization members' {
    #         @($members).Count | Should -Be 1
    #     }
    # }

    # Describe 'Obtaining organization teams' {
    #     $teams = Get-GitHubTeam -OrganizationName $script:organizationName

    #     It 'Should return expected number of organization teams' {
    #         @($teams).Count | Should -Be 2
    #     }
    # }

    # Describe 'Obtaining organization team members' {
    #     $members = Get-GitHubTeamMember -OrganizationName $script:organizationName -TeamName $script:organizationTeamName

    #     It 'Should return expected number of organization team members' {
    #         @($members).Count | Should -Be 1
    #     }
    # }
}
finally
{
    if (Test-Path -Path $script:originalConfigFile -PathType Leaf)
    {
        # Restore the user's configuration to its pre-test state
        Restore-GitHubConfiguration -Path $script:originalConfigFile
        $script:originalConfigFile = $null
    }
}
