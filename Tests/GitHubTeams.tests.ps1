# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

<#
.Synopsis
   Tests for GitHubTeams.ps1 module
#>

[CmdletBinding()]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '',
    Justification='Suppress false positives in Pester code blocks')]
param()

Set-StrictMode -Version 1.0

# This is common test code setup logic for all Pester test files
$moduleRootPath = Split-Path -Path $PSScriptRoot -Parent
. (Join-Path -Path $moduleRootPath -ChildPath 'Tests\Common.ps1')

try
{
    # Define Script-scoped, readonly, hidden variables.
    @{
        defaultRepoDesc = "This is a description."
        defaultRepoHomePage = "https://www.microsoft.com/"
        defaultRepoTopic = "microsoft"
    }.GetEnumerator() | ForEach-Object {
        Set-Variable -Force -Scope Script -Option ReadOnly -Visibility Private -Name $_.Key -Value $_.Value
    }

    Describe 'GitHubTeams\Get-GitHubTeam' {

        Context 'When getting a GitHub Team by organization' {
            BeforeAll {
                $repoName = [Guid]::NewGuid().Guid

                $newGithubRepositoryParms = @{
                    RepositoryName = $repoName
                    OrganizationName = $script:organizationName
                }
                $repo = New-GitHubRepository @newGitHubRepositoryParms

                $teamName = [Guid]::NewGuid().Guid
                $description = 'Team Description'
                $privacy = 'closed'
                $maintainers = $script:ownerName

                $newGithubTeamParms = @{
                    OrganizationName = $script:organizationName
                    TeamName = $teamName
                    Description = $description
                    RepositoryName = $repo.full_name
                    Privacy = $privacy
                    Maintainers = $maintainers
                }
                New-GitHubTeam @newGithubTeamParms | Out-Null

                $getGitHubTeamParms = @{
                    OrganizationName = $script:organizationName
                    TeamName = $teamName
                }
                $team = Get-GitHubTeam @getGitHubTeamParms
            }

            It 'Should return an object of the correct type' {
                $team | Should -BeOfType PSCustomObject
            }

            It 'Should return the correct properties' {
                $team.name | Should -Be $teamName
                $team.description | Should -Be $description
                $team.organization.login | Should -Be $script:organizationName
                $team.parent | Should -BeNullOrEmpty
                $team.members_count | Should -Be 1
                $team.repos_count | Should -Be 1
                $team.privacy | Should -Be $privacy
            }

            AfterAll {
                if ($team)
                {
                    $removeGitHubTeamParms = @{
                        OrganizationName = $script:organizationName
                        TeamName = $team.name
                        Confirm = $false
                    }
                    Remove-GitHubTeam @RemoveGitHubTeamParms
                }
            }
        }

        Context 'When getting a GitHub Team by repository' {
            BeforeAll -ScriptBlock {
                $repoName = [Guid]::NewGuid().Guid

                $newGithubRepositoryParms = @{
                    RepositoryName = $repoName
                    OrganizationName = $script:organizationName
                }
                $repo = New-GitHubRepository @newGitHubRepositoryParms

                $teamName = [Guid]::NewGuid().Guid
                $description = 'Team Description'
                $privacy = 'closed'

                $newGithubTeamParms = @{
                    OrganizationName = $script:organizationName
                    TeamName = $teamName
                    Description = $description
                    RepositoryName = $repo.full_name
                    Privacy = $privacy
                }
                New-GitHubTeam @newGithubTeamParms | Out-Null

                $getGitHubTeamParms = @{
                    OwnerName = $script:organizationName
                    RepositoryName = $repoName
                }
                $team = Get-GitHubTeam @getGitHubTeamParms
            }

            It 'Should return an object of the correct type' {
                $team | Should -BeOfType PSCustomObject
            }

            It 'Should return the correct properties' {
                $team.name | Should -Be $teamName
                $team.description | Should -Be $description
                $team.parent | Should -BeNullOrEmpty
                $team.privacy | Should -Be $privacy
            }

            AfterAll {
                if ($repo)
                {
                    $removeGitHubRepositoryParms = @{
                        OwnerName = $script:organizationName
                        RepositoryName = $repo.name
                        Confirm = $false
                    }
                    Remove-GitHubRepository @removeGitHubRepositoryParms
                }

                if ($team)
                {
                    $removeGitHubTeamParms = @{
                        OrganizationName = $script:organizationName
                        TeamName = $team.name
                        Confirm = $false
                    }
                    Remove-GitHubTeam @RemoveGitHubTeamParms
                }
            }
        }

        Context 'When getting a GitHub Team by TeamId' {
            BeforeAll {
                $repoName = [Guid]::NewGuid().Guid

                $newGithubRepositoryParms = @{
                    RepositoryName = $repoName
                    OrganizationName = $script:organizationName
                }
                $repo = New-GitHubRepository @newGitHubRepositoryParms

                $teamName = [Guid]::NewGuid().Guid
                $description = 'Team Description'
                $privacy = 'closed'
                $maintainers = $script:ownerName

                $newGithubTeamParms = @{
                    OrganizationName = $script:organizationName
                    TeamName = $teamName
                    Description = $description
                    RepositoryName = $repo.full_name
                    Privacy = $privacy
                    Maintainers = $maintainers
                }
                $newTeam = New-GitHubTeam @newGithubTeamParms

                $getGitHubTeamParms = @{
                    TeamId = $newTeam.id
                }
                $team = Get-GitHubTeam @getGitHubTeamParms
            }

            It 'Should return an object of the correct type' {
                $team | Should -BeOfType PSCustomObject
            }

            It 'Should return the correct properties' {
                $team.name | Should -Be $teamName
                $team.description | Should -Be $description
                $team.organization.login | Should -Be $script:organizationName
                $team.parent | Should -BeNullOrEmpty
                $team.members_count | Should -Be 1
                $team.repos_count | Should -Be 1
                $team.privacy | Should -Be $privacy
            }

            AfterAll {
                if ($team)
                {
                    $removeGitHubTeamParms = @{
                        OrganizationName = $script:organizationName
                        TeamName = $team.name
                        Confirm = $false
                    }
                    Remove-GitHubTeam @RemoveGitHubTeamParms
                }
            }
        }
    }

    Describe 'GitHubTeams\New-GitHubTeam' {

        Context 'When creating a new GitHub team with default settings' {
            BeforeAll {
                $teamName = [Guid]::NewGuid().Guid
                $newGithubTeamParms = @{
                    OrganizationName = $script:organizationName
                    TeamName = $teamName
                }
                $team = New-GitHubTeam @newGithubTeamParms
            }

            It 'Should return an object of the correct type' {
                $team | Should -BeOfType PSCustomObject
            }

            It 'Should return the correct properties' {
                $team.name | Should -Be $teamName
                $team.organization.login | Should -Be $OrganizationName
                $team.description | Should -BeNullOrEmpty
                $team.parent | Should -BeNullOrEmpty
                $team.members_count | Should -Be 1
                $team.repos_count | Should -Be 0
            }

            AfterAll {
                if ($team)
                {
                    $removeGitHubTeamParms = @{
                        OrganizationName = $script:organizationName
                        TeamName = $team.name
                        Confirm = $false
                    }
                    Remove-GitHubTeam @RemoveGitHubTeamParms
                }
            }
        }

        Context 'When creating a new GitHub team with all possible settings' {
            BeforeAll {
                $repoName = [Guid]::NewGuid().Guid

                $newGithubRepositoryParms = @{
                    RepositoryName = $repoName
                    OrganizationName = $script:organizationName
                }
                $repo = New-GitHubRepository @newGitHubRepositoryParms

                $teamName = [Guid]::NewGuid().Guid
                $description = 'Team Description'
                $privacy = 'closed'
                $maintainers = $script:ownerName

                $newGithubTeamParms = @{
                    OrganizationName = $script:organizationName
                    TeamName = $teamName
                    Description = $description
                    RepositoryName = $repo.full_name
                    Privacy = $privacy
                    Maintainers = $maintainers
                }
                $team = New-GitHubTeam @newGithubTeamParms
            }

            It 'Should return an object of the correct type' {
                $team | Should -BeOfType PSCustomObject
            }

            It 'Should return the correct properties' {
                $team.name | Should -Be $teamName
                $team.organization.login | Should -Be $OrganizationName
                $team.description | Should -Be $description
                $team.parent | Should -BeNullOrEmpty
                $team.members_count | Should -Be 1
                $team.repos_count | Should -Be 1
                $team.privacy | Should -Be $privacy
            }

            AfterAll {
                if ($repo)
                {
                    $removeGitHubRepositoryParms = @{
                        OwnerName = $script:organizationName
                        RepositoryName = $repo.name
                        Confirm = $false
                    }
                    Remove-GitHubRepository @removeGitHubRepositoryParms
                }
                if ($team)
                {
                    $removeGitHubTeamParms = @{
                        OrganizationName = $script:organizationName
                        TeamName = $team.name
                        Confirm = $false
                    }
                    Remove-GitHubTeam @RemoveGitHubTeamParms
                }
            }
        }

        Context 'When creating a child GitHub team' {
            BeforeAll {

                $parentTeamName = [Guid]::NewGuid().Guid
                $privacy= 'Closed'

                $newGithubTeamParms = @{
                    OrganizationName = $script:organizationName
                    TeamName = $parentTeamName
                    Privacy = $privacy
                }
                $parentTeam = New-GitHubTeam @newGithubTeamParms

                $childTeamName = [Guid]::NewGuid().Guid

                $newGithubTeamParms = @{
                    OrganizationName = $script:organizationName
                    TeamName = $childTeamName
                    ParentTeamName = $parentTeamName
                    Privacy = $privacy
                }
                $childTeam = New-GitHubTeam @newGithubTeamParms
            }

            It 'Should return an object of the correct type' {
                $childTeam | Should -BeOfType PSCustomObject
            }

            It 'Should return the correct properties' {
                $childTeam.name | Should -Be $childTeamName
                $childTeam.organization.login | Should -Be $OrganizationName
                $childTeam.parent.name | Should -Be $parentTeamName
                $childTeam.privacy | Should -Be $privacy
            }

            AfterAll {
                if ($childTeam)
                {
                    $removeGitHubTeamParms = @{
                        OrganizationName = $script:organizationName
                        TeamName = $childTeam.name
                        Confirm = $false
                    }
                    Remove-GitHubTeam @RemoveGitHubTeamParms
                }

                if ($parentTeam)
                {
                    $removeGitHubTeamParms = @{
                        OrganizationName = $script:organizationName
                        TeamName = $parentTeam.name
                        Confirm = $false
                    }
                    Remove-GitHubTeam @RemoveGitHubTeamParms
                }
            }
        }
    }

    Describe 'GitHubTeams\Update-GitHubTeam' {

        Context 'When updating a Child GitHub team' {
            BeforeAll {
                $teamName = [Guid]::NewGuid().Guid
                $description = 'Team Description'
                $privacy = 'Closed'
                $parentTeamName = [Guid]::NewGuid().Guid

                $newGithubTeamParms = @{
                    OrganizationName = $script:organizationName
                    TeamName = $parentTeamName
                    Privacy = $privacy
                }
                $parentTeam = New-GitHubTeam @newGithubTeamParms

                $newGithubTeamParms = @{
                    OrganizationName = $script:organizationName
                    TeamName = $teamName
                    Privacy = $privacy
                }
                $team = New-GitHubTeam @newGithubTeamParms

                $updateGitHubTeamParms = @{
                    OrganizationName = $script:organizationName
                    TeamName = $teamName
                    Description = $description
                    Privacy = $privacy
                    ParentTeamName = $parentTeamName
                }

                $updatedTeam = Update-GitHubTeam @updateGitHubTeamParms
            }

            It 'Should return an object of the correct type' {
                $updatedTeam | Should -BeOfType PSCustomObject
            }

            It 'Should return the correct properties' {
                $updatedTeam.name | Should -Be $teamName
                $updatedTeam.organization.login | Should -Be $OrganizationName
                $updatedTeam.description | Should -Be $description
                $updatedTeam.parent.name | Should -Be $parentTeamName
                $updatedTeam.privacy | Should -Be $privacy
            }

            AfterAll {
                if ($team)
                {
                    $removeGitHubTeamParms = @{
                        OrganizationName = $script:organizationName
                        TeamName = $team.name
                        Confirm = $false
                    }
                    Remove-GitHubTeam @RemoveGitHubTeamParms
                }

                if ($parentTeam)
                {
                    $removeGitHubTeamParms = @{
                        OrganizationName = $script:organizationName
                        TeamName = $parentTeam.name
                        Confirm = $false
                    }
                    Remove-GitHubTeam @RemoveGitHubTeamParms
                }
            }
        }

        Context 'When updating a non-nested GitHub team' {
            BeforeAll {
                $teamName = [Guid]::NewGuid().Guid
                $description = 'Team Description'
                $privacy = 'Closed'

                $newGithubTeamParms = @{
                    OrganizationName = $script:organizationName
                    TeamName = $teamName
                    Privacy = 'Secret'
                }
                $team = New-GitHubTeam @newGithubTeamParms

                $updateGitHubTeamParms = @{
                    OrganizationName = $script:organizationName
                    TeamName = $teamName
                    Description = $description
                    Privacy = $privacy
                }

                $updatedTeam = Update-GitHubTeam @updateGitHubTeamParms
            }

            It 'Should return an object of the correct type' {
                $updatedTeam | Should -BeOfType PSCustomObject
            }

            It 'Should return the correct properties' {
                $updatedTeam.name | Should -Be $teamName
                $updatedTeam.organization.login | Should -Be $OrganizationName
                $updatedTeam.description | Should -Be $description
                $updatedTeam.parent.name | Should -BeNullOrEmpty
                $updatedTeam.privacy | Should -Be $privacy
            }

            AfterAll {
                if ($team)
                {
                    $removeGitHubTeamParms = @{
                        OrganizationName = $script:organizationName
                        TeamName = $team.name
                        Confirm = $false
                    }
                    Remove-GitHubTeam @RemoveGitHubTeamParms
                }
            }
        }
    }

    Describe 'GitHubTeams\Remove-GitHubTeam' {

        Context 'When removing a GitHub team' {
            BeforeAll {
                $teamName = [Guid]::NewGuid().Guid
                $newGithubTeamParms = @{
                    OrganizationName = $script:organizationName
                    TeamName = $teamName
                }
                $team = New-GitHubTeam @newGithubTeamParms
            }

            It 'Should not throw an exception' {
                $removeGitHubTeamParms = @{
                    OrganizationName = $script:organizationName
                    TeamName = $teamName
                    Confirm = $false
                }
                { Remove-GitHubTeam @RemoveGitHubTeamParms } |
                    Should -Not -Throw

            }

            It 'Should have removed the team' {
                $getGitHubTeamParms = @{
                    OrganizationName = $script:organizationName
                    TeamName = $teamName
                }
                { Get-GitHubTeam @getGitHubTeamParms } | Should -Throw
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
