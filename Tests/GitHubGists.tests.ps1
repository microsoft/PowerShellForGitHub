# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

<#
.Synopsis
   Tests for GitHubGists.ps1 module
#>

[CmdletBinding()]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '',
    Justification = 'Suppress false positives in Pester code blocks')]
param()

BeforeAll {
    # This is common test code setup logic for all Pester test files
    $moduleRootPath = Split-Path -Path $PSScriptRoot -Parent
    . (Join-Path -Path $moduleRootPath -ChildPath 'Tests\Common.ps1')

    filter New-LargeFile
    {
        <#
    .SYNOPSIS
        Creates a large dummy file with random conntent

    .DESCRIPTION
        Creates a large dummy file with random conntent
        Credits for the random content creation logic goes to Robert Robelo

    .PARAMETER Path
        The full path to the file to create.

    .PARAMETER SizeMB
        The size of the random file to be genrated. Default is one MB

    .PARAMETER Type
        The type of file should be created.

    .PARAMETER Force
        Will allow this to overwrite the target file if it already exists.

    .EXAMPLE
        New-LargeFile -Path C:\Temp\LF\bigfile.txt -SizeMB 10
#>

        [CmdletBinding(SupportsShouldProcess)]
        param(
            [Parameter(ValueFromPipeline)]
            [String] $Path,

            [ValidateRange(1, 5120)]
            [UInt16] $SizeMB = 1,

            [ValidateSet('Text', 'Binary')]
            [string] $Type = 'Text',

            [switch] $Force
        )

        $tempFile = New-TemporaryFile

        if ($Type -eq 'Text')
        {
            $streamWriter = New-Object -TypeName IO.StreamWriter -ArgumentList ($tempFile)
            try
            {
                # get a 64 element Char[]; I added the - and \n to have 64 chars
                [char[]]$chars = 'azertyuiopqsdfghjklmwxcvbnAZERTYUIOPQSDFGHJKLMWXCVBN0123456789-\n'
                1..$SizeMB | ForEach-Object {
                    # get 1MB of chars from 4 256KB strings
                    1..4 | ForEach-Object {
                        $randomizedChars = $chars | Get-Random -Count $chars.Count

                        # repeat random string 4096 times to get a 256KB string
                        $output = (-join $randomizedChars) * 4kb

                        # write 256KB string to file
                        $streamWriter.Write($output)

                        # release resources
                        Clear-Variable -Name @('randomizedChars', 'output')
                    }
                }
            }
            catch
            {
                Remove-File -Path $tempFile -ErrorAction SilentlyContinue
            }
            finally
            {
                $streamWriter.Close()
                $streamWriter.Dispose()

                # Force the immediate garbage collection of allocated resources
                [GC]::Collect()
            }
        }
        else
        {
            $content = New-Object -TypeName Byte[] -ArgumentList ($SizeMB * 1mb)
        (New-Object -TypeName Random).NextBytes($content)
            [IO.File]::WriteAllBytes($tempFile, $content)
        }

        try
        {
            if ($PSBoundParameters.ContainsKey('Path'))
            {
                return (Move-Item -Path $tempFile -Destination $Path -Force:$Force)
            }
            else
            {
                return (Get-Item -Path $tempFile)
            }
        }
        catch
        {
            Remove-File -Path $tempFile -ErrorAction SilentlyContinue
        }
    }
}

