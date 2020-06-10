# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

<#
.Synopsis
   Tests for GitHubRepositoryForks.ps1 module
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
    Describe 'Creating a new fork for user' {
        BeforeEach {
            $repo = New-GitHubRepositoryFork -OwnerName Microsoft -RepositoryName PowerShellForGitHub
        }

        AfterEach {
            Remove-GitHubRepository -Uri $repo.svn_url -Confirm:$false
        }

        Context 'When a new fork is created' {
            $newForks = @(Get-GitHubRepositoryFork -OwnerName Microsoft -RepositoryName PowerShellForGitHub -Sort Newest)

            It 'Should be the latest fork in the list' {
                $newForks.full_name | Should -Contain "$($script:ownerName)/PowerShellForGitHub"
            }
        }
    }

    Describe 'Creating a new fork for an org' {
        BeforeEach {
            $repo = New-GitHubRepositoryFork -OwnerName Microsoft -RepositoryName PowerShellForGitHub -OrganizationName $script:organizationName
        }

        AfterEach {
            Remove-GitHubRepository -Uri $repo.svn_url -Confirm:$false
        }

        Context 'When a new fork is created' {
            $newForks = @(Get-GitHubRepositoryFork -OwnerName Microsoft -RepositoryName PowerShellForGitHub -Sort Newest)

            It 'Should be the latest fork in the list' {
                $newForks.full_name | Should -Contain  "$($script:organizationName)/PowerShellForGitHub"
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
