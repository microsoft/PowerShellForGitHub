# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

<#
.Synopsis
   Tests for GitHubLabels.ps1 module
#>

[CmdletBinding()]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '',
    Justification = 'Suppress false positives in Pester code blocks')]
param()

BeforeAll {
    # This is common test code setup logic for all Pester test files
    $moduleRootPath = Split-Path -Path $PSScriptRoot -Parent
    . (Join-Path -Path $moduleRootPath -ChildPath 'Tests\Common.ps1')

    $defaultLabels = @(
        @{
            'name' = 'pri:lowest'
            'color' = '4285F4'
        },
        @{
            'name' = 'pri:low'
            'color' = '4285F4'
        },
        @{
            'name' = 'pri:medium'
            'color' = '4285F4'
        },
        @{
            'name' = 'pri:high'
            'color' = '4285F4'
        },
        @{
            'name' = 'pri:highest'
            'color' = '4285F4'
        },
        @{
            'name' = 'bug'
            'color' = 'fc2929'
        },
        @{
            'name' = 'duplicate'
            'color' = 'cccccc'
        },
        @{
            'name' = 'enhancement'
            'color' = '121459'
        },
        @{
            'name' = 'up for grabs'
            'color' = '159818'
        },
        @{
            'name' = 'question'
            'color' = 'cc317c'
        },
        @{
            'name' = 'discussion'
            'color' = 'fe9a3d'
        },
        @{
            'name' = 'wontfix'
            'color' = 'dcb39c'
        },
        @{
            'name' = 'in progress'
            'color' = 'f0d218'
        },
        @{
            'name' = 'ready'
            'color' = '145912'
        }
    )
}

Describe 'Getting labels from a repository' {
    BeforeAll {
        $repositoryName = [Guid]::NewGuid().Guid
        $repo = New-GitHubRepository -RepositoryName $repositoryName
        Initialize-GitHubLabel -OwnerName $script:ownerName -RepositoryName $repositoryName -Label $defaultLabels
    }

    AfterAll {
        $repo | Remove-GitHubRepository -Force
    }

    Context 'Querying all labels' {
        BeforeAll {
            $labels = @(Get-GitHubLabel -OwnerName $script:ownerName -RepositoryName $repositoryName)
        }


        Context 'When querying for all labels' {
            It 'Should return expected number of labels' {
                $labels.Count | Should -Be $defaultLabels.Count
            }

            It 'Should have the expected type and additional properties' {
                foreach ($label in $labels)
                {
                    $label.PSObject.TypeNames[0] | Should -Be 'GitHub.Label'
                    $label.RepositoryUrl | Should -Be $repo.RepositoryUrl
                    $label.LabelId | Should -Be $label.id
                    $label.LabelName | Should -Be $label.name
                }
            }
        }
    }

    Context 'When querying for all labels (via repo on pipeline)' {
        BeforeAll {
            $labels = @($repo | Get-GitHubLabel)
        }

        It 'Should return expected number of labels' {
            $labels.Count | Should -Be $defaultLabels.Count
        }

        It 'Should have the expected type and additional properties' {
            foreach ($label in $labels)
            {
                $label.PSObject.TypeNames[0] | Should -Be 'GitHub.Label'
                $label.RepositoryUrl | Should -Be $repo.RepositoryUrl
                $label.LabelId | Should -Be $label.id
                $label.LabelName | Should -Be $label.name
            }
        }
    }

    Context 'When pipeline properties are disabled' {
        BeforeAll {
            Set-GitHubConfiguration -DisablePipelineSupport
            $labels = @($repo | Get-GitHubLabel)
        }

        AfterAll {
            Set-GitHubConfiguration -DisablePipelineSupport:$false
        }

        It 'Should return expected number of labels' {
            $labels.Count | Should -Be $defaultLabels.Count
        }

        It 'Should have the expected type and additional properties' {
            foreach ($label in $labels)
            {
                $label.PSObject.TypeNames[0] | Should -Be 'GitHub.Label'
                $label.RepositoryUrl | Should -BeNullOrEmpty
                $label.LabelId | Should -BeNullOrEmpty
                $label.LabelName | Should -BeNullOrEmpty
            }
        }
    }

    Context 'When querying for a specific label' {
        BeforeAll {
            $labelName = 'bug'
            $label = Get-GitHubLabel -OwnerName $script:ownerName -RepositoryName $repositoryName -Label $labelName
        }

        It 'Should return expected label' {
            $label.name | Should -Be $labelName
        }

        It 'Should have the expected type and additional properties' {
            $label.PSObject.TypeNames[0] | Should -Be 'GitHub.Label'
            $label.RepositoryUrl | Should -Be $repo.RepositoryUrl
            $label.LabelId | Should -Be $label.id
            $label.LabelName | Should -Be $label.name
        }
    }

    Context 'When querying for a specific label (via repo on pipeline)' {
        BeforeAll {
            $labelName = 'bug'
            $label = $repo | Get-GitHubLabel -Label $labelName
        }

        It 'Should return expected label' {
            $label.name | Should -Be $labelName
        }

        It 'Should have the expected type and additional properties' {
            $label.PSObject.TypeNames[0] | Should -Be 'GitHub.Label'
            $label.RepositoryUrl | Should -Be $repo.RepositoryUrl
            $label.LabelId | Should -Be $label.id
            $label.LabelName | Should -Be $label.name
        }
    }

    # TODO: This test has been disabled until we can figure out how to fix the parameter sets
    # for Get-GitHubLabel pipelining to still support Label this way.
    #
    # Context 'When querying for a specific label (via Label on pipeline)' {
    #     BeforeAll {
    #     $labelName = 'bug'
    #     $label = $labelName | Get-GitHubLabel -OwnerName $script:ownerName -RepositoryName $repositoryName
    #     }

    #     It 'Should return expected label' {
    #         $label.name | Should -Be $labelName
    #     }

    #     It 'Should have the expected type and additional properties' {
    #         $label.PSObject.TypeNames[0] | Should -Be 'GitHub.Label'
    #         $label.RepositoryUrl | Should -Be $repo.RepositoryUrl
    #         $label.LabelId | Should -Be $label.id
    #         $label.LabelName | Should -Be $label.name
    #     }
    # }
}

