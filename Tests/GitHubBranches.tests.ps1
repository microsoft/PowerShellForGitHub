# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

<#
.Synopsis
   Tests for GitHubBranches.ps1 module
#>

[CmdletBinding()]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '',
    Justification = 'Suppress false positives in Pester code blocks')]
param()

BeforeAll {
    # This is common test code setup logic for all Pester test files
    $moduleRootPath = Split-Path -Path $PSScriptRoot -Parent
    . (Join-Path -Path $moduleRootPath -ChildPath 'Tests\Common.ps1')
}

Set-StrictMode -Version 1.0

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
        BeforeAll {
            $branches = @(Get-GitHubRepositoryBranch -OwnerName $script:ownerName -RepositoryName $repositoryName)
        }

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
        BeforeAll {
            $branches = @($repo | Get-GitHubRepositoryBranch)
        }

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
        BeforeAll {
            $branch = Get-GitHubRepositoryBranch -OwnerName $script:ownerName -RepositoryName $repositoryName -BranchName $branchName
        }

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
        BeforeAll {
            $branch = $repo | Get-GitHubRepositoryBranch -BranchName $branchName
        }

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
        BeforeAll {
            $branch = Get-GitHubRepositoryBranch -OwnerName $script:ownerName -RepositoryName $repositoryName -BranchName $branchName
            $branchAgain = $branch | Get-GitHubRepositoryBranch
        }

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
                $newBranchName = 'sha2'
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

                { New-GitHubRepositoryBranch @newGitHubRepositoryBranchParms } | Should -Throw
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
                RestrictPushUser = $script:OwnerName
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
    BeforeAll {
        $repoName = [Guid]::NewGuid().Guid
        $branchName = 'master'
        $repo = New-GitHubRepository -RepositoryName $repoName -AutoInit

        New-GitHubRepositoryBranchProtectionRule -Uri $repo.svn_url -BranchName $branchName |
        Out-Null
    }

    Context 'When removing GitHub repository branch protection' {
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
                { $repo | Remove-GitHubRepositoryBranchProtectionRule -BranchName $branchName -Force } |
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

    }
    AfterAll -ScriptBlock {
        if ($repo)
        {
            Remove-GitHubRepository -Uri $repo.svn_url -Confirm:$false
        }
    }
}

