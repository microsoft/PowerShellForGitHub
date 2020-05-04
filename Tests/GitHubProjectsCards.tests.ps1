# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

<#
.Synopsis
   Tests for GitHubProjectsCards.ps1 module
#>

# This is common test code setup logic for all Pester test files
$moduleRootPath = Split-Path -Path $PSScriptRoot -Parent
. (Join-Path -Path $moduleRootPath -ChildPath 'Tests\Common.ps1')

try
{
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
    $project = New-GitHubProject -Owner $script:ownerName -Repository $repo.name -Name $defaultProject

    $column = New-GitHubProjectColumn -Project $project.id -Name $defaultColumn
    $columntwo = New-GitHubProjectColumn -Project $project.id -Name $defaultColumnTwo

    $issue = New-GitHubIssue -Owner $script:ownerName -RepositoryName $repo.name -Title $defaultIssue

    Describe 'Getting Project Cards' {
        BeforeAll {
            $card = New-GitHubProjectCard -Column $column.id -Note $defaultCard
            $cardArchived = New-GitHubProjectCard -Column $column.id -Note $defaultArchivedCard
            $null = Set-GitHubProjectCard -Card $cardArchived.id -Archived
        }
        AfterAll {
            $null = Remove-GitHubProjectCard -Card $card.id -Confirm:$false
        }

        Context 'Get cards for a column' {
            $results = Get-GitHubProjectCard -Column $column.id
            It 'Should get cards' {
                $results | Should Not BeNullOrEmpty
            }

            It 'Note is correct' {
                $results.note | Should be $defaultCard
            }
        }

        Context 'Get archived cards for a column' {
            $results = Get-GitHubProjectCard -Column $column.id -ArchivedState Archived
            It 'Should get archived card' {
                $results | Should Not BeNullOrEmpty
            }

            It 'Note is correct' {
                $results.note | Should be $defaultArchivedCard
            }

            It 'Should be archived' {
                $results.Archived | Should be $true
            }
        }
    }

    Describe 'Modify card' {
        BeforeAll {
            $card = New-GitHubProjectCard -Column $column.id -Note $defaultCard
            $cardTwo = New-GitHubProjectCard -Column $column.id -Note $defaultCardTwo
            $cardArchived = New-GitHubProjectCard -Column $column.id -Note $defaultArchivedCard
        }
        AfterAll {
            $null = Remove-GitHubProjectCard -Card $card.id -Confirm:$false
        }

        Context 'Modify card note' {
            $null = Set-GitHubProjectCard -Card $card.id -Note $defaultCardUpdated
            $results = Get-GitHubProjectCard -Card $card.id

            It 'Should get card' {
                $results | Should Not BeNullOrEmpty
            }

            It 'Note has been updated' {
                $results.note | Should be $defaultCardUpdated
            }
        }

        Context 'Modify card to be archived' {
            $null = Set-GitHubProjectCard -Card $cardArchived.id -Archived
            $results = Get-GitHubProjectCard -Card $cardArchived.id

            It 'Should get card' {
                $results | Should Not BeNullOrEmpty
            }

            It 'Card is archived' {
                $results.Archived | Should be $true
            }
        }

        Context 'Move column position within column' {
            $null = Move-GitHubProjectCard -Card $cardTwo.id -Position Top
            $results = Get-GitHubProjectCard -Column $column.id

            It 'Card is now top' {
                $results[0].note | Should be $defaultCardTwo
            }
        }

        Context 'Move column to another column' {
            $null = Move-GitHubProjectCard -Card $cardTwo.id -Position Top -ColumnId $columnTwo.id
            $results = Get-GitHubProjectCard -Column $columnTwo.id

            It 'Card now exists in new column' {
                $results[0].note | Should be $defaultCardTwo
            }
        }
    }

    Describe 'Create Project Cards' -tag new {
        Context 'Create project card with note' {
            BeforeAll {
                $card = @{id = 0}
            }
            AfterAll {
                $null = Remove-GitHubProjectCard -Card $card.id -Confirm:$false
                Remove-Variable card
            }

            $card.id = (New-GitHubProjectCard -Column $column.id -Note $defaultCard).id
            $results = Get-GitHubProjectCard -Card $card.id

            It 'Card exists' {
                $results | Should Not BeNullOrEmpty
            }

            It 'Name is correct' {
                $results.note | Should be $defaultCard
            }
        }

        Context 'Create project card from issue' {
            BeforeAll {
                $card = @{id = 0}
            }
            AfterAll {
                $null = Remove-GitHubProjectCard -Card $card.id -Confirm:$false
                Remove-Variable card
            }

            $card.id = (New-GitHubProjectCard -Column $column.id -ContentId $issue.id -ContentType 'Issue').id
            $results = Get-GitHubProjectCard -Card $card.id

            It 'Card exists' {
                $results | Should Not BeNullOrEmpty
            }

            It 'Content url contains issue' {
                $results.content_url | Should match 'issues'
            }
        }
    }

    Describe 'Remove card' {
        Context 'Remove card' {
            BeforeAll {
                $card = New-GitHubProjectCard -Column $column.id -Note $defaultCard
            }

            $null = Remove-GitHubProjectCard -Card $card.id -Confirm:$false
            It 'Project card should be removed' {
                {Get-GitHubProjectCard -Card $card.id} | Should Throw
            }
        }
    }

    Remove-GitHubProject -Project $project.id -Confirm:$false
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