# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

<#
.Synopsis
   Tests for GitHubRepositoryForks.ps1 module
#>

# This is common test code setup logic for all Pester test files
$moduleRootPath = Split-Path -Path $PSScriptRoot -Parent
. (Join-Path -Path $moduleRootPath -ChildPath 'Tests\Common.ps1')

try
{
    Describe 'Creating a new fork for user' {
        $originalForks = Get-GitHubRepositoryFork -OwnerName Microsoft -RepositoryName PowerShellForGitHub

        Context 'When a new fork is created' {
            $repo = New-GitHubRepositoryFork -OwnerName Microsoft -RepositoryName PowerShellForGitHub
            $newForks = Get-GitHubRepositoryFork -OwnerName Microsoft -RepositoryName PowerShellForGitHub -Sort Newest

            It 'Should have one more fork than before' {
                (@($newForks).Count - @($originalForks).Count) | Should be 1
            }

            It 'Should be the latest fork in the list' {
                $newForks[0].full_name | Should be "$($script:ownerName)/PowerShellForGitHub"
            }

            Remove-GitHubRepository -Uri $repo.svn_url
        }
    }

    Describe 'Creating a new fork for an org' {
        $originalForks = Get-GitHubRepositoryFork -OwnerName Microsoft -RepositoryName PowerShellForGitHub

        Context 'When a new fork is created' {
            $repo = New-GitHubRepositoryFork -OwnerName Microsoft -RepositoryName PowerShellForGitHub -OrganizationName $script:organizationName
            $newForks = Get-GitHubRepositoryFork -OwnerName Microsoft -RepositoryName PowerShellForGitHub -Sort Newest

            It 'Should have one more fork than before' {
                (@($newForks).Count - @($originalForks).Count) | Should be 1
            }

            It 'Should be the latest fork in the list' {
                $newForks[0].full_name | Should be "$($script:organizationName)/PowerShellForGitHub"
            }

            Remove-GitHubRepository -Uri $repo.svn_url
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
