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
    Describe 'Getting a user' {
        Context 'Current user when additional properties are enabled' {
            BeforeAll {
                $currentUser = Get-GitHubUser -Current

                # Avoid PSScriptAnalyzer PSUseDeclaredVarsMoreThanAssignments
                $currentUser = $currentUser
            }

            It 'Should have the expected type and additional properties' {
                $currentUser.UserName | Should -Be $currentUser.login
                $currentUser.UserId | Should -Be $currentUser.id
                $currentUser.PSObject.TypeNames[0] | Should -Be 'GitHub.User'
            }
        }

        Context 'Current user when additional properties are disabled' {
            BeforeAll {
                Set-GitHubConfiguration -DisablePipelineSupport
                $currentUser = Get-GitHubUser -Current

                # Avoid PSScriptAnalyzer PSUseDeclaredVarsMoreThanAssignments
                $currentUser = $currentUser
            }

            AfterAll {
                Set-GitHubConfiguration -DisablePipelineSupport:$false
            }

            It 'Should only have the expected type' {
                $currentUser.UserName | Should -BeNullOrEmpty
                $currentUser.UserId | Should -BeNullOrEmpty
                $currentUser.PSObject.TypeNames[0] | Should -Be 'GitHub.User'
            }
        }

        Context 'Specific user as a parameter' {
            BeforeAll {
                $user = Get-GitHubUser -User $script:ownerName

                # Avoid PSScriptAnalyzer PSUseDeclaredVarsMoreThanAssignments
                $user = $user
            }

            It 'Should have the expected type and additional properties' {
                $user.UserName | Should -Be $user.login
                $user.UserId | Should -Be $user.id
                $user.PSObject.TypeNames[0] | Should -Be 'GitHub.User'
            }
        }

        Context 'Specific user with the pipeline' {
            BeforeAll {
                $user = $script:ownerName | Get-GitHubUser

                # Avoid PSScriptAnalyzer PSUseDeclaredVarsMoreThanAssignments
                $user = $user
            }

            It 'Should have the expected type and additional properties' {
                $user.UserName | Should -Be $user.login
                $user.UserId | Should -Be $user.id
                $user.PSObject.TypeNames[0] | Should -Be 'GitHub.User'
            }
        }
    }

    Describe 'Getting user context' {
        BeforeAll {
            $repo = New-GitHubRepository -RepositoryName ([Guid]::NewGuid().Guid) -AutoInit

            # Avoid PSScriptAnalyzer PSUseDeclaredVarsMoreThanAssignments
            $repo = $repo
        }

        AfterAll {
            Remove-GitHubRepository -Uri $repo.RepositoryUrl -Confirm:$false
        }

        Context 'Checking context on a repo' {
            It 'Should indicate ownership as a parameter' {
                $context = Get-GitHubUserContextualInformation -User $script:ownerName -RepositoryId $repo.id
                'Owns this repository' | Should -BeIn $context.contexts.message
            }

            It 'Should indicate ownership with the repo on the pipeline' {
                $context = $repo | Get-GitHubUserContextualInformation -User $script:ownerName
                'Owns this repository' | Should -BeIn $context.contexts.message
            }

            It 'Should indicate ownership with the username on the pipeline' {
                $context = $script:ownerName | Get-GitHubUserContextualInformation -RepositoryId $repo.id
                'Owns this repository' | Should -BeIn $context.contexts.message
            }

            It 'Should indicate ownership with the user on the pipeline' {
                $user = Get-GitHubUser -User $script:ownerName
                $context = $user | Get-GitHubUserContextualInformation -RepositoryId $repo.id
                'Owns this repository' | Should -BeIn $context.contexts.message
            }
        }

        Context 'Checking context on an issue with the pipeline' {
            $issue = New-GitHubIssue -Uri $repo.RepositoryUrl -Title ([guid]::NewGuid().Guid)
            $context = $issue | Get-GitHubUserContextualInformation -User $script:ownerName

            It 'Should indicate the user created the issue' {
                $context.contexts[0].octicon | Should -Be 'issue-opened'
            }

            It 'Should indicate the user owns the repository' {
                $context.contexts[1].message | Should -Be 'Owns this repository'
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
