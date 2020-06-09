# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

<#
.Synopsis
   Tests for GitHubIssues.ps1 module
#>

# This is common test code setup logic for all Pester test files
$moduleRootPath = Split-Path -Path $PSScriptRoot -Parent
. (Join-Path -Path $moduleRootPath -ChildPath 'Tests\Common.ps1')

try
{
    # All of these tests will fail without authentication.  Let's just avoid the failures.
    if (-not $accessTokenConfigured) { return }

    Describe 'Obtaining issues for repository' {
        BeforeAll {
            $repo = New-GitHubRepository -RepositoryName ([Guid]::NewGuid().Guid) -AutoInit

            # Avoid PSScriptAnalyzer PSUseDeclaredVarsMoreThanAssignments
            $repo = $repo
        }

        AfterAll {
            Remove-GitHubRepository -Uri $repo.RepositoryUrl -Confirm:$false
        }

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
    }

    Describe 'Obtaining repository with biggest number of issues' {
        BeforeAll {
            $repo1 = New-GitHubRepository -RepositoryName ([Guid]::NewGuid().Guid) -AutoInit
            $repo2 = New-GitHubRepository -RepositoryName ([Guid]::NewGuid().Guid) -AutoInit

            # Avoid PSScriptAnalyzer PSUseDeclaredVarsMoreThanAssignments
            $repo1 = $repo1
            $repo2 = $repo2
        }

        AfterAll {
            Remove-GitHubRepository -Uri $repo1.RepositoryUrl -Confirm:$false
            Remove-GitHubRepository -Uri $repo2.RepositoryUrl -Confirm:$false
        }

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
