# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

<#
.Synopsis
   Tests for GitHubRepositoryTraffic.ps1 module
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

Describe 'Testing the referrer traffic on a repository' {
    BeforeAll {
        $repo = New-GitHubRepository -RepositoryName ([Guid]::NewGuid().Guid) -AutoInit
    }

    AfterAll {
        Remove-GitHubRepository -Uri $repo.RepositoryUrl -Confirm:$false
    }

    Context 'When initially created, there are no referrers' {
        It 'Should return expected number of referrers' {
            $traffic = Get-GitHubReferrerTraffic -Uri $repo.svn_url
            $traffic | Should -BeNullOrEmpty
        }

        It 'Should have the expected type (via pipeline)' {
            $traffic = $repo | Get-GitHubReferrerTraffic
            $traffic | Should -BeNullOrEmpty
        }
    }
}

Describe 'Testing the path traffic on a repository' {
    BeforeAll {
        $repo = New-GitHubRepository -RepositoryName ([Guid]::NewGuid().Guid) -AutoInit
    }

    AfterAll {
        Remove-GitHubRepository -Uri $repo.RepositoryUrl -Confirm:$false
    }

    Context 'Getting the popular content over the last 14 days' {
        It 'Should have no traffic since it was just created' {
            $traffic = Get-GitHubPathTraffic -Uri $repo.svn_url
            $traffic | Should -BeNullOrEmpty
        }

        It 'Should have the expected type (via pipeline)' {
            $traffic = $repo | Get-GitHubPathTraffic
            $traffic | Should -BeNullOrEmpty
        }
    }
}

Describe 'Testing the view traffic on a repository' {
    BeforeAll {
        $repo = New-GitHubRepository -RepositoryName ([Guid]::NewGuid().Guid) -AutoInit
    }

    AfterAll {
        Remove-GitHubRepository -Uri $repo.RepositoryUrl -Confirm:$false
    }

    Context 'Getting the views over the last 14 days' {
        It 'Should have no traffic since it was just created' {
            $traffic = Get-GitHubViewTraffic -Uri $repo.svn_url
            $traffic.Count | Should -Be 0
        }

        It 'Should have the expected type (via pipeline)' {
            $traffic = $repo | Get-GitHubViewTraffic
            $traffic.PSObject.TypeNames[0] | Should -Be 'GitHub.ViewTraffic'
        }
    }
}

Describe 'Testing the clone traffic on a repository' {
    BeforeAll {
        $repo = New-GitHubRepository -RepositoryName ([Guid]::NewGuid().Guid) -AutoInit
    }

    AfterAll {
        Remove-GitHubRepository -Uri $repo.RepositoryUrl -Confirm:$false
    }

    Context 'Getting the clones over the last 14 days' {
        It 'Should have no clones since it was just created' {
            $traffic = Get-GitHubCloneTraffic -Uri $repo.svn_url
            $traffic.Count | Should -Be 0
        }

        It 'Should have no clones since it was just created (via pipeline)' {
            $traffic = $repo | Get-GitHubCloneTraffic
            $traffic.PSObject.TypeNames[0] | Should -Be 'GitHub.CloneTraffic'
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
