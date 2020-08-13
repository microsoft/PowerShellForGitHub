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

Set-StrictMode -Version 1.0

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

            It 'Should have the expected type and addititional properties' {
                $branches[0].PSObject.TypeNames[0] | Should -Be 'GitHub.Branch'
                $branches[0].RepositoryUrl | Should -Be $repo.RepositoryUrl
                $branches[0].BranchName | Should -Be $branches[0].name
                $branches[0].Sha | Should -Be $branches[0].commit.sha
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

            It 'Should have the expected type and addititional properties' {
                $branches[0].PSObject.TypeNames[0] | Should -Be 'GitHub.Branch'
                $branches[0].RepositoryUrl | Should -Be $repo.RepositoryUrl
                $branches[0].BranchName | Should -Be $branches[0].name
                $branches[0].Sha | Should -Be $branches[0].commit.sha
            }
        }

        Context 'Getting a specific branch for a repository with parameters' {
            $branch = Get-GitHubRepositoryBranch -OwnerName $script:ownerName -RepositoryName $repositoryName -BranchName $branchName

            It 'Should return the expected branch name' {
                $branch.name | Should -Be $branchName
            }

            It 'Should have the expected type and addititional properties' {
                $branch.PSObject.TypeNames[0] | Should -Be 'GitHub.Branch'
                $branch.RepositoryUrl | Should -Be $repo.RepositoryUrl
                $branch.BranchName | Should -Be $branch.name
                $branch.Sha | Should -Be $branch.commit.sha
            }
        }

        Context 'Getting a specific branch for a repository with the repo on the pipeline' {
            $branch = $repo | Get-GitHubRepositoryBranch -BranchName $branchName

            It 'Should return the expected branch name' {
                $branch.name | Should -Be $branchName
            }

            It 'Should have the expected type and addititional properties' {
                $branch.PSObject.TypeNames[0] | Should -Be 'GitHub.Branch'
                $branch.RepositoryUrl | Should -Be $repo.RepositoryUrl
                $branch.BranchName | Should -Be $branch.name
                $branch.Sha | Should -Be $branch.commit.sha
            }
        }

        Context 'Getting a specific branch for a repository with the branch object on the pipeline' {
            $branch = Get-GitHubRepositoryBranch -OwnerName $script:ownerName -RepositoryName $repositoryName -BranchName $branchName
            $branchAgain = $branch | Get-GitHubRepositoryBranch

            It 'Should return the expected branch name' {
                $branchAgain.name | Should -Be $branchName
            }

            It 'Should have the expected type and addititional properties' {
                $branchAgain.PSObject.TypeNames[0] | Should -Be 'GitHub.Branch'
                $branchAgain.RepositoryUrl | Should -Be $repo.RepositoryUrl
                $branchAgain.BranchName | Should -Be $branchAgain.name
                $branchAgain.Sha | Should -Be $branchAgain.commit.sha
            }
        }
    }

    Describe 'GitHubBranches\New-GitHubRepositoryBranch' {
        BeforeAll {
            $repoName = [Guid]::NewGuid().Guid
            $originBranchName = 'master'
            $newGitHubRepositoryParms = @{
                RepositoryName = $repoName
                AutoInit = $true
            }

            $repo = New-GitHubRepository @newGitHubRepositoryParms
        }

        Context 'When creating a new GitHub repository branch' {
            Context 'When using non-pipelined parameters' {
                BeforeAll {
                    $newBranchName = 'develop1'
                    $newGitHubRepositoryBranchParms = @{
                        OwnerName = $script:ownerName
                        RepositoryName = $repoName
                        BranchName = $originBranchName
                        TargetBranchName = $newBranchName
                    }

                    $branch = New-GitHubRepositoryBranch @newGitHubRepositoryBranchParms
                }

                It 'Should have the expected type and addititional properties' {
                    $branch.PSObject.TypeNames[0] | Should -Be 'GitHub.Branch'
                    $branch.RepositoryUrl | Should -Be $repo.RepositoryUrl
                    $branch.BranchName | Should -Be $newBranchName
                    $branch.Sha | Should -Be $branch.object.sha
                }

                It 'Should have created the branch' {
                    $getGitHubRepositoryBranchParms = @{
                        OwnerName = $script:ownerName
                        RepositoryName = $repoName
                        BranchName = $newBranchName
                    }

                    { Get-GitHubRepositoryBranch @getGitHubRepositoryBranchParms } |
                        Should -Not -Throw
                }
            }

            Context 'When using pipelined parameters' {
                Context 'When providing pipeline input for the "Uri" parameter' {
                    BeforeAll {
                        $newBranchName = 'develop2'
                        $branch = $repo | New-GitHubRepositoryBranch -TargetBranchName $newBranchName
                    }

                    It 'Should have the expected type and addititional properties' {
                        $branch.PSObject.TypeNames[0] | Should -Be 'GitHub.Branch'
                        $branch.RepositoryUrl | Should -Be $repo.RepositoryUrl
                        $branch.BranchName | Should -Be $newBranchName
                        $branch.Sha | Should -Be $branch.object.sha
                    }

                    It 'Should have created the branch' {
                        $getGitHubRepositoryBranchParms = @{
                            OwnerName = $script:ownerName
                            RepositoryName = $repoName
                            BranchName = $newBranchName
                        }

                        { Get-GitHubRepositoryBranch @getGitHubRepositoryBranchParms } |
                            Should -Not -Throw
                    }
                }

                Context 'When providing pipeline input for the "TargetBranchName" parameter' {
                    BeforeAll {
                        $newBranchName = 'develop3'
                        $branch = $newBranchName | New-GitHubRepositoryBranch -Uri $repo.html_url
                    }

                    It 'Should have the expected type and addititional properties' {
                        $branch.PSObject.TypeNames[0] | Should -Be 'GitHub.Branch'
                        $branch.RepositoryUrl | Should -Be $repo.RepositoryUrl
                        $branch.BranchName | Should -Be $newBranchName
                        $branch.Sha | Should -Be $branch.object.sha
                    }

                    It 'Should have created the branch' {
                        $getGitHubRepositoryBranchParms = @{
                            OwnerName = $script:ownerName
                            RepositoryName = $repoName
                            BranchName = $newBranchName
                        }

                        { Get-GitHubRepositoryBranch @getGitHubRepositoryBranchParms } |
                            Should -Not -Throw
                    }
                }

                Context 'When providing the GitHub.Branch on the pipeline' {
                    BeforeAll {
                        $baseBranchName = 'develop4'
                        $baseBranch = $baseBranchName | New-GitHubRepositoryBranch -Uri $repo.html_url

                        $newBranchName = 'develop5'
                        $branch = $baseBranch | New-GitHubRepositoryBranch -TargetBranchName $newBranchName
                    }

                    It 'Should have been created from the right Sha' {
                        $branch.Sha | Should -Be $baseBranch.Sha
                    }

                    It 'Should have the expected type and addititional properties' {
                        $branch.PSObject.TypeNames[0] | Should -Be 'GitHub.Branch'
                        $branch.RepositoryUrl | Should -Be $repo.RepositoryUrl
                        $branch.BranchName | Should -Be $newBranchName
                        $branch.Sha | Should -Be $branch.object.sha
                    }

                    It 'Should have created the branch' {
                        $getGitHubRepositoryBranchParms = @{
                            OwnerName = $script:ownerName
                            RepositoryName = $repoName
                            BranchName = $newBranchName
                        }

                        { Get-GitHubRepositoryBranch @getGitHubRepositoryBranchParms } |
                            Should -Not -Throw
                    }
                }

                Context 'When providing the Repo on the pipeline and specifying the Sha' {
                    BeforeAll {
                        $baseBranchName = 'sha1'
                        $baseBranch = $baseBranchName | New-GitHubRepositoryBranch -Uri $repo.html_url

                        $newBranchName = 'sha2'
                        $branch = $repo | New-GitHubRepositoryBranch -Sha $baseBranch.Sha -TargetBranchName $newBranchName
                    }

                    It 'Should have been created from the right Sha' {
                        $branch.Sha | Should -Be $baseBranch.Sha
                    }

                    It 'Should have the expected type and addititional properties' {
                        $branch.PSObject.TypeNames[0] | Should -Be 'GitHub.Branch'
                        $branch.RepositoryUrl | Should -Be $repo.RepositoryUrl
                        $branch.BranchName | Should -Be $newBranchName
                        $branch.Sha | Should -Be $branch.object.sha
                    }

                    It 'Should have created the branch' {
                        $getGitHubRepositoryBranchParms = @{
                            OwnerName = $script:ownerName
                            RepositoryName = $repoName
                            BranchName = $newBranchName
                        }

                        { Get-GitHubRepositoryBranch @getGitHubRepositoryBranchParms } |
                            Should -Not -Throw
                    }
                }
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
                        BranchName = $missingOriginBranchName
                        TargetBranchName = $newBranchName
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
                        BranchName = 'test'
                        TargetBranchName = 'test'
                    }

                    { New-GitHubRepositoryBranch @newGitHubRepositoryBranchParms } |
                        Should -Throw 'Not Found'
                }
            }
        }

        AfterAll -ScriptBlock {
            if (Get-Variable -Name repo -ErrorAction SilentlyContinue)
            {
                Remove-GitHubRepository -Uri $repo.svn_url -Confirm:$false
            }
        }
    }

    Describe 'GitHubBranches\Remove-GitHubRepositoryBranch' {
        BeforeAll -Scriptblock {
            $repoName = [Guid]::NewGuid().Guid
            $originBranchName = 'master'
            $newGitHubRepositoryParms = @{
                RepositoryName = $repoName
                AutoInit = $true
            }

            $repo = New-GitHubRepository @newGitHubRepositoryParms
        }

        Context 'When using non-pipelined parameters' {
            BeforeAll {
                $newBranchName = 'develop1'
                $newGitHubRepositoryBranchParms = @{
                    OwnerName = $script:ownerName
                    RepositoryName = $repoName
                    BranchName = $originBranchName
                    TargetBranchName = $newBranchName
                }

                $branch = New-GitHubRepositoryBranch @newGitHubRepositoryBranchParms
            }

            It 'Should not throw an exception' {
                $removeGitHubRepositoryBranchParms = @{
                    OwnerName = $script:ownerName
                    RepositoryName = $repoName
                    BranchName = $newBranchName
                    Confirm = $false
                }

                { Remove-GitHubRepositoryBranch @removeGitHubRepositoryBranchParms } |
                    Should -Not -Throw
            }

            It 'Should have removed the branch' {
                $getGitHubRepositoryBranchParms = @{
                    OwnerName = $script:ownerName
                    RepositoryName = $repoName
                    BranchName = $newBranchName
                }

                { Get-GitHubRepositoryBranch @getGitHubRepositoryBranchParms } |
                    Should -Throw
            }
        }

        Context 'When using pipelined parameters' {
            BeforeAll {
                $newBranchName = 'develop2'
                $newGitHubRepositoryBranchParms = @{
                    OwnerName = $script:ownerName
                    RepositoryName = $repoName
                    BranchName = $originBranchName
                    TargetBranchName = $newBranchName
                }

                $branch = New-GitHubRepositoryBranch @newGitHubRepositoryBranchParms
            }

            It 'Should not throw an exception' {
                { $branch | Remove-GitHubRepositoryBranch -Force } | Should -Not -Throw
            }

            It 'Should have removed the branch' {
                $getGitHubRepositoryBranchParms = @{
                    OwnerName = $script:ownerName
                    RepositoryName = $repoName
                    BranchName = $newBranchName
                }

                { Get-GitHubRepositoryBranch @getGitHubRepositoryBranchParms } |
                    Should -Throw
            }
        }

        AfterAll -ScriptBlock {
            if (Get-Variable -Name repo -ErrorAction SilentlyContinue)
            {
                Remove-GitHubRepository -Uri $repo.svn_url -Confirm:$false
            }
        }
    }
    Describe 'GitHubBranches\Get-GitHubRepositoryBranchProtectionRule' {
        Context 'When getting GitHub repository branch protection' {
            BeforeAll {
                $repoName = [Guid]::NewGuid().Guid
                $branchName = 'master'
                $protectionUrl = ("https://api.github.com/repos/$script:ownerName/" +
                    "$repoName/branches/$branchName/protection")
                $repo = New-GitHubRepository -RepositoryName $repoName -AutoInit
                New-GitHubRepositoryBranchProtectionRule -Uri $repo.svn_url -BranchName $branchName | Out-Null
                $rule = Get-GitHubRepositoryBranchProtectionRule -Uri $repo.svn_url -BranchName $branchName
            }

            It 'Should have the expected type and addititional properties' {
                $rule.PSObject.TypeNames[0] | Should -Be 'GitHub.BranchProtectionRule'
                $rule.url | Should -Be $protectionUrl
                $rule.enforce_admins.enabled | Should -BeFalse
                $rule.required_linear_history.enabled | Should -BeFalse
                $rule.allow_force_pushes.enabled | Should -BeFalse
                $rule.allow_deletions.enabled | Should -BeFalse
                $rule.RepositoryUrl | Should -Be $repo.RepositoryUrl
            }

            Context 'When specifying the "Uri" parameter through the pipeline' {
                BeforeAll {
                    $rule = $repo | Get-GitHubRepositoryBranchProtectionRule -BranchName $branchName
                }

                It 'Should have the expected type and addititional properties' {
                    $rule.PSObject.TypeNames[0] | Should -Be 'GitHub.BranchProtectionRule'
                    $rule.url | Should -Be $protectionUrl
                    $rule.enforce_admins.enabled | Should -BeFalse
                    $rule.required_linear_history.enabled | Should -BeFalse
                    $rule.allow_force_pushes.enabled | Should -BeFalse
                    $rule.allow_deletions.enabled | Should -BeFalse
                    $rule.RepositoryUrl | Should -Be $repo.RepositoryUrl
                }
            }

            Context 'When specifying the "BranchName" and "Uri" parameters through the pipeline' {
                BeforeAll {
                    $branch = Get-GitHubRepositoryBranch -Uri $repo.svn_url -BranchName $branchName
                    $rule = $branch | Get-GitHubRepositoryBranchProtectionRule
                }

                It 'Should have the expected type and addititional properties' {
                    $rule.PSObject.TypeNames[0] | Should -Be 'GitHub.BranchProtectionRule'
                    $rule.url | Should -Be $protectionUrl
                    $rule.enforce_admins.enabled | Should -BeFalse
                    $rule.required_linear_history.enabled | Should -BeFalse
                    $rule.allow_force_pushes.enabled | Should -BeFalse
                    $rule.allow_deletions.enabled | Should -BeFalse
                    $rule.RepositoryUrl | Should -Be $repo.RepositoryUrl
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

    Describe 'GitHubBranches\New-GitHubRepositoryBranchProtectionRule' {
        BeforeAll {
            $repoName = [Guid]::NewGuid().Guid
            $branchName = 'master'
            $newGitHubRepositoryParms = @{
                OrganizationName = $script:organizationName
                RepositoryName = $repoName
                AutoInit = $true
            }

            $repo = New-GitHubRepository @newGitHubRepositoryParms
        }

        Context 'When setting base protection options' {
            BeforeAll {
                $targetBranchName = [Guid]::NewGuid().Guid

                $protectionUrl = ("https://api.github.com/repos/$script:organizationName/" +
                    "$repoName/branches/$targetBranchName/protection")

                $newGitHubRepositoryBranchParms = @{
                    OwnerName = $script:organizationName
                    RepositoryName = $repoName
                    BranchName = $branchName
                    TargetBranchName = $targetBranchName
                }

                $branch = New-GitHubRepositoryBranch @newGitHubRepositoryBranchParms

                $newGitHubRepositoryBranchProtectionParms = @{
                    Uri = $repo.svn_url
                    BranchName = $targetBranchName
                    EnforceAdmins = $true
                    RequireLinearHistory = $true
                    AllowForcePushes = $true
                    AllowDeletions = $true
                }

                $rule = New-GitHubRepositoryBranchProtectionRule @newGitHubRepositoryBranchProtectionParms
            }

            It 'Should have the expected type and addititional properties' {
                $rule.PSObject.TypeNames[0] | Should -Be 'GitHub.BranchProtectionRule'
                $rule.url | Should -Be $protectionUrl
                $rule.enforce_admins.enabled | Should -BeTrue
                $rule.required_linear_history.enabled | Should -BeTrue
                $rule.allow_force_pushes.enabled | Should -BeTrue
                $rule.allow_deletions.enabled | Should -BeTrue
                $rule.RepositoryUrl | Should -Be $repo.RepositoryUrl
            }
        }

        Context 'When setting required status checks' {
            BeforeAll {
                $targetBranchName = [Guid]::NewGuid().Guid

                $protectionUrl = ("https://api.github.com/repos/$script:organizationName/" +
                    "$repoName/branches/$targetBranchName/protection")

                $newGitHubRepositoryBranchParms = @{
                    OwnerName = $script:organizationName
                    RepositoryName = $repoName
                    BranchName = $branchName
                    TargetBranchName = $targetBranchName
                }

                $branch = New-GitHubRepositoryBranch @newGitHubRepositoryBranchParms

                $statusChecks = 'test'

                $newGitHubRepositoryBranchProtectionParms = @{
                    Uri = $repo.svn_url
                    BranchName = $targetBranchName
                    RequireUpToDateBranches = $true
                    StatusChecks = $statusChecks
                }

                $rule = New-GitHubRepositoryBranchProtectionRule @newGitHubRepositoryBranchProtectionParms
            }

            It 'Should have the expected type and addititional properties' {
                $rule.PSObject.TypeNames[0] | Should -Be 'GitHub.BranchProtectionRule'
                $rule.url | Should -Be $protectionUrl
                $rule.required_status_checks.strict | Should -BeTrue
                $rule.required_status_checks.contexts | Should -Be $statusChecks
            }
        }

        Context 'When setting required pull request reviews' {
            BeforeAll {
                $targetBranchName = [Guid]::NewGuid().Guid

                $protectionUrl = ("https://api.github.com/repos/$script:organizationName/" +
                    "$repoName/branches/$targetBranchName/protection")

                $newGitHubRepositoryBranchParms = @{
                    OwnerName = $script:organizationName
                    RepositoryName = $repoName
                    BranchName = $branchName
                    TargetBranchName = $targetBranchName
                }

                $branch = New-GitHubRepositoryBranch @newGitHubRepositoryBranchParms

                $newGitHubRepositoryBranchProtectionParms = @{
                    Uri = $repo.svn_url
                    BranchName = $targetBranchName
                    DismissalUsers = $script:ownerName
                    DismissStaleReviews = $true
                    RequireCodeOwnerReviews = $true
                    RequiredApprovingReviewCount = 1
                }

                $rule = New-GitHubRepositoryBranchProtectionRule @newGitHubRepositoryBranchProtectionParms
            }

            It 'Should have the expected type and addititional properties' {
                $rule.PSObject.TypeNames[0] | Should -Be 'GitHub.BranchProtectionRule'
                $rule.url | Should -Be $protectionUrl
                $rule.required_pull_request_reviews.dismissal_restrictions.users.login |
                Should -Contain $script:OwnerName
            }
        }

        Context 'When setting push restrictions' {
            BeforeAll {
                $targetBranchName = [Guid]::NewGuid().Guid

                $protectionUrl = ("https://api.github.com/repos/$script:organizationName/" +
                    "$repoName/branches/$targetBranchName/protection")

                $newGitHubRepositoryBranchParms = @{
                    OwnerName = $script:organizationName
                    RepositoryName = $repoName
                    BranchName = $branchName
                    TargetBranchName = $targetBranchName
                }

                $branch = New-GitHubRepositoryBranch @newGitHubRepositoryBranchParms

                $newGitHubRepositoryBranchProtectionParms = @{
                    Uri = $repo.svn_url
                    BranchName = $targetBranchName
                    RestrictPushUsers = $script:OwnerName
                }

                $rule = New-GitHubRepositoryBranchProtectionRule @newGitHubRepositoryBranchProtectionParms
            }

            It 'Should have the expected type and addititional properties' {
                $rule.PSObject.TypeNames[0] | Should -Be 'GitHub.BranchProtectionRule'
                $rule.url | Should -Be $protectionUrl
                $rule.restrictions.users.login | Should -Contain $script:OwnerName
            }
        }

        Context 'When the branch rule already exists' {
            BeforeAll {
                $targetBranchName = [Guid]::NewGuid().Guid

                $newGitHubRepositoryBranchParms = @{
                    OwnerName = $script:organizationName
                    RepositoryName = $repoName
                    BranchName = $branchName
                    TargetBranchName = $targetBranchName
                }

                $branch = New-GitHubRepositoryBranch @newGitHubRepositoryBranchParms

                $newGitHubRepositoryBranchProtectionParms = @{
                    Uri = $repo.svn_url
                    BranchName = $targetBranchName
                }

                $rule = New-GitHubRepositoryBranchProtectionRule @newGitHubRepositoryBranchProtectionParms
            }

            It 'Should throw the correct exception' {
                $errorMessage = "Branch protection rule for branch $targetBranchName already exists on Repository $repoName"
                { New-GitHubRepositoryBranchProtectionRule @newGitHubRepositoryBranchProtectionParms } |
                    Should -Throw $errorMessage
            }
        }

        Context 'When specifying the "Uri" parameter through the pipeline' {
            BeforeAll {
                $targetBranchName = [Guid]::NewGuid().Guid

                $newGitHubRepositoryBranchParms = @{
                    OwnerName = $script:organizationName
                    RepositoryName = $repoName
                    BranchName = $branchName
                    TargetBranchName = $targetBranchName
                }

                $branch = New-GitHubRepositoryBranch @newGitHubRepositoryBranchParms

                $protectionUrl = ("https://api.github.com/repos/$script:organizationName/" +
                "$repoName/branches/$targetBranchName/protection")

                $rule = $repo | New-GitHubRepositoryBranchProtectionRule -BranchName $targetBranchName
            }

            It 'Should have the expected type and addititional properties' {
                $rule.PSObject.TypeNames[0] | Should -Be 'GitHub.BranchProtectionRule'
                $rule.url | Should -Be $protectionUrl
                $rule.enforce_admins.enabled | Should -BeFalse
                $rule.required_linear_history.enabled | Should -BeFalse
                $rule.allow_force_pushes.enabled | Should -BeFalse
                $rule.allow_deletions.enabled | Should -BeFalse
                $rule.RepositoryUrl | Should -Be $repo.RepositoryUrl
            }
        }

        Context 'When specifying the "BranchName" and "Uri" parameters through the pipeline' {
            BeforeAll {
                $targetBranchName = [Guid]::NewGuid().Guid

                $newGitHubRepositoryBranchParms = @{
                    OwnerName = $script:organizationName
                    RepositoryName = $repoName
                    BranchName = $branchName
                    TargetBranchName = $targetBranchName
                }

                $branch = New-GitHubRepositoryBranch @newGitHubRepositoryBranchParms

                $protectionUrl = ("https://api.github.com/repos/$script:organizationName/" +
                "$repoName/branches/$targetBranchName/protection")

                $rule = $branch | New-GitHubRepositoryBranchProtectionRule
            }

            It 'Should have the expected type and addititional properties' {
                $rule.PSObject.TypeNames[0] | Should -Be 'GitHub.BranchProtectionRule'
                $rule.url | Should -Be $protectionUrl
                $rule.enforce_admins.enabled | Should -BeFalse
                $rule.required_linear_history.enabled | Should -BeFalse
                $rule.allow_force_pushes.enabled | Should -BeFalse
                $rule.allow_deletions.enabled | Should -BeFalse
                $rule.RepositoryUrl | Should -Be $repo.RepositoryUrl
            }
        }

        AfterAll -ScriptBlock {
            if ($repo)
            {
                Remove-GitHubRepository -Uri $repo.svn_url -Confirm:$false
            }
        }
    }

    Describe 'GitHubBranches\Remove-GitHubRepositoryBranchProtectionRule' {
        Context 'When removing GitHub repository branch protection' {
            BeforeAll {
                $repoName = [Guid]::NewGuid().Guid
                $branchName = 'master'
                $repo = New-GitHubRepository -RepositoryName $repoName -AutoInit

                New-GitHubRepositoryBranchProtectionRule -Uri $repo.svn_url -BranchName $branchName |
                    Out-Null
            }

            It 'Should not throw' {
                { Remove-GitHubRepositoryBranchProtectionRule -Uri $repo.svn_url -BranchName $branchName -Force } |
                    Should -Not -Throw
            }

            It 'Should have removed the protection rule' {
                { Get-GitHubRepositoryBranchProtectionRule -Uri $repo.svn_url -BranchName $branchName } |
                    Should -Throw
            }

            Context 'When specifying the "Uri" parameter through the pipeline' {
                BeforeAll {
                    $rule = New-GitHubRepositoryBranchProtectionRule -Uri $repo.svn_url -BranchName $branchName
                }

                It 'Should not throw' {
                    { $repo | Remove-GitHubRepositoryBranchProtectionRule -BranchName $branchName -Force} |
                        Should -Not -Throw
                }

                It 'Should have removed the protection rule' {
                    { Get-GitHubRepositoryBranchProtectionRule -Uri $repo.svn_url -BranchName $branchName } |
                        Should -Throw
                }
            }

            Context 'When specifying the "Uri" and "BranchName" parameters through the pipeline' {
                BeforeAll {
                    $rule = New-GitHubRepositoryBranchProtectionRule -Uri $repo.svn_url -BranchName $branchName
                }

                It 'Should not throw' {
                    { $rule | Remove-GitHubRepositoryBranchProtectionRule -Force } |
                        Should -Not -Throw
                }

                It 'Should have removed the protection rule' {
                    { Get-GitHubRepositoryBranchProtectionRule -Uri $repo.svn_url -BranchName $branchName } |
                        Should -Throw
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
