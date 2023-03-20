# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

<#
.Synopsis
   Tests for GitHubProjectColumns.ps1 module
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
        defaultColumnUpdate = "TestColumn_Updated"
    }.GetEnumerator() | ForEach-Object {
        Set-Variable -Force -Scope Script -Option ReadOnly -Visibility Private -Name $_.Key -Value $_.Value
    }

    $project = New-GitHubProject -UserProject -ProjectName $defaultProject
#>
}

Describe 'Getting Project Columns' -Skip {
    BeforeAll {
        $column = New-GitHubProjectColumn -Project $project.id -ColumnName $defaultColumn
    }

    AfterAll {
        $null = Remove-GitHubProjectColumn -Column $column.id -Confirm:$false
    }

    Context 'Get columns for a project' {
        BeforeAll {
            $results = @(Get-GitHubProjectColumn -Project $project.id)
        }

        It 'Should get column' {
            $results | Should -Not -BeNullOrEmpty
        }

        It 'Should only have one column' {
            $results.Count | Should -Be 1
        }

        It 'Name is correct' {
            $results[0].name | Should -Be $defaultColumn
        }

        It 'Should have the expected type and additional properties' {
            $results[0].PSObject.TypeNames[0] | Should -Be 'GitHub.ProjectColumn'
            $results[0].ColumnId | Should -Be $results[0].id
            $results[0].ColumnName | Should -Be $results[0].name
            $results[0].ProjectId | Should -Be $project.id
        }
    }

    Context 'Get columns for a project (via pipeline)' {
        BeforeAll {
            $results = @($project | Get-GitHubProjectColumn)
        }

        It 'Should get column' {
            $results | Should -Not -BeNullOrEmpty
        }

        It 'Should only have one column' {
            $results.Count | Should -Be 1
        }

        It 'Name is correct' {
            $results[0].name | Should -Be $defaultColumn
        }

        It 'Should have the expected type and additional properties' {
            $results[0].PSObject.TypeNames[0] | Should -Be 'GitHub.ProjectColumn'
            $results[0].ColumnId | Should -Be $results[0].id
            $results[0].ColumnName | Should -Be $results[0].name
            $results[0].ProjectId | Should -Be $project.id
        }
    }

    Context 'Get specific column' {
        BeforeAll {
            $result = Get-GitHubProjectColumn -Column $column.id
        }

        It 'Should be the right column' {
            $result.id | Should -Be $column.id
        }

        It 'Should have the expected type and additional properties' {
            $result.PSObject.TypeNames[0] | Should -Be 'GitHub.ProjectColumn'
            $result.ColumnId | Should -Be $result.id
            $result.ColumnName | Should -Be $result.name
            $result.ProjectId | Should -Be $project.id
        }
    }

    Context 'Get specific column (via pipeline)' {
        BeforeAll {
            $result = $column | Get-GitHubProjectColumn
        }

        It 'Should be the right column' {
            $result.id | Should -Be $column.id
        }

        It 'Should have the expected type and additional properties' {
            $result.PSObject.TypeNames[0] | Should -Be 'GitHub.ProjectColumn'
            $result.ColumnId | Should -Be $result.id
            $result.ColumnName | Should -Be $result.name
            $result.ProjectId | Should -Be $project.id
        }
    }
}

Describe 'Modify Project Column' -Skip {
    BeforeAll {
        $column = New-GitHubProjectColumn -Project $project.id -ColumnName $defaultColumn
        $columntwo = New-GitHubProjectColumn -Project $project.id -ColumnName $defaultColumnTwo
    }

    AfterAll {
        $null = Remove-GitHubProjectColumn -Column $column.id -Confirm:$false
        $null = Remove-GitHubProjectColumn -Column $columntwo.id -Confirm:$false
    }

    Context 'Modify column name' {
        BeforeAll {
            Set-GitHubProjectColumn -Column $column.id -ColumnName $defaultColumnUpdate
            $result = Get-GitHubProjectColumn -Column $column.id
        }

        It 'Should get column' {
            $result | Should -Not -BeNullOrEmpty
        }

        It 'Name has been updated' {
            $result.name | Should -Be $defaultColumnUpdate
        }

        It 'Should have the expected type and additional properties' {
            $result.PSObject.TypeNames[0] | Should -Be 'GitHub.ProjectColumn'
            $result.ColumnId | Should -Be $result.id
            $result.ColumnName | Should -Be $result.name
            $result.ProjectId | Should -Be $project.id
        }
    }

    Context 'Move column to first position' {
        BeforeAll {
            $null = Move-GitHubProjectColumn -Column $columntwo.id -First
            $results = @(Get-GitHubProjectColumn -Project $project.id)
        }

        It 'Should still have more than one column in the project' {
            $results.Count | Should -Be 2
        }

        It 'Column is now in the first position' {
            $results[0].name | Should -Be $defaultColumnTwo
        }

        It 'Should have the expected type and additional properties' {
            $results[0].PSObject.TypeNames[0] | Should -Be 'GitHub.ProjectColumn'
            $results[0].ColumnId | Should -Be $results[0].id
            $results[0].ColumnName | Should -Be $results[0].name
            $results[0].ProjectId | Should -Be $project.id
        }
    }

    Context 'Move column using after parameter' {
        BeforeAll {
            $null = Move-GitHubProjectColumn -Column $columntwo.id -After $column.id
            $results = @(Get-GitHubProjectColumn -Project $project.id)
        }

        It 'Column is now not in the first position' {
            $results[1].name | Should -Be $defaultColumnTwo
        }

        It 'Should have the expected type and additional properties' {
            $results[1].PSObject.TypeNames[0] | Should -Be 'GitHub.ProjectColumn'
            $results[1].ColumnId | Should -Be $columntwo.ColumnId
            $results[1].ColumnName | Should -Be $columntwo.ColumnName
            $results[1].ProjectId | Should -Be $project.id
        }
    }

    Context 'Move command throws appropriate error' {
        It 'Expected error returned' {
            { Move-GitHubProjectColumn -Column $column.id -First -Last } | Should -Throw 'You must use one (and only one) of the parameters First, Last or After.'
        }
    }
}

