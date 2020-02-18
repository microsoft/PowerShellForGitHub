# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

<#
.Synopsis
   Tests for GitHubMilestones.ps1 module
#>

# This is common test code setup logic for all Pester test files
$moduleRootPath = Split-Path -Path $PSScriptRoot -Parent
. (Join-Path -Path $moduleRootPath -ChildPath 'Tests\Common.ps1')

try
{
    # Define Script-scoped, readonly, hidden variables.
    @{
        defaultIssueTitle = "This is a test issue."
        defaultMilestoneTitle1 = "This is a test milestone title #1."
        defaultMilestoneTitle2 = "This is a test milestone title #2."
        defaultMilestoneTitle3 = "This is a test milestone title #3."
        defaultMilestoneTitle4 = "This is a test milestone title #4."
        defaultEditedMilestoneTitle = "This is an edited milestone title."
        defaultMilestoneDescription = "This is a test milestone description."
        defaultEditedMilestoneDescription = "This is an edited milestone description."
        defaultMilestoneDueOn = (Get-Date).AddYears(1).ToUniversalTime()
    }.GetEnumerator() | ForEach-Object {
        Set-Variable -Force -Scope Script -Option ReadOnly -Visibility Private -Name $_.Key -Value $_.Value
    }

    Describe 'Creating, modifying and deleting milestones' {
        $repo = New-GitHubRepository -RepositoryName ([Guid]::NewGuid().Guid) -AutoInit
        $issue = New-GitHubIssue -Uri $repo.svn_url -Title $defaultIssueTitle

        Context 'For creating a new milestone' {
            $newMilestone = New-GitHubMilestone -Uri $repo.svn_url -Title $defaultMilestoneTitle1 -State "Closed" -DueOn $defaultMilestoneDueOn
            $existingMilestone = Get-GitHubMilestone -Uri $repo.svn_url -Milestone $newMilestone.number

            # We'll be testing to make sure that regardless of the time in the timestamp, we'll get the desired date.
            $newMilestoneDueOnEarlyMorning = New-GitHubMilestone -Uri $repo.svn_url -Title $defaultMilestoneTitle2 -State "Closed" -DueOn $defaultMilestoneDueOn.date.AddHours(1)
            $newMilestoneDueOnLateEvening = New-GitHubMilestone -Uri $repo.svn_url -Title $defaultMilestoneTitle3 -State "Closed" -DueOn $defaultMilestoneDueOn.date.AddHours(23)

            It "Should have the expected title text" {
                $existingMilestone.title | Should be $defaultMilestoneTitle1
            }

            It "Should have the expected state" {
                $existingMilestone.state | Should be "closed"
            }

            It "Should have the expected due_on date" {
                # GitHub drops the time that is attached to 'due_on', so it's only relevant
                # to compare the dates against each other.
                (Get-Date -Date $existingMilestone.due_on).Date | Should be $defaultMilestoneDueOn.Date
            }

            It "Should have the expected due_on date even if early morning" {
                # GitHub drops the time that is attached to 'due_on', so it's only relevant
                # to compare the dates against each other.
                (Get-Date -Date $newMilestoneDueOnEarlyMorning.due_on).Date | Should be $defaultMilestoneDueOn.Date
            }

            It "Should have the expected due_on date even if late evening" {
                # GitHub drops the time that is attached to 'due_on', so it's only relevant
                # to compare the dates against each other.
                (Get-Date -Date $newMilestoneDueOnLateEvening.due_on).Date | Should be $defaultMilestoneDueOn.Date
            }

            It "Should allow the addition of an existing issue" {
                Update-GitHubIssue -Uri $repo.svn_url -Issue $issue.number -Milestone $existingMilestone.number
            }
        }

        Context 'For getting milestones from a repo' {
            $existingMilestones = @(Get-GitHubMilestone -Uri $repo.svn_url -State Closed)
            $issue = Get-GitHubIssue -Uri $repo.svn_url -Issue $issue.number

            It 'Should have the expected number of milestones' {
                $existingMilestones.Count | Should be 3
            }

            It 'Should have the expected title text on the first milestone' {
                $existingMilestones[0].title | Should be $defaultMilestoneTitle1
            }

            It 'Should have the expected issue in the first milestone' {
                $existingMilestones[0].open_issues | should be 1
                $issue.milestone.number | Should be 1
            }
        }

        Context 'For editing a milestone' {
            $newMilestone = New-GitHubMilestone -Uri $repo.svn_url -Title $defaultMilestoneTitle4 -Description $defaultMilestoneDescription
            $editedMilestone = Set-GitHubMilestone -Uri $repo.svn_url -Milestone $newMilestone.number -Title $defaultEditedMilestoneTitle -Description $defaultEditedMilestoneDescription

            It 'Should have a title/description that is not equal to the original title/description' {
                $editedMilestone.title | Should not be $newMilestone.title
                $editedMilestone.description | Should not be $newMilestone.description
            }

            It 'Should have the edited content' {
                $editedMilestone.title | Should be $defaultEditedMilestoneTitle
                $editedMilestone.description | Should be $defaultEditedMilestoneDescription
            }
        }

        Context 'For getting milestones from a repository and deleting them' {
            $existingMilestones = @(Get-GitHubMilestone -Uri $repo.svn_url -State All -Sort Completeness -Direction Descending)

            It 'Should have the expected number of milestones' {
                $existingMilestones.Count | Should be 4
            }

            foreach($milestone in $existingMilestones) {
                Remove-GitHubMilestone -Uri $repo.svn_url -Milestone $milestone.number
            }

            $existingMilestones = @(Get-GitHubMilestone -Uri $repo.svn_url)
            $issue = Get-GitHubIssue -Uri $repo.svn_url -Issue $issue.number

            It 'Should have no milestones' {
                $existingMilestones.Count | Should be 0
                $issue.milestone | Should be $null
            }
        }

        Remove-GitHubRepository -Uri $repo.svn_url
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
