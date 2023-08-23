# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

<#
.Synopsis
   Tests for GitHubDeployments.ps1 module
#>

[CmdletBinding()]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '',
    Justification = 'Suppress false positives in Pester code blocks')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingCmdletAliases', '',
    Justification = 'Using Set-GitHubDeploymentEnvironment the way a user would.')]
param()

Set-StrictMode -Version 1.0

# This is common test code setup logic for all Pester test files
BeforeAll {
    $moduleRootPath = Split-Path -Path $PSScriptRoot -Parent
    . (Join-Path -Path $moduleRootPath -ChildPath 'Tests\Common.ps1')

    $repoName = ([Guid]::NewGuid().Guid)
    $newGitHubRepositoryParms = @{
        RepositoryName = $repoName
        OrganizationName = $script:organizationName
        Private = $false
    }
    $repo = New-GitHubRepository @newGitHubRepositoryParms

    $team1Name = [Guid]::NewGuid().Guid
    $team2Name = [Guid]::NewGuid().Guid
    $description = 'Team Description'
    $privacy = 'closed'
    $maintainerName = $script:ownerName

    $newGithubTeamParms = @{
        OrganizationName = $script:organizationName
        Description = $description
        Privacy = $privacy
        MaintainerName = $MaintainerName
    }

    $reviewerTeam1 = New-GitHubTeam @newGithubTeamParms -TeamName $team1Name
    $reviewerTeam2 = New-GitHubTeam @newGithubTeamParms -TeamName $team2Name
    $reviewerTeamId = $reviewerTeam1.TeamId, $reviewerTeam2.TeamId
    $reviewerUser = Get-GitHubUser -UserName $script:ownerName

    $repo | Set-GitHubRepositoryTeamPermission -TeamSlug $reviewerTeam1.TeamSlug -Permission Push
    $repo | Set-GitHubRepositoryTeamPermission -TeamSlug $reviewerTeam2.TeamSlug -Permission Push
}

Describe 'GitHubDeployments\New-GitHubDeploymentEnvironment' {
    Context -Name 'When creating a new deployment environment' -Fixture {
        BeforeAll -ScriptBlock {
            $environmentName = [Guid]::NewGuid().Guid
            $waitTimer = 50
            $deploymentBranchPolicy = 'ProtectedBranches'

            $newGitHubDeploymentEnvironmentParms = @{
                EnvironmentName = $environmentName
                WaitTimer = $waitTimer
                DeploymentBranchPolicy = $deploymentBranchPolicy
                ReviewerTeamId = $reviewerTeamId
                ReviewerUserId = $reviewerUser.UserId
            }
            $environment = $repo | New-GitHubDeploymentEnvironment @newGitHubDeploymentEnvironmentParms
        }

        It 'Should return an object of the correct type' {
            $environment.PSObject.TypeNames[0] | Should -Be 'GitHub.DeploymentEnvironment'
        }

        It 'Should return the correct properties' {
            $environment.name | Should -Be $environmentName
            $environment.RepositoryUrl | Should -Be $repo.RepositoryUrl
            $environment.EnvironmentName | Should -Be $environmentName
            $environment.ReviewerUser[0].UserName | Should -Be $reviewerUser.UserName
            $environment.ReviewerUser[0].UserId | Should -Be $reviewerUser.UserId
            $environment.ReviewerTeam.count | Should -Be $reviewerTeamId.count
            $environment.ReviewerTeam[0].TeamName | Should -Be $reviewerTeam1.TeamName
            $environment.ReviewerTeam[0].TeamId | Should -Be $reviewerTeam1.TeamId
            $environment.ReviewerTeam[1].TeamName | Should -Be $reviewerTeam2.TeamName
            $environment.ReviewerTeam[1].TeamId | Should -Be $reviewerTeam2.TeamId
            $environment.WaitTimer | Should -Be $waitTimer
            $environment.DeploymentBranchPolicy | Should -Be $deploymentBranchPolicy
        }
    }
}