Describe 'Creating a new label' {
    BeforeAll {
        $repositoryName = [Guid]::NewGuid().Guid
        $repo = New-GitHubRepository -RepositoryName $repositoryName
    }

    AfterAll {
        $repo | Remove-GitHubRepository -Force
    }

    Context 'On a repo with parameters' {
        BeforeAll {
            $labelName = [Guid]::NewGuid().Guid
            $color = 'AAAAAA'
            $label = New-GitHubLabel -OwnerName $script:ownerName -RepositoryName $repositoryName -Label $labelName -Color $color
        }

        It 'New label should be created' {
            $label.name | Should -Be $labelName
            $label.color | Should -Be $color
        }

        It 'Should have the expected type and additional properties' {
            $label.PSObject.TypeNames[0] | Should -Be 'GitHub.Label'
            $label.RepositoryUrl | Should -Be $repo.RepositoryUrl
            $label.LabelId | Should -Be $label.id
            $label.LabelName | Should -Be $label.name
        }
    }

    Context 'On a repo with and color starts with a #' {
        BeforeAll {
            $labelName = [Guid]::NewGuid().Guid
            $color = '#AAAAAA'
            $label = New-GitHubLabel -OwnerName $script:ownerName -RepositoryName $repositoryName -Label $labelName -Color $color
        }

        It 'New label should be created' {
            $label.name | Should -Be $labelName
            $label.color | Should -Be $color.Substring(1)
            $label.description | Should -BeNullOrEmpty
        }

        It 'Should have the expected type and additional properties' {
            $label.PSObject.TypeNames[0] | Should -Be 'GitHub.Label'
            $label.RepositoryUrl | Should -Be $repo.RepositoryUrl
            $label.LabelId | Should -Be $label.id
            $label.LabelName | Should -Be $label.name
        }
    }

    Context 'On a repo with the repo on the pipeline' {
        BeforeAll {
            $labelName = [Guid]::NewGuid().Guid
            $color = 'BBBBBB'
            $description = 'test description'
            $label = $repo | New-GitHubLabel -Label $labelName -Color $color -Description $description
        }

        It 'New label should be created' {
            $label.name | Should -Be $labelName
            $label.color | Should -Be $color
            $label.description | Should -Be $description
        }

        It 'Should have the expected type and additional properties' {
            $label.PSObject.TypeNames[0] | Should -Be 'GitHub.Label'
            $label.RepositoryUrl | Should -Be $repo.RepositoryUrl
            $label.LabelId | Should -Be $label.id
            $label.LabelName | Should -Be $label.name
        }
    }

    Context 'On a repo with the name on the pipeline' {
        BeforeAll {
            $labelName = [Guid]::NewGuid().Guid
            $color = 'CCCCCC'
            $label = $labelName | New-GitHubLabel -OwnerName $script:ownerName -RepositoryName $repositoryName -Color $color
        }

        It 'New label should be created' {
            $label.name | Should -Be $labelName
            $label.color | Should -Be $color
        }

        It 'Should have the expected type and additional properties' {
            $label.PSObject.TypeNames[0] | Should -Be 'GitHub.Label'
            $label.RepositoryUrl | Should -Be $repo.RepositoryUrl
            $label.LabelId | Should -Be $label.id
            $label.LabelName | Should -Be $label.name
        }
    }

    Context 'On a repo with three names on the pipeline' {
        BeforeAll {
            $labelNames = @(([Guid]::NewGuid().Guid), ([Guid]::NewGuid().Guid), ([Guid]::NewGuid().Guid))
            $color = 'CCCCCC'
            $labels = @($labelNames | New-GitHubLabel -OwnerName $script:ownerName -RepositoryName $repositoryName -Color $color)
        }

        It 'Has the right count of labels' {
            $labels.Count | Should -Be $labelNames.Count
        }

        It 'Has the right label details' {
            foreach ($label in $labels)
            {
                $labelNames | Should -Contain $label.name
                $label.color | Should -Be $color
            }
        }

        It 'Should have the expected type and additional properties' {
            foreach ($label in $labels)
            {
                $label.PSObject.TypeNames[0] | Should -Be 'GitHub.Label'
                $label.RepositoryUrl | Should -Be $repo.RepositoryUrl
                $label.LabelId | Should -Be $label.id
                $label.LabelName | Should -Be $label.name
            }
        }
    }
}

Describe 'Removing a label' {
    BeforeAll {
        $repositoryName = [Guid]::NewGuid().Guid
        $repo = New-GitHubRepository -RepositoryName $repositoryName
    }

    AfterAll {
        $repo | Remove-GitHubRepository -Force
    }

    Context 'Removing a label with parameters' {

        It 'Should be gone after being removed by parameter' {
            $label = $repo | New-GitHubLabel -Label 'test' -Color 'CCCCCC'
            Remove-GitHubLabel -OwnerName $script:ownerName -RepositoryName $repositoryName -Label $label.name -Force
            { $label | Get-GitHubLabel } | Should -Throw
        }
    }

    Context 'Removing a label with the repo on the pipeline' {

        It 'Should be gone after being removed by parameter' {
            $label = $repo | New-GitHubLabel -Label 'test' -Color 'CCCCCC'
            $repo | Remove-GitHubLabel -Label $label.name -Confirm:$false
            { $label | Get-GitHubLabel } | Should -Throw
        }
    }

    Context 'Removing a label with the name on the pipeline' {

        It 'Should be gone after being removed by parameter' {
            $label = $repo | New-GitHubLabel -Label 'test' -Color 'CCCCCC'
            $label.name | Remove-GitHubLabel -OwnerName $script:ownerName -RepositoryName $repositoryName -Force
            { $label | Get-GitHubLabel } | Should -Throw
        }
    }

    Context 'Removing a label with the label object on the pipeline' {

        It 'Should be gone after being removed by parameter' {
            $label = $repo | New-GitHubLabel -Label 'test' -Color 'CCCCCC'
            $label | Remove-GitHubLabel -Force
            { $label | Get-GitHubLabel } | Should -Throw
        }
    }
}

