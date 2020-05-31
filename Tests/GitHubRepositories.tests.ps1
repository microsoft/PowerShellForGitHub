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
    Describe 'Getting repositories' {
        Context 'For authenticated user' {
            BeforeAll -Scriptblock {
                $publicRepo = New-GitHubRepository -RepositoryName ([Guid]::NewGuid().Guid) -AutoInit
                $privateRepo = New-GitHubRepository -RepositoryName ([Guid]::NewGuid().Guid) -AutoInit -Private

                # Avoid PSScriptAnalyzer PSUseDeclaredVarsMoreThanAssignments
                $publicRepo = $publicRepo
                $privateRepo = $privateRepo
            }

            $publicRepos = @(Get-GitHubRepository -Visibility Public)
            $privateRepos = @(Get-GitHubRepository -Visibility Private)

            It "Should have the public repo" {
                $publicRepo.Name | Should BeIn $publicRepos.Name
                $publicRepo.Name | Should Not BeIn $privateRepos.Name
            }

            It "Should have the private repo" {
                $privateRepo.Name | Should BeIn $privateRepos.Name
                $privateRepo.Name | Should Not BeIn $publicRepos.Name
            }

            It 'Should not permit bad combination of parameters' {
                { Get-GitHubRepository -Type All -Visibility All } | Should Throw
                { Get-GitHubRepository -Type All -Affiliation Owner } | Should Throw
            }

            AfterAll -ScriptBlock {
                Remove-GitHubRepository -Uri $publicRepo.svn_url
                Remove-GitHubRepository -Uri $privateRepo.svn_url
            }
        }

        Context 'For any user' {
            $repos = @(Get-GitHubRepository -OwnerName 'octocat' -Type Public)

            It "Should have results for The Octocat" {
                $repos.Count | Should -BeGreaterThan 0
                $repos[0].owner.login | Should Be 'octocat'
            }
        }

        Context 'For organizations' {
            BeforeAll -Scriptblock {
                $repo = New-GitHubRepository -OrganizationName $script:organizationName -RepositoryName ([Guid]::NewGuid().Guid) -AutoInit

                # Avoid PSScriptAnalyzer PSUseDeclaredVarsMoreThanAssignments
                $repo = $repo
            }

            $repos = @(Get-GitHubRepository -OrganizationName $script:organizationName -Type All)
            It "Should have results for the organization" {
                $repo.name | Should BeIn $repos.name
            }

            AfterAll -ScriptBlock {
                Remove-GitHubRepository -Uri $repo.svn_url
            }
        }

        Context 'For public repos' {
            # Skipping these tests for now, as it would run for a _very_ long time.
            # No obviously good way to verify this.
        }

        Context 'For a specific repo' {
            BeforeAll -Scriptblock {
                $repo = New-GitHubRepository -RepositoryName ([Guid]::NewGuid().Guid) -AutoInit

                # Avoid PSScriptAnalyzer PSUseDeclaredVarsMoreThanAssignments
                $repo = $repo
            }

            $result = Get-GitHubRepository -Uri $repo.svn_url
            It "Should be a single result using Uri ParameterSet" {
                $result | Should -BeOfType PSCustomObject
            }

            $result = Get-GitHubRepository -OwnerName $repo.owner.login -RepositoryName $repo.Name
            It "Should be a single result using Elements ParameterSet" {
                $result | Should -BeOfType PSCustomObject
            }

            It 'Should not permit additional parameters' {
                { Get-GitHubRepository -OwnerName $repo.owner.login -RepositoryName $repo.Name -Type All } | Should Throw
            }

            It 'Should require both OwnerName and RepositoryName' {
                { Get-GitHubRepository -RepositoryName $repo.Name } | Should Throw
                { Get-GitHubRepository -Uri "https://github.com/$script:ownerName" } | Should Throw
            }

            AfterAll -ScriptBlock {
                Remove-GitHubRepository -Uri $repo.svn_url
            }
        }
    }

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
                Remove-GitHubRepository -Uri "$($repo.svn_url)$suffixToAddToRepo"
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
