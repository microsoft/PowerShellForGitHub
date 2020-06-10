# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

<#
.Synopsis
   Tests for GitHubRepositoryForks.ps1 module
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
    # Define Script-scoped, readonly, hidden variables.
    @{
        upstreamOwnerName = 'microsoft'
        upstreamRepositoryName = 'PowerShellForGitHub'
    }.GetEnumerator() | ForEach-Object {
        Set-Variable -Force -Scope Script -Option ReadOnly -Visibility Private -Name $_.Key -Value $_.Value
    }

    Describe 'Creating a new fork for user' {
        Context 'When a new fork is created' {
            BeforeAll {
                $repo = New-GitHubRepositoryFork -OwnerName $script:upstreamOwnerName -RepositoryName $script:upstreamRepositoryName
            }

            AfterAll {
                Remove-GitHubRepository -Uri $repo.svn_url -Confirm:$false
            }

            $newForks = @(Get-GitHubRepositoryFork -OwnerName $script:upstreamOwnerName -RepositoryName $script:upstreamRepositoryName -Sort Newest)
            $ourFork = $newForks | Where-Object { $_.owner.login -eq $script:ownerName }

            It 'Should be in the list' {
                # Doing this syntax, because due to odd timing with GitHub, it's possible it may
                # think that there's an existing clone out there and so may name this one "...-1"
                $ourFork.full_name.StartsWith("$($script:ownerName)/$script:upstreamRepositoryName") | Should -BeTrue
            }
        }
    }

    Describe 'Creating a new fork for an org' {
        Context 'When a new fork is created' {
            BeforeAll {
                $repo = New-GitHubRepositoryFork -OwnerName $script:upstreamOwnerName -RepositoryName $script:upstreamRepositoryName -OrganizationName $script:organizationName
            }

            AfterAll {
                Remove-GitHubRepository -Uri $repo.svn_url -Confirm:$false
            }

            $newForks = @(Get-GitHubRepositoryFork -OwnerName $script:upstreamOwnerName -RepositoryName $script:upstreamRepositoryName -Sort Newest)
            $ourFork = $newForks | Where-Object { $_.owner.login -eq $script:organizationName }

            It 'Should be in the list' {
                # Doing this syntax, because due to odd timing with GitHub, it's possible it may
                # think that there's an existing clone out there and so may name this one "...-1"
                $ourFork.full_name.StartsWith("$($script:organizationName)/$script:upstreamRepositoryName") | Should -BeTrue
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