Describe 'Updating a label' {
    BeforeAll {
        $repositoryName = [Guid]::NewGuid().Guid
        $repo = New-GitHubRepository -RepositoryName $repositoryName
    }

    AfterAll {
        $repo | Remove-GitHubRepository -Force
    }

    Context 'Updating label color with parameters' {
        BeforeAll {
            $label = $repo | New-GitHubLabel -Label ([Guid]::NewGuid().Guid) -Color 'BBBBBB'

            $newColor = 'AAAAAA'
            $result = Set-GitHubLabel -OwnerName $script:ownerName -RepositoryName $repositoryName -Label $label.name -Color $newColor -PassThru
        }

        It 'Label should have different color' {
            $result.name | Should -Be $label.name
            $result.color | Should -Be $newColor
            $result.description | Should -Be $label.description
        }

        It 'Should have the expected type and additional properties' {
            $result.PSObject.TypeNames[0] | Should -Be 'GitHub.Label'
            $result.RepositoryUrl | Should -Be $repo.RepositoryUrl
            $result.LabelId | Should -Be $result.id
            $result.LabelName | Should -Be $result.name
        }
    }

    Context 'Updating label color (with #) with parameters' {
        BeforeAll {
            $label = $repo | New-GitHubLabel -Label ([Guid]::NewGuid().Guid) -Color 'BBBBBB'

            $newColor = '#AAAAAA'
            $result = Set-GitHubLabel -OwnerName $script:ownerName -RepositoryName $repositoryName -Label $label.name -Color $newColor -PassThru
        }

        It 'Label should have different color' {
            $result.name | Should -Be $label.name
            $result.color | Should -Be $newColor.Substring(1)
            $result.description | Should -Be $label.description
        }

        It 'Should have the expected type and additional properties' {
            $result.PSObject.TypeNames[0] | Should -Be 'GitHub.Label'
            $result.RepositoryUrl | Should -Be $repo.RepositoryUrl
            $result.LabelId | Should -Be $result.id
            $result.LabelName | Should -Be $result.name
        }
    }

    Context 'Updating label name with parameters' {
        BeforeAll {
            $label = $repo | New-GitHubLabel -Label ([Guid]::NewGuid().Guid) -Color 'BBBBBB'

            $newName = [Guid]::NewGuid().Guid
            $result = Set-GitHubLabel -OwnerName $script:ownerName -RepositoryName $repositoryName -Label $label.name -NewName $newName -PassThru
        }

        It 'Label should have different name' {
            $result.name | Should -Be $newName
            $result.color | Should -Be $label.color
            $result.description | Should -Be $label.description
        }

        It 'Should have the expected type and additional properties' {
            $result.PSObject.TypeNames[0] | Should -Be 'GitHub.Label'
            $result.RepositoryUrl | Should -Be $repo.RepositoryUrl
            $result.LabelId | Should -Be $result.id
            $result.LabelName | Should -Be $result.name
        }
    }

    Context 'Updating label description with parameters' {
        BeforeAll {
            $label = $repo | New-GitHubLabel -Label ([Guid]::NewGuid().Guid) -Color 'BBBBBB' -Description 'test description'

            $newDescription = [Guid]::NewGuid().Guid
            $result = Set-GitHubLabel -OwnerName $script:ownerName -RepositoryName $repositoryName -Label $label.name -Description $newDescription -PassThru
        }

        It 'Label should have different name' {
            $result.name | Should -Be $label.name
            $result.color | Should -Be $label.color
            $result.description | Should -Be $newDescription
        }

        It 'Should have the expected type and additional properties' {
            $result.PSObject.TypeNames[0] | Should -Be 'GitHub.Label'
            $result.RepositoryUrl | Should -Be $repo.RepositoryUrl
            $result.LabelId | Should -Be $result.id
            $result.LabelName | Should -Be $result.name
        }
    }

    Context 'Updating label name, color and description with parameters' {
        BeforeAll {
            $label = $repo | New-GitHubLabel -Label ([Guid]::NewGuid().Guid) -Color 'BBBBBB' -Description 'test description'

            $newName = [Guid]::NewGuid().Guid
            $newColor = 'AAAAAA'
            $newDescription = [Guid]::NewGuid().Guid
            $result = Set-GitHubLabel -OwnerName $script:ownerName -RepositoryName $repositoryName -Label $label.name -NewName $newName -Color $newColor -Description $newDescription -PassThru
        }

        It 'Label should have different everything' {
            $result.name | Should -Be $newName
            $result.color | Should -Be $newColor
            $result.description | Should -Be $newDescription
        }

        It 'Should have the expected type and additional properties' {
            $result.PSObject.TypeNames[0] | Should -Be 'GitHub.Label'
            $result.RepositoryUrl | Should -Be $repo.RepositoryUrl
            $result.LabelId | Should -Be $result.id
            $result.LabelName | Should -Be $result.name
        }


    }

    Context 'Updating label color with repo on the pipeline' {
        BeforeAll {
            $label = $repo | New-GitHubLabel -Label ([Guid]::NewGuid().Guid) -Color 'BBBBBB'

            $newColor = 'AAAAAA'
            $result = $repo | Set-GitHubLabel -Label $label.name -Color $newColor -PassThru
        }

        It 'Label should have different color' {
            $result.name | Should -Be $label.name
            $result.color | Should -Be $newColor
            $result.description | Should -Be $label.description
        }

        It 'Should have the expected type and additional properties' {
            $result.PSObject.TypeNames[0] | Should -Be 'GitHub.Label'
            $result.RepositoryUrl | Should -Be $repo.RepositoryUrl
            $result.LabelId | Should -Be $result.id
            $result.LabelName | Should -Be $result.name
        }
    }

    Context 'Updating label name with the label on the pipeline' {
        BeforeAll {
            $label = $repo | New-GitHubLabel -Label ([Guid]::NewGuid().Guid) -Color 'BBBBBB'

            $newName = [Guid]::NewGuid().Guid
            $result = $label | Set-GitHubLabel -NewName $newName -PassThru
        }

        It 'Label should have different name' {
            $result.name | Should -Be $newName
            $result.color | Should -Be $label.color
            $result.description | Should -Be $label.description
        }

        It 'Should have the expected type and additional properties' {
            $result.PSObject.TypeNames[0] | Should -Be 'GitHub.Label'
            $result.RepositoryUrl | Should -Be $repo.RepositoryUrl
            $result.LabelId | Should -Be $result.id
            $result.LabelName | Should -Be $result.name
        }
    }

    Context 'Updating label name, color and description with the label on the pipeline' {
        BeforeAll {
            $label = $repo | New-GitHubLabel -Label ([Guid]::NewGuid().Guid) -Color 'BBBBBB' -Description 'test description'

            $newName = [Guid]::NewGuid().Guid
            $newColor = 'AAAAAA'
            $newDescription = [Guid]::NewGuid().Guid
            $result = $label | Set-GitHubLabel -NewName $newName -Color $newColor -Description $newDescription -PassThru
        }

        It 'Label should have different everything' {
            $result.name | Should -Be $newName
            $result.color | Should -Be $newColor
            $result.description | Should -Be $newDescription
        }

        It 'Should have the expected type and additional properties' {
            $result.PSObject.TypeNames[0] | Should -Be 'GitHub.Label'
            $result.RepositoryUrl | Should -Be $repo.RepositoryUrl
            $result.LabelId | Should -Be $result.id
            $result.LabelName | Should -Be $result.name
        }
    }
}