Describe 'GitHubBranches\Get-GitHubRepositoryBranchPatternProtectionRule' {
    BeforeAll {
        $repoName = [Guid]::NewGuid().Guid
        $branchPatternName = [Guid]::NewGuid().Guid + '/**/*'

        $newGitHubRepositoryParms = @{
            OrganizationName = $script:organizationName
            RepositoryName = $repoName
        }
        $repo = New-GitHubRepository @newGitHubRepositoryParms

        $teamName = [Guid]::NewGuid().Guid

        $newGithubTeamParms = @{
            OrganizationName = $script:OrganizationName
            TeamName = $teamName
        }
        $team = New-GitHubTeam @newGithubTeamParms

        $setGitHubRepositoryTeamPermissionParms = @{
            Uri = $repo.svn_url
            TeamSlug = $team.slug
            Permission = 'Push'
        }
        Set-GitHubRepositoryTeamPermission @setGitHubRepositoryTeamPermissionParms
    }

    Context 'When getting branch pattern protection default options' {
        BeforeAll {
            $branchPatternName = [Guid]::NewGuid().Guid + '/**/*'

            New-GitHubRepositoryBranchPatternProtectionRule -Uri $repo.svn_url -BranchPatternName $branchPatternName

            $rule = Get-GitHubRepositoryBranchPatternProtectionRule -Uri $repo.svn_url -BranchPatternName $branchPatternName
        }

        It 'Should have the expected type and addititional properties' {
            $rule.PSObject.TypeNames[0] | Should -Be 'GitHub.BranchPatternProtectionRule'
            $rule.pattern | Should -Be $branchPatternName
            $rule.RepositoryUrl | Should -Be $repo.RepositoryUrl
            $rule.requiresApprovingReviews | Should -BeFalse
            $rule.requiredApprovingReviewCount | Should -BeNullOrEmpty
            $rule.dismissesStaleReviews | Should -BeFalse
            $rule.requiresCodeOwnerReviews | Should -BeFalse
            $rule.restrictsReviewDismissals | Should -BeFalse
            $rule.DismissalTeams | Should -BeNullOrEmpty
            $rule.DismissalUsers | Should -BeNullOrEmpty
            $rule.requiresStatusChecks | Should -BeFalse
            $rule.requiresStrictStatusChecks | Should -BeTrue
            $rule.requiredStatusCheckContexts | Should -BeNullOrEmpty
            $rule.requiresCommitSignatures | Should -BeFalse
            $rule.requiresLinearHistory | Should -BeFalse
            $rule.isAdminEnforced | Should -BeFalse
            $rule.restrictsPushes | Should -BeFalse
            $rule.RestrictPushUsers | Should -BeNullOrEmpty
            $rule.RestrictPushTeams | Should -BeNullOrEmpty
            $rule.RestictPushApps | Should -BeNullOrEmpty
            $rule.allowsForcePushes | Should -BeFalse
            $rule.allowsDeletions | Should -BeFalse
        }
    }

    Context 'When getting base protection options' {
        BeforeAll {
            $branchPatternName = [Guid]::NewGuid().Guid + '/**/*'

            $newGitHubRepositoryBranchPatternProtectionParms = @{
                Uri = $repo.svn_url
                BranchPatternName = $branchPatternName
                RequireCommitSignatures = $true
                RequireLinearHistory = $true
                IsAdminEnforced = $true
                RestrictPushUser = $script:OwnerName
                RestrictPushTeam = $TeamName
                AllowForcePushes = $true
                AllowDeletions = $true
            }
            New-GitHubRepositoryBranchPatternProtectionRule @newGitHubRepositoryBranchPatternProtectionParms

            $rule = Get-GitHubRepositoryBranchPatternProtectionRule -Uri $repo.svn_url -BranchPatternName $branchPatternName
        }

        It 'Should have the expected type and addititional properties' {
            $rule.PSObject.TypeNames[0] | Should -Be 'GitHub.BranchPatternProtectionRule'
            $rule.pattern | Should -Be $branchPatternName
            $rule.RepositoryUrl | Should -Be $repo.RepositoryUrl
            $rule.requiresApprovingReviews | Should -BeFalse
            $rule.requiredApprovingReviewCount | Should -BeNullOrEmpty
            $rule.dismissesStaleReviews | Should -BeFalse
            $rule.requiresCodeOwnerReviews | Should -BeFalse
            $rule.restrictsReviewDismissals | Should -BeFalse
            $rule.DismissalTeams | Should -BeNullOrEmpty
            $rule.DismissalUsers | Should -BeNullOrEmpty
            $rule.requiresStatusChecks | Should -BeFalse
            $rule.requiresStrictStatusChecks | Should -BeTrue
            $rule.requiredStatusCheckContexts | Should -BeNullOrEmpty
            $rule.requiresCommitSignatures | Should -BeTrue
            $rule.requiresLinearHistory | Should -BeTrue
            $rule.isAdminEnforced | Should -BeTrue
            $rule.restrictsPushes | Should -BeTrue
            $rule.RestrictPushUsers.Count | Should -Be 1
            $rule.RestrictPushUsers | Should -Contain $script:OwnerName
            $rule.RestrictPushTeams.Count | Should -Be 1
            $rule.RestrictPushTeams | Should -Contain $teamName
            $rule.RestrictPushApps | Should -BeNullOrEmpty
            $rule.allowsForcePushes | Should -BeTrue
            $rule.allowsDeletions | Should -BeTrue
        }
    }

    Context 'When getting required pull request reviews' {
        BeforeAll {
            $branchPatternName = [Guid]::NewGuid().Guid + '/**/*'

            $newGitHubRepositoryBranchPatternProtectionParms = @{
                Uri = $repo.svn_url
                BranchPatternName = $branchPatternName
                RequiredApprovingReviewCount = 1
                DismissStaleReviews = $true
                RequireCodeOwnerReviews = $true
                DismissalUser = $script:OwnerName
                DismissalTeam = $teamName
            }
            New-GitHubRepositoryBranchPatternProtectionRule @newGitHubRepositoryBranchPatternProtectionParms

            $rule = Get-GitHubRepositoryBranchPatternProtectionRule -Uri $repo.svn_url -BranchPatternName $branchPatternName
        }

        It 'Should have the expected type and addititional properties' {
            $rule = Get-GitHubRepositoryBranchPatternProtectionRule -Uri $repo.svn_url -BranchPatternName $branchPatternName
            $rule.PSObject.TypeNames[0] | Should -Be 'GitHub.BranchPatternProtectionRule'
            $rule.pattern | Should -Be $branchPatternName
            $rule.RepositoryUrl | Should -Be $repo.RepositoryUrl
            $rule.requiresApprovingReviews | Should -BeTrue
            $rule.requiredApprovingReviewCount | Should -Be 1
            $rule.dismissesStaleReviews | Should -BeTrue
            $rule.requiresCodeOwnerReviews | Should -BeTrue
            $rule.restrictsReviewDismissals | Should -BeTrue
            $rule.DismissalTeams.Count | Should -Be 1
            $rule.DismissalTeams | Should -Contain $teamName
            $rule.DismissalUsers.Count | Should -Be 1
            $rule.DismissalUsers | Should -Contain $script:OwnerName
        }
    }

    Context 'When getting required status checks' {
        BeforeAll {
            $statusChecks = 'test'

            $newGitHubRepositoryBranchPatternProtectionParms = @{
                Uri = $repo.svn_url
                BranchPatternName = $branchPatternName
                RequireStrictStatusChecks = $true
                StatusCheck = $statusChecks
            }
            New-GitHubRepositoryBranchPatternProtectionRule @newGitHubRepositoryBranchPatternProtectionParms

            $rule = Get-GitHubRepositoryBranchPatternProtectionRule -Uri $repo.svn_url -BranchPatternName $branchPatternName
        }

        It 'Should have the expected type and addititional properties' {
            $rule.PSObject.TypeNames[0] | Should -Be 'GitHub.BranchPatternProtectionRule'
            $rule.pattern | Should -Be $branchPatternName
            $rule.RepositoryUrl | Should -Be $repo.RepositoryUrl
            $rule.requiresStatusChecks | Should -BeTrue
            $rule.requiresStrictStatusChecks | Should -BeTrue
            $rule.requiredStatusCheckContexts | Should -Contain $statusChecks
        }
    }

    Context 'When specifying the "Uri" parameter through the pipeline' {
        BeforeAll {
            $rule = $repo | Get-GitHubRepositoryBranchPatternProtectionRule -BranchPatternName $branchPatternName
        }

        It 'Should have the expected type and addititional properties' {
            $rule.PSObject.TypeNames[0] | Should -Be 'GitHub.BranchPatternProtectionRule'
            $rule.pattern | Should -Be $branchPatternName
            $rule.RepositoryUrl | Should -Be $repo.RepositoryUrl
        }
    }

    AfterAll -ScriptBlock {
        if (Get-Variable -Name repo -ErrorAction SilentlyContinue)
        {
            $repo | Remove-GitHubRepository -Force
        }

        if (Get-Variable -Name team -ErrorAction SilentlyContinue)
        {
            $team | Remove-GitHubTeam -Force
        }
    }
}