Describe 'Get-GitHubGist' {
    Context 'Specific Gist' {
        BeforeAll {
            $id = '0831f3fbd83ac4d46451' # octocat/git-author-rewrite.sh
            $gist = Get-GitHubGist -Gist $id
        }

        It 'Should be the expected gist' {
            $gist.id | Should -Be $id
        }

        It 'Should have the expected type and additional properties' {
            $gist.PSObject.TypeNames[0] | Should -Be 'GitHub.Gist'
            $gist.GistId | Should -Be $gist.id
            $gist.owner.PSObject.TypeNames[0] | Should -Be 'GitHub.User'
            $gist.history[0].PSObject.TypeNames[0] | Should -Be 'GitHub.GistCommit'
            $gist.forks[0].PSObject.TypeNames[0] | Should -Be 'GitHub.GistFork'
        }

        It 'Should be the expected gist with the gist on the pipeline' {
            $gist = $gist | Get-GitHubGist
            $gist.id | Should -Be $id
        }
    }

    Context 'Commits and specific Gist with Sha' {
        BeforeAll {
            $id = '0831f3fbd83ac4d46451' # octocat/git-author-rewrite.sh

            $gist = Get-GitHubGist -Gist $id
            $commits = Get-GitHubGist -Gist $gist.id -Commits
            $oldestSha = $commits | Sort-Object -Property 'committed_at' | Select-Object -First 1
        }

        It 'Should have multiple commits' {
            $commits.Count | Should -BeGreaterThan 1
        }

        It 'Should have the expected type and additional properties' {
            foreach ($commit in $commits)
            {
                $commit.PSObject.TypeNames[0] | Should -Be 'GitHub.GistCommit'
                $commit.GistId | Should -Be $gist.id
                $commit.Sha | Should -Be $commit.version
                $commit.user.PSObject.TypeNames[0] | Should -Be 'GitHub.User'
            }
        }

        It 'Should be the expected commit' {
            $firstGistCommit = Get-GitHubGist -Gist $gist.id -Sha $oldestSha.version
            $firstGistCommit.created_at | Should -Be $oldestSha.committed_at
        }

        It 'Should have the expected type and additional properties' {
            $firstGistCommit = Get-GitHubGist -Gist $gist.id -Sha $oldestSha.version
            $firstGistCommit.PSObject.TypeNames[0] | Should -Be 'GitHub.Gist'
            $firstGistCommit.GistId | Should -Be $firstGistCommit.id
            $gist.owner.PSObject.TypeNames[0] | Should -Be 'GitHub.User'
            $gist.history[0].PSObject.TypeNames[0] | Should -Be 'GitHub.GistCommit'
            $gist.forks[0].PSObject.TypeNames[0] | Should -Be 'GitHub.GistFork'
        }

        It 'Should fail if we specify Sha _and_ Commits' {
            { Get-GitHubGist -Gist $gist.id -Commits -Sha $oldestSha.version } | Should -Throw
        }

        It 'Should fail if we specify Sha _and_ Forks' {
            { Get-GitHubGist -Gist $gist.id -Forks -Sha $oldestSha.version } | Should -Throw
        }

        It 'Should be the expected gist commit with the gist on the pipeline' {
            $firstGistCommit = $gist | Get-GitHubGist -Sha $oldestSha.version
            $firstGistCommit.created_at | Should -Be $oldestSha.committed_at
        }

        It 'Should be the expected gist commit with the gist commit on the pipeline' {
            $firstGistCommit = $gist | Get-GitHubGist -Sha $oldestSha.version
            $firstGistCommit = $firstGistCommit | Get-GitHubGist
            $firstGistCommit.created_at | Should -Be $oldestSha.committed_at
        }
    }

    Context 'Forks' {
        BeforeAll {
            $id = '0831f3fbd83ac4d46451' # octocat/git-author-rewrite.sh

            $gist = Get-GitHubGist -Gist $id
            $forks = Get-GitHubGist -Gist $gist.id -Forks
        }

        It 'Should have multiple forks' {
            $forks.Count | Should -BeGreaterThan 1
        }

        It 'Should have the expected type and additional properties' {
            foreach ($fork in $forks)
            {
                $fork.PSObject.TypeNames[0] | Should -Be 'GitHub.GistFork'
                $fork.GistId | Should -Be $fork.id
                $fork.owner.PSObject.TypeNames[0] | Should -Be 'GitHub.User'
            }
        }

        It 'Should have multiple forks when gist is on the pipeline' {
            $forks = $gist | Get-GitHubGist -Forks

            $forks.Count | Should -BeGreaterThan 1
        }
    }

    Context 'All gists for a specific user' {
        BeforeAll {
            $username = 'octocat'
            $gists = Get-GitHubGist -UserName $username
        }

        It 'Should have multiple gists' {
            $gists.Count | Should -BeGreaterThan 1
        }

        It 'Should have the expected type and additional properties' {
            foreach ($gist in $gists)
            {
                $gist.PSObject.TypeNames[0] | Should -Be 'GitHub.GistSummary'
                $gist.GistId | Should -Be $gist.id
                $gist.owner.PSObject.TypeNames[0] | Should -Be 'GitHub.User'
            }
        }

        It 'Should have fewer results with using the since parameter' {
            $since = $gists.updated_At | Sort-Object | Select-Object -Last 1
            $sinceGists = Get-GitHubGist -UserName $username -Since $since
            $sinceGists.Count | Should -BeGreaterThan 0
            $sinceGists.Count | Should -BeLessThan $gists.Count
        }
    }

    Context 'All gists for the current authenticated user' {
        BeforeAll {
            $gist = New-GitHubGist -Filename 'sample.txt' -Content 'Sample text'
            $gists = @(Get-GitHubGist)
        }

        It 'Should at least one gist including the one just created' {
            $gists.Count | Should -BeGreaterOrEqual 1
            $gists.id | Should -Contain $gist.id
        }

        It 'Should have the expected type and additional properties' {
            foreach ($gist in $gists)
            {
                $gist.PSObject.TypeNames[0] | Should -Be 'GitHub.GistSummary'
                $gist.GistId | Should -Be $gist.id
                $gist.owner.PSObject.TypeNames[0] | Should -Be 'GitHub.User'
            }
        }

        It 'Should be removed' {
            { $gist | Remove-GitHubGist -Force } | Should -Not -Throw
        }
    }

    Context 'All gists for the current authenticated user, but not authenticated' {
        # This would just be testing that an exception is thrown.
        # There's no easy way to cover unauthenticated sessions in the UT's,
        # so we'll just accept the lower code coverage here.
    }

    Context 'All starred gists for the current authenticated user' {
        BeforeAll {
            $id = '0831f3fbd83ac4d46451' # octocat/git-author-rewrite.sh
            Add-GitHubGistStar -Gist $id

            $gists = @(Get-GitHubGist -Starred)
        }

        It 'Should include the one we just starred' {
            $gists.Count | Should -BeGreaterOrEqual 1
            $gists.id | Should -Contain $id
        }

        AfterAll {
            Remove-GitHubGistStar -Gist $id
        }
    }

    Context 'All starred gists for the current authenticated user, but not authenticated' {
        # This would just be testing that an exception is thrown.
        # There's no easy way to cover unauthenticated sessions in the UT's,
        # so we'll just accept the lower code coverage here.
    }

    Context 'All public gists' {
        # This would require 100 queries, taking over 2 minutes.
        # Given the limited additional value that we'd get from this additional test relative
        # to the time it would take to execute, we'll just accept the lower code coverage here.
    }
}