Describe 'Initializing the labels on a repository' {
    BeforeAll {
        $repositoryName = [Guid]::NewGuid().Guid
        $repo = New-GitHubRepository -RepositoryName $repositoryName
    }

    AfterAll {
        $repo | Remove-GitHubRepository -Force
    }

    Context 'Applying a default set of labels' {
        BeforeAll {
            Initialize-GitHubLabel -OwnerName $script:ownerName -RepositoryName $repositoryName -Label $defaultLabels

            $labels = @($repo | Get-GitHubLabel)
        }

        It 'Should return the expected number of labels' {
            $labels.Count | Should -Be $defaultLabels.Count
        }

        It 'Should have the right set of labels' {
            foreach ($item in $defaultLabels)
            {
                $label = $labels | Where-Object { $_.name -eq $item.name }
                $item.name | Should -Be $label.name
                $item.color | Should -Be $label.color
            }
        }
    }

    Context 'Applying an overlapping set of labels' {
        BeforeAll {
            $newLabels = @(
                @{ 'name' = $defaultLabels[0].name; 'color' = 'aaaaaa' },
                @{ 'name' = $defaultLabels[1].name; 'color' = 'bbbbbb' }
                @{ 'name' = $defaultLabels[2].name; 'color' = $defaultLabels[2].color }
                @{ 'name' = ([Guid]::NewGuid().Guid); 'color' = 'cccccc' }
                @{ 'name' = ([Guid]::NewGuid().Guid); 'color' = 'dddddd' }
            )

            $originalLabels = @($repo | Get-GitHubLabel)
            $null = $repo | Initialize-GitHubLabel -Label $newLabels
            $labels = @($repo | Get-GitHubLabel)
        }

        It 'Should return the expected number of labels' {
            $labels.Count | Should -Be $newLabels.Count
        }

        It 'Should have the right set of labels' {
            foreach ($item in $newLabels)
            {
                $label = $labels | Where-Object { $_.name -eq $item.name }
                $item.name | Should -Be $label.name
                $item.color | Should -Be $label.color
            }
        }

        It 'Should have retained the ID''s of the pre-existing labels' {
            for ($i = 0; $i -le 2; $i++)
            {
                $originalLabel = $originalLabels | Where-Object { $_.name -eq $newLabels[$i].name }
                $label = $labels | Where-Object { $_.name -eq $newLabels[$i].name }
                $label.id | Should -Be $originalLabel.id
            }

            for ($i = 3; $i -le 4; $i++)
            {
                $originalLabel = $originalLabels | Where-Object { $_.name -eq $newLabels[$i].name }
                $label = $labels | Where-Object { $_.name -eq $newLabels[$i].name }
                $originalLabel | Should -BeNullOrEmpty
                $label | Should -Not -BeNullOrEmpty
            }
        }
    }
}

