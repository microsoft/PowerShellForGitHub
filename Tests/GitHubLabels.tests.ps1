# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

<#
.Synopsis
   Tests for GitHubLabels.ps1 module
#>

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

    if ($accessTokenConfigured)
    {
        Describe 'Getting labels from repository' {
            $repositoryName = [Guid]::NewGuid().Guid
            $null = New-GitHubRepository -RepositoryName $repositoryName
            Set-GitHubLabel -OwnerName $ownerName -RepositoryName $repositoryName -Label $defaultLabels

            Context 'When querying for all labels' {
                $labels = Get-GitHubLabel -OwnerName $ownerName -RepositoryName $repositoryName

                It 'Should return expected number of labels' {
                    $($labels).Count | Should be $:defaultLabels.Count
                }
            }

            Context 'When querying for specific label' {
                $label = Get-GitHubLabel -OwnerName $ownerName -RepositoryName $repositoryName -Name bug

                It 'Should return expected label' {
                    $label.name | Should be "bug"
                }
            }

            $null = Remove-GitHubRepository -OwnerName $ownerName -RepositoryName $repositoryName
        }

        Describe 'Creating new label' {
            $repositoryName = [Guid]::NewGuid().Guid
            $null = New-GitHubRepository -RepositoryName $repositoryName

            $labelName = [Guid]::NewGuid().Guid
            New-GitHubLabel -OwnerName $ownerName -RepositoryName $repositoryName -Name $labelName -Color BBBBBB
            $label = Get-GitHubLabel -OwnerName $ownerName -RepositoryName $repositoryName -Name $labelName

            It 'New label should be created' {
                $label.name | Should be $labelName
            }

            AfterEach {
                Remove-GitHubLabel -OwnerName $ownerName -RepositoryName $repositoryName -Name $labelName
            }

            $null = Remove-GitHubRepository -OwnerName $ownerName -RepositoryName $repositoryName
        }

        Describe 'Removing label' {
            $repositoryName = [Guid]::NewGuid().Guid
            $null = New-GitHubRepository -RepositoryName $repositoryName
            Set-GitHubLabel -OwnerName $ownerName -RepositoryName $repositoryName -Label $defaultLabels

            $labelName = [Guid]::NewGuid().Guid
            New-GitHubLabel -OwnerName $ownerName -RepositoryName $repositoryName -Name $labelName -Color BBBBBB
            $labels = Get-GitHubLabel -OwnerName $ownerName -RepositoryName $repositoryName

            It 'Should return increased number of labels' {
                $($labels).Count | Should be ($defaultLabels.Count + 1)
            }

            Remove-GitHubLabel -OwnerName $ownerName -RepositoryName $repositoryName -Name $labelName
            $labels = Get-GitHubLabel -OwnerName $ownerName -RepositoryName $repositoryName

            It 'Should return expected number of labels' {
                $($labels).Count | Should be $defaultLabels.Count
            }

            $null = Remove-GitHubRepository -OwnerName $ownerName -RepositoryName $repositoryName
        }

        Describe 'Updating label' {
            $repositoryName = [Guid]::NewGuid().Guid
            $null = New-GitHubRepository -RepositoryName $repositoryName

            $labelName = [Guid]::NewGuid().Guid

            Context 'Updating label color' {
                New-GitHubLabel -OwnerName $ownerName -RepositoryName $repositoryName -Name $labelName -Color BBBBBB
                Update-GitHubLabel -OwnerName $ownerName -RepositoryName $repositoryName -Name $labelName -NewName $labelName -Color AAAAAA
                $label = Get-GitHubLabel -OwnerName $ownerName -RepositoryName $repositoryName -Name $labelName

                AfterEach {
                    Remove-GitHubLabel -OwnerName $ownerName -RepositoryName $repositoryName -Name $labelName
                }

                It 'Label should have different color' {
                    $label.color | Should be AAAAAA
                }
            }

            Context 'Updating label name' {
                $newLabelName = $labelName + "2"
                New-GitHubLabel -OwnerName $ownerName -RepositoryName $repositoryName -Name $labelName -Color BBBBBB
                Update-GitHubLabel -OwnerName $ownerName -RepositoryName $repositoryName -Name $labelName -NewName $newLabelName -Color BBBBBB
                $label = Get-GitHubLabel -OwnerName $ownerName -RepositoryName $repositoryName -Name $newLabelName

                AfterEach {
                    Remove-GitHubLabel -OwnerName $ownerName -RepositoryName $repositoryName -Name $newLabelName
                }

                It 'Label should have different color' {
                    $label | Should not be $null
                    $label.color | Should be BBBBBB
                }
            }

            $null = Remove-GitHubRepository -OwnerName $ownerName -RepositoryName $repositoryName
        }

        Describe 'Applying set of labels on repository' {
            $repositoryName = [Guid]::NewGuid().Guid
            $null = New-GitHubRepository -RepositoryName $repositoryName

            $labelName = [Guid]::NewGuid().Guid
            Set-GitHubLabel -OwnerName $ownerName -RepositoryName $repositoryName -Label $defaultLabels

            # Add new label
            New-GitHubLabel -OwnerName $ownerName -RepositoryName $repositoryName -Name $labelName -Color BBBBBB
            $labels = Get-GitHubLabel -OwnerName $ownerName -RepositoryName $repositoryName

            # Change color of existing label
            Update-GitHubLabel -OwnerName $ownerName -RepositoryName $repositoryName -Name "bug" -NewName "bug" -Color BBBBBB

            # Remove one of approved labels"
            Remove-GitHubLabel -OwnerName $ownerName -RepositoryName $repositoryName -Name "discussion"

            It 'Should return increased number of labels' {
                $($labels).Count | Should be ($defaultLabels.Count + 1)
            }

            Set-GitHubLabel -OwnerName $ownerName -RepositoryName $repositoryName -Label $defaultLabels
            $labels = Get-GitHubLabel -OwnerName $ownerName -RepositoryName $repositoryName

            It 'Should return expected number of labels' {
                $($labels).Count | Should be $defaultLabels.Count
                $bugLabel = $labels | Where-Object {$_.name -eq "bug"}
                $bugLabel.color | Should be "fc2929"
            }

            $null = Remove-GitHubRepository -OwnerName $ownerName -RepositoryName $repositoryName
        }

        Describe 'Adding labels to an issue'{
            $repositoryName = [Guid]::NewGuid().Guid
            $null = New-GitHubRepository -RepositoryName $repositoryName
            Set-GitHubLabel -OwnerName $ownerName -RepositoryName $repositoryName -Label $defaultLabels

            $issueName = [Guid]::NewGuid().Guid
            $issue = New-GitHubIssue -OwnerName $ownerName -RepositoryName $repositoryName -Title $issueName

            Context 'Adding labels to an issue' {
                $labelsToAdd = @('pri:lowest', 'pri:low', 'pri:medium', 'pri:high', 'pri:highest', 'bug', 'duplicate',
                    'enhancement', 'up for grabs', 'question', 'discussion', 'wontfix', 'in progress', 'ready')
                $addedLabels = @(Add-GitHubIssueLabel -OwnerName $ownerName -RepositoryName $repositoryName -Issue $issue.number -LabelName $labelsToAdd)

                It 'Should return the number of labels that were just added' {
                    $addedLabels.Count | Should be $defaultLabels.Count
                }

                $labelIssues = Get-GitHubLabel -OwnerName $ownerName -RepositoryName $repositoryName -Issue $issue.number

                It 'Should return the number of labels that were just added from querying the issue again' {
                    $labelIssues.Count | Should be $defaultLabels.Count
                }
            }

            $null = Remove-GitHubRepository -OwnerName $ownerName -RepositoryName $repositoryName
        }

        Describe 'Creating a new Issue with labels' {
            $repositoryName = [Guid]::NewGuid().Guid
            $null = New-GitHubRepository -RepositoryName $repositoryName
            Set-GitHubLabel -OwnerName $ownerName -RepositoryName $repositoryName -Label $defaultLabels

            $issueName = [Guid]::NewGuid().Guid
            $issueLabels = @($defaultLabels[0].name, $defaultLabels[1].name)
            $issue = New-GitHubIssue -OwnerName $ownerName -RepositoryName $repositoryName -Title $issueName -Label $issueLabels

            It 'Should return the number of labels that were just added' {
                $issue.labels.Count | Should be $issueLabels.Count
            }

            $null = Remove-GitHubRepository -OwnerName $ownerName -RepositoryName $repositoryName
        }

        Describe 'Removing labels on an issue'{
            $repositoryName = [Guid]::NewGuid().Guid
            $null = New-GitHubRepository -RepositoryName $repositoryName

            $issueName = [Guid]::NewGuid().Guid
            $issue = New-GitHubIssue -OwnerName $ownerName -RepositoryName $repositoryName -Title $issueName

            $labelsToAdd = @('pri:lowest', 'pri:low', 'pri:medium', 'pri:high', 'pri:highest', 'bug', 'duplicate',
            'enhancement', 'up for grabs', 'question', 'discussion', 'wontfix', 'in progress', 'ready')
            Add-GitHubIssueLabel -OwnerName $ownerName -RepositoryName $repositoryName -Issue $issue.number -LabelName $labelsToAdd

            Context 'For removing individual issues'{
                Remove-GitHubIssueLabel -OwnerName $ownerName -RepositoryName $repositoryName -Name "discussion" -Issue $issue.number
                Remove-GitHubIssueLabel -OwnerName $ownerName -RepositoryName $repositoryName -Name "question" -Issue $issue.number
                Remove-GitHubIssueLabel -OwnerName $ownerName -RepositoryName $repositoryName -Name "bug" -Issue $issue.number
                $labelIssues = Get-GitHubLabel -OwnerName $ownerName -RepositoryName $repositoryName -Issue $issue.number

                It 'Should have removed three labels from the issue' {
                    $labelIssues.Count | Should be ($defaultLabels.Count - 3)
                }
            }

            Context 'For removing all issues'{
                Remove-GitHubIssueLabel -OwnerName $ownerName -RepositoryName $repositoryName -Issue $issue.number
                $labelIssues = Get-GitHubLabel -OwnerName $ownerName -RepositoryName $repositoryName -Issue $issue.number

                It 'Should have removed all labels from the issue' {
                    $labelIssues.Count | Should be 0
                }
            }

            $null = Remove-GitHubRepository -OwnerName $ownerName -RepositoryName $repositoryName
        }

        Describe 'Replacing labels on an issue'{
            $repositoryName = [Guid]::NewGuid().Guid
            $null = New-GitHubRepository -RepositoryName $repositoryName

            $issueName = [Guid]::NewGuid().Guid
            $issue = New-GitHubIssue -OwnerName $ownerName -RepositoryName $repositoryName -Title $issueName

            $labelsToAdd = @('pri:lowest', 'pri:low', 'pri:medium', 'pri:high', 'pri:highest', 'bug', 'duplicate',
            'enhancement', 'up for grabs', 'question', 'discussion', 'wontfix', 'in progress', 'ready')

            Add-GitHubIssueLabel  -OwnerName $ownerName -RepositoryName $repositoryName -Issue $issue.number -LabelName 'pri:medium'

            $addedLabels = @(Set-GitHubIssueLabel -OwnerName $ownerName -RepositoryName $repositoryName -Issue $issue.number -LabelName $labelsToAdd)

            It 'Should return the issue with 14 labels' {
                $addedLabels.Count | Should be $labelsToAdd.Count
            }

            $labelIssues = Get-GitHubLabel -OwnerName $ownerName -RepositoryName $repositoryName -Issue $issue.number

            It 'Should have 14 labels after querying the issue' {
                $labelIssues.Count | Should be $defaultLabels.Count
            }

            $updatedIssueLabels = @($labelsToAdd[0])
            $updatedIssue = Update-GitHubIssue -OwnerName $ownerName -RepositoryName $repositoryName -Issue $issue.number -Label $updatedIssueLabels

            It 'Should have 1 label after updating the issue' {
                $updatedIssue.labels.Count | Should be $updatedIssueLabels.Count
            }

            $null = Remove-GitHubRepository -OwnerName $ownerName -RepositoryName $repositoryName
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