Describe 'Get-GitHubGist/Download' {
    BeforeAll {
        # To get access to New-TemporaryDirectory
        $moduleRootPath = Split-Path -Path $PSScriptRoot -Parent
        . (Join-Path -Path $moduleRootPath -ChildPath 'Helpers.ps1')
        $tempPath = New-TemporaryDirectory
    }

    AfterAll {
        if (Get-Variable -Name tempPath -ErrorAction SilentlyContinue)
        {
            Remove-Item -Path $tempPath -Recurse -ErrorAction SilentlyContinue -Force
        }
    }

    Context 'Download gist content' {
        BeforeAll {
            $tempFile = New-TemporaryFile
            $fileA = "$($tempFile.FullName).ps1"
            Move-Item -Path $tempFile -Destination $fileA
            $fileAName = (Get-Item -Path $fileA).Name
            $fileAContent = 'fileA content'
            Out-File -FilePath $fileA -InputObject $fileAContent -Encoding utf8

            $tempFile = New-TemporaryFile
            $fileB = "$($tempFile.FullName).txt"
            Move-Item -Path $tempFile -Destination $fileB
            $fileBName = (Get-Item -Path $fileB).Name
            $fileBContent = 'fileB content'
            Out-File -FilePath $fileB -InputObject $fileBContent -Encoding utf8

            $tempFile = New-LargeFile -SizeMB 1
            $twoMegFile = "$($tempFile.FullName).bin"
            Move-Item -Path $tempFile -Destination $twoMegFile
            $twoMegFileName = (Get-Item -Path $twoMegFile).Name

            $gist = @($fileA, $fileB, $twoMegFile) | New-GitHubGist
        }

        AfterAll {
            $gist | Remove-GitHubGist -Force
            @($fileA, $fileB, $twoMegFile) |
            Remove-Item -Force -ErrorAction SilentlyContinue | Out-Null
        }

        It 'Should have no files at the download path' {
            @(Get-ChildItem -Path $tempPath).Count | Should -Be 0
        }

        It 'Should download all of the files' {
            Get-GitHubGist -Gist $gist.id -Path $tempPath
            @(Get-ChildItem -Path $tempPath).Count | Should -Be 3
            [System.IO.File]::ReadAllText($fileA).Trim() |
            Should -Be ([System.IO.File]::ReadAllText((Join-Path -Path $tempPath -ChildPath $fileAName)).Trim())
            [System.IO.File]::ReadAllText($fileB).Trim() |
            Should -Be ([System.IO.File]::ReadAllText((Join-Path -Path $tempPath -ChildPath $fileBName)).Trim())
                (Get-FileHash -Path $twoMegFile).Hash |
            Should -Be (Get-FileHash -Path (Join-Path -Path $tempPath -ChildPath $twoMegFileName)).Hash
        }

        It 'Should download all of the files with the gist on the pipeline and -Force' {
            $gist | Get-GitHubGist -Path $tempPath -Force
            @(Get-ChildItem -Path $tempPath).Count | Should -Be 3
            [System.IO.File]::ReadAllText($fileA).Trim() |
            Should -Be ([System.IO.File]::ReadAllText((Join-Path -Path $tempPath -ChildPath $fileAName)).Trim())
            [System.IO.File]::ReadAllText($fileB).Trim() |
            Should -Be ([System.IO.File]::ReadAllText((Join-Path -Path $tempPath -ChildPath $fileBName)).Trim())
                (Get-FileHash -Path $twoMegFile).Hash |
            Should -Be (Get-FileHash -Path (Join-Path -Path $tempPath -ChildPath $twoMegFileName)).Hash
        }
    }

    Context 'More than 300 files' {
        BeforeAll {
            $files = @()
            1..301 | ForEach-Object {
                $tempFile = New-TemporaryFile
                $file = "$($tempFile.FullName)-$_.ps1"
                Move-Item -Path $tempFile -Destination $file
                $fileContent = "file-$_ content"
                Out-File -FilePath $file -InputObject $fileContent -Encoding utf8
                $files += $file
            }
        }

        AfterAll {
            $files | Remove-Item -Force -ErrorAction SilentlyContinue | Out-Null
        }

        # May want to consider skipping this test.
        # It works just fine, but takes 26 second to execute.
        # (May not be worth it for the moderate improvement to code coverage.)
        It 'Should throw an exception because there are too many files' {
            $gist = $files | New-GitHubGist
            { $gist | Get-GitHubGist -Path $tempPath -Force } | Should -Throw
            $gist | Remove-GitHubGist -Force
        }

    }

    Context 'Download gist content' {
        BeforeAll {
            $tempFile = New-LargeFile -SizeMB 10
            $tenMegFile = "$($tempFile.FullName).bin"
            Move-Item -Path $tempFile -Destination $tenMegFile
            $tenMegFileName = (Get-Item -Path $tenMegFile).Name
        }

        AfterAll {
            @($tenMegFile) |
            Remove-Item -Force -ErrorAction SilentlyContinue | Out-Null
        }

        # May want to consider skipping this test.
        # It works just fine, but takes 26 second to execute.
        # (May not be worth it for the moderate improvement to code coverage.)
        It 'Should throw an exception because the file is too large to download' {
            $gist = $tenMegFile | New-GitHubGist
            { $gist | Get-GitHubGist -Path $tempPath -Force } | Should -Throw
            $gist | Remove-GitHubGist -Force
        }
    }
}

Describe 'Remove-GitHubGist' {
    Context 'With parameters' {
        BeforeAll {
            $gist = New-GitHubGist -FileName 'sample.txt' -Content 'Sample text'
        }

        It 'Should be there' {
            { Get-GitHubGist -Gist $gist.id } | Should -Not -Throw
        }

        It 'Should remove the gist successfully' {
            { Remove-GitHubGist -Gist $gist.id -Force } | Should -Not -Throw
        }

        It 'Should be removed' {
            { Get-GitHubGist -Gist $gist.id } | Should -Throw
        }
    }

    Context 'With the gist on the pipeline' {
        BeforeAll {
            $gist = New-GitHubGist -FileName 'sample.txt' -Content 'Sample text'
        }

        It 'Should be there' {
            { $gist | Get-GitHubGist } | Should -Not -Throw
        }

        It 'Should remove the gist successfully' {
            { $gist | Remove-GitHubGist -Force } | Should -Not -Throw
        }

        It 'Should be removed' {
            { $gist | Get-GitHubGist } | Should -Throw
        }
    }
}

