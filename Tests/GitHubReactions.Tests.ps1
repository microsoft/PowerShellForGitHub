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
        $repo = New-GitHubRepository -RepositoryName ([Guid]::NewGuid().Guid) -AutoInit
        $issue = New-GitHubIssue -Uri $repo.svn_url -Title $defaultIssueTitle

        Context 'For creating a reaction' {
            Set-GitHubReaction -Uri $repo.svn_url -Issue $issue.number -ReactionType $defaultReactionType
            $existingReaction = Get-GitHubReaction -Uri $repo.svn_url -Issue $issue.number

            It "Should have the expected reaction type" {
                $existingReaction.content | Should be $defaultReactionType
            }
        }

        Context 'For getting reactions from an issue' {
            Get-GitHubIssue -Uri $repo.svn_url -Issue $issue.number | Set-GitHubReaction -ReactionType $otherReactionType
            $allReactions = Get-GitHubReaction -Uri $repo.svn_url -Issue $issue.number
            $specificReactions = Get-GitHubReaction -Uri $repo.svn_url -Issue $issue.number -ReactionType $otherReactionType

            It 'Should have the expected number of reactions' {
                $allReactions.Count | Should be 2
                $specificReactions.Count | Should be 1
            }

            It 'Should have the expected reaction content' {

                $specificReactions.content | Should be $otherReactionType
                $specificReactions.RepositoryName | Should be $repo.name
            }
        }

        Context 'For getting reactions from a repository and deleting them' {
            $existingReactions = @(Get-GitHubReaction -Uri $repo.svn_url -Issue $issue.number)

            It 'Should have the expected number of reactions' {
                $existingReactions.Count | Should be 2
            }

            $existingReactions | Remove-GitHubReaction -Confirm:$false

            $existingReactions = @(Get-GitHubReaction -Uri $repo.svn_url -Issue $issue.number)

            It 'Should have no reactions' {
                $existingReactions
                $existingReactions.Count | Should be 0
            }
        }

        Remove-GitHubRepository -Uri $repo.svn_url
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
