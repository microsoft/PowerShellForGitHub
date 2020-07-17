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

                $getGitHubTeamParms = @{
                    OrganizationName = $organizationName
                    TeamName = $teamName
                }

                $team = Get-GitHubTeam @getGitHubTeamParms
            }

            It 'Should have the expected type and additional properties' {
                $team.PSObject.TypeNames[0] | Should -Be 'GitHub.Team'
                $team.name | Should -Be $teamName
                $team.description | Should -Be $description
                $team.organization.login | Should -Be $organizationName
                $team.parent | Should -BeNullOrEmpty
                $team.members_count | Should -Be 1
                $team.repos_count | Should -Be 0
                $team.privacy | Should -Be $privacy
                $team.TeamName | Should -Be $teamName
                $team.TeamId | Should -Be $team.id
                $team.OrganizationName | Should -Be $organizationName
            }

            It 'Should support pipeline input for the organization parameter' {
                { $team | Get-GitHubTeam -WhatIf } | Should -Not -Throw
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

                $newGithubRepositoryParms = @{
                    RepositoryName = $repoName
                    OrganizationName = $organizationName
                }

                $repo = New-GitHubRepository @newGitHubRepositoryParms

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

                $getGitHubTeamParms = @{
                    OwnerName = $organizationName
                    RepositoryName = $repoName
                }

                $team = Get-GitHubTeam @getGitHubTeamParms
            }

            It 'Should have the expected type and additional properties' {
                $team.PSObject.TypeNames[0] | Should -Be 'GitHub.Team'
                $team.name | Should -Be $teamName
                $team.description | Should -Be $description
                $team.parent | Should -BeNullOrEmpty
                $team.privacy | Should -Be $privacy
                $team.TeamName | Should -Be $teamName
                $team.TeamId | Should -Be $team.id
                $team.OrganizationName | Should -Be $organizationName
            }

            It 'Should support pipeline input for the uri parameter' {
                { $repo | Get-GitHubTeam -WhatIf } | Should -Not -Throw
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

                $getGitHubTeamParms = @{
                    TeamId = $newTeam.id
                }

                $team = Get-GitHubTeam @getGitHubTeamParms
            }

            It 'Should have the expected type and additional properties' {
                $team.PSObject.TypeNames[0] | Should -Be 'GitHub.Team'
                $team.name | Should -Be $teamName
                $team.description | Should -Be $description
                $team.organization.login | Should -Be $organizationName
                $team.parent | Should -BeNullOrEmpty
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

            It 'Should support pipeline input for the TeamName parameter' {
                { $teamName | New-GitHubTeam -OrganizationName $organizationName -WhatIf } |
                    Should -Not -Throw
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

            It 'Should support pipeline input for the MaintainerName parameter' {
                $newGithubTeamParms = @{
                    OrganizationName = $organizationName
                    TeamName = $teamName
                }

                { $maintainer | New-GitHubTeam @newGithubTeamParms -WhatIf } |
                    Should -Not -Throw
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

            It 'Should support pipeline input for the OrganizationName and TeamName parameters' {
                { $team | Set-GitHubTeam -Description $description -WhatIf } |
                    Should -Not -Throw
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

                $updatedTeam = Set-GitHubTeam @updateGitHubTeamParms
            }

            It 'Should have the expected type and additional properties' {
                $updatedTeam.PSObject.TypeNames[0] | Should -Be 'GitHub.Team'
                $updatedTeam.name | Should -Be $teamName
                $updatedTeam.organization.login | Should -Be $OrganizationName
                $updatedTeam.description | Should -Be $description
                $updatedTeam.parent.name | Should -BeNullOrEmpty
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
                $newGithubTeamParms = @{
                    OrganizationName = $organizationName
                    TeamName = $teamName
                }

                $team = New-GitHubTeam @newGithubTeamParms
            }

            It 'Should support pipeline input for the TeamName parameter' {
                { $team | Remove-GitHubTeam -Force -WhatIf } | Should -Not -Throw
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
                $getGitHubTeamParms = @{
                    OrganizationName = $organizationName
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
