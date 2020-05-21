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
        defaultRepoName = ([Guid]::NewGuid().Guid)
        defaultRepoDesc = "This is a description."
        defaultRepoHomePage = "https://www.microsoft.com/"
        defaultRepoTopic = "microsoft"
        modifiedRepoDesc = "This is a modified description."
    }.GetEnumerator() | ForEach-Object {
        Set-Variable -Force -Scope Script -Option ReadOnly -Visibility Private -Name $_.Key -Value $_.Value
    }

    Describe 'Getting repositories' {

        Context -Name 'For getting a repository' -Fixture {
            BeforeAll {
                $repo = New-GitHubRepository -RepositoryName $defaultRepoName -Description $defaultRepoDesc -AutoInit
            }
            AfterAll {
                Remove-GitHubRepository -Uri "$($repo.svn_url)" -Verbose
            }

            $newRepo = Get-GitHubRepository -RepositoryName $defaultRepoName
            It 'Should get repository' {
                $newRepo | Should Not BeNullOrEmpty
            }

            It 'Name is correct' {
                $newRepo.name | Should be $defaultRepoName
            }

            It 'Description is correct' {
                $newRepo.description | Should be $defaultRepoDesc
            }
        }

        Context -Name 'For getting a from default/repository' -Fixture {
            BeforeAll {
                $originalOwnerName = Get-GitHubConfiguration -Name DefaultOwnerName
                $originalRepositoryName = Get-GitHubConfiguration -Name DefaultRepositoryName
            }
            AfterAll {
                Set-GitHubConfiguration -DefaultOwnerName $originalOwnerName
                Set-GitHubConfiguration -DefaultRepositoryName $originalRepositoryName
            }

            $repo = Get-GitHubRepository
            It 'Should get repository' {
                $repo | Should Not BeNullOrEmpty
            }

            It 'Owner is correct' {
                $repo.owner.login | Should be Get-GitHubConfiguration -Name DefaultOwnerName
            }

            It 'Name is correct' {
                $repo.name | Should be Get-GitHubConfiguration -Name DefaultRepositoryName
            }
        }
    }

    Describe 'Creating repositories' {

        Context -Name 'For creating a repository' -Fixture {
            BeforeAll {
                $repo = New-GitHubRepository -RepositoryName $defaultRepoName -Description $defaultRepoDesc -AutoInit
            }
            AfterAll {
                Remove-GitHubRepository -Uri "$($repo.svn_url)" -Verbose
            }

            It 'Should get repository' {
                $repo | Should Not BeNullOrEmpty
            }

            It 'Name is correct' {
                $repo.name | Should be $defaultRepoName
            }

            It 'Description is correct' {
                $repo.Description | Should be $defaultRepoDesc
            }
        }
    }

    Describe 'Deleting repositories' {

        Context -Name 'For deleting a repository' -Fixture {
            BeforeAll {
                $repo = New-GitHubRepository -RepositoryName $defaultRepoName -Description $defaultRepoDesc -AutoInit
            }

            $delete = Remove-GitHubRepository -RepositoryName $defaultRepoName -Verbose
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
                Remove-GitHubRepository -Uri "$($repo.svn_url)$suffixToAddToRepo" -Verbose
            }
        }
    }

    Describe 'Updating repositories' {

        Context -Name 'For creating a repository' -Fixture {
            BeforeAll {
                $repo = New-GitHubRepository -RepositoryName $defaultRepoName -Description $defaultRepoDesc -AutoInit
            }
            AfterAll {
                Remove-GitHubRepository -Uri "$($repo.svn_url)" -Verbose
            }

            It 'Should have the new updated description' {
                $updatedRepo = Update-GitHubRepository -RepositoryName $defaultRepoName -Description $modifiedRepoDesc
                $updatedRepo.description | Should be $modifiedRepoDesc
            }

            It 'Should have the new updated homepage url' {
                $updatedRepo = Update-GitHubRepository -RepositoryName $defaultRepoName -Homepage $defaultRepoHomePage
                $repo.homepage | Should be $defaultRepoHomePage
            }
        }
    }

    Describe 'Get/set repository topic' {

        Context -Name 'For creating and getting a repository topic' -Fixture {
            BeforeAll {
                $repo = New-GitHubRepository -RepositoryName $defaultRepoName -AutoInit
            }
            AfterAll {
                Remove-GitHubRepository -Uri "$($repo.svn_url)" -Verbose
            }

            It 'Should have the expected topic' {
                $topic = Set-GitHubRepositoryTopic -RepositoryName $defaultRepoName -Name ($defaultRepoTopic)
                $updatedRepo.names[0] | Should be $defaultRepoTopics
            }

            It 'Should have no topics' {
                $topic = Set-GitHubRepositoryTopic -RepositoryName $defaultRepoName -Clear
                $updatedRepo.names | Should BeNullOrEmpty
            }
        }
    }

    Describe 'Get repository languages' {

        Context -Name 'For getting repository languages' -Fixture {
            BeforeAll {
                $repo = New-GitHubRepositoryLanguage -RepositoryName $defaultRepoName -AutoInit
            }
            AfterAll {
                Remove-GitHubRepository -Uri "$($repo.svn_url)" -Verbose
            }

            $languages = Get-GitHubRepositoryLanguage -RepositoryName $defaultRepoName
            It 'Should be empty' {
                $languages | Should BeNullOrEmpty
            }
        }
    }

    Describe 'Get repository tags' {

        Context -Name 'For getting repository tags' -Fixture {
            BeforeAll {
                $repo = New-GitHubRepositoryLanguage -RepositoryName $defaultRepoName -AutoInit
            }
            AfterAll {
                Remove-GitHubRepository -Uri "$($repo.svn_url)" -Verbose
            }

            $tags = Get-GitHubRepositoryTag -RepositoryName $defaultRepoName
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
