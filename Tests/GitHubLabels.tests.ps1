# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

<#
.Synopsis
   Tests for GitHubLabels.ps1 module
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

    Describe 'Getting labels from a repository' {
        BeforeAll {
            $repositoryName = [Guid]::NewGuid().Guid
            $repo = New-GitHubRepository -RepositoryName $script:repositoryName

            Set-GitHubLabel -OwnerName $script:ownerName -RepositoryName $script:repositoryName -Label $defaultLabels
        }

        AfterAll {
            $repo | Remove-GitHubRepository -Force
        }

        Context 'When querying for all labels' {
            $labels = @(Get-GitHubLabel -OwnerName $ownerName -RepositoryName $repositoryName)

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

        Context 'When querying for all labels (via repo on pipeline)' {
            $labels = @($repo | Get-GitHubLabel)

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
                    $label.PSObject.TypeNames[0] | Should -Not -Be 'GitHub.Label'
                    $label.RepositoryUrl | Should -BeNullOrEmpty
                    $label.LabelId | Should -BeNullOrEmpty
                    $label.LabelName | Should -BeNullOrEmpty
                }
            }
        }

        Context 'When querying for a specific label' {
            $labelName = 'bug'
            $label = Get-GitHubLabel -OwnerName $script:ownerName -RepositoryName $script:repositoryName -Label $labelName

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
            $labelName = 'bug'
            $label = $repo | Get-GitHubLabel -Label $labelName

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

        Context 'When querying for a specific label (via name on pipeline)' {
            $labelName = 'bug'
            $label = $labelName | Get-GitHubLabel -OwnerName $script:ownerName -RepositoryName $script:repositoryName

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
    }

    Describe 'Creating a new label' {
        BeforeAll {
            $repositoryName = [Guid]::NewGuid().Guid
            $repo = New-GitHubRepository -RepositoryName $script:repositoryName
        }

        AfterAll {
            $repo | Remove-GitHubRepository -Force
        }

        Context 'On a repo with parameters' {
            $labelName = [Guid]::NewGuid().Guid
            $color = 'AAAAAA'
            $label = New-GitHubLabel -OwnerName $script:ownerName -RepositoryName $script:repositoryName -Label $labelName -Color $color

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
            $labelName = [Guid]::NewGuid().Guid
            $color = '#AAAAAA'
            $label = New-GitHubLabel -OwnerName $script:ownerName -RepositoryName $script:repositoryName -Label $labelName -Color $color

            It 'New label should be created' {
                $label.name | Should -Be $labelName
                $label.color | Should -Be $color.Substring(1)
                $label.description | Should -BeNullOrEmpty
            }

            It 'Should have the expected type and additional properties' {
                $result.PSObject.TypeNames[0] | Should -Be 'GitHub.Label'
                $result.RepositoryUrl | Should -Be $repo.RepositoryUrl
                $result.LabelId | Should -Be $result.id
                $result.LabelName | Should -Be $result.name
            }
        }

        Context 'On a repo with the repo on the pipeline' {
            $labelName = [Guid]::NewGuid().Guid
            $color = 'BBBBBB'
            $description = 'test description'
            $label = $repo | New-GitHubLabel -Label $labelName -Color $color -Description $description

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
            $labelName = [Guid]::NewGuid().Guid
            $color = 'CCCCCC'
            $label = $labelName | New-GitHubLabel -OwnerName $script:ownerName -RepositoryName $script:repositoryName -Color $color

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
    }

    Describe 'Removing a label' {
        BeforeAll {
            $repositoryName = [Guid]::NewGuid().Guid
            $repo = New-GitHubRepository -RepositoryName $script:repositoryName
        }

        AfterAll {
            $repo | Remove-GitHubRepository -Force
        }

        BeforeEach {
            $label = $repo | New-GitHubLabel -Label 'test' -Color 'CCCCCC'
        }

        Context 'Removing a label with parameters' {
            Remove-GitHubLabel -OwnerName $script:ownerName -RepositoryName $script:repositoryName -Label $label.name -Force

            It 'Should be gone after being removed by parameter' {
                { $label | Get-GitHubLabel } | Should -Throw
            }
        }

        Context 'Removing a label with the repo on the pipeline' {
            $repo | Remove-GitHubLabel -Label $label.name -Confirm:$false

            It 'Should be gone after being removed by parameter' {
                { $label | Get-GitHubLabel } | Should -Throw
            }
        }

        Context 'Removing a label with the name on the pipeline' {
            $label.name | Remove-GitHubLabel -OwnerName $script:ownerName -RepositoryName $script:repositoryName -Force

            It 'Should be gone after being removed by parameter' {
                { $label | Get-GitHubLabel } | Should -Throw
            }
        }
    }

    Describe 'Updating a label' {
        BeforeAll {
            $repositoryName = [Guid]::NewGuid().Guid
            $repo = New-GitHubRepository -RepositoryName $script:repositoryName
        }

        AfterAll {
            $repo | Remove-GitHubRepository -Force
        }

        Context 'Updating label color with parameters' {
            $label = $repo | New-GitHubLabel -Label ([Guid]::NewGuid().Guid) -Color 'BBBBBB'

            $newColor = 'AAAAAA'
            $result = Update-GitHubLabel -OwnerName $script:ownerName -RepositoryName $script:repositoryName -Label $label.name -Color $newColor

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
            $label = $repo | New-GitHubLabel -Label ([Guid]::NewGuid().Guid) -Color 'BBBBBB'

            $newColor = '#AAAAAA'
            $result = Update-GitHubLabel -OwnerName $script:ownerName -RepositoryName $script:repositoryName -Label $label.name -Color $newColor

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
            $label = $repo | New-GitHubLabel -Label ([Guid]::NewGuid().Guid) -Color 'BBBBBB'

            $newName = [Guid]::NewGuid().Guid
            $result = Update-GitHubLabel -OwnerName $script:ownerName -RepositoryName $script:repositoryName -Label $label.name -NewName $newName

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
            $label = $repo | New-GitHubLabel -Label ([Guid]::NewGuid().Guid) -Color 'BBBBBB' -Description 'test description'

            $newDescription = [Guid]::NewGuid().Guid
            $result = Update-GitHubLabel -OwnerName $script:ownerName -RepositoryName $script:repositoryName -Label $label.name -Description $newDescription

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
            $label = $repo | New-GitHubLabel -Label ([Guid]::NewGuid().Guid) -Color 'BBBBBB' -Description 'test description'

            $newName = [Guid]::NewGuid().Guid
            $newColor = 'AAAAAA'
            $newDescription = [Guid]::NewGuid().Guid
            $result = Update-GitHubLabel -OwnerName $script:ownerName -RepositoryName $script:repositoryName -Label $label.name -NewName $newName -Color $newColor -Description $newDescription

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
            $label = $repo | New-GitHubLabel -Label ([Guid]::NewGuid().Guid) -Color 'BBBBBB'

            $newColor = 'AAAAAA'
            $result = $repo | Update-GitHubLabel -Label $label.name -Color $newColor

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
            $label = $repo | New-GitHubLabel -Label ([Guid]::NewGuid().Guid) -Color 'BBBBBB'

            $newName = [Guid]::NewGuid().Guid
            $result = $label | Update-GitHubLabel -NewName $newName

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
            $label = $repo | New-GitHubLabel -Label ([Guid]::NewGuid().Guid) -Color 'BBBBBB' -Description 'test description'

            $newName = [Guid]::NewGuid().Guid
            $newColor = 'AAAAAA'
            $newDescription = [Guid]::NewGuid().Guid
            $result = $label | Update-GitHubLabel -NewName $newName -Color $newColor -Description $newDescription

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
            $repo = New-GitHubRepository -RepositoryName $script:repositoryName
        }

        AfterAll {
            $repo | Remove-GitHubRepository -Force
        }

        Context 'Applying a default set of labels' {
            Set-GitHubLabel -OwnerName $script:ownerName -RepositoryName $script:repositoryName -Label $defaultLabels

            $labels = @($repo | Get-GitHubLabel)

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
            $newLabels = @(
                @{ 'name' = $defaultLabels[0].name; 'color' = 'aaaaaa' },
                @{ 'name' = $defaultLabels[1].name; 'color' = 'bbbbbb' }
                @{ 'name' = $defaultLabels[2].name; 'color' = $defaultLabels[2].color }
                @{ 'name' = ([Guid]::NewGuid().Guid); 'color' = 'cccccc' }
                @{ 'name' = ([Guid]::NewGuid().Guid); 'color' = 'dddddd' }
            )

            $originalLabels = @($repo | Get-GitHubLabel)
            $null = $repo | Set-GitHubLabel -Label $newLabels
            $labels = @($repo | Get-GitHubLabel)

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
                $originalLabel = $originalLabels | Where-Object { $_.name -eq $newLabels[0].name }
                $label = $labels | Where-Object { $_.name -eq $newLabels[0].name }
                $label.id | Should -Be $originalLabel.id

                $originalLabel = $originalLabels | Where-Object { $_.name -eq $newLabels[1] }
                $label = $labels | Where-Object { $_.name -eq $newLabels[1].name }
                $label.id | Should -Be $originalLabel.id

                $originalLabel = $originalLabels | Where-Object { $_.name -eq $newLabels[2] }
                $label = $labels | Where-Object { $_.name -eq $newLabels[2].name }
                $label.id | Should -Be $originalLabel.id

                $originalLabel = $originalLabels | Where-Object { $_.name -eq $newLabels[3] }
                $label = $labels | Where-Object { $_.name -eq $newLabels[3].name }
                $originalLabel | Should -BeNullOrEmpty
                $label | Should -Not -BeNullOrEmpty

                $originalLabel = $originalLabels | Where-Object { $_.name -eq $newLabels[4] }
                $label = $labels | Where-Object { $_.name -eq $newLabels[4].name }
                $originalLabel | Should -BeNullOrEmpty
                $label | Should -Not -BeNullOrEmpty
            }
        }

    }

    Describe 'Adding labels to an issue'{
        BeforeAll {
            $repositoryName = [Guid]::NewGuid().Guid
            $repo = New-GitHubRepository -RepositoryName $script:repositoryName
            $repo | Set-GitHubLabel -Label $defaultLabels
        }

        AfterAll {
            $repo | Remove-GitHubRepository -Force
        }

        Context 'Adding labels to an issue' {
            $expectedLabels = @($defaultLabels[0].name, $defaultLabels[1].name, $defaultLabels[3].name)
            $issue = $repo | New-GitHubIssue -Title 'test issue'
            $result = @(Add-GitHubIssueLabel -OwnerName $script:ownerName -RepositoryName $script:repositoryName -Issue $issue.number -LabelName $expectedLabels)

            It 'Should return the number of labels that were just added' {
                $result.Count | Should -Be $expectedLabels.Count
            }

            It 'Should be the right set of labels' {
                foreach ($label in $expectedLabels)
                {
                    $result | Should -Contant $label
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

            $issueLabels = Get-GitHubLabel -OwnerName $ownerName -RepositoryName $repositoryName -Issue $issue.number

            It 'Should return the number of labels that were just added from querying the issue again' {
                $issueLabels.Count | Should -Be $defaultLabels.Count
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
            $expectedLabels = @($defaultLabels[0].name, $defaultLabels[1].name, $defaultLabels[3].name)
            $issue = $repo | New-GitHubIssue -Title 'test issue'
            $result = @($repo | Add-GitHubIssueLabel -Issue $issue.number -LabelName $expectedLabels)

            It 'Should return the number of labels that were just added' {
                $result.Count | Should -Be $expectedLabels.Count
            }

            It 'Should be the right set of labels' {
                foreach ($label in $expectedLabels)
                {
                    $result | Should -Contant $label
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

            $issueLabels = $repo | Get-GitHubLabel -Issue $issue.number

            It 'Should return the number of labels that were just added from querying the issue again' {
                $issueLabels.Count | Should -Be $defaultLabels.Count
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
            $expectedLabels = @($defaultLabels[0].name, $defaultLabels[1].name, $defaultLabels[3].name)
            $issue = $repo | New-GitHubIssue -Title 'test issue'
            $result = @($issue | Add-GitHubIssueLabel -LabelName $expectedLabels)

            It 'Should return the number of labels that were just added' {
                $result.Count | Should -Be $expectedLabels.Count
            }

            It 'Should be the right set of labels' {
                foreach ($label in $expectedLabels)
                {
                    $result | Should -Contant $label
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

            $issueLabels = $issue | Get-GitHubLabel

            It 'Should return the number of labels that were just added from querying the issue again' {
                $issueLabels.Count | Should -Be $defaultLabels.Count
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

        Context 'Adding labels to an issue with the labels on the pipeline' {
            $expectedLabels = @($defaultLabels[0].name, $defaultLabels[1].name, $defaultLabels[3].name)
            $issue = $repo | New-GitHubIssue -Title 'test issue'
            $result = @($expectedLabels | Add-GitHubIssueLabel -OwnerName $script:ownerName -RepositoryName $script:repositoryName -Issue $issue.number)

            It 'Should return the number of labels that were just added' {
                $result.Count | Should -Be $expectedLabels.Count
            }

            It 'Should be the right set of labels' {
                foreach ($label in $expectedLabels)
                {
                    $result | Should -Contant $label
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

            $issueLabels = $issue | Get-GitHubLabel

            It 'Should return the number of labels that were just added from querying the issue again' {
                $issueLabels.Count | Should -Be $defaultLabels.Count
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
            $repo = New-GitHubRepository -RepositoryName $script:repositoryName
            $repo | Set-GitHubLabel -Label $defaultLabels
        }

        AfterAll {
            $repo | Remove-GitHubRepository -Force
        }

        Context 'When creating a new issue using parameters' {
            $issueName = [Guid]::NewGuid().Guid
            $issueLabels = @($defaultLabels[0].name, $defaultLabels[1].name)
            $issue = New-GitHubIssue -OwnerName $script:ownerName -RepositoryName $script:repositoryName -Title $issueName -Label $issueLabels

            It 'Should return the number of labels that were just added' {
                $issue.labels.Count | Should -Be $issueLabels.Count
            }

            It 'Should be the right set of labels' {
                foreach ($label in $issueLabels)
                {
                    $issue.labels.name | Should -Contain $issueLabel
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
            $issueName = [Guid]::NewGuid().Guid
            $issueLabels = @($defaultLabels[0].name, $defaultLabels[1].name)
            $issue = $repo | New-GitHubIssue -Title $issueName -Label $issueLabels

            It 'Should return the number of labels that were just added' {
                $issue.labels.Count | Should -Be $issueLabels.Count
            }

            It 'Should be the right set of labels' {
                foreach ($label in $issueLabels)
                {
                    $issue.labels.name | Should -Contain $issueLabel
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
            $repo = New-GitHubRepository -RepositoryName $script:repositoryName
            $repo | Set-GitHubLabel -Label $defaultLabels
        }

        AfterAll {
            $repo | Remove-GitHubRepository -Force
        }

        Context 'For removing an individual issue with parameters' {
            $issueName = [Guid]::NewGuid().Guid
            $issue = $repo | New-GitHubIssue -Title $issueName

            $labelsToAdd = @($defaultLabels[0].name, $defaultLabels[1].name, $defaultLabels[2].name)
            $issue | Add-GitHubIssueLabel -LabelName $labelsToAdd

            $issueLabels = @($issue | Get-GitHubLabel)
            It 'Should have the expected number of labels' {
                $issueLabels.Count | Should -Be $labelsToAdd.Count
            }

            # Doing this manually instead of in a loop to try out different combinations of -Confirm:$false and -Force
            Remove-GitHubIssueLabel -OwnerName $script:ownerName -RepositoryName $script:repositoryName -Label $labelsToAdd[0] -Issue $issue.number -Confirm:$false
            Remove-GitHubIssueLabel -OwnerName $script:ownerName -RepositoryName $script:repositoryName -Label $labelsToAdd[1] -Issue $issue.number -Force
            Remove-GitHubIssueLabel -OwnerName $script:ownerName -RepositoryName $script:repositoryName -Label $labelsToAdd[2] -Issue $issue.number -Confirm:$false -Force

            $issueLabels = @($issue | Get-GitHubLabel)
            It 'Should have removed all labels from the issue' {
                $issueLabels.Count | Should -Be 0
            }
        }

        Context 'For removing an individual issue using the repo on the pipeline' {
            $issueName = [Guid]::NewGuid().Guid
            $issue = $repo | New-GitHubIssue -Title $issueName

            $labelsToAdd = @($defaultLabels[0].name, $defaultLabels[1].name, $defaultLabels[2].name, $defaultLabels[3].name)
            $issue | Add-GitHubIssueLabel -LabelName $labelsToAdd

            $issueLabels = @($issue | Get-GitHubLabel)
            It 'Should have the expected number of labels' {
                $issueLabels.Count | Should -Be $labelsToAdd.Count
            }

            $labelToRemove = $labelsToAdd[0]
            $repo | Remove-GitHubIssueLabel -Label $labelToRemove -Issue $issue.number -Confirm:$false

            $issueLabels = @($issue | Get-GitHubLabel)
            It 'Should have removed the expected label from the issue' {
                $issueLabels.Count | Should -Be ($issueLables - 1)
                $issueLabels.name | Should -Not -Contain $labelToRemove
            }
        }

        Context 'For removing an individual issue using the issue on the pipeline' {
            $issueName = [Guid]::NewGuid().Guid
            $issue = $repo | New-GitHubIssue -Title $issueName

            $labelsToAdd = @($defaultLabels[0].name, $defaultLabels[1].name, $defaultLabels[2].name, $defaultLabels[3].name)
            $issue | Add-GitHubIssueLabel -LabelName $labelsToAdd

            $issueLabels = @($issue | Get-GitHubLabel)
            It 'Should have the expected number of labels' {
                $issueLabels.Count | Should -Be $labelsToAdd.Count
            }

            $labelToRemove = $labelsToAdd[1]
            $issue | Remove-GitHubIssueLabel -Label $labelToRemove -Confirm:$false

            $issueLabels = @($issue | Get-GitHubLabel)
            It 'Should have removed the expected label from the issue' {
                $issueLabels.Count | Should -Be ($issueLables - 1)
                $issueLabels.name | Should -Not -Contain $labelToRemove
            }
        }

        Context 'For removing an individual issue using the label name on the pipeline' {
            $issueName = [Guid]::NewGuid().Guid
            $issue = $repo | New-GitHubIssue -Title $issueName

            $labelsToAdd = @($defaultLabels[0].name, $defaultLabels[1].name, $defaultLabels[2].name, $defaultLabels[3].name)
            $issue | Add-GitHubIssueLabel -LabelName $labelsToAdd

            $issueLabels = @($issue | Get-GitHubLabel)
            It 'Should have the expected number of labels' {
                $issueLabels.Count | Should -Be $labelsToAdd.Count
            }

            $labelToRemove = $labelsToAdd[2]
            $labelToRemove | Remove-GitHubIssueLabel  -OwnerName $script:ownerName -RepositoryName $script:repositoryName -Issue $issue.number -Confirm:$false

            $issueLabels = @($issue | Get-GitHubLabel)
            It 'Should have removed the expected label from the issue' {
                $issueLabels.Count | Should -Be ($issueLables - 1)
                $issueLabels.name | Should -Not -Contain $labelToRemove
            }
        }

        Context 'For removing an individual issue using the label object on the pipeline' {
            $issueName = [Guid]::NewGuid().Guid
            $issue = $repo | New-GitHubIssue -Title $issueName

            $labelsToAdd = @($defaultLabels[0].name, $defaultLabels[1].name, $defaultLabels[2].name, $defaultLabels[3].name)
            $issue | Add-GitHubIssueLabel -LabelName $labelsToAdd

            $issueLabels = @($issue | Get-GitHubLabel)
            It 'Should have the expected number of labels' {
                $issueLabels.Count | Should -Be $labelsToAdd.Count
            }

            $labelToRemove = $labelsToAdd[0]
            $label = $repo | Get-GitHubLabel -Label $labelToRemove
            $label | Remove-GitHubIssueLabel -Issue $issue.number -Confirm:$false

            $issueLabels = @($issue | Get-GitHubLabel)
            It 'Should have removed the expected label from the issue' {
                $issueLabels.Count | Should -Be ($issueLables - 1)
                $issueLabels.name | Should -Not -Contain $labelToRemove
            }
        }

        Context 'For removing all issues' {
            $issueName = [Guid]::NewGuid().Guid
            $issue = $repo | New-GitHubIssue -Title $issueName

            $labelsToAdd = @($defaultLabels[0].name, $defaultLabels[1].name, $defaultLabels[2].name, $defaultLabels[3].name)
            $issue | Add-GitHubIssueLabel -LabelName $labelsToAdd

            $issueLabels = @($issue | Get-GitHubLabel)
            It 'Should have the expected number of labels' {
                $issueLabels.Count | Should -Be $labelsToAdd.Count
            }

            $issue | Remove-GitHubIssueLabel -Confirm:$false

            $issueLabels = @($issue | Get-GitHubLabel)
            It 'Should have removed all labels from the issue' {
                $issueLabels.Count | Should -Be 0
            }
        }
    }

    Describe 'Replacing labels on an issue'{
        BeforeAll {
            $repositoryName = [Guid]::NewGuid().Guid
            $repo = New-GitHubRepository -RepositoryName $script:repositoryName
            $repo | Set-GitHubLabel -Label $defaultLabels
        }

        AfterAll {
            $repo | Remove-GitHubRepository -Force
        }

        Context 'Change the set of labels with parameters' {
            $labelsToAdd = @($defaultLabels[0].name, $defaultLabels[1].name)
            $issue = $repo | New-GitHubIssue -Title ([Guid]::NewGuid().Guid) -Label $labelsToAdd

            It 'Should have assigned the expected labels' {
                $issue.labels.Count | Should -Be $labelsToAdd.Count
                foreach ($label in $labelsToAdd)
                {
                    $issue.labels | Should -Contain $label
                }
            }

            $newIssueLabels = @($defaultLabels[0].name, $defaultLabels[5].name)
            $result = @(Set-GitHubIssueLabel -OwnerName $script:ownerName -RepositoryName $script:repositoryName -Issue $issue.number -Label $newIssueLabels)

            It 'Should have the expected labels' {
                $result.labels.Count | Should -Be $newIssueLabels.Count
                foreach ($label in $newIssueLabels)
                {
                    $result.labels | Should -Contain $label
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
            $labelsToAdd = @($defaultLabels[0].name, $defaultLabels[1].name)
            $issue = $repo | New-GitHubIssue -Title ([Guid]::NewGuid().Guid) -Label $labelsToAdd

            It 'Should have assigned the expected labels' {
                $issue.labels.Count | Should -Be $labelsToAdd.Count
                foreach ($label in $labelsToAdd)
                {
                    $issue.labels | Should -Contain $label
                }
            }

            $newIssueLabels = @($defaultLabels[0].name, $defaultLabels[5].name)
            $result = @($repo | Set-GitHubIssueLabel -Issue $issue.number -Label $newIssueLabels)

            It 'Should have the expected labels' {
                $result.labels.Count | Should -Be $newIssueLabels.Count
                foreach ($label in $newIssueLabels)
                {
                    $result.labels | Should -Contain $label
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
            $labelsToAdd = @($defaultLabels[0].name, $defaultLabels[1].name)
            $issue = $repo | New-GitHubIssue -Title ([Guid]::NewGuid().Guid) -Label $labelsToAdd

            It 'Should have assigned the expected labels' {
                $issue.labels.Count | Should -Be $labelsToAdd.Count
                foreach ($label in $labelsToAdd)
                {
                    $issue.labels | Should -Contain $label
                }
            }

            $newIssueLabels = @($defaultLabels[0].name, $defaultLabels[5].name)
            $result = @($issue | Set-GitHubIssueLabel -Label $newIssueLabels)

            It 'Should have the expected labels' {
                $result.labels.Count | Should -Be $newIssueLabels.Count
                foreach ($label in $newIssueLabels)
                {
                    $result.labels | Should -Contain $label
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
            $labelsToAdd = @($defaultLabels[0].name, $defaultLabels[1].name)
            $issue = $repo | New-GitHubIssue -Title ([Guid]::NewGuid().Guid) -Label $labelsToAdd

            It 'Should have assigned the expected labels' {
                $issue.labels.Count | Should -Be $labelsToAdd.Count
                foreach ($label in $labelsToAdd)
                {
                    $issue.labels | Should -Contain $label
                }
            }

            $newIssueLabels = @($defaultLabels[0].name, $defaultLabels[5].name)
            $result = @($newIssueLabels | Set-GitHubIssueLabel -OwnerName $script:ownerName -RepositoryName $script:repositoryName -Issue $issue.number)

            It 'Should have the expected labels' {
                $result.labels.Count | Should -Be $newIssueLabels.Count
                foreach ($label in $newIssueLabels)
                {
                    $result.labels | Should -Contain $label
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
