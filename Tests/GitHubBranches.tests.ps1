# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

<#
.Synopsis
   Tests for GitHubBranches.ps1 module
#>

# This is common test code setup logic for all Pester test files
$moduleRootPath = Split-Path -Path $PSScriptRoot -Parent
. (Join-Path -Path $moduleRootPath -ChildPath 'Tests\Common.ps1')

try
{
    Describe 'Getting branches for repository' {
        $repositoryName = [guid]::NewGuid().Guid
        $null = New-GitHubRepository -RepositoryName $repositoryName -AutoInit

        $branches = @(Get-GitHubRepositoryBranch -OwnerName $script:ownerName -RepositoryName $repositoryName)

        It 'Should return expected number of repository branches' {
            $branches.Count | Should -Be 1
        }

        It 'Should return the name of the branches' {
            $branches[0].name | Should -Be 'master'
        }

        $null = Remove-GitHubRepository -OwnerName $script:ownerName -RepositoryName $repositoryName -Confirm:$false
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
