# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

<#
.Synopsis
   Tests for GitHubIssues.ps1 module
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

Describe 'Getting issues for a repository' {
    BeforeAll {
        $repo = New-GitHubRepository -RepositoryName ([Guid]::NewGuid().Guid) -AutoInit
    }

    AfterAll {
        Remove-GitHubRepository -Uri $repo.RepositoryUrl -Confirm:$false
    }

    Context 'Getting all issues for a repository with parameters' {
        It 'Should return expected number of issues' {
            $currentIssues = @(Get-GitHubIssue -OwnerName $script:ownerName -RepositoryName $repo.name)

            $numIssues = 2
            1..$numIssues |
            ForEach-Object { New-GitHubIssue -OwnerName $script:ownerName -RepositoryName $repo.name -Title ([Guid]::NewGuid().Guid) } |
            Out-Null

            $issues = @(Get-GitHubIssue -OwnerName $script:ownerName -RepositoryName $repo.name)
            $issues.Count | Should -Be ($numIssues + $currentIssues.Count)
        }
    }

    Context 'Getting all issues for a repository with the repo on the pipeline' {
        It 'Should return expected number of issues' {
            $currentIssues = @($repo | Get-GitHubIssue)

            $numIssues = 2
            1..$numIssues |
            ForEach-Object { $repo | New-GitHubIssue -Title ([Guid]::NewGuid().Guid) } |
            Out-Null

            $issues = @($repo | Get-GitHubIssue)
            $issues.Count | Should -Be ($numIssues + $currentIssues.Count)
        }
    }

    Context 'Getting a specific issue with parameters' {
        BeforeAll {
            $issue = New-GitHubIssue -OwnerName $script:ownerName -RepositoryName $repo.name -Title ([Guid]::NewGuid().Guid)

            $result = Get-GitHubIssue -OwnerName $script:ownerName -RepositoryName $repo.name -Issue $issue.number
        }

        It 'Should be the expected Issue' {
            $result.id | Should -Be $issue.id
        }

        It 'Should have the expected property values' {
            $result.user.login | Should -Be $script:ownerName
            $result.labels | Should -BeNullOrEmpty
            $result.milestone | Should -BeNullOrEmpty
            $result.assignee | Should -BeNullOrEmpty
            $result.assignees | Should -BeNullOrEmpty
            $result.closed_by | Should -BeNullOrEmpty
            $result.repository | Should -BeNullOrEmpty
        }

        It 'Should have the expected type and additional properties' {
            $result.PSObject.TypeNames[0] | Should -Be 'GitHub.Issue'
            $result.RepositoryUrl | Should -Be $repo.RepositoryUrl
            $result.IssueId | Should -Be $result.id
            $result.IssueNumber | Should -Be $result.number
            $result.user.PSObject.TypeNames[0] | Should -Be 'GitHub.User'
        }
    }

    Context 'Getting a specific issue with the repo on the pipeline' {
        BeforeAll {
            $issue = $repo | New-GitHubIssue -Title ([Guid]::NewGuid().Guid)

            $result = $repo | Get-GitHubIssue -Issue $issue.number
        }

        It 'Should be the expected Issue' {
            $result.id | Should -Be $issue.id
        }

        It 'Should have the expected property values' {
            $result.user.login | Should -Be $script:ownerName
            $result.labels | Should -BeNullOrEmpty
            $result.milestone | Should -BeNullOrEmpty
            $result.assignee | Should -BeNullOrEmpty
            $result.assignees | Should -BeNullOrEmpty
            $result.closed_by | Should -BeNullOrEmpty
            $result.repository | Should -BeNullOrEmpty
        }

        It 'Should have the expected type and additional properties' {
            $result.PSObject.TypeNames[0] | Should -Be 'GitHub.Issue'
            $result.RepositoryUrl | Should -Be $repo.RepositoryUrl
            $result.IssueId | Should -Be $result.id
            $result.IssueNumber | Should -Be $result.number
            $result.user.PSObject.TypeNames[0] | Should -Be 'GitHub.User'
        }
    }

    Context 'Getting a specific issue with the issue on the pipeline' {
        BeforeAll {
            $issue = $repo | New-GitHubIssue -Title ([Guid]::NewGuid().Guid)

            $result = $issue | Get-GitHubIssue -Issue $issue.number
        }

        It 'Should be the expected Issue' {
            $result.id | Should -Be $issue.id
        }

        It 'Should have the expected property values' {
            $result.user.login | Should -Be $script:ownerName
            $result.labels | Should -BeNullOrEmpty
            $result.milestone | Should -BeNullOrEmpty
            $result.assignee | Should -BeNullOrEmpty
            $result.assignees | Should -BeNullOrEmpty
            $result.closed_by | Should -BeNullOrEmpty
            $result.repository | Should -BeNullOrEmpty
        }

        It 'Should have the expected type and additional properties' {
            $result.PSObject.TypeNames[0] | Should -Be 'GitHub.Issue'
            $result.RepositoryUrl | Should -Be $repo.RepositoryUrl
            $result.IssueId | Should -Be $result.id
            $result.IssueNumber | Should -Be $result.number
            $result.user.PSObject.TypeNames[0] | Should -Be 'GitHub.User'
        }
    }

    Context 'When issues are retrieved with a specific MediaTypes' {
        It 'Should return an issue with body_html' {
            $newIssue = New-GitHubIssue -OwnerName $script:ownerName -RepositoryName $repo.name -Title ([guid]::NewGuid()) -Body ([Guid]::NewGuid())

            $issues = @(Get-GitHubIssue -Uri $repo.svn_url -Issue $newIssue.number -MediaType 'Html')
            $issues[0].body_html | Should -Not -Be $null
        }
    }
}

