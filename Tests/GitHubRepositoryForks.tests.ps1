# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

<#
.Synopsis
   Tests for GitHubRepositoryForks.ps1 module
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
        upstreamOwnerName = 'octocat'
        upstreamRepositoryName = 'git-consortium'
    }.GetEnumerator() | ForEach-Object {
        Set-Variable -Force -Scope Script -Option ReadOnly -Visibility Private -Name $_.Key -Value $_.Value
    }
}
Describe 'Creating a new fork for user' {
    Context 'When a new fork is created' {
        BeforeAll {
            $repo = New-GitHubRepositoryFork -OwnerName $script:upstreamOwnerName -RepositoryName $script:upstreamRepositoryName
            $newForks = @(Get-GitHubRepositoryFork -OwnerName $script:upstreamOwnerName -RepositoryName $script:upstreamRepositoryName -Sort Newest)
            $ourFork = $newForks | Where-Object { $_.owner.login -eq $script:ownerName }
        }

        AfterAll {
            $repo | Remove-GitHubRepository -Force
        }


        It 'Should be in the list' {
            # Doing this syntax, because due to odd timing with GitHub, it's possible it may
            # think that there's an existing clone out there and so may name this one "...-1"
            $ourFork.full_name.StartsWith("$($script:ownerName)/$script:upstreamRepositoryName") | Should -BeTrue
        }

        It 'Should have the expected additional type and properties' {
            $ourFork.PSObject.TypeNames[0] | Should -Be 'GitHub.Repository'
            $ourFork.RepositoryId | Should -Be $ourFork.id
        }
    }

    Context 'When a new fork is created (with the pipeline)' {
        BeforeAll {
            $upstream = Get-GitHubRepository -OwnerName $script:upstreamOwnerName -RepositoryName $script:upstreamRepositoryName
            $repo = $upstream | New-GitHubRepositoryFork
            $newForks = @(Get-GitHubRepositoryFork -OwnerName $script:upstreamOwnerName -RepositoryName $script:upstreamRepositoryName -Sort Newest)
            $ourFork = $newForks | Where-Object { $_.owner.login -eq $script:ownerName }
        }

        AfterAll {
            $repo | Remove-GitHubRepository -Force
        }


        It 'Should be in the list' {
            # Doing this syntax, because due to odd timing with GitHub, it's possible it may
            # think that there's an existing clone out there and so may name this one "...-1"
            $ourFork.full_name.StartsWith("$($script:ownerName)/$script:upstreamRepositoryName") | Should -BeTrue
        }

        It 'Should have the expected additional type and properties' {
            $ourFork.PSObject.TypeNames[0] | Should -Be 'GitHub.Repository'
            $ourFork.RepositoryId | Should -Be $ourFork.id
        }
    }
}

Describe 'Creating a new fork for an org' {
    Context 'When a new fork is created' {
        BeforeAll {
            $repo = New-GitHubRepositoryFork -OwnerName $script:upstreamOwnerName -RepositoryName $script:upstreamRepositoryName -OrganizationName $script:organizationName
            $newForks = @(Get-GitHubRepositoryFork -OwnerName $script:upstreamOwnerName -RepositoryName $script:upstreamRepositoryName -Sort Newest)
            $ourFork = $newForks | Where-Object { $_.owner.login -eq $script:organizationName }
        }

        AfterAll {
            $repo | Remove-GitHubRepository -Force
        }


        It 'Should be in the list' {
            # Doing this syntax, because due to odd timing with GitHub, it's possible it may
            # think that there's an existing clone out there and so may name this one "...-1"
            $ourFork.full_name.StartsWith("$($script:organizationName)/$script:upstreamRepositoryName") | Should -BeTrue
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
