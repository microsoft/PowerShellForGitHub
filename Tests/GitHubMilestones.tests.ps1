# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

<#
.Synopsis
   Tests for GitHubMilestones.ps1 module
#>

[CmdletBinding()]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '',
    Justification = 'Suppress false positives in Pester code blocks')]
param()

BeforeAll {
    # This is common test code setup logic for all Pester test files
    $moduleRootPath = Split-Path -Path $PSScriptRoot -Parent
    . (Join-Path -Path $moduleRootPath -ChildPath 'Tests\Common.ps1')

    # Define Script-scoped, readonly, hidden variables.
    @{
        defaultMilestoneDueOn = (Get-Date).AddYears(1).ToUniversalTime()
    }.GetEnumerator() | ForEach-Object {
        Set-Variable -Force -Scope Script -Option ReadOnly -Visibility Private -Name $_.Key -Value $_.Value
    }
}
Describe 'Creating a milestone' {
    BeforeAll {
        $repo = New-GitHubRepository -RepositoryName ([Guid]::NewGuid().Guid) -AutoInit

        $commonParams = @{
            'State' = 'Closed'
            'DueOn' = $script:defaultMilestoneDueOn
            'Description' = 'Milestone description'
        }

        $title = 'Milestone title'
    }

    AfterAll {
        $repo | Remove-GitHubRepository -Force
    }

    Context 'Using the parameter' {
        BeforeAll {
            $milestone = New-GitHubMilestone -OwnerName $repo.owner.login -RepositoryName $repo.name -Title $title @commonParams
        }

        AfterAll {
            $milestone | Remove-GitHubMilestone -Force
        }

        It 'Should exist' {
            $returned = Get-GitHubMilestone -OwnerName $repo.owner.login -RepositoryName $repo.name -Milestone $milestone.MilestoneNumber

            $returned.id | Should -Be $milestone.id
        }

        It 'Should have the correct creation properties' {
            $milestone.title | Should -Be $title
            $milestone.state | Should -Be $commonParams['State']
            $milestone.description | Should -Be $commonParams['Description']

            # GitHub drops the time that is attached to 'due_on', so it's only relevant
            # to compare the dates against each other.
                (Get-Date -Date $milestone.due_on).Date | Should -Be $commonParams['DueOn'].Date
        }

        It 'Should have the expected type and additional properties' {
            $milestone.PSObject.TypeNames[0] | Should -Be 'GitHub.Milestone'
            $milestone.RepositoryUrl | Should -Be $repo.RepositoryUrl
            $milestone.MilestoneId | Should -Be $milestone.id
            $milestone.MilestoneNumber | Should -Be $milestone.number
            $milestone.creator.PSObject.TypeNames[0] | Should -Be 'GitHub.User'
        }
    }

    Context 'Using the pipeline for the repo' {
        BeforeAll {
            $milestone = $repo | New-GitHubMilestone -Title $title @commonParams
        }

        AfterAll {
            $milestone | Remove-GitHubMilestone -Force
        }

        It 'Should exist' {
            $returned = $milestone | Get-GitHubMilestone

            $returned.id | Should -Be $milestone.id
        }

        It 'Should have the correct creation properties' {
            $milestone.title | Should -Be $title
            $milestone.state | Should -Be $commonParams['State']
            $milestone.description | Should -Be $commonParams['Description']

            # GitHub drops the time that is attached to 'due_on', so it's only relevant
            # to compare the dates against each other.
                (Get-Date -Date $milestone.due_on).Date | Should -Be $commonParams['DueOn'].Date
        }

        It 'Should have the expected type and additional properties' {
            $milestone.PSObject.TypeNames[0] | Should -Be 'GitHub.Milestone'
            $milestone.RepositoryUrl | Should -Be $repo.RepositoryUrl
            $milestone.MilestoneId | Should -Be $milestone.id
            $milestone.MilestoneNumber | Should -Be $milestone.number
            $milestone.creator.PSObject.TypeNames[0] | Should -Be 'GitHub.User'
        }
    }

    Context 'Using the pipeline for the title' {
        BeforeAll {
            $milestone = $title | New-GitHubMilestone -OwnerName $repo.owner.login -RepositoryName $repo.name @commonParams
        }

        AfterAll {
            $milestone | Remove-GitHubMilestone -Force
        }

        It 'Should exist' {
            $returned = $repo | Get-GitHubMilestone -Milestone $milestone.MilestoneNumber

            $returned.id | Should -Be $milestone.id
        }

        It 'Should have the correct creation properties' {
            $milestone.title | Should -Be $title
            $milestone.state | Should -Be $commonParams['State']
            $milestone.description | Should -Be $commonParams['Description']

            # GitHub drops the time that is attached to 'due_on', so it's only relevant
            # to compare the dates against each other.
                (Get-Date -Date $milestone.due_on).Date | Should -Be $commonParams['DueOn'].Date
        }

        It 'Should have the expected type and additional properties' {
            $milestone.PSObject.TypeNames[0] | Should -Be 'GitHub.Milestone'
            $milestone.RepositoryUrl | Should -Be $repo.RepositoryUrl
            $milestone.MilestoneId | Should -Be $milestone.id
            $milestone.MilestoneNumber | Should -Be $milestone.number
            $milestone.creator.PSObject.TypeNames[0] | Should -Be 'GitHub.User'
        }
    }

    Context 'That is due at different times of the day' {
        BeforeAll {
            # We'll be testing to make sure that regardless of the time in the timestamp, we'll get the desired date.
            $title = 'Milestone title'
        }

        It "Should have the expected due_on date even if early morning" {
            $milestone = $repo | New-GitHubMilestone -Title 'Due early in the morning' -State "Closed" -DueOn $defaultMilestoneDueOn.date.AddHours(1)

            # GitHub drops the time that is attached to 'due_on', so it's only relevant
            # to compare the dates against each other.
                (Get-Date -Date $milestone.due_on).Date | Should -Be $defaultMilestoneDueOn.Date
        }

        It "Should have the expected due_on date even if late evening" {
            $milestone = $repo | New-GitHubMilestone -Title 'Due late in the evening' -State "Closed" -DueOn $defaultMilestoneDueOn.date.AddHours(23)

            # GitHub drops the time that is attached to 'due_on', so it's only relevant
            # to compare the dates against each other.
                (Get-Date -Date $milestone.due_on).Date | Should -Be $defaultMilestoneDueOn.Date
        }
    }
}

