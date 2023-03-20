# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

<#
.Synopsis
   Tests for GitHubEvents.ps1 module
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

Describe 'Getting events from repository' {
    BeforeAll {
        $repositoryName = [Guid]::NewGuid()
        $repo = New-GitHubRepository -RepositoryName $repositoryName
    }

    AfterAll {
        $null = $repo | Remove-GitHubRepository -Force
    }

    Context 'For getting events from a new repository (via parameter)' {

        It 'Should have no events (via parameter)' {
            $events = @(Get-GitHubEvent -OwnerName $ownerName -RepositoryName $repositoryName)
            $events.Count | Should -Be 0
        }
    }

    Context 'For getting events from a new repository (via pipeline)' {

        It 'Should have no events (via parameter)' {
            $events = @($repo | Get-GitHubEvent)
            $events.Count | Should -Be 0
        }
    }

    Context 'For getting Issue events from a repository' {

        BeforeAll {
            $issue = $repo | New-GitHubIssue -Title 'New Issue'
            $issue = $issue | Set-GitHubIssue -State Closed -PassThru
            $events = @($repo | Get-GitHubEvent)
        }

        It 'Should have an event from closing an issue' {
            $events.Count | Should -Be 1
        }

        It 'Should have the expected type and additional properties' {
            $events[0].PSObject.TypeNames[0] | Should -Be 'GitHub.Event'
            $events[0].issue.PSObject.TypeNames[0] | Should -Be 'GitHub.Issue'
            $events[0].IssueId | Should -Be $events[0].issue.id
            $events[0].IssueNumber | Should -Be $events[0].issue.number
            $events[0].actor.PSObject.TypeNames[0] | Should -Be 'GitHub.User'
        }
    }
}

Describe 'Getting events from an issue' {
    BeforeAll {
        $repositoryName = [Guid]::NewGuid()
        $repo = New-GitHubRepository -RepositoryName $repositoryName
        $issue = New-GitHubIssue -OwnerName $ownerName -RepositoryName $repositoryName -Title "New Issue"
    }

    AfterAll {
        $repo | Remove-GitHubRepository -Confirm:$false
    }

    Context 'For getting events from a new issue' {

        It 'Should have no events' {
            $events = @(Get-GitHubEvent -OwnerName $ownerName -RepositoryName $repositoryName -Issue $issue.number)
            $events.Count | Should -Be 0
        }
    }

    Context 'For getting events from an issue' {

        It 'Should have two events from closing and opening the issue' {
            $issue = $issue | Set-GitHubIssue -State Closed -PassThru
            $issue = $issue | Set-GitHubIssue -State Open -PassThru
            $events = @(Get-GitHubEvent -OwnerName $ownerName -RepositoryName $repositoryName)

            $events.Count | Should -Be 2
        }
    }

}

Describe 'Getting an event directly' {
    BeforeAll {
        $repositoryName = [Guid]::NewGuid()
        $repo = New-GitHubRepository -RepositoryName $repositoryName
        $issue = $repo | New-GitHubIssue -Title 'New Issue'
        $issue = $issue | Set-GitHubIssue -State Closed -PassThru
        $issue = $issue | Set-GitHubIssue -State Open -PassThru
        $events = @($repo | Get-GitHubEvent)
    }

    AfterAll {
        $repo | Remove-GitHubRepository -Confirm:$false
    }

    Context 'For getting a single event directly by parameter' {

        It 'Should have the correct event type' {
            $singleEvent = Get-GitHubEvent -OwnerName $ownerName -RepositoryName $repositoryName -EventID $events[0].id
            $singleEvent.event | Should -Be 'reopened'
        }
    }

    Context 'For getting a single event directly by pipeline' {

        BeforeAll {
            $singleEvent = $events[0] | Get-GitHubEvent
        }

        It 'Should have the expected event type' {
            $singleEvent.event | Should -Be $events[0].event
        }

        It 'Should have the same id' {
            $singleEvent.id | Should -Be $events[0].id
        }

        It 'Should have the expected type and additional properties' {
            $singleEvent.PSObject.TypeNames[0] | Should -Be 'GitHub.Event'
            $singleEvent.RepositoryUrl | Should -Be $repo.RepositoryUrl
            $singleEvent.EventId | Should -Be $singleEvent.id
            $singleEvent.actor.PSObject.TypeNames[0] | Should -Be 'GitHub.User'
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
