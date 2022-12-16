# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

<#
.Synopsis
   Tests for GitHubContents.ps1 module
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
        repoGuid = [Guid]::NewGuid().Guid
        readmeFileName = "README.md"
    }.GetEnumerator() | ForEach-Object {
        Set-Variable -Force -Scope Script -Option ReadOnly -Visibility Private -Name $_.Key -Value $_.Value
    }

    # Need two separate blocks to set constants because we need to reference a constant from the first block in this block.
    @{
        htmlOutputStart = '<div id="file" class="md" data-path="README.md">'
        rawOutput = "# $repoGuid"
    }.GetEnumerator() | ForEach-Object {
        Set-Variable -Force -Scope Script -Option ReadOnly -Visibility Private -Name $_.Key -Value $_.Value
    }
}

Describe 'Getting file and folder content' {
    BeforeAll {
        # AutoInit will create a readme with the GUID of the repo name
        $repo = New-GitHubRepository -RepositoryName ($repoGuid) -AutoInit
    }

    AfterAll {
        Remove-GitHubRepository -Uri $repo.svn_url -Confirm:$false
    }

    Context 'For getting folder contents with parameters' {
        BeforeAll {
            $folderOutput = Get-GitHubContent -OwnerName $script:ownerName -RepositoryName $repo.name
        }

        It "Should have the expected name" {
            $folderOutput.name | Should -BeNullOrEmpty
        }

        It "Should have the expected path" {
            $folderOutput.path | Should -BeNullOrEmpty
        }

        It "Should have the expected type" {
            $folderOutput.type | Should -Be "dir"
        }

        It "Should have the expected entries" {
            $folderOutput.entries.length | Should -Be 1
        }

        It "Should have the expected entry data" {
            $folderOutput.entries[0].name | Should -Be $readmeFileName
            $folderOutput.entries[0].path | Should -Be $readmeFileName
        }

        It "Should have the expected type and additional properties" {
            $folderOutput.PSObject.TypeNames[0] | Should -Be 'GitHub.Content'
            $folderOutput.RepositoryUrl | Should -Be $repo.RepositoryUrl
        }
    }

    Context 'For getting folder contents via URL' {
        BeforeAll {
            $folderOutput = Get-GitHubContent -Uri "https://github.com/$($script:ownerName)/$($repo.name)"
        }

        It "Should have the expected name" {
            $folderOutput.name | Should -BeNullOrEmpty
        }

        It "Should have the expected path" {
            $folderOutput.path | Should -BeNullOrEmpty
        }

        It "Should have the expected type" {
            $folderOutput.type | Should -Be "dir"
        }

        It "Should have the expected entries" {
            $folderOutput.entries.length | Should -Be 1
        }

        It "Should have the expected entry data" {
            $folderOutput.entries[0].name | Should -Be $readmeFileName
            $folderOutput.entries[0].path | Should -Be $readmeFileName
        }

        It "Should have the expected type" {
            $folderOutput.PSObject.TypeNames[0] | Should -Be 'GitHub.Content'
            $folderOutput.RepositoryUrl | Should -Be $repo.RepositoryUrl
        }
    }

    Context 'For getting folder contents with the repo on the pipeline' {
        BeforeAll {
            $folderOutput = $repo | Get-GitHubContent
        }

        It "Should have the expected name" {
            $folderOutput.name | Should -BeNullOrEmpty
        }

        It "Should have the expected path" {
            $folderOutput.path | Should -BeNullOrEmpty
        }

        It "Should have the expected type" {
            $folderOutput.type | Should -Be "dir"
        }

        It "Should have the expected entries" {
            $folderOutput.entries.length | Should -Be 1
        }

        It "Should have the expected entry data" {
            $folderOutput.entries[0].name | Should -Be $readmeFileName
            $folderOutput.entries[0].path | Should -Be $readmeFileName
        }

        It "Should have the expected type" {
            $folderOutput.PSObject.TypeNames[0] | Should -Be 'GitHub.Content'
            $folderOutput.RepositoryUrl | Should -Be $repo.RepositoryUrl
        }
    }

    Context 'For getting raw (byte) file contents' {
        BeforeAll {
            $readmeFileBytes = Get-GitHubContent -OwnerName $script:ownerName -RepositoryName $repo.name -Path $readmeFileName -MediaType Raw
            $readmeFileString = [System.Text.Encoding]::UTF8.GetString($readmeFileBytes)
        }

        It "Should have the expected content" {
            $readmeFileString | Should -Be $rawOutput
        }

        It "Should have the expected type" {
            $readmeFileString.PSObject.TypeNames[0] | Should -Not -Be 'GitHub.Content'
            $readmeFileString.RepositoryUrl | Should -BeNullOrEmpty
        }
    }

    Context 'For getting raw (string) file contents' {
        BeforeAll {
            $readmeFileString = Get-GitHubContent -OwnerName $script:ownerName -RepositoryName $repo.name -Path $readmeFileName -MediaType Raw -ResultAsString
        }

        It "Should have the expected content" {
            $readmeFileString | Should -Be $rawOutput
        }

        It "Should have the expected type" {
            $readmeFileString.PSObject.TypeNames[0] | Should -Not -Be 'GitHub.Content'
            $readmeFileString.RepositoryUrl | Should -BeNullOrEmpty
        }
    }

    Context 'For getting html (byte) file contents' {
        BeforeAll {
            $readmeFileBytes = Get-GitHubContent -OwnerName $script:ownerName -RepositoryName $repo.name -Path $readmeFileName -MediaType Html
            $readmeFileString = [System.Text.Encoding]::UTF8.GetString($readmeFileBytes)

            # Replace newlines with empty for comparison purposes
            $readmeNoBreaks = $readmeFileString.Replace("`n", "").Replace("`r", "")
        }

        It "Should have the expected content" {
            # GitHub changes the syntax for this file too frequently, so we'll just do some
            # partial matches to make sure we're getting HTML output for the right repo.
            $readmeNoBreaks.StartsWith($htmlOutputStart) | Should -BeTrue
            $readmeNoBreaks.IndexOf($repoGuid) | Should -BeGreaterOrEqual 0
        }

        It "Should have the expected type" {
            $readmeNoBreaks.PSObject.TypeNames[0] | Should -Not -Be 'GitHub.Content'
            $readmeNoBreaks.RepositoryUrl | Should -BeNullOrEmpty
        }
    }

    Context 'For getting html (string) file contents' {
        BeforeAll {
            $readmeFileString = Get-GitHubContent -OwnerName $script:ownerName -RepositoryName $repo.name -Path $readmeFileName -MediaType Html -ResultAsString

            # Replace newlines with empty for comparison purposes
            $readmeNoBreaks = $readmeFileString.Replace("`n", "").Replace("`r", "")
        }

        It "Should have the expected content" {
            # GitHub changes the syntax for this file too frequently, so we'll just do some
            # partial matches to make sure we're getting HTML output for the right repo.
            $readmeNoBreaks.StartsWith($htmlOutputStart) | Should -BeTrue
            $readmeNoBreaks.IndexOf($repoGuid) | Should -BeGreaterOrEqual 0
        }

        It "Should have the expected type" {
            $readmeFileString.PSObject.TypeNames[0] | Should -Not -Be 'GitHub.Content'
            $readmeFileString.RepositoryUrl | Should -BeNullOrEmpty
        }
    }

    Context 'For getting object (default) file result' {
        BeforeAll {
            $readmeFileObject = Get-GitHubContent -OwnerName $script:ownerName -RepositoryName $repo.name -Path $readmeFileName
        }

        It "Should have the expected name" {
            $readmeFileObject.name | Should -Be $readmeFileName
        }

        It "Should have the expected path" {
            $readmeFileObject.path | Should -Be $readmeFileName
        }

        It "Should have the expected type" {
            $readmeFileObject.type | Should -Be "file"
        }

        It "Should have the expected encoding" {
            $readmeFileObject.encoding | Should -Be "base64"
        }

        It "Should have the expected content" {
            # Convert from base64
            $readmeFileString = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($readmeFileObject.content))
            $readmeFileString | Should -Be $rawOutput
        }

        It "Should have the expected type" {
            $readmeFileObject.PSObject.TypeNames[0] | Should -Be 'GitHub.Content'
            $readmeFileObject.RepositoryUrl | Should -Be $repo.RepositoryUrl
        }
    }

    Context 'For getting object file result as string' {
        BeforeAll {
            $readmeFileObject = Get-GitHubContent -OwnerName $script:ownerName -RepositoryName $repo.name -Path $readmeFileName -MediaType Object -ResultAsString
        }

        It "Should have the expected name" {
            $readmeFileObject.name | Should -Be $readmeFileName
        }
        It "Should have the expected path" {
            $readmeFileObject.path | Should -Be $readmeFileName
        }
        It "Should have the expected type" {
            $readmeFileObject.type | Should -Be "file"
        }
        It "Should have the expected encoding" {
            $readmeFileObject.encoding | Should -Be "base64"
        }

        It "Should have the expected content" {
            $readmeFileObject.contentAsString | Should -Be $rawOutput
        }

        It "Should have the expected type" {
            $readmeFileObject.PSObject.TypeNames[0] | Should -Be 'GitHub.Content'
            $readmeFileObject.RepositoryUrl | Should -Be $repo.RepositoryUrl
        }
    }
}

