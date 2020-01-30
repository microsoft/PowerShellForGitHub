# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

<#
.Synopsis
   Tests for GitHubRepositories.ps1 module
.Description
    Many cmdlets are indirectly tested in the course of other tests (New-GitHubRepository, Remove-GitHubRepository), and may not have explicit tests here
#>

# This is common test code setup logic for all Pester test files
$moduleRootPath = Split-Path -Path $PSScriptRoot -Parent
. (Join-Path -Path $moduleRootPath -ChildPath 'Tests\Common.ps1')

try
{
    Describe 'Modifying repositories' {
        $repo = New-GitHubRepository -RepositoryName ([Guid]::NewGuid().Guid) -AutoInit
        $strNewRepoName = "$($repo.Name)_renamed"
        $renamedRepo = $repo | Rename-GitHubRepository -NewName $strNewRepoName -Confirm:$false

        Context 'For renaming a repository' {
            It "Should have the expected new repository name" {
                $renamedRepo.Name | Should be $strNewRepoName
            }
        }

        Remove-GitHubRepository -Uri $renamedRepo.svn_url
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
