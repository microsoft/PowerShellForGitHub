# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

<#
.Synopsis
   Tests for GitHubRepositories.ps1 module
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

            It "Should have the public repo" {
                $publicRepos = @(Get-GitHubRepository -Visibility Public)
                $privateRepos = @(Get-GitHubRepository -Visibility Private)
                $publicRepo.name | Should -BeIn $publicRepos.name
                $publicRepo.name | Should -Not -BeIn $privateRepos.name
            }

            It "Should have the private repo" {
                $publicRepos = @(Get-GitHubRepository -Visibility Public)
                $privateRepos = @(Get-GitHubRepository -Visibility Private)
                $privateRepo.name | Should -BeIn $privateRepos.name
                $privateRepo.name | Should -Not -BeIn $publicRepos.name
            }

            It 'Should not permit bad combination of parameters' {
                { Get-GitHubRepository -Type All -Visibility All } | Should -Throw
                { Get-GitHubRepository -Type All -Affiliation Owner } | Should -Throw
            }

            AfterAll -ScriptBlock {
                Remove-GitHubRepository -Uri $publicRepo.svn_url -Confirm:$false
                Remove-GitHubRepository -Uri $privateRepo.svn_url -Confirm:$false
            }
        }

        Context 'For any user' {
            It "Should have results for The Octocat" {
                $repos = @(Get-GitHubRepository -OwnerName 'octocat' -Type Public)
                $repos.Count | Should -BeGreaterThan 0
                $repos[0].owner.login | Should -Be 'octocat'
            }
        }

        Context 'For organizations' {
            BeforeAll -Scriptblock {
                $repo = New-GitHubRepository -OrganizationName $script:organizationName -RepositoryName ([Guid]::NewGuid().Guid) -AutoInit

                # Avoid PSScriptAnalyzer PSUseDeclaredVarsMoreThanAssignments
                $repo = $repo
            }

            It "Should have results for the organization" {
                $repos = @(Get-GitHubRepository -OrganizationName $script:organizationName -Type All)
                $repo.name | Should -BeIn $repos.name
            }

            AfterAll -ScriptBlock {
                Remove-GitHubRepository -Uri $repo.svn_url -Confirm:$false
            }
        }

        Context 'For public repos' {
            # Skipping these tests for now, as it would run for a _very_ long time.
            # No obviously good way to verify this.
        }

        Context 'For a specific repo' {
            BeforeAll -ScriptBlock {
                $repo = New-GitHubRepository -RepositoryName ([Guid]::NewGuid().Guid) -AutoInit

                # Avoid PSScriptAnalyzer PSUseDeclaredVarsMoreThanAssignments
                $repo = $repo
            }

            It "Should be a single result using Uri ParameterSet" {
                $result = Get-GitHubRepository -Uri $repo.svn_url
                $result | Should -BeOfType PSCustomObject
            }

            It "Should be a single result using Elements ParameterSet" {
                $result = Get-GitHubRepository -OwnerName $repo.owner.login -RepositoryName $repo.name
                $result | Should -BeOfType PSCustomObject
            }

            It 'Should not permit additional parameters' {
                { Get-GitHubRepository -OwnerName $repo.owner.login -RepositoryName $repo.name -Type All } | Should -Throw
            }

            It 'Should require both OwnerName and RepositoryName' {
                { Get-GitHubRepository -RepositoryName $repo.name } | Should -Throw
                { Get-GitHubRepository -Uri "https://github.com/$script:ownerName" } | Should -Throw
            }

            AfterAll -ScriptBlock {
                Remove-GitHubRepository -Uri $repo.svn_url -Confirm:$false
            }
        }
    }

    Describe 'Creating repositories' {

        Context -Name 'For creating a repository' -Fixture {
            BeforeAll -ScriptBlock {
                $repoName = ([Guid]::NewGuid().Guid)
                $repo = New-GitHubRepository -RepositoryName $repoName -Description $defaultRepoDesc -AutoInit

                # Avoid PSScriptAnalyzer PSUseDeclaredVarsMoreThanAssignments
                $repoName = $repoName
                $repo = $repo
            }

            It 'Should get repository' {
                $repo | Should -Not -BeNullOrEmpty
            }

            It 'Name is correct' {
                $repo.name | Should -Be $repoName
            }

            It 'Description is correct' {
                $repo.description | Should -Be $defaultRepoDesc
            }

            AfterAll -ScriptBlock {
                Remove-GitHubRepository -Uri $repo.svn_url -Confirm:$false
            }
        }
    }

    Describe 'Deleting repositories' {

        Context -Name 'For deleting a repository' -Fixture {
            BeforeAll -ScriptBlock {
                $repo = New-GitHubRepository -RepositoryName ([Guid]::NewGuid().Guid) -Description $defaultRepoDesc -AutoInit

                # Avoid PSScriptAnalyzer PSUseDeclaredVarsMoreThanAssignments
                $repo = $repo
            }

            It 'Should get no content' {
                Remove-GitHubRepository -OwnerName $repo.owner.login -RepositoryName $repo.name -Confirm:$false
                { Get-GitHubRepository -OwnerName $repo.owner.login -RepositoryName $repo.name } | Should -Throw
            }
        }
    }

    Describe 'Renaming repositories' {

        Context -Name 'For renaming a repository' -Fixture {
            BeforeEach -Scriptblock {
                $repo = New-GitHubRepository -RepositoryName ([Guid]::NewGuid().Guid) -AutoInit
                $suffixToAddToRepo = "_renamed"
                $newRepoName = "$($repo.name)$suffixToAddToRepo"

                # Avoid PSScriptAnalyzer PSUseDeclaredVarsMoreThanAssignments
                $newRepoName = $newRepoName
            }

            It "Should have the expected new repository name - by URI" {
                $renamedRepo = $repo | Rename-GitHubRepository -NewName $newRepoName -Confirm:$false
                $renamedRepo.name | Should -Be $newRepoName
            }

            It "Should have the expected new repository name - by Elements" {
                $renamedRepo = Rename-GitHubRepository -OwnerName $repo.owner.login -RepositoryName $repo.name -NewName $newRepoName -Confirm:$false
                $renamedRepo.name | Should -Be $newRepoName
            }

            AfterEach -Scriptblock {
                Remove-GitHubRepository -Uri "$($repo.svn_url)$suffixToAddToRepo" -Confirm:$false
            }
        }
    }

    Describe 'Updating repositories' {

        Context -Name 'For creating a repository' -Fixture {
            BeforeAll -ScriptBlock {
                $repo = New-GitHubRepository -RepositoryName ([Guid]::NewGuid().Guid) -Description $defaultRepoDesc -AutoInit

                # Avoid PSScriptAnalyzer PSUseDeclaredVarsMoreThanAssignments
                $repo = $repo
            }

            It 'Should have the new updated description' {
                $modifiedRepoDesc = $defaultRepoDesc + "_modified"
                $updatedRepo = Update-GitHubRepository -OwnerName $repo.owner.login -RepositoryName $repo.name -Description $modifiedRepoDesc
                $updatedRepo.description | Should -Be $modifiedRepoDesc
            }

            It 'Should have the new updated homepage url' {
                $updatedRepo = Update-GitHubRepository -OwnerName $repo.owner.login -RepositoryName $repo.name -Homepage $defaultRepoHomePage
                $updatedRepo.homepage | Should -Be $defaultRepoHomePage
            }

            AfterAll -ScriptBlock {
                Remove-GitHubRepository -Uri $repo.svn_url -Confirm:$false
            }
        }
    }

    Describe 'Get/set repository topic' {

        Context -Name 'For creating and getting a repository topic' -Fixture {
            BeforeAll -ScriptBlock {
                $repo = New-GitHubRepository -RepositoryName ([Guid]::NewGuid().Guid) -AutoInit

                # Avoid PSScriptAnalyzer PSUseDeclaredVarsMoreThanAssignments
                $repo = $repo
            }

            It 'Should have the expected topic' {
                Set-GitHubRepositoryTopic -OwnerName $repo.owner.login -RepositoryName $repo.name -Name $defaultRepoTopic
                $topic = Get-GitHubRepositoryTopic -OwnerName $repo.owner.login -RepositoryName $repo.name
                $topic.names | Should -Be $defaultRepoTopic
            }

            It 'Should have no topics' {
                Set-GitHubRepositoryTopic -OwnerName $repo.owner.login -RepositoryName $repo.name -Clear
                $topic = Get-GitHubRepositoryTopic -OwnerName $repo.owner.login -RepositoryName $repo.name
                $topic.names | Should -BeNullOrEmpty
            }

            AfterAll -ScriptBlock {
                Remove-GitHubRepository -Uri $repo.svn_url -Confirm:$false
            }
        }
    }

    Describe 'Get repository languages' {

        Context -Name 'For getting repository languages' -Fixture {
            BeforeAll -ScriptBlock {
                $repo = New-GitHubRepository -RepositoryName ([Guid]::NewGuid().Guid) -AutoInit

                # Avoid PSScriptAnalyzer PSUseDeclaredVarsMoreThanAssignments
                $repo = $repo
            }

            It 'Should be empty' {
                $languages = Get-GitHubRepositoryLanguage -OwnerName $repo.owner.login -RepositoryName $repo.name
                $languages | Should -BeNullOrEmpty
            }

            It 'Should contain PowerShell' {
                $languages = Get-GitHubRepositoryLanguage -OwnerName "microsoft" -RepositoryName "PowerShellForGitHub"
                $languages.PowerShell | Should -Not -BeNullOrEmpty
            }

            AfterAll -ScriptBlock {
                Remove-GitHubRepository -Uri $repo.svn_url -Confirm:$false
            }
        }
    }

    Describe 'Get repository tags' {

        Context -Name 'For getting repository tags' -Fixture {
            BeforeAll -ScriptBlock {
                $repo = New-GitHubRepository -RepositoryName ([Guid]::NewGuid().Guid) -AutoInit

                # Avoid PSScriptAnalyzer PSUseDeclaredVarsMoreThanAssignments
                $repo = $repo
            }

            It 'Should be empty' {
                $tags = Get-GitHubRepositoryTag -OwnerName $repo.owner.login -RepositoryName $repo.name
                $tags | Should -BeNullOrEmpty
            }

            AfterAll -ScriptBlock {
                Remove-GitHubRepository -Uri $repo.svn_url -Confirm:$false
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
