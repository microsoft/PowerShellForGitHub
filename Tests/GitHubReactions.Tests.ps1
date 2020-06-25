# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

<#
.Synopsis
   Tests for GitHubReactions.ps1 module
#>

# This is common test code setup logic for all Pester test files
$moduleRootPath = Split-Path -Path $PSScriptRoot -Parent
. (Join-Path -Path $moduleRootPath -ChildPath 'Tests\Common.ps1')

try
{
    # Define Script-scoped, readonly, hidden variables.
    @{
        defaultIssueTitle = "Test Title"
        defaultCommentBody = "This is a test body."
        defaultReactionType = "+1"
        otherReactionType = "eyes"
    }.GetEnumerator() | ForEach-Object {
        Set-Variable -Force -Scope Script -Option ReadOnly -Visibility Private -Name $_.Key -Value $_.Value
    }

    Describe 'Creating, modifying and deleting comments' {
        BeforeAll {
            $repo = New-GitHubRepository -RepositoryName ([Guid]::NewGuid().Guid) -AutoInit
            $issue = New-GitHubIssue -Uri $repo.svn_url -Title $defaultIssueTitle
            $issueComment = $issue | New-GitHubIssueComment -Body "Foo"

            # To get rid of linting issue saying this variable isn't used.
            $issueComment.CommentId
        }

        Context 'For creating a reaction' {
            Set-GitHubReaction -Uri $repo.svn_url -Issue $issue.IssueNumber -ReactionType $defaultReactionType
            $existingReaction = Get-GitHubReaction -Uri $repo.svn_url -Issue $issue.IssueNumber

            It "Should have the expected reaction type" {
                $existingReaction.content | Should -Be $defaultReactionType
            }
        }

        Context 'For getting reactions from an issue' {
            Get-GitHubIssue -Uri $repo.svn_url -Issue $issue.IssueNumber | Set-GitHubReaction -ReactionType $otherReactionType
            $allReactions = Get-GitHubReaction -Uri $repo.svn_url -Issue $issue.IssueNumber
            $specificReactions = Get-GitHubReaction -Uri $repo.svn_url -Issue $issue.IssueNumber -ReactionType $otherReactionType

            It 'Should have the expected number of reactions' {
                $allReactions.Count | Should -Be 2
                $specificReactions.Count | Should -Be 1
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
            # TODO: there are currently PRs out to add the ability to create new branches and add content to a repo.
            # When those go in, this test can be refactored to use those so the test is more reliable using a test PR.
            $url = 'https://github.com/microsoft/PowerShellForGitHub'
            $pr = Get-GitHubPullRequest -Uri $url -PullRequest 193
            $pr | Get-GitHubReaction | Remove-GitHubReaction -ErrorAction Ignore -Confirm:$false

            $reaction1 = $pr | Set-GitHubReaction -ReactionType $defaultReactionType
            $reaction2 = $pr | Set-GitHubReaction -ReactionType $otherReactionType

            try {
                $allReactions = $pr | Get-GitHubReaction
                $specificReactions = $pr | Get-GitHubReaction -ReactionType $otherReactionType

                It 'Should have the expected number of reactions' {
                    $allReactions.Count | Should -Be 2
                    $specificReactions.Count | Should -Be 1
                }

                It 'Should have the expected reaction content' {
                    $specificReactions.content | Should -Be $otherReactionType
                    $specificReactions.RepositoryUrl | Should -Be $url
                    $specificReactions.PullRequestNumber | Should -Be $pr.PullRequestNumber
                    $specificReactions.ReactionId | Should -Be $specificReactions.id
                    $specificReactions.PSObject.TypeNames[0] | Should -Be 'GitHub.Reaction'
                }
            } finally {
                $reaction1 | Remove-GitHubReaction -Force
                $reaction2 | Remove-GitHubReaction -Force
            }
        }

        Context 'For getting reactions from an issue comment' {
            Set-GitHubReaction -Uri $repo.svn_url -Comment $issueComment.CommentId -ReactionType $defaultReactionType
            $issueComment | Set-GitHubReaction -ReactionType $otherReactionType
            $allReactions = Get-GitHubReaction -Uri $repo.svn_url -Comment $issueComment.CommentId
            $specificReactions = Get-GitHubReaction -Uri $repo.svn_url -Comment $issueComment.CommentId -ReactionType $otherReactionType

            It 'Should have the expected number of reactions' {
                $allReactions.Count | Should -Be 2
                $specificReactions.Count | Should -Be 1
            }

            It 'Should have the expected reaction content' {
                $specificReactions.content | Should -Be $otherReactionType
                $specificReactions.RepositoryUrl | Should -Be $repo.RepositoryUrl
                $specificReactions.CommentId | Should -Be $issueComment.CommentId
                $specificReactions.ReactionId | Should -Be $specificReactions.id
                $specificReactions.PSObject.TypeNames[0] | Should -Be 'GitHub.Reaction'
            }
        }

        Context 'For getting reactions from an Issue and deleting them' {
            $existingReactions = @(Get-GitHubReaction -Uri $repo.svn_url -Issue $issue.number)

            It 'Should have the expected number of reactions' {
                $existingReactions.Count | Should -Be 2
            }

            $existingReactions | Remove-GitHubReaction -Force

            $existingReactions = @(Get-GitHubReaction -Uri $repo.svn_url -Issue $issue.number)

            It 'Should have no reactions' {
                $existingReactions
                $existingReactions.Count | Should -Be 0
            }
        }

        AfterAll {
            Remove-GitHubRepository -Uri $repo.svn_url -Confirm:$false
        }
    }
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
