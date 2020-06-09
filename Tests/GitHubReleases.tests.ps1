# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

<#
.Synopsis
   Tests for GitHubReleases.ps1 module
#>

# This is common test code setup logic for all Pester test files
$moduleRootPath = Split-Path -Path $PSScriptRoot -Parent
. (Join-Path -Path $moduleRootPath -ChildPath 'Tests\Common.ps1')

try
{
    Describe 'Getting releases from repository' {
        $ownerName = "dotnet"
        $repositoryName = "core"
        $releases = @(Get-GitHubRelease -OwnerName $ownerName -RepositoryName $repositoryName)

        Context 'When getting all releases' {
            It 'Should return multiple releases' {
                $releases.Count | Should BeGreaterThan 1
            }
        }

        Context 'When getting the latest releases' {
            $latest = @(Get-GitHubRelease -OwnerName $ownerName -RepositoryName $repositoryName -Latest)

            It 'Should return one value' {
                $latest.Count | Should Be 1
            }

            It 'Should return the first release from the full releases list' {
                $latest[0].url | Should Be $releases[0].url
                $latest[0].name | Should Be $releases[0].name
            }
        }

        Context 'When getting a specific release' {
            $specificIndex = 5
            $specific = @(Get-GitHubRelease -OwnerName $ownerName -RepositoryName $repositoryName -ReleaseId $releases[$specificIndex].id)

            It 'Should return one value' {
                $specific.Count | Should Be 1
            }

            It 'Should return the correct release' {
                $specific.name | Should Be $releases[$specificIndex].name
            }
        }

        Context 'When getting a tagged release' {
            $taggedIndex = 8
            $tagged = @(Get-GitHubRelease -OwnerName $ownerName -RepositoryName $repositoryName -Tag $releases[$taggedIndex].tag_name)

            It 'Should return one value' {
                $tagged.Count | Should Be 1
            }

            It 'Should return the correct release' {
                $tagged.name | Should Be $releases[$taggedIndex].name
            }
        }
    }

    Describe 'Getting releases from default owner/repository' {
        $originalOwnerName = Get-GitHubConfiguration -Name DefaultOwnerName
        $originalRepositoryName = Get-GitHubConfiguration -Name DefaultRepositoryName

        try {
            Set-GitHubConfiguration -DefaultOwnerName "dotnet"
            Set-GitHubConfiguration -DefaultRepositoryName "core"
            $releases = @(Get-GitHubRelease)

            Context 'When getting all releases' {
                It 'Should return multiple releases' {
                    $releases.Count | Should BeGreaterThan 1
                }
            }
        } finally {
            Set-GitHubConfiguration -DefaultOwnerName $originalOwnerName
            Set-GitHubConfiguration -DefaultRepositoryName $originalRepositoryName
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
