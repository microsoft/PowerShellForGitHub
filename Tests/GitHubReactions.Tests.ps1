# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

<#
.Synopsis
   Tests for GitHubReactions.ps1 module
#>

[CmdletBinding()]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '',
    Justification = 'Suppress false positives in Pester code blocks')]
param()

BeforeAll {
    # This is common test code setup logic for all Pester test files
    $moduleRootPath = Split-Path -Path $PSScriptRoot -Parent
    . (Join-Path -Path $moduleRootPath -ChildPath 'Tests\Common.ps1')

    # Define Script-scoped, readonly, hidden variables.
    @{
        defaultIssueTitle = "Test Title"
        defaultCommentBody = "This is a test body."
        defaultReactionType = "+1"
        otherReactionType = "eyes"
    }.GetEnumerator() | ForEach-Object {
        Set-Variable -Force -Scope Script -Option ReadOnly -Visibility Private -Name $_.Key -Value $_.Value
    }
}

Describe 'Creating, modifying and deleting reactions' {
    BeforeAll {
        $repo = New-GitHubRepository -RepositoryName ([Guid]::NewGuid().Guid) -AutoInit
        $issue = New-GitHubIssue -Uri $repo.svn_url -Title $defaultIssueTitle
        $issueComment = $issue | New-GitHubIssueComment -Body "Foo"
    }

    Context 'For creating a reaction' {
        It "Should have the expected reaction type" {
            Set-GitHubReaction -Uri $repo.svn_url -Issue $issue.IssueNumber -ReactionType $defaultReactionType
            $existingReaction = Get-GitHubReaction -Uri $repo.svn_url -Issue $issue.IssueNumber

            $existingReaction.content | Should -Be $defaultReactionType
        }
    }

    Context 'For getting reactions from an issue' {
        BeforeAll {
            Get-GitHubIssue -Uri $repo.svn_url -Issue $issue.IssueNumber | Set-GitHubReaction -ReactionType $otherReactionType
            $allReactions = Get-GitHubReaction -Uri $repo.svn_url -Issue $issue.IssueNumber
            $specificReactions = Get-GitHubReaction -Uri $repo.svn_url -Issue $issue.IssueNumber -ReactionType $otherReactionType
        }

        It 'Should have the expected number of reactions' {
            $allReactions.Count | Should -Be 2
            $specificReactions | Measure-Object | Select-Object -ExpandProperty Count | Should -Be 1
        }

        It 'Should have the expected reaction content' {
            $specificReactions.content | Should -Be $otherReactionType
            $specificReactions.RepositoryUrl | Should -Be $repo.RepositoryUrl
            $specificReactions.IssueNumber | Should -Be $issue.IssueNumber
            $specificReactions.ReactionId | Should -Be $specificReactions.id
            $specificReactions.PSObject.TypeNames[0] | Should -Be 'GitHub.Reaction'
        }
    }

    Context 'For getting reactions from a pull request' {
        BeforeAll {
            # TODO: there are currently PRs out to add the ability to create new branches and add content to a repo.
            # When those go in, this test can be refactored to use those so the test is more reliable using a test PR.
            $url = 'https://github.com/microsoft/PowerShellForGitHub'
            $pr = Get-GitHubPullRequest -Uri $url -PullRequest 193

            $allReactions = $pr | Get-GitHubReaction
            $specificReactions = $pr | Get-GitHubReaction -ReactionType $otherReactionType
        }

        It 'Should have the expected number of reactions' {
            $allReactions.Count | Should -Be 2
            $specificReactions | Measure-Object | Select-Object -ExpandProperty Count | Should -Be 1
        }

        It 'Should have the expected reaction content' {
            $specificReactions.content | Should -Be $otherReactionType
            $specificReactions.RepositoryUrl | Should -Be $url
            $specificReactions.PullRequestNumber | Should -Be $pr.PullRequestNumber
            $specificReactions.ReactionId | Should -Be $specificReactions.id
            $specificReactions.PSObject.TypeNames[0] | Should -Be 'GitHub.Reaction'
        }
    }

    Context 'For getting reactions from an Issue and deleting them' {
        BeforeAll {
            $existingReactions = @(Get-GitHubReaction -Uri $repo.svn_url -Issue $issue.number)
        }

        It 'Should have the expected number of reactions' {
            $existingReactions.Count | Should -Be 2
        }

        It 'Should have no reactions' {
            $existingReactions | Remove-GitHubReaction -Force

            $existingReactions = @(Get-GitHubReaction -Uri $repo.svn_url -Issue $issue.number)

            $existingReactions
            $existingReactions.Count | Should -Be 0
        }
    }

    AfterAll {
        Remove-GitHubRepository -Uri $repo.svn_url -Confirm:$false
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
