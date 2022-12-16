# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

<#
.Synopsis
   Tests for GitHubProjectCards.ps1 module
#>

[CmdletBinding()]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '',
    Justification = 'Suppress false positives in Pester code blocks')]
param()

<#

The Projects tests have been disabled because GitHub has deprecated the ability to create
classic Projects, so these tests will fail when trying to create the project that they test
against.

There's still value in the rest of the functions as they can still manipulate existing
classic Projects, however we can no longer easily validate that these functions still work
correctly since we have no classic Project to test against.

For more info, see: https://github.com/microsoft/PowerShellForGitHub/issues/380

#>

BeforeAll {
<#
    # This is common test code setup logic for all Pester test files
    $moduleRootPath = Split-Path -Path $PSScriptRoot -Parent
    . (Join-Path -Path $moduleRootPath -ChildPath 'Tests\Common.ps1')

    # Define Script-scoped, readOnly, hidden variables.
    @{
        defaultProject = "TestProject_$([Guid]::NewGuid().Guid)"
        defaultColumn = "TestColumn"
        defaultColumnTwo = "TestColumnTwo"

        defaultCard = "TestCard"
        defaultCardTwo = "TestCardTwo"
        defaultCardUpdated = "TestCard_Updated"
        defaultArchivedCard = "TestCard_Archived"

        defaultIssue = "TestIssue"
    }.GetEnumerator() | ForEach-Object {
        Set-Variable -Force -Scope Script -Option ReadOnly -Visibility Private -Name $_.Key -Value $_.Value
    }

    $repo = New-GitHubRepository -RepositoryName ([Guid]::NewGuid().Guid) -AutoInit
    $project = New-GitHubProject -OwnerName $script:ownerName -RepositoryName $repo.name -ProjectName $defaultProject

    $column = New-GitHubProjectColumn -Project $project.id -ColumnName $defaultColumn
    $columntwo = New-GitHubProjectColumn -Project $project.id -ColumnName $defaultColumnTwo

    $issue = New-GitHubIssue -Owner $script:ownerName -RepositoryName $repo.name -Title $defaultIssue
#>
}