Describe 'Associating milestones with issues' {
    BeforeAll {
        $repo = New-GitHubRepository -RepositoryName ([Guid]::NewGuid().Guid) -AutoInit
        $milestone = $repo | New-GitHubMilestone -Title 'Milestone Title'
        $issue = $repo | New-GitHubIssue -Title 'Issue Title'
    }

    AfterAll {
        $repo | Remove-GitHubRepository -Force
    }

    Context 'Adding milestone to an issue' {
        It 'Should not have any open issues associated with it' {
            $issue.milestone | Should -BeNullOrEmpty
            $milestone.open_issues | Should -Be 0
        }

        It "Should be associated to the milestone now" {
            $issue = $issue | Set-GitHubIssue -Milestone $milestone.MilestoneNumber -PassThru
            $milestone = $milestone | Get-GitHubMilestone
            $issue.milestone.number | Should -Be $milestone.MilestoneNumber
            $milestone.open_issues | Should -Be 1
        }

        It 'Should no longer be associated to the milestone' {
            $issue = $issue | Set-GitHubIssue -Milestone 0 -PassThru
            $milestone = $milestone | Get-GitHubMilestone
            $issue.milestone | Should -BeNullOrEmpty
            $milestone.open_issues | Should -Be 0
        }

        It "Should be associated to the milestone again" {
            $issue = $issue | Set-GitHubIssue -Milestone $milestone.MilestoneNumber -PassThru
            $milestone = $milestone | Get-GitHubMilestone
            $issue.milestone.number | Should -Be $milestone.MilestoneNumber
            $milestone.open_issues | Should -Be 1
        }

        It 'Should have removed the association when the milestone was deleted' {
            $milestone | Remove-GitHubMilestone -Force
            $issue = Get-GitHubIssue -Uri $repo.svn_url -Issue $issue.number
            $issue.milestone | Should -BeNullOrEmpty
        }
    }
}

