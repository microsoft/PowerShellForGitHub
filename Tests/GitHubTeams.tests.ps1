# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

<#
.Synopsis
   Tests for GitHubTeams.ps1 module
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
        defaultRepoDesc = "This is a description."
        defaultRepoHomePage = "https://www.microsoft.com/"
        defaultRepoTopic = "microsoft"
    }.GetEnumerator() | ForEach-Object {
        Set-Variable -Force -Scope Script -Option ReadOnly -Visibility Private -Name $_.Key -Value $_.Value
    }
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
            $team.TeamName | Should -Be $team.name
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
                $team.TeamName | Should -Be $team.name
                $team.TeamId | Should -Be $team.id
                $team.OrganizationName | Should -Be $organizationName
            }
        }

        Context 'When specifying the "OrganizationName" and "TeamSlug" through the pipeline' {
            BeforeAll {
                $orgTeams = $team | Get-GitHubTeam
                $team = $orgTeams | Where-Object -Property name -eq $teamName
            }

            It 'Should have the expected type and additional properties' {
                $team.PSObject.TypeNames[0] | Should -Be 'GitHub.Team'
                $team.name | Should -Be $teamName
                $team.description | Should -Be $description
                $team.parent | Should -BeNullOrEmpty
                $team.privacy | Should -Be $privacy
                $team.TeamName | Should -Be $team.name
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
            $team.TeamName | Should -Be $team.name
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
                $team.TeamName | Should -Be $team.name
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
                $team.TeamName | Should -Be $team.name
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

    Context 'When getting a GitHub Team by TeamSlug' {
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
        }

        It 'Should have the expected type and additional properties as a parameter' {
            $team = Get-GitHubTeam -OrganizationName  $script:organizationName -TeamSlug $newTeam.slug
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
            $team.TeamName | Should -Be $team.name
            $team.TeamId | Should -Be $team.id
            $team.OrganizationName | Should -Be $organizationName
        }

        It 'Should have the expected type and additional properties via the pipeline' {
            $team = $newTeam | Get-GitHubTeam
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
            $team.TeamName | Should -Be $team.name
            $team.TeamId | Should -Be $team.id
            $team.OrganizationName | Should -Be $organizationName
        }

        AfterAll {
            if (Get-Variable -Name newTeam -ErrorAction SilentlyContinue)
            {
                $newTeam | Remove-GitHubTeam -Force
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
            $team.TeamName | Should -Be $team.name
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
            $team.TeamName | Should -Be $team.name
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

    Context 'When creating a child GitHub team using the Parent TeamName' {
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
            $childTeam.TeamName | Should -Be $childTeam.name
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

    Context 'When creating a child GitHub team using the Parent TeamId' {
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
                ParentTeamId = $parentTeam.id
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
            $childTeam.TeamName | Should -Be $childTeam.name
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

    Context 'When creating a child GitHub team using the Parent TeamId on the pipeline' {
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
                TeamName = $childTeamName
                Privacy = $privacy
            }

            $childTeam = $parentTeam | New-GitHubTeam @newGithubTeamParms
        }

        It 'Should have the expected type and additional properties' {
            $childTeam.PSObject.TypeNames[0] | Should -Be 'GitHub.Team'
            $childTeam.name | Should -Be $childTeamName
            $childTeam.organization.login | Should -Be $organizationName
            $childTeam.parent.name | Should -Be $parentTeamName
            $childTeam.privacy | Should -Be $privacy
            $childTeam.TeamName | Should -Be $childTeam.name
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
            $team.TeamName | Should -Be $team.name
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
            $team.TeamName | Should -Be $team.name
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

            $updatedTeam = Set-GitHubTeam @updateGitHubTeamParms -PassThru
        }

        It 'Should have the expected type and additional properties' {
            $updatedTeam.PSObject.TypeNames[0] | Should -Be 'GitHub.Team'
            $updatedTeam.name | Should -Be $teamName
            $updatedTeam.organization.login | Should -Be $organizationName
            $updatedTeam.description | Should -Be $description
            $updatedTeam.parent.name | Should -Be $parentTeamName
            $updatedTeam.privacy | Should -Be $privacy
            $updatedTeam.TeamName | Should -Be $team.name
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

            $updatedTeam = Set-GitHubTeam @updateGitHubTeamParms -PassThru
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
            $updatedTeam.TeamName | Should -Be $team.name
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

    Context 'When updating a GitHub team to be a child using the Parent TeamId' {
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
                ParentTeamId = $parentTeam.id
            }

            $updatedTeam = Set-GitHubTeam @updateGitHubTeamParms -PassThru
        }

        It 'Should have the expected type and additional properties' {
            $updatedTeam.PSObject.TypeNames[0] | Should -Be 'GitHub.Team'
            $updatedTeam.name | Should -Be $teamName
            $updatedTeam.organization.login | Should -Be $organizationName
            $updatedTeam.description | Should -Be $description
            $updatedTeam.parent.name | Should -Be $parentTeamName
            $updatedTeam.privacy | Should -Be $privacy
            $updatedTeam.TeamName | Should -Be $team.name
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

    Context 'When specifying the "Organization" and "TeamName" parameters through the pipeline' {
        BeforeAll {
            $teamName = [Guid]::NewGuid().Guid
            $description = 'Team Description'

            $newGithubTeamParms = @{
                OrganizationName = $organizationName
                TeamName = $teamName
            }

            $team = New-GitHubTeam @newGithubTeamParms

            $updatedTeam = $team | Set-GitHubTeam -Description $description -PassThru
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
            $updatedTeam.TeamName | Should -Be $team.name
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

Describe 'GitHubTeams\Rename-GitHubTeam' {
    BeforeAll {
        $organizationName = $script:organizationName
        $teamName = [Guid]::NewGuid().Guid
        $newTeamName = [Guid]::NewGuid().Guid
    }

    Context 'When renaming a GitHub team with the TeamName' {
        BeforeAll {
            $team = New-GitHubTeam -OrganizationName $organizationName -TeamName $teamName
            $updatedTeam = Rename-GitHubTeam -OrganizationName $organizationName -TeamName $teamName -NewTeamName $newTeamName -PassThru
        }

        It 'Should have the expected type and additional properties' {
            $updatedTeam.PSObject.TypeNames[0] | Should -Be 'GitHub.Team'
            $updatedTeam.name | Should -Be $newTeamName
            $updatedTeam.organization.login | Should -Be $OrganizationName
            $updatedTeam.description | Should -BeNullOrEmpty
            $updatedTeam.parent.name | Should -BeNullOrEmpty
            $updatedTeam.created_at | Should -Not -BeNullOrEmpty
            $updatedTeam.updated_at | Should -Not -BeNullOrEmpty
            $updatedTeam.members_count | Should -Be 1
            $updatedTeam.repos_count | Should -Be 0
            $updatedTeam.TeamName | Should -Be $updatedTeam.name
            $updatedTeam.TeamId | Should -Be $updatedTeam.id
            $updatedTeam.OrganizationName | Should -Be $organizationName
        }

        It 'Should find the renamed team' {
            { Get-GitHubTeam -OrganizationName $organizationName -TeamName $newTeamName } |
            Should -Not -Throw
        }

        AfterAll {
            Remove-GitHubTeam -OrganizationName $organizationName -TeamName $newTeamName -Force
        }
    }

    Context 'When renaming a GitHub team with the TeamSlug' {
        BeforeAll {
            $team = New-GitHubTeam -OrganizationName $organizationName -TeamName $teamName
            $updatedTeam = Rename-GitHubTeam -OrganizationName $organizationName -TeamSlug $team.slug -NewTeamName $newTeamName -PassThru
        }

        It 'Should have the expected type and additional properties' {
            $updatedTeam.PSObject.TypeNames[0] | Should -Be 'GitHub.Team'
            $updatedTeam.name | Should -Be $newTeamName
            $updatedTeam.organization.login | Should -Be $OrganizationName
            $updatedTeam.description | Should -BeNullOrEmpty
            $updatedTeam.parent.name | Should -BeNullOrEmpty
            $updatedTeam.created_at | Should -Not -BeNullOrEmpty
            $updatedTeam.updated_at | Should -Not -BeNullOrEmpty
            $updatedTeam.members_count | Should -Be 1
            $updatedTeam.repos_count | Should -Be 0
            $updatedTeam.TeamName | Should -Be $updatedTeam.name
            $updatedTeam.TeamId | Should -Be $updatedTeam.id
            $updatedTeam.OrganizationName | Should -Be $organizationName
        }

        It 'Should find the renamed team' {
            { Get-GitHubTeam -OrganizationName $organizationName -TeamName $newTeamName } |
            Should -Not -Throw
        }

        AfterAll {
            Remove-GitHubTeam -OrganizationName $organizationName -TeamName $newTeamName -Force
        }
    }

    Context 'When renaming a GitHub team with the TeamSlug on the pipeline' {
        BeforeAll {
            $team = New-GitHubTeam -OrganizationName $organizationName -TeamName $teamName
            $updatedTeam = $team | Rename-GitHubTeam -NewTeamName $newTeamName -PassThru
        }

        It 'Should have the expected type and additional properties' {
            $updatedTeam.PSObject.TypeNames[0] | Should -Be 'GitHub.Team'
            $updatedTeam.name | Should -Be $newTeamName
            $updatedTeam.organization.login | Should -Be $OrganizationName
            $updatedTeam.description | Should -BeNullOrEmpty
            $updatedTeam.parent.name | Should -BeNullOrEmpty
            $updatedTeam.created_at | Should -Not -BeNullOrEmpty
            $updatedTeam.updated_at | Should -Not -BeNullOrEmpty
            $updatedTeam.members_count | Should -Be 1
            $updatedTeam.repos_count | Should -Be 0
            $updatedTeam.TeamName | Should -Be $updatedTeam.name
            $updatedTeam.TeamId | Should -Be $updatedTeam.id
            $updatedTeam.OrganizationName | Should -Be $organizationName
        }

        It 'Should find the renamed team' {
            { Get-GitHubTeam -OrganizationName $organizationName -TeamName $newTeamName } |
            Should -Not -Throw
        }

        AfterAll {
            Remove-GitHubTeam -OrganizationName $organizationName -TeamName $newTeamName -Force
        }
    }
}

Describe 'GitHubTeams\Remove-GitHubTeam' {
    BeforeAll {
        $organizationName = $script:organizationName
    }

    Context 'When removing a GitHub team with the TeamName' {
        BeforeAll {
            $teamName = [Guid]::NewGuid().Guid

            $team = New-GitHubTeam -OrganizationName $organizationName -TeamName $teamName
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

    Context 'When removing a GitHub team with the TeamSlug' {
        BeforeAll {
            $teamName = [Guid]::NewGuid().Guid

            $team = New-GitHubTeam -OrganizationName $organizationName -TeamName $teamName
        }

        It 'Should not throw an exception' {
            $removeGitHubTeamParms = @{
                OrganizationName = $organizationName
                TeamSlug = $team.slug
                Confirm = $false
            }

            { Remove-GitHubTeam @RemoveGitHubTeamParms } | Should -Not -Throw
        }

        It 'Should have removed the team' {
            { Get-GitHubTeam -OrganizationName $organizationName -TeamSlug $team.slug } |
            Should -Throw
        }
    }

    Context 'When removing a GitHub team with the TeamSlug on the pipeline' {
        BeforeAll {
            $teamName = [Guid]::NewGuid().Guid

            $team = New-GitHubTeam -OrganizationName $organizationName -TeamName $teamName
        }

        It 'Should not throw an exception' {
            { $team | Remove-GitHubTeam -Force } | Should -Not -Throw
        }

        It 'Should have removed the team' {
            { $team | Get-GitHubTeam } | Should -Throw
        }
    }
}

Describe 'GitHubTeams\Get-GitHubTeamMember' {
    BeforeAll {
        $organizationName = $script:organizationName
        $teamName = [Guid]::NewGuid().Guid
        $team = New-GitHubTeam -OrganizationName $organizationName -TeamName $teamName
    }

    AfterAll {
        $team | Remove-GitHubTeam -Force
    }

    Context 'Getting team members using TeamName' {
        BeforeAll {
            $members = @(Get-GitHubTeamMember -OrganizationName $organizationName -TeamName $teamName)
        }

        It 'Should have the expected type number of members' {
            $members.Count | Should -Be 1
        }

        It 'Should have the expected type and additional properties' {
            $members[0].PSObject.TypeNames[0] | Should -Be 'GitHub.User'
        }
    }

    Context 'Getting team members using TeamSlug' {
        BeforeAll {
            $members = @(Get-GitHubTeamMember -OrganizationName $organizationName -TeamSlug $team.slug)
        }

        It 'Should have the expected type number of members' {
            $members.Count | Should -Be 1
        }

        It 'Should have the expected type and additional properties' {
            $members[0].PSObject.TypeNames[0] | Should -Be 'GitHub.User'
        }
    }

    Context 'Getting team members using TeamSlug on the pipeline' {
        BeforeAll {
            $members = @($team | Get-GitHubTeamMember)
        }

        It 'Should have the expected type number of members' {
            $members.Count | Should -Be 1
        }

        It 'Should have the expected type and additional properties' {
            $members[0].PSObject.TypeNames[0] | Should -Be 'GitHub.User'
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