Describe 'GitHubBranches\New-GitHubRepositoryBranchPatternProtectionRule' {
    BeforeAll {
        $repoName = [Guid]::NewGuid().Guid

        $newGitHubRepositoryParms = @{
            OrganizationName = $script:organizationName
            RepositoryName = $repoName
        }
        $repo = New-GitHubRepository @newGitHubRepositoryParms

        $pushTeamName = [Guid]::NewGuid().Guid

        $newGithubTeamParms = @{
            OrganizationName = $script:OrganizationName
            TeamName = $pushTeamName
        }
        $pushTeam = New-GitHubTeam @newGithubTeamParms

        $setGitHubRepositoryTeamPermissionParms = @{
            Uri = $repo.svn_url
            TeamSlug = $pushTeam.slug
            Permission = 'Push'
        }
        Set-GitHubRepositoryTeamPermission @setGitHubRepositoryTeamPermissionParms

        $pullTeamName = [Guid]::NewGuid().Guid

        $newGithubTeamParms = @{
            OrganizationName = $script:OrganizationName
            TeamName = $pullTeamName
        }
        $pullTeam = New-GitHubTeam @newGithubTeamParms

        $setGitHubRepositoryTeamPermissionParms = @{
            Uri = $repo.svn_url
            TeamSlug = $pullTeam.slug

            Permission = 'Pull'
        }
        Set-GitHubRepositoryTeamPermission @setGitHubRepositoryTeamPermissionParms
    }

    Context 'When setting default protection options' {
        BeforeAll {
            $branchPatternName = [Guid]::NewGuid().Guid + '/**/*'

            $newGitHubRepositoryBranchPatternProtectionParms = @{
                Uri = $repo.svn_url
                BranchPatternName = $branchPatternName
            }
        }

        It 'Should not throw' {
            { New-GitHubRepositoryBranchPatternProtectionRule @newGitHubRepositoryBranchPatternProtectionParms } |
            Should -Not -Throw
        }

        It 'Should have set the correct properties' {
            $rule = Get-GitHubRepositoryBranchPatternProtectionRule -Uri $repo.svn_url -BranchPatternName $branchPatternName

            $rule.PSObject.TypeNames[0] | Should -Be 'GitHub.BranchPatternProtectionRule'
            $rule.pattern | Should -Be $branchPatternName
            $rule.RepositoryUrl | Should -Be $repo.RepositoryUrl
            $rule.requiresApprovingReviews | Should -BeFalse
            $rule.requiredApprovingReviewCount | Should -BeNullOrEmpty
            $rule.dismissesStaleReviews | Should -BeFalse
            $rule.requiresCodeOwnerReviews | Should -BeFalse
            $rule.restrictsReviewDismissals | Should -BeFalse
            $rule.DismissalTeams | Should -BeNullOrEmpty
            $rule.DismissalUsers | Should -BeNullOrEmpty
            $rule.requiresStatusChecks | Should -BeFalse
            $rule.requiresStrictStatusChecks | Should -BeTrue
            $rule.requiredStatusCheckContexts | Should -BeNullOrEmpty
            $rule.requiresCommitSignatures | Should -BeFalse
            $rule.requiresLinearHistory | Should -BeFalse
            $rule.isAdminEnforced | Should -BeFalse
            $rule.restrictsPushes | Should -BeFalse
            $rule.RestrictPushUsers | Should -BeNullOrEmpty
            $rule.RestrictPushTeams | Should -BeNullOrEmpty
            $rule.RestictPushApps | Should -BeNullOrEmpty
            $rule.allowsForcePushes | Should -BeFalse
            $rule.allowsDeletions | Should -BeFalse
        }
    }

    Context 'When setting base protection options' {
        BeforeAll {
            $branchPatternName = [Guid]::NewGuid().Guid + '/**/*'

            $newGitHubRepositoryBranchPatternProtectionParms = @{
                Uri = $repo.svn_url
                BranchPatternName = $branchPatternName
                RequireCommitSignatures = $true
                RequireLinearHistory = $true
                IsAdminEnforced = $true
                RestrictPushUser = $script:OwnerName
                RestrictPushTeam = $pushTeamName
                AllowForcePushes = $true
                AllowDeletions = $true
            }
        }

        It 'Should not throw' {
            { New-GitHubRepositoryBranchPatternProtectionRule @newGitHubRepositoryBranchPatternProtectionParms } |
            Should -Not -Throw
        }

        It 'Should have set the correct properties' {
            $rule = Get-GitHubRepositoryBranchPatternProtectionRule -Uri $repo.svn_url -BranchPatternName $branchPatternName

            $rule.PSObject.TypeNames[0] | Should -Be 'GitHub.BranchPatternProtectionRule'
            $rule.pattern | Should -Be $branchPatternName
            $rule.RepositoryUrl | Should -Be $repo.RepositoryUrl
            $rule.requiresApprovingReviews | Should -BeFalse
            $rule.requiredApprovingReviewCount | Should -BeNullOrEmpty
            $rule.dismissesStaleReviews | Should -BeFalse
            $rule.requiresCodeOwnerReviews | Should -BeFalse
            $rule.restrictsReviewDismissals | Should -BeFalse
            $rule.DismissalTeams | Should -BeNullOrEmpty
            $rule.DismissalUsers | Should -BeNullOrEmpty
            $rule.requiresStatusChecks | Should -BeFalse
            $rule.requiresStrictStatusChecks | Should -BeTrue
            $rule.requiredStatusCheckContexts | Should -BeNullOrEmpty
            $rule.requiresCommitSignatures | Should -BeTrue
            $rule.requiresLinearHistory | Should -BeTrue
            $rule.isAdminEnforced | Should -BeTrue
            $rule.restrictsPushes | Should -BeTrue
            $rule.RestrictPushUsers.Count | Should -Be 1
            $rule.RestrictPushUsers | Should -Contain $script:OwnerName
            $rule.RestrictPushTeams.Count | Should -Be 1
            $rule.RestrictPushTeams | Should -Contain $pushTeamName
            $rule.RestrictPushApps | Should -BeNullOrEmpty
            $rule.allowsForcePushes | Should -BeTrue
            $rule.allowsDeletions | Should -BeTrue
        }

        Context 'When the Restrict Push Team does not exist in the organization' {
            BeforeAll {
                $branchPatternName = [Guid]::NewGuid().Guid + '/**/*'
                $mockTeamName = 'MockTeam'

                $newGitHubRepositoryBranchPatternProtectionParms = @{
                    Uri = $repo.svn_url
                    BranchPatternName = $branchPatternName
                    RestrictPushTeam = $mockTeamName
                }
            }

            It 'Should throw the correct exception' {
                $errorMessage = "Team '$mockTeamName' not found in organization '$OrganizationName'"
                { New-GitHubRepositoryBranchPatternProtectionRule @newGitHubRepositoryBranchPatternProtectionParms } |
                Should -Throw $errorMessage
            }
        }

        Context 'When the Restrict Push Team does not have push Permissions to the Repository' {
            BeforeAll {
                $branchPatternName = [Guid]::NewGuid().Guid + '/**/*'

                $newGitHubRepositoryBranchPatternProtectionParms = @{
                    Uri = $repo.svn_url
                    BranchPatternName = $branchPatternName
                    RestrictPushTeam = $pullTeamName
                }
            }

            It 'Should throw the correct exception' {
                $errorMessage = "Team '$pullTeamName' does not have push or maintain permissions on repository '$OrganizationName/$repoName'"
                { New-GitHubRepositoryBranchPatternProtectionRule @newGitHubRepositoryBranchPatternProtectionParms } |
                Should -Throw $errorMessage
            }
        }
    }

    Context 'When setting required pull request reviews' {
        BeforeAll {
            $branchPatternName = [Guid]::NewGuid().Guid + '/**/*'

            $newGitHubRepositoryBranchPatternProtectionParms = @{
                Uri = $repo.svn_url
                BranchPatternName = $branchPatternName
                RequiredApprovingReviewCount = 1
                DismissStaleReviews = $true
                RequireCodeOwnerReviews = $true
                DismissalUser = $script:OwnerName
                DismissalTeam = $pushTeamName
            }
        }

        It 'Should not throw' {
            { New-GitHubRepositoryBranchPatternProtectionRule @newGitHubRepositoryBranchPatternProtectionParms } |
            Should -Not -Throw
        }

        It 'Should have set the correct properties' {
            $rule = Get-GitHubRepositoryBranchPatternProtectionRule -Uri $repo.svn_url -BranchPatternName $branchPatternName
            $rule.PSObject.TypeNames[0] | Should -Be 'GitHub.BranchPatternProtectionRule'
            $rule.pattern | Should -Be $branchPatternName
            $rule.RepositoryUrl | Should -Be $repo.RepositoryUrl
            $rule.requiresApprovingReviews | Should -BeTrue
            $rule.requiredApprovingReviewCount | Should -Be 1
            $rule.dismissesStaleReviews | Should -BeTrue
            $rule.requiresCodeOwnerReviews | Should -BeTrue
            $rule.restrictsReviewDismissals | Should -BeTrue
            $rule.DismissalTeams.Count | Should -Be 1
            $rule.DismissalTeams | Should -Contain $pushTeamName
            $rule.DismissalUsers.Count | Should -Be 1
            $rule.DismissalUsers | Should -Contain $script:OwnerName
        }

        Context 'When the Dismissal Team does not exist in the organization' {
            BeforeAll {
                $branchPatternName = [Guid]::NewGuid().Guid + '/**/*'
                $mockTeamName = 'MockTeam'

                $newGitHubRepositoryBranchPatternProtectionParms = @{
                    Uri = $repo.svn_url
                    BranchPatternName = $branchPatternName
                    DismissalTeam = $mockTeamName
                }
            }

            It 'Should throw the correct exception' {
                $errorMessage = "Team '$mockTeamName' not found in organization '$OrganizationName'"
                { New-GitHubRepositoryBranchPatternProtectionRule @newGitHubRepositoryBranchPatternProtectionParms } |
                Should -Throw $errorMessage
            }
        }

        Context 'When the Dismissal Team does not have write Permissions to the Repository' {
            BeforeAll {
                $branchPatternName = [Guid]::NewGuid().Guid + '/**/*'

                $newGitHubRepositoryBranchPatternProtectionParms = @{
                    Uri = $repo.svn_url
                    BranchPatternName = $branchPatternName
                    DismissalTeam = $pullTeamName
                }
            }

            It 'Should throw the correct exception' {
                $errorMessage = "Team '$pullTeamName' does not have push or maintain permissions on repository '$OrganizationName/$repoName'"
                { New-GitHubRepositoryBranchPatternProtectionRule @newGitHubRepositoryBranchPatternProtectionParms } |
                Should -Throw $errorMessage
            }
        }
    }

    Context 'When setting required status checks' {
        BeforeAll {
            $branchPatternName = [Guid]::NewGuid().Guid + '/**/*'
            $statusCheck = 'test'

            $newGitHubRepositoryBranchPatternProtectionParms = @{
                Uri = $repo.svn_url
                BranchPatternName = $branchPatternName
                RequireStrictStatusChecks = $true
                StatusCheck = $statusCheck
            }
        }

        It 'Should not throw' {
            { New-GitHubRepositoryBranchPatternProtectionRule @newGitHubRepositoryBranchPatternProtectionParms } |
            Should -Not -Throw
        }

        It 'Should have set the correct properties' {
            $rule = Get-GitHubRepositoryBranchPatternProtectionRule -Uri $repo.svn_url -BranchPatternName $branchPatternName

            $rule.PSObject.TypeNames[0] | Should -Be 'GitHub.BranchPatternProtectionRule'
            $rule.pattern | Should -Be $branchPatternName
            $rule.RepositoryUrl | Should -Be $repo.RepositoryUrl
            $rule.requiresStatusChecks | Should -BeTrue
            $rule.requiresStrictStatusChecks | Should -BeTrue
            $rule.requiredStatusCheckContexts | Should -Contain $statusCheck
        }
    }

    Context 'When the branch pattern rule already exists' {
        BeforeAll {
            $branchPatternName = [Guid]::NewGuid().Guid + '/**/*'

            $newGitHubRepositoryBranchPatternProtectionParms = @{
                Uri = $repo.svn_url
                BranchPatternName = $branchPatternName
            }
            $rule = New-GitHubRepositoryBranchPatternProtectionRule @newGitHubRepositoryBranchPatternProtectionParms
        }

        It 'Should throw the correct exception' {
            $errorMessage = "GraphQl Error: Name already protected: $branchPatternName"
            { New-GitHubRepositoryBranchPatternProtectionRule @newGitHubRepositoryBranchPatternProtectionParms } |
            Should -Throw $errorMessage
        }
    }

    Context 'When specifying the "Uri" parameter through the pipeline' {
        BeforeAll {
            $branchPatternName = [Guid]::NewGuid().Guid + '/**/*'
        }

        It 'Should not throw' {
            { $repo | New-GitHubRepositoryBranchPatternProtectionRule -BranchPatternName $branchPatternName } |
            Should -Not -Throw
        }

        It 'Should have set the correct properties' {
            $rule = Get-GitHubRepositoryBranchPatternProtectionRule -Uri $repo.svn_url -BranchPatternName $branchPatternName

            $rule.PSObject.TypeNames[0] | Should -Be 'GitHub.BranchPatternProtectionRule'
            $rule.pattern | Should -Be $branchPatternName
            $rule.RepositoryUrl | Should -Be $repo.RepositoryUrl
        }
    }

    AfterAll -ScriptBlock {
        if (Get-Variable -Name repo -ErrorAction SilentlyContinue)
        {
            $repo | Remove-GitHubRepository -Force
        }

        if (Get-Variable -Name pushTeam -ErrorAction SilentlyContinue)
        {
            $pushTeam | Remove-GitHubTeam -Force
        }

        if (Get-Variable -Name pullTeam -ErrorAction SilentlyContinue)
        {
            $pullTeam | Remove-GitHubTeam -Force
        }
    }
}