Describe 'Adding labels to an issue' {
    BeforeAll {
        $repositoryName = [Guid]::NewGuid().Guid
        $repo = New-GitHubRepository -RepositoryName $repositoryName
        $repo | Initialize-GitHubLabel -Label $defaultLabels
    }

    AfterAll {
        $repo | Remove-GitHubRepository -Force
    }

    Context 'Adding labels to an issue' {
        BeforeAll {
            $expectedLabels = @($defaultLabels[0].name, $defaultLabels[1].name, $defaultLabels[3].name)
            $issue = $repo | New-GitHubIssue -Title 'test issue'
            $result = @(Add-GitHubIssueLabel -OwnerName $script:ownerName -RepositoryName $repositoryName -Issue $issue.number -LabelName $expectedLabels -PassThru)
            $issueLabels = Get-GitHubLabel -OwnerName $ownerName -RepositoryName $repositoryName -Issue $issue.number
        }

        It 'Should return the number of labels that were just added' {
            $result.Count | Should -Be $expectedLabels.Count
        }

        It 'Should be the right set of labels' {
            foreach ($label in $expectedLabels)
            {
                $result.name | Should -Contain $label
            }
        }

        It 'Should have the expected type and additional properties' {
            foreach ($label in $result)
            {
                $label.PSObject.TypeNames[0] | Should -Be 'GitHub.Label'
                $label.RepositoryUrl | Should -Be $repo.RepositoryUrl
                $label.LabelId | Should -Be $label.id
                $label.LabelName | Should -Be $label.name
            }
        }

        It 'Should return the number of labels that were just added from querying the issue again' {
            $issueLabels.Count | Should -Be $expectedLabels.Count
        }

        It 'Should have the expected type and additional properties' {
            foreach ($label in $issueLabels)
            {
                $label.PSObject.TypeNames[0] | Should -Be 'GitHub.Label'
                $label.RepositoryUrl | Should -Be $repo.RepositoryUrl
                $label.LabelId | Should -Be $label.id
                $label.LabelName | Should -Be $label.name
            }
        }
    }

    Context 'Adding labels to an issue with the repo on the pipeline' {
        BeforeAll {
            $expectedLabels = @($defaultLabels[0].name, $defaultLabels[1].name, $defaultLabels[3].name)
            $issue = $repo | New-GitHubIssue -Title 'test issue'
            $result = @($repo | Add-GitHubIssueLabel -Issue $issue.number -LabelName $expectedLabels -PassThru)
            $issueLabels = $repo | Get-GitHubLabel -Issue $issue.number
        }

        It 'Should return the number of labels that were just added' {
            $result.Count | Should -Be $expectedLabels.Count
        }

        It 'Should be the right set of labels' {
            foreach ($label in $expectedLabels)
            {
                $result.name | Should -Contain $label
            }
        }

        It 'Should have the expected type and additional properties' {
            foreach ($label in $result)
            {
                $label.PSObject.TypeNames[0] | Should -Be 'GitHub.Label'
                $label.RepositoryUrl | Should -Be $repo.RepositoryUrl
                $label.LabelId | Should -Be $label.id
                $label.LabelName | Should -Be $label.name
            }
        }

        It 'Should return the number of labels that were just added from querying the issue again' {
            $issueLabels.Count | Should -Be $expectedLabels.Count
        }

        It 'Should have the expected type and additional properties' {
            foreach ($label in $issueLabels)
            {
                $label.PSObject.TypeNames[0] | Should -Be 'GitHub.Label'
                $label.RepositoryUrl | Should -Be $repo.RepositoryUrl
                $label.LabelId | Should -Be $label.id
                $label.LabelName | Should -Be $label.name
            }
        }
    }

    Context 'Adding labels to an issue with the issue on the pipeline' {
        BeforeAll {
            $expectedLabels = @($defaultLabels[0].name, $defaultLabels[1].name, $defaultLabels[3].name)
            $issue = $repo | New-GitHubIssue -Title 'test issue'
            $result = @($issue | Add-GitHubIssueLabel -LabelName $expectedLabels -PassThru)
            $issueLabels = $issue | Get-GitHubLabel
        }

        It 'Should return the number of labels that were just added' {
            $result.Count | Should -Be $expectedLabels.Count
        }

        It 'Should be the right set of labels' {
            foreach ($label in $expectedLabels)
            {
                $result.name | Should -Contain $label
            }
        }

        It 'Should have the expected type and additional properties' {
            foreach ($label in $result)
            {
                $label.PSObject.TypeNames[0] | Should -Be 'GitHub.Label'
                $label.RepositoryUrl | Should -Be $repo.RepositoryUrl
                $label.LabelId | Should -Be $label.id
                $label.LabelName | Should -Be $label.name
            }
        }

        It 'Should return the number of labels that were just added from querying the issue again' {
            $issueLabels.Count | Should -Be $expectedLabels.Count
        }

        It 'Should have the expected type and additional properties' {
            foreach ($label in $issueLabels)
            {
                $label.PSObject.TypeNames[0] | Should -Be 'GitHub.Label'
                $label.RepositoryUrl | Should -Be $repo.RepositoryUrl
                $label.LabelId | Should -Be $label.id
                $label.LabelName | Should -Be $label.name
            }
        }
    }

    Context 'Adding labels to an issue with the label names on the pipeline' {
        BeforeAll {
            $expectedLabels = @($defaultLabels[0].name, $defaultLabels[1].name, $defaultLabels[3].name)
            $issue = $repo | New-GitHubIssue -Title 'test issue'
            $result = @($expectedLabels | Add-GitHubIssueLabel -OwnerName $script:ownerName -RepositoryName $repositoryName -Issue $issue.number -PassThru)
            $issueLabels = $issue | Get-GitHubLabel
        }

        It 'Should return the number of labels that were just added' {
            $result.Count | Should -Be $expectedLabels.Count
        }

        It 'Should be the right set of labels' {
            foreach ($label in $expectedLabels)
            {
                $result.name | Should -Contain $label
            }
        }

        It 'Should have the expected type and additional properties' {
            foreach ($label in $result)
            {
                $label.PSObject.TypeNames[0] | Should -Be 'GitHub.Label'
                $label.RepositoryUrl | Should -Be $repo.RepositoryUrl
                $label.LabelId | Should -Be $label.id
                $label.LabelName | Should -Be $label.name
            }
        }

        It 'Should return the number of labels that were just added from querying the issue again' {
            $issueLabels.Count | Should -Be $expectedLabels.Count
        }

        It 'Should have the expected type and additional properties' {
            foreach ($label in $issueLabels)
            {
                $label.PSObject.TypeNames[0] | Should -Be 'GitHub.Label'
                $label.RepositoryUrl | Should -Be $repo.RepositoryUrl
                $label.LabelId | Should -Be $label.id
                $label.LabelName | Should -Be $label.name
            }
        }
    }

    Context 'Adding labels to an issue with the label object on the pipeline' {
        BeforeAll {
            $expectedLabels = @($defaultLabels[0].name, $defaultLabels[1].name, $defaultLabels[3].name)
            $issue = $repo | New-GitHubIssue -Title 'test issue'
            $labels = @($expectedLabels | ForEach-Object { Get-GitHubLabel -OwnerName $script:ownerName -RepositoryName $repositoryName -Label $_ } )
            $result = @($labels | Add-GitHubIssueLabel -OwnerName $script:ownerName -RepositoryName $repositoryName -Issue $issue.number -PassThru)
            $issueLabels = $issue | Get-GitHubLabel
        }

        It 'Should return the number of labels that were just added' {
            $result.Count | Should -Be $expectedLabels.Count
        }

        It 'Should be the right set of labels' {
            foreach ($label in $expectedLabels)
            {
                $result.name | Should -Contain $label
            }
        }

        It 'Should have the expected type and additional properties' {
            foreach ($label in $result)
            {
                $label.PSObject.TypeNames[0] | Should -Be 'GitHub.Label'
                $label.RepositoryUrl | Should -Be $repo.RepositoryUrl
                $label.LabelId | Should -Be $label.id
                $label.LabelName | Should -Be $label.name
            }
        }

        It 'Should return the number of labels that were just added from querying the issue again' {
            $issueLabels.Count | Should -Be $expectedLabels.Count
        }

        It 'Should have the expected type and additional properties' {
            foreach ($label in $issueLabels)
            {
                $label.PSObject.TypeNames[0] | Should -Be 'GitHub.Label'
                $label.RepositoryUrl | Should -Be $repo.RepositoryUrl
                $label.LabelId | Should -Be $label.id
                $label.LabelName | Should -Be $label.name
            }
        }
    }
}

Describe 'Creating a new Issue with labels' {
    BeforeAll {
        $repositoryName = [Guid]::NewGuid().Guid
        $repo = New-GitHubRepository -RepositoryName $repositoryName
        $repo | Initialize-GitHubLabel -Label $defaultLabels
    }

    AfterAll {
        $repo | Remove-GitHubRepository -Force
    }

    Context 'When creating a new issue using parameters' {
        BeforeAll {
            $issueName = [Guid]::NewGuid().Guid
            $issueLabels = @($defaultLabels[0].name, $defaultLabels[1].name)
            $issue = New-GitHubIssue -OwnerName $script:ownerName -RepositoryName $repositoryName -Title $issueName -Label $issueLabels
        }

        It 'Should return the number of labels that were just added' {
            $issue.labels.Count | Should -Be $issueLabels.Count
        }

        It 'Should be the right set of labels' {
            foreach ($label in $issueLabels)
            {
                $issue.labels.name | Should -Contain $label
            }
        }

        It 'Should have the expected type and additional properties' {
            foreach ($label in $issue.labels)
            {
                $label.PSObject.TypeNames[0] | Should -Be 'GitHub.Label'
                $label.RepositoryUrl | Should -Be $repo.RepositoryUrl
                $label.LabelId | Should -Be $label.id
                $label.LabelName | Should -Be $label.name
            }
        }
    }

    Context 'When creating a new issue using the repo on the pipeline' {
        BeforeAll {
            $issueName = [Guid]::NewGuid().Guid
            $issueLabels = @($defaultLabels[0].name, $defaultLabels[1].name)
            $issue = $repo | New-GitHubIssue -Title $issueName -Label $issueLabels
        }

        It 'Should return the number of labels that were just added' {
            $issue.labels.Count | Should -Be $issueLabels.Count
        }

        It 'Should be the right set of labels' {
            foreach ($label in $issueLabels)
            {
                $issue.labels.name | Should -Contain $label
            }
        }

        It 'Should have the expected type and additional properties' {
            foreach ($label in $issue.labels)
            {
                $label.PSObject.TypeNames[0] | Should -Be 'GitHub.Label'
                $label.RepositoryUrl | Should -Be $repo.RepositoryUrl
                $label.LabelId | Should -Be $label.id
                $label.LabelName | Should -Be $label.name
            }
        }
    }
}

