# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

<#
.Synopsis
   Tests for GitHubGists.ps1 module
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
    Describe 'Get-GitHubGist' {
        Context 'Specific Gist' {
        }

        Context 'Specific Gist with Sha' {
        }

        Context 'Forks' {
            # Make sure you check for error when Sha specified
        }

        Context 'Commits' {
            # Make sure you check for error when Sha specified
        }

        Context 'All gists for a specific user' {
        }

        Context 'All starred gists for a specific user' {
        }

        Context 'All gists for the current authenticated user' {
        }

        Context 'All gists for the current authenticated user, but not authenticated' {
        }

        Context 'All starred gists for the current authenticated user, but not authenticated' {
        }

        Context 'All public gists' {
        }
    }

    Describe 'Get-GitHubGist' {
        Context 'By files' {
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
                $gist.PSObject.TypeNames[0] | Should -Be 'GitHub.Gist'
                $gist.GistId | Should -Be $gist.id
                $gist.owner.PSObject.TypeNames[0] | Should -Be 'GitHub.User'
            }
        }
    }

    Describe 'Remove-GitHubGist' {
        Context 'By files' {
            BeforeAll {
            }

            AfterAll {
            }
        }
    }

    Describe 'Copy-GitHubGist' {
        BeforeAll {
            $originalGist = Get-GitHubGist -Gist '1169852' # octocat/test.cs
        }

        Context 'By parameters' {
            $gist = Copy-GitHubGist -Gist $originalGist.id
            It 'Should have been forked' {
                $gist.files.Count | Should -Be $originalGist.files.Count
                foreach ($file in $gist.files)
                {
                    $originalFile = $originalGist.files |
                        Where-Object { $_.filename -eq $file.filename }
                    $file.filename | Should -Be $originalFile.filename
                    $file.size | Should -Be $originalFile.size
                }
            }

            It 'Should have the expected additional type and properties' {
                $gist.PSObject.TypeNames[0] | Should -Be 'GitHub.Gist'
                $gist.GistId | Should -Be $gist.id
                $gist.owner.PSObject.TypeNames[0] | Should -Be 'GitHub.User'
            }

            It 'Should be removed' {
                { Remove-GitHubGist -Gist $gist.id -Force } | Should -Not -Throw
            }
        }

        Context 'Gist on the pipeline' {
            $gist = $originalGist | Copy-GitHubGist
            It 'Should have been forked' {
                $gist.files.Count | Should -Be $originalGist.files.Count
                foreach ($file in $gist.files)
                {
                    $originalFile = $originalGist.files |
                        Where-Object { $_.filename -eq $file.filename }
                    $file.filename | Should -Be $originalFile.filename
                    $file.size | Should -Be $originalFile.size
                }
            }

            It 'Should have the expected additional type and properties' {
                $gist.PSObject.TypeNames[0] | Should -Be 'GitHub.Gist'
                $gist.GistId | Should -Be $gist.id
                $gist.owner.PSObject.TypeNames[0] | Should -Be 'GitHub.User'
            }

            It 'Should be removed' {
                { $gist | Remove-GitHubGist -Force } | Should -Not -Throw
            }
        }
    }

    Describe 'Add/Remove/Test-GitHubGistStar' {
        BeforeAll {
            $gist = New-GitHubGist -Content 'Sample text' -Filename 'sample.txt'
        }

        AfterAll {
            $gist | Remove-GitHubGist -Force
        }

        Context 'With parameters' {
            $starred = Test-GitHubGistStar -Gist $gist.id
            It 'Should not be starred yet' {
                $starred | Should -BeFalse
            }

            Add-GitHubGistStar -Gist $gist.id
            $starred = Test-GitHubGistStar -Gist $gist.id
            It 'Should now be starred yet' {
                $starred | Should -BeTrue
            }

            $starred = Test-GitHubGistStar -Gist $gist.id
            It 'Should not be starred yet' {
                $starred | Should -BeTrue
            }

            Remove-GitHubGistStar -Gist $gist.id
            $starred = Test-GitHubGistStar -Gist $gist.id
            It 'Should no longer be starred yet' {
                $starred | Should -BeFalse
            }
        }

        Context 'With the gist on the pipeline' {
            $starred = $gist | Test-GitHubGistStar
            It 'Should not be starred yet' {
                $starred | Should -BeFalse
            }

            $gist | Add-GitHubGistStar
            $starred = $gist | Test-GitHubGistStar
            It 'Should now be starred yet' {
                $starred | Should -BeTrue
            }

            $starred = $gist | Test-GitHubGistStar
            It 'Should not be starred yet' {
                $starred | Should -BeTrue
            }

            $gist | Remove-GitHubGistStar
            $starred = $gist | Test-GitHubGistStar
            It 'Should no longer be starred yet' {
                $starred | Should -BeFalse
            }
        }
    }

    Describe 'New-GitHubGist' {
        Context 'By files' {
            BeforeAll {
            }

            AfterAll {
            }
        }
    }

    Describe 'Set-GitHubGist' {
        Context 'By files' {
            BeforeAll {
            }

            AfterAll {
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
