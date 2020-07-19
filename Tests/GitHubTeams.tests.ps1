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

# This is common test code setup logic for all Pester test files
$moduleRootPath = Split-Path -Path $PSScriptRoot -Parent
. (Join-Path -Path $moduleRootPath -ChildPath 'Tests\Common.ps1')

Set-StrictMode -Version 1.0

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
        BeforeAll {
            $organizationName = $script:organizationName
        }

        Context 'When getting a GitHub Team by organization' {
            BeforeAll {
                $teamName = [Guid]::NewGuid().Guid
                $description = 'Team Description'
                $privacy = 'closed'
                $MaintainerName = $script:ownerName

                $newGithubTeamParms = @{
                    OrganizationName = $organizationName
                    TeamName = $teamName
                    Description = $description
                    Privacy = $privacy
                    MaintainerName = $MaintainerName
                }

                New-GitHubTeam @newGithubTeamParms | Out-Null

                $orgTeams = Get-GitHubTeam -OrganizationName $organizationName

                $team = $orgTeams | Where-Object -Property name -eq $teamName
            }

            It 'Should have the expected type and additional properties' {
                $team.PSObject.TypeNames[0] | Should -Be 'GitHub.TeamSummary'
                $team.name | Should -Be $teamName
                $team.description | Should -Be $description
                $team.parent | Should -BeNullOrEmpty
                $team.privacy | Should -Be $privacy
                $team.TeamName | Should -Be $teamName
                $team.TeamId | Should -Be $team.id
                $team.OrganizationName | Should -Be $organizationName
            }

            Context 'When specifying the "TeamName" parameter' {
                BeforeAll {
                    $team = Get-GitHubTeam -OrganizationName $organizationName -TeamName $teamName
                }

                It 'Should have the expected type and additional properties' {
                    $team.PSObject.TypeNames[0] | Should -Be 'GitHub.Team'
                    $team.name | Should -Be $teamName
                    $team.description | Should -Be $description
                    $team.parent | Should -BeNullOrEmpty
                    $team.privacy | Should -Be $privacy
                    $team.created_at | Should -Not -BeNullOrEmpty
                    $team.updated_at | Should -Not -BeNullOrEmpty
                    $team.members_count | Should -Be 1
                    $team.repos_count | Should -Be 0
                    $team.TeamName | Should -Be $teamName
                    $team.TeamId | Should -Be $team.id
                    $team.OrganizationName | Should -Be $organizationName
                }
            }

            Context 'When specifying the "OrganizationName" parameter through the pipeline' {
                BeforeAll {
                    $orgTeams = $team | Get-GitHubTeam
                    $team = $orgTeams | Where-Object -Property name -eq $teamName
                }

                It 'Should have the expected type and additional properties' {
                    $team.PSObject.TypeNames[0] | Should -Be 'GitHub.TeamSummary'
                    $team.name | Should -Be $teamName
                    $team.description | Should -Be $description
                    $team.parent | Should -BeNullOrEmpty
                    $team.privacy | Should -Be $privacy
                    $team.TeamName | Should -Be $teamName
                    $team.TeamId | Should -Be $team.id
                    $team.OrganizationName | Should -Be $organizationName
                }
            }

            AfterAll {
                if (Get-Variable -Name team -ErrorAction SilentlyContinue)
                {
                    $team | Remove-GitHubTeam -Force
                }
            }
        }

        Context 'When getting a GitHub Team by repository' {
            BeforeAll {
                $repoName = [Guid]::NewGuid().Guid

                $repo = New-GitHubRepository -RepositoryName $repoName -OrganizationName $organizationName

                $teamName = [Guid]::NewGuid().Guid
                $description = 'Team Description'
                $privacy = 'closed'

                $newGithubTeamParms = @{
                    OrganizationName = $organizationName
                    TeamName = $teamName
                    Description = $description
                    RepositoryName = $repoName
                    Privacy = $privacy
                }

                New-GitHubTeam @newGithubTeamParms | Out-Null

                $orgTeams = Get-GitHubTeam -OwnerName $organizationName -RepositoryName $repoName
                $team = $orgTeams | Where-Object -Property name -eq $teamName
            }

            It 'Should have the expected type and additional properties' {
                $team.PSObject.TypeNames[0] | Should -Be 'GitHub.TeamSummary'
                $team.name | Should -Be $teamName
                $team.description | Should -Be $description
                $team.parent | Should -BeNullOrEmpty
                $team.privacy | Should -Be $privacy
                $team.TeamName | Should -Be $teamName
                $team.TeamId | Should -Be $team.id
                $team.OrganizationName | Should -Be $organizationName
            }

            Context 'When specifying the "TeamName" parameter' {
                BeforeAll {
                    $getGitHubTeamParms = @{
                        OwnerName = $organizationName
                        RepositoryName = $repoName
                        TeamName = $teamName
                    }

                    $team = Get-GitHubTeam @getGitHubTeamParms
                }

                It 'Should have the expected type and additional properties' {
                    $team.PSObject.TypeNames[0] | Should -Be 'GitHub.Team'
                    $team.name | Should -Be $teamName
                    $team.description | Should -Be $description
                    $team.parent | Should -BeNullOrEmpty
                    $team.privacy | Should -Be $privacy
                    $team.created_at | Should -Not -BeNullOrEmpty
                    $team.updated_at | Should -Not -BeNullOrEmpty
                    $team.members_count | Should -Be 1
                    $team.repos_count | Should -Be 1
                    $team.TeamName | Should -Be $teamName
                    $team.TeamId | Should -Be $team.id
                    $team.OrganizationName | Should -Be $organizationName
                }
            }

            Context 'When specifying the "Uri" parameter through the pipeline' {
                BeforeAll {
                    $orgTeams = $repo | Get-GitHubTeam -TeamName $teamName
                    $team = $orgTeams | Where-Object -Property name -eq $teamName
                }

                It 'Should have the expected type and additional properties' {
                    $team.PSObject.TypeNames[0] | Should -Be 'GitHub.Team'
                    $team.name | Should -Be $teamName
                    $team.description | Should -Be $description
                    $team.organization.login | Should -Be $organizationName
                    $team.parent | Should -BeNullOrEmpty
                    $team.created_at | Should -Not -BeNullOrEmpty
                    $team.updated_at | Should -Not -BeNullOrEmpty
                    $team.members_count | Should -Be 1
                    $team.repos_count | Should -Be 1
                    $team.privacy | Should -Be $privacy
                    $team.TeamName | Should -Be $teamName
                    $team.TeamId | Should -Be $team.id
                    $team.OrganizationName | Should -Be $organizationName
                }
            }

            AfterAll {
                if (Get-Variable -Name repo -ErrorAction SilentlyContinue)
                {
                    $repo | Remove-GitHubRepository -Force
                }

                if (Get-Variable -Name team -ErrorAction SilentlyContinue)
                {
                    $team | Remove-GitHubTeam -Force
                }
            }
        }

        Context 'When getting a GitHub Team by TeamId' {
            BeforeAll {
                $teamName = [Guid]::NewGuid().Guid
                $description = 'Team Description'
                $privacy = 'closed'
                $MaintainerName = $script:ownerName

                $newGithubTeamParms = @{
                    OrganizationName = $script:organizationName
                    TeamName = $teamName
                    Description = $description
                    Privacy = $privacy
                    MaintainerName = $MaintainerName
                }

                $newTeam = New-GitHubTeam @newGithubTeamParms

                $team = Get-GitHubTeam -TeamId $newTeam.id
            }

            It 'Should have the expected type and additional properties' {
                $team.PSObject.TypeNames[0] | Should -Be 'GitHub.Team'
                $team.name | Should -Be $teamName
                $team.description | Should -Be $description
                $team.organization.login | Should -Be $organizationName
                $team.parent | Should -BeNullOrEmpty
                $team.created_at | Should -Not -BeNullOrEmpty
                $team.updated_at | Should -Not -BeNullOrEmpty
                $team.members_count | Should -Be 1
                $team.repos_count | Should -Be 0
                $team.privacy | Should -Be $privacy
                $team.TeamName | Should -Be $teamName
                $team.TeamId | Should -Be $team.id
                $team.OrganizationName | Should -Be $organizationName
            }

            AfterAll {
                if (Get-Variable -Name team -ErrorAction SilentlyContinue)
                {
                    # The CI build has been unreliable with this test.
                    # Adding a short sleep to ensure successive queries reflect updated state.
                    Start-Sleep -Seconds $script:defaultSleepSecondsForReliability

                    $team | Remove-GitHubTeam -Force
                }
            }
        }
    }

    Describe 'GitHubTeams\New-GitHubTeam' {
        BeforeAll {
            $organizationName = $script:organizationName
        }

        Context 'When creating a new GitHub team with default settings' {
            BeforeAll {
                $teamName = [Guid]::NewGuid().Guid
                $newGithubTeamParms = @{
                    OrganizationName = $organizationName
                    TeamName = $teamName
                }

                $team = New-GitHubTeam @newGithubTeamParms
            }

            It 'Should have the expected type and additional properties' {
                $team.PSObject.TypeNames[0] | Should -Be 'GitHub.Team'
                $team.name | Should -Be $teamName
                $team.description | Should -BeNullOrEmpty
                $team.organization.login | Should -Be $organizationName
                $team.parent | Should -BeNullOrEmpty
                $team.members_count | Should -Be 1
                $team.repos_count | Should -Be 0
                $team.TeamName | Should -Be $teamName
                $team.TeamId | Should -Be $team.id
                $team.OrganizationName | Should -Be $organizationName
            }

            AfterAll {
                if (Get-Variable -Name team -ErrorAction SilentlyContinue)
                {
                    $team | Remove-GitHubTeam -Force
                }
            }
        }

        Context 'When creating a new GitHub team with all possible settings' {
            BeforeAll {
                $repoName = [Guid]::NewGuid().Guid

                $newGithubRepositoryParms = @{
                    RepositoryName = $repoName
                    OrganizationName = $organizationName
                }

                $repo = New-GitHubRepository @newGitHubRepositoryParms

                $maintainer = Get-GitHubUser -UserName $script:ownerName

                $teamName = [Guid]::NewGuid().Guid
                $description = 'Team Description'
                $privacy = 'closed'

                $newGithubTeamParms = @{
                    OrganizationName = $organizationName
                    TeamName = $teamName
                    Description = $description
                    RepositoryName = $repoName
                    Privacy = $privacy
                    MaintainerName = $maintainer.UserName
                }

                $team = New-GitHubTeam @newGithubTeamParms
            }

            It 'Should have the expected type and additional properties' {
                $team.PSObject.TypeNames[0] | Should -Be 'GitHub.Team'
                $team.name | Should -Be $teamName
                $team.description | Should -Be $description
                $team.organization.login | Should -Be $organizationName
                $team.parent | Should -BeNullOrEmpty
                $team.members_count | Should -Be 1
                $team.repos_count | Should -Be 1
                $team.privacy | Should -Be $privacy
                $team.TeamName | Should -Be $teamName
                $team.TeamId | Should -Be $team.id
                $team.OrganizationName | Should -Be $organizationName
            }

            AfterAll {
                if (Get-Variable -Name repo -ErrorAction SilentlyContinue)
                {
                    $repo | Remove-GitHubRepository -Force
                }

                if (Get-Variable -Name team -ErrorAction SilentlyContinue)
                {
                    $team | Remove-GitHubTeam -Force
                }
            }
        }

        Context 'When creating a child GitHub team' {
            BeforeAll {
                $parentTeamName = [Guid]::NewGuid().Guid
                $privacy = 'Closed'

                $newGithubTeamParms = @{
                    OrganizationName = $organizationName
                    TeamName = $parentTeamName
                    Privacy = $privacy
                }

                $parentTeam = New-GitHubTeam @newGithubTeamParms

                $childTeamName = [Guid]::NewGuid().Guid

                $newGithubTeamParms = @{
                    OrganizationName = $organizationName
                    TeamName = $childTeamName
                    ParentTeamName = $parentTeamName
                    Privacy = $privacy
                }

                $childTeam = New-GitHubTeam @newGithubTeamParms
            }

            It 'Should have the expected type and additional properties' {
                $childTeam.PSObject.TypeNames[0] | Should -Be 'GitHub.Team'
                $childTeam.name | Should -Be $childTeamName
                $childTeam.organization.login | Should -Be $organizationName
                $childTeam.parent.name | Should -Be $parentTeamName
                $childTeam.privacy | Should -Be $privacy
                $childTeam.TeamName | Should -Be $childTeamName
                $childTeam.TeamId | Should -Be $childTeam.id
                $childTeam.OrganizationName | Should -Be $organizationName
            }

            AfterAll {
                if (Get-Variable -Name childTeam -ErrorAction SilentlyContinue)
                {
                    $childTeam | Remove-GitHubTeam -Force
                }

                if (Get-Variable -Name parentTeam -ErrorAction SilentlyContinue)
                {
                    $parentTeam | Remove-GitHubTeam -Force
                }
            }
        }

        Context 'When specifying the "Organization" parameter through the pipeline' {
            BeforeAll {
                $teamName1 = [Guid]::NewGuid().Guid
                $teamName2 = [Guid]::NewGuid().Guid

                $newGithubTeamParms = @{
                    OrganizationName = $organizationName
                    TeamName = $teamName1
                }

                $team1 = New-GitHubTeam @newGithubTeamParms

                $team2 = $team1 | New-GitHubTeam -TeamName $teamName2
            }

            It 'Should have the expected type and additional properties' {
                $team2.PSObject.TypeNames[0] | Should -Be 'GitHub.Team'
                $team2.name | Should -Be $teamName2
                $team2.organization.login | Should -Be $organizationName
                $team2.parent | Should -BeNullOrEmpty
                $team2.created_at | Should -Not -BeNullOrEmpty
                $team2.updated_at | Should -Not -BeNullOrEmpty
                $team2.members_count | Should -Be 1
                $team2.repos_count | Should -Be 0
                $team2.TeamName | Should -Be $teamName2
                $team2.TeamId | Should -Be $team2.id
                $team2.OrganizationName | Should -Be $organizationName
            }

            AfterAll {
                if (Get-Variable -Name team1 -ErrorAction SilentlyContinue)
                {
                    $team1 | Remove-GitHubTeam -Force
                }

                if (Get-Variable -Name team2 -ErrorAction SilentlyContinue)
                {
                    $team2 | Remove-GitHubTeam -Force
                }
            }
        }

        Context 'When specifying the "TeamName" parameter through the pipeline' {
            BeforeAll {
                $teamName = [Guid]::NewGuid().Guid

                $team = $teamName | New-GitHubTeam -OrganizationName $organizationName
            }

            It 'Should have the expected type and additional properties' {
                $team.PSObject.TypeNames[0] | Should -Be 'GitHub.Team'
                $team.name | Should -Be $teamName
                $team.organization.login | Should -Be $organizationName
                $team.parent | Should -BeNullOrEmpty
                $team.created_at | Should -Not -BeNullOrEmpty
                $team.updated_at | Should -Not -BeNullOrEmpty
                $team.members_count | Should -Be 1
                $team.repos_count | Should -Be 0
                $team.TeamName | Should -Be $teamName
                $team.TeamId | Should -Be $team.id
                $team.OrganizationName | Should -Be $organizationName
            }

            AfterAll {
                if (Get-Variable -Name team -ErrorAction SilentlyContinue)
                {
                    $team | Remove-GitHubTeam -Force
                }
            }
        }

        Context 'When specifying the "MaintainerName" parameter through the pipeline' {
            BeforeAll {
                $teamName = [Guid]::NewGuid().Guid
                $maintainer = Get-GitHubUser -UserName $script:ownerName

                $team = $maintainer | New-GitHubTeam -OrganizationName $organizationName -TeamName $teamName
            }

            It 'Should have the expected type and additional properties' {
                $team.PSObject.TypeNames[0] | Should -Be 'GitHub.Team'
                $team.name | Should -Be $teamName
                $team.organization.login | Should -Be $organizationName
                $team.parent | Should -BeNullOrEmpty
                $team.created_at | Should -Not -BeNullOrEmpty
                $team.updated_at | Should -Not -BeNullOrEmpty
                $team.members_count | Should -Be 1
                $team.repos_count | Should -Be 0
                $team.TeamName | Should -Be $teamName
                $team.TeamId | Should -Be $team.id
                $team.OrganizationName | Should -Be $organizationName
            }

            AfterAll {
                if (Get-Variable -Name team -ErrorAction SilentlyContinue)
                {
                    $team | Remove-GitHubTeam -Force
                }
            }
        }
    }

    Describe 'GitHubTeams\Set-GitHubTeam' {
        BeforeAll {
            $organizationName = $script:organizationName
        }

        Context 'When updating a Child GitHub team' {
            BeforeAll {
                $teamName = [Guid]::NewGuid().Guid
                $parentTeamName = [Guid]::NewGuid().Guid
                $description = 'Team Description'
                $privacy = 'Closed'

                $newGithubTeamParms = @{
                    OrganizationName = $organizationName
                    TeamName = $parentTeamName
                    Privacy = $privacy
                }

                $parentTeam = New-GitHubTeam @newGithubTeamParms

                $newGithubTeamParms = @{
                    OrganizationName = $organizationName
                    TeamName = $teamName
                    Privacy = $privacy
                }

                $team = New-GitHubTeam @newGithubTeamParms

                $updateGitHubTeamParms = @{
                    OrganizationName = $organizationName
                    TeamName = $teamName
                    Description = $description
                    Privacy = $privacy
                    ParentTeamName = $parentTeamName
                }

                $updatedTeam = Set-GitHubTeam @updateGitHubTeamParms
            }

            It 'Should have the expected type and additional properties' {
                $updatedTeam.PSObject.TypeNames[0] | Should -Be 'GitHub.Team'
                $updatedTeam.name | Should -Be $teamName
                $updatedTeam.organization.login | Should -Be $organizationName
                $updatedTeam.description | Should -Be $description
                $updatedTeam.parent.name | Should -Be $parentTeamName
                $updatedTeam.privacy | Should -Be $privacy
                $updatedTeam.TeamName | Should -Be $teamName
                $updatedTeam.TeamId | Should -Be $team.id
                $updatedTeam.OrganizationName | Should -Be $organizationName
            }

            AfterAll {
                if (Get-Variable -Name team -ErrorAction SilentlyContinue)
                {
                    $team | Remove-GitHubTeam -Force
                }

                if (Get-Variable -Name parentTeam -ErrorAction SilentlyContinue)
                {
                    $parentTeam | Remove-GitHubTeam -Force
                }
            }
        }

        Context 'When updating a non-child GitHub team' {
            BeforeAll {
                $teamName = [Guid]::NewGuid().Guid
                $description = 'Team Description'
                $privacy = 'Closed'

                $newGithubTeamParms = @{
                    OrganizationName = $organizationName
                    TeamName = $teamName
                    Privacy = 'Secret'
                }

                $team = New-GitHubTeam @newGithubTeamParms

                $updateGitHubTeamParms = @{
                    OrganizationName = $organizationName
                    TeamName = $teamName
                    Description = $description
                    Privacy = $privacy
                }

                # The CI build has been unreliable with this test.
                # Adding a short sleep to ensure successive queries reflect updated state.
                Start-Sleep -Seconds $script:defaultSleepSecondsForReliability

                $updatedTeam = Set-GitHubTeam @updateGitHubTeamParms
            }

            It 'Should have the expected type and additional properties' {
                $updatedTeam.PSObject.TypeNames[0] | Should -Be 'GitHub.Team'
                $updatedTeam.name | Should -Be $teamName
                $updatedTeam.organization.login | Should -Be $OrganizationName
                $updatedTeam.description | Should -Be $description
                $updatedTeam.parent.name | Should -BeNullOrEmpty
                $updatedTeam.privacy | Should -Be $privacy
                $updatedTeam.created_at | Should -Not -BeNullOrEmpty
                $updatedTeam.updated_at | Should -Not -BeNullOrEmpty
                $updatedTeam.members_count | Should -Be 1
                $updatedTeam.repos_count | Should -Be 0
                $updatedTeam.TeamName | Should -Be $teamName
                $updatedTeam.TeamId | Should -Be $team.id
                $updatedTeam.OrganizationName | Should -Be $organizationName
            }

            AfterAll {
                if (Get-Variable -Name team -ErrorAction SilentlyContinue)
                {
                    $team | Remove-GitHubTeam -Force
                }
            }
        }

        Context 'When specifying the "Organization" and "TeamName" parameters through the pipeline' {
            BeforeAll {
                $teamName = [Guid]::NewGuid().Guid
                $description = 'Team Description'

                $newGithubTeamParms = @{
                    OrganizationName = $organizationName
                    TeamName = $teamName
                }

                $team = New-GitHubTeam -OrganizationName $organizationName -TeamName $teamName

                $updatedTeam = $team | Set-GitHubTeam -Description $description
            }

            It 'Should have the expected type and additional properties' {
                $updatedTeam.PSObject.TypeNames[0] | Should -Be 'GitHub.Team'
                $updatedTeam.name | Should -Be $teamName
                $updatedTeam.organization.login | Should -Be $OrganizationName
                $updatedTeam.description | Should -Be $description
                $updatedTeam.parent.name | Should -BeNullOrEmpty
                $updatedTeam.created_at | Should -Not -BeNullOrEmpty
                $updatedTeam.updated_at | Should -Not -BeNullOrEmpty
                $updatedTeam.members_count | Should -Be 1
                $updatedTeam.repos_count | Should -Be 0
                $updatedTeam.TeamName | Should -Be $teamName
                $updatedTeam.TeamId | Should -Be $updatedTeam.id
                $updatedTeam.OrganizationName | Should -Be $organizationName
            }

            AfterAll {
                if (Get-Variable -Name team -ErrorAction SilentlyContinue)
                {
                    $team | Remove-GitHubTeam -Force
                }
            }
        }
    }

    Describe 'GitHubTeams\Remove-GitHubTeam' {
        BeforeAll {
            $organizationName = $script:organizationName
        }

        Context 'When removing a GitHub team' {
            BeforeAll {
                $teamName = [Guid]::NewGuid().Guid

                $team = New-GitHubTeam -OrganizationName $organizationName -TeamName $teamName

                # The CI build has been unreliable with this test.
                # Adding a short sleep to ensure successive queries reflect updated state.
                Start-Sleep -Seconds $script:defaultSleepSecondsForReliability
            }

            It 'Should not throw an exception' {
                $removeGitHubTeamParms = @{
                    OrganizationName = $organizationName
                    TeamName = $teamName
                    Confirm = $false
                }

                { Remove-GitHubTeam @RemoveGitHubTeamParms } | Should -Not -Throw
            }

            It 'Should have removed the team' {
                { Get-GitHubTeam -OrganizationName $organizationName -TeamName $teamName } |
                    Should -Throw
            }
        }

        Context 'When specifying the "Organization" and "TeamName" parameters through the pipeline' {
            BeforeAll {
                $teamName = [Guid]::NewGuid().Guid
                $description = 'Team Description'

                $team = New-GitHubTeam -OrganizationName $organizationName -TeamName $teamName

                It 'Should not throw an exception' {
                    { $team |Remove-GitHubTeam -Force } | Should -Not -Throw
                }

                It 'Should have removed the team' {
                    { Get-GitHubTeam -OrganizationName $organizationName -TeamName $teamName } |
                        Should -Throw
                }
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