Describe 'Getting Project Cards' -Skip {
    BeforeAll {
        $card = New-GitHubProjectCard -Column $column.id -Note $defaultCard
        $cardArchived = New-GitHubProjectCard -Column $column.id -Note $defaultArchivedCard
        Set-GitHubProjectCard -Card $cardArchived.id -Archive
    }

    AfterAll {
        $null = Remove-GitHubProjectCard -Card $card.id -Confirm:$false
    }

    Context 'Get cards for a column' {

        BeforeAll {
            $results = @(Get-GitHubProjectCard -Column $column.id)
        }

        It 'Should get cards' {
            $results | Should -Not -BeNullOrEmpty
        }

        It 'Should only have one card (since it defaults to not archived)' {
            $results.Count | Should -Be 1
        }

        It 'Note is correct' {
            $results[0].note | Should -Be $defaultCard
        }

        It 'Has the expected type and additional properties' {
            $results[0].PSObject.TypeNames[0] | Should -Be 'GitHub.ProjectCard'
            $results[0].CardId | Should -Be $results[0].id
            $results[0].ProjectId | Should -Be $project.id
            $results[0].ColumnId | Should -Be $column.id
            $results[0].IssueNumber | Should -BeNullOrEmpty
            $results[0].RepositoryUrl | Should -BeNullOrEmpty
            $results[0].PullRequestNumber | Should -BeNullOrEmpty
            $results[0].creator.PSObject.TypeNames[0] | Should -Be 'GitHub.User'
        }
    }

    Context 'Get all cards for a column' {
        BeforeAll {
            $results = @(Get-GitHubProjectCard -Column $column.id -State All)
        }

        It 'Should get all cards' {
            $results.Count | Should -Be 2
        }

        It 'Has the expected type and additional properties' {
            foreach ($item in $results)
            {
                $item.PSObject.TypeNames[0] | Should -Be 'GitHub.ProjectCard'
                $item.CardId | Should -Be $item.id
                $item.ProjectId | Should -Be $project.id
                $item.ColumnId | Should -Be $column.id
                $item.IssueNumber | Should -BeNullOrEmpty
                $item.RepositoryUrl | Should -BeNullOrEmpty
                $item.PullRequestNumber | Should -BeNullOrEmpty
                $item.creator.PSObject.TypeNames[0] | Should -Be 'GitHub.User'
            }
        }
    }

    Context 'Get archived cards for a column' {
        BeforeAll {
            $result = Get-GitHubProjectCard -Column $column.id -State Archived
        }

        It 'Should get archived card' {
            $result | Should -Not -BeNullOrEmpty
        }

        It 'Note is correct' {
            $result.note | Should -Be $defaultArchivedCard
        }

        It 'Should be archived' {
            $result.Archived | Should -Be $true
        }

        It 'Has the expected type and additional properties' {
            $result.PSObject.TypeNames[0] | Should -Be 'GitHub.ProjectCard'
            $result.CardId | Should -Be $result.id
            $result.ProjectId | Should -Be $project.id
            $result.ColumnId | Should -Be $column.id
            $result.IssueNumber | Should -BeNullOrEmpty
            $result.RepositoryUrl | Should -BeNullOrEmpty
            $result.PullRequestNumber | Should -BeNullOrEmpty
            $result.creator.PSObject.TypeNames[0] | Should -Be 'GitHub.User'
        }
    }

    Context 'Get non-archived cards for a column (with column on pipeline)' {
        BeforeAll {
            $result = $column | Get-GitHubProjectCard -State NotArchived
        }

        It 'Should get non-archived card' {
            $result | Should -Not -BeNullOrEmpty
        }

        It 'Should have the right ID' {
            $result.id | Should -Be $card.id
        }

        It 'Should not be archived' {
            $result.Archived | Should -Be $false
        }

        It 'Has the expected type and additional properties' {
            $result.PSObject.TypeNames[0] | Should -Be 'GitHub.ProjectCard'
            $result.CardId | Should -Be $result.id
            $result.ProjectId | Should -Be $project.id
            $result.ColumnId | Should -Be $column.id
            $result.IssueNumber | Should -BeNullOrEmpty
            $result.RepositoryUrl | Should -BeNullOrEmpty
            $result.PullRequestNumber | Should -BeNullOrEmpty
            $result.creator.PSObject.TypeNames[0] | Should -Be 'GitHub.User'
        }
    }
}