Describe 'Copy-GitHubGist' {
    BeforeAll {
        $originalGist = Get-GitHubGist -Gist '1169852' # octocat/test.cs
    }

    Context 'By parameters' {
        BeforeAll {
            $gist = Copy-GitHubGist -Gist $originalGist.id -PassThru
        }

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
            $gist.PSObject.TypeNames[0] | Should -Be 'GitHub.GistSummary'
            $gist.GistId | Should -Be $gist.id
            $gist.owner.PSObject.TypeNames[0] | Should -Be 'GitHub.User'
        }

        It 'Should be removed' {
            { Remove-GitHubGist -Gist $gist.id -Force } | Should -Not -Throw
        }
    }

    Context 'Gist on the pipeline' {
        BeforeAll {
            $gist = $originalGist | Copy-GitHubGist -PassThru
        }

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
            $gist.PSObject.TypeNames[0] | Should -Be 'GitHub.GistSummary'
            $gist.GistId | Should -Be $gist.id
            $gist.owner.PSObject.TypeNames[0] | Should -Be 'GitHub.User'
        }

        It 'Should be removed' {
            { $gist | Remove-GitHubGist -Force } | Should -Not -Throw
        }
    }
}

Describe 'Add/Remove/Set/Test-GitHubGistStar' {
    BeforeAll {
        $gist = New-GitHubGist -FileName 'sample.txt' -Content 'Sample text'
    }

    AfterAll {
        $gist | Remove-GitHubGist -Force
    }

    Context 'With parameters' {
        It 'Should not be starred yet' {
            $starred = Test-GitHubGistStar -Gist $gist.id
            $starred | Should -BeFalse
        }

        It 'Should now be starred' {
            Add-GitHubGistStar -Gist $gist.id
            $starred = Test-GitHubGistStar -Gist $gist.id
            $starred | Should -BeTrue
        }

        It 'Should no longer be starred' {
            Remove-GitHubGistStar -Gist $gist.id
            $starred = Test-GitHubGistStar -Gist $gist.id
            $starred | Should -BeFalse
        }

        It 'Should now be starred' {
            Set-GitHubGistStar -Gist $gist.id -Star
            $starred = Test-GitHubGistStar -Gist $gist.id
            $starred | Should -BeTrue
        }

        It 'Should no longer be starred' {
            Set-GitHubGistStar -Gist $gist.id
            $starred = Test-GitHubGistStar -Gist $gist.id
            $starred | Should -BeFalse
        }
    }

    Context 'With the gist on the pipeline' {
        It 'Should not be starred yet' {
            $starred = $gist | Test-GitHubGistStar
            $starred | Should -BeFalse
        }

        It 'Should now be starred' {
            $gist | Add-GitHubGistStar
            $starred = $gist | Test-GitHubGistStar
            $starred | Should -BeTrue
        }

        It 'Should no longer be starred' {
            $gist | Remove-GitHubGistStar
            $starred = $gist | Test-GitHubGistStar
            $starred | Should -BeFalse
        }

        It 'Should now be starred' {
            $gist | Set-GitHubGistStar -Star
            $starred = $gist | Test-GitHubGistStar
            $starred | Should -BeTrue
        }

        It 'Should no longer be starred' {
            $gist | Set-GitHubGistStar
            $starred = $gist | Test-GitHubGistStar
            $starred | Should -BeFalse
        }
    }
}

Describe 'New-GitHubGist' {
    Context 'By content' {
        BeforeAll {
            $content = 'This is my content'
            $filename = 'sample.txt'
            $description = 'my description'
        }

        Context 'Add public Gist' {
            BeforeAll {
                $gist = New-GitHubGist -FileName $filename -Content $content -Public
            }

            It 'Should have the expected result' {
                $gist.public | Should -BeTrue
                $gist.description | Should -BeNullOrEmpty
                $gist.files.$filename.content | Should -Be $content
            }

            It 'Should have the expected type and additional properties' {
                $gist.PSObject.TypeNames[0] | Should -Be 'GitHub.Gist'
                $gist.GistId | Should -Be $gist.id
                $gist.owner.PSObject.TypeNames[0] | Should -Be 'GitHub.User'
            }

            It 'Should be removed' {
                { $gist | Remove-GitHubGist -Force } | Should -Not -Throw
            }
        }

        Context 'Add Private Gist' {
            BeforeAll {
                $gist = New-GitHubGist -FileName $filename -Content $content -Description $description -Public:$false
            }

            It 'Should have the expected result' {
                $gist.public | Should -BeFalse
                $gist.description | Should -Be $description
                $gist.files.$filename.content | Should -Be $content
            }

            It 'Should have the expected type and additional properties' {
                $gist.PSObject.TypeNames[0] | Should -Be 'GitHub.Gist'
                $gist.GistId | Should -Be $gist.id
                $gist.owner.PSObject.TypeNames[0] | Should -Be 'GitHub.User'
            }

            It 'Should error if file starts with "gistfile"' {
                { New-GitHubGist -FileName 'gistfile1' -Content $content } | Should -Throw
            }

            It 'Should be removed' {
                { $gist | Remove-GitHubGist -Force } | Should -Not -Throw
            }
        }
    }

    Context 'By files' {
        BeforeAll {
            $tempFile = New-TemporaryFile
            $fileA = "$($tempFile.FullName).ps1"
            Move-Item -Path $tempFile -Destination $fileA
            $fileAName = (Get-Item -Path $fileA).Name
            $fileAContent = 'fileA content'
            Out-File -FilePath $fileA -InputObject $fileAContent -Encoding utf8

            $tempFile = New-TemporaryFile
            $fileB = "$($tempFile.FullName).txt"
            Move-Item -Path $tempFile -Destination $fileB
            $fileBName = (Get-Item -Path $fileB).Name
            $fileBContent = 'fileB content'
            Out-File -FilePath $fileB -InputObject $fileBContent -Encoding utf8

            $description = 'my description'
        }

        AfterAll {
            @($fileA, $fileB) | Remove-Item -Force -ErrorAction SilentlyContinue | Out-Null
        }

        Context 'Add Public Gist' {
            BeforeAll {
                $gist = New-GitHubGist -File @($fileA, $fileB) -Public
            }

            It 'Should have the expected result' {
                $gist.public | Should -BeTrue
                $gist.description | Should -BeNullOrEmpty
                ($gist.files | Get-Member -Type NoteProperty).Count | Should -Be 2
                $gist.files.$fileAName.content.Trim() | Should -Be $fileAContent
                $gist.files.$fileBName.content.Trim() | Should -Be $fileBContent
            }

            It 'Should have the expected type and additional properties' {
                $gist.PSObject.TypeNames[0] | Should -Be 'GitHub.Gist'
                $gist.GistId | Should -Be $gist.id
                $gist.owner.PSObject.TypeNames[0] | Should -Be 'GitHub.User'
            }

            It 'Should be removed' {
                { $gist | Remove-GitHubGist -Force } | Should -Not -Throw
            }
        }

        Context 'Add Private Gist' {
            BeforeAll {
                $gist = New-GitHubGist -File @($fileA, $fileB) -Description $description -Public:$false
            }

            It 'Should have the expected result' {
                $gist.public | Should -BeFalse
                $gist.description | Should -Be $description
                ($gist.files | Get-Member -Type NoteProperty).Count | Should -Be 2
                $gist.files.$fileAName.content.Trim() | Should -Be $fileAContent
                $gist.files.$fileBName.content.Trim() | Should -Be $fileBContent
            }

            It 'Should be removed' {
                { $gist | Remove-GitHubGist -Force } | Should -Not -Throw
            }
        }

        It 'Should have the expected result with the files on the pipeline' {
            $gist = @($fileA, $fileB) | New-GitHubGist -Description $description -Public:$false
            $gist.public | Should -BeFalse
            $gist.description | Should -Be $description
                ($gist.files | Get-Member -Type NoteProperty).Count | Should -Be 2
            $gist.files.$fileAName.content.Trim() | Should -Be $fileAContent
            $gist.files.$fileBName.content.Trim() | Should -Be $fileBContent
        }
    }
}