Describe 'Date-specific Issue tests' {
    BeforeAll {
        $repo = New-GitHubRepository -RepositoryName ([Guid]::NewGuid().Guid) -AutoInit
    }

    AfterAll {
        Remove-GitHubRepository -Uri $repo.RepositoryUrl -Confirm:$false
    }

    Context 'Date specific scenarios' {
        BeforeAll {
            $existingIssues = @($repo | Get-GitHubIssue -State All)

            $newIssues = @()
            for ($i = 0; $i -lt 4; $i++)
            {
                $newIssues += New-GitHubIssue -OwnerName $script:ownerName -RepositoryName $repo.name -Title ([Guid]::NewGuid().Guid)
            }

            $newIssues[0] = Set-GitHubIssue -OwnerName $script:ownerName -RepositoryName $repo.name -Issue $newIssues[0].number -State Closed -PassThru
            $newIssues[-1] = Set-GitHubIssue -OwnerName $script:ownerName -RepositoryName $repo.name -Issue $newIssues[-1].number -State Closed -PassThru

            $existingOpenIssues = @($existingIssues | Where-Object { $_.state -eq 'open' })
            $newOpenIssues = @($newIssues | Where-Object { $_.state -eq 'open' })
            $issues = @($repo | Get-GitHubIssue)
        }
        It 'Should return only open issues' {
            $issues.Count | Should -Be ($newOpenIssues.Count + $existingOpenIssues.Count)
        }

        It 'Should return all issues' {
            $issues = @($repo | Get-GitHubIssue -State All)
            $issues.Count | Should -Be ($newIssues.Count + $existingIssues.Count)
        }


        It 'Smart object date conversion works for comparing dates' {
            $createdOnOrAfterDate = Get-Date -Date $newIssues[0].created_at
            $createdOnOrBeforeDate = Get-Date -Date $newIssues[2].created_at
            $issues = @(($repo | Get-GitHubIssue) |
                Where-Object { ($_.created_at -ge $createdOnOrAfterDate) -and ($_.created_at -le $createdOnOrBeforeDate) })
            $issues.Count | Should -Be 2
        }

        It 'Able to filter based on date and state' {
            $createdDate = Get-Date -Date $newIssues[1].created_at
            $issues = @(Get-GitHubIssue -Uri $repo.svn_url -State All |
                Where-Object { ($_.created_at -ge $createdDate) -and ($_.state -eq 'closed') })

            $issues.Count | Should -Be 1
        }
    }
}
Describe 'Creating issues' {
    BeforeAll {
        $repo = New-GitHubRepository -RepositoryName ([Guid]::NewGuid().Guid) -AutoInit
        $milestone = $repo | New-GitHubMilestone -Title ([Guid]::NewGuid().Guid)
    }

    AfterAll {
        Remove-GitHubRepository -Uri $repo.RepositoryUrl -Confirm:$false
    }

    Context 'Creating an Issue with parameters' {
        BeforeAll {
            $params = @{
                'OwnerName' = $script:ownerName
                'RepositoryName' = $repo.name
                'Title' = '-issue title-'
                'Body' = '-issue body-'
                'Assignee' = $script:ownerName
                'Milestone' = $milestone.number
                'Label' = 'bug'
                'MediaType' = 'Raw'
            }

            $issue = New-GitHubIssue @params
        }

        It 'Should have the expected property values' {
            $issue.title | Should -Be $params.Title
            $issue.body | Should -Be $params.Body
            $issue.assignee.login | Should -Be $params.Assignee
            $issue.assignees.Count | Should -Be 1
            $issue.assignees[0].login | Should -Be $params.Assignee
            $issue.milestone.number | Should -Be $params.Milestone
            $issue.labels.Count | Should -Be 1
            $issue.labels[0].name | Should -Contain $params.Label
        }

        It 'Should have the expected type and additional properties' {
            $issue.PSObject.TypeNames[0] | Should -Be 'GitHub.Issue'
            $issue.RepositoryUrl | Should -Be $repo.RepositoryUrl
            $issue.IssueId | Should -Be $issue.id
            $issue.IssueNumber | Should -Be $issue.number
            $issue.user.PSObject.TypeNames[0] | Should -Be 'GitHub.User'
            $issue.assignee.PSObject.TypeNames[0] | Should -Be 'GitHub.User'
            $issue.assignees[0].PSObject.TypeNames[0] | Should -Be 'GitHub.User'
            $issue.milestone.PSObject.TypeNames[0] | Should -Be 'GitHub.Milestone'
            $issue.labels[0].PSObject.TypeNames[0] | Should -Be 'GitHub.Label'
        }
    }

    Context 'Creating an Issue with the repo on the pipeline' {
        BeforeAll {
            $params = @{
                'Title' = '-issue title-'
                'Body' = '-issue body-'
                'Assignee' = $script:ownerName
                'Milestone' = $milestone.number
                'Label' = 'bug'
                'MediaType' = 'Raw'
            }

            $issue = $repo | New-GitHubIssue @params
        }

        It 'Should have the expected property values' {
            $issue.title | Should -Be $params.Title
            $issue.body | Should -Be $params.Body
            $issue.assignee.login | Should -Be $params.Assignee
            $issue.assignees.Count | Should -Be 1
            $issue.assignees[0].login | Should -Be $params.Assignee
            $issue.milestone.number | Should -Be $params.Milestone
            $issue.labels.Count | Should -Be 1
            $issue.labels[0].name | Should -Contain $params.Label
        }

        It 'Should have the expected type and additional properties' {
            $issue.PSObject.TypeNames[0] | Should -Be 'GitHub.Issue'
            $issue.RepositoryUrl | Should -Be $repo.RepositoryUrl
            $issue.IssueId | Should -Be $issue.id
            $issue.IssueNumber | Should -Be $issue.number
            $issue.user.PSObject.TypeNames[0] | Should -Be 'GitHub.User'
            $issue.assignee.PSObject.TypeNames[0] | Should -Be 'GitHub.User'
            $issue.assignees[0].PSObject.TypeNames[0] | Should -Be 'GitHub.User'
            $issue.milestone.PSObject.TypeNames[0] | Should -Be 'GitHub.Milestone'
            $issue.labels[0].PSObject.TypeNames[0] | Should -Be 'GitHub.Label'
        }
    }
}