Describe 'Modify card' -Skip {
    BeforeAll {
        $card = New-GitHubProjectCard -Column $column.id -Note $defaultCard
        $cardTwo = New-GitHubProjectCard -Column $column.id -Note $defaultCardTwo
        $cardArchived = New-GitHubProjectCard -Column $column.id -Note $defaultArchivedCard
    }

    AfterAll {
        $null = Remove-GitHubProjectCard -Card $card.id -Force
    }

    Context 'Modify card note' {
        BeforeAll {
            Set-GitHubProjectCard -Card $card.id -Note $defaultCardUpdated
            $result = Get-GitHubProjectCard -Card $card.id
        }

        It 'Should get card' {
            $result | Should -Not -BeNullOrEmpty
        }

        It 'Note has been updated' {
            $result.note | Should -Be $defaultCardUpdated
        }

        It 'Has the expected type and additional properties' {
            $result.PSObject.TypeNames[0] | Should -Be 'GitHub.ProjectCard'
            $result.CardId | Should -Be $result.id
            $result.ProjectId | Should -Be $project.id
            $result.ColumnId | Should -Be $column.id
            $result.IssueNumber | Should -BeNullOrEmpty
            $result.RepositoryUrl | Should -BeNullOrEmpty
            $result.PullRequestNumber | Should -BeNullOrEmpty
            $result.creator.PSObject.TypeNames[0] | Should -Be 'GitHub.User'
        }
    }

    Context 'Modify card note (via card on pipeline)' {
        BeforeAll {
            $card | Set-GitHubProjectCard -Note $defaultCard
            $result = $card | Get-GitHubProjectCard
        }

        It 'Should have the expected Note value' {
            $result.note | Should -Be $defaultCardUpdated
        }


        It 'Should have the updated Note' {
            $result = $card | Get-GitHubProjectCard
            $result.note | Should -Be $defaultCard
        }

        It 'Has the expected type and additional properties' {
            $result = $card | Get-GitHubProjectCard
            $result.PSObject.TypeNames[0] | Should -Be 'GitHub.ProjectCard'
            $result.CardId | Should -Be $result.id
            $result.ProjectId | Should -Be $project.id
            $result.ColumnId | Should -Be $column.id
            $result.IssueNumber | Should -BeNullOrEmpty
            $result.RepositoryUrl | Should -BeNullOrEmpty
            $result.PullRequestNumber | Should -BeNullOrEmpty
            $result.creator.PSObject.TypeNames[0] | Should -Be 'GitHub.User'
        }
    }

    Context 'Archive a card' {
        BeforeAll {
            Set-GitHubProjectCard -Card $cardArchived.id -Archive
            $result = Get-GitHubProjectCard -Card $cardArchived.id
        }

        It 'Should get card' {
            $result | Should -Not -BeNullOrEmpty
        }

        It 'Card is archived' {
            $result.Archived | Should -Be $true
        }
    }

    Context 'Restore a card' {
        BeforeAll {
            $cardArchived | Set-GitHubProjectCard -Restore
            $result = Get-GitHubProjectCard -Card $cardArchived.id
        }

        It 'Should get card' {
            $result | Should -Not -BeNullOrEmpty
        }

        It 'Card is not archived' {
            $result.Archived | Should -Be $false
        }
    }

    Context 'Move card position within column' {
        BeforeAll {
            $null = Move-GitHubProjectCard -Card $cardTwo.id -Top
            $results = @(Get-GitHubProjectCard -Column $column.id)
        }

        It 'Card is now top' {
            $results[0].note | Should -Be $defaultCardTwo
        }

        It 'Has the expected type and additional properties' {
            $results[0].PSObject.TypeNames[0] | Should -Be 'GitHub.ProjectCard'
            $results[0].CardId | Should -Be $results[0].id
            $results[0].ProjectId | Should -Be $project.id
            $results[0].ColumnId | Should -Be $column.id
            $results[0].IssueNumber | Should -BeNullOrEmpty
            $results[0].RepositoryUrl | Should -BeNullOrEmpty
            $results[0].PullRequestNumber | Should -BeNullOrEmpty
            $results[0].creator.PSObject.TypeNames[0] | Should -Be 'GitHub.User'
        }
    }

    Context 'Move card using after parameter' {
        BeforeAll {
            $null = Move-GitHubProjectCard -Card $cardTwo.id -After $card.id
            $results = @(Get-GitHubProjectCard -Column $column.id)
        }

        It 'Card now exists in new column' {
            $results[1].note | Should -Be $defaultCardTwo
        }

        It 'Has the expected type and additional properties' {
            $results[1].PSObject.TypeNames[0] | Should -Be 'GitHub.ProjectCard'
            $results[1].CardId | Should -Be $results[1].id
            $results[1].ProjectId | Should -Be $project.id
            $results[1].ColumnId | Should -Be $column.id
            $results[1].IssueNumber | Should -BeNullOrEmpty
            $results[1].RepositoryUrl | Should -BeNullOrEmpty
            $results[1].PullRequestNumber | Should -BeNullOrEmpty
            $results[1].creator.PSObject.TypeNames[0] | Should -Be 'GitHub.User'
        }
    }

    Context 'Move card using before parameter (card on pipeline)' {
        BeforeAll {
            $null = $cardTwo | Move-GitHubProjectCard -After $card.id
            $results = @($column | Get-GitHubProjectCard)
        }

        It 'Card now exists in new column' {
            $results[1].note | Should -Be $defaultCardTwo
        }

        It 'Has the expected type and additional properties' {
            $results[1].PSObject.TypeNames[0] | Should -Be 'GitHub.ProjectCard'
            $results[1].CardId | Should -Be $results[1].id
            $results[1].ProjectId | Should -Be $project.id
            $results[1].ColumnId | Should -Be $column.id
            $results[1].IssueNumber | Should -BeNullOrEmpty
            $results[1].RepositoryUrl | Should -BeNullOrEmpty
            $results[1].PullRequestNumber | Should -BeNullOrEmpty
            $results[1].creator.PSObject.TypeNames[0] | Should -Be 'GitHub.User'
        }
    }

    Context 'Move card to another column' {
        BeforeAll {
            $null = Move-GitHubProjectCard -Card $cardTwo.id -Top -ColumnId $columnTwo.id
            $results = @(Get-GitHubProjectCard -Column $columnTwo.id)
        }

        It 'Card now exists in new column' {
            $results[0].note | Should -Be $defaultCardTwo
        }

        It 'Has the expected type and additional properties' {
            $results[0].PSObject.TypeNames[0] | Should -Be 'GitHub.ProjectCard'
            $results[0].CardId | Should -Be $results[0].id
            $results[0].ProjectId | Should -Be $project.id
            $results[0].ColumnId | Should -Be $columnTwo.id
            $results[0].IssueNumber | Should -BeNullOrEmpty
            $results[0].RepositoryUrl | Should -BeNullOrEmpty
            $results[0].PullRequestNumber | Should -BeNullOrEmpty
            $results[0].creator.PSObject.TypeNames[0] | Should -Be 'GitHub.User'
        }
    }

    Context 'Move card to another column (with column on pipeline)' {
        BeforeAll {
            $null = ($column | Move-GitHubProjectCard -Card $cardTwo.id -Top)
            $result = $cardTwo | Get-GitHubProjectCard
        }

        It 'Card now exists in new column' {
            $result.ColumnId | Should -Be $column.ColumnId
        }

        It 'Has the expected type and additional properties' {
            $result.PSObject.TypeNames[0] | Should -Be 'GitHub.ProjectCard'
            $result.CardId | Should -Be $result.id
            $result.ProjectId | Should -Be $project.id
            $result.ColumnId | Should -Be $column.id
            $result.IssueNumber | Should -BeNullOrEmpty
            $result.RepositoryUrl | Should -BeNullOrEmpty
            $result.PullRequestNumber | Should -BeNullOrEmpty
            $result.creator.PSObject.TypeNames[0] | Should -Be 'GitHub.User'
        }
    }

    Context 'Move command throws appropriate error' {
        It 'Appropriate error is thrown' {
            { Move-GitHubProjectCard -Card $cardTwo.id -Top -Bottom } | Should -Throw 'You must use one (and only one) of the parameters Top, Bottom or After.'
        }
    }
}

