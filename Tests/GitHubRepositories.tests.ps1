# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

<#
.Synopsis
   Tests for GitHubRepositories.ps1 module
#>

[CmdletBinding()]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '',
    Justification = 'Suppress false positives in Pester code blocks')]
param()

# This is common test code setup logic for all Pester test files
BeforeAll {
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

Describe 'GitHubRepositories\New-GitHubRepository' {

    Context -Name 'When creating a repository for the authenticated user' -Fixture {

        Context -Name 'When creating a public repository with default settings' -Fixture {
            BeforeAll -ScriptBlock {
                $repoName = ([Guid]::NewGuid().Guid)
                $newGitHubRepositoryParms = @{
                    RepositoryName = $repoName
                }
                $repo = New-GitHubRepository @newGitHubRepositoryParms
            }

            It 'Should return an object of the correct type' {
                $repo | Should -BeOfType PSCustomObject
            }

            It 'Should return the correct properties' {
                $repo.name | Should -Be $repoName
                $repo.private | Should -BeFalse
                $repo.description | Should -BeNullOrEmpty
                $repo.homepage | Should -BeNullOrEmpty
                $repo.has_issues | Should -BeTrue
                $repo.has_projects | Should -BeTrue
                $repo.has_Wiki | Should -BeTrue
                $repo.has_discussions | Should -BeFalse
                $repo.allow_squash_merge | Should -BeTrue
                $repo.allow_merge_commit | Should -BeTrue
                $repo.allow_rebase_merge | Should -BeTrue
                $repo.delete_branch_on_merge | Should -BeFalse
                $repo.is_template | Should -BeFalse
            }

            AfterAll -ScriptBlock {
                if ($repo)
                {
                    Remove-GitHubRepository -Uri $repo.svn_url -Confirm:$false
                }
            }
        }

        Context -Name 'When creating a private repository with default settings' -Fixture {
            BeforeAll -ScriptBlock {
                $repoName = ([Guid]::NewGuid().Guid)
                $newGitHubRepositoryParms = @{
                    RepositoryName = $repoName
                    Private = $true
                }
                $repo = New-GitHubRepository @newGitHubRepositoryParms
            }

            It 'Should return an object of the correct type' {
                $repo | Should -BeOfType PSCustomObject
            }

            It 'Should return the correct properties' {
                $repo.name | Should -Be $repoName
                $repo.private | Should -BeTrue
                $repo.description | Should -BeNullOrEmpty
                $repo.homepage | Should -BeNullOrEmpty
                $repo.has_issues | Should -BeTrue
                $repo.has_projects | Should -BeTrue
                $repo.has_discussions | Should -BeFalse
                $repo.allow_squash_merge | Should -BeTrue
                $repo.allow_merge_commit | Should -BeTrue
                $repo.allow_rebase_merge | Should -BeTrue
                $repo.delete_branch_on_merge | Should -BeFalse
                $repo.is_template | Should -BeFalse
            }

            AfterAll -ScriptBlock {
                if ($repo)
                {
                    Remove-GitHubRepository -Uri $repo.svn_url -Confirm:$false
                }
            }
        }

        Context -Name 'When creating a public repository with all possible settings' -Fixture {
            BeforeAll -ScriptBlock {
                $repoName = ([Guid]::NewGuid().Guid)
                $testGitIgnoreTemplate = (Get-GitHubGitIgnore)[0]
                $testLicenseTemplate = (Get-GitHubLicense)[0].key

                $newGitHubRepositoryParms = @{
                    RepositoryName = $repoName
                    Description = $defaultRepoDesc
                    HomePage = $defaultRepoHomePage
                    NoIssues = $true
                    NoProjects = $true
                    NoWiki = $true
                    HasDiscussions = $true
                    DisallowSquashMerge = $true
                    DisallowMergeCommit = $true
                    DisallowRebaseMerge = $false
                    AllowAutoMerge = $true
                    AllowUpdateBranch = $true
                    DeleteBranchOnMerge = $true
                    GitIgnoreTemplate = $testGitIgnoreTemplate
                    LicenseTemplate = $testLicenseTemplate
                    IsTemplate = $true
                }

                $repo = New-GitHubRepository @newGitHubRepositoryParms
            }

            It 'Should return an object of the correct type' {
                $repo | Should -BeOfType PSCustomObject
            }

            It 'Should return the correct properties' {
                $repo.name | Should -Be $repoName
                $repo.description | Should -Be $defaultRepoDesc
                $repo.homepage | Should -Be $defaultRepoHomePage
                $repo.has_issues | Should -BeFalse
                $repo.has_projects | Should -BeFalse
                $repo.has_Wiki | Should -BeFalse
                $repo.has_discussions | Should -BeTrue
                $repo.allow_squash_merge | Should -BeFalse
                $repo.allow_merge_commit | Should -BeFalse
                $repo.allow_rebase_merge | Should -BeTrue
                $repo.allow_auto_merge | Should -BeTrue
                $repo.allow_update_branch | Should -BeTrue
                $repo.delete_branch_on_merge | Should -BeTrue
                $repo.is_template | Should -BeTrue
            }

            It 'Should have created a .gitignore file' {
                { Get-GitHubContent -Uri $repo.svn_url -Path '.gitignore' } | Should -Not -Throw
            }

            It 'Should have created a LICENSE file' {
                { Get-GitHubContent -Uri $repo.svn_url -Path 'LICENSE' } | Should -Not -Throw
            }

            AfterAll -ScriptBlock {
                if ($repo)
                {
                    Remove-GitHubRepository -Uri $repo.svn_url -Confirm:$false
                }
            }
        }

        Context -Name 'When creating a public repository with alternative Merge settings' -Fixture {
            BeforeAll -ScriptBlock {
                $repoName = ([Guid]::NewGuid().Guid)
                $newGitHubRepositoryParms = @{
                    RepositoryName = $repoName
                    DisallowSquashMerge = $true
                    DisallowMergeCommit = $false
                    DisallowRebaseMerge = $true
                    AllowAutoMerge = $false
                }
                $repo = New-GitHubRepository @newGitHubRepositoryParms
            }

            It 'Should return an object of the correct type' {
                $repo | Should -BeOfType PSCustomObject
            }

            It 'Should return the correct properties' {
                $repo.name | Should -Be $repoName
                $repo.allow_squash_merge | Should -BeFalse
                $repo.allow_merge_commit | Should -BeTrue
                $repo.allow_rebase_merge | Should -BeFalse
                $repo.allow_auto_merge | Should -BeFalse
            }

            AfterAll -ScriptBlock {
                if ($repo)
                {
                    Remove-GitHubRepository -Uri $repo.svn_url -Confirm:$false
                }
            }
        }

        Context -Name 'When creating a repository with Squash Merge Commit PR Title' {
            BeforeAll -ScriptBlock {
                $repoName = ([Guid]::NewGuid().Guid)
                $newGithubRepositoryParms = @{
                    RepositoryName = $repoName
                    DisallowSquashMerge = $false
                    SquashMergeCommitTitle = 'PRTitle'
                    SquashMergeCommitMessage = 'Blank'
                }

                $repo = New-GitHubRepository @newGithubRepositoryParms
            }

            It 'Should return an object of the correct type' {
                $repo | Should -BeOfType PSCustomObject
            }

            It 'Should return the correct properties' {
                $repo.name | Should -Be $repoName
                $repo.allow_squash_merge | Should -BeTrue
                $repo.squash_merge_commit_title | Should -Be 'PR_TITLE'
                $repo.squash_merge_commit_message | Should -Be 'BLANK'
            }

            AfterAll -ScriptBlock {
                if ($repo)
                {
                    Remove-GitHubRepository -Uri $repo.svn_url -Confirm:$false
                }
            }
        }

        Context -Name 'When creating a repository with Squash Merge Commit PR Title and Commit details' {
            BeforeAll -ScriptBlock {
                $repoName = ([Guid]::NewGuid().Guid)
                $newGithubRepositoryParms = @{
                    RepositoryName = $repoName
                    DisallowSquashMerge = $false
                    SquashMergeCommitTitle = 'PRTitle'
                    SquashMergeCommitMessage = 'CommitMessages'
                }

                $repo = New-GitHubRepository @newGithubRepositoryParms
            }

            It 'Should return an object of the correct type' {
                $repo | Should -BeOfType PSCustomObject
            }

            It 'Should return the correct properties' {
                $repo.name | Should -Be $repoName
                $repo.allow_squash_merge | Should -BeTrue
                $repo.squash_merge_commit_title | Should -Be 'PR_TITLE'
                $repo.squash_merge_commit_message | Should -Be 'COMMIT_MESSAGES'
            }

            AfterAll -ScriptBlock {
                if ($repo)
                {
                    Remove-GitHubRepository -Uri $repo.svn_url -Confirm:$false
                }
            }
        }

        Context -Name 'When creating a repository with Squash Merge Commit PR Title and Description' {
            BeforeAll -ScriptBlock {
                $repoName = ([Guid]::NewGuid().Guid)
                $newGithubRepositoryParms = @{
                    RepositoryName = $repoName
                    DisallowSquashMerge = $false
                    SquashMergeCommitTitle = 'PRTitle'
                    SquashMergeCommitMessage = 'PRBody'
                }

                $repo = New-GitHubRepository @newGithubRepositoryParms
            }

            It 'Should return an object of the correct type' {
                $repo | Should -BeOfType PSCustomObject
            }

            It 'Should return the correct properties' {
                $repo.name | Should -Be $repoName
                $repo.allow_squash_merge | Should -BeTrue
                $repo.squash_merge_commit_title | Should -Be 'PR_TITLE'
                $repo.squash_merge_commit_message | Should -Be 'PR_BODY'
            }

            AfterAll -ScriptBlock {
                if ($repo)
                {
                    Remove-GitHubRepository -Uri $repo.svn_url -Confirm:$false
                }
            }
        }

        Context -Name 'When creating a repository with Squash Merge Commit default message' {
            BeforeAll -ScriptBlock {
                $repoName = ([Guid]::NewGuid().Guid)
                $newGithubRepositoryParms = @{
                    RepositoryName = $repoName
                    DisallowSquashMerge = $false
                    SquashMergeCommitTitle = 'CommitOrPRTitle'
                    SquashMergeCommitMessage = 'CommitMessages'
                }

                $repo = New-GitHubRepository @newGithubRepositoryParms
            }

            It 'Should return an object of the correct type' {
                $repo | Should -BeOfType PSCustomObject
            }

            It 'Should return the correct properties' {
                $repo.name | Should -Be $repoName
                $repo.allow_squash_merge | Should -BeTrue
                $repo.squash_merge_commit_title | Should -Be 'COMMIT_OR_PR_TITLE'
                $repo.squash_merge_commit_message | Should -Be 'COMMIT_MESSAGES'
            }

            AfterAll -ScriptBlock {
                if ($repo)
                {
                    Remove-GitHubRepository -Uri $repo.svn_url -Confirm:$false
                }
            }
        }

        Context -Name 'When creating a repository with Merge Commit PR Title' {
            BeforeAll -ScriptBlock {
                $repoName = ([Guid]::NewGuid().Guid)
                $newGithubRepositoryParms = @{
                    RepositoryName = $repoName
                    DisallowMergeCommit = $false
                    MergeCommitTitle = 'PRTitle'
                    MergeCommitMessage = 'Blank'
                }

                $repo = New-GitHubRepository @newGithubRepositoryParms
            }

            It 'Should return an object of the correct type' {
                $repo | Should -BeOfType PSCustomObject
            }

            It 'Should return the correct properties' {
                $repo.name | Should -Be $repoName
                $repo.allow_merge_commit | Should -BeTrue
                $repo.merge_commit_title | Should -Be 'PR_TITLE'
                $repo.merge_commit_message | Should -Be 'BLANK'
            }

            AfterAll -ScriptBlock {
                if ($repo)
                {
                    Remove-GitHubRepository -Uri $repo.svn_url -Confirm:$false
                }
            }
        }

        Context -Name 'When creating a repository with Merge Commit PR Title and Description' {
            BeforeAll -ScriptBlock {
                $repoName = ([Guid]::NewGuid().Guid)
                $newGithubRepositoryParms = @{
                    RepositoryName = $repoName
                    DisallowMergeCommit = $false
                    MergeCommitTitle = 'PRTitle'
                    MergeCommitMessage = 'PRBody'
                }

                $repo = New-GitHubRepository @newGithubRepositoryParms
            }

            It 'Should return an object of the correct type' {
                $repo | Should -BeOfType PSCustomObject
            }

            It 'Should return the correct properties' {
                $repo.name | Should -Be $repoName
                $repo.allow_merge_commit | Should -BeTrue
                $repo.merge_commit_title | Should -Be 'PR_TITLE'
                $repo.merge_commit_message | Should -Be 'PR_BODY'
            }

            AfterAll -ScriptBlock {
                if ($repo)
                {
                    Remove-GitHubRepository -Uri $repo.svn_url -Confirm:$false
                }
            }
        }

        Context -Name 'When creating a repository with Merge Commit default message' {
            BeforeAll -ScriptBlock {
                $repoName = ([Guid]::NewGuid().Guid)
                $newGithubRepositoryParms = @{
                    RepositoryName = $repoName
                    DisallowMergeCommit = $false
                    MergeCommitTitle = 'MergeMessage'
                    MergeCommitMessage = 'PRTitle'
                }

                $repo = New-GitHubRepository @newGithubRepositoryParms
            }

            It 'Should return an object of the correct type' {
                $repo | Should -BeOfType PSCustomObject
            }

            It 'Should return the correct properties' {
                $repo.name | Should -Be $repoName
                $repo.allow_merge_commit | Should -BeTrue
                $repo.merge_commit_title | Should -Be 'MERGE_MESSAGE'
                $repo.merge_commit_message | Should -Be 'PR_TITLE'
            }

            AfterAll -ScriptBlock {
                if ($repo)
                {
                    Remove-GitHubRepository -Uri $repo.svn_url -Confirm:$false
                }
            }
        }

        Context -Name 'When a TeamID is specified' -Fixture {
            BeforeAll -ScriptBlock {
                $repoName = ([Guid]::NewGuid().Guid)
                $mockTeamID = 1
                $newGitHubRepositoryParms = @{
                    RepositoryName = $repoName
                    TeamID = $mockTeamID
                }
            }

            It 'Should throw the correct exception' {
                $errorMessage = 'TeamId may only be specified when creating a repository under an organization.'
                { New-GitHubRepository @newGitHubRepositoryParms } | Should -Throw $errorMessage
            }
        }
    }

    Context -Name 'When creating an organization repository' -Fixture {

        Context -Name 'When creating a public repository with default settings' -Fixture {
            BeforeAll -ScriptBlock {
                $repoName = ([Guid]::NewGuid().Guid)
                $newGitHubRepositoryParms = @{
                    RepositoryName = $repoName
                    OrganizationName = $script:organizationName
                }
                $repo = New-GitHubRepository @newGitHubRepositoryParms
            }

            It 'Should return an object of the correct type' {
                $repo | Should -BeOfType PSCustomObject
            }

            It 'Should return the correct properties' {
                $repo.name | Should -Be $repoName
                $repo.private | Should -BeFalse
                $repo.organization.login | Should -Be $script:organizationName
                $repo.description | Should -BeNullOrEmpty
                $repo.homepage | Should -BeNullOrEmpty
                $repo.has_issues | Should -BeTrue
                $repo.has_projects | Should -BeTrue
                $repo.has_Wiki | Should -BeTrue
                $repo.has_discussions | Should -BeFalse
                $repo.allow_squash_merge | Should -BeTrue
                $repo.allow_merge_commit | Should -BeTrue
                $repo.allow_rebase_merge | Should -BeTrue
                $repo.delete_branch_on_merge | Should -BeFalse
                $repo.is_template | Should -BeFalse
            }

            AfterAll -ScriptBlock {
                if ($repo)
                {
                    Remove-GitHubRepository -Uri $repo.svn_url -Confirm:$false
                }
            }
        }

        Context -Name 'When creating a private repository with default settings' -Fixture {
            BeforeAll -ScriptBlock {
                $repoName = ([Guid]::NewGuid().Guid)
                $newGitHubRepositoryParms = @{
                    RepositoryName = $repoName
                    Private = $true
                    OrganizationName = $script:organizationName
                }
                $repo = New-GitHubRepository @newGitHubRepositoryParms
            }

            It 'Should return an object of the correct type' {
                $repo | Should -BeOfType PSCustomObject
            }

            It 'Should return the correct properties' {
                $repo.name | Should -Be $repoName
                $repo.private | Should -BeTrue
                $repo.organization.login | Should -Be $script:organizationName
                $repo.description | Should -BeNullOrEmpty
                $repo.homepage | Should -BeNullOrEmpty
                $repo.has_issues | Should -BeTrue
                $repo.has_projects | Should -BeTrue
                $repo.allow_squash_merge | Should -BeTrue
                $repo.allow_merge_commit | Should -BeTrue
                $repo.allow_rebase_merge | Should -BeTrue
                $repo.delete_branch_on_merge | Should -BeFalse
                $repo.is_template | Should -BeFalse
            }

            AfterAll -ScriptBlock {
                if ($repo)
                {
                    Remove-GitHubRepository -Uri $repo.svn_url -Confirm:$false
                }
            }
        }
    }
}

Describe 'GitHubRepositories\New-GitHubRepositoryFromTemplate' {
    BeforeAll {
        $templateRepoName = ([Guid]::NewGuid().Guid)
        $ownerName = $script:ownerName
        $testGitIgnoreTemplate = (Get-GitHubGitIgnore)[0]
        $testLicenseTemplate = (Get-GitHubLicense)[0].key

        $newGitHubRepositoryParms = @{
            RepositoryName = $templateRepoName
            Description = $defaultRepoDesc
            GitIgnoreTemplate = $testGitIgnoreTemplate
            LicenseTemplate = $testLicenseTemplate
            IsTemplate = $true
        }

        $templateRepo = New-GitHubRepository @newGitHubRepositoryParms
    }

    Context 'When creating a public repository from a template' {
        BeforeAll {
            $repoName = ([Guid]::NewGuid().Guid)
            $newRepoDesc = 'New Repo Description'
            $newGitHubRepositoryFromTemplateParms = @{
                RepositoryName = $templateRepoName
                OwnerName = $templateRepo.owner.login
                TargetOwnerName = $ownerName
                TargetRepositoryName = $repoName
                Description = $newRepoDesc
            }

            $repo = New-GitHubRepositoryFromTemplate @newGitHubRepositoryFromTemplateParms
        }

        It 'Should have the expected type and addititional properties' {
            $repo.PSObject.TypeNames[0] | Should -Be 'GitHub.Repository'
            $repo.name | Should -Be $repoName
            $repo.private | Should -BeFalse
            $repo.owner.login | Should -Be $script:ownerName
            $repo.description | Should -Be $newRepoDesc
            $repo.is_template | Should -BeFalse
            $repo.RepositoryId | Should -Be $repo.id
            $repo.RepositoryUrl | Should -Be $repo.html_url
        }

        It 'Should have created a .gitignore file' {
            { Get-GitHubContent -Uri $repo.svn_url -Path '.gitignore' } | Should -Not -Throw
        }

        It 'Should have created a LICENSE file' {
            { Get-GitHubContent -Uri $repo.svn_url -Path 'LICENSE' } | Should -Not -Throw
        }

        AfterAll {
            if (Get-Variable -Name repo -ErrorAction SilentlyContinue)
            {
                Remove-GitHubRepository -Uri $repo.svn_url -Confirm:$false
            }
        }
    }

    Context 'When creating a public repository from a template (via pipeline input)' {
        BeforeAll {
            $repoName = ([Guid]::NewGuid().Guid)
            $newRepoDesc = 'New Repo Description'
            $newGitHubRepositoryFromTemplateParms = @{
                TargetOwnerName = $ownerName
                TargetRepositoryName = $repoName
                Description = $newRepoDesc
            }

            $repo = $templateRepo | New-GitHubRepositoryFromTemplate @newGitHubRepositoryFromTemplateParms
        }

        It 'Should have the expected type and addititional properties' {
            $repo.PSObject.TypeNames[0] | Should -Be 'GitHub.Repository'
            $repo.name | Should -Be $repoName
            $repo.private | Should -BeFalse
            $repo.owner.login | Should -Be $script:ownerName
            $repo.description | Should -Be $newRepoDesc
            $repo.is_template | Should -BeFalse
            $repo.RepositoryId | Should -Be $repo.id
            $repo.RepositoryUrl | Should -Be $repo.html_url
        }

        It 'Should have created a .gitignore file' {
            { Get-GitHubContent -Uri $repo.svn_url -Path '.gitignore' } | Should -Not -Throw
        }

        It 'Should have created a LICENSE file' {
            { Get-GitHubContent -Uri $repo.svn_url -Path 'LICENSE' } | Should -Not -Throw
        }

        AfterAll {
            if (Get-Variable -Name repo -ErrorAction SilentlyContinue)
            {
                Remove-GitHubRepository -Uri $repo.svn_url -Confirm:$false
            }
        }
    }

    AfterAll {
        if (Get-Variable -Name templateRepo -ErrorAction SilentlyContinue)
        {
            Remove-GitHubRepository -Uri $templateRepo.svn_url -Confirm:$false
        }
    }
}

Describe 'GitHubRepositories\Get-GitHubRepository' {
    Context 'When getting a repository for the authenticated user' {
        BeforeAll {
            $publicRepo = New-GitHubRepository -RepositoryName ([Guid]::NewGuid().Guid)
            $privateRepo = New-GitHubRepository -RepositoryName ([Guid]::NewGuid().Guid) -Private
        }

        Context 'When specify the visibility parameter' {
            BeforeAll {
                $publicRepos = Get-GitHubRepository -Visibility Public
                $privateRepos = Get-GitHubRepository -Visibility Private
            }

            It 'Should return objects of the correct type' {
                $publicRepos[0].PSObject.TypeNames[0] | Should -Be 'GitHub.Repository'
                $privateRepos[0].PSObject.TypeNames[0] | Should -Be 'GitHub.Repository'
            }

            It "Should return the correct membership" {
                $publicRepo.name | Should -BeIn $publicRepos.name
                $publicRepo.name | Should -Not -BeIn $privateRepos.name
                $privateRepo.name | Should -BeIn $privateRepos.name
                $privateRepo.name | Should -Not -BeIn $publicRepos.name
            }
        }

        Context 'When specifying the Type parameter' {
            BeforeAll {
                $publicRepos = Get-GitHubRepository -Type Public
                $privateRepos = Get-GitHubRepository -Type Private
                $ownerRepos = Get-GitHubRepository -Type Owner
                $allRepos = Get-GitHubRepository -Type All
            }

            It 'Should return objects of the correct type' {
                $publicRepos[0].PSObject.TypeNames[0] | Should -Be 'GitHub.Repository'
                $publicRepos[0].PSObject.TypeNames[0] | Should -Be 'GitHub.Repository'
                $ownerRepos[0].PSObject.TypeNames[0] | Should -Be 'GitHub.Repository'
            }

            It "Should return the correct membership" {
                $publicRepo.name | Should -BeIn $publicRepos.name
                $publicRepo.name | Should -Not -BeIn $privateRepos.name
                $privateRepo.name | Should -BeIn $privateRepos.name
                $privateRepo.name | Should -Not -BeIn $publicRepos.name
                $publicRepo.name | Should -BeIn $ownerRepos.name
                $privateRepo.name | Should -BeIn $ownerRepos.name
                $publicRepo.name | Should -BeIn $allRepos.name
                $privateRepo.name | Should -BeIn $allRepos.name
            }
        }

        Context 'When specifying the Affiliation parameter' {
            BeforeAll {
                $ownerRepos = Get-GitHubRepository -Affiliation Owner, Collaborator
            }

            It 'Should return objects of the correct type' {
                $ownerRepos[0].PSObject.TypeNames[0] | Should -Be 'GitHub.Repository'
            }

            It "Should return the correct membership" {
                $publicRepo.name | Should -BeIn $ownerRepos.name
                $privateRepo.name | Should -BeIn $ownerRepos.name
            }
        }

        Context 'When specifying the Sort and Direction parameters' {
            BeforeAll {
                $sortedRepos = Get-GitHubRepository -Sort 'FullName'
                $sortedDescendingRepos = Get-GitHubRepository -Sort FullName -Direction Descending

                $sortedRepoFullNames = [System.Collections.ArrayList]$sortedRepos.full_Name
                $sortedRepoFullNames.Sort([System.StringComparer]::OrdinalIgnoreCase)
                $sortedDescendingRepoFullNames = [System.Collections.ArrayList]$sortedDescendingRepos.full_Name
                $sortedDescendingRepoFullNames.Sort([System.StringComparer]::OrdinalIgnoreCase)
                $sortedDescendingRepoFullNames.Reverse()
            }

            It 'Should return objects of the correct type' {
                $sortedRepos[0].PSObject.TypeNames[0] | Should -Be 'GitHub.Repository'
                $sortedDescendingRepos[0].PSObject.TypeNames[0] | Should -Be 'GitHub.Repository'
            }

            It "Should return the correct membership order" {
                for ($i = 1; $i -le $sortedRepos.count; $i++)
                {
                    $sortedRepos[$i].full_name | Should -Be $sortedRepoFullNames[$i]
                    $sortedDescendingRepos[$i].full_name | Should -Be $sortedDescendingRepoFullNames[$i]
                }
            }
        }

        Context 'When Specifying an invalid Visibility parameter set' {
            It 'Should throw the correct exception' {
                $errorMessage = 'Unable to specify -Type when using -Visibility and/or -Affiliation.'
                { Get-GitHubRepository -Type All -Visibility All } | Should -Throw $errorMessage
            }
        }

        Context 'When Specifying an invalid Affiliation parameter set' {
            It 'Should throw the correct exception' {
                $errorMessage = 'Unable to specify -Type when using -Visibility and/or -Affiliation.'
                { Get-GitHubRepository -Type All -Visibility All } | Should -Throw $errorMessage
            }
        }

        AfterAll {
            Remove-GitHubRepository -Uri $publicRepo.svn_url -Force
            Remove-GitHubRepository -Uri $privateRepo.svn_url -Force
        }
    }

    Context 'When getting a repository for a specified owner' {
        BeforeAll {
            $ownerName = 'octocat'
            $repos = Get-GitHubRepository -OwnerName $ownerName
        }

        It 'Should return objects of the correct type' {
            $repos | Should -BeOfType PSCustomObject
        }

        It "Should return one or more results" {
            $repos.Count | Should -BeGreaterOrEqual 1
        }

        It 'Should return the correct properties' {
            foreach ($repo in $repos)
            {
                $repo.owner.login | Should -Be $ownerName
            }
        }
    }

    Context 'When getting a repository for a specified organization' {
        BeforeAll {
            $repo = New-GitHubRepository -OrganizationName $script:organizationName -RepositoryName ([Guid]::NewGuid().Guid)
        }

        It "Should have results for the organization" {
            $repos = Get-GitHubRepository -OrganizationName $script:organizationName -Type All
            $repo.name | Should -BeIn $repos.name
        }

        AfterAll {
            Remove-GitHubRepository -Uri $repo.svn_url -Confirm:$false
        }
    }

    Context 'When getting all public repositories' {
        BeforeAll {
            $repo1 = New-GitHubRepository -RepositoryName ([Guid]::NewGuid().Guid)
            $repo2 = New-GitHubRepository -RepositoryName ([Guid]::NewGuid().Guid)
            $repos = Get-GitHubRepository -GetAllPublicRepositories -Since $repo1.id
        }

        It 'Should return an object of the correct type' {
            $repos[0].PSObject.TypeNames[0] | Should -Be 'GitHub.Repository'
        }

        It 'Should return at least one result' {
            $repos.count | Should -BeGreaterOrEqual 1
        }

        It "Should return the correct membership" {
            $repo2.name | Should -BeIn $repos.name
        }

        AfterAll {
            Remove-GitHubRepository -Uri $repo1.svn_url -Force
            Remove-GitHubRepository -Uri $repo2.svn_url -Force
        }
    }

    Context 'When getting a specific repository' {
        BeforeAll {
            $repoName = [Guid]::NewGuid().Guid
            $newGitHubRepositoryParms = @{
                RepositoryName = $repoName
                Description = $defaultRepoDesc
                HomePage = $defaultRepoHomePage
            }

            $repo = New-GitHubRepository @newGitHubRepositoryParms
        }

        Context 'When specifiying the Uri parameter' {
            BeforeAll {
                $uriRepo = Get-GitHubRepository -Uri $repo.svn_url
            }

            It 'Should return an object of the correct type' {
                $uriRepo.PSObject.TypeNames[0] | Should -Be 'GitHub.Repository'
            }

            It 'Should return a single result' {
                $uriRepo | Should -HaveCount 1
            }

            It 'Should return the correct properties' {
                $uriRepo.name | Should -Be $repoName
                $uriRepo.description | Should -Be $defaultRepoDesc
                $uriRepo.homepage | Should -Be $defaultRepoHomePage
            }
        }

        Context 'When specifying the Owner and RepositoryName parameters' {
            BeforeAll {
                $uriRepo = Get-GitHubRepository -Uri $repo.svn_url
                $elementsRepo = Get-GitHubRepository -OwnerName $repo.owner.login -RepositoryName $repo.name
            }

            It 'Should return an object of the correct type' {
                $uriRepo.PSObject.TypeNames[0] | Should -Be 'GitHub.Repository'
            }

            It 'Should return a single result' {
                $uriRepo | Should -HaveCount 1
            }

            It 'Should return the correct properties' {
                $uriRepo.name | Should -Be $repoName
                $uriRepo.description | Should -Be $defaultRepoDesc
                $uriRepo.homepage | Should -Be $defaultRepoHomePage
            }

            Context 'When specifying additional invalid parameters' {
                It 'Should throw the correct exception' {
                    $errorMessage = 'Unable to specify -Type, -Sort and/or -Direction when retrieving a specific repository.'
                    { Get-GitHubRepository -OwnerName $repo.owner.login -RepositoryName $repo.name -Type All } |
                    Should -Throw $errorMessage
                }
            }
        }

        Context 'When specifying only the Repository parameter' {
            It 'Should throw the correct exception' {
                $errorMessage = 'OwnerName could not be determined.'
                { Get-GitHubRepository -RepositoryName $repo.name } | Should -Throw $errorMessage
            }
        }

        AfterAll {
            if (Get-Variable -Name repo -ErrorAction SilentlyContinue)
            {
                Remove-GitHubRepository -Uri $repo.svn_url -Confirm:$false
            }
        }
    }
}

Describe 'GitHubRepositories\Delete-GitHubRepository' {

    Context -Name 'When deleting a repository' -Fixture {
        BeforeEach -ScriptBlock {
            $repo = New-GitHubRepository -RepositoryName ([Guid]::NewGuid().Guid) -Description $defaultRepoDesc -AutoInit
        }

        It 'Should get no content using -Confirm:$false' {
            Remove-GitHubRepository -OwnerName $repo.owner.login -RepositoryName $repo.name -Confirm:$false
            { Get-GitHubRepository -OwnerName $repo.owner.login -RepositoryName $repo.name } | Should -Throw
        }

        It 'Should get no content using -Force' {
            Remove-GitHubRepository -OwnerName $repo.owner.login -RepositoryName $repo.name -Force
            { Get-GitHubRepository -OwnerName $repo.owner.login -RepositoryName $repo.name } | Should -Throw
        }
    }
}

Describe 'GitHubRepositories\Rename-GitHubRepository' {
    Context -Name 'When renaming a repository' -Fixture {
        BeforeEach -Scriptblock {
            $repo = New-GitHubRepository -RepositoryName ([Guid]::NewGuid().Guid) -AutoInit
            $suffixToAddToRepo = "_renamed"
            $newRepoName = "$($repo.name)$suffixToAddToRepo"
        }

        It "Should have the expected new repository name - by URI" {
            $renamedRepo = Rename-GitHubRepository -Uri ($repo.RepositoryUrl) -NewName $newRepoName -Force -PassThru
            $renamedRepo.name | Should -Be $newRepoName
        }

        It "Should have the expected new repository name - by Elements" {
            $renamedRepo = Rename-GitHubRepository -OwnerName $repo.owner.login -RepositoryName $repo.name -NewName $newRepoName -Confirm:$false -PassThru
            $renamedRepo.name | Should -Be $newRepoName
        }

        It "Should work via the pipeline" {
            $renamedRepo = $repo | Rename-GitHubRepository -NewName $newRepoName -Confirm:$false -PassThru
            $renamedRepo.name | Should -Be $newRepoName
            $renamedRepo.PSObject.TypeNames[0] | Should -Be 'GitHub.Repository'
        }

        It "Should be possible to rename with Set-GitHubRepository too" {
            $renamedRepo = $repo | Set-GitHubRepository -NewName $newRepoName -Confirm:$false -PassThru
            $renamedRepo.name | Should -Be $newRepoName
            $renamedRepo.PSObject.TypeNames[0] | Should -Be 'GitHub.Repository'
        }

        AfterEach -Scriptblock {
            Remove-GitHubRepository -Uri "$($repo.svn_url)$suffixToAddToRepo" -Confirm:$false
        }
    }
}

Describe 'GitHubRepositories\Set-GitHubRepository' {

    Context -Name 'When updating a public repository' -Fixture {
        BeforeAll -ScriptBlock {
            $repoName = ([Guid]::NewGuid().Guid)
            $repo = New-GitHubRepository -RepositoryName $repoName
        }

        Context -Name 'When updating a public repository with Secret Scanning' {
            BeforeAll -ScriptBlock {
                $updateGithubRepositoryParms = @{
                    OwnerName = $repo.owner.login
                    RepositoryName = $repoName
                    SecretScanning = 'Enabled'
                }

                $updatedRepo = Set-GitHubRepository @updateGithubRepositoryParms -PassThru
            }

            It 'Should return an object of the correct type' {
                $updatedRepo | Should -BeOfType PSCustomObject
            }

            It 'Should return the correct properties' {
                $updatedRepo.name | Should -Be $repoName
                $updatedRepo.security_and_analysis.secret_scanning.status | Should -Be 'enabled'
            }
        }

        Context -Name 'When updating a public repository with auto-merge set to true' {
            BeforeAll -ScriptBlock {
                $updateGithubRepositoryParms = @{
                    OwnerName = $repo.owner.login
                    RepositoryName = $repoName
                    AllowAutoMerge = $true
                }

                $updatedRepo = Set-GitHubRepository @updateGithubRepositoryParms -PassThru
            }

            It 'Should return an object of the correct type' {
                $updatedRepo | Should -BeOfType PSCustomObject
            }

            It 'Should return the correct properties' {
                $updatedRepo.name | Should -Be $repoName
                $updatedRepo.allow_auto_merge | Should -BeTrue
            }
        }

        Context -Name 'When updating a public repository with auto-merge set to false' {
            BeforeAll -ScriptBlock {
                $updateGithubRepositoryParms = @{
                    OwnerName = $repo.owner.login
                    RepositoryName = $repoName
                    AllowAutoMerge = $false
                }

                $updatedRepo = Set-GitHubRepository @updateGithubRepositoryParms -PassThru
            }

            It 'Should return an object of the correct type' {
                $updatedRepo | Should -BeOfType PSCustomObject
            }

            It 'Should return the correct properties' {
                $updatedRepo.name | Should -Be $repoName
                $updatedRepo.allow_auto_merge | Should -BeFalse
            }
        }

        Context -Name 'When updating a repository with all possible settings' {
            BeforeAll -ScriptBlock {
                $updateGithubRepositoryParms = @{
                    OwnerName = $repo.owner.login
                    RepositoryName = $repoName
                    Private = $true
                    Description = $defaultRepoDesc
                    HomePage = $defaultRepoHomePage
                    NoIssues = $true
                    NoProjects = $true
                    NoWiki = $true
                    HasDiscussions = $true
                    DisallowSquashMerge = $true
                    DisallowMergeCommit = $true
                    DisallowRebaseMerge = $false
                    AllowUpdateBranch = $true
                    DeleteBranchOnMerge = $true
                    IsTemplate = $true
                    WebCommitSignoffRequired = $true
                }

                $updatedRepo = Set-GitHubRepository @updateGithubRepositoryParms -PassThru
            }

            It 'Should return an object of the correct type' {
                $updatedRepo | Should -BeOfType PSCustomObject
            }

            It 'Should return the correct properties' {
                $updatedRepo.name | Should -Be $repoName
                $updatedRepo.private | Should -BeTrue
                $updatedRepo.description | Should -Be $defaultRepoDesc
                $updatedRepo.homepage | Should -Be $defaultRepoHomePage
                $updatedRepo.has_issues | Should -BeFalse
                $updatedRepo.has_projects | Should -BeFalse
                $updatedRepo.has_Wiki | Should -BeFalse
                $updatedRepo.has_discussions | Should -BeTrue
                $updatedRepo.allow_squash_merge | Should -BeFalse
                $updatedRepo.allow_merge_commit | Should -BeFalse
                $updatedRepo.allow_rebase_merge | Should -BeTrue
                $updatedRepo.allow_update_branch | Should -BeTrue
                $updatedRepo.delete_branch_on_merge | Should -BeTrue
                $updatedRepo.is_template | Should -BeTrue
                $updatedRepo.web_commit_signoff_required | Should -BeTrue
            }
        }

        Context -Name 'When updating a repository with alternative Merge settings' {
            BeforeAll -ScriptBlock {
                $updateGithubRepositoryParms = @{
                    OwnerName = $repo.owner.login
                    RepositoryName = $repoName
                    DisallowSquashMerge = $true
                    DisallowMergeCommit = $false
                    DisallowRebaseMerge = $true
                }

                $updatedRepo = Set-GitHubRepository @updateGithubRepositoryParms -PassThru
            }

            It 'Should return an object of the correct type' {
                $updatedRepo | Should -BeOfType PSCustomObject
            }

            It 'Should return the correct properties' {
                $updatedRepo.name | Should -Be $repoName
                $updatedRepo.allow_squash_merge | Should -BeFalse
                $updatedRepo.allow_merge_commit | Should -BeTrue
                $updatedRepo.allow_rebase_merge | Should -BeFalse
            }
        }

        Context -Name 'When updating a repository with Squash Merge Commit PR Title' {
            BeforeAll -ScriptBlock {
                $updateGithubRepositoryParms = @{
                    OwnerName = $repo.owner.login
                    RepositoryName = $repoName
                    DisallowSquashMerge = $false
                    SquashMergeCommitTitle = 'PRTitle'
                    SquashMergeCommitMessage = 'Blank'
                }

                $updatedRepo = Set-GitHubRepository @updateGithubRepositoryParms -PassThru
            }

            It 'Should return an object of the correct type' {
                $updatedRepo | Should -BeOfType PSCustomObject
            }

            It 'Should return the correct properties' {
                $updatedRepo.name | Should -Be $repoName
                $updatedRepo.allow_squash_merge | Should -BeTrue
                $updatedRepo.squash_merge_commit_title | Should -Be 'PR_TITLE'
                $updatedRepo.squash_merge_commit_message | Should -Be 'BLANK'
            }
        }

        Context -Name 'When updating a repository with Squash Merge Commit PR Title and Commit details' {
            BeforeAll -ScriptBlock {
                $updateGithubRepositoryParms = @{
                    OwnerName = $repo.owner.login
                    RepositoryName = $repoName
                    DisallowSquashMerge = $false
                    SquashMergeCommitTitle = 'PRTitle'
                    SquashMergeCommitMessage = 'CommitMessages'
                }

                $updatedRepo = Set-GitHubRepository @updateGithubRepositoryParms -PassThru
            }

            It 'Should return an object of the correct type' {
                $updatedRepo | Should -BeOfType PSCustomObject
            }

            It 'Should return the correct properties' {
                $updatedRepo.name | Should -Be $repoName
                $updatedRepo.allow_squash_merge | Should -BeTrue
                $updatedRepo.squash_merge_commit_title | Should -Be 'PR_TITLE'
                $updatedRepo.squash_merge_commit_message | Should -Be 'COMMIT_MESSAGES'
            }
        }

        Context -Name 'When updating a repository with Squash Merge Commit PR Title and Description' {
            BeforeAll -ScriptBlock {
                $updateGithubRepositoryParms = @{
                    OwnerName = $repo.owner.login
                    RepositoryName = $repoName
                    DisallowSquashMerge = $false
                    SquashMergeCommitTitle = 'PRTitle'
                    SquashMergeCommitMessage = 'PRBody'
                }

                $updatedRepo = Set-GitHubRepository @updateGithubRepositoryParms -PassThru
            }

            It 'Should return an object of the correct type' {
                $updatedRepo | Should -BeOfType PSCustomObject
            }

            It 'Should return the correct properties' {
                $updatedRepo.name | Should -Be $repoName
                $updatedRepo.allow_squash_merge | Should -BeTrue
                $updatedRepo.squash_merge_commit_title | Should -Be 'PR_TITLE'
                $updatedRepo.squash_merge_commit_message | Should -Be 'PR_BODY'
            }
        }

        Context -Name 'When updating a repository with Squash Merge Commit default message' {
            BeforeAll -ScriptBlock {
                $updateGithubRepositoryParms = @{
                    OwnerName = $repo.owner.login
                    RepositoryName = $repoName
                    DisallowSquashMerge = $false
                    SquashMergeCommitTitle = 'CommitOrPRTitle'
                    SquashMergeCommitMessage = 'CommitMessages'
                }

                $updatedRepo = Set-GitHubRepository @updateGithubRepositoryParms -PassThru
            }

            It 'Should return an object of the correct type' {
                $updatedRepo | Should -BeOfType PSCustomObject
            }

            It 'Should return the correct properties' {
                $updatedRepo.name | Should -Be $repoName
                $updatedRepo.allow_squash_merge | Should -BeTrue
                $updatedRepo.squash_merge_commit_title | Should -Be 'COMMIT_OR_PR_TITLE'
                $updatedRepo.squash_merge_commit_message | Should -Be 'COMMIT_MESSAGES'
            }
        }

        Context -Name 'When updating a repository with Merge Commit PR Title' {
            BeforeAll -ScriptBlock {
                $updateGithubRepositoryParms = @{
                    OwnerName = $repo.owner.login
                    RepositoryName = $repoName
                    DisallowMergeCommit = $false
                    MergeCommitTitle = 'PRTitle'
                    MergeCommitMessage = 'Blank'
                }

                $updatedRepo = Set-GitHubRepository @updateGithubRepositoryParms -PassThru
            }

            It 'Should return an object of the correct type' {
                $updatedRepo | Should -BeOfType PSCustomObject
            }

            It 'Should return the correct properties' {
                $updatedRepo.name | Should -Be $repoName
                $updatedRepo.allow_merge_commit | Should -BeTrue
                $updatedRepo.merge_commit_title | Should -Be 'PR_TITLE'
                $updatedRepo.merge_commit_message | Should -Be 'BLANK'
            }
        }

        Context -Name 'When updating a repository with Merge Commit PR Title and Description' {
            BeforeAll -ScriptBlock {
                $updateGithubRepositoryParms = @{
                    OwnerName = $repo.owner.login
                    RepositoryName = $repoName
                    DisallowMergeCommit = $false
                    MergeCommitTitle = 'PRTitle'
                    MergeCommitMessage = 'PRBody'
                }

                $updatedRepo = Set-GitHubRepository @updateGithubRepositoryParms -PassThru
            }

            It 'Should return an object of the correct type' {
                $updatedRepo | Should -BeOfType PSCustomObject
            }

            It 'Should return the correct properties' {
                $updatedRepo.name | Should -Be $repoName
                $updatedRepo.allow_merge_commit | Should -BeTrue
                $updatedRepo.merge_commit_title | Should -Be 'PR_TITLE'
                $updatedRepo.merge_commit_message | Should -Be 'PR_BODY'
            }
        }

        Context -Name 'When updating a repository with Merge Commit default message' {
            BeforeAll -ScriptBlock {
                $updateGithubRepositoryParms = @{
                    OwnerName = $repo.owner.login
                    RepositoryName = $repoName
                    DisallowMergeCommit = $false
                    MergeCommitTitle = 'MergeMessage'
                    MergeCommitMessage = 'PRTitle'
                }

                $updatedRepo = Set-GitHubRepository @updateGithubRepositoryParms -PassThru
            }

            It 'Should return an object of the correct type' {
                $updatedRepo | Should -BeOfType PSCustomObject
            }

            It 'Should return the correct properties' {
                $updatedRepo.name | Should -Be $repoName
                $updatedRepo.allow_merge_commit | Should -BeTrue
                $updatedRepo.merge_commit_title | Should -Be 'MERGE_MESSAGE'
                $updatedRepo.merge_commit_message | Should -Be 'PR_TITLE'
            }
        }

        Context -Name 'When updating a repository with the Archive setting' {
            BeforeAll -ScriptBlock {
                $updateGithubRepositoryParms = @{
                    OwnerName = $repo.owner.login
                    RepositoryName = $repoName
                    Archived = $true
                }

                $updatedRepo = Set-GitHubRepository @updateGithubRepositoryParms -PassThru
            }

            It 'Should return an object of the correct type' {
                $updatedRepo | Should -BeOfType PSCustomObject
            }

            It 'Should return the correct properties' {
                $updatedRepo.name | Should -Be $repoName
                $updatedRepo.archived | Should -BeTrue
            }
        }

        AfterAll -ScriptBlock {
            if (Get-Variable -Name repo -ErrorAction SilentlyContinue)
            {
                Remove-GitHubRepository -Uri $repo.svn_url -Confirm:$false
            }
        }
    }

    Context -Name 'When updating a private repository' -Fixture {
        BeforeAll -ScriptBlock {
            $repoName = ([Guid]::NewGuid().Guid)
            $repo = New-GitHubRepository -RepositoryName $repoName -Private

            $updateGithubRepositoryParms = @{
                OwnerName = $repo.owner.login
                RepositoryName = $repoName
                Private = $false
            }

            $updatedRepo = Set-GitHubRepository @updateGithubRepositoryParms -PassThru
        }

        It 'Should return an object of the correct type' {
            $updatedRepo | Should -BeOfType PSCustomObject
        }

        It 'Should return the correct properties' {
            $updatedRepo.name | Should -Be $repoName
            $updatedRepo.private | Should -BeFalse
        }

        AfterAll -ScriptBlock {
            if ($repo)
            {
                Remove-GitHubRepository -Uri $repo.svn_url -Confirm:$false
            }
        }
    }
}

Describe 'Common user repository pipeline scenarios' {
    Context 'For authenticated user' {
        BeforeAll -Scriptblock {
            $repo = ([Guid]::NewGuid().Guid) | New-GitHubRepository -AutoInit
        }

        It "Should have expected additional properties and type after creation" {
            $repo.PSObject.TypeNames[0] | Should -Be 'GitHub.Repository'
            $repo.RepositoryUrl | Should -Be (Join-GitHubUri -OwnerName $script:ownerName -RepositoryName $repo.name)
            $repo.RepositoryId | Should -Be $repo.id
            $repo.owner.PSObject.TypeNames[0] | Should -Be 'GitHub.User'
        }

        It "Should have expected additional properties and type after creation" {
            $returned = ($repo | Get-GitHubRepository)
            $returned.PSObject.TypeNames[0] | Should -Be 'GitHub.Repository'
            $returned.RepositoryUrl | Should -Be (Join-GitHubUri -OwnerName $script:ownerName -RepositoryName $returned.name)
            $returned.RepositoryId | Should -Be $returned.id
            $returned.owner.PSObject.TypeNames[0] | Should -Be 'GitHub.User'
        }

        It "Should get the repository by user" {
            $repos = @($script:ownerName | Get-GitHubUser | Get-GitHubRepository)
            $repos.name | Should -Contain $repo.name
        }

        It 'Should be removable by the pipeline' {
                ($repo | Remove-GitHubRepository -Confirm:$false) | Should -BeNullOrEmpty

            { $repo | Get-GitHubRepository } | Should -Throw
        }
    }
}

Describe 'Common organization repository pipeline scenarios' {
    Context 'For organization' {
        BeforeAll -Scriptblock {
            $org = [PSCustomObject]@{'OrganizationName' = $script:organizationName }
            $repo = $org | New-GitHubRepository -RepositoryName ([Guid]::NewGuid().Guid) -AutoInit
        }

        It "Should have expected additional properties and type after creation" {
            $repo.PSObject.TypeNames[0] | Should -Be 'GitHub.Repository'
            $repo.RepositoryUrl | Should -Be (Join-GitHubUri -OwnerName $script:organizationName -RepositoryName $repo.name)
            $repo.RepositoryId | Should -Be $repo.id
            $repo.owner.PSObject.TypeNames[0] | Should -Be 'GitHub.User'
            $repo.organization.PSObject.TypeNames[0] | Should -Be 'GitHub.Organization'
            $repo.organization.OrganizationName | Should -Be $repo.organization.login
            $repo.organization.OrganizationId | Should -Be $repo.organization.id
        }

        It "Should have expected additional properties and type after creation" {
            $returned = ($repo | Get-GitHubRepository)
            $returned.PSObject.TypeNames[0] | Should -Be 'GitHub.Repository'
            $returned.RepositoryUrl | Should -Be (Join-GitHubUri -OwnerName $script:organizationName -RepositoryName $returned.name)
            $returned.RepositoryId | Should -Be $returned.id
            $returned.owner.PSObject.TypeNames[0] | Should -Be 'GitHub.User'
            $returned.organization.PSObject.TypeNames[0] | Should -Be 'GitHub.Organization'
            $returned.organization.OrganizationName | Should -Be $returned.organization.login
            $returned.organization.OrganizationId | Should -Be $returned.organization.id
        }

        It 'Should be removable by the pipeline' {
                ($repo | Remove-GitHubRepository -Confirm:$false) | Should -BeNullOrEmpty
            { $repo | Get-GitHubRepository } | Should -Throw
        }
    }
}

Describe 'GitHubRepositories\Get-GitHubRepositoryTopic' {

    Context -Name 'When getting a repository topic' {
        BeforeAll {
            $repo = New-GitHubRepository -RepositoryName ([Guid]::NewGuid().Guid)
            Set-GitHubRepositoryTopic -OwnerName $repo.owner.login -RepositoryName $repo.name -Name $defaultRepoTopic
            $topic = Get-GitHubRepositoryTopic -OwnerName $repo.owner.login -RepositoryName $repo.name
        }

        It 'Should have the expected topic' {
            Set-GitHubRepositoryTopic -OwnerName $repo.owner.login -RepositoryName $repo.name -Topic $defaultRepoTopic
            $topic = Get-GitHubRepositoryTopic -OwnerName $repo.owner.login -RepositoryName $repo.name

            $topic.names | Should -Be $defaultRepoTopic
        }

        It 'Should have no topics' {
            Set-GitHubRepositoryTopic -OwnerName $repo.owner.login -RepositoryName $repo.name -Clear
            $topic = Get-GitHubRepositoryTopic -OwnerName $repo.owner.login -RepositoryName $repo.name

            $topic.names | Should -BeNullOrEmpty
        }

        It 'Should have the expected topic (using repo via pipeline)' {
            $repo | Set-GitHubRepositoryTopic -Topic $defaultRepoTopic
            $topic = $repo | Get-GitHubRepositoryTopic

            $topic.names | Should -Be $defaultRepoTopic
            $topic.PSObject.TypeNames[0] | Should -Be 'GitHub.RepositoryTopic'
            $topic.RepositoryUrl | Should -Be $repo.RepositoryUrl
        }

        It 'Should have the expected topic (using topic via pipeline)' {
            $defaultRepoTopic | Set-GitHubRepositoryTopic -OwnerName $repo.owner.login -RepositoryName $repo.name
            $topic = $repo | Get-GitHubRepositoryTopic

            $topic.names | Should -Be $defaultRepoTopic
            $topic.PSObject.TypeNames[0] | Should -Be 'GitHub.RepositoryTopic'
            $topic.RepositoryUrl | Should -Be $repo.RepositoryUrl
        }

        It 'Should have the expected multi-topic (using topic via pipeline)' {
            $topics = @('one', 'two')
            $topics | Set-GitHubRepositoryTopic -OwnerName $repo.owner.login -RepositoryName $repo.name
            $result = $repo | Get-GitHubRepositoryTopic

            $result.PSObject.TypeNames[0] | Should -Be 'GitHub.RepositoryTopic'
            $result.RepositoryUrl | Should -Be $repo.RepositoryUrl
            $result.names.count | Should -Be $topics.Count
            foreach ($topic in $topics)
            {
                $result.names | Should -Contain $topic
            }
        }

        AfterAll {
            Remove-GitHubRepository -Uri $repo.svn_url -Confirm:$false
        }
    }
}

Describe 'GitHubRepositories\Set-GitHubRepositoryTopic' {
    BeforeAll {
        $repo = New-GitHubRepository -RepositoryName ([Guid]::NewGuid().Guid)
        $topic = Set-GitHubRepositoryTopic -OwnerName $repo.owner.login -RepositoryName $repo.name -Name $defaultRepoTopic -PassThru
    }

    Context -Name 'When setting a repository topic' {
        It 'Should return an object of the correct type' {
            $topic | Should -BeOfType PSCustomObject
        }

        It 'Should return the correct properties' {
            $defaultRepoTopic | Should -BeIn $topic.names
        }
    }

    Context -Name 'When clearing all repository topics' {
        BeforeAll {
            $topic = Set-GitHubRepositoryTopic -OwnerName $repo.owner.login -RepositoryName $repo.name -Clear -PassThru
        }

        It 'Should return an object of the correct type' {
            $topic.PSObject.TypeNames[0] | Should -Be 'GitHub.RepositoryTopic'
        }

        It 'Should return the correct properties' {
            $topic.names | Should -BeNullOrEmpty
        }
    }

    AfterAll {
        Remove-GitHubRepository -Uri $repo.svn_url -Confirm:$false
    }
}

Describe 'GitHubRepositories\Get-GitHubRepositoryContributor' {
    BeforeAll {
        $repoName = [Guid]::NewGuid().Guid
        $repo = New-GitHubRepository -RepositoryName $repoName -AutoInit
    }

    Context 'When getting GitHub Repository Contributors' {
        BeforeAll {
            $getGitHubRepositoryContributorParms = @{
                OwnerName = $repo.owner.login
                RepositoryName = $repoName
            }

            $contributors = @(Get-GitHubRepositoryContributor @getGitHubRepositoryContributorParms)
        }

        It 'Should return objects of the correct type' {
            $contributors[0].PSObject.TypeNames[0] | Should -Be 'GitHub.RepositoryContributor'
        }

        It 'Should return expected number of contributors' {
            $contributors.Count | Should -Be 1
        }

        It "Should return the correct membership" {
            $repo.owner.login | Should -BeIn $contributors.login
        }
    }

    # TODO: This test has been disabled because GitHub isn't returning back a result after over
    # one hour of retries.  See here for more info:
    # https://github.community/t/unable-to-retrieve-contributor-statistics-for-a-brand-new-repo/136658
    #
    # Context 'When getting Github Repository Contributors with Statistics' {
    #     BeforeAll {
    #         $getGitHubRepositoryContributorParms = @{
    #             OwnerName = $repo.owner.login
    #             RepositoryName = $repoName
    #             IncludeStatistics = $true
    #         }

    #         $contributors = @(Get-GitHubRepositoryContributor @getGitHubRepositoryContributorParms)
    #     }

    #     It 'Should return objects of the correct type' {
    #         $contributors[0].PSObject.TypeNames[0] | Should -Be 'GitHub.RepositoryContributorStatistics'
    #         $contributors[0].author.PSObject.TypeNames[0] | Should -Be 'GitHub.User'
    #     }

    #     It 'Should return expected number of contributors' {
    #         $contributors.Count | Should -Be 1
    #     }

    #     It 'Should return the correct membership' {
    #         $repo.owner.login | Should -BeIn $contributors.author.login
    #     }

    #     It 'Should return the correct properties' {
    #         $contributors.weeks | Should -Not -BeNullOrEmpty
    #     }
    # }

    Context 'When getting Github Repository Contributors including Anonymous' {
        BeforeAll {
            $getGitHubRepositoryContributorParms = @{
                OwnerName = $repo.owner.login
                RepositoryName = $repoName
                IncludeAnonymousContributors = $true
            }

            $contributors = @(Get-GitHubRepositoryContributor @getGitHubRepositoryContributorParms)
        }

        It 'Should return objects of the correct type' {
            $contributors[0].PSObject.TypeNames[0] | Should -Be 'GitHub.RepositoryContributor'
        }

        It 'Should return at least one result' {
            $contributors.count | Should -BeGreaterOrEqual 1
        }

        It 'Should return the correct membership' {
            $repo.owner.login | Should -BeIn $contributors.login
        }
    }

    AfterAll {
        Remove-GitHubRepository -Uri $repo.svn_url -Confirm:$false
    }
}

Describe 'GitHubRepositories\Get-GitHubRepositoryCollaborator' {
    BeforeAll {
        $repoName = [Guid]::NewGuid().Guid
        $repo = New-GitHubRepository -RepositoryName $repoName -AutoInit
    }

    Context 'When getting GitHub Repository Collaborators' {
        BeforeAll {
            $getGitHubRepositoryCollaboratorParms = @{
                OwnerName = $repo.owner.login
                RepositoryName = $repoName
            }

            $collaborators = @(Get-GitHubRepositoryCollaborator @getGitHubRepositoryCollaboratorParms)
        }

        It 'Should return objects of the correct type' {
            $collaborators[0].PSObject.TypeNames[0] | Should -Be 'GitHub.RepositoryCollaborator'
        }

        It 'Should return expected number of collaborators' {
            $collaborators.Count | Should -Be 1
        }

        It "Should return the correct membership" {
            $repo.owner.login | Should -BeIn $collaborators.login
        }
    }

    Context 'When getting GitHub Repository Collaborators (via pipeline)' {
        BeforeAll {
            $collaborators = @($repo | Get-GitHubRepositoryCollaborator)
        }

        It 'Should return objects of the correct type' {
            $collaborators[0].PSObject.TypeNames[0] | Should -Be 'GitHub.RepositoryCollaborator'
        }

        It 'Should return expected number of collaborators' {
            $collaborators.Count | Should -Be 1
        }

        It "Should return the correct membership" {
            $repo.owner.login | Should -BeIn $collaborators.login
        }
    }

    AfterAll {
        Remove-GitHubRepository -Uri $repo.svn_url -Confirm:$false
    }
}

Describe 'GitHubRepositories\Get-GitHubRepositoryLanguage' {

    Context -Name 'When getting repository languages' {
        BeforeAll {
            $repo = New-GitHubRepository -RepositoryName ([Guid]::NewGuid().Guid) -AutoInit
        }

        It 'Should be empty' {
            $languages = Get-GitHubRepositoryLanguage -OwnerName $repo.owner.login -RepositoryName $repo.name
            $languages | Should -BeNullOrEmpty
        }

        It 'Should contain PowerShell' {
            $languages = Get-GitHubRepositoryLanguage -OwnerName "microsoft" -RepositoryName "PowerShellForGitHub"
            $languages.PowerShell | Should -Not -BeNullOrEmpty
            $languages.PSObject.TypeNames[0] | Should -Be 'GitHub.RepositoryLanguage'
        }

        It 'Should contain PowerShell (via pipeline)' {
            $psfg = Get-GitHubRepository -OwnerName "microsoft" -RepositoryName "PowerShellForGitHub"
            $languages = $psfg | Get-GitHubRepositoryLanguage
            $languages.PowerShell | Should -Not -BeNullOrEmpty
            $languages.PSObject.TypeNames[0] | Should -Be 'GitHub.RepositoryLanguage'
        }

        AfterAll {
            Remove-GitHubRepository -Uri $repo.svn_url -Force
        }
    }
}

Describe 'GitHubRepositories\Get-GitHubRepositoryTag' {

    Context -Name 'When getting repository tags' {
        BeforeAll {
            $repo = New-GitHubRepository -RepositoryName ([Guid]::NewGuid().Guid) -AutoInit
        }

        It 'Should be empty' {
            $tags = Get-GitHubRepositoryTag -OwnerName $repo.owner.login -RepositoryName $repo.name
            $tags | Should -BeNullOrEmpty
        }

        It 'Should be empty (via pipeline)' {
            $tags = $repo | Get-GitHubRepositoryTag
            $tags | Should -BeNullOrEmpty
        }

        AfterAll {
            Remove-GitHubRepository -Uri $repo.svn_url -Confirm:$false
        }
    }
}

Describe 'GitHubRepositories\Test-GitHubRepositoryVulnerabilityAlert' {
    BeforeAll -ScriptBlock {
        $repo = New-GitHubRepository -RepositoryName ([Guid]::NewGuid().Guid)
    }

    Context 'When the Git Hub Repository Vulnerability Alert Status is Enabled' {
        BeforeAll -ScriptBlock {
            Enable-GitHubRepositoryVulnerabilityAlert -Uri  $repo.svn_url
            $result = Test-GitHubRepositoryVulnerabilityAlert -Uri $repo.svn_url
        }

        It 'Should return an object of the correct type' {
            $result | Should -BeOfType System.Boolean
        }

        It 'Should return the correct value' {
            $result | Should -Be $true
        }
    }

    Context 'When the Git Hub Repository Vulnerability Alert Status is Disabled' {
        BeforeAll -ScriptBlock {
            Disable-GitHubRepositoryVulnerabilityAlert -Uri  $repo.svn_url
            $status = Test-GitHubRepositoryVulnerabilityAlert -Uri $repo.svn_url
        }

        It 'Should return an object of the correct type' {
            $status | Should -BeOfType System.Boolean
        }

        It 'Should return the correct value' {
            $status | Should -BeFalse
        }
    }

    Context 'When Invoke-GHRestMethod returns an unexpected error' {
        It 'Should throw' {
            $getGitHubRepositoryVulnerabilityAlertParms = @{
                OwnerName = 'octocat'
                RepositoryName = 'IncorrectRepostioryName'
            }
            { Test-GitHubRepositoryVulnerabilityAlert @getGitHubRepositoryVulnerabilityAlertParms } |
            Should -Throw
        }
    }

    Context "When specifiying the 'URI' Parameter from the Pipeline" {
        BeforeAll -ScriptBlock {
            $status = $repo | Test-GitHubRepositoryVulnerabilityAlert
        }

        It 'Should return an object of the correct type' {
            $status | Should -BeOfType System.Boolean
        }
    }

    AfterAll -ScriptBlock {
        Remove-GitHubRepository -Uri $repo.svn_url -Force
    }
}

Describe 'GitHubRepositories\Enable-GitHubRepositoryVulnerabilityAlert' {
    BeforeAll {
        $repo = New-GitHubRepository -RepositoryName ([Guid]::NewGuid().Guid)
    }

    Context 'When Enabling GitHub Repository Vulnerability Alerts' {
        It 'Should not throw' {
            { Enable-GitHubRepositoryVulnerabilityAlert -Uri  $repo.svn_url } |
            Should -Not -Throw
        }
    }

    Context "When specifiying the 'URI' Parameter from the Pipeline" {
        BeforeAll -ScriptBlock {
            Disable-GitHubRepositoryVulnerabilityAlert -Uri $repo.svn_url
        }

        It 'Should not throw' {
            { $repo | Enable-GitHubRepositoryVulnerabilityAlert } |
            Should -Not -Throw
        }
    }

    AfterAll -ScriptBlock {
        Remove-GitHubRepository -Uri $repo.svn_url -Force
    }
}

Describe 'GitHubRepositories\Disable-GitHubRepositoryVulnerabilityAlert' {
    BeforeAll {
        $repo = New-GitHubRepository -RepositoryName ([Guid]::NewGuid().Guid)
        Enable-GitHubRepositoryVulnerabilityAlert -Uri $repo.svn_url
    }

    Context 'When Disabling GitHub Repository Vulnerability Alerts' {
        It 'Should not throw' {
            { Disable-GitHubRepositoryVulnerabilityAlert -Uri $repo.svn_url } |
            Should -Not -Throw
        }
    }

    Context "When specifiying the 'URI' Parameter from the Pipeline" {
        BeforeAll -ScriptBlock {
            Enable-GitHubRepositoryVulnerabilityAlert -Uri $repo.svn_url
        }

        It 'Should not throw' {
            { $repo | Disable-GitHubRepositoryVulnerabilityAlert } |
            Should -Not -Throw
        }
    }

    AfterAll -ScriptBlock {
        Remove-GitHubRepository -Uri $repo.svn_url -Force
    }
}

Describe 'GitHubRepositories\Enable-GitHubRepositorySecurityFix' {
    BeforeAll {
        $repo = New-GitHubRepository -RepositoryName ([Guid]::NewGuid().Guid)
        Enable-GitHubRepositoryVulnerabilityAlert -Uri $repo.svn_url
    }

    Context 'When Enabling GitHub Repository Security Fixes' {
        It 'Should not throw' {
            { Enable-GitHubRepositorySecurityFix -Uri $repo.svn_url } |
            Should -Not -Throw
        }
    }

    Context "When specifiying the 'URI' Parameter from the Pipeline" {
        BeforeAll -ScriptBlock {
            Disable-GitHubRepositorySecurityFix -Uri $repo.svn_url
        }

        It 'Should not throw' {
            { $repo | Enable-GitHubRepositorySecurityFix } |
            Should -Not -Throw
        }
    }

    AfterAll -ScriptBlock {
        Remove-GitHubRepository -Uri $repo.svn_url -Force
    }
}

Describe 'GitHubRepositories\Disable-GitHubRepositorySecurityFix' {
    BeforeAll {
        $repo = New-GitHubRepository -RepositoryName ([Guid]::NewGuid().Guid)
        Enable-GitHubRepositoryVulnerabilityAlert -Uri $repo.svn_url
        Enable-GitHubRepositorySecurityFix -Uri  $repo.svn_url
    }

    Context 'When Disabling GitHub Repository Security Fixes' {
        It 'Should not throw' {
            { Disable-GitHubRepositorySecurityFix -Uri $repo.svn_url } |
            Should -Not -Throw
        }
    }

    Context "When specifiying the 'URI' Parameter from the Pipeline" {
        BeforeAll -ScriptBlock {
            Enable-GitHubRepositorySecurityFix -Uri $repo.svn_url
        }

        It 'Should not throw' {
            { $repo | Disable-GitHubRepositorySecurityFix } |
            Should -Not -Throw
        }
    }

    AfterAll -ScriptBlock {
        Remove-GitHubRepository -Uri $repo.svn_url -Force
    }
}

Describe 'GitHubRepositories\Get-GitHubRepositoryActionsPermission' {
    BeforeAll {
        $repoName = [Guid]::NewGuid().Guid
        $repo = New-GitHubRepository -RepositoryName $repoName

    }

    Context "Checking AllowedActions" -ForEach @('All', 'LocalOnly', 'Selected', 'Disabled') {
        BeforeAll {
            $setGitHubRepositoryActionsPermissionParms = @{
                Uri = $repo.svn_url
                AllowedActions = $_
            }

            Set-GitHubRepositoryActionsPermission @setGitHubRepositoryActionsPermissionParms

            $permissions = Get-GitHubRepositoryActionsPermission -Uri $repo.svn_url
        }

        It "Should return the correct type and properties for $_" {
            $permissions.PSObject.TypeNames[0] | Should -Be 'GitHub.RepositoryActionsPermission'

            $permissions.RepositoryName | Should -Be $repoName
            $permissions.RepositoryUrl | Should -Be $repo.svn_url

            if ($_ -eq 'Disabled')
            {
                $permissions.Enabled | Should -BeFalse
            }
            else
            {
                $permissions.Enabled | Should -BeTrue
                $permissions.AllowedActions | Should -Be $_
            }
        }
    }

    Context "When specifiying the 'URI' Parameter from the Pipeline" {
        BeforeAll {
            $permissions = $repo | Get-GitHubRepositoryActionsPermission
        }

        It 'Should return an object of the correct type' {
            $permissions.PSObject.TypeNames[0] | Should -Be 'GitHub.RepositoryActionsPermission'
        }
    }

    AfterAll {
        if (Get-Variable -Name repo -ErrorAction SilentlyContinue)
        {
            $repo | Remove-GitHubRepository -Force
        }
    }
}

Describe 'GitHubRepositories\Set-GitHubRepositoryActionsPermission' {
    BeforeAll {
        $repo = New-GitHubRepository -RepositoryName ([Guid]::NewGuid().Guid)

    }

    Context "Checking the AllowedAction Parameter" -ForEach @('All', 'LocalOnly', 'Selected', 'Disabled') {
        BeforeAll {
            $setGitHubRepositoryActionsPermissionParms = @{
                Uri = $repo.svn_url
                AllowedActions = $_
            }

            Set-GitHubRepositoryActionsPermission @setGitHubRepositoryActionsPermissionParms
        }

        It "Should have set the expected permissions for $_" {
            $permissions = Get-GitHubRepositoryActionsPermission -Uri $repo.svn_url

            if ($_ -eq 'Disabled')
            {
                $permissions.Enabled | Should -BeFalse
            }
            else
            {
                $permissions.Enabled | Should -BeTrue
                $permissions.AllowedActions | Should -Be $_
            }
        }
    }

    Context "When specifiying the 'URI' Parameter from the Pipeline" {
        It 'Should not throw' {
            { $repo | Set-GitHubRepositoryActionsPermission -AllowedActions 'All' } |
            Should -Not -Throw
        }
    }

    AfterAll {
        if (Get-Variable -Name repo -ErrorAction SilentlyContinue)
        {
            $repo | Remove-GitHubRepository -Force
        }
    }
}

Describe 'GitHubRepositories\Get-GitHubRepositoryTeamPermission' {
    BeforeAll {
        $repositoryTeamPermissionTypeName = 'GitHub.RepositoryTeamPermission'
        $repoName = [Guid]::NewGuid().Guid
        $repo = New-GitHubRepository -OrganizationName $script:organizationName -RepositoryName $repoName

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

        $team = New-GitHubTeam @newGithubTeamParms

    }

    Context "Checking the Team Permissions" -ForEach @('Push', 'Pull', 'Maintain', 'Triage', 'Admin') {
        BeforeAll {
            $setGitHubRepositoryTeamPermissionParms = @{
                Uri = $repo.svn_url
                TeamSlug = $team.slug
                Permission = $_
            }

            Set-GitHubRepositoryTeamPermission @setGitHubRepositoryTeamPermissionParms

            $getGithubRepositoryTeamPermissionParms = @{
                Uri = $repo.svn_url
                TeamSlug = $team.slug
            }

            $repoPermission = Get-GitHubRepositoryTeamPermission @getGithubRepositoryTeamPermissionParms
        }

        It "Should have the expected type and additional properties for $_" {
            $repoPermission.PSObject.TypeNames[0] | Should -Be $repositoryTeamPermissionTypeName
            $repoPermission.RepositoryName | Should -Be $repo.full_name
            $repoPermission.RepositoryUrl | Should -Be $repo.svn_url
            $repoPermission.RepositoryId | Should -Be $repo.RepositoryId
            $repoPermission.TeamName | Should -Be $team.TeamName
            $repoPermission.TeamSlug | Should -Be $team.TeamSlug
            $repoPermission.Permission | Should -Be $_
        }
    }

    Context "When specifying the 'TeamName' parameter" {
        BeforeAll {
            $permission = 'Pull'

            $setGitHubRepositoryTeamPermissionParms = @{
                Uri = $repo.svn_url
                TeamSlug = $team.slug
                Permission = $permission
            }

            Set-GitHubRepositoryTeamPermission @setGitHubRepositoryTeamPermissionParms

            $getGithubRepositoryTeamPermissionParms = @{
                Uri = $repo.svn_url
                TeamName = $teamName
            }

            $repoPermission = Get-GitHubRepositoryTeamPermission @getGithubRepositoryTeamPermissionParms
        }

        It 'Should have the expected type and additional properties' {
            $repoPermission.PSObject.TypeNames[0] | Should -Be $repositoryTeamPermissionTypeName
            $repoPermission.RepositoryName | Should -Be $repo.full_name
            $repoPermission.RepositoryUrl | Should -Be $repo.svn_url
            $repoPermission.RepositoryId | Should -Be $repo.RepositoryId
            $repoPermission.TeamName | Should -Be $team.TeamName
            $repoPermission.TeamSlug | Should -Be $team.TeamSlug
            $repoPermission.Permission | Should -Be $permission
        }

        Context 'When the specified TeamName does not exist' {
            BeforeAll {
                $nonExistingTeamName = [Guid]::NewGuid().Guid

                $getGithubRepositoryTeamPermissionParms = @{
                    Uri = $repo.svn_url
                    TeamName = $nonExistingTeamName
                }
            }

            It 'Should throw the correct exception' {
                { Get-GitHubRepositoryTeamPermission @getGithubRepositoryTeamPermissionParms } |
                Should -Throw "Team '$nonExistingTeamName' not found"
            }
        }
    }

    Context "When specifying the 'URI' Parameter from the Pipeline" {
        BeforeAll -ScriptBlock {
            $getGitHubRepositoryTeamPermissionParms = @{
                TeamName = $teamName
            }
            $repoPermission = $repo |
            Get-GitHubRepositoryTeamPermission @getGitHubRepositoryTeamPermissionParms
        }

        It 'Should have the expected type and additional properties' {
            $repoPermission.PSObject.TypeNames[0] | Should -Be $repositoryTeamPermissionTypeName
            $repoPermission.RepositoryName | Should -Be $repo.full_name
            $repoPermission.TeamName | Should -Be $teamName
        }
    }

    Context "When specifying the 'TeamSlug' and 'OrganizationName' Parameters from the Pipeline" {
        BeforeAll -ScriptBlock {
            $getGitHubRepositoryTeamPermissionParms = @{
                Uri = $repo.svn_url
            }
            $repoPermission = $team |
            Get-GitHubRepositoryTeamPermission @getGitHubRepositoryTeamPermissionParms
        }

        It 'Should have the expected type and additional properties' {
            $repoPermission.PSObject.TypeNames[0] | Should -Be $repositoryTeamPermissionTypeName
            $repoPermission.RepositoryName | Should -Be $repo.full_name
            $repoPermission.TeamName | Should -Be $teamName
            $repoPermission.TeamSlug | Should -Be $team.TeamSlug
        }
    }

    AfterAll {
        if (Get-Variable -Name team -ErrorAction SilentlyContinue)
        {
            $team | Remove-GitHubTeam -Force
        }

        if (Get-Variable -Name repo -ErrorAction SilentlyContinue)
        {
            $repo | Remove-GitHubRepository -Force
        }
    }
}

Describe 'GitHubRepositories\Set-GitHubRepositoryTeamPermission' {
    BeforeAll {
        $repoName = [Guid]::NewGuid().Guid
        $repo = New-GitHubRepository -OrganizationName $script:organizationName -RepositoryName $repoName

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

        $team = New-GitHubTeam @newGithubTeamParms

    }

    Context "Checking the Team Permission" -ForEach @('Push', 'Pull', 'Maintain', 'Triage', 'Admin') {
        BeforeAll {
            $setGitHubRepositoryTeamPermissionParms = @{
                Uri = $repo.svn_url
                TeamSlug = $team.slug
                Permission = $_
            }

        }

        It 'Should not throw' {
            { Set-GitHubRepositoryTeamPermission @setGitHubRepositoryTeamPermissionParms }  |
            Should -Not -Throw

        }

        It "Should have set the correct Team permission of $_" {
            $getGithubRepositoryTeamPermissionParms = @{
                Uri = $repo.svn_url
                TeamSlug = $team.slug
            }

            $repoPermission = Get-GitHubRepositoryTeamPermission @getGithubRepositoryTeamPermissionParms

            $repoPermission.Permission | Should -Be $_
        }
    }


    Context "When specifying the 'TeamName' parameter" {
        BeforeAll {
            $permission = 'Pull'

            $setGitHubRepositoryTeamPermissionParms = @{
                Uri = $repo.svn_url
                TeamName = $teamName
                Permission = $permission
            }
        }

        It 'Should not throw' {
            { Set-GitHubRepositoryTeamPermission @setGitHubRepositoryTeamPermissionParms } |
            Should -Not -Throw
        }

        It 'Should have set the correct Team permission' {
            $getGithubRepositoryTeamPermissionParms = @{
                Uri = $repo.svn_url
                TeamSlug = $team.slug
            }

            $repoPermission = Get-GitHubRepositoryTeamPermission @getGithubRepositoryTeamPermissionParms

            $repoPermission.Permission | Should -Be $permission
        }

        Context 'When the specified TeamName does not exist' {
            BeforeAll {
                $nonExistingTeamName = [Guid]::NewGuid().Guid

                $setGithubRepositoryTeamPermissionParms = @{
                    Uri = $repo.svn_url
                    TeamName = $nonExistingTeamName
                }
            }

            It 'Should throw the correct exception' {
                { Set-GitHubRepositoryTeamPermission @setGithubRepositoryTeamPermissionParms } |
                Should -Throw "Team '$nonExistingTeamName' not found"
            }
        }
    }

    Context "When specifying the 'URI' Parameter from the Pipeline" {
        BeforeAll -ScriptBlock {
            $setGitHubRepositoryTeamPermissionParms = @{
                TeamName = $teamName
            }
        }

        It 'Should not throw' {
            { $repo | Set-GitHubRepositoryTeamPermission @setGitHubRepositoryTeamPermissionParms } |
            Should -Not -Throw
        }
    }

    Context "When specifying the 'TeamSlug' and 'OrganizationName' Parameters from the Pipeline" {
        BeforeAll -ScriptBlock {
            $setGitHubRepositoryTeamPermissionParms = @{
                Uri = $repo.svn_url
            }
        }

        It 'Should not throw' {
            { $team | Set-GitHubRepositoryTeamPermission @setGitHubRepositoryTeamPermissionParms } |
            Should -Not -Throw
        }
    }

    AfterAll {
        if (Get-Variable -Name team -ErrorAction SilentlyContinue)
        {
            $team | Remove-GitHubTeam -Force
        }

        if (Get-Variable -Name repo -ErrorAction SilentlyContinue)
        {
            $repo | Remove-GitHubRepository -Force
        }
    }
}

Describe 'GitHubRepositories\Remove-GitHubRepositoryTeamPermission' {
    BeforeAll {
        $repoName = [Guid]::NewGuid().Guid
        $repo = New-GitHubRepository -OrganizationName $script:organizationName -RepositoryName $repoName

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

        $team = New-GitHubTeam @newGithubTeamParms

        $setGitHubRepositoryTeamPermissionParms = @{
            Uri = $repo.svn_url
            TeamSlug = $team.slug
            Permission = 'Pull'
        }

        Set-GitHubRepositoryTeamPermission @setGitHubRepositoryTeamPermissionParms
    }

    Context "When specifying the 'TeamSlug' parameter" {
        BeforeAll {
            $setGitHubRepositoryTeamPermissionParms = @{
                Uri = $repo.svn_url
                TeamSlug = $team.slug
                Permission = 'Pull'
            }

            Set-GitHubRepositoryTeamPermission @setGitHubRepositoryTeamPermissionParms
        }

        It 'Should not throw' {
            $removeGitHubRepositoryTeamPermissionParms = @{
                Uri = $repo.svn_url
                TeamSlug = $team.slug
                Force = $true
            }

            { Remove-GitHubRepositoryTeamPermission @removeGitHubRepositoryTeamPermissionParms } |
            Should -Not -Throw

        }

        It 'Should have removed the Team permission' {
            $getGithubRepositoryTeamPermissionParms = @{
                Uri = $repo.svn_url
                TeamSlug = $team.slug
            }

            { Get-GitHubRepositoryTeamPermission @getGithubRepositoryTeamPermissionParms } |
            Should -Throw
        }
    }

    Context "When specifying the 'TeamName' parameter" {
        BeforeAll {
            $setGitHubRepositoryTeamPermissionParms = @{
                Uri = $repo.svn_url
                TeamSlug = $team.slug
                Permission = 'Pull'
            }

            Set-GitHubRepositoryTeamPermission @setGitHubRepositoryTeamPermissionParms
        }

        It 'Should not throw' {
            $removeGitHubRepositoryTeamPermissionParms = @{
                Uri = $repo.svn_url
                TeamName = $teamName
                Force = $true
            }

            { Remove-GitHubRepositoryTeamPermission @removeGitHubRepositoryTeamPermissionParms } |
            Should -Not -Throw
        }

        It 'Should have removed the Team permission' {
            $getGithubRepositoryTeamPermissionParms = @{
                Uri = $repo.svn_url
                TeamSlug = $team.slug
            }

            { Get-GitHubRepositoryTeamPermission @getGithubRepositoryTeamPermissionParms } |
            Should -Throw
        }

        Context 'When the specified TeamName does not exist' {
            BeforeAll {
                $nonExistingTeamName = [Guid]::NewGuid().Guid

                $removeGithubRepositoryTeamPermissionParms = @{
                    Uri = $repo.svn_url
                    TeamName = $nonExistingTeamName
                    Force = $true
                }
            }

            It 'Should throw the correct exception' {
                { Remove-GitHubRepositoryTeamPermission @removeGithubRepositoryTeamPermissionParms } |
                Should -Throw "Team '$nonExistingTeamName' not found"
            }
        }
    }

    Context "When specifying the 'URI' Parameter from the Pipeline" {
        BeforeAll -ScriptBlock {
            $removeGitHubRepositoryTeamPermissionParms = @{
                TeamName = $teamName
                Force = $true
            }
        }

        It 'Should not throw' {
            { $repo | Remove-GitHubRepositoryTeamPermission @removeGitHubRepositoryTeamPermissionParms } |
            Should -Not -Throw
        }
    }

    Context "When specifying the 'TeamSlug' and 'Organization' Parameter from the Pipeline" {
        BeforeAll -ScriptBlock {
            $removeGitHubRepositoryTeamPermissionParms = @{
                RepositoryUrl = $repo.svn_url
                Force = $true
            }
        }

        It 'Should not throw' {
            { $team | Remove-GitHubRepositoryTeamPermission @removeGitHubRepositoryTeamPermissionParms } |
            Should -Not -Throw
        }
    }

    AfterAll {
        if (Get-Variable -Name team -ErrorAction SilentlyContinue)
        {
            $team | Remove-GitHubTeam -Force
        }

        if (Get-Variable -Name repo -ErrorAction SilentlyContinue)
        {
            $repo | Remove-GitHubRepository -Force
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
