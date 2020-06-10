# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

<#
.Synopsis
   Tests for GitHubComments.ps1 module
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
    # Define Script-scoped, readonly, hidden variables.
    @{
        defaultIssueTitle = "Test Title"
        defaultCommentBody = "This is a test body."
        defaultEditedCommentBody = "This is an edited test body."
    }.GetEnumerator() | ForEach-Object {
        Set-Variable -Force -Scope Script -Option ReadOnly -Visibility Private -Name $_.Key -Value $_.Value
    }

    Describe 'Creating, modifying and deleting comments' {
        $repo = New-GitHubRepository -RepositoryName ([Guid]::NewGuid().Guid) -AutoInit

        $issue = New-GitHubIssue -Uri $repo.svn_url -Title $defaultIssueTitle

        Context 'For creating a new comment' {
            $newComment = New-GitHubComment -Uri $repo.svn_url -Issue $issue.number -Body $defaultCommentBody
            $existingComment = Get-GitHubComment -Uri $repo.svn_url -CommentID $newComment.id

            It "Should have the expected body text" {
                $existingComment.body | Should -Be $defaultCommentBody
            }
        }

        Context 'For getting comments from an issue' {
            $existingComments = @(Get-GitHubComment -Uri $repo.svn_url -Issue $issue.number)

            It 'Should have the expected number of comments' {
                $existingComments.Count | Should -Be 1
            }

            It 'Should have the expected body text on the first comment' {
                $existingComments[0].body | Should -Be $defaultCommentBody
            }
        }

        Context 'For getting comments from an issue with a specific MediaType' {
            $existingComments = @(Get-GitHubComment -Uri $repo.svn_url -Issue $issue.number -MediaType 'Html')

            It 'Should have the expected body_html on the first comment' {
                $existingComments[0].body_html | Should -Not -Be $null
            }
        }

        Context 'For editing a comment' {
            $newComment = New-GitHubComment -Uri $repo.svn_url -Issue $issue.number -Body $defaultCommentBody
            $editedComment = Set-GitHubComment -Uri $repo.svn_url -CommentID $newComment.id -Body $defaultEditedCommentBody

            It 'Should have a body that is not equal to the original body' {
                $editedComment.body | Should -Not -Be $newComment.Body
            }

            It 'Should have the edited content' {
                $editedComment.body | Should -Be $defaultEditedCommentBody
            }
        }

        Context 'For getting comments from a repository and deleting them' {
            $existingComments = @(Get-GitHubComment -Uri $repo.svn_url)

            It 'Should have the expected number of comments' {
                $existingComments.Count | Should -Be 2
            }

            foreach($comment in $existingComments) {
                Remove-GitHubComment -Uri $repo.svn_url -CommentID $comment.id -Confirm:$false
            }

            $existingComments = @(Get-GitHubComment -Uri $repo.svn_url)

            It 'Should have no comments' {
                $existingComments.Count | Should -Be 0
            }
        }

        Remove-GitHubRepository -Uri $repo.svn_url -Confirm:$false
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
