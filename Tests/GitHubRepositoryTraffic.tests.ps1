# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

<#
.Synopsis
   Tests for GitHubRepositoryTraffic.ps1 module
#>

# This is common test code setup logic for all Pester test files
$moduleRootPath = Split-Path -Path $PSScriptRoot -Parent
. (Join-Path -Path $moduleRootPath -ChildPath 'Tests\Common.ps1')

try
{
    Describe 'Getting the referrer list' {
        $repo = New-GitHubRepository -RepositoryName ([Guid]::NewGuid().Guid) -AutoInit

        Context 'When initially created, there are no referrers' {
            $referrerList = Get-GitHubReferrerTraffic -Uri $repo.svn_url

            It 'Should return expected number of referrers' {
                @($referrerList).Count | Should be 0
            }

            Remove-GitHubRepository -Uri $repo.svn_url -Confirm:$false
        }
    }

    Describe 'Getting the popular content over the last 14 days' {
        $repo = New-GitHubRepository -RepositoryName ([Guid]::NewGuid().Guid) -AutoInit

        Context 'When initially created, there are is no popular content' {
            $pathList = Get-GitHubPathTraffic -Uri $repo.svn_url

            It 'Should return expected number of popular content' {
                @($pathList).Count | Should be 0
            }

            Remove-GitHubRepository -Uri $repo.svn_url -Confirm:$false
        }
    }

    Describe 'Getting the views over the last 14 days' {
        $repo = New-GitHubRepository -RepositoryName ([Guid]::NewGuid().Guid) -AutoInit

        Context 'When initially created, there are no views' {
            $viewList = Get-GitHubViewTraffic -Uri $repo.svn_url

            It 'Should return 0 in the count property' {
                $viewList.Count | Should be 0
            }

            Remove-GitHubRepository -Uri $repo.svn_url -Confirm:$false
        }
    }

    Describe 'Getting the clones over the last 14 days' {
        $repo = New-GitHubRepository -RepositoryName ([Guid]::NewGuid().Guid) -AutoInit

        Context 'When initially created, there is 0 clones' {
            $cloneList = Get-GitHubCloneTraffic -Uri $repo.svn_url

            It 'Should return expected number of clones' {
                $cloneList.Count | Should be 0
            }

            Remove-GitHubRepository -Uri $repo.svn_url -Confirm:$false
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
