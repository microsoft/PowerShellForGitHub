# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

<#
.Synopsis
   Tests for GitHubEvents.ps1 module
#>

# This is common test code setup logic for all Pester test files
$moduleRootPath = Split-Path -Parent (Split-Path -Parent $Script:MyInvocation.MyCommand.Path)
. (Join-Path -Path $moduleRootPath -ChildPath 'Tests\Common.ps1')

try
{
    if ($accessTokenConfigured)
    {
        Describe 'Getting events from repository' {
            $repositoryName = [Guid]::NewGuid()
            $null = New-GitHubRepository -RepositoryName $repositoryName

            Context 'For getting events from a new repository' {
                $events = @(Get-GitHubEvent -OwnerName $ownerName -RepositoryName $repositoryName)

                It 'Should have no events' {
                    $events.Count | Should be 0
                }
            }

            $issue = New-GithubIssue -OwnerName $ownerName -RepositoryName $repositoryName -Title "New Issue"
            Update-GitHubIssue -OwnerName $ownerName -RepositoryName $repositoryName -Issue $issue.number -State Closed

            Context 'For getting events from a repository' {
                $events = @(Get-GitHubEvent -OwnerName $ownerName -RepositoryName $repositoryName)

                It 'Should have an event from closing an issue' {
                    $events.Count | Should be 1
                }
            }

            $null = Remove-GitHubRepository -OwnerName $ownerName -RepositoryName $repositoryName
        }

        Describe 'Getting events from an issue' {
            $repositoryName = [Guid]::NewGuid()
            $null = New-GitHubRepository -RepositoryName $repositoryName
            $issue = New-GithubIssue -OwnerName $ownerName -RepositoryName $repositoryName -Title "New Issue"

            Context 'For getting events from a new issue' {
                $events = @(Get-GitHubEvent -OwnerName $ownerName -RepositoryName $repositoryName -Issue $issue.number)

                It 'Should have no events' {
                    $events.Count | Should be 0
                }
            }

            Context 'For getting events from an issue' {
                Update-GitHubIssue -OwnerName $ownerName -RepositoryName $repositoryName -Issue $issue.number -State Closed
                Update-GitHubIssue -OwnerName $ownerName -RepositoryName $repositoryName -Issue $issue.number -State Open
                $events = @(Get-GitHubEvent -OwnerName $ownerName -RepositoryName $repositoryName)

                It 'Should have two events from closing and opening the issue' {
                    $events.Count | Should be 2
                }
            }

            $null = Remove-GitHubRepository -OwnerName $ownerName -RepositoryName $repositoryName
        }

        Describe 'Getting an event directly' {
            $repositoryName = [Guid]::NewGuid()
            $null = New-GitHubRepository -RepositoryName $repositoryName
            $issue = New-GithubIssue -OwnerName $ownerName -RepositoryName $repositoryName -Title "New Issue"
            Update-GitHubIssue -OwnerName $ownerName -RepositoryName $repositoryName -Issue $issue.number -State Closed
            Update-GitHubIssue -OwnerName $ownerName -RepositoryName $repositoryName -Issue $issue.number -State Open
            $events = @(Get-GitHubEvent -OwnerName $ownerName -RepositoryName $repositoryName)

            Context 'For getting an event directly'{
                $singleEvent = Get-GitHubEvent -OwnerName $ownerName -RepositoryName $repositoryName -EventID $events[0].id

                It 'Should have the correct event type'{
                    $singleEvent.event | Should be 'reopened'
                }
            }

            $null = Remove-GitHubRepository -OwnerName $ownerName -RepositoryName $repositoryName
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
