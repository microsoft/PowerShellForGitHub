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
    # Define Script-scoped, readonly, hidden variables.
    @{
        defaultRepoDesc = "This is a description."
        defaultRepoHomePage = "https://www.microsoft.com/"
        defaultRepoTopic = "microsoft"
    }.GetEnumerator() | ForEach-Object {
        Set-Variable -Force -Scope Script -Option ReadOnly -Visibility Private -Name $_.Key -Value $_.Value
    }

    Describe 'Getting repositories' {
        Context 'For authenticated user' {
            BeforeAll -Scriptblock {
                $publicRepo = New-GitHubRepository -RepositoryName ([Guid]::NewGuid().Guid) -AutoInit
                $privateRepo = New-GitHubRepository -RepositoryName ([Guid]::NewGuid().Guid) -AutoInit -Private

                # Avoid PSScriptAnalyzer PSUseDeclaredVarsMoreThanAssignments
                $publicRepo = $publicRepo
                $privateRepo = $privateRepo
            }

            $publicRepos = Get-GitHubRepository -Visibility Public
            $privateRepos = Get-GitHubRepository -Visibility Private

            It "Should have the public repo" {
                $publicRepo.name | Should BeIn $publicRepos.name
                $publicRepo.name | Should Not BeIn $privateRepos.name
            }

            It "Should have the private repo" {
                $privateRepo.name | Should BeIn $privateRepos.name
                $privateRepo.name | Should Not BeIn $publicRepos.name
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
            $repos = Get-GitHubRepository -OwnerName 'octocat' -Type Public

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

            $repos = Get-GitHubRepository -OrganizationName $script:organizationName -Type All
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

            $returned = Get-GitHubRepository -Uri $repo.svn_url
            It "Should be a single result using Uri ParameterSet" {
                $returned | Should -BeOfType PSCustomObject
            }

            $returned = Get-GitHubRepository -OwnerName $repo.owner.login -RepositoryName $repo.name
            It "Should be a single result using Elements ParameterSet" {
                $returned | Should -BeOfType PSCustomObject
            }

            It 'Should not permit additional parameters' {
                { Get-GitHubRepository -OwnerName $repo.owner.login -RepositoryName $repo.name -Type All } | Should Throw
            }

            It 'Should require both OwnerName and RepositoryName' {
                { Get-GitHubRepository -RepositoryName $repo.name } | Should Throw
                { Get-GitHubRepository -Uri "https://github.com/$script:ownerName" } | Should Throw
            }

            AfterAll -ScriptBlock {
                Remove-GitHubRepository -Uri $repo.svn_url
            }
        }
    }

    Describe 'Creating repositories' {

        Context -Name 'For creating a repository' -Fixture {
            BeforeAll {
                $repoName = ([Guid]::NewGuid().Guid)
                $repo = New-GitHubRepository -RepositoryName $repoName -Description $defaultRepoDesc -AutoInit
            }
            AfterAll {
                Remove-GitHubRepository -Uri $repo.svn_url
            }

            It 'Should get repository' {
                $repo | Should Not BeNullOrEmpty
            }

            It 'Name is correct' {
                $repo.name | Should be $repoName
            }

            It 'Description is correct' {
                $repo.description | Should be $defaultRepoDesc
            }
        }
    }

    Describe 'Deleting repositories' {

        Context -Name 'For deleting a repository' -Fixture {
            BeforeAll {
                $repo = New-GitHubRepository -RepositoryName ([Guid]::NewGuid().Guid) -Description $defaultRepoDesc -AutoInit
            }

            $delete = Remove-GitHubRepository -RepositoryName $repo.name
            It 'Should get no content' {
                $repo | Should BeNullOrEmpty
            }
        }
    }

    Describe 'Renaming repositories' {

        Context -Name 'For renaming a repository' -Fixture {
            BeforeEach -Scriptblock {
                $repo = New-GitHubRepository -RepositoryName ([Guid]::NewGuid().Guid) -AutoInit
                $suffixToAddToRepo = "_renamed"
                $newRepoName = "$($repo.name)$suffixToAddToRepo"
            }
            It "Should have the expected new repository name - by URI" {
                $renamedRepo = $repo | Rename-GitHubRepository -NewName $newRepoName -Confirm:$false
                $renamedRepo.name | Should be $newRepoName
            }

            It "Should have the expected new repository name - by Elements" {
                $renamedRepo = Rename-GitHubRepository -OwnerName $repo.owner.login -RepositoryName $repo.name -NewName $newRepoName -Confirm:$false
                $renamedRepo.name | Should be $newRepoName
            }
            ## cleanup temp testing repository
            AfterEach -Scriptblock {
                ## variables from BeforeEach scriptblock are accessible here, but not variables from It scriptblocks, so need to make URI (instead of being able to use $renamedRepo variable from It scriptblock)
                Remove-GitHubRepository -Uri "$($repo.svn_url)$suffixToAddToRepo"
            }
        }
    }

    Describe 'Updating repositories' {

        Context -Name 'For creating a repository' -Fixture {
            BeforeAll {
                $repo = New-GitHubRepository -RepositoryName ([Guid]::NewGuid().Guid) -Description $defaultRepoDesc -AutoInit
            }
            AfterAll {
                Remove-GitHubRepository -Uri $repo.svn_url
            }

            It 'Should have the new updated description' {
                $modifiedRepoDesc = $defaultRepoDesc + "_modified"
                $updatedRepo = Update-GitHubRepository -OwnerName $repo.owner.login -RepositoryName $repo.name -Description $modifiedRepoDesc
                $updatedRepo.description | Should be $modifiedRepoDesc
            }

            It 'Should have the new updated homepage url' {
                $updatedRepo = Update-GitHubRepository -OwnerName $repo.owner.login -RepositoryName $repo.name -Homepage $defaultRepoHomePage
                $repo.homepage | Should be $defaultRepoHomePage
            }
        }
    }

    Describe 'Get/set repository topic' {

        Context -Name 'For creating and getting a repository topic' -Fixture {
            BeforeAll {
                $repo = New-GitHubRepository -RepositoryName ([Guid]::NewGuid().Guid) -AutoInit
            }
            AfterAll {
                Remove-GitHubRepository -Uri $repo.svn_url
            }

            It 'Should have the expected topic' {
                $topic = Set-GitHubRepositoryTopic -OwnerName $repo.owner.login -RepositoryName $repo.name -Name $defaultRepoTopic
                $updatedRepo.names[0] | Should be $defaultRepoTopic
            }

            It 'Should have no topics' {
                $topic = Set-GitHubRepositoryTopic -OwnerName $repo.owner.login -RepositoryName $repo.name -Clear
                $updatedRepo.names | Should BeNullOrEmpty
            }
        }
    }

    Describe 'Get repository languages' {

        Context -Name 'For getting repository languages' -Fixture {
            BeforeAll {
                $repo = New-GitHubRepository -RepositoryName ([Guid]::NewGuid().Guid) -AutoInit
            }
            AfterAll {
                Remove-GitHubRepository -Uri $repo.svn_url
            }

            $languages = Get-GitHubRepositoryLanguage -OwnerName $repo.owner.login -RepositoryName $repo.name
            It 'Should be empty' {
                $languages | Should BeNullOrEmpty
            }
        }
    }

    Describe 'Get repository tags' {

        Context -Name 'For getting repository tags' -Fixture {
            BeforeAll {
                $repo = New-GitHubRepository -RepositoryName ([Guid]::NewGuid().Guid) -AutoInit
            }
            AfterAll {
                Remove-GitHubRepository -Uri $repo.svn_url
            }

            $tags = Get-GitHubRepositoryTag -OwnerName $repo.owner.login -RepositoryName $repo.name
            It 'Should be empty' {
                $tags | Should BeNullOrEmpty
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