Describe 'Set-GitHubGist' {
    BeforeAll {
        $fileAName = 'foo.txt'
        $fileAContent = 'foo content'
        $fileAUpdatedContent = 'foo updated content'
        $fileANewName = 'gamma.txt'

        $fileBName = 'bar.txt'
        $fileBContent = 'bar content'
        $fileBUpdatedContent = 'bar updated content'

        $fileCName = 'alpha.txt'
        $fileCContent = 'alpha content'
        $fileCUpdatedContent = 'alpha updated content'
        $fileCNewName = 'gamma.txt'

        $tempFile = New-TemporaryFile
        $fileD = "$($tempFile.FullName).txt"
        Move-Item -Path $tempFile -Destination $fileD
        $fileDName = (Get-Item -Path $fileD).Name
        $fileDContent = 'fileD content'
        Out-File -FilePath $fileD -InputObject $fileDContent -Encoding utf8
        $fileDUpdatedContent = 'fileD updated content'

        $description = 'my description'
        $updatedDescription = 'updated description'
    }

    AfterAll {
        @($fileD) | Remove-Item -Force -ErrorAction SilentlyContinue | Out-Null
    }

    Context 'With parameters' {
        BeforeAll {
            $gist = New-GitHubGist -FileName $fileAName -Content $fileAContent -Description $description
            $gist = Set-GitHubGistFile -Gist $gist.id -FileName $fileBName -Content $fileBContent -PassThru
        }

        AfterAll {
            $gist | Remove-GitHubGist -Force
        }

        It 'Should be in the expected, original state' {
            $gist.description | Should -Be $description
                ($gist.files | Get-Member -Type NoteProperty).Count | Should -Be 2
            $gist.files.$fileAName.content | Should -Be $fileAContent
            $gist.files.$fileBName.content | Should -Be $fileBContent
        }

        Context 'Update Gist' {
            BeforeAll {
                $setParams = @{
                    Gist = $gist.id
                    Description = $updatedDescription
                    Delete = @($fileBName)
                    Update = @{
                        $fileAName = @{
                            fileName = $fileANewName
                            content = $fileAUpdatedContent
                        }
                        $fileCName = @{ content = $fileCContent }
                        $fileDName = @{ filePath = $fileD }
                    }
                }

                $gist = Set-GitHubGist @setParams -Force -PassThru
            }

            It 'Should have been properly updated' {
                $gist.description | Should -Be $updatedDescription
                ($gist.files | Get-Member -Type NoteProperty).Count | Should -Be 3
                $gist.files.$fileAName | Should -BeNullOrEmpty
                $gist.files.$fileANewName.content | Should -Be $fileAContent
                $gist.files.$fileBName | Should -BeNullOrEmpty
                $gist.files.$fileCName.content | Should -Be $fileCContent
                $gist.files.$fileDName.content.Trim() | Should -Be $fileDContent
            }

            It 'Should have the expected type and additional properties' {
                $gist.PSObject.TypeNames[0] | Should -Be 'GitHub.Gist'
                $gist.GistId | Should -Be $gist.id
                $gist.owner.PSObject.TypeNames[0] | Should -Be 'GitHub.User'
            }


            It 'Should throw if updating a file with both a filePath and content' {
                $setParams = @{
                    Gist = $gist.id
                    Update = @{
                        $fileDName = @{
                            content = 'updated content'
                            filePath = $fileD
                        }
                    }
                }
                { $gist = Set-GitHubGist @setParams } | Should -Throw
            }
        }
    }

    Context 'With the gist on the pipeline' {
        BeforeAll {
            $gist = New-GitHubGist -FileName $fileAName -Content $fileAContent -Description $description
            $gist = Set-GitHubGistFile -Gist $gist.id -FileName $fileBName -Content $fileBContent -PassThru
        }

        AfterAll {
            $gist | Remove-GitHubGist -Force
        }

        It 'Should be in the expected, original state' {
            $gist.description | Should -Be $description
                ($gist.files | Get-Member -Type NoteProperty).Count | Should -Be 2
            $gist.files.$fileAName.content | Should -Be $fileAContent
            $gist.files.$fileBName.content | Should -Be $fileBContent
        }

        Context 'Update Gist' {
            BeforeAll {
                $setParams = @{
                    Description = $updatedDescription
                    Delete = @($fileBName)
                    Update = @{
                        $fileAName = @{
                            fileName = $fileANewName
                            content = $fileAUpdatedContent
                        }
                        $fileCName = @{ content = $fileCContent }
                        $fileDName = @{ filePath = $fileD }
                    }
                }
                $gist = $gist | Set-GitHubGist @setParams -Confirm:$false -PassThru
            }

            It 'Should have been properly updated' {
                $gist.description | Should -Be $updatedDescription
                ($gist.files | Get-Member -Type NoteProperty).Count | Should -Be 3
                $gist.files.$fileAName | Should -BeNullOrEmpty
                $gist.files.$fileANewName.content | Should -Be $fileAContent
                $gist.files.$fileBName | Should -BeNullOrEmpty
                $gist.files.$fileCName.content | Should -Be $fileCContent
                $gist.files.$fileDName.content.Trim() | Should -Be $fileDContent
            }

            It 'Should have the expected type and additional properties' {
                $gist.PSObject.TypeNames[0] | Should -Be 'GitHub.Gist'
                $gist.GistId | Should -Be $gist.id
                $gist.owner.PSObject.TypeNames[0] | Should -Be 'GitHub.User'
            }
        }

        It 'Should throw if updating a file with both a filePath and content' {
            $setParams = @{
                Update = @{
                    $fileDName = @{
                        content = 'updated content'
                        filePath = $fileD
                    }
                }
            }

            { $gist = $gist | Set-GitHubGist @setParams } | Should -Throw
        }
    }
}