Describe 'Create Project Column' -Skip {
    Context 'Create project column' {
        BeforeAll {
            $column = @{id = 0 }

            $column.id = (New-GitHubProjectColumn -Project $project.id -ColumnName $defaultColumn).id
            $result = Get-GitHubProjectColumn -Column $column.id
        }

        AfterAll {
            $null = Remove-GitHubProjectColumn -Column $column.id -Force
            Remove-Variable -Name column
        }

        It 'Column exists' {
            $result | Should -Not -BeNullOrEmpty
        }

        It 'Name is correct' {
            $result.name | Should -Be $defaultColumn
        }

        It 'Should have the expected type and additional properties' {
            $result.PSObject.TypeNames[0] | Should -Be 'GitHub.ProjectColumn'
            $result.ColumnId | Should -Be $result.id
            $result.ColumnName | Should -Be $result.name
            $result.ProjectId | Should -Be $project.id
        }
    }

    Context 'Create project column (object via pipeline)' {
        BeforeAll {
            $column = @{id = 0 }

            $column.id = ($project | New-GitHubProjectColumn -ColumnName $defaultColumn).id
            $result = Get-GitHubProjectColumn -Column $column.id
        }

        AfterAll {
            $null = Remove-GitHubProjectColumn -Column $column.id -Force
            Remove-Variable -Name column
        }

        It 'Column exists' {
            $result | Should -Not -BeNullOrEmpty
        }

        It 'Name is correct' {
            $result.name | Should -Be $defaultColumn
        }

        It 'Should have the expected type and additional properties' {
            $result.PSObject.TypeNames[0] | Should -Be 'GitHub.ProjectColumn'
            $result.ColumnId | Should -Be $result.id
            $result.ColumnName | Should -Be $result.name
            $result.ProjectId | Should -Be $project.id
        }
    }

    Context 'Create project column (name via pipeline)' {
        BeforeAll {
            $column = @{id = 0 }

            $column.id = ($defaultColumn | New-GitHubProjectColumn -Project $project.id).id
            $result = Get-GitHubProjectColumn -Column $column.id
        }

        AfterAll {
            $null = Remove-GitHubProjectColumn -Column $column.id -Force
            Remove-Variable -Name column
        }

        It 'Column exists' {
            $result | Should -Not -BeNullOrEmpty
        }

        It 'Name is correct' {
            $result.name | Should -Be $defaultColumn
        }

        It 'Should have the expected type and additional properties' {
            $result.PSObject.TypeNames[0] | Should -Be 'GitHub.ProjectColumn'
            $result.ColumnId | Should -Be $result.id
            $result.ColumnName | Should -Be $result.name
            $result.ProjectId | Should -Be $project.id
        }
    }
}

Describe 'Remove project column' -Skip {
    Context 'Remove project column' {
        BeforeAll {
            $column = New-GitHubProjectColumn -Project $project.id -ColumnName $defaultColumn
            $null = Remove-GitHubProjectColumn -Column $column.id -Confirm:$false
        }

        It 'Project column should be removed' {
            { Get-GitHubProjectColumn -Column $column.id } | Should -Throw
        }
    }

    Context 'Remove project column (via pipeline)' {
        BeforeAll {
            $column = New-GitHubProjectColumn -Project $project.id -ColumnName $defaultColumn
            $column | Remove-GitHubProjectColumn -Force
        }

        It 'Project column should be removed' {
            { $column | Get-GitHubProjectColumn } | Should -Throw
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