Describe 'GitHubDeployments\Set-GitHubDeploymentEnvironment' {
    Context -Name 'When updating a deployment environment' -Fixture {
        BeforeAll -ScriptBlock {
            $environmentName = [Guid]::NewGuid().Guid
            $waitTimer = 50
            $deploymentBranchPolicy = 'ProtectedBranches'

            $environment = $repo | New-GitHubDeploymentEnvironment -EnvironmentName $environmentName

            $setGitHubDeploymentEnvironmentParms = @{
                EnvironmentName = $environmentName
                WaitTimer = $waitTimer
                DeploymentBranchPolicy = $deploymentBranchPolicy
                ReviewerTeamId = $reviewerTeam1.TeamId, $reviewerTeam2.TeamId
                ReviewerUserId = $reviewerUser.UserId
                PassThru = $true
            }
            $updatedEnvironment = $environment | Set-GitHubDeploymentEnvironment @setGitHubDeploymentEnvironmentParms
        }

        It 'Should return an object of the correct type' {
            $updatedEnvironment.PSObject.TypeNames[0] | Should -Be 'GitHub.DeploymentEnvironment'
        }

        It 'Should return the correct properties' {
            $updatedEnvironment.name | Should -Be $environmentName
            $updatedEnvironment.RepositoryUrl | Should -Be $repo.RepositoryUrl
            $updatedEnvironment.EnvironmentName | Should -Be $environmentName
            $updatedenvironment.ReviewerUser[0].UserName | Should -Be $reviewerUser.UserName
            $updatedenvironment.ReviewerUser[0].UserId | Should -Be $reviewerUser.UserId
            $updatedenvironment.ReviewerTeam.count | Should -Be $reviewerTeamId.count
            $updatedenvironment.ReviewerTeam[0].TeamName | Should -Be $reviewerTeam1.TeamName
            $updatedenvironment.ReviewerTeam[0].TeamId | Should -Be $reviewerTeam1.TeamId
            $updatedenvironment.ReviewerTeam[1].TeamName | Should -Be $reviewerTeam2.TeamName
            $updatedenvironment.ReviewerTeam[1].TeamId | Should -Be $reviewerTeam2.TeamId
            $updatedenvironment.WaitTimer | Should -Be $waitTimer
            $updatedenvironment.DeploymentBranchPolicy | Should -Be $deploymentBranchPolicy
        }
    }
}

Describe 'GitHubDeployments\Get-GitHubDeploymentEnvironment' {

    Context -Name 'When getting a deployment environment' -Fixture {
        BeforeAll -ScriptBlock {
            $environmentName = [Guid]::NewGuid().Guid
            $waitTimer = 50
            $deploymentBranchPolicy = 'ProtectedBranches'

            $newGitHubDeploymentEnvironmentParms = @{
                EnvironmentName = $environmentName
                WaitTimer = $waitTimer
                DeploymentBranchPolicy = $deploymentBranchPolicy
                ReviewerTeamId = $reviewerTeamId
                ReviewerUserId = $reviewerUser.UserId
            }
            $repo | New-GitHubDeploymentEnvironment @newGitHubDeploymentEnvironmentParms | Out-Null

            $environment = $repo | Get-GitHubDeploymentEnvironment -EnvironmentName $environmentName
        }

        It 'Should return an object of the correct type' {
            $environment.PSObject.TypeNames[0] | Should -Be 'GitHub.DeploymentEnvironment'
        }

        It 'Should return the correct properties' {
            $environment.name | Should -Be $environmentName
            $environment.RepositoryUrl | Should -Be $repo.RepositoryUrl
            $environment.EnvironmentName | Should -Be $environmentName
            $environment.ReviewerUser[0].UserName | Should -Be $reviewerUser.UserName
            $environment.ReviewerUser[0].UserId | Should -Be $reviewerUser.UserId
            $environment.ReviewerTeam.count | Should -Be $reviewerTeamId.count
            $environment.ReviewerTeam[0].TeamName | Should -Be $reviewerTeam1.TeamName
            $environment.ReviewerTeam[0].TeamId | Should -Be $reviewerTeam1.TeamId
            $environment.ReviewerTeam[1].TeamName | Should -Be $reviewerTeam2.TeamName
            $environment.ReviewerTeam[1].TeamId | Should -Be $reviewerTeam2.TeamId
            $environment.WaitTimer | Should -Be $waitTimer
            $environment.DeploymentBranchPolicy | Should -Be $deploymentBranchPolicy
        }
    }
}

Describe 'GitHubDeployments\Remove-GitHubDeploymentEnvironment' {

    Context -Name 'When removing a deployment environment' -Fixture {
        BeforeAll -ScriptBlock {
            $environmentName = [Guid]::NewGuid().Guid
            $waitTimer = 50
            $deploymentBranchPolicy = 'ProtectedBranches'

            $newGitHubDeploymentEnvironmentParms = @{
                EnvironmentName = $environmentName
                WaitTimer = $waitTimer
                DeploymentBranchPolicy = $deploymentBranchPolicy
                ReviewerTeamId = $reviewerTeam1.id
                ReviewerUserId = $reviewerUser.UserId
            }
            $environment = $repo | New-GitHubDeploymentEnvironment @newGitHubDeploymentEnvironmentParms
        }

        It 'Should not throw an exception' {
            { $environment | Remove-GitHubDeploymentEnvironment -Confirm:$false } | Should -Not -Throw
        }

        It 'Should have removed the deployment environment' {
            { $repo | Get-GitHubDeploymentEnvironment -EnvironmentName $environmentName } | `
                Should -Throw '*Not Found*'
        }
    }
}

AfterAll -ScriptBlock {
    if ($repo)
    {
        $repo | Remove-GitHubRepository -Confirm:$false
    }

    if ($reviewerTeam1)
    {
        $reviewerTeam1 | Remove-GitHubTeam -Confirm:$false
    }

    if ($reviewerTeam2)
    {
        $reviewerTeam2 | Remove-GitHubTeam -Confirm:$false
    }
}