Describe 'Set-GitHubGistFile' {
    BeforeAll {
        $origFileName = 'foo.txt'
        $origContent = 'original content'
        $updatedOrigContent = 'updated content'

        $newFileName = 'bar.txt'
        $newContent = 'new content'

        $gist = New-GitHubGist -FileName $origFileName -Content $origContent
    }

    AfterAll {
        $gist | Remove-GitHubGist -Force
    }

    Context 'By content with parameters' {
        BeforeAll {
            $gist = Set-GitHubGistFile -Gist $gist.id -FileName $origFileName -Content $updatedOrigContent -PassThru
        }

        It 'Should have the expected result' {
            $gist.files.$origFileName.content | Should -Be $updatedOrigContent
            $gist.files.$newFileName | Should -BeNullOrEmpty
        }

        It 'Should have the expected type and additional properties' {
            $gist.PSObject.TypeNames[0] | Should -Be 'GitHub.Gist'
            $gist.GistId | Should -Be $gist.id
            $gist.owner.PSObject.TypeNames[0] | Should -Be 'GitHub.User'
        }

        Context 'Update Gist' {
            BeforeAll {
                $gist = Set-GitHubGistFile -Gist $gist.id -FileName $newFileName -Content $newContent -PassThru
            }

            It 'Should have the expected result' {
                $gist.files.$origFileName.content | Should -Be $updatedOrigContent
                $gist.files.$newFileName.content | Should -Be $newContent
            }

            It 'Should have the expected type and additional properties' {
                $gist.PSObject.TypeNames[0] | Should -Be 'GitHub.Gist'
                $gist.GistId | Should -Be $gist.id
                $gist.owner.PSObject.TypeNames[0] | Should -Be 'GitHub.User'
            }
        }

        It 'Should remove the new file' {
            $gist = Set-GitHubGistFile -Gist $gist.id -FileName $origFileName -Content $origContent -PassThru
            { $gist | Remove-GitHubGistFile -FileName $newFileName -Force } | Should -Not -Throw
        }
    }

    Context 'By content with the gist on the pipeline' {
        BeforeAll {
            $gist = $gist | Set-GitHubGistFile -FileName $origFileName -Content $updatedOrigContent -PassThru
        }

        It 'Should have the expected result' {
            $gist.files.$origFileName.content | Should -Be $updatedOrigContent
            $gist.files.$newFileName | Should -BeNullOrEmpty
        }

        It 'Should have the expected type and additional properties' {
            $gist.PSObject.TypeNames[0] | Should -Be 'GitHub.Gist'
            $gist.GistId | Should -Be $gist.id
            $gist.owner.PSObject.TypeNames[0] | Should -Be 'GitHub.User'
        }

        Context 'Update Gist' {
            BeforeAll {
                $gist = $gist | Set-GitHubGistFile -FileName $newFileName -Content $newContent -PassThru
            }

            It 'Should have the expected result' {
                $gist.files.$origFileName.content | Should -Be $updatedOrigContent
                $gist.files.$newFileName.content | Should -Be $newContent
            }

            It 'Should have the expected type and additional properties' {
                $gist.PSObject.TypeNames[0] | Should -Be 'GitHub.Gist'
                $gist.GistId | Should -Be $gist.id
                $gist.owner.PSObject.TypeNames[0] | Should -Be 'GitHub.User'
            }
        }

        It 'Should remove the new file' {
            $gist = Set-GitHubGistFile -Gist $gist.id -FileName $origFileName -Content $origContent -PassThru
            { $gist | Remove-GitHubGistFile -FileName $newFileName -Force } | Should -Not -Throw
        }
    }

    Context 'By files with parameters' {
        BeforeAll {
            $tempFile = New-TemporaryFile
            $fileA = "$($tempFile.FullName).txt"
            Move-Item -Path $tempFile -Destination $fileA
            $fileAName = (Get-Item -Path $fileA).Name
            $fileAContent = 'fileA content'
            Out-File -FilePath $fileA -InputObject $fileAContent -Encoding utf8
            $fileAUpdatedContent = 'fileA content updated'
            $gist = Set-GitHubGistFile -Gist $gist.id -File $fileA -PassThru
        }

        AfterAll {
            @($fileA) | Remove-Item -Force -ErrorAction SilentlyContinue | Out-Null
        }

        It 'Should have the expected result' {
                ($gist.files | Get-Member -Type NoteProperty).Count | Should -Be 2
            $gist.files.$origFileName.content | Should -Be $origContent
            $gist.files.$fileAName.content.Trim() | Should -Be $fileAContent
        }

        It 'Should have the expected type and additional properties' {
            $gist.PSObject.TypeNames[0] | Should -Be 'GitHub.Gist'
            $gist.GistId | Should -Be $gist.id
            $gist.owner.PSObject.TypeNames[0] | Should -Be 'GitHub.User'
        }

        Context 'Update Gist' {
            BeforeAll {
                Out-File -FilePath $fileA -InputObject $fileAUpdatedContent -Encoding utf8
                $gist = Set-GitHubGistFile -Gist $gist.id -File $fileA -PassThru
            }

            It 'Should have the expected result' {
                ($gist.files | Get-Member -Type NoteProperty).Count | Should -Be 2
                $gist.files.$origFileName.content | Should -Be $origContent
                $gist.files.$fileAName.content.Trim() | Should -Be $fileAUpdatedContent
            }

            It 'Should have the expected type and additional properties' {
                $gist.PSObject.TypeNames[0] | Should -Be 'GitHub.Gist'
                $gist.GistId | Should -Be $gist.id
                $gist.owner.PSObject.TypeNames[0] | Should -Be 'GitHub.User'
            }
        }

        It 'Should remove the new file' {
            $gist = Set-GitHubGistFile -Gist $gist.id -FileName $origFileName -Content $origContent -PassThru
            { $gist | Remove-GitHubGistFile -FileName $fileAName -Force } | Should -Not -Throw
        }
    }

    Context 'By files with the gist on the pipeline' {
        BeforeAll {
            $tempFile = New-TemporaryFile
            $fileA = "$($tempFile.FullName).txt"
            Move-Item -Path $tempFile -Destination $fileA
            $fileAName = (Get-Item -Path $fileA).Name
            $fileAContent = 'fileA content'
            Out-File -FilePath $fileA -InputObject $fileAContent -Encoding utf8
            $fileAUpdatedContent = 'fileA content updated'
            $gist = $gist | Set-GitHubGistFile -File $fileA -PassThru
        }

        AfterAll {
            @($fileA) | Remove-Item -Force -ErrorAction SilentlyContinue | Out-Null
        }

        It 'Should have the expected result' {
                ($gist.files | Get-Member -Type NoteProperty).Count | Should -Be 2
            $gist.files.$origFileName.content | Should -Be $origContent
            $gist.files.$fileAName.content.Trim() | Should -Be $fileAContent
        }

        It 'Should have the expected type and additional properties' {
            $gist.PSObject.TypeNames[0] | Should -Be 'GitHub.Gist'
            $gist.GistId | Should -Be $gist.id
            $gist.owner.PSObject.TypeNames[0] | Should -Be 'GitHub.User'
        }

        Context 'Update Gist' {
            BeforeAll {
                Out-File -FilePath $fileA -InputObject $fileAUpdatedContent -Encoding utf8
                $gist = $gist | Set-GitHubGistFile -File $fileA -PassThru
            }

            It 'Should have the expected result' {
                ($gist.files | Get-Member -Type NoteProperty).Count | Should -Be 2
                $gist.files.$origFileName.content | Should -Be $origContent
                $gist.files.$fileAName.content.Trim() | Should -Be $fileAUpdatedContent
            }

            It 'Should have the expected type and additional properties' {
                $gist.PSObject.TypeNames[0] | Should -Be 'GitHub.Gist'
                $gist.GistId | Should -Be $gist.id
                $gist.owner.PSObject.TypeNames[0] | Should -Be 'GitHub.User'
            }
        }

        It 'Should remove the new file' {
            $gist = Set-GitHubGistFile -Gist $gist.id -FileName $origFileName -Content $origContent -PassThru
            { $gist | Remove-GitHubGistFile -FileName $fileAName -Force } | Should -Not -Throw
        }
    }

    Context 'By files with the file on the pipeline' {
        BeforeAll {
            $tempFile = New-TemporaryFile
            $fileA = "$($tempFile.FullName).txt"
            Move-Item -Path $tempFile -Destination $fileA
            $fileAName = (Get-Item -Path $fileA).Name
            $fileAContent = 'fileA content'
            Out-File -FilePath $fileA -InputObject $fileAContent -Encoding utf8
            $fileAUpdatedContent = 'fileA content updated'
            $gist = $fileA | Set-GitHubGistFile -Gist $gist.id -PassThru
        }

        AfterAll {
            @($fileA) | Remove-Item -Force -ErrorAction SilentlyContinue | Out-Null
        }

        It 'Should have the expected result' {
                ($gist.files | Get-Member -Type NoteProperty).Count | Should -Be 2
            $gist.files.$origFileName.content | Should -Be $origContent
            $gist.files.$fileAName.content.Trim() | Should -Be $fileAContent
        }

        It 'Should have the expected type and additional properties' {
            $gist.PSObject.TypeNames[0] | Should -Be 'GitHub.Gist'
            $gist.GistId | Should -Be $gist.id
            $gist.owner.PSObject.TypeNames[0] | Should -Be 'GitHub.User'
        }

        Context 'Update Gist' {
            BeforeAll {
                Out-File -FilePath $fileA -InputObject $fileAUpdatedContent -Encoding utf8
                $gist = $fileA | Set-GitHubGistFile -Gist $gist.id -PassThru
            }

            It 'Should have the expected result' {
                ($gist.files | Get-Member -Type NoteProperty).Count | Should -Be 2
                $gist.files.$origFileName.content | Should -Be $origContent
                $gist.files.$fileAName.content.Trim() | Should -Be $fileAUpdatedContent
            }

            It 'Should have the expected type and additional properties' {
                $gist.PSObject.TypeNames[0] | Should -Be 'GitHub.Gist'
                $gist.GistId | Should -Be $gist.id
                $gist.owner.PSObject.TypeNames[0] | Should -Be 'GitHub.User'
            }
        }

        It 'Should remove the new file' {
            $gist = Set-GitHubGistFile -Gist $gist.id -FileName $origFileName -Content $origContent -PassThru
            { $gist | Remove-GitHubGistFile -FileName $fileAName -Force } | Should -Not -Throw
        }
    }
}