Describe 'Updating issues' {
    BeforeAll {
        $repo = New-GitHubRepository -RepositoryName ([Guid]::NewGuid().Guid) -AutoInit
        $milestone = $repo | New-GitHubMilestone -Title ([Guid]::NewGuid().Guid)
        $title = 'issue title'
    }

    AfterAll {
        Remove-GitHubRepository -Uri $repo.RepositoryUrl -Confirm:$false
    }

    Context 'Updating an Issue with parameters' {
        BeforeAll {
            $issue = New-GitHubIssue -OwnerName $script:OwnerName -RepositoryName $repo.name -Title $title
        }

        It 'Should have the expected property values' {
            $issue.title | Should -Be $title
            $issue.body | Should -BeNullOrEmpty
            $issue.assignee.login | Should -BeNullOrEmpty
            $issue.assignees | Should -BeNullOrEmpty
            $issue.milestone | Should -BeNullOrEmpty
            $issue.labels | Should -BeNullOrEmpty
        }

        Context 'Update issue' {
            BeforeAll {
                $params = @{
                    'OwnerName' = $script:ownerName
                    'RepositoryName' = $repo.name
                    'Issue' = $issue.number
                    'Title' = '-new title-'
                    'Body' = '-new body-'
                    'Assignee' = $script:ownerName
                    'Milestone' = $milestone.number
                    'Label' = 'bug'
                    'MediaType' = 'Raw'
                }

                $updated = Set-GitHubIssue @params -PassThru
            }

            It 'Should have the expected property values' {
                $updated.id | Should -Be $issue.id
                $updated.number | Should -Be $issue.number
                $updated.title | Should -Be $params.Title
                $updated.body | Should -Be $params.Body
                $updated.assignee.login | Should -Be $params.Assignee
                $updated.assignees.Count | Should -Be 1
                $updated.assignees[0].login | Should -Be $params.Assignee
                $updated.milestone.number | Should -Be $params.Milestone
                $updated.labels.Count | Should -Be 1
                $updated.labels[0].name | Should -Contain $params.Label
            }

            It 'Should have the expected type and additional properties' {
                $updated.PSObject.TypeNames[0] | Should -Be 'GitHub.Issue'
                $updated.RepositoryUrl | Should -Be $repo.RepositoryUrl
                $updated.IssueId | Should -Be $updated.id
                $updated.IssueNumber | Should -Be $updated.number
                $updated.user.PSObject.TypeNames[0] | Should -Be 'GitHub.User'
                $updated.assignee.PSObject.TypeNames[0] | Should -Be 'GitHub.User'
                $updated.assignees[0].PSObject.TypeNames[0] | Should -Be 'GitHub.User'
                $updated.milestone.PSObject.TypeNames[0] | Should -Be 'GitHub.Milestone'
                $updated.labels[0].PSObject.TypeNames[0] | Should -Be 'GitHub.Label'
            }
        }
    }

    Context 'Updating an Issue with the repo on the pipeline' {
        BeforeAll {
            $issue = New-GitHubIssue -OwnerName $script:OwnerName -RepositoryName $repo.name -Title $title
        }

        It 'Should have the expected property values' {
            $issue.title | Should -Be $title
            $issue.body | Should -BeNullOrEmpty
            $issue.assignee.login | Should -BeNullOrEmpty
            $issue.assignees | Should -BeNullOrEmpty
            $issue.milestone | Should -BeNullOrEmpty
            $issue.labels | Should -BeNullOrEmpty
        }

        Context 'Update issue' {
            BeforeAll {
                $params = @{
                    'Issue' = $issue.number
                    'Title' = '-new title-'
                    'Body' = '-new body-'
                    'Assignee' = $script:ownerName
                    'Milestone' = $milestone.number
                    'Label' = 'bug'
                    'MediaType' = 'Raw'
                }

                $updated = $repo | Set-GitHubIssue @params -PassThru
            }

            It 'Should have the expected property values' {
                $updated.id | Should -Be $issue.id
                $updated.number | Should -Be $issue.number
                $updated.title | Should -Be $params.Title
                $updated.body | Should -Be $params.Body
                $updated.assignee.login | Should -Be $params.Assignee
                $updated.assignees.Count | Should -Be 1
                $updated.assignees[0].login | Should -Be $params.Assignee
                $updated.milestone.number | Should -Be $params.Milestone
                $updated.labels.Count | Should -Be 1
                $updated.labels[0].name | Should -Contain $params.Label
            }

            It 'Should have the expected type and additional properties' {
                $updated.PSObject.TypeNames[0] | Should -Be 'GitHub.Issue'
                $updated.RepositoryUrl | Should -Be $repo.RepositoryUrl
                $updated.IssueId | Should -Be $updated.id
                $updated.IssueNumber | Should -Be $updated.number
                $updated.user.PSObject.TypeNames[0] | Should -Be 'GitHub.User'
                $updated.assignee.PSObject.TypeNames[0] | Should -Be 'GitHub.User'
                $updated.assignees[0].PSObject.TypeNames[0] | Should -Be 'GitHub.User'
                $updated.milestone.PSObject.TypeNames[0] | Should -Be 'GitHub.Milestone'
                $updated.labels[0].PSObject.TypeNames[0] | Should -Be 'GitHub.Label'
            }
        }
    }

    Context 'Updating an Issue with the issue on the pipeline' {
        BeforeAll {
            $issue = New-GitHubIssue -OwnerName $script:OwnerName -RepositoryName $repo.name -Title $title
        }

        It 'Should have the expected property values' {
            $issue.title | Should -Be $title
            $issue.body | Should -BeNullOrEmpty
            $issue.assignee.login | Should -BeNullOrEmpty
            $issue.assignees | Should -BeNullOrEmpty
            $issue.milestone | Should -BeNullOrEmpty
            $issue.labels | Should -BeNullOrEmpty
        }

        Context 'Update issue' {
            BeforeAll {
                $params = @{
                    'Title' = '-new title-'
                    'Body' = '-new body-'
                    'Assignee' = $script:ownerName
                    'Milestone' = $milestone.number
                    'Label' = 'bug'
                    'MediaType' = 'Raw'
                }

                $updated = $issue | Set-GitHubIssue @params -PassThru
            }

            It 'Should have the expected property values' {
                $updated.id | Should -Be $issue.id
                $updated.number | Should -Be $issue.number
                $updated.title | Should -Be $params.Title
                $updated.body | Should -Be $params.Body
                $updated.assignee.login | Should -Be $params.Assignee
                $updated.assignees.Count | Should -Be 1
                $updated.assignees[0].login | Should -Be $params.Assignee
                $updated.milestone.number | Should -Be $params.Milestone
                $updated.labels.Count | Should -Be 1
                $updated.labels[0].name | Should -Contain $params.Label
            }

            It 'Should have the expected type and additional properties' {
                $updated.PSObject.TypeNames[0] | Should -Be 'GitHub.Issue'
                $updated.RepositoryUrl | Should -Be $repo.RepositoryUrl
                $updated.IssueId | Should -Be $updated.id
                $updated.IssueNumber | Should -Be $updated.number
                $updated.user.PSObject.TypeNames[0] | Should -Be 'GitHub.User'
                $updated.assignee.PSObject.TypeNames[0] | Should -Be 'GitHub.User'
                $updated.assignees[0].PSObject.TypeNames[0] | Should -Be 'GitHub.User'
                $updated.milestone.PSObject.TypeNames[0] | Should -Be 'GitHub.Milestone'
                $updated.labels[0].PSObject.TypeNames[0] | Should -Be 'GitHub.Label'
            }
        }
    }
}