Describe 'Create Project Cards' -Skip {
    Context 'Create project card with note' {
        BeforeAll {
            $card = @{id = 0 }

            $card.id = (New-GitHubProjectCard -Column $column.id -Note $defaultCard).id
            $result = Get-GitHubProjectCard -Card $card.id
        }

        AfterAll {
            $null = Remove-GitHubProjectCard -Card $card.id -Confirm:$false
            Remove-Variable -Name card
        }

        It 'Card exists' {
            $result | Should -Not -BeNullOrEmpty
        }

        It 'Note is correct' {
            $result.note | Should -Be $defaultCard
        }

        It 'Has the expected type and additional properties' {
            $result.PSObject.TypeNames[0] | Should -Be 'GitHub.ProjectCard'
            $result.CardId | Should -Be $result.id
            $result.ProjectId | Should -Be $project.id
            $result.ColumnId | Should -Be $column.id
            $result.IssueNumber | Should -BeNullOrEmpty
            $result.RepositoryUrl | Should -BeNullOrEmpty
            $result.PullRequestNumber | Should -BeNullOrEmpty
            $result.creator.PSObject.TypeNames[0] | Should -Be 'GitHub.User'
        }
    }

    Context 'Create project card with note (with column object via pipeline)' {
        BeforeAll {
            $card = @{id = 0 }

            $newCard = $column | New-GitHubProjectCard -Note $defaultCard
            $card.id = $newCard.id
            $result = $newCard | Get-GitHubProjectCard
        }

        AfterAll {
            $null = Remove-GitHubProjectCard -Card $card.id -Confirm:$false
            Remove-Variable -Name card
        }

        It 'Card exists' {
            $result | Should -Not -BeNullOrEmpty
        }

        It 'Note is correct' {
            $result.note | Should -Be $defaultCard
        }

        It 'Has the expected type and additional properties' {
            $result.PSObject.TypeNames[0] | Should -Be 'GitHub.ProjectCard'
            $result.CardId | Should -Be $result.id
            $result.ProjectId | Should -Be $project.id
            $result.ColumnId | Should -Be $column.id
            $result.IssueNumber | Should -BeNullOrEmpty
            $result.RepositoryUrl | Should -BeNullOrEmpty
            $result.PullRequestNumber | Should -BeNullOrEmpty
            $result.creator.PSObject.TypeNames[0] | Should -Be 'GitHub.User'
        }
    }

    Context 'Create project card from issue' {
        BeforeAll {
            $card = @{id = 0 }

            $card.id = (New-GitHubProjectCard -Column $column.id -IssueId $issue.id).id
            $result = Get-GitHubProjectCard -Card $card.id
        }

        AfterAll {
            $null = Remove-GitHubProjectCard -Card $card.id -Force
            Remove-Variable -Name card
        }

        It 'Card exists' {
            $result | Should -Not -BeNullOrEmpty
        }

        It 'Content url is for an issue' {
            $result.content_url | Should -Match 'issues'
        }

        It 'Has the expected type and additional properties' {
            $result.PSObject.TypeNames[0] | Should -Be 'GitHub.ProjectCard'
            $result.CardId | Should -Be $result.id
            $result.ProjectId | Should -Be $project.id
            $result.ColumnId | Should -Be $column.id
            $result.IssueNumber | Should -Be $issue.number
            $result.RepositoryUrl | Should -Be $issue.RepositoryUrl
            $result.PullRequestNumber | Should -BeNullOrEmpty
            $result.creator.PSObject.TypeNames[0] | Should -Be 'GitHub.User'
        }
    }

    Context 'Create project card from issue (with issue object on pipeline)' {
        BeforeAll {
            $card = @{id = 0 }

            $newCard = $issue | New-GitHubProjectCard -Column $column.id
            $card.id = $newCard.id
            $result = $newCard | Get-GitHubProjectCard
        }

        AfterAll {
            $null = Remove-GitHubProjectCard -Card $card.id -Force
            Remove-Variable -Name card
        }

        It 'Card exists' {
            $result | Should -Not -BeNullOrEmpty
        }

        It 'Content url is for an issue' {
            $result.content_url | Should -Match 'issues'
        }

        It 'Has the expected type and additional properties' {
            $result.PSObject.TypeNames[0] | Should -Be 'GitHub.ProjectCard'
            $result.CardId | Should -Be $result.id
            $result.ProjectId | Should -Be $project.id
            $result.ColumnId | Should -Be $column.id
            $result.IssueNumber | Should -Be $issue.number
            $result.RepositoryUrl | Should -Be $issue.RepositoryUrl
            $result.PullRequestNumber | Should -BeNullOrEmpty
            $result.creator.PSObject.TypeNames[0] | Should -Be 'GitHub.User'
        }
    }

    # TODO: Create a test that verifies cards created based on a pull request
}

Describe 'Remove card' -Skip {
    Context 'Remove card' {
        BeforeAll {
            $card = New-GitHubProjectCard -Column $column.id -Note $defaultCard
            $null = Remove-GitHubProjectCard -Card $card.id -Confirm:$false
        }

        It 'Project card should be removed' {
            { Get-GitHubProjectCard -Card $card.id } | Should -Throw
        }
    }

    Context 'Remove card (via pipeline)' {
        BeforeAll {
            $card = $column | New-GitHubProjectCard -Note $defaultCard
            $null = $card | Remove-GitHubProjectCard -Force
        }

        It 'Project card should be removed' {
            { $card | Get-GitHubProjectCard } | Should -Throw
        }
    }
}

AfterAll {
<#
    Remove-GitHubProject -Project $project.id -Confirm:$false

    if (Test-Path -Path $script:originalConfigFile -PathType Leaf)
    {
        # Restore the user's configuration to its pre-test state
        Restore-GitHubConfiguration -Path $script:originalConfigFile
        $script:originalConfigFile = $null
    }
#>
}