Describe 'GitHubContents/Set-GitHubContent' {
    BeforeAll {
        $repoName = [Guid]::NewGuid().Guid
        $repo = New-GitHubRepository -RepositoryName $repoName -AutoInit

        $filePath = 'notes'
        $fileName = 'hello.txt'
        $commitMessage = 'Commit Message 2'
        $content = 'This is the new content for test.txt'
        $branchName = 'master'
        $committerName = 'John Doe'
        $committerEmail = 'john.doe@testdomain.com'
        $authorName = 'Jane Doe'
        $authorEmail = 'jane.doe@testdomain.com'
    }

    Context 'When setting new file content' {
        BeforeAll {
            $setGitHubContentParms = @{
                Path = "$filePath/$fileName"
                CommitMessage = $commitMessage
                Branch = $branchName
                Content = $content
                Uri = $repo.svn_url
                CommitterName = $committerName
                CommitterEmail = $committerEmail
                authorName = $authorName
                authorEmail = $authorEmail
            }

            $result = Set-GitHubContent @setGitHubContentParms -PassThru
        }

        It 'Should have the expected type and additional properties' {
            $result.PSObject.TypeNames[0] | Should -Be 'GitHub.Content'
            $result.content.name | Should -Be $fileName
            $result.content.path | Should -Be "$filePath/$fileName"
            $result.content.url | Should -Be ("https://api.github.com/repos/$($script:ownerName)" +
                "/$repoName/contents/$filePath/$($fileName)?ref=$BranchName")
            $result.commit.author.name | Should -Be $authorName
            $result.commit.author.email | Should -Be $authorEmail
            $result.commit.committer.name | Should -Be $committerName
            $result.commit.committer.email | Should -Be $committerEmail
            $result.commit.message | Should -Be $commitMessage
        }

        It 'Should have written the correct content' {
            $getGitHubContentParms = @{
                Path = "$filePath/$fileName"
                Uri = $repo.svn_url
                MediaType = 'Raw'
                ResultAsString = $true
            }

            $writtenContent = Get-GitHubContent @getGitHubContentParms

            $content | Should -Be $writtenContent
        }

        It 'Should support pipeline input' {
            $getGitHubContentParms = @{
                Path = "$filePath/$fileName"
                Uri = $repo.svn_url
            }

            $writtenContent = Get-GitHubContent @getGitHubContentParms

            $setGitHubContentParms = @{
                CommitMessage = $commitMessage
                Content = $content
                CommitterName = $committerName
                CommitterEmail = $committerEmail
                authorName = $authorName
                authorEmail = $authorEmail
            }

            { $writtenContent | Set-GitHubContent @setGitHubContentParms -WhatIf } | Should -Not -Throw
        }
    }

    Context 'When overwriting file content' {
        BeforeAll {
            $setGitHubContentParms = @{
                Path = "$filePath/$fileName"
                CommitMessage = $commitMessage
                BranchName = $branchName
                Content = $content
                Uri = $repo.svn_url
                CommitterName = $committerName
                CommitterEmail = $committerEmail
                authorName = $authorName
                authorEmail = $authorEmail
            }

            $result = Set-GitHubContent @setGitHubContentParms -PassThru
        }

        It 'Should have the expected type and additional properties' {
            $result.PSObject.TypeNames[0] | Should -Be 'GitHub.Content'
            $result.content.name | Should -Be $fileName
            $result.content.path | Should -Be "$filePath/$fileName"
            $result.content.url | Should -Be ("https://api.github.com/repos/$($script:ownerName)" +
                "/$repoName/contents/$filePath/$($fileName)?ref=$BranchName")
            $result.commit.author.name | Should -Be $authorName
            $result.commit.author.email | Should -Be $authorEmail
            $result.commit.committer.name | Should -Be $committerName
            $result.commit.committer.email | Should -Be $committerEmail
            $result.commit.message | Should -Be $commitMessage
        }

        It 'Should have written the correct content' {
            $getGitHubContentParms = @{
                Path = "$filePath/$fileName"
                Uri = $repo.svn_url
                MediaType = 'Raw'
                ResultAsString = $true
            }

            $writtenContent = Get-GitHubContent @getGitHubContentParms

            $content | Should -Be $writtenContent
        }
    }

    Context 'When Specifying only one Committer parameter' {
        BeforeAll {
            $setGitHubContentParms = @{
                Path = "$filePath/$fileName"
                CommitMessage = $commitMessage
                BranchName = $branchName
                Content = $content
                Uri = $repo.svn_url
                CommitterName = $committerName
            }
        }

        It 'Shoud throw the correct exception' {
            $errorMessage = 'Both CommiterName and CommitterEmail need to be specified.'
            { Set-GitHubContent @setGitHubContentParms } | Should -Throw $errorMessage
        }
    }

    Context 'When Specifying only one Author parameter' {
        BeforeAll {
            $setGitHubContentParms = @{
                Path = "$filePath/$fileName"
                Uri = $repo.svn_url
                CommitMessage = $commitMessage
                BranchName = $branchName
                Content = $content
                AuthorName = $authorName
            }
        }

        It 'Shoud throw the correct exception' {
            $errorMessage = 'Both AuthorName and AuthorEmail need to be specified.'
            { Set-GitHubContent @setGitHubContentParms } | Should -Throw $errorMessage
        }
    }

    Context 'When Invoke-GHRestMethod returns an unexpected error' {
        It 'Should throw' {
            $setGitHubContentParms = @{
                Path = "$filePath/$fileName"
                OwnerName = $script:ownerName
                RepositoryName = 'IncorrectRepositoryName'
                BranchName = $branchName
                CommitMessage = $commitMessage
                Content = $content
            }

            { Set-GitHubContent @setGitHubContentParms } | Should -Throw
        }
    }

    AfterAll {
        Remove-GitHubRepository -Uri $repo.svn_url -Force
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