Describe 'Locking and unlocking issues' {
    BeforeAll {
        $repo = New-GitHubRepository -RepositoryName ([Guid]::NewGuid().Guid) -AutoInit
    }

    AfterAll {
        Remove-GitHubRepository -Uri $repo.RepositoryUrl -Confirm:$false
    }

    Context 'Locking and unlocking an Issue with parameters' {
        BeforeAll {
            $issue = New-GitHubIssue -OwnerName $script:OwnerName -RepositoryName $repo.name -Title ([Guid]::NewGuid().Guid)
        }

        It 'Should be unlocked' {
            $issue.locked | Should -BeFalse
            $issue.active_lock_reason | Should -BeNullOrEmpty
        }

        It 'Should be locked' {
            $reason = 'Resolved'
            Lock-GitHubIssue -OwnerName $script:OwnerName -RepositoryName $repo.name -Issue $issue.number -Reason $reason
            $updated = Get-GitHubIssue -OwnerName $script:OwnerName -RepositoryName $repo.name -Issue $issue.number
            $updated.id | Should -Be $issue.id
            $updated.number | Should -Be $issue.number
            $updated.locked | Should -BeTrue
            $updated.active_lock_reason | Should -Be $reason
        }

        It 'Should be unlocked again' {
            Unlock-GitHubIssue -OwnerName $script:OwnerName -RepositoryName $repo.name -Issue $issue.number
            $updated = Get-GitHubIssue -OwnerName $script:OwnerName -RepositoryName $repo.name -Issue $issue.number
            $updated.id | Should -Be $issue.id
            $updated.number | Should -Be $issue.number
            $updated.locked | Should -BeFalse
            $updated.active_lock_reason | Should -BeNullOrEmpty
        }
    }

    Context 'Locking and unlocking an Issue with the repo on the pipeline' {
        BeforeAll {
            $issue = $repo | New-GitHubIssue -Title ([Guid]::NewGuid().Guid)
        }

        It 'Should be unlocked' {
            $issue.locked | Should -BeFalse
            $issue.active_lock_reason | Should -BeNullOrEmpty
        }

        It 'Should be locked' {
            $reason = 'Resolved'
            $repo | Lock-GitHubIssue -Issue $issue.number -Reason $reason
            $updated = $repo | Get-GitHubIssue -Issue $issue.number
            $updated.id | Should -Be $issue.id
            $updated.number | Should -Be $issue.number
            $updated.locked | Should -BeTrue
            $updated.active_lock_reason | Should -Be $reason
        }

        It 'Should be unlocked again' {
            $repo | Unlock-GitHubIssue -Issue $issue.number
            $updated = $repo | Get-GitHubIssue -Issue $issue.number
            $updated.id | Should -Be $issue.id
            $updated.number | Should -Be $issue.number
            $updated.locked | Should -BeFalse
            $updated.active_lock_reason | Should -BeNullOrEmpty
        }
    }

    Context 'Locking and unlocking an Issue with the issue on the pipeline' {
        BeforeAll {
            $issue = New-GitHubIssue -OwnerName $script:OwnerName -RepositoryName $repo.name -Title ([Guid]::NewGuid().Guid)
        }

        It 'Should be unlocked' {
            $issue.locked | Should -BeFalse
            $issue.active_lock_reason | Should -BeNullOrEmpty
        }

        It 'Should be locked' {
            $reason = 'Resolved'
            $issue | Lock-GitHubIssue -Reason $reason
            $updated = $issue | Get-GitHubIssue
            $updated.id | Should -Be $issue.id
            $updated.number | Should -Be $issue.number
            $updated.locked | Should -BeTrue
            $updated.active_lock_reason | Should -Be $reason
        }

        It 'Should be unlocked again' {
            $issue | Unlock-GitHubIssue
            $updated = $issue | Get-GitHubIssue
            $updated.id | Should -Be $issue.id
            $updated.number | Should -Be $issue.number
            $updated.locked | Should -BeFalse
            $updated.active_lock_reason | Should -BeNullOrEmpty
        }
    }
}