Describe 'Removing labels on an issue' {
    BeforeAll {
        $repositoryName = [Guid]::NewGuid().Guid
        $repo = New-GitHubRepository -RepositoryName $repositoryName
        $repo | Initialize-GitHubLabel -Label $defaultLabels
    }

    AfterAll {
        $repo | Remove-GitHubRepository -Force
    }

    Context 'For removing an individual issue with parameters' {
        BeforeAll {
            $issueName = [Guid]::NewGuid().Guid
            $issue = $repo | New-GitHubIssue -Title $issueName

            $labelsToAdd = @($defaultLabels[0].name, $defaultLabels[1].name, $defaultLabels[2].name)
            $issue | Add-GitHubIssueLabel -LabelName $labelsToAdd -PassThru

            $issueLabels = @($issue | Get-GitHubLabel)
        }

        It 'Should have the expected number of labels' {
            $issueLabels.Count | Should -Be $labelsToAdd.Count
        }

        It 'Should have removed all labels from the issue' {
            # Doing this manually instead of in a loop to try out different combinations of -Confirm:$false and -Force
            Remove-GitHubIssueLabel -OwnerName $script:ownerName -RepositoryName $repositoryName -Label $labelsToAdd[0] -Issue $issue.number -Confirm:$false
            Remove-GitHubIssueLabel -OwnerName $script:ownerName -RepositoryName $repositoryName -Label $labelsToAdd[1] -Issue $issue.number -Force
            Remove-GitHubIssueLabel -OwnerName $script:ownerName -RepositoryName $repositoryName -Label $labelsToAdd[2] -Issue $issue.number -Confirm:$false -Force

            $issueLabels = @($issue | Get-GitHubLabel)
            $issueLabels.Count | Should -Be 0
        }
    }

    Context 'For removing an individual issue using the repo on the pipeline' {
        BeforeAll {
            $issueName = [Guid]::NewGuid().Guid
            $issue = $repo | New-GitHubIssue -Title $issueName

            $labelsToAdd = @($defaultLabels[0].name, $defaultLabels[1].name, $defaultLabels[2].name, $defaultLabels[3].name)
            $issue | Add-GitHubIssueLabel -LabelName $labelsToAdd -PassThru

            $issueLabels = @($issue | Get-GitHubLabel)
        }

        It 'Should have the expected number of labels' {
            $issueLabels.Count | Should -Be $labelsToAdd.Count
        }

        It 'Should have removed the expected label from the issue' {
            $labelToRemove = $labelsToAdd[0]
            $repo | Remove-GitHubIssueLabel -Label $labelToRemove -Issue $issue.number -Confirm:$false

            $issueLabels = @($issue | Get-GitHubLabel)
            $issueLabels.Count | Should -Be ($labelsToAdd.Count - 1)
            $issueLabels.name | Should -Not -Contain $labelToRemove
        }
    }

    Context 'For removing an individual issue using the issue on the pipeline' {
        BeforeAll {
            $issueName = [Guid]::NewGuid().Guid
            $issue = $repo | New-GitHubIssue -Title $issueName

            $labelsToAdd = @($defaultLabels[0].name, $defaultLabels[1].name, $defaultLabels[2].name, $defaultLabels[3].name)
            $issue | Add-GitHubIssueLabel -LabelName $labelsToAdd -PassThru

            $issueLabels = @($issue | Get-GitHubLabel)
        }

        It 'Should have the expected number of labels' {
            $issueLabels.Count | Should -Be $labelsToAdd.Count
        }

        It 'Should have removed the expected label from the issue' {
            $labelToRemove = $labelsToAdd[1]
            $issue | Remove-GitHubIssueLabel -Label $labelToRemove -Confirm:$false

            $issueLabels = @($issue | Get-GitHubLabel)
            $issueLabels.Count | Should -Be ($labelsToAdd.Count - 1)
            $issueLabels.name | Should -Not -Contain $labelToRemove
        }
    }

    # TODO: This has been disabled for now, as ValueFromPipeline has been disabled until we
    # sort out some complication issues with the ParameterSets
    #
    # Context 'For removing an individual issue using the label name on the pipeline' {
    #    BeforeAll {
    #     $issueName = [Guid]::NewGuid().Guid
    #     $issue = $repo | New-GitHubIssue -Title $issueName

    #     $labelsToAdd = @($defaultLabels[0].name, $defaultLabels[1].name, $defaultLabels[2].name, $defaultLabels[3].name)
    #     $issue | Add-GitHubIssueLabel -LabelName $labelsToAdd -PassThru

    #     $issueLabels = @($issue | Get-GitHubLabel)}
    #     It 'Should have the expected number of labels' {
    #         $issueLabels.Count | Should -Be $labelsToAdd.Count
    #     }

    #     It 'Should have removed the expected label from the issue' {
    #     $labelToRemove = $labelsToAdd[2]
    #     $labelToRemove | Remove-GitHubIssueLabel  -OwnerName $script:ownerName -RepositoryName $repositoryName -Issue $issue.number -Confirm:$false

    #     $issueLabels = @($issue | Get-GitHubLabel)
    #         $issueLabels.Count | Should -Be ($labelsToAdd.Count - 1)
    #         $issueLabels.name | Should -Not -Contain $labelToRemove
    #     }
    # }

    Context 'For removing an individual issue using the label object on the pipeline' {
        BeforeAll {
            $issueName = [Guid]::NewGuid().Guid
            $issue = $repo | New-GitHubIssue -Title $issueName

            $labelsToAdd = @($defaultLabels[0].name, $defaultLabels[1].name, $defaultLabels[2].name, $defaultLabels[3].name)
            $issue | Add-GitHubIssueLabel -LabelName $labelsToAdd -PassThru

            $issueLabels = @($issue | Get-GitHubLabel)
        }
        It 'Should have the expected number of labels' {
            $issueLabels.Count | Should -Be $labelsToAdd.Count
        }

        It 'Should have removed the expected label from the issue' {
            $labelToRemove = $labelsToAdd[0]
            $label = $repo | Get-GitHubLabel -Label $labelToRemove
            $label | Remove-GitHubIssueLabel -Issue $issue.number -Confirm:$false

            $issueLabels = @($issue | Get-GitHubLabel)
            $issueLabels.Count | Should -Be ($labelsToAdd.Count - 1)
            $issueLabels.name | Should -Not -Contain $labelToRemove
        }
    }

    Context 'For removing all issues' {
        BeforeAll {
            $issueName = [Guid]::NewGuid().Guid
            $issue = $repo | New-GitHubIssue -Title $issueName

            $labelsToAdd = @($defaultLabels[0].name, $defaultLabels[1].name, $defaultLabels[2].name, $defaultLabels[3].name)
            $issue | Add-GitHubIssueLabel -LabelName $labelsToAdd -PassThru

            $issueLabels = @($issue | Get-GitHubLabel)
        }

        It 'Should have the expected number of labels' {
            $issueLabels.Count | Should -Be $labelsToAdd.Count
        }

        It 'Should have removed all labels from the issue' {
            $issue | Remove-GitHubIssueLabel -Confirm:$false

            $issueLabels = @($issue | Get-GitHubLabel)
            $issueLabels.Count | Should -Be 0
        }
    }

    Context 'For removing all issues using Set-GitHubIssueLabel with the Issue on the pipeline' {
        BeforeAll {
            $issueName = [Guid]::NewGuid().Guid
            $issue = $repo | New-GitHubIssue -Title $issueName

            $labelsToAdd = @($defaultLabels[0].name, $defaultLabels[1].name, $defaultLabels[2].name, $defaultLabels[3].name)
            $issue | Add-GitHubIssueLabel -LabelName $labelsToAdd -PassThru

            $issueLabels = @($issue | Get-GitHubLabel)
        }
        It 'Should have the expected number of labels' {
            $issueLabels.Count | Should -Be $labelsToAdd.Count
        }

        It 'Should have removed all labels from the issue' {
            $issue | Set-GitHubIssueLabel -Confirm:$false

            $issueLabels = @($issue | Get-GitHubLabel)
            $issueLabels.Count | Should -Be 0
        }
    }
}

