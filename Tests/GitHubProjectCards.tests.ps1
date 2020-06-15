# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

<#
.Synopsis
   Tests for GitHubProjectCards.ps1 module
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
            $null = Set-GitHubProjectCard -Card $cardArchived.id -Archive

            # Avoid PSScriptAnalyzer PSUseDeclaredVarsMoreThanAssignments
            $card = $card
            $cardArchived = $cardArchived
        }

        AfterAll {
            $null = Remove-GitHubProjectCard -Card $card.id -Confirm:$false
        }

        Context 'Get cards for a column' {
            $results = @(Get-GitHubProjectCard -Column $column.id)
            It 'Should get cards' {
                $results | Should -Not -BeNullOrEmpty
            }

            It 'Note is correct' {
                $results.note | Should -Be $defaultCard
            }
        }

        Context 'Get all cards for a column' {
            $results = @(Get-GitHubProjectCard -Column $column.id -ArchivedState All)
            It 'Should get all cards' {
                $results.Count | Should -Be 2
            }
        }

        Context 'Get archived cards for a column' {
            $result = Get-GitHubProjectCard -Column $column.id -ArchivedState Archived
            It 'Should get archived card' {
                $result | Should -Not -BeNullOrEmpty
            }

            It 'Note is correct' {
                $result.note | Should -Be $defaultArchivedCard
            }

            It 'Should be archived' {
                $result.Archived | Should -Be $true
            }
        }
    }

    Describe 'Modify card' {
        BeforeAll {
            $card = New-GitHubProjectCard -Column $column.id -Note $defaultCard
            $cardTwo = New-GitHubProjectCard -Column $column.id -Note $defaultCardTwo
            $cardArchived = New-GitHubProjectCard -Column $column.id -Note $defaultArchivedCard

            # Avoid PSScriptAnalyzer PSUseDeclaredVarsMoreThanAssignments
            $card = $card
            $cardTwo = $cardTwo
            $cardArchived = $cardArchived
        }

        AfterAll {
            $null = Remove-GitHubProjectCard -Card $card.id -Force
        }

        Context 'Modify card note' {
            $null = Set-GitHubProjectCard -Card $card.id -Note $defaultCardUpdated
            $result = Get-GitHubProjectCard -Card $card.id

            It 'Should get card' {
                $result | Should -Not -BeNullOrEmpty
            }

            It 'Note has been updated' {
                $result.note | Should -Be $defaultCardUpdated
            }
        }

        Context 'Archive a card' {
            $null = Set-GitHubProjectCard -Card $cardArchived.id -Archive
            $result = Get-GitHubProjectCard -Card $cardArchived.id

            It 'Should get card' {
                $result | Should -Not -BeNullOrEmpty
            }

            It 'Card is archived' {
                $result.Archived | Should -Be $true
            }
        }

        Context 'Restore a card' {
            $null = Set-GitHubProjectCard -Card $cardArchived.id -Restore
            $result = Get-GitHubProjectCard -Card $cardArchived.id

            It 'Should get card' {
                $result | Should -Not -BeNullOrEmpty
            }

            It 'Card is not archived' {
                $result.Archived | Should -Be $false
            }
        }

        Context 'Move card position within column' {
            $null = Move-GitHubProjectCard -Card $cardTwo.id -Top
            $results = @(Get-GitHubProjectCard -Column $column.id)

            It 'Card is now top' {
                $results[0].note | Should -Be $defaultCardTwo
            }
        }

        Context 'Move card using after parameter' {
            $null = Move-GitHubProjectCard -Card $cardTwo.id -After $card.id
            $results = @(Get-GitHubProjectCard -Column $column.id)

            It 'Card now exists in new column' {
                $results[1].note | Should -Be $defaultCardTwo
            }
        }

        Context 'Move card to another column' {
            $null = Move-GitHubProjectCard -Card $cardTwo.id -Top -ColumnId $columnTwo.id
            $results = @(Get-GitHubProjectCard -Column $columnTwo.id)

            It 'Card now exists in new column' {
                $results[0].note | Should -Be $defaultCardTwo
            }
        }

        Context 'Move command throws appropriate error' {
            It 'Appropriate error is thrown' {
                { Move-GitHubProjectCard -Card $cardTwo.id -Top -Bottom } | Should -Throw 'You must use one (and only one) of the parameters Top, Bottom or After.'
            }
        }
    }

    Describe 'Create Project Cards' -tag new {
        Context 'Create project card with note' {
            BeforeAll {
                $card = @{id = 0}

                # Avoid PSScriptAnalyzer PSUseDeclaredVarsMoreThanAssignments
                $card = $card
            }

            AfterAll {
                $null = Remove-GitHubProjectCard -Card $card.id -Confirm:$false
                Remove-Variable -Name card
            }

            $card.id = (New-GitHubProjectCard -Column $column.id -Note $defaultCard).id
            $result = Get-GitHubProjectCard -Card $card.id

            It 'Card exists' {
                $result | Should -Not -BeNullOrEmpty
            }

            It 'Note is correct' {
                $result.note | Should -Be $defaultCard
            }
        }

        Context 'Create project card from issue' {
            BeforeAll {
                $card = @{id = 0}

                # Avoid PSScriptAnalyzer PSUseDeclaredVarsMoreThanAssignments
                $card = $card
            }

            AfterAll {
                $null = Remove-GitHubProjectCard -Card $card.id -Force
                Remove-Variable -Name card
            }

            $card.id = (New-GitHubProjectCard -Column $column.id -ContentId $issue.id -ContentType 'Issue').id
            $result = Get-GitHubProjectCard -Card $card.id

            It 'Card exists' {
                $result | Should -Not -BeNullOrEmpty
            }

            It 'Content url is for an issue' {
                $result.content_url | Should -Match 'issues'
            }
        }
    }

    Describe 'Remove card' {
        Context 'Remove card' {
            BeforeAll {
                $card = New-GitHubProjectCard -Column $column.id -Note $defaultCard

                # Avoid PSScriptAnalyzer PSUseDeclaredVarsMoreThanAssignments
                $card = $card
            }

            $null = Remove-GitHubProjectCard -Card $card.id -Confirm:$false
            It 'Project card should be removed' {
                {Get-GitHubProjectCard -Card $card.id} | Should -Throw
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