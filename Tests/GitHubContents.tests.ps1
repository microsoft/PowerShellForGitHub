# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

<#
.Synopsis
   Tests for GitHubContents.ps1 module
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

    Describe 'Getting file and folder content' {
        # AutoInit will create a readme with the GUID of the repo name
        $repo = New-GitHubRepository -RepositoryName ($repoGuid) -AutoInit

        Context 'For getting folder contents' {

            $folderOutput = Get-GitHubContent -OwnerName $script:ownerName -RepositoryName $repo.name

            It "Should have the expected name" {
                $folderOutput.name | Should -Be ""
            }
            It "Should have the expected path" {
                $folderOutput.path | Should -Be ""
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
        }

        Context 'For getting folder contents via URL' {

            $folderOutput = Get-GitHubContent -Uri "https://github.com/$($script:ownerName)/$($repo.name)"

            It "Should have the expected name" {
                $folderOutput.name | Should -Be ""
            }
            It "Should have the expected path" {
                $folderOutput.path | Should -Be ""
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
        }

        Context 'For getting raw (byte) file contents' {

            $readmeFileBytes = Get-GitHubContent -OwnerName $script:ownerName -RepositoryName $repo.name -Path $readmeFileName -MediaType Raw
            $readmeFileString = [System.Text.Encoding]::UTF8.GetString($readmeFileBytes)

            It "Should have the expected content" {
                $readmeFileString | Should -Be $rawOutput
            }
        }

        Context 'For getting raw (string) file contents' {

            $readmeFileString = Get-GitHubContent -OwnerName $script:ownerName -RepositoryName $repo.name -Path $readmeFileName -MediaType Raw -ResultAsString

            It "Should have the expected content" {
                $readmeFileString | Should -Be $rawOutput
            }
        }

        Context 'For getting html (byte) file contents' {

            $readmeFileBytes = Get-GitHubContent -OwnerName $script:ownerName -RepositoryName $repo.name -Path $readmeFileName -MediaType Html
            $readmeFileString = [System.Text.Encoding]::UTF8.GetString($readmeFileBytes)

            # Replace newlines with empty for comparison purposes
            $readmeNoBreaks = $readmeFileString.Replace("`n", "").Replace("`r", "")
            It "Should have the expected content" {
                # GitHub changes the syntax for this file too frequently, so we'll just do some
                # partial matches to make sure we're getting HTML output for the right repo.
                $readmeNoBreaks.StartsWith($htmlOutputStart) | Should -BeTrue
                $readmeNoBreaks.IndexOf($repoGuid) | Should -BeGreaterOrEqual 0
            }
        }

        Context 'For getting html (string) file contents' {

            $readmeFileString = Get-GitHubContent -OwnerName $script:ownerName -RepositoryName $repo.name -Path $readmeFileName -MediaType Html -ResultAsString

            # Replace newlines with empty for comparison purposes
            $readmeNoBreaks = $readmeFileString.Replace("`n", "").Replace("`r", "")
            It "Should have the expected content" {
                # GitHub changes the syntax for this file too frequently, so we'll just do some
                # partial matches to make sure we're getting HTML output for the right repo.
                $readmeNoBreaks.StartsWith($htmlOutputStart) | Should -BeTrue
                $readmeNoBreaks.IndexOf($repoGuid) | Should -BeGreaterOrEqual 0
            }
        }

        Context 'For getting object (default) file result' {

            $readmeFileObject = Get-GitHubContent -OwnerName $script:ownerName -RepositoryName $repo.name -Path $readmeFileName

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
        }

        Context 'For getting object file result as string' {

            $readmeFileObject = Get-GitHubContent -OwnerName $script:ownerName -RepositoryName $repo.name -Path $readmeFileName -MediaType Object -ResultAsString

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
        }

        Remove-GitHubRepository -Uri $repo.svn_url -Confirm:$false
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
