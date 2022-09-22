# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

<#
.Synopsis
   Tests for GitHubPullRequests.ps1 module
#>

[CmdletBinding()]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '',
    Justification = 'Suppress false positives in Pester code blocks')]
param()

BeforeAll {
    # This is common test code setup logic for all Pester test files
    $moduleRootPath = Split-Path -Path $PSScriptRoot -Parent
    . (Join-Path -Path $moduleRootPath -ChildPath 'Tests\Common.ps1')
}

Describe 'Getting pull request from repository' {
    BeforeAll {
        $repo = Get-GitHubRepository -OwnerName 'microsoft' -RepositoryName 'PowerShellForGitHub'
    }

    Context 'When getting a pull request' {
        BeforeAll {
            $pullRequestNumber = 39
            $pullRequest = Get-GitHubPullRequest -OwnerName 'microsoft' -RepositoryName 'PowerShellForGitHub' -PullRequest $pullRequestNumber
        }

        It 'Should be the expected pull request' {
            $pullRequest.number | Should -Be $pullRequestNumber
        }

        It 'Should have the expected type and additional properties' {
            $elements = Split-GitHubUri -Uri $pullRequest.html_url
            $repositoryUrl = Join-GitHubUri @elements

            $pullRequest.PSObject.TypeNames[0] | Should -Be 'GitHub.PullRequest'
            $pullRequest.RepositoryUrl | Should -Be $repo.RepositoryUrl
            $pullRequest.PullRequestId | Should -Be $pullRequest.id
            $pullRequest.PullRequestNumber | Should -Be $pullRequest.number
            $pullRequest.user.PSObject.TypeNames[0] | Should -Be 'GitHub.User'
            $pullRequest.labels[0].PSObject.TypeNames[0] | Should -Be 'GitHub.Label'
            $pullRequest.assignee.PSObject.TypeNames[0] | Should -Be 'GitHub.User'
            $pullRequest.assignees[0].PSObject.TypeNames[0] | Should -Be 'GitHub.User'
            $pullRequest.requested_teams[0].PSObject.TypeNames[0] | Should -Be 'GitHub.Team'
            $pullRequest.merged_by.PSObject.TypeNames[0] | Should -Be 'GitHub.User'
        }

        It 'Should be refreshable via the pipeline' {
            $refresh = $pullRequest | Get-GitHubPullRequest
            $refresh.PullRequestNumber | Should -Be $pullRequest.PullRequestNumber
        }

        It 'Should be retrievable by passing the repo on the pipeline' {
            $pullRequest = $repo | Get-GitHubPullRequest -PullRequest $pullRequestNumber
            $pullRequest.number | Should -Be $pullRequestNumber
        }

        It 'Should fail when it the pull request does not exist' {
            { $repo | Get-GitHubPullRequest -PullRequest 1 } | Should -Throw
        }
    }
}

Describe 'Getting multiple pull requests from repository' {
    BeforeAll {
        $ownerName = 'microsoft'
        $repositoryName = 'PowerShellForGitHub'
    }

    Context 'All closed' {
        BeforeAll {
            $pullRequests = @(Get-GitHubPullRequest -OwnerName $ownerName -RepositoryName $repositoryName -State 'Closed')
        }

        It 'Should return expected number of PRs' {
            $pullRequests.Count | Should -BeGreaterOrEqual 140
        }
    }
}

AfterAll {
    if (Test-Path -Path $script:originalConfigFile -PathType Leaf)
    {
        # Restore the user's configuration to its pre-test state
        Restore-GitHubConfiguration -Path $script:originalConfigFile
        $script:originalConfigFile = $null
    }
}
