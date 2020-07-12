# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

<#
.Synopsis
   Tests for GitHubGistCommentss.ps1 module
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
    Describe 'New-GitHubGistComment' {
        Context 'By parameters' {
            BeforeAll {
                $tempFile = New-TemporaryFile
                $fileA = "$($tempFile.FullName).ps1"
                Move-Item -Path $tempFile -Destination $fileA
                Out-File -FilePath $fileA -InputObject "fileA content" -Encoding utf8

                $tempFile = New-TemporaryFile
                $fileB = "$($tempFile.FullName).txt"
                Move-Item -Path $tempFile -Destination $fileB
                Out-File -FilePath $fileB -InputObject "fileB content" -Encoding utf8

                $description = 'my description'
            }

            AfterAll {
                @($fileA, $fileB) | Remove-Item -Force -ErrorAction SilentlyContinue | Out-Null
            }

            $gist = New-GitHubGist -File $fileA -Description $description -Public
            It 'Should have the expected result' {

            }

            It 'Should have the expected type and additional properties' {
                $comment.PSObject.TypeNames[0] | Should -Be 'GitHub.GistComment'
                $comment.GistCommentId | Should -Be $comment.id
                $comment.GistId | Should -Be $gist.id
                $comment.user.PSObject.TypeNames[0] | Should -Be 'GitHub.User'
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
