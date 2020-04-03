# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

<#
.Synopsis
   Tests for GitHubContents.ps1 module
#>

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
        htmlOutput = "<div id=`"file`" class=`"md`" data-path=`"README.md`"><article class=`"markdown-body entry-content`" itemprop=`"text`"><h1><a id=`"user-content-$repoGuid`" class=`"anchor`" aria-hidden=`"true`" href=`"#$repoGuid`"><svg class=`"octicon octicon-link`" viewBox=`"0 0 16 16`" version=`"1.1`" width=`"16`" height=`"16`" aria-hidden=`"true`"><path fill-rule=`"evenodd`" d=`"M4 9h1v1H4c-1.5 0-3-1.69-3-3.5S2.55 3 4 3h4c1.45 0 3 1.69 3 3.5 0 1.41-.91 2.72-2 3.25V8.59c.58-.45 1-1.27 1-2.09C10 5.22 8.98 4 8 4H4c-.98 0-2 1.22-2 2.5S3 9 4 9zm9-3h-1v1h1c1 0 2 1.22 2 2.5S13.98 12 13 12H9c-.98 0-2-1.22-2-2.5 0-.83.42-1.64 1-2.09V6.25c-1.09.53-2 1.84-2 3.25C6 11.31 7.55 13 9 13h4c1.45 0 3-1.69 3-3.5S14.5 6 13 6z`"></path></svg></a>$repoGuid</h1></article></div>"
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
                $folderOutput.name | Should be ""
            }
            It "Should have the expected path" {
                $folderOutput.path | Should be ""
            }
            It "Should have the expected type" {
                $folderOutput.type | Should be "dir"
            }
            It "Should have the expected entries" {
                $folderOutput.entries.length | Should be 1
            }
            It "Should have the expected entry data" {
                $folderOutput.entries[0].name | Should be $readmeFileName
                $folderOutput.entries[0].path | Should be $readmeFileName
            }
        }

        Context 'For getting folder contents via URL' {

            $folderOutput = Get-GitHubContent -Uri "https://github.com/$($script:ownerName)/$($repo.name)"

            It "Should have the expected name" {
                $folderOutput.name | Should be ""
            }
            It "Should have the expected path" {
                $folderOutput.path | Should be ""
            }
            It "Should have the expected type" {
                $folderOutput.type | Should be "dir"
            }
            It "Should have the expected entries" {
                $folderOutput.entries.length | Should be 1
            }
            It "Should have the expected entry data" {
                $folderOutput.entries[0].name | Should be $readmeFileName
                $folderOutput.entries[0].path | Should be $readmeFileName
            }
        }

        Context 'For getting raw (byte) file contents' {

            $readmeFileBytes = Get-GitHubContent -OwnerName $script:ownerName -RepositoryName $repo.name -Path $readmeFileName -MediaType Raw
            $readmeFileString = [System.Text.Encoding]::UTF8.GetString($readmeFileBytes)

            It "Should have the expected content" {
                $readmeFileString | Should be $rawOutput
            }
        }

        Context 'For getting raw (string) file contents' {

            $readmeFileString = Get-GitHubContent -OwnerName $script:ownerName -RepositoryName $repo.name -Path $readmeFileName -MediaType Raw -ResultAsString

            It "Should have the expected content" {
                $readmeFileString | Should be $rawOutput
            }
        }

        Context 'For getting html (byte) file contents' {

            $readmeFileBytes = Get-GitHubContent -OwnerName $script:ownerName -RepositoryName $repo.name -Path $readmeFileName -MediaType Html
            $readmeFileString = [System.Text.Encoding]::UTF8.GetString($readmeFileBytes)

            It "Should have the expected content" {
                # Replace newlines with empty for comparison
                $readmeFileString.Replace("`n", "").Replace("`r", "") | Should be $htmlOutput
            }
        }

        Context 'For getting html (string) file contents' {

            $readmeFileString = Get-GitHubContent -OwnerName $script:ownerName -RepositoryName $repo.name -Path $readmeFileName -MediaType Html -ResultAsString

            It "Should have the expected content" {
                # Replace newlines with empty for comparison
                $readmeFileString.Replace("`n", "").Replace("`r", "") | Should be $htmlOutput
            }
        }

        Context 'For getting object (default) file result' {

            $readmeFileObject = Get-GitHubContent -OwnerName $script:ownerName -RepositoryName $repo.name -Path $readmeFileName

            It "Should have the expected name" {
                $readmeFileObject.name | Should be $readmeFileName
            }
            It "Should have the expected path" {
                $readmeFileObject.path | Should be $readmeFileName
            }
            It "Should have the expected type" {
                $readmeFileObject.type | Should be "file"
            }
            It "Should have the expected encoding" {
                $readmeFileObject.encoding | Should be "base64"
            }

            It "Should have the expected content" {
                # Convert from base64
                $readmeFileString = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($readmeFileObject.content))
                $readmeFileString | Should be $rawOutput
            }
        }

        Context 'For getting object file result as string' {

            $readmeFileObject = Get-GitHubContent -OwnerName $script:ownerName -RepositoryName $repo.name -Path $readmeFileName -MediaType Object -ResultAsString

            It "Should have the expected name" {
                $readmeFileObject.name | Should be $readmeFileName
            }
            It "Should have the expected path" {
                $readmeFileObject.path | Should be $readmeFileName
            }
            It "Should have the expected type" {
                $readmeFileObject.type | Should be "file"
            }
            It "Should have the expected encoding" {
                $readmeFileObject.encoding | Should be "base64"
            }

            It "Should have the expected content" {
                $readmeFileObject.contentAsString | Should be $rawOutput
            }
        }

        Remove-GitHubRepository -Uri $repo.svn_url
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