Describe 'GitHubBranches\Remove-GitHubRepositoryBranchPatternProtectionRule' {
    BeforeAll {
        $repoName = [Guid]::NewGuid().Guid

        $repo = New-GitHubRepository -RepositoryName $repoName
    }

    Context 'When removing GitHub repository branch pattern protection' {
        BeforeAll {
            $branchPatternName = [Guid]::NewGuid().Guid + '/**/*'

            New-GitHubRepositoryBranchPatternProtectionRule -Uri $repo.svn_url -BranchPatternName $branchPatternName
        }

        It 'Should not throw' {
            { Remove-GitHubRepositoryBranchPatternProtectionRule -Uri $repo.svn_url -BranchPatternName $branchPatternName -Force } |
            Should -Not -Throw
        }

        It 'Should have removed the protection rule' {
            { Get-GitHubRepositoryBranchPatternProtectionRule -Uri $repo.svn_url -BranchPatternName $branchPatternName } |
            Should -Throw
        }
    }

    Context 'When specifying the "Uri" parameter through the pipeline' {
        BeforeAll {
            $branchPatternName = [Guid]::NewGuid().Guid + '/**/*'

            $rule = New-GitHubRepositoryBranchPatternProtectionRule -Uri $repo.svn_url -BranchPatternName $branchPatternName
        }

        It 'Should not throw' {
            { $repo | Remove-GitHubRepositoryBranchPatternProtectionRule -BranchPatternName $branchPatternName -Force } |
            Should -Not -Throw
        }

        It 'Should have removed the protection rule' {
            { Get-GitHubRepositoryBranchPatternProtectionRule -Uri $repo.svn_url -BranchPatternName $branchPatternName } |
            Should -Throw
        }
    }

    AfterAll {
        if (Get-Variable -Name repo -ErrorAction SilentlyContinue)
        {
            $repo | Remove-GitHubRepository -Force
        }
    }
}

AfterAll {
    if (Test-Path -Path $script:originalConfigFile -PathType Leaf)
    {
        # Restore the user's configuration to its pre-test state
        Restore-GitHubConfiguration -Path $script:originalConfigFile
        $script:originalConfigFile = $null
    }
}