Describe 'Rename-GitHubGistFile' {
    BeforeAll {
        $originalName = 'foo.txt'
        $newName = 'bar.txt'
        $content = 'sample content'
    }

    Context 'With parameters' {
        BeforeAll {
            $gist = New-GitHubGist -FileName $originalName -Content $content
        }

        It 'Should have the expected file' {
            $gist.files.$originalName.content | Should -Be $content
            $gist.files.$newName | Should -BeNullOrEmpty
        }

        Context 'Rename Gist' {
            BeforeAll {
                $gist = Rename-GitHubGistFile -Gist $gist.id -FileName $originalName -NewName $newName -PassThru
            }

            It 'Should have been renamed' {
                $gist.files.$originalName | Should -BeNullOrEmpty
                $gist.files.$newName.content | Should -Be $content
            }

            It 'Should have the expected additional type and properties' {
                $gist.PSObject.TypeNames[0] | Should -Be 'GitHub.Gist'
                $gist.GistId | Should -Be $gist.id
                $gist.owner.PSObject.TypeNames[0] | Should -Be 'GitHub.User'
            }
        }

        It 'Should successfully remove the gist' {
            { $gist | Remove-GitHubGist -Force } | Should -Not -Throw
        }
    }

    Context 'With the gist on the pipeline' {
        BeforeAll {
            $gist = New-GitHubGist -FileName $originalName -Content $content
        }

        It 'Should have the expected file' {
            $gist.files.$originalName.content | Should -Be $content
            $gist.files.$newName | Should -BeNullOrEmpty
        }

        Context 'Rename Gist' {
            BeforeAll {
                $gist = $gist | Rename-GitHubGistFile -FileName $originalName -NewName $newName -PassThru
            }

            It 'Should have been renamed' {
                $gist.files.$originalName | Should -BeNullOrEmpty
                $gist.files.$newName.content | Should -Be $content
            }

            It 'Should have the expected additional type and properties' {
                $gist.PSObject.TypeNames[0] | Should -Be 'GitHub.Gist'
                $gist.GistId | Should -Be $gist.id
                $gist.owner.PSObject.TypeNames[0] | Should -Be 'GitHub.User'
            }
        }

        It 'Should successfully remove the gist' {
            { $gist | Remove-GitHubGist -Force } | Should -Not -Throw
        }
    }
}

