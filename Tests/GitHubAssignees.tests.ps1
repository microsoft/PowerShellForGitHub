# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

<#
.Synopsis
   Tests for GitHubAssignees.ps1 module
#>

# This is common test code setup logic for all Pester test files
$moduleRootPath = Split-Path -Path $PSScriptRoot -Parent
. (Join-Path -Path $moduleRootPath -ChildPath 'Tests\Common.ps1')

try
{
    Describe 'Getting a valid assignee' {
        BeforeAll {
            $repo = New-GitHubRepository -RepositoryName ([Guid]::NewGuid().Guid) -AutoInit
            $issue = New-GitHubIssue -Uri $repo.RepositoryUrl -Title "Test issue"

            # Avoid PSScriptAnalyzer PSUseDeclaredVarsMoreThanAssignments
            $issue = $issue
        }

        AfterAll {
            Remove-GitHubRepository -Uri $repo.RepositoryUrl -Confirm:$false
        }

        Context 'For getting a valid assignee' {
            $assigneeList = @(Get-GitHubAssignee -Uri $repo.RepositoryUrl)

            It 'Should have returned the one assignee' {
                $assigneeList.Count | Should be 1
            }

            $assigneeUserName = $assigneeList[0].login

            It 'Should have returned an assignee with a login'{
                $assigneeUserName | Should not be $null
            }

            $hasPermission = Test-GitHubAssignee -Uri $repo.RepositoryUrl -Assignee $assigneeUserName

            It 'Should have returned an assignee with permission to be assigned to an issue'{
                $hasPermission | Should be $true
            }

        }
    }

    Describe 'Adding and removing an assignee to an issue'{
        BeforeAll {
            $repo = New-GitHubRepository -RepositoryName ([Guid]::NewGuid().Guid) -AutoInit
            $issue = New-GitHubIssue -Uri $repo.RepositoryUrl -Title "Test issue"

            # Avoid PSScriptAnalyzer PSUseDeclaredVarsMoreThanAssignments
            $issue = $issue
        }

        AfterAll {
            Remove-GitHubRepository -Uri $repo.RepositoryUrl -Confirm:$false
        }

        Context 'For adding an assignee to an issue'{
            $assigneeList = @(Get-GitHubAssignee -Uri $repo.RepositoryUrl)
            $assignees = $assigneeList[0].UserName
            $null = New-GithubAssignee -Uri $repo.RepositoryUrl -Issue $issue.number -Assignee $assignees
            $issue = Get-GitHubIssue -Uri $repo.RepositoryUrl -Issue $issue.number

            It 'Should have assigned the user to the issue' {
                $issue.assignee.login | Should be $assigneeUserName
            }

            Remove-GithubAssignee -Uri $repo.RepositoryUrl -Issue $issue.number -Assignee $assignees -Confirm:$false
            $issue = Get-GitHubIssue -Uri $repo.RepositoryUrl -Issue $issue.number

            It 'Should have removed the user from issue' {
                $issue.assignees.Count | Should be 0
            }
        }
    }

    Describe 'Adding and removing an assignee to an issue via the pipeline'{
        BeforeAll {
            $repo = New-GitHubRepository -RepositoryName ([Guid]::NewGuid().Guid) -AutoInit

            # Avoid PSScriptAnalyzer PSUseDeclaredVarsMoreThanAssignments
            $repo = $repo
        }

        BeforeEach {
            $issue = New-GitHubIssue -Uri $repo.RepositoryUrl -Title "Test issue"

            # Avoid PSScriptAnalyzer PSUseDeclaredVarsMoreThanAssignments
            $issue = $issue
        }

        AfterAll {
            Remove-GitHubRepository -Uri $repo.RepositoryUrl -Confirm:$false
        }

        Context 'For adding an assignee to an issue - pipe in the repo'{
            $assigneeList = @($repo | Get-GitHubAssignee)
            $assignees = $assigneeList[0].UserName
            $null = $repo | New-GithubAssignee -Issue $issue.IssueNumber -Assignee $assignees
            $issue = Get-GitHubIssue -Uri $repo.RepositoryUrl -Issue $issue.number

            It 'Should have assigned the user to the issue' {
                $issue.assignee.UserName | Should be $assigneeUserName
            }

            $repo | Remove-GithubAssignee -Issue $issue.IssueNumber -Assignee $assignees -Confirm:$false
            $issue = $repo | Get-GitHubIssue -Issue $issue.IssueNumber

            It 'Should have removed the user from issue' {
                $issue.assignees.Count | Should be 0
            }
        }

        Context 'For adding an assignee to an issue - pipe in the issue'{
            $assigneeList = @(Get-GitHubAssignee -Uri $repo.RepositoryUrl)
            $assignees = $assigneeList[0].UserName
            $null = $issue | New-GithubAssignee -Assignee $assignees
            $issue = $issue | Get-GitHubIssue

            It 'Should have assigned the user to the issue' {
                $issue.assignee.UserName | Should be $assigneeUserName
            }

            $issue | Remove-GithubAssignee -Assignee $assignees -Confirm:$false
            $issue = $issue | Get-GitHubIssue

            It 'Should have removed the user from issue' {
                $issue.assignees.Count | Should be 0
            }
        }

        Context 'For adding an assignee to an issue - pipe in the assignee'{
            $assigneeList = @(Get-GitHubAssignee -Uri $repo.RepositoryUrl)
            $assignees = $assigneeList[0].UserName
            $null = $assignees | New-GithubAssignee -Uri $repo.RepositoryUrl -Issue $issue.number
            $issue = Get-GitHubIssue -Uri $repo.RepositoryUrl -Issue $issue.IssueNumber

            It 'Should have assigned the user to the issue' {
                $issue.assignee.UserName | Should be $assigneeUserName
            }

            $assignees | Remove-GithubAssignee -Uri $repo.RepositoryUrl -Issue $issue.number -Confirm:$false
            $issue = Get-GitHubIssue -Uri $repo.RepositoryUrl -Issue $issue.IssueNumber

            It 'Should have removed the user from issue' {
                $issue.assignees.Count | Should be 0
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
