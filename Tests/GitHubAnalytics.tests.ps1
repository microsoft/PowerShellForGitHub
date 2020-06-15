# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

<#
.Synopsis
   Tests for GitHubAnalytics.ps1 module
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
<<<<<<< HEAD
    Describe 'Obtaining issues for repository' {
        $repo = New-GitHubRepository -RepositoryName ([Guid]::NewGuid().Guid) -AutoInit

        Context 'When initially created, there are no issues' {
            $issues = @(Get-GitHubIssue -Uri $repo.svn_url)

            It 'Should return expected number of issues' {
                $issues.Count | Should be 0
            }
        }

        Context 'When there are issues present' {
            $newIssues = @()
            for ($i = 0; $i -lt 4; $i++)
            {
                $newIssues += New-GitHubIssue -OwnerName $script:ownerName -RepositoryName $repo.name -Title ([guid]::NewGuid().Guid)
            }

            $newIssues[0] = Update-GitHubIssue -OwnerName $script:ownerName -RepositoryName $repo.name -Issue $newIssues[0].number -State Closed
            $newIssues[-1] = Update-GitHubIssue -OwnerName $script:ownerName -RepositoryName $repo.name -Issue $newIssues[-1].number -State Closed

            $issues = @(Get-GitHubIssue -Uri $repo.svn_url)
            It 'Should return only open issues' {
                $issues.Count | Should be 2
            }

            $issues = @(Get-GitHubIssue -Uri $repo.svn_url -State All)
            It 'Should return all issues' {
                $issues.Count | Should be 4
            }

            $createdOnOrAfterDate = Get-Date -Date $newIssues[0].created_at
            $createdOnOrBeforeDate = Get-Date -Date $newIssues[2].created_at
            $issues = @((Get-GitHubIssue -Uri $repo.svn_url) | Where-Object { ($_.created_at -ge $createdOnOrAfterDate) -and ($_.created_at -le $createdOnOrBeforeDate) })

            It 'Smart object date conversion works for comparing dates' {
                $issues.Count | Should be 2
            }

            $createdDate = Get-Date -Date $newIssues[1].created_at
            $issues = @(Get-GitHubIssue -Uri $repo.svn_url -State All | Where-Object { ($_.created_at -ge $createdDate) -and ($_.state -eq 'closed') })

            It 'Able to filter based on date and state' {
                $issues.Count | Should be 1
            }
        }

        Context 'When issues are retrieved with a specific MediaTypes' {
            $newIssue = New-GitHubIssue -OwnerName $script:ownerName -RepositoryName $repo.name -Title ([guid]::NewGuid()) -Body ([guid]::NewGuid())

            $issues = @(Get-GitHubIssue -Uri $repo.svn_url -Issue $newIssue.number -MediaType 'Html')
            It 'Should return an issue with body_html' {
                $issues[0].body_html | Should not be $null
            }
        }

        $null = Remove-GitHubRepository -Uri ($repo.svn_url) -Confirm:$false
    }

    Describe 'Obtaining repository with biggest number of issues' {
        $repo1 = New-GitHubRepository -RepositoryName ([Guid]::NewGuid().Guid) -AutoInit
        $repo2 = New-GitHubRepository -RepositoryName ([Guid]::NewGuid().Guid) -AutoInit

        Context 'When no additional conditions specified' {
            for ($i = 0; $i -lt 3; $i++)
            {
                $null = New-GitHubIssue -OwnerName $script:ownerName -RepositoryName $repo1.name -Title ([guid]::NewGuid().Guid)
            }

            $repos = @(($repo1.svn_url), ($repo2.svn_url))
            $issueCounts = @()
            $repos | ForEach-Object { $issueCounts = $issueCounts + ([PSCustomObject]@{ 'Uri' = $_; 'Count' = (Get-GitHubIssue -Uri $_).Count }) }
            $issueCounts = $issueCounts | Sort-Object -Property Count -Descending

            It 'Should return expected number of issues for each repository' {
                $issueCounts[0].Count | Should be 3
                $issueCounts[1].Count | Should be 0
            }

            It 'Should return expected repository names' {
                $issueCounts[0].Uri | Should be $repo1.svn_url
                $issueCounts[1].Uri | Should be $repo2.svn_url
            }
        }

        $null = Remove-GitHubRepository -Uri ($repo1.svn_url) -Confirm:$false
        $null = Remove-GitHubRepository -Uri ($repo2.svn_url) -Confirm:$false
    }