Describe 'Getting milestones' {
    BeforeAll {
        $repo = New-GitHubRepository -RepositoryName ([Guid]::NewGuid().Guid) -AutoInit
        $title = 'Milestone title'
    }

    AfterAll {
        $repo | Remove-GitHubRepository -Force
    }

    Context 'Getting a specific milestone' {
        BeforeAll {
            $closedMilestone = 'C' | New-GitHubMilestone -Uri $repo.RepositoryUrl -State 'Closed'
            $openMilestone = 'O' | New-GitHubMilestone -Uri $repo.RepositoryUrl -State 'Open'
        }

        AfterAll {
            $closedMilestone | Remove-GitHubMilestone -Force
            $openMilestone | Remove-GitHubMilestone -Force
        }

        Context 'By parameter' {
            BeforeAll {
                $milestone = $closedMilestone
                $returned = Get-GitHubMilestone -Uri $repo.RepositoryUrl -Milestone $milestone.MilestoneNumber
            }
            It 'Should get the right milestone as a parameter' {
                $returned.MilestoneId | Should -Be $milestone.MilestoneId
            }

            It 'Should have the expected type and additional properties' {
                $returned.PSObject.TypeNames[0] | Should -Be 'GitHub.Milestone'
                $returned.RepositoryUrl | Should -Be $repo.RepositoryUrl
                $returned.MilestoneId | Should -Be $returned.id
                $returned.MilestoneNumber | Should -Be $returned.number
                $returned.creator.PSObject.TypeNames[0] | Should -Be 'GitHub.User'
            }
        }

        Context 'By pipeline' {
            BeforeAll {
                $milestone = $openMilestone
                $returned = $openMilestone | Get-GitHubMilestone
            }

            It 'Should get the right milestone via the pipeline' {
                $returned.MilestoneId | Should -Be $milestone.MilestoneId
            }

            It 'Should have the expected type and additional properties' {
                $returned.PSObject.TypeNames[0] | Should -Be 'GitHub.Milestone'
                $returned.RepositoryUrl | Should -Be $repo.RepositoryUrl
                $returned.MilestoneId | Should -Be $returned.id
                $returned.MilestoneNumber | Should -Be $returned.number
                $returned.creator.PSObject.TypeNames[0] | Should -Be 'GitHub.User'
            }
        }
     }

    Context 'Getting multiple milestones' {
        BeforeAll {
            $today = (Get-Date).ToUniversalTime()
            $nextWeek = (Get-Date).AddDays(7).ToUniversalTime()
            $numClosedMilestones = 3
            $numOpenMilestones = 4
            $closed = 1..$numClosedMilestones | ForEach-Object { $repo | New-GitHubMilestone -Title "Closed $_" -State 'Closed' -DueOn $today }
            $open = 1..$numOpenMilestones | ForEach-Object { $repo | New-GitHubMilestone -Title "Open $_" -State 'Open' -DueOn $nextWeek }
        }

        AfterAll {
            $closed | Remove-GitHubMilestone -Force
            $open | Remove-GitHubMilestone -Force
        }

        It 'Should have the expected number of milestones' {
            $milestones = @(Get-GitHubMilestone -Uri $repo.RepositoryUrl -State 'All')
            $milestones.Count | Should -Be ($numClosedMilestones + $numOpenMilestones)
        }

        It 'Should have the expected number of open milestones' {
            $milestones = @($repo | Get-GitHubMilestone -State 'Open')
            $milestones.Count | Should -Be $numOpenMilestones
        }

        It 'Should have the expected number of closed milestones' {
            $milestones = @(Get-GitHubMilestone -Uri $repo.RepositoryUrl -State 'Closed')
            $milestones.Count | Should -Be $numClosedMilestones
        }

        It 'Should sort them the right way | DueOn, Descending' {
            $milestones = @(Get-GitHubMilestone -Uri $repo.RepositoryUrl -State 'All' -Sort 'DueOn' -Direction 'Descending')
            $milestones[0].state | Should -Be 'Open'
        }

        It 'Should sort them the right way | DueOn, Ascending' {
            $milestones = @(Get-GitHubMilestone -Uri $repo.RepositoryUrl -State 'All' -Sort 'DueOn' -Direction 'Ascending')
            $milestones[0].state | Should -Be 'Closed'
        }
    }
}

