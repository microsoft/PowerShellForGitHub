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
        BeforeAll {
            $repo = New-GitHubRepository -RepositoryName ([Guid]::NewGuid().Guid) -AutoInit
            $issue = $repo | New-GitHubIssue -Title $defaultIssueTitle
        }

        AfterAll {
            $repo | Remove-GitHubRepository -Confirm:$false
        }

        Context 'With parameters' {
            $comment = New-GitHubIssueComment -OwnerName $script:ownerName -RepositoryName $repo.name -Issue $issue.number -Body $defaultCommentBody
            It 'Should have the expected body text' {
                $comment.body | Should -Be $defaultCommentBody
            }

            It 'Should have the expected type and additional properties' {
                $comment.PSObject.TypeNames[0] | Should -Be 'GitHub.IssueComment'
                $comment.PSObject.TypeNames[1] | Should -Be 'GitHub.Comment'
                $comment.RepositoryUrl | Should -Be $repo.RepositoryUrl
                $comment.CommentId | Should -Be $comment.id
                $comment.user.PSObject.TypeNames[0] | Should -Be 'GitHub.User'
            }

            $result = Get-GitHubIssueComment -OwnerName $script:ownerName -RepositoryName $repo.name -Comment $comment.id
            It 'Should be the expected comment' {
                $result.id | Should -Be $comment.id
            }

            It 'Should have the expected type and additional properties' {
                $result.PSObject.TypeNames[0] | Should -Be 'GitHub.IssueComment'
                $result.PSObject.TypeNames[1] | Should -Be 'GitHub.Comment'
                $result.RepositoryUrl | Should -Be $repo.RepositoryUrl
                $result.CommentId | Should -Be $result.id
                $result.user.PSObject.TypeNames[0] | Should -Be 'GitHub.User'
            }

            $commentId = $result.id
            $updated = Set-GitHubIssueComment -OwnerName $script:ownerName -RepositoryName $repo.name -Comment $commentId -Body $defaultEditedCommentBody -PassThru
            It 'Should have modified the expected comment' {
                $updated.id | Should -Be $commentId
            }

            It 'Should have the expected body text' {
                $updated.body | Should -Be $defaultEditedCommentBody
            }

            It 'Should have the expected type and additional properties' {
                $updated.PSObject.TypeNames[0] | Should -Be 'GitHub.IssueComment'
                $updated.PSObject.TypeNames[1] | Should -Be 'GitHub.Comment'
                $updated.RepositoryUrl | Should -Be $repo.RepositoryUrl
                $updated.CommentId | Should -Be $updated.id
                $updated.user.PSObject.TypeNames[0] | Should -Be 'GitHub.User'
            }

            Remove-GitHubIssueComment -OwnerName $script:ownerName -RepositoryName $repo.name -Comment $commentId -Force
            It 'Should have been removed' {
                { Get-GitHubIssueComment -OwnerName $script:ownerName -RepositoryName $repo.name -Comment $commentId } | Should -Throw
            }
        }

        Context 'With the repo on the pipeline' {
            $comment = $repo | New-GitHubIssueComment -Issue $issue.number -Body $defaultCommentBody
            It 'Should have the expected body text' {
                $comment.body | Should -Be $defaultCommentBody
            }

            It 'Should have the expected type and additional properties' {
                $comment.PSObject.TypeNames[0] | Should -Be 'GitHub.IssueComment'
                $comment.PSObject.TypeNames[1] | Should -Be 'GitHub.Comment'
                $comment.RepositoryUrl | Should -Be $repo.RepositoryUrl
                $comment.CommentId | Should -Be $comment.id
                $comment.user.PSObject.TypeNames[0] | Should -Be 'GitHub.User'
            }

            $result = $repo | Get-GitHubIssueComment -Comment $comment.id
            It 'Should be the expected comment' {
                $result.id | Should -Be $comment.id
            }

            It 'Should have the expected type and additional properties' {
                $result.PSObject.TypeNames[0] | Should -Be 'GitHub.IssueComment'
                $result.PSObject.TypeNames[1] | Should -Be 'GitHub.Comment'
                $result.RepositoryUrl | Should -Be $repo.RepositoryUrl
                $result.CommentId | Should -Be $result.id
                $result.user.PSObject.TypeNames[0] | Should -Be 'GitHub.User'
            }

            $commentId = $result.id
            $updated = $repo | Set-GitHubIssueComment -Comment $commentId -Body $defaultEditedCommentBody -PassThru
            It 'Should have modified the expected comment' {
                $updated.id | Should -Be $commentId
            }

            It 'Should have the expected body text' {
                $updated.body | Should -Be $defaultEditedCommentBody
            }

            It 'Should have the expected type and additional properties' {
                $updated.PSObject.TypeNames[0] | Should -Be 'GitHub.IssueComment'
                $updated.PSObject.TypeNames[1] | Should -Be 'GitHub.Comment'
                $updated.RepositoryUrl | Should -Be $repo.RepositoryUrl
                $updated.CommentId | Should -Be $updated.id
                $updated.user.PSObject.TypeNames[0] | Should -Be 'GitHub.User'
            }

            $repo | Remove-GitHubIssueComment -Comment $commentId -Force
            It 'Should have been removed' {
                { $repo | Get-GitHubIssueComment -Comment $commentId } | Should -Throw
            }
        }

        Context 'With the issue on the pipeline' {
            $comment = $issue | New-GitHubIssueComment -Body $defaultCommentBody
            It 'Should have the expected body text' {
                $comment.body | Should -Be $defaultCommentBody
            }

            It 'Should have the expected type and additional properties' {
                $comment.PSObject.TypeNames[0] | Should -Be 'GitHub.IssueComment'
                $comment.PSObject.TypeNames[1] | Should -Be 'GitHub.Comment'
                $comment.RepositoryUrl | Should -Be $repo.RepositoryUrl
                $comment.CommentId | Should -Be $comment.id
                $comment.user.PSObject.TypeNames[0] | Should -Be 'GitHub.User'
            }

            $result = Get-GitHubIssueComment -OwnerName $script:ownerName -RepositoryName $repo.name -Comment $comment.id
            It 'Should be the expected comment' {
                $result.id | Should -Be $comment.id
            }

            It 'Should have the expected type and additional properties' {
                $result.PSObject.TypeNames[0] | Should -Be 'GitHub.IssueComment'
                $result.PSObject.TypeNames[1] | Should -Be 'GitHub.Comment'
                $result.RepositoryUrl | Should -Be $repo.RepositoryUrl
                $result.CommentId | Should -Be $result.id
                $result.user.PSObject.TypeNames[0] | Should -Be 'GitHub.User'
            }

            $commentId = $result.id
            $updated = Set-GitHubIssueComment -OwnerName $script:ownerName -RepositoryName $repo.name -Comment $commentId -Body $defaultEditedCommentBody -PassThru
            It 'Should have modified the expected comment' {
                $updated.id | Should -Be $commentId
            }

            It 'Should have the expected body text' {
                $updated.body | Should -Be $defaultEditedCommentBody
            }

            It 'Should have the expected type and additional properties' {
                $updated.PSObject.TypeNames[0] | Should -Be 'GitHub.IssueComment'
                $updated.PSObject.TypeNames[1] | Should -Be 'GitHub.Comment'
                $updated.RepositoryUrl | Should -Be $repo.RepositoryUrl
                $updated.CommentId | Should -Be $updated.id
                $updated.user.PSObject.TypeNames[0] | Should -Be 'GitHub.User'
            }

            Remove-GitHubIssueComment -OwnerName $script:ownerName -RepositoryName $repo.name -Comment $commentId -Force
            It 'Should have been removed' {
                { Get-GitHubIssueComment -OwnerName $script:ownerName -RepositoryName $repo.name -Comment $commentId } | Should -Throw
            }
        }

        Context 'With the comment object on the pipeline' {
            $comment = New-GitHubIssueComment -OwnerName $script:ownerName -RepositoryName $repo.name -Issue $issue.number -Body $defaultCommentBody
            It 'Should have the expected body text' {
                $comment.body | Should -Be $defaultCommentBody
            }

            It 'Should have the expected type and additional properties' {
                $comment.PSObject.TypeNames[0] | Should -Be 'GitHub.IssueComment'
                $comment.PSObject.TypeNames[1] | Should -Be 'GitHub.Comment'
                $comment.RepositoryUrl | Should -Be $repo.RepositoryUrl
                $comment.CommentId | Should -Be $comment.id
                $comment.user.PSObject.TypeNames[0] | Should -Be 'GitHub.User'
            }

            $result = $comment | Get-GitHubIssueComment
            It 'Should be the expected comment' {
                $result.id | Should -Be $comment.id
            }

            It 'Should have the expected type and additional properties' {
                $result.PSObject.TypeNames[0] | Should -Be 'GitHub.IssueComment'
                $result.PSObject.TypeNames[1] | Should -Be 'GitHub.Comment'
                $result.RepositoryUrl | Should -Be $repo.RepositoryUrl
                $result.CommentId | Should -Be $result.id
                $result.user.PSObject.TypeNames[0] | Should -Be 'GitHub.User'
            }

            $updated = $comment | Set-GitHubIssueComment -Body $defaultEditedCommentBody -PassThru
            It 'Should have modified the expected comment' {
                $updated.id | Should -Be $comment.id
            }

            It 'Should have the expected body text' {
                $updated.body | Should -Be $defaultEditedCommentBody
            }

            It 'Should have the expected type and additional properties' {
                $updated.PSObject.TypeNames[0] | Should -Be 'GitHub.IssueComment'
                $updated.PSObject.TypeNames[1] | Should -Be 'GitHub.Comment'
                $updated.RepositoryUrl | Should -Be $repo.RepositoryUrl
                $updated.CommentId | Should -Be $updated.id
                $updated.user.PSObject.TypeNames[0] | Should -Be 'GitHub.User'
            }

            $comment | Remove-GitHubIssueComment -Force
            It 'Should have been removed' {
                { $comment | Get-GitHubIssueComment } | Should -Throw
            }
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