=======
>>>>>>> 89bfa42... * [BREAKING CHANGE] Changed signature for Get-GitHubUserContextualInformation to be more natural
    # TODO: Re-enable these tests once the module has sufficient support getting the repository into the
    # required state for testing, and to recover back to the original state at the conclusion of the test.

    # Describe 'Obtaining pull requests for repository' {
    #     Context 'When no additional conditions specified' {
    #         $pullRequests = Get-GitHubPullRequest -Uri $script:repositoryUrl

    #         It 'Should return expected number of PRs' {
    #             @($pullRequests).Count | Should -Be 2
    #         }
    #     }

    #     Context 'When state and time range specified' {
    #         $mergedStartDate = Get-Date -Date '2016-04-10'
    #         $mergedEndDate = Get-Date -Date '2016-05-07'
    #         $pullRequests = Get-GitHubPullRequest -Uri $script:repositoryUrl -State Closed |
    #             Where-Object { ($_.merged_at -ge $mergedStartDate) -and ($_.merged_at -le $mergedEndDate) }

    #         It 'Should return expected number of PRs' {
    #             @($pullRequests).Count | Should -Be 3
    #         }
    #     }
    # }

    # Describe 'Obtaining repository with biggest number of pull requests' {
    #     Context 'When no additional conditions specified' {
    #         @($script:repositoryUrl, $script:repositoryUrl2) |
    #             ForEach-Object {
    #                 $pullRequestCounts += ([PSCustomObject]@{
    #                     'Uri' = $_;
    #                     'Count' = (Get-GitHubPullRequest -Uri $_).Count }) }
    #         $pullRequestCounts = $pullRequestCounts | Sort-Object -Property Count -Descending

    #         It 'Should return expected number of pull requests for each repository' {
    #             @($pullRequestCounts[0].Count) | Should -Be 2
    #             @($pullRequestCounts[1].Count) | Should -Be 0
    #         }

    #         It 'Should return expected repository names' {
    #             @($pullRequestCounts[0].Uri) | Should -Be $script:repositoryUrl
    #             @($pullRequestCounts[1].Uri) | Should -Be $script:repositoryUrl2
    #         }
    #     }

    #     Context 'When state and time range specified' {
    #         $mergedDate = Get-Date -Date '2015-04-20'
    #         $repos = @($script:repositoryUrl, $script:repositoryUrl2)
    #         $pullRequestCounts = @()
    #         $pullRequestSearchParams = @{
    #             'State' = 'closed'
    #         }
    #         $repos |
    #             ForEach-Object {
    #                 $pullRequestCounts += ([PSCustomObject]@{
    #                     'Uri' = $_;
    #                     'Count' = (
    #                         (Get-GitHubPullRequest -Uri $_ @pullRequestSearchParams) |
    #                             Where-Object { $_.merged_at -ge $mergedDate }
    #                     ).Count
    #                 }) }

    #         $pullRequestCounts = $pullRequestCounts | Sort-Object -Property Count -Descending
    #         $pullRequests = Get-GitHubTopPullRequestRepository -Uri @($script:repositoryUrl, $script:repositoryUrl2) -State Closed -MergedOnOrAfter

    #         It 'Should return expected number of pull requests for each repository' {
    #             @($pullRequests[0].Count) | Should -Be 3
    #             @($pullRequests[1].Count) | Should -Be 0
    #         }

    #         It 'Should return expected repository names' {
    #             @($pullRequests[0].Uri) | Should -Be $script:repositoryUrl
    #             @($pullRequests[1].Uri) | Should -Be $script:repositoryUrl2
    #         }
    #     }
    # }

    # TODO: Re-enable these tests once the module has sufficient support getting the Organization
    # and repository into the required state for testing, and to recover back to the original state
    # at the conclusion of the test.

    # Describe 'Obtaining organization members' {
    #     $members = Get-GitHubOrganizationMember -OrganizationName $script:organizationName

    #     It 'Should return expected number of organization members' {
    #         @($members).Count | Should -Be 1
    #     }
    # }

    # Describe 'Obtaining organization teams' {
    #     $teams = Get-GitHubTeam -OrganizationName $script:organizationName

    #     It 'Should return expected number of organization teams' {
    #         @($teams).Count | Should -Be 2
    #     }
    # }

    # Describe 'Obtaining organization team members' {
    #     $members = Get-GitHubTeamMember -OrganizationName $script:organizationName -TeamName $script:organizationTeamName

    #     It 'Should return expected number of organization team members' {
    #         @($members).Count | Should -Be 1
    #     }
    # }
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