Describe 'Editing a milestone' {
    BeforeAll {
        $repo = New-GitHubRepository -RepositoryName ([Guid]::NewGuid().Guid) -AutoInit

        $createParams = @{
            'Title' = 'Created Title'
            'State' = 'Open'
            'Description' = 'Created Description'
            'DueOn' = (Get-Date).ToUniversalTime()
        }

        $editParams = @{
            'Title' = 'Edited Title'
            'State' = 'Closed'
            'Description' = 'Edited Description'
            'DueOn' = (Get-Date).AddDays(7).ToUniversalTime()
            'PassThru' = $true
        }
    }

    AfterAll {
        $repo | Remove-GitHubRepository -Force
    }

    Context 'Using the parameter' {
        BeforeAll {
            $milestone = New-GitHubMilestone -OwnerName $repo.owner.login -RepositoryName $repo.name @createParams
            $edited = Set-GitHubMilestone -Uri $milestone.RepositoryUrl -Milestone $milestone.MilestoneNumber @editParams
        }

        AfterAll {
            $milestone | Remove-GitHubMilestone -Force
        }

        It 'Should be editable via the parameter' {
            $edited.id | Should -Be $milestone.id
            $edited.title | Should -Be $editParams['Title']
            $edited.state | Should -Be $editParams['State']
            $edited.description | Should -Be $editParams['Description']

            # GitHub drops the time that is attached to 'due_on', so it's only relevant
            # to compare the dates against each other.
                (Get-Date -Date $edited.due_on).Date | Should -Be $editParams['DueOn'].Date
        }

        It 'Should have the expected type and additional properties' {
            $edited.PSObject.TypeNames[0] | Should -Be 'GitHub.Milestone'
            $edited.RepositoryUrl | Should -Be $repo.RepositoryUrl
            $edited.MilestoneId | Should -Be $milestone.id
            $edited.MilestoneNumber | Should -Be $milestone.number
            $edited.creator.PSObject.TypeNames[0] | Should -Be 'GitHub.User'
        }
    }

    Context 'Using the pipeline' {
        BeforeAll {
            $milestone = New-GitHubMilestone -OwnerName $repo.owner.login -RepositoryName $repo.name @createParams
            $edited = $milestone | Set-GitHubMilestone @editParams
        }

        AfterAll {
            $milestone | Remove-GitHubMilestone -Force
        }

        It 'Should be editable via the pipeline' {
            $edited.id | Should -Be $milestone.id
            $edited.title | Should -Be $editParams['Title']
            $edited.state | Should -Be $editParams['State']
            $edited.description | Should -Be $editParams['Description']

            # GitHub drops the time that is attached to 'due_on', so it's only relevant
            # to compare the dates against each other.
                (Get-Date -Date $edited.due_on).Date | Should -Be $editParams['DueOn'].Date
        }

        It 'Should have the expected type and additional properties' {
            $edited.PSObject.TypeNames[0] | Should -Be 'GitHub.Milestone'
            $edited.RepositoryUrl | Should -Be $repo.RepositoryUrl
            $edited.MilestoneId | Should -Be $milestone.id
            $edited.MilestoneNumber | Should -Be $milestone.number
            $edited.creator.PSObject.TypeNames[0] | Should -Be 'GitHub.User'
        }
    }
}

Describe 'Deleting a milestone' {
    BeforeAll {
        $repo = New-GitHubRepository -RepositoryName ([Guid]::NewGuid().Guid) -AutoInit
    }

    AfterAll {
        $repo | Remove-GitHubRepository -Force
    }

    Context 'Using the parameter' {
        It 'Should be deleted' {
            $milestone = $repo | New-GitHubMilestone -Title 'Milestone title' -State "Closed" -DueOn $defaultMilestoneDueOn
            Remove-GitHubMilestone -OwnerName $repo.owner.login -RepositoryName $repo.name -Milestone $milestone.MilestoneNumber -Force

            { Get-GitHubMilestone -OwnerName $repo.owner.login -RepositoryName $repo.name -Milestone $milestone.MilestoneNumber } | Should -Throw
        }
    }

    Context 'Using the pipeline' {
        It 'Should be deleted' {
            $milestone = $repo | New-GitHubMilestone -Title 'Milestone title' -State "Closed" -DueOn $defaultMilestoneDueOn
            $milestone | Remove-GitHubMilestone -Force

            { $milestone | Get-GitHubMilestone } | Should -Throw
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