Describe 'Replacing labels on an issue' {
    BeforeAll {
        $repositoryName = [Guid]::NewGuid().Guid
        $repo = New-GitHubRepository -RepositoryName $repositoryName
        $repo | Initialize-GitHubLabel -Label $defaultLabels
    }

    AfterAll {
        $repo | Remove-GitHubRepository -Force
    }

    Context 'Change the set of labels with parameters' {
        BeforeAll {
            $labelsToAdd = @($defaultLabels[0].name, $defaultLabels[1].name)
            $issue = $repo | New-GitHubIssue -Title ([Guid]::NewGuid().Guid) -Label $labelsToAdd
            $newIssueLabels = @($defaultLabels[0].name, $defaultLabels[5].name)
            $result = @(Set-GitHubIssueLabel -OwnerName $script:ownerName -RepositoryName $repositoryName -Issue $issue.number -Label $newIssueLabels -PassThru)
        }

        It 'Should have assigned the expected labels' {
            $issue.labels.Count | Should -Be $labelsToAdd.Count
            foreach ($label in $labelsToAdd)
            {
                $issue.labels.name | Should -Contain $label
            }
        }


        It 'Should have the expected labels' {
            $result.labels.Count | Should -Be $newIssueLabels.Count
            foreach ($label in $newIssueLabels)
            {
                $result.name | Should -Contain $label
            }
        }

        It 'Should have the expected type and additional properties' {
            foreach ($label in $result)
            {
                $label.PSObject.TypeNames[0] | Should -Be 'GitHub.Label'
                $label.RepositoryUrl | Should -Be $repo.RepositoryUrl
                $label.LabelId | Should -Be $label.id
                $label.LabelName | Should -Be $label.name
            }
        }
    }

    Context 'Change the set of labels with the repo on the pipeline' {
        BeforeAll {
            $labelsToAdd = @($defaultLabels[0].name, $defaultLabels[1].name)
            $issue = $repo | New-GitHubIssue -Title ([Guid]::NewGuid().Guid) -Label $labelsToAdd
            $newIssueLabels = @($defaultLabels[0].name, $defaultLabels[5].name)
            $result = @($repo | Set-GitHubIssueLabel -Issue $issue.number -Label $newIssueLabels -PassThru)
        }

        It 'Should have assigned the expected labels' {
            $issue.labels.Count | Should -Be $labelsToAdd.Count
            foreach ($label in $labelsToAdd)
            {
                $issue.labels.name | Should -Contain $label
            }
        }

        It 'Should have the expected labels' {
            $result.labels.Count | Should -Be $newIssueLabels.Count
            foreach ($label in $newIssueLabels)
            {
                $result.name | Should -Contain $label
            }
        }

        It 'Should have the expected type and additional properties' {
            foreach ($label in $result)
            {
                $label.PSObject.TypeNames[0] | Should -Be 'GitHub.Label'
                $label.RepositoryUrl | Should -Be $repo.RepositoryUrl
                $label.LabelId | Should -Be $label.id
                $label.LabelName | Should -Be $label.name
            }
        }
    }

    Context 'Change the set of labels with the issue on the pipeline' {
        BeforeAll {
            $labelsToAdd = @($defaultLabels[0].name, $defaultLabels[1].name)
            $issue = $repo | New-GitHubIssue -Title ([Guid]::NewGuid().Guid) -Label $labelsToAdd

            $newIssueLabels = @($defaultLabels[0].name, $defaultLabels[5].name)
            $result = @($issue | Set-GitHubIssueLabel -Label $newIssueLabels -PassThru)
        }

        It 'Should have assigned the expected labels' {
            $issue.labels.Count | Should -Be $labelsToAdd.Count
            foreach ($label in $labelsToAdd)
            {
                $issue.labels.name | Should -Contain $label
            }
        }

        It 'Should have the expected labels' {
            $result.labels.Count | Should -Be $newIssueLabels.Count
            foreach ($label in $newIssueLabels)
            {
                $result.name | Should -Contain $label
            }
        }

        It 'Should have the expected type and additional properties' {
            foreach ($label in $result)
            {
                $label.PSObject.TypeNames[0] | Should -Be 'GitHub.Label'
                $label.RepositoryUrl | Should -Be $repo.RepositoryUrl
                $label.LabelId | Should -Be $label.id
                $label.LabelName | Should -Be $label.name
            }
        }
    }

    Context 'Change the set of labels with parameters with the labels on the pipeline' {
        BeforeAll {
            $labelsToAdd = @($defaultLabels[0].name, $defaultLabels[1].name)
            $issue = $repo | New-GitHubIssue -Title ([Guid]::NewGuid().Guid) -Label $labelsToAdd
            $newIssueLabelNames = @($defaultLabels[0].name, $defaultLabels[5].name)
            $issueLabels = @($newIssueLabelNames | ForEach-Object { $repo | Get-GitHubLabel -Label $_ })
            $result = @($issueLabels | Set-GitHubIssueLabel -OwnerName $script:ownerName -RepositoryName $repositoryName -Issue $issue.number -PassThru)
        }

        It 'Should have assigned the expected labels' {
            $issue.labels.Count | Should -Be $labelsToAdd.Count
            foreach ($label in $labelsToAdd)
            {
                $issue.labels.name | Should -Contain $label
            }
        }


        It 'Should have the expected labels' {
            $result.labels.Count | Should -Be $newIssueLabelNames.Count
            foreach ($label in $newIssueLabelNames)
            {
                $result.name | Should -Contain $label
            }
        }

        It 'Should have the expected type and additional properties' {
            foreach ($label in $result)
            {
                $label.PSObject.TypeNames[0] | Should -Be 'GitHub.Label'
                $label.RepositoryUrl | Should -Be $repo.RepositoryUrl
                $label.LabelId | Should -Be $label.id
                $label.LabelName | Should -Be $label.name
            }
        }
    }
}

