# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

<#
.Synopsis
   Tests for GitHubGistCommentss.ps1 module
#>

[CmdletBinding()]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '',
    Justification = 'Suppress false positives in Pester code blocks')]
param()

BeforeAll {
    # This is common test code setup logic for all Pester test files
    $moduleRootPath = Split-Path -Path $PSScriptRoot -Parent
    . (Join-Path -Path $moduleRootPath -ChildPath 'Tests\Common.ps1')
}

Describe 'Get-GitHubGistComment' {
    BeforeAll {
        $body = 'Comment body'
    }

    Context 'By parameters' {
        BeforeAll {
            $gist = New-GitHubGist -FileName 'sample.txt' -Content 'Sample text'
            $body = 'Comment body'
        }

        AfterAll {
            $gist | Remove-GitHubGist -Force
        }

        It 'Should have no comments so far' {
            $comments = @(Get-GitHubGistComment -Gist $gist.id -MediaType 'Raw')
            $comments.Count | Should -Be 0
        }

        Context 'Add comment to Gist' {
            BeforeAll {
                $firstComment = New-GitHubGistComment -Gist $gist.id -Body $body
                $comments = @(Get-GitHubGistComment -Gist $gist.id -MediaType 'Text')
            }
            It 'Should have one comments so far' {
                $comments.Count | Should -Be 1
                $comments[0].id | Should -Be $firstComment.id
                $comments[0].body | Should -BeNullOrEmpty
                $comments[0].body_html | Should -BeNullOrEmpty
                $comments[0].body_text | Should -Not -BeNullOrEmpty
            }

            It 'Should have the expected type and additional properties' {
                $comments[0].PSObject.TypeNames[0] | Should -Be 'GitHub.GistComment'
                $comments[0].GistCommentId | Should -Be $comments[0].id
                $comments[0].GistId | Should -Be $gist.id
                $comments[0].user.PSObject.TypeNames[0] | Should -Be 'GitHub.User'
            }

            Context 'Add second comment to gist' {
                BeforeAll {
                    $null = New-GitHubGistComment -Gist $gist.id -Body $body
                    $comments = @(Get-GitHubGistComment -Gist $gist.id -MediaType 'Html')
                }
                It 'Should have one comments so far' {
                    $comments.Count | Should -Be 2
                    foreach ($comment in $comments)
                    {
                        $comment.body | Should -BeNullOrEmpty
                        $comment.body_html | Should -Not -BeNullOrEmpty
                        $comment.body_text | Should -BeNullOrEmpty
                    }
                }

                It 'Should have the expected type and additional properties' {
                    foreach ($comment in $comments)
                    {
                        $comment.PSObject.TypeNames[0] | Should -Be 'GitHub.GistComment'
                        $comment.GistCommentId | Should -Be $comment.id
                        $comment.GistId | Should -Be $gist.id
                        $comment.user.PSObject.TypeNames[0] | Should -Be 'GitHub.User'
                    }
                }
            }

            Context 'Retrieve a specific comment' {
                BeforeAll {
                    $comment = Get-GitHubGistComment -Gist $gist.id -Comment $firstComment.id -MediaType 'Html'
                }
                It 'Should retrieve the specific comment' {
                    $comment.id | Should -Be $firstComment.id
                    $comment.body | Should -BeNullOrEmpty
                    $comment.body_html | Should -Not -BeNullOrEmpty
                    $comment.body_text | Should -BeNullOrEmpty
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

    Context 'Gist on the pipeline' {
        BeforeAll {
            $gist = New-GitHubGist -FileName 'sample.txt' -Content 'Sample text'
            $body = 'Comment body'
        }

        AfterAll {
            $gist | Remove-GitHubGist -Force
        }

        It 'Should have no comments so far' {
            $comments = @(Get-GitHubGistComment -Gist $gist.id -MediaType 'Text')
            $comments.Count | Should -Be 0
        }

        Context 'Create first comment' {
            BeforeAll {
                $firstComment = $gist | New-GitHubGistComment -Body $body
            }

            It 'Should have one comments so far' {
                $comments = @($gist | Get-GitHubGistComment -MediaType 'Raw')
                $comments.Count | Should -Be 1
                $comments[0].id | Should -Be $firstComment.id
                $comments[0].body | Should -Not -BeNullOrEmpty
                $comments[0].body_html | Should -BeNullOrEmpty
                $comments[0].body_text | Should -BeNullOrEmpty
            }

            It 'Should have the expected type and additional properties' {
                $comments = @($gist | Get-GitHubGistComment -MediaType 'Raw')
                $comments[0].PSObject.TypeNames[0] | Should -Be 'GitHub.GistComment'
                $comments[0].GistCommentId | Should -Be $comments[0].id
                $comments[0].GistId | Should -Be $gist.id
                $comments[0].user.PSObject.TypeNames[0] | Should -Be 'GitHub.User'
            }

            Context 'Add second comment' {
                BeforeAll {
                    $null = $gist | New-GitHubGistComment -Body $body
                }
                It 'Should have one comments so far' {
                    $comments = @($gist | Get-GitHubGistComment -MediaType 'Full')
                    $comments.Count | Should -Be 2
                    foreach ($comment in $comments)
                    {
                        $comment.body | Should -Not -BeNullOrEmpty
                        $comment.body_html | Should -Not -BeNullOrEmpty
                        $comment.body_text | Should -Not -BeNullOrEmpty
                    }
                }

                It 'Should have the expected type and additional properties' {
                    $comments = @($gist | Get-GitHubGistComment -MediaType 'Full')
                    foreach ($comment in $comments)
                    {
                        $comment.PSObject.TypeNames[0] | Should -Be 'GitHub.GistComment'
                        $comment.GistCommentId | Should -Be $comment.id
                        $comment.GistId | Should -Be $gist.id
                        $comment.user.PSObject.TypeNames[0] | Should -Be 'GitHub.User'
                    }
                }
            }

            It 'Should retrieve the specific comment' {
                $comment = Get-GitHubGistComment -Gist $gist.id -Comment $firstComment.id -MediaType 'Html'
                $comment.id | Should -Be $firstComment.id
                $comment.body | Should -BeNullOrEmpty
                $comment.body_html | Should -Not -BeNullOrEmpty
                $comment.body_text | Should -BeNullOrEmpty
            }

            It 'Should have the expected type and additional properties' {
                $comment = Get-GitHubGistComment -Gist $gist.id -Comment $firstComment.id -MediaType 'Html'
                $comment.PSObject.TypeNames[0] | Should -Be 'GitHub.GistComment'
                $comment.GistCommentId | Should -Be $comment.id
                $comment.GistId | Should -Be $gist.id
                $comment.user.PSObject.TypeNames[0] | Should -Be 'GitHub.User'
            }

            It 'Should retrieve the specific comment with the comment on the pipeline' {
                $comment = $firstComment | Get-GitHubGistComment -MediaType 'Html'
                $comment.id | Should -Be $firstComment.id
                $comment.body | Should -BeNullOrEmpty
                $comment.body_html | Should -Not -BeNullOrEmpty
                $comment.body_text | Should -BeNullOrEmpty
            }

            It 'Should have the expected type and additional properties' {
                $comment = $firstComment | Get-GitHubGistComment -MediaType 'Html'
                $comment.PSObject.TypeNames[0] | Should -Be 'GitHub.GistComment'
                $comment.GistCommentId | Should -Be $comment.id
                $comment.GistId | Should -Be $gist.id
                $comment.user.PSObject.TypeNames[0] | Should -Be 'GitHub.User'
            }
        }
    }
}

Describe 'New-GitHubGistComment' {
    BeforeAll {
        $gist = New-GitHubGist -FileName 'sample.txt' -Content 'Sample text'
        $body = 'Comment body'
    }

    AfterAll {
        $gist | Remove-GitHubGist -Force
    }

    Context 'By parameters' {
        BeforeAll {
            $comment = New-GitHubGistComment -Gist $gist.id -Body $body
        }
        It 'Should have the expected result' {
            $comment.body | Should -Be $body
        }

        It 'Should have the expected type and additional properties' {
            $comment.PSObject.TypeNames[0] | Should -Be 'GitHub.GistComment'
            $comment.GistCommentId | Should -Be $comment.id
            $comment.GistId | Should -Be $gist.id
            $comment.user.PSObject.TypeNames[0] | Should -Be 'GitHub.User'
        }
    }

    Context 'Gist on the pipeline' {
        BeforeAll {
            $comment = $gist | New-GitHubGistComment -Body $body
        }
        It 'Should have the expected result' {
            $comment.body | Should -Be $body
        }

        It 'Should have the expected type and additional properties' {
            $comment.PSObject.TypeNames[0] | Should -Be 'GitHub.GistComment'
            $comment.GistCommentId | Should -Be $comment.id
            $comment.GistId | Should -Be $gist.id
            $comment.user.PSObject.TypeNames[0] | Should -Be 'GitHub.User'
        }
    }
}

Describe 'New-GitHubGistComment' {
    BeforeAll {
        $gist = New-GitHubGist -Filename 'sample.txt' -Content 'Sample text'
        $body = 'Comment body'
        $updatedBody = 'Updated comment body'
    }

    AfterAll {
        $gist | Remove-GitHubGist -Force
    }

    Context 'By parameters' {
        BeforeAll {
            $comment = New-GitHubGistComment -Gist $gist.id -Body $body
        }
        It 'Should have the expected result' {
            $comment.body | Should -Be $body
        }

        It 'Should have the expected result' {
            $comment = Set-GitHubGistComment -Gist $gist.id -Comment $comment.id -Body $updatedBody -PassThru
            $comment.body | Should -Be $updatedBody
        }

        It 'Should have the expected type and additional properties' {
            $comment = Set-GitHubGistComment -Gist $gist.id -Comment $comment.id -Body $updatedBody -PassThru
            $comment.PSObject.TypeNames[0] | Should -Be 'GitHub.GistComment'
            $comment.GistCommentId | Should -Be $comment.id
            $comment.GistId | Should -Be $gist.id
            $comment.user.PSObject.TypeNames[0] | Should -Be 'GitHub.User'
        }
    }

    Context 'Gist on the pipeline' {
        BeforeAll {
            $comment = $gist | New-GitHubGistComment -Body $body
        }
        It 'Should have the expected result' {
            $comment.body | Should -Be $body
        }

        It 'Should have the expected result' {
            $comment = $gist | Set-GitHubGistComment -Comment $comment.id -Body $updatedBody -PassThru
            $comment.body | Should -Be $updatedBody
        }

        It 'Should have the expected type and additional properties' {
            $comment = $gist | Set-GitHubGistComment -Comment $comment.id -Body $updatedBody -PassThru
            $comment.PSObject.TypeNames[0] | Should -Be 'GitHub.GistComment'
            $comment.GistCommentId | Should -Be $comment.id
            $comment.GistId | Should -Be $gist.id
            $comment.user.PSObject.TypeNames[0] | Should -Be 'GitHub.User'
        }
    }

    Context 'Gist Comment on the pipeline' {
        BeforeAll {
            $comment = $gist | New-GitHubGistComment -Body $body
        }
        It 'Should have the expected result' {
            $comment.body | Should -Be $body
        }

        It 'Should have the expected result' {
            $comment = $comment | Set-GitHubGistComment -Body $updatedBody -PassThru
            $comment.body | Should -Be $updatedBody
        }

        It 'Should have the expected type and additional properties' {
            $comment = $comment | Set-GitHubGistComment -Body $updatedBody -PassThru
            $comment.PSObject.TypeNames[0] | Should -Be 'GitHub.GistComment'
            $comment.GistCommentId | Should -Be $comment.id
            $comment.GistId | Should -Be $gist.id
            $comment.user.PSObject.TypeNames[0] | Should -Be 'GitHub.User'
        }
    }
}

Describe 'Remove-GitHubGistComment' {
    BeforeAll {
        $gist = New-GitHubGist -FileName 'sample.txt' -Content 'Sample text'
        $body = 'Comment body'
    }

    AfterAll {
        $gist | Remove-GitHubGist -Force
    }

    Context 'By parameters' {
        It 'Should be gone' {
            $comment = New-GitHubGistComment -Gist $gist.id -Body $body

            Remove-GitHubGistComment -Gist $gist.id -Comment $comment.id -Force
            { Get-GitHubGistComment -Gist $gist.id -Comment $comment.id } | Should -Throw
        }
    }

    Context 'Gist on the pipeline' {
        It 'Should be gone' {
            $comment = $gist | New-GitHubGistComment -Body $body

            $gist | Remove-GitHubGistComment -Comment $comment.id -Force
            { $gist | Get-GitHubGistComment -Comment $comment.id } | Should -Throw
        }
    }

    Context 'Gist Comment on the pipeline' {
        It 'Should be gone' {
            $comment = $gist | New-GitHubGistComment -Body $body

            $comment | Remove-GitHubGistComment -Force
            { $comment | Get-GitHubGistComment } | Should -Throw
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