Describe 'Issue Timeline' {
    BeforeAll {
        $repo = New-GitHubRepository -RepositoryName ([Guid]::NewGuid().Guid) -AutoInit
    }

    AfterAll {
        Remove-GitHubRepository -Uri $repo.RepositoryUrl -Confirm:$false
    }

    Context 'Getting the Issue timeline with parameters' {
        BeforeAll {
            $issue = New-GitHubIssue -OwnerName $script:OwnerName -RepositoryName $repo.name -Title ([Guid]::NewGuid().Guid)
            $timeline = @(Get-GitHubIssueTimeline -OwnerName $script:OwnerName -RepositoryName $repo.name -Issue $issue.number)
        }

        It 'Should have no events so far' {
            $timeline.Count | Should -Be 0
        }

        Context 'Lock issue' {
            BeforeAll {
                Lock-GitHubIssue -OwnerName $script:OwnerName -RepositoryName $repo.name -Issue $issue.number

                $timeline = @(Get-GitHubIssueTimeline -OwnerName $script:OwnerName -RepositoryName $repo.name -Issue $issue.number)
            }

            It 'Should have an event now' {
                $timeline.Count | Should -Be 1
                $timeline[0].event | Should -Be 'locked'
            }

            It 'Should have the expected type and additional properties' {
                $timeline[0].PSObject.TypeNames[0] | Should -Be 'GitHub.Event'
                $timeline[0].RepositoryUrl | Should -Be $repo.RepositoryUrl
                $timeline[0].EventId | Should -Be $timeline[0].id
                $timeline[0].actor.PSObject.TypeNames[0] | Should -Be 'GitHub.User'
            }
        }
    }

    Context 'Getting the Issue timeline with the repo on the pipeline' {
        BeforeAll {
            $issue = $repo | New-GitHubIssue -Title ([Guid]::NewGuid().Guid)
            $timeline = @($repo | Get-GitHubIssueTimeline -Issue $issue.number)
        }

        It 'Should have no events so far' {
            $timeline.Count | Should -Be 0
        }

        Context 'Lock Issue' {
            BeforeAll {
                $repo | Lock-GitHubIssue -Issue $issue.number
                $timeline = @($repo | Get-GitHubIssueTimeline -Issue $issue.number)
            }

            It 'Should have an event now' {
                $timeline.Count | Should -Be 1
                $timeline[0].event | Should -Be 'locked'
            }

            It 'Should have the expected type and additional properties' {
                $timeline[0].PSObject.TypeNames[0] | Should -Be 'GitHub.Event'
                $timeline[0].RepositoryUrl | Should -Be $repo.RepositoryUrl
                $timeline[0].EventId | Should -Be $timeline[0].id
                $timeline[0].actor.PSObject.TypeNames[0] | Should -Be 'GitHub.User'
            }
        }
    }

    Context 'Getting the Issue timeline with the issue on the pipeline' {
        BeforeAll {
            $issue = $repo | New-GitHubIssue -Title ([Guid]::NewGuid().Guid)
            $timeline = @($issue | Get-GitHubIssueTimeline)
        }

        It 'Should have no events so far' {
            $timeline.Count | Should -Be 0
        }

        Context 'Lock Issue' {
            BeforeAll {
                $issue | Lock-GitHubIssue
                $timeline = @($issue | Get-GitHubIssueTimeline)
            }

            It 'Should have an event now' {
                $timeline.Count | Should -Be 1
                $timeline[0].event | Should -Be 'locked'
            }

            It 'Should have the expected type and additional properties' {
                $timeline[0].PSObject.TypeNames[0] | Should -Be 'GitHub.Event'
                $timeline[0].RepositoryUrl | Should -Be $repo.RepositoryUrl
                $timeline[0].EventId | Should -Be $timeline[0].id
                $timeline[0].actor.PSObject.TypeNames[0] | Should -Be 'GitHub.User'
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
