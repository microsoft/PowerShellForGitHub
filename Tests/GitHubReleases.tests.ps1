# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

<#
.Synopsis
   Tests for GitHubReleases.ps1 module
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
    Describe 'Getting releases from repository' {
        $ownerName = "dotnet"
        $repositoryName = "core"
        $releases = @(Get-GitHubRelease -OwnerName $ownerName -RepositoryName $repositoryName)

        Context 'When getting all releases' {
            It 'Should return multiple releases' {
                $releases.Count | Should -BeGreaterThan 1
            }

            It 'Should have expected type and additional properties' {
                $releases[0].PSObject.TypeNames[0] | Should -Be 'GitHub.Release'
                $releases[0].html_url.StartsWith($releases[0].RepositoryUrl) | Should -BeTrue
                $releases[0].id | Should -Be $releases[0].ReleaseId
            }
        }

        Context 'When getting the latest releases' {
            $latest = @(Get-GitHubRelease -OwnerName $ownerName -RepositoryName $repositoryName -Latest)

            It 'Should return one value' {
                $latest.Count | Should -Be 1
            }

            It 'Should return the first release from the full releases list' {
                $latest[0].url | Should -Be $releases[0].url
                $latest[0].name | Should -Be $releases[0].name
            }
        }

            It 'Should have expected type and additional properties' {
                $latest[0].PSObject.TypeNames[0] | Should -Be 'GitHub.Release'
                $latest[0].html_url.StartsWith($latest[0].RepositoryUrl) | Should -BeTrue
                $latest[0].id | Should -Be $latest[0].ReleaseId
            }
        }

        Context 'When getting the latest releases via the pipeline' {
            $latest = @(Get-GitHubRepository -OwnerName $ownerName -RepositoryName $repositoryName |
                Get-GitHubRelease -Latest)

            It 'Should return one value' {
                $latest.Count | Should -Be 1
            }
        }

            It 'Should return the first release from the full releases list' {
                $latest[0].url | Should -Be $releases[0].url
                $latest[0].name | Should -Be $releases[0].name
            }

            It 'Should have expected type and additional properties' {
                $latest[0].PSObject.TypeNames[0] | Should -Be 'GitHub.Release'
                $latest[0].html_url.StartsWith($latest[0].RepositoryUrl) | Should -BeTrue
                $latest[0].id | Should -Be $latest[0].ReleaseId
            }

            $latestAgain = @($latest | Get-GitHubRelease)
            It 'Should be the same release' {
                $latest[0].ReleaseId | Should -Be $latestAgain[0].ReleaseId
            }
        }
    }

        Context 'When getting a specific release' {
            $specificIndex = 5
            $specific = @(Get-GitHubRelease -OwnerName $ownerName -RepositoryName $repositoryName -ReleaseId $releases[$specificIndex].id)

            It 'Should return one value' {
                $specific.Count | Should -Be 1
            }

            It 'Should return the correct release' {
                $specific.name | Should -Be $releases[$specificIndex].name
            }

            It 'Should have expected type and additional properties' {
                $specific[0].PSObject.TypeNames[0] | Should -Be 'GitHub.Release'
                $specific[0].html_url.StartsWith($specific[0].RepositoryUrl) | Should -BeTrue
                $specific[0].id | Should -Be $specific[0].ReleaseId
            }
        }

        Context 'When getting a tagged release' {
            $taggedIndex = 8
            $tagged = @(Get-GitHubRelease -OwnerName $ownerName -RepositoryName $repositoryName -Tag $releases[$taggedIndex].tag_name)

            It 'Should return one value' {
                $tagged.Count | Should -Be 1
            }

            It 'Should return the correct release' {
                $tagged.name | Should -Be $releases[$taggedIndex].name
            }

            It 'Should have expected type and additional properties' {
                $tagged[0].PSObject.TypeNames[0] | Should -Be 'GitHub.Release'
                $tagged[0].html_url.StartsWith($tagged[0].RepositoryUrl) | Should -BeTrue
                $tagged[0].id | Should -Be $tagged[0].ReleaseId
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
                    $releases.Count | Should -BeGreaterThan 1
                }
            }
        } finally {
            Set-GitHubConfiguration -DefaultOwnerName $originalOwnerName
            Set-GitHubConfiguration -DefaultRepositoryName $originalRepositoryName
        }
        finally
        {
            Set-GitHubConfiguration -DefaultOwnerName $originalOwnerName
            Set-GitHubConfiguration -DefaultRepositoryName $originalRepositoryName
        }
    }

    Describe 'Creating, changing and deleting releases' {
        $repo = New-GitHubRepository -RepositoryName ([Guid]::NewGuid().Guid) -AutoInit -Private

        Context 'When creating a simple new release' {
            $release = New-GitHubRelease -Uri $repo.svn_url -TagName $script:defaultTagName
            $queried = Get-GitHubRelease -Uri $repo.svn_url -Release $release.id

            It 'Should be queryable' {
                $queried.id | Should -Be $release.id
                $queried.tag_name | Should -Be $script:defaultTagName
            }

            It 'Should have the expected default property values' {
                $queried.name | Should -BeNullOrEmpty
                $queried.body | Should -BeNullOrEmpty
                $queried.draft | Should -BeFalse
                $queried.prerelease | Should -BeFalse
            }

            It 'Should be modifiable' {
                Set-GitHubRelease -Uri $repo.svn_url -Release $release.id -Name $script:defaultReleaseName -Body $script:defaultReleaseBody -Draft -PreRelease
                $queried = Get-GitHubRelease -Uri $repo.svn_url -Release $release.id
                $queried.name | Should -Be $script:defaultReleaseName
                $queried.body | Should -Be $script:defaultReleaseBody
                $queried.draft | Should -BeTrue
                $queried.prerelease | Should -BeTrue
            }

            It 'Should be removable' {
                Remove-GitHubRelease -Uri $repo.svn_url -Release $release.id -Confirm:$false
                { Get-GitHubRelease -Uri $repo.svn_url -Release $release.id } | Should -Throw
            }

            It 'Should be creatable with non-default property values' {
                $release = New-GitHubRelease -Uri $repo.svn_url -TagName $script:defaultTagName -Name $script:defaultReleaseName -Body $script:defaultReleaseBody -Draft -PreRelease
                $queried = Get-GitHubRelease -Uri $repo.svn_url -Release $release.id
                $queried.id | Should -Be $release.id
                $queried.tag_name | Should -Be $script:defaultTagName
                $queried.name | Should -Be $script:defaultReleaseName
                $queried.body | Should -Be $script:defaultReleaseBody
                $queried.draft | Should -BeTrue
                $queried.prerelease | Should -BeTrue
                Remove-GitHubRelease -Uri $repo.svn_url -Release $release.id -Confirm:$false
            }
        }

        Remove-GitHubRepository -Uri $repo.svn_url -Confirm:$false
    }

    Describe 'Creating, changing and deleting release assets' {

            # TODO

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
