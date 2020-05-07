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
        }
        AfterAll {
            $null = Remove-GitHubProjectColumn -Column $column.id -Confirm:$false
        }

        Context 'Get columns for a project' {
            $results = Get-GitHubProjectColumn -Project $project.id
            It 'Should get column' {
                $results | Should Not BeNullOrEmpty
            }

            It 'Name is correct' {
                $results.name | Should be $defaultColumn
            }
        }
    }

    Describe 'Modify Project Column' {
        BeforeAll {
            $column = New-GitHubProjectColumn -Project $project.id -Name $defaultColumn
            $columntwo = New-GitHubProjectColumn -Project $project.id -Name $defaultColumnTwo
        }
        AfterAll {
            $null = Remove-GitHubProjectColumn -Column $column.id -Confirm:$false
            $null = Remove-GitHubProjectColumn -Column $columntwo.id -Confirm:$false
        }

        Context 'Modify column name' {
            $null = Set-GitHubProjectColumn -Column $column.id -Name $defaultColumnUpdate
            $results = Get-GitHubProjectColumn -Column $column.id

            It 'Should get column' {
                $results | Should Not BeNullOrEmpty
            }

            It 'Name has been updated' {
                $results.name | Should be $defaultColumnUpdate
            }
        }

        Context 'Move column to first position' {
            $null = Move-GitHubProjectColumn -Column $columntwo.id -First
            $results = Get-GitHubProjectColumn -Project $project.id

            It 'Column is now in the first position' {
                $results[0].name | Should be $defaultColumnTwo
            }
        }

        Context 'Move column using after parameter' {
            $null = Move-GitHubProjectColumn -Column $columntwo.id -After $column.id
            $results = Get-GitHubProjectColumn -Project $project.id

            It 'Column is now not in the first position' {
                $results[1].name | Should be $defaultColumnTwo
            }
        }
    }

    Describe 'Create Project Column' {
        Context 'Create project column' {
            BeforeAll {
                $column = @{id = 0}
            }
            AfterAll {
                $null = Remove-GitHubProjectColumn -Column $column.id -Confirm:$false
                Remove-Variable column
            }

            $column.id = (New-GitHubProjectColumn -Project $project.id -Name $defaultColumn).id
            $results = Get-GitHubProjectColumn -Column $column.id

            It 'Column exists' {
                $results | Should Not BeNullOrEmpty
            }

            It 'Name is correct' {
                $results.name | Should be $defaultColumn
            }
        }
    }

    Describe 'Remove project column' {
        Context 'Remove project column' {
            BeforeAll {
                $column = New-GitHubProjectColumn -Project $project.id -Name $defaultColumn
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