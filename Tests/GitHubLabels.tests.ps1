# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

<#
.Synopsis
   Tests for GitHubLabels.psm1 module
#>

[String] $root = Split-Path -Parent (Split-Path -Parent $Script:MyInvocation.MyCommand.Path)

if ($env:AppVeyor)
{
    $global:gitHubApiToken = $env:token
    $message = 'This run is executed in the AppVeyor environment. 
GitHubApiToken won''t be decrypted in PR runs causing some tests to fail.
403 errors possible due to GitHub hourly limit for unauthenticated queries.
Define $global:gitHubApiToken manually and run tests on your machine first.'
    Write-Host $message -BackgroundColor Yellow -ForegroundColor Black
}

$apiTokensFilePath = "$root\ApiTokens.psm1"
if (Test-Path $apiTokensFilePath)
{
    Write-Host "Importing $apiTokensFilePath"
    Import-Module  -force $apiTokensFilePath
}
else
{
    Write-Host "$apiTokensFilePath does not exist, skipping import in tests"
}

$script:tokenExists = $true
if ($global:gitHubApiToken -eq $null)
{
    Write-Host "GitHubApiToken not defined, some of the tests will be skipped. `n403 errors possible due to GitHub hourly limit for unauthenticated queries." -BackgroundColor Yellow -ForegroundColor Black
    $script:tokenExists = $false
}
else
{
    Write-Host "GitHubApiToken has been defined in tests"
}

Import-Module (Join-Path -Path $root -ChildPath 'GitHubLabels.psm1') -Force

$script:gitHubAccountUrl = "https://github.com/gipstestaccount"
$script:accountName = "gipstestaccount"
$script:repositoryName = "TestRepository"
$script:repositoryUrl = "$script:gitHubAccountUrl/$script:repositoryName"
$script:expectedNumberOfLabels = 14

if ($script:tokenExists)
{
    New-GitHubLabels -RepositoryName $script:repositoryName -OwnerName $script:accountName

    Describe 'Getting labels from repository' {
        Context 'When querying for all labels' {
            $labels = Get-GitHubLabel -RepositoryName $script:repositoryName -OwnerName $script:accountName

            It 'Should return expected number of labels' {
                $($labels).Count | Should be $script:expectedNumberOfLabels
            }
        }

        Context 'When querying for specific label' {
            $label = Get-GitHubLabel -RepositoryName $script:repositoryName -OwnerName $script:accountName -LabelName bug

            It 'Should return expected label' {
                $label.name | Should be "bug"
            }
        }
    }

    Describe 'Creating new label' {
        $labelName = "TestLabel"
        New-GitHubLabel -RepositoryName $script:repositoryName -OwnerName $script:accountName -LabelName $labelName -LabelColor BBBBBB
        $label = Get-GitHubLabel -RepositoryName $script:repositoryName -OwnerName $script:accountName -LabelName $labelName

        AfterEach { 
            Remove-GitHubLabel -RepositoryName $script:repositoryName -OwnerName $script:accountName -LabelName $labelName
        }

        It 'New label should be created' {
            $label.name | Should be $labelName
        }
    }

    Describe 'Removing label' {
        $labelName = "TestLabel"

        New-GitHubLabel -RepositoryName $script:repositoryName -OwnerName $script:accountName -LabelName $labelName -LabelColor BBBBBB
        $labels = Get-GitHubLabel -RepositoryName $script:repositoryName -OwnerName $script:accountName

        It 'Should return increased number of labels' {
            $($labels).Count | Should be ($script:expectedNumberOfLabels + 1)
        }

        Remove-GitHubLabel -RepositoryName $script:repositoryName -OwnerName $script:accountName -LabelName $labelName
        $labels = Get-GitHubLabel -RepositoryName $script:repositoryName -OwnerName $script:accountName

        It 'Should return expected number of labels' {
            $($labels).Count | Should be $script:expectedNumberOfLabels
        }
    }

    Describe 'Updating label' {
        $labelName = "TestLabel"
    
        Context 'Updating label color' {
            New-GitHubLabel -RepositoryName $script:repositoryName -OwnerName $script:accountName -LabelName $labelName -LabelColor BBBBBB
            Update-GitHubLabel -RepositoryName $script:repositoryName -OwnerName $script:accountName -LabelName $labelName -NewLabelName $labelName -LabelColor AAAAAA
            $label = Get-GitHubLabel -RepositoryName $script:repositoryName -OwnerName $script:accountName -LabelName $labelName

            AfterEach { 
                Remove-GitHubLabel -RepositoryName $script:repositoryName -OwnerName $script:accountName -LabelName $labelName
            }

            It 'Label should have different color' {
                $label.color | Should be AAAAAA
            }
        }
    
        Context 'Updating label name' {
            $newLabelName = $labelName + "2"
            New-GitHubLabel -RepositoryName $script:repositoryName -OwnerName $script:accountName -LabelName $labelName -LabelColor BBBBBB
            Update-GitHubLabel -RepositoryName $script:repositoryName -OwnerName $script:accountName -LabelName $labelName -NewLabelName $newLabelName -LabelColor BBBBBB
            $label = Get-GitHubLabel -RepositoryName $script:repositoryName -OwnerName $script:accountName -LabelName $newLabelName 

            AfterEach { 
                Remove-GitHubLabel -RepositoryName $script:repositoryName -OwnerName $script:accountName -LabelName $newLabelName
            }

            It 'Label should have different color' {
                $label | Should not be $null
                $label.color | Should be BBBBBB
            }
        }
    }

    Describe 'Applying set of labels on repository' {
        $labelName = "TestLabel"

        New-GitHubLabels -RepositoryName $script:repositoryName -OwnerName $script:accountName

        # Add new label
        New-GitHubLabel -RepositoryName $script:repositoryName -OwnerName $script:accountName -LabelName $labelName -LabelColor BBBBBB
        $labels = Get-GitHubLabel -RepositoryName $script:repositoryName -OwnerName $script:accountName

        # Change color of existing label
        Update-GitHubLabel -RepositoryName $script:repositoryName -OwnerName $script:accountName -LabelName "bug" -NewLabelName "bug" -LabelColor BBBBBB

        # Remove one of approved labels"
        Remove-GitHubLabel -RepositoryName $script:repositoryName -OwnerName $script:accountName -LabelName "discussion"

        It 'Should return increased number of labels' {
            $($labels).Count | Should be ($script:expectedNumberOfLabels + 1)
        }

        New-GitHubLabels -RepositoryName $script:repositoryName -OwnerName $script:accountName
        $labels = Get-GitHubLabel -RepositoryName $script:repositoryName -OwnerName $script:accountName

        It 'Should return expected number of labels' {
            $($labels).Count | Should be $script:expectedNumberOfLabels
            $bugLabel = $labels | ?{$_.name -eq "bug"}
            $bugLabel.color | Should be "fc2929"
        }
    }
}