# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

<#
.Synopsis
   Tests for GitHubAssignees.ps1 module
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

Describe 'Getting an Assignee' {
    BeforeAll {
        $repo = New-GitHubRepository -RepositoryName ([Guid]::NewGuid().Guid) -AutoInit
    }

    AfterAll {
        $repo | Remove-GitHubRepository -Confirm:$false
    }

    Context 'For getting assignees in a repository via parameters' {
        BeforeAll {
            $assigneeList = @(Get-GitHubAssignee -OwnerName $script:ownerName -RepositoryName $repo.name)
        }

        It 'Should have returned the one assignee' {
            $assigneeList.Count | Should -Be 1
        }

        It 'Should have the expected type' {
            $assigneeList[0].PSObject.TypeNames[0] | Should -Be 'GitHub.User'
        }
    }

    Context 'For getting assignees in a repository with the repo on the pipeline' {
        BeforeAll {
            $assigneeList = @($repo | Get-GitHubAssignee)
        }

        It 'Should have returned the one assignee' {
            $assigneeList.Count | Should -Be 1
        }

        It 'Should have the expected type' {
            $assigneeList[0].PSObject.TypeNames[0] | Should -Be 'GitHub.User'
        }
    }
}

Describe 'Testing for a valid Assignee' {
    BeforeAll {
        $repo = New-GitHubRepository -RepositoryName ([Guid]::NewGuid().Guid) -AutoInit
        $octocat = Get-GitHubUser -UserName 'octocat'
        $owner = Get-GitHubUser -UserName $script:ownerName
    }

    AfterAll {
        $repo | Remove-GitHubRepository -Confirm:$false
    }

    Context 'For testing valid owner with parameters' {
        BeforeAll {
            $hasPermission = Test-GitHubAssignee -OwnerName $script:ownerName -RepositoryName $repo.name -Assignee $script:ownerName
        }

        It 'Should consider the owner of the repo to be a valid assignee' {
            $hasPermission | Should -BeTrue
        }
    }

    Context 'For testing valid owner with the repo on the pipeline' {
        BeforeAll {
            $hasPermission = $repo | Test-GitHubAssignee -Assignee $script:ownerName
        }

        It 'Should consider the owner of the repo to be a valid assignee' {
            $hasPermission | Should -BeTrue
        }
    }

    Context 'For testing valid owner with a user object on the pipeline' {
        BeforeAll {
            $hasPermission = $owner | Test-GitHubAssignee -OwnerName $script:ownerName -RepositoryName $repo.name
        }

        It 'Should consider the owner of the repo to be a valid assignee' {
            $hasPermission | Should -BeTrue
        }
    }

    Context 'For testing invalid owner with a user object on the pipeline' {
        BeforeAll {
            $hasPermission = $octocat | Test-GitHubAssignee -OwnerName $script:ownerName -RepositoryName $repo.name
        }

        It 'Should consider the owner of the repo to be a valid assignee' {
            $hasPermission | Should -BeFalse
        }
    }
}

Describe 'Adding and Removing Assignees from an Issue' {
    BeforeAll {
        $repo = New-GitHubRepository -RepositoryName ([Guid]::NewGuid().Guid) -AutoInit
        $owner = Get-GitHubUser -UserName $script:ownerName
    }

    AfterAll {
        $repo | Remove-GitHubRepository -Confirm:$false
    }

    Context 'Adding and removing an assignee via parameters' {
        BeforeAll {
            $issue = $repo | New-GitHubIssue -Title "Test issue"
        }

        It 'Should have no assignees when created' {
            $issue.assignee.login | Should -BeNullOrEmpty
            $issue.assignees | Should -BeNullOrEmpty
        }

        Context 'Adding an assignee via parameters' {

            BeforeAll {
                $updatedIssue = Add-GitHubAssignee -OwnerName $script:ownerName -RepositoryName $repo.name -Issue $issue.number -Assignee $owner.login -PassThru
            }

            It 'Should have returned the same issue' {
                $updatedIssue.number | Should -Be $issue.number
            }

            It 'Should have added the requested Assignee to the issue' {
                $updatedIssue.assignees.Count | Should -Be 1
                $updatedIssue.assignee.login | Should -Be $owner.login
                $updatedIssue.assignees[0].login | Should -Be $owner.login
            }

            It 'Should be of the expected type' {
                $updatedIssue.PSObject.TypeNames[0] | Should -Be 'GitHub.Issue'
            }
        }

        Context 'Remove an assignee via parameters' {

            BeforeAll {
                $updatedIssue = Remove-GitHubAssignee -OwnerName $script:ownerName -RepositoryName $repo.name -Issue $issue.number -Assignee $owner.login -Confirm:$false
            }

            It 'Should have returned the same issue' {
                $updatedIssue.number | Should -Be $issue.number
            }

            It 'Should have added the requested Assignee to the issue' {
                $updatedIssue.assignee.login | Should -BeNullOrEmpty
                $updatedIssue.assignees | Should -BeNullOrEmpty
            }

            It 'Should be of the expected type' {
                $updatedIssue.PSObject.TypeNames[0] | Should -Be 'GitHub.Issue'
            }
        }
    }

    Context 'Adding an assignee with the repo on the pipeline' {
        BeforeAll {
            $issue = $repo | New-GitHubIssue -Title "Test issue"
        }

        It 'Should have no assignees when created' {
            $issue.assignee.login | Should -BeNullOrEmpty
            $issue.assignees | Should -BeNullOrEmpty
        }

        Context "Adding an assignee with the repo on the pipeline" {
            BeforeAll {
                $updatedIssue = $repo | Add-GitHubAssignee -Issue $issue.number -Assignee $owner.login -PassThru
            }

            It 'Should have returned the same issue' {
                $updatedIssue.number | Should -Be $issue.number
            }

            It 'Should have added the requested Assignee to the issue' {
                $updatedIssue.assignees.Count | Should -Be 1
                $updatedIssue.assignee.login | Should -Be $owner.login
                $updatedIssue.assignees[0].login | Should -Be $owner.login
            }

            It 'Should be of the expected type' {
                $updatedIssue.PSObject.TypeNames[0] | Should -Be 'GitHub.Issue'
            }
        }

        Context "Removing an assignee with the repo on the pipeline" {
            BeforeAll {
                $updatedIssue = $repo | Remove-GitHubAssignee -Issue $issue.number -Assignee $owner.login -Force -Confirm:$false
            }

            It 'Should have returned the same issue' {
                $updatedIssue.number | Should -Be $issue.number
            }

            It 'Should have added the requested Assignee to the issue' {
                $updatedIssue.assignee.login | Should -BeNullOrEmpty
                $updatedIssue.assignees | Should -BeNullOrEmpty
            }

            It 'Should be of the expected type' {
                $updatedIssue.PSObject.TypeNames[0] | Should -Be 'GitHub.Issue'
            }
        }
    }

    Context 'Adding an assignee with the issue on the pipeline' {
        BeforeAll {
            $issue = $repo | New-GitHubIssue -Title "Test issue"
        }

        It 'Should have no assignees when created' {
            $issue.assignee.login | Should -BeNullOrEmpty
            $issue.assignees | Should -BeNullOrEmpty
        }

        Context "Add assignee with the issue on the pipeline" {
            BeforeAll {
                $updatedIssue = $issue | Add-GitHubAssignee -Assignee $owner.login -PassThru
            }

            It 'Should have returned the same issue' {
                $updatedIssue.number | Should -Be $issue.number
            }

            It 'Should have added the requested Assignee to the issue' {
                $updatedIssue.assignees.Count | Should -Be 1
                $updatedIssue.assignee.login | Should -Be $owner.login
                $updatedIssue.assignees[0].login | Should -Be $owner.login
            }

            It 'Should be of the expected type' {
                $updatedIssue.PSObject.TypeNames[0] | Should -Be 'GitHub.Issue'
            }
        }

        Context "Remove assignee with the issue on the pipeline" {
            BeforeAll {
                $updatedIssue = $issue | Remove-GitHubAssignee -Assignee $owner.login -Force
            }

            It 'Should have returned the same issue' {
                $updatedIssue.number | Should -Be $issue.number
            }

            It 'Should have added the requested Assignee to the issue' {
                $updatedIssue.assignee.login | Should -BeNullOrEmpty
                $updatedIssue.assignees | Should -BeNullOrEmpty
            }

            It 'Should be of the expected type' {
                $updatedIssue.PSObject.TypeNames[0] | Should -Be 'GitHub.Issue'
            }
        }
    }

    Context 'Adding an assignee with the assignee user object on the pipeline' {
        BeforeAll {
            $issue = $repo | New-GitHubIssue -Title "Test issue"
        }

        It 'Should have no assignees when created' {
            $issue.assignee.login | Should -BeNullOrEmpty
            $issue.assignees | Should -BeNullOrEmpty
        }

        Context 'Adding an assignee with the assignee user object on the pipeline' {
            BeforeAll {
                $updatedIssue = $owner | Add-GitHubAssignee -OwnerName $script:ownerName -RepositoryName $repo.name -Issue $issue.number -PassThru
            }

            It 'Should have returned the same issue' {
                $updatedIssue.number | Should -Be $issue.number
            }

            It 'Should have added the requested Assignee to the issue' {
                $updatedIssue.assignees.Count | Should -Be 1
                $updatedIssue.assignee.login | Should -Be $owner.login
                $updatedIssue.assignees[0].login | Should -Be $owner.login
            }

            It 'Should be of the expected type' {
                $updatedIssue.PSObject.TypeNames[0] | Should -Be 'GitHub.Issue'
            }
        }

        Context 'Removing an assignee with the assignee user object on the pipeline' {
            BeforeAll {
                $updatedIssue = $owner | Remove-GitHubAssignee -OwnerName $script:ownerName -RepositoryName $repo.name -Issue $issue.number -Force
            }

            It 'Should have returned the same issue' {
                $updatedIssue.number | Should -Be $issue.number
            }

            It 'Should have added the requested Assignee to the issue' {
                $updatedIssue.assignee.login | Should -BeNullOrEmpty
                $updatedIssue.assignees | Should -BeNullOrEmpty
            }

            It 'Should be of the expected type' {
                $updatedIssue.PSObject.TypeNames[0] | Should -Be 'GitHub.Issue'
            }
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
