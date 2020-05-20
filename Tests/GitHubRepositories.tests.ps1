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

        Context -Name 'For renaming a repository' -Fixture {
            BeforeEach -Scriptblock {
                $repo = New-GitHubRepository -RepositoryName ([Guid]::NewGuid().Guid) -AutoInit
                $suffixToAddToRepo = "_renamed"
                $newRepoName = "$($repo.Name)$suffixToAddToRepo"
                Write-Verbose "New repo name shall be: '$newRepoName'"
            }
            It "Should have the expected new repository name - by URI" {
                $renamedRepo = $repo | Rename-GitHubRepository -NewName $newRepoName -Confirm:$false
                $renamedRepo.Name | Should be $newRepoName
            }

            It "Should have the expected new repository name - by Elements" {
                $renamedRepo = Rename-GitHubRepository -OwnerName $repo.owner.login -RepositoryName $repo.name -NewName $newRepoName -Confirm:$false
                $renamedRepo.Name | Should be $newRepoName
            }
            ## cleanup temp testing repository
            AfterEach -Scriptblock {
                ## variables from BeforeEach scriptblock are accessible here, but not variables from It scriptblocks, so need to make URI (instead of being able to use $renamedRepo variable from It scriptblock)
                Remove-GitHubRepository -Uri "$($repo.svn_url)$suffixToAddToRepo" -Verbose -Confirm:$false
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
