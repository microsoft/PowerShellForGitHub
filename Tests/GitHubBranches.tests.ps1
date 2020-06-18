# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

<#
.Synopsis
   Tests for GitHubBranches.ps1 module
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
    Describe 'Getting branches for repository' {
        BeforeAll {
            $repositoryName = [guid]::NewGuid().Guid
            $repo = New-GitHubRepository -RepositoryName $repositoryName -AutoInit
            $branchName = 'master'
        }

        AfterAll {
            $repo | Remove-GitHubRepository -Confirm:$false
        }

        Context 'Getting all branches for a repository with parameters' {
            $branches = @(Get-GitHubRepositoryBranch -OwnerName $script:ownerName -RepositoryName $repositoryName)

            It 'Should return expected number of repository branches' {
                $branches.Count | Should -Be 1
            }

            It 'Should return the name of the expected branch' {
                $branches.name | Should -Contain $branchName
            }

            It 'Should have the exected type and addititional properties' {
                $branches[0].PSObject.TypeNames[0] | Should -Be 'GitHub.Branch'
                $branches[0].RepositoryUrl | Should -Be $repo.RepositoryUrl
                $branches[0].BranchName | Should -Be $branches[0].name
            }
        }

        Context 'Getting all branches for a repository with the repo on the pipeline' {
            $branches = @($repo | Get-GitHubRepositoryBranch)

            It 'Should return expected number of repository branches' {
                $branches.Count | Should -Be 1
            }

            It 'Should return the name of the expected branch' {
                $branches.name | Should -Contain $branchName
            }

            It 'Should have the exected type and addititional properties' {
                $branches[0].PSObject.TypeNames[0] | Should -Be 'GitHub.Branch'
                $branches[0].RepositoryUrl | Should -Be $repo.RepositoryUrl
                $branches[0].BranchName | Should -Be $branches[0].name
            }
        }

        Context 'Getting a specific branch for a repository with parameters' {
            $branch = Get-GitHubRepositoryBranch -OwnerName $script:ownerName -RepositoryName $repositoryName -BranchName $branchName

            It 'Should return the expected branch name' {
                $branch.name | Should -Be $branchName
            }

            It 'Should have the exected type and addititional properties' {
                $branch.PSObject.TypeNames[0] | Should -Be 'GitHub.Branch'
                $branch.RepositoryUrl | Should -Be $repo.RepositoryUrl
                $branch.BranchName | Should -Be $branch.name
            }
        }

        Context 'Getting a specific branch for a repository with the repo on the pipeline' {
            $branch = $repo | Get-GitHubRepositoryBranch -BranchName $branchName

            It 'Should return the expected branch name' {
                $branch.name | Should -Be $branchName
            }

            It 'Should have the exected type and addititional properties' {
                $branch.PSObject.TypeNames[0] | Should -Be 'GitHub.Branch'
                $branch.RepositoryUrl | Should -Be $repo.RepositoryUrl
                $branch.BranchName | Should -Be $branch.name
            }
        }

        Context 'Getting a specific branch for a repository with the branch object on the pipeline' {
            $branch = Get-GitHubRepositoryBranch -OwnerName $script:ownerName -RepositoryName $repositoryName -BranchName $branchName
            $branchAgain = $branch | Get-GitHubRepositoryBranch

            It 'Should return the expected branch name' {
                $branchAgain.name | Should -Be $branchName
            }

            It 'Should have the exected type and addititional properties' {
                $branchAgain.PSObject.TypeNames[0] | Should -Be 'GitHub.Branch'
                $branchAgain.RepositoryUrl | Should -Be $repo.RepositoryUrl
                $branchAgain.BranchName | Should -Be $branchAgain.name
            }
        }
    }

    Describe 'GitHubBranches\New-GitHubRepositoryBranch' {
        Context 'When creating a new GitHub repository branch' {
            BeforeAll -Scriptblock {
                $repoName = [Guid]::NewGuid().Guid
                $originBranchName = 'master'
                $newBranchName = 'develop'
                $newGitHubRepositoryParms = @{
                    RepositoryName = $repoName
                    AutoInit = $true
                }
                $repo = New-GitHubRepository @newGitHubRepositoryParms

                $newGitHubRepositoryBranchParms = @{
                    OwnerName = $script:ownerName
                    RepositoryName = $repoName
                    Name = $newBranchName
                    OriginBranchName = $originBranchName
                }
                $branch = New-GitHubRepositoryBranch @newGitHubRepositoryBranchParms
            }

            It 'Should return an object of the correct type' {
                $branch | Should -BeOfType PSCustomObject
            }

            It 'Should return the correct properties' {
                $branch.ref | Should -Be "refs/heads/$newBranchName"
            }

            It 'Should have created the branch' {
                $getGitHubRepositoryBranchParms = @{
                    OwnerName = $script:ownerName
                    RepositoryName = $repoName
                    Name = $newBranchName
                }
                { Get-GitHubRepositoryBranch @getGitHubRepositoryBranchParms } |
                    Should -Not -Throw
            }

            Context 'When the origin branch cannot be found' {
                BeforeAll -Scriptblock {
                    $missingOriginBranchName = 'Missing-Branch'
                }

                It 'Should throw the correct exception' {
                    $errorMessage = "Origin branch $missingOriginBranchName not found"

                    $newGitHubRepositoryBranchParms = @{
                        OwnerName = $script:ownerName
                        RepositoryName = $repoName
                        Name = $newBranchName
                        OriginBranchName = $missingOriginBranchName
                    }
                    { New-GitHubRepositoryBranch @newGitHubRepositoryBranchParms } |
                        Should -Throw $errorMessage
                }
            }

            Context 'When Get-GitHubRepositoryBranch throws an undefined HttpResponseException' {
                It 'Should throw the correct exception' {
                    $newGitHubRepositoryBranchParms = @{
                        OwnerName = $script:ownerName
                        RepositoryName = 'test'
                        Name = 'test'
                        OriginBranchName = 'test'
                    }
                    { New-GitHubRepositoryBranch @newGitHubRepositoryBranchParms } |
                        Should -Throw 'Not Found'
                }
            }

            AfterAll -ScriptBlock {
                if ($repo)
                {
                    Remove-GitHubRepository -Uri $repo.svn_url -Confirm:$false
                }
            }
        }
    }

    Describe 'GitHubBranches\Remove-GitHubRepositoryBranch' {
        BeforeAll -Scriptblock {
            $repoName = [Guid]::NewGuid().Guid
            $originBranchName = 'master'
            $newBranchName = 'develop'
            $newGitHubRepositoryParms = @{
                RepositoryName = $repoName
                AutoInit = $true
            }
            $repo = New-GitHubRepository @newGitHubRepositoryParms

            $newGitHubRepositoryBranchParms = @{
                OwnerName = $script:ownerName
                RepositoryName = $repoName
                Name = $newBranchName
                OriginBranchName = $originBranchName
            }
            $branch = New-GitHubRepositoryBranch @newGitHubRepositoryBranchParms
        }

        It 'Should not throw an exception' {
            $removeGitHubRepositoryBranchParms = @{
                OwnerName = $script:ownerName
                RepositoryName = $repoName
                Name = $newBranchName
                Confirm = $false
            }
            { Remove-GitHubRepositoryBranch @removeGitHubRepositoryBranchParms } |
                Should -Not -Throw
        }

        It 'Should have removed the branch' {
            $getGitHubRepositoryBranchParms = @{
                OwnerName = $script:ownerName
                RepositoryName = $repoName
                Name = $newBranchName
            }
            { Get-GitHubRepositoryBranch @getGitHubRepositoryBranchParms } |
                Should -Throw
        }

        AfterAll -ScriptBlock {
            if ($repo)
            {
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
