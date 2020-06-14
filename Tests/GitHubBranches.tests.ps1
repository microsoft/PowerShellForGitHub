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

    Describe 'GitHubBranches\Get-GitHubRepositoryBranchProtectionRule' {
        Context 'When getting GitHub repository branch protection' {
            BeforeAll {
                $repoName = [Guid]::NewGuid().Guid
                $branchName = 'master'
                $repo = New-GitHubRepository -RepositoryName $repoName -AutoInit
                Set-GitHubRepositoryBranchProtectionRule -Name $branchName -Uri $repo.svn_url | Out-Null
                $protection = Get-GitHubRepositoryBranchProtectionRule -Name $branchName -uri $repo.svn_url
            }

            It 'Should return an object of the correct type' {
                $protection | Should -BeOfType PSCustomObject
            }

            It 'Should return the correct properties' {
                $protection.url |
                    Should -Be "https://api.github.com/repos/$script:ownerName/$repoName/branches/$branchName/protection"
            }

            AfterAll -ScriptBlock {
                if ($repo)
                {
                    Remove-GitHubRepository -Uri $repo.svn_url -Confirm:$false
                }
            }
        }
    }

    Describe 'GitHubBranches\Set-GitHubRepositoryBranchProtectionRule' {

        Context 'When setting GitHub repository branch protection' {
            BeforeAll {
                $repoName = [Guid]::NewGuid().Guid
                $branchName = 'master'
                $protectionUrl = "https://api.github.com/repos/$script:organizationName/" +
                    "$repoName/branches/$branchName/protection"
                $newGitHubRepositoryParms = @{
                    OrganizationName = $script:organizationName
                    RepositoryName = $repoName
                    AutoInit = $true
                }
                $repo = New-GitHubRepository @newGitHubRepositoryParms
            }

            Context 'When setting base protection options' {
                BeforeAll {
                    $setGitHubRepositoryBranchProtectionParms = @{
                        Name = $branchName
                        Uri = $repo.svn_url
                        EnforceAdmins = $true
                        RequiredLinearHistory = $true
                        AllowForcePushes = $true
                        AllowDeletions = $true
                    }
                    $protection = Set-GitHubRepositoryBranchProtectionRule @setGitHubRepositoryBranchProtectionParms
                }

                It 'Should return an object of the correct type' {
                    $protection | Should -BeOfType PSCustomObject
                }

                It 'Should return the correct properties' {
                    $protection.url | Should -Be $protectionUrl
                    $protection.enforce_admins.enabled | Should -BeTrue
                    $protection.required_linear_history.enabled | Should -BeTrue
                    $protection.allow_force_pushes | Should -BeTrue
                    $protection.allow_deletions | Should -BeTrue
                }
            }

            Context 'When setting required status checks' {
                BeforeAll {
                    $statusChecks = 'test'
                    $setGitHubRepositoryBranchProtectionParms = @{
                        Name = $branchName
                        Uri = $repo.svn_url
                        RequireUpToDateBranches = $true
                        StatusChecks = $statusChecks
                    }
                    $protection = Set-GitHubRepositoryBranchProtectionRule @setGitHubRepositoryBranchProtectionParms
                }

                It 'Should return an object of the correct type' {
                    $protection | Should -BeOfType PSCustomObject
                }

                It 'Should return the correct properties' {
                    $protection.url | Should -Be $protectionUrl
                    $protection.required_status_checks.strict | Should -BeTrue
                    $protection.required_status_checks.contexts | Should -Be $statusChecks
                }
            }

            Context 'When setting required pull request reviews' {
                BeforeAll {
                    $setGitHubRepositoryBranchProtectionParms = @{
                        Name = $branchName
                        Uri = $repo.svn_url
                        DismissalUsers = $script:OwnerName
                        DismissStaleReviews = $true
                        RequireCodeOwnerReviews = $true
                        RequiredApprovingReviewCount = 1
                    }
                    $protection = Set-GitHubRepositoryBranchProtectionRule @setGitHubRepositoryBranchProtectionParms
                }

                It 'Should return an object of the correct type' {
                    $protection | Should -BeOfType PSCustomObject
                }

                It 'Should return the correct properties' {
                    $protection.url | Should -Be $protectionUrl
                    $protection.required_pull_request_reviews.dismissal_restrictions.users.login |
                        Should -Contain $script:OwnerName
                }
            }

            Context 'When setting push restrictions' {
                BeforeAll {
                    $setGitHubRepositoryBranchProtectionParms = @{
                        Name = $branchName
                        Uri = $repo.svn_url
                        RestrictPushUsers = $script:OwnerName
                    }
                    $protection = Set-GitHubRepositoryBranchProtectionRule @setGitHubRepositoryBranchProtectionParms
                }

                It 'Should return an object of the correct type' {
                    $protection | Should -BeOfType PSCustomObject
                }

                It 'Should return the correct properties' {
                    $protection.url | Should -Be $protectionUrl
                    $protection.restrictions.users.login | Should -Contain $script:OwnerName
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

    Describe 'GitHubBranches\Remove-GitHubRepositoryBranchProtectionRule' {
        Context 'When removing GitHub repository branch protection' {
            BeforeAll {
                $repoName = [Guid]::NewGuid().Guid
                $branchName = 'master'
                $repo = New-GitHubRepository -RepositoryName $repoName -AutoInit
                Set-GitHubRepositoryBranchProtectionRule -Name $branchName -Uri $repo.svn_url | Out-Null
            }

            It 'Should not throw' {
                { Remove-GitHubRepositoryBranchProtectionRule -Name $branchName -Uri $repo.svn_url -Force } |
                    Should -Not -Throw
            }

            AfterAll -ScriptBlock {
                if ($repo)
                {
                    Remove-GitHubRepository -Uri $repo.svn_url -Confirm:$false
                }
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
