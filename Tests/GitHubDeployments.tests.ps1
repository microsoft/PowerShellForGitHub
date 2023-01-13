# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

<#
.Synopsis
   Tests for GitHubDeployments.ps1 module
#>

[CmdletBinding()]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '',
    Justification = 'Suppress false positives in Pester code blocks')]
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
    }
    $repo = New-GitHubRepository @newGitHubRepositoryParms

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

    $reviewerTeam = New-GitHubTeam @newGithubTeamParms
    $reviewerUser = Get-GitHubUser -UserName $script:ownerName

    $repo | Set-GitHubRepositoryTeamPermission -TeamSlug $reviewerTeam.TeamSlug -Permission Push
}

Describe 'GitHubDeployments\New-GitHubDeploymentEnvironment' {
    Context -Name 'When creating a new deployment environment' -Fixture {
        BeforeAll -ScriptBlock {
            $environmentName = 'testenv'
            $waitTimer = 50
            $deploymentBranchPolicy = 'ProtectedBranches'

            $newGitHubDeploymentEnvironmentParms = @{
                EnvironmentName = $environmentName
                WaitTimer = $waitTimer
                DeploymentBranchPolicy = $deploymentBranchPolicy
                ReviewerTeamId = $reviewerTeam.id
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
            (($environment.protection_rules |
                Where-Object -Property type -eq 'required_reviewers').reviewers |
                Where-Object -Property type -eq 'Team').reviewer.name | Should -Be $reviewerTeam.TeamName
            (($environment.protection_rules |
                Where-Object -Property type -eq 'required_reviewers').reviewers |
                Where-Object -Property type -eq 'User').reviewer.login | Should -Be $reviewerUser.UserName
            ($environment.protection_rules |
                Where-Object -Property type -eq 'wait_timer').wait_timer | Should -Be $waitTimer
            $environment.deployment_branch_policy.protected_branches | Should -BeTrue
            $environment.deployment_branch_policy.custom_branch_policies | Should -BeFalse
        }
    }
}

Describe 'GitHubDeployments\Set-GitHubDeploymentEnvironment' {
    Context -Name 'When updating a deployment environment' -Fixture {
        BeforeAll -ScriptBlock {
            $environmentName = 'testenv'
            $waitTimer = 50
            $deploymentBranchPolicy = 'ProtectedBranches'

            $environment = $repo | New-GitHubDeploymentEnvironment -EnvironmentName $environmentName

            $setGitHubDeploymentEnvironmentParms = @{
                EnvironmentName = $environmentName
                WaitTimer = $waitTimer
                DeploymentBranchPolicy = $deploymentBranchPolicy
                ReviewerTeamId = $reviewerTeam.id
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
            (($updatedEnvironment.protection_rules |
                Where-Object -Property type -eq 'required_reviewers').reviewers |
                Where-Object -Property type -eq 'Team').reviewer.name | Should -Be $reviewerTeam.TeamName
            (($updatedEnvironment.protection_rules |
                Where-Object -Property type -eq 'required_reviewers').reviewers |
                Where-Object -Property type -eq 'User').reviewer.login | Should -Be $reviewerUser.UserName
            ($updatedEnvironment.protection_rules |
                Where-Object -Property type -eq 'wait_timer').wait_timer | Should -Be $waitTimer
            $updatedEnvironment.deployment_branch_policy.protected_branches | Should -BeTrue
            $updatedEnvironment.deployment_branch_policy.custom_branch_policies | Should -BeFalse
        }
    }
}

Describe 'GitHubDeployments\Get-GitHubDeploymentEnvironment' {

    Context -Name 'When getting a deployment environment' -Fixture {
        BeforeAll -ScriptBlock {
            $environmentName = 'testenv'
            $waitTimer = 50
            $deploymentBranchPolicy = 'ProtectedBranches'

            $newGitHubDeploymentEnvironmentParms = @{
                EnvironmentName = $environmentName
                WaitTimer = $waitTimer
                DeploymentBranchPolicy = $deploymentBranchPolicy
                ReviewerTeamId = $reviewerTeam.id
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
            (($environment.protection_rules |
                Where-Object -Property type -eq 'required_reviewers').reviewers |
                Where-Object -Property type -eq 'Team').reviewer.name | Should -Be $reviewerTeam.TeamName
            (($environment.protection_rules |
                Where-Object -Property type -eq 'required_reviewers').reviewers |
                Where-Object -Property type -eq 'User').reviewer.login | Should -Be $reviewerUser.UserName
            ($environment.protection_rules |
                Where-Object -Property type -eq 'wait_timer').wait_timer | Should -Be $waitTimer
            $environment.deployment_branch_policy.protected_branches | Should -BeTrue
            $environment.deployment_branch_policy.custom_branch_policies | Should -BeFalse
        }
    }
}

Describe 'GitHubDeployments\Remove-GitHubDeploymentEnvironment' {

    Context -Name 'When removing a deployment environment' -Fixture {
        BeforeAll -ScriptBlock {
            $environmentName = 'testenv'
            $waitTimer = 50
            $deploymentBranchPolicy = 'ProtectedBranches'

            $newGitHubDeploymentEnvironmentParms = @{
                EnvironmentName = $environmentName
                WaitTimer = $waitTimer
                DeploymentBranchPolicy = $deploymentBranchPolicy
                ReviewerTeamId = $reviewerTeam.id
                ReviewerUserId = $reviewerUser.UserId
            }
            $environment = $repo | New-GitHubDeploymentEnvironment @newGitHubDeploymentEnvironmentParms
        }

        It 'Should not throw an exception' {
            { $environment | Remove-GitHubDeploymentEnvironment -Confirm:$false } | Should -Not -Throw
        }

        It 'Should have removed the deployment environment' {
            { $repo | Get-GitHubDeploymentEnvironment -EnvironmentName $environmentName } | Should -Throw
        }
    }
}

AfterAll -ScriptBlock {
    if ($repo)
    {
        $repo | Remove-GitHubRepository -Confirm:$false
    }

    if ($reviewerTeam)
    {
        $reviewerTeam | Remove-GitHubTeam -Confirm:$false
    }
}