Describe 'Labels and Milestones' {
    BeforeAll {
        $repositoryName = [Guid]::NewGuid().Guid
        $repo = New-GitHubRepository -RepositoryName $repositoryName
        $repo | Initialize-GitHubLabel -Label $defaultLabels

        $milestone = $repo | New-GitHubMilestone -Title 'test milestone'

        $issueLabels = @($defaultLabels[0].name, $defaultLabels[1].name, $defaultLabels[3].name)
        $issue = $milestone | New-GitHubIssue -Title 'test issue' -Label $issueLabels

        $issueLabels2 = @($defaultLabels[4].name, $defaultLabels[5].name)
        $issue2 = $milestone | New-GitHubIssue -Title 'test issue' -Label $issueLabels2

        $milestoneLabels = Get-GitHubLabel -OwnerName $script:ownerName -RepositoryName $repositoryName -Milestone $milestone.number
    }

    AfterAll {
        $repo | Remove-GitHubRepository -Force
    }

    Context 'Getting labels for issues in a milestone with parameters' {
        It 'Should return the number of labels that were just added to the issue' {
            $issue.labels.Count | Should -Be $issueLabels.Count
            $issue2.labels.Count | Should -Be $issueLabels2.Count
        }

        It 'Should return the same number of labels in the issue that were assigned to the milestone' {
            $milestoneLabels.Count | Should -Be ($issue.labels.Count + $issue2.labels.Count)
        }

        It 'Should be the right set of labels' {
            $allLabels = $issue.labels.name + $issue2.labels.name
            foreach ($label in $allLabels)
            {
                $milestoneLabels.name | Should -Contain $label
            }
        }

        It 'Should have the expected type and additional properties' {
            foreach ($label in $milestoneLabels)
            {
                $label.PSObject.TypeNames[0] | Should -Be 'GitHub.Label'
                $label.RepositoryUrl | Should -Be $repo.RepositoryUrl
                $label.LabelId | Should -Be $label.id
                $label.LabelName | Should -Be $label.name
            }
        }
    }

    Context 'Getting labels for issues in a milestone with the repo on the pipeline' {
        BeforeAll {
            $milestoneLabels = $repo | Get-GitHubLabel -Milestone $milestone.number
        }

        It 'Should return the number of labels that were just added to the issue' {
            $issue.labels.Count | Should -Be $issueLabels.Count
            $issue2.labels.Count | Should -Be $issueLabels2.Count
        }

        It 'Should return the same number of labels in the issues that were assigned to the milestone' {
            $milestoneLabels.Count | Should -Be ($issue.labels.Count + $issue2.labels.Count)
        }

        It 'Should be the right set of labels' {
            $allLabels = $issue.labels.name + $issue2.labels.name
            foreach ($label in $allLabels)
            {
                $milestoneLabels.name | Should -Contain $label
            }
        }

        It 'Should have the expected type and additional properties' {
            foreach ($label in $milestoneLabels)
            {
                $label.PSObject.TypeNames[0] | Should -Be 'GitHub.Label'
                $label.RepositoryUrl | Should -Be $repo.RepositoryUrl
                $label.LabelId | Should -Be $label.id
                $label.LabelName | Should -Be $label.name
            }
        }
    }

    Context 'Getting labels for issues in a milestone on the pipeline' {
        BeforeAll {
            $milestoneLabels = $milestone | Get-GitHubLabel
        }

        It 'Should return the number of labels that were just added to the issue' {
            $issue.labels.Count | Should -Be $issueLabels.Count
            $issue2.labels.Count | Should -Be $issueLabels2.Count
        }

        It 'Should return the same number of labels in the issue that is assigned to the milestone' {
            $milestoneLabels.Count | Should -Be ($issue.labels.Count + $issue2.labels.Count)
        }

        It 'Should be the right set of labels' {
            $allLabels = $issue.labels.name + $issue2.labels.name
            foreach ($label in $allLabels)
            {
                $milestoneLabels.name | Should -Contain $label
            }
        }

        It 'Should have the expected type and additional properties' {
            foreach ($label in $milestoneLabels)
            {
                $label.PSObject.TypeNames[0] | Should -Be 'GitHub.Label'
                $label.RepositoryUrl | Should -Be $repo.RepositoryUrl
                $label.LabelId | Should -Be $label.id
                $label.LabelName | Should -Be $label.name
            }
        }
    }
}

AfterAll {
    if (Test-Path -Path $script:originalConfigFile -PathType Leaf)
    {
        # Restore the user's configuration to its pre-test state
        Restore-GitHubConfiguration -Path $script:originalConfigFile
        $script:originalConfigFile = $null
    }
}