Describe 'Remove-GitHubGistFile' {
    BeforeAll {
        $fileName = 'sample.txt'
        $content = 'sample'
    }

    Context 'With parameters' {
        BeforeAll {
            $gist = New-GitHubGist -FileName $fileName -Content $content
        }

        It 'Should have the expected file' {
            $gist.files.$fileName | Should -Not -BeNullOrEmpty
        }

        Context 'Remove Gist File' {
            BeforeAll {
                $gist = Remove-GitHubGistFile -Gist $gist.id -FileName $fileName -Force -PassThru
            }

            It 'Should have been removed' {
                $gist.files.$fileName | Should -BeNullOrEmpty
            }

            It 'Should have the expected additional type and properties' {
                $gist.PSObject.TypeNames[0] | Should -Be 'GitHub.Gist'
                $gist.GistId | Should -Be $gist.id
                $gist.owner.PSObject.TypeNames[0] | Should -Be 'GitHub.User'
            }
        }

        It 'Should successfully remove the gist' {
            { $gist | Remove-GitHubGist -Force } | Should -Not -Throw
        }
    }

    Context 'With the gist on the pipeline' {
        BeforeAll {
            $gist = New-GitHubGist -FileName $fileName -Content $content
        }

        It 'Should have the expected file' {
            $gist.files.$fileName | Should -Not -BeNullOrEmpty
        }

        Context 'Remove Gist File' {
            BeforeAll {
                $gist = $gist | Remove-GitHubGistFile -FileName $fileName -Confirm:$false -PassThru
            }

            It 'Should have been removed' {
                $gist.files.$fileName | Should -BeNullOrEmpty
            }

            It 'Should have the expected additional type and properties' {
                $gist.PSObject.TypeNames[0] | Should -Be 'GitHub.Gist'
                $gist.GistId | Should -Be $gist.id
                $gist.owner.PSObject.TypeNames[0] | Should -Be 'GitHub.User'
            }
        }

        It 'Should successfully remove the gist' {
            { $gist | Remove-GitHubGist -Force } | Should -Not -Throw
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
