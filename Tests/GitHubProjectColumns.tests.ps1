# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

<#
.Synopsis
   Tests for GitHubProjectColumns.ps1 module
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
        defaultColumnUpdate = "TestColumn_Updated"
    }.GetEnumerator() | ForEach-Object {
        Set-Variable -Force -Scope Script -Option ReadOnly -Visibility Private -Name $_.Key -Value $_.Value
    }

    $project = New-GitHubProject -UserProject -Name $defaultProject

    Describe 'Getting Project Columns' {
        BeforeAll {
            $column = New-GitHubProjectColumn -Project $project.id -Name $defaultColumn

            # Avoid PSScriptAnalyzer PSUseDeclaredVarsMoreThanAssignments
            $column = $column
        }

        AfterAll {
            $null = Remove-GitHubProjectColumn -Column $column.id -Confirm:$false
        }

        Context 'Get columns for a project' {
            $results = @(Get-GitHubProjectColumn -Project $project.id)
            It 'Should get column' {
                $results | Should Not BeNullOrEmpty
            }

            It 'Should only have one column' {
                $results.Count | Should Be 1
            }

            It 'Name is correct' {
                $results[0].name | Should Be $defaultColumn
            }
        }
    }

    Describe 'Modify Project Column' {
        BeforeAll {
            $column = New-GitHubProjectColumn -Project $project.id -Name $defaultColumn
            $columntwo = New-GitHubProjectColumn -Project $project.id -Name $defaultColumnTwo

            # Avoid PSScriptAnalyzer PSUseDeclaredVarsMoreThanAssignments
            $column = $column
            $columnTwo = $columnTwo
        }

        AfterAll {
            $null = Remove-GitHubProjectColumn -Column $column.id -Confirm:$false
            $null = Remove-GitHubProjectColumn -Column $columntwo.id -Confirm:$false
        }

        Context 'Modify column name' {
            $null = Set-GitHubProjectColumn -Column $column.id -Name $defaultColumnUpdate
            $result = Get-GitHubProjectColumn -Column $column.id

            It 'Should get column' {
                $result | Should Not BeNullOrEmpty
            }

            It 'Name has been updated' {
                $result.name | Should Be $defaultColumnUpdate
            }
        }

        Context 'Move column to first position' {
            $null = Move-GitHubProjectColumn -Column $columntwo.id -First
            $results = @(Get-GitHubProjectColumn -Project $project.id)

            It 'Should still have more than one column in the project' {
                $results.Count | Should Be 2
            }

            It 'Column is now in the first position' {
                $results[0].name | Should Be $defaultColumnTwo
            }
        }

        Context 'Move column using after parameter' {
            $null = Move-GitHubProjectColumn -Column $columntwo.id -After $column.id
            $results = @(Get-GitHubProjectColumn -Project $project.id)

            It 'Column is now not in the first position' {
                $results[1].name | Should Be $defaultColumnTwo
            }
        }

        Context 'Move command throws appropriate error' {
            It 'Expected error returned' {
                { Move-GitHubProjectColumn -Column $column.id -First -Last } | Should Throw 'You must use one (and only one) of the parameters First, Last or After.'
            }
        }
    }

    Describe 'Create Project Column' {
        Context 'Create project column' {
            BeforeAll {
                $column = @{id = 0}

                # Avoid PSScriptAnalyzer PSUseDeclaredVarsMoreThanAssignments
                $column = $column
            }

            AfterAll {
                $null = Remove-GitHubProjectColumn -Column $column.id -Confirm:$false
                Remove-Variable -Name column
            }

            $column.id = (New-GitHubProjectColumn -Project $project.id -Name $defaultColumn).id
            $result = Get-GitHubProjectColumn -Column $column.id

            It 'Column exists' {
                $result | Should Not BeNullOrEmpty
            }

            It 'Name is correct' {
                $result.name | Should Be $defaultColumn
            }
        }
    }

    Describe 'Remove project column' {
        Context 'Remove project column' {
            BeforeAll {
                $column = New-GitHubProjectColumn -Project $project.id -Name $defaultColumn

                # Avoid PSScriptAnalyzer PSUseDeclaredVarsMoreThanAssignments
                $column = $column
            }

            $null = Remove-GitHubProjectColumn -Column $column.id -Confirm:$false
            It 'Project column should be removed' {
                {Get-GitHubProjectColumn -Column $column.id} | Should Throw
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