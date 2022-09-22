# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

<#
.Synopsis
   Tests for GitHubReleases.ps1 module
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

Describe 'Getting releases from repository' {
    Context 'Common test state' {
        BeforeAll {
            $dotNetOwnerName = "dotnet"
            $repositoryName = "core"

            $releases = @(Get-GitHubRelease -OwnerName $dotNetOwnerName -RepositoryName $repositoryName)
        }

        Context 'When getting all releases' {
            It 'Should return multiple releases' {
                $releases.Count | Should -BeGreaterThan 1
            }

            It 'Should have expected type and additional properties' {
                $elements = Split-GitHubUri -Uri $releases[0].html_url
                $repositoryUrl = Join-GitHubUri @elements

                $releases[0].PSObject.TypeNames[0] | Should -Be 'GitHub.Release'
                $releases[0].RepositoryUrl | Should -Be $repositoryUrl
                $releases[0].ReleaseId | Should -Be $releases[0].id
            }
        }

        Context 'When getting the latest releases' {
            BeforeAll {
                $latest = @(Get-GitHubRelease -OwnerName $dotNetOwnerName -RepositoryName $repositoryName -Latest)
            }

            It 'Should return one value' {
                $latest.Count | Should -Be 1
            }

            It 'Should return the first release from the full releases list' {
                $first = $releases | Where-Object prerelease -eq $false | Select-Object -First 1
                $latest[0].url | Should -Be $first[0].url
                $latest[0].name | Should -Be $first[0].name
            }

            It 'Should have expected type and additional properties' {
                $elements = Split-GitHubUri -Uri $latest[0].html_url
                $repositoryUrl = Join-GitHubUri @elements

                $latest[0].PSObject.TypeNames[0] | Should -Be 'GitHub.Release'
                $latest[0].RepositoryUrl | Should -Be $repositoryUrl
                $latest[0].ReleaseId | Should -Be $latest[0].id
            }
        }

        Context 'When getting the latest releases via the pipeline' {
            BeforeAll {
                $latest = @(Get-GitHubRepository -OwnerName $dotNetOwnerName -RepositoryName $repositoryName |
                    Get-GitHubRelease -Latest)
            }

            It 'Should return one value' {
                $latest.Count | Should -Be 1
            }

            It 'Should return the first release from the full releases list' {
                $first = $releases | Where-Object prerelease -eq $false | Select-Object -First 1
                $latest[0].url | Should -Be $first[0].url
                $latest[0].name | Should -Be $first[0].name
            }

            It 'Should have expected type and additional properties' {
                $elements = Split-GitHubUri -Uri $latest[0].html_url
                $repositoryUrl = Join-GitHubUri @elements

                $latest[0].PSObject.TypeNames[0] | Should -Be 'GitHub.Release'
                $latest[0].RepositoryUrl | Should -Be $repositoryUrl
                $latest[0].ReleaseId | Should -Be $latest[0].id
            }

            It 'Should be the same release' {
                $latestAgain = @($latest | Get-GitHubRelease)
                $latest[0].ReleaseId | Should -Be $latestAgain[0].ReleaseId
            }
        }

        Context 'When getting a specific release' {
            BeforeAll {
                $specificIndex = 5
                $specific = @(Get-GitHubRelease -OwnerName $dotNetOwnerName -RepositoryName $repositoryName -ReleaseId $releases[$specificIndex].id)
            }

            It 'Should return one value' {
                $specific.Count | Should -Be 1
            }

            It 'Should return the correct release' {
                $specific.name | Should -Be $releases[$specificIndex].name
            }

            It 'Should have expected type and additional properties' {
                $elements = Split-GitHubUri -Uri $specific[0].html_url
                $repositoryUrl = Join-GitHubUri @elements

                $specific[0].PSObject.TypeNames[0] | Should -Be 'GitHub.Release'
                $specific[0].RepositoryUrl | Should -Be $repositoryUrl
                $specific[0].id | Should -Be $specific[0].ReleaseId
            }
        }

        Context 'When getting a tagged release' {
            BeforeAll {
                $taggedIndex = 8
                $tagged = @(Get-GitHubRelease -OwnerName $dotNetOwnerName -RepositoryName $repositoryName -Tag $releases[$taggedIndex].tag_name)
            }

            It 'Should return one value' {
                $tagged.Count | Should -Be 1
            }

            It 'Should return the correct release' {
                $tagged.name | Should -Be $releases[$taggedIndex].name
            }

            It 'Should have expected type and additional properties' {
                $elements = Split-GitHubUri -Uri $tagged[0].html_url
                $repositoryUrl = Join-GitHubUri @elements

                $tagged[0].PSObject.TypeNames[0] | Should -Be 'GitHub.Release'
                $tagged[0].RepositoryUrl | Should -Be $repositoryUrl
                $tagged[0].ReleaseId | Should -Be $tagged[0].id
            }
        }
    }
}

Describe 'Getting releases from default owner/repository' {
    Context 'Common test state' {
        BeforeAll {
            $originalOwnerName = Get-GitHubConfiguration -Name DefaultOwnerName
            $originalRepositoryName = Get-GitHubConfiguration -Name DefaultRepositoryName

            Set-GitHubConfiguration -DefaultOwnerName "dotnet"
            Set-GitHubConfiguration -DefaultRepositoryName "core"
        }

        AfterAll {
            Set-GitHubConfiguration -DefaultOwnerName $originalOwnerName
            Set-GitHubConfiguration -DefaultRepositoryName $originalRepositoryName
        }

        Context 'When getting all releases' {
            It 'Should return multiple releases' {
                $releases = @(Get-GitHubRelease)

                $releases.Count | Should -BeGreaterThan 1
            }
        }
    }
}

Describe 'Creating, changing and deleting releases with defaults' {
    Context 'Common test state' {
        BeforeAll {
            $defaultTagName = '0.2.0'
            $defaultReleaseName = 'Release Name'
            $defaultReleaseBody = 'Releasey Body'
            $repo = New-GitHubRepository -RepositoryName ([Guid]::NewGuid().Guid) -AutoInit -Private
            $release = New-GitHubRelease -Uri $repo.svn_url -Tag $defaultTagName
            $queried = Get-GitHubRelease -Uri $repo.svn_url -Release $release.id
        }

        AfterAll {
            Remove-GitHubRepository -Uri $repo.svn_url -Confirm:$false
        }

        Context 'When creating a simple new release' {
            It 'Should have expected type and additional properties' {
                $elements = Split-GitHubUri -Uri $release.html_url
                $repositoryUrl = Join-GitHubUri @elements

                $release.PSObject.TypeNames[0] | Should -Be 'GitHub.Release'
                $release.RepositoryUrl | Should -Be $repositoryUrl
                $release.ReleaseId | Should -Be $release.id
            }

            It 'Should be queryable' {
                $queried.id | Should -Be $release.id
                $queried.tag_name | Should -Be $defaultTagName
            }

            It 'Should have the expected default property values' {
                $queried.name | Should -BeNullOrEmpty
                $queried.body | Should -BeNullOrEmpty
                $queried.draft | Should -BeFalse
                $queried.prerelease | Should -BeFalse
            }

            It 'Should be modifiable' {
                Set-GitHubRelease -Uri $repo.svn_url -Release $release.id -Name $defaultReleaseName -Body $defaultReleaseBody -Draft -PreRelease
                $queried = Get-GitHubRelease -Uri $repo.svn_url -Release $release.id
                $queried.name | Should -Be $defaultReleaseName
                $queried.body | Should -Be $defaultReleaseBody
                $queried.draft | Should -BeTrue
                $queried.prerelease | Should -BeTrue
            }

            It 'Should be removable' {
                Remove-GitHubRelease -Uri $repo.svn_url -Release $release.id -Confirm:$false
                { Get-GitHubRelease -Uri $repo.svn_url -Release $release.id } | Should -Throw
            }
        }
    }
}

Describe 'Creating, changing and deleting releases with defaults using the pipeline' {
    Context 'Common test state' {
        BeforeAll {
            $defaultTagName = '0.2.0'
            $defaultReleaseName = 'Release Name'
            $defaultReleaseBody = 'Releasey Body'
            $repo = New-GitHubRepository -RepositoryName ([Guid]::NewGuid().Guid) -AutoInit -Private
            $release = $repo | New-GitHubRelease -Tag $defaultTagName
            $queried = $release | Get-GitHubRelease
        }

        AfterAll {
            $repo | Remove-GitHubRepository -Force
        }

        Context 'When creating a simple new release' {
            It 'Should have expected type and additional properties' {
                $elements = Split-GitHubUri -Uri $release.html_url
                $repositoryUrl = Join-GitHubUri @elements

                $release.PSObject.TypeNames[0] | Should -Be 'GitHub.Release'
                $release.RepositoryUrl | Should -Be $repositoryUrl
                $release.ReleaseId | Should -Be $release.id
            }

            It 'Should be queryable' {
                $queried.id | Should -Be $release.id
                $queried.tag_name | Should -Be $defaultTagName
            }

            It 'Should have the expected default property values' {
                $queried.name | Should -BeNullOrEmpty
                $queried.body | Should -BeNullOrEmpty
                $queried.draft | Should -BeFalse
                $queried.prerelease | Should -BeFalse
            }

            It 'Should be modifiable with the release on the pipeline' {
                $release | Set-GitHubRelease -Name $defaultReleaseName -Body $defaultReleaseBody -Draft -PreRelease
                $queried = $release | Get-GitHubRelease
                $queried.name | Should -Be $defaultReleaseName
                $queried.body | Should -Be $defaultReleaseBody
                $queried.draft | Should -BeTrue
                $queried.prerelease | Should -BeTrue
            }

            It 'Should be modifiable with the URI on the pipeline' {
                $repo | Set-GitHubRelease -Release $release.id -Draft:$false
                $queried = $repo | Get-GitHubRelease -Release $release.id
                $queried.name | Should -Be $defaultReleaseName
                $queried.body | Should -Be $defaultReleaseBody
                $queried.draft | Should -BeFalse
                $queried.prerelease | Should -BeTrue
            }

            It 'Should be removable' {
                $release | Remove-GitHubRelease -Force
                { $release | Get-GitHubRelease } | Should -Throw
            }
        }
    }
}

Describe 'Creating and changing releases with non-defaults' {
    Context 'Common test state' {
        BeforeAll {
            $defaultTagName = '0.2.0'
            $defaultReleaseName = 'Release Name'
            $defaultReleaseBody = 'Releasey Body'
            $repo = New-GitHubRepository -RepositoryName ([Guid]::NewGuid().Guid) -AutoInit -Private
        }

        AfterAll {
            Remove-GitHubRepository -Uri $repo.svn_url -Confirm:$false
        }

        Context 'When creating a simple new release' {
            BeforeAll {
                $release = New-GitHubRelease -Uri $repo.svn_url -Tag $defaultTagName -Name $defaultReleaseName -Body $defaultReleaseBody -Draft -PreRelease
                $queried = Get-GitHubRelease -Uri $repo.svn_url -Release $release.id
            }

            AfterAll {
                $release | Remove-GitHubRelease -Force
            }

            It 'Should be creatable with non-default property values' {
                $queried.id | Should -Be $release.id
                $queried.tag_name | Should -Be $defaultTagName
                $queried.name | Should -Be $defaultReleaseName
                $queried.body | Should -Be $defaultReleaseBody
                $queried.draft | Should -BeTrue
                $queried.prerelease | Should -BeTrue
            }
        }

        Context 'When creating a simple new release with the repo on the pipeline' {
            BeforeAll {
                $release = $repo | New-GitHubRelease -Tag $defaultTagName -Name $defaultReleaseName -Body $defaultReleaseBody -Draft -PreRelease
                $queried = Get-GitHubRelease -Uri $repo.svn_url -Release $release.id
            }

            AfterAll {
                $release | Remove-GitHubRelease -Force
            }

            It 'Should be creatable with non-default property values' {
                $queried.id | Should -Be $release.id
                $queried.tag_name | Should -Be $defaultTagName
                $queried.name | Should -Be $defaultReleaseName
                $queried.body | Should -Be $defaultReleaseBody
                $queried.draft | Should -BeTrue
                $queried.prerelease | Should -BeTrue
            }
        }
    }
}

Describe 'Get-GitHubReleaseAsset' {
    BeforeAll {
        $defaultTagName = '0.2.0'

        $repo = New-GitHubRepository -RepositoryName ([Guid]::NewGuid().Guid) -AutoInit -Private

        $tempFile = New-TemporaryFile
        $zipFile = "$($tempFile.FullName).zip"
        Move-Item -Path $tempFile -Destination $zipFile

        $tempFile = New-TemporaryFile
        $txtFile = "$($tempFile.FullName).txt"
        Move-Item -Path $tempFile -Destination $txtFile
        Out-File -FilePath $txtFile -InputObject "txt file content" -Encoding utf8

        # The file we'll save the downloaded contents to
        $saveFile = New-TemporaryFile

        # Disable Progress Bar in function scope during Compress-Archive
        $ProgressPreference = 'SilentlyContinue'
        Compress-Archive -Path $txtFile -DestinationPath $zipFile -Force

        $labelBase = 'mylabel'
    }

    AfterAll {
        @($zipFile, $txtFile, $saveFile) | Remove-Item -ErrorAction SilentlyContinue | Out-Null
        Remove-GitHubRepository -Uri $repo.svn_url -Confirm:$false
    }

    Context 'Using parameters' {
        BeforeAll {
            $release = New-GitHubRelease -Uri $repo.svn_url -Tag $defaultTagName

            # We want to make sure we start out without the file being there.
            Remove-Item -Path $saveFile -ErrorAction SilentlyContinue | Out-Null
        }

        AfterAll {
            $release | Remove-GitHubRelease -Force
        }

        It 'Should have no assets so far' {
            $assets = @(Get-GitHubReleaseAsset -Uri $repo.svn_url -Release $release.id)
            $assets.Count | Should -Be 0
        }

        Context 'Add zip asset' {
            BeforeAll {
                $fileName = (Get-Item -Path $zipFile).Name
                $finalLabel = "$labelBase-$fileName"
                $asset = New-GitHubReleaseAsset -Uri $repo.svn_url -Release $release.id -Path $zipFile -Label $finalLabel
            }

            It "Can add a release asset" {
                $assetId = $asset.id

                $asset.name | Should -BeExactly $fileName
                $asset.label | Should -BeExactly $finalLabel
            }

            It 'Should have expected type and additional properties' {
                $elements = Split-GitHubUri -Uri $asset.url
                $repositoryUrl = Join-GitHubUri @elements

                $asset.PSObject.TypeNames[0] | Should -Be 'GitHub.ReleaseAsset'
                $asset.RepositoryUrl | Should -Be $repositoryUrl
                $asset.AssetId | Should -Be $asset.id
                $asset.uploader.PSObject.TypeNames[0] | Should -Be 'GitHub.User'
            }
        }

        Context 'Add txt asset' {
            BeforeAll {
                $fileName = (Get-Item -Path $txtFile).Name
                $finalLabel = "$labelBase-$fileName"
                $asset = New-GitHubReleaseAsset -Uri $repo.svn_url -Release $release.id -Path $txtFile -Label $finalLabel
            }

            It "Can add a release asset" {
                $assetId = $asset.id

                $asset.name | Should -BeExactly $fileName
                $asset.label | Should -BeExactly $finalLabel
            }

            It 'Should have expected type and additional properties' {
                $elements = Split-GitHubUri -Uri $asset.url
                $repositoryUrl = Join-GitHubUri @elements

                $asset.PSObject.TypeNames[0] | Should -Be 'GitHub.ReleaseAsset'
                $asset.RepositoryUrl | Should -Be $repositoryUrl
                $asset.AssetId | Should -Be $asset.id
                $asset.uploader.PSObject.TypeNames[0] | Should -Be 'GitHub.User'
            }
        }

        Context 'Retrieve Assets' {
            BeforeAll {
                $assets = @(Get-GitHubReleaseAsset -Uri $repo.svn_url -Release $release.id)
            }

            It 'Should have both assets now' {
                $assets.Count | Should -Be 2
            }

            It 'Should have expected type and additional properties' {
                foreach ($asset in $assets)
                {
                    $elements = Split-GitHubUri -Uri $asset.url
                    $repositoryUrl = Join-GitHubUri @elements

                    $asset.PSObject.TypeNames[0] | Should -Be 'GitHub.ReleaseAsset'
                    $asset.RepositoryUrl | Should -Be $repositoryUrl
                    $asset.AssetId | Should -Be $asset.id
                    $asset.uploader.PSObject.TypeNames[0] | Should -Be 'GitHub.User'
                }
            }


            Context 'Retrieve txt asset' {
                BeforeAll {
                    $txtFileName = (Get-Item -Path $txtFile).Name
                    $txtFileAsset = $assets | Where-Object { $_.name -eq $txtFileName }
                    $asset = Get-GitHubReleaseAsset -Uri $repo.svn_url -Asset $txtFileAsset.id
                }

                It 'Should be able to query for a single asset' {
                    $asset.id | Should -Be $txtFileAsset.id
                }

                It 'Should have expected type and additional properties' {
                    $elements = Split-GitHubUri -Uri $asset.url
                    $repositoryUrl = Join-GitHubUri @elements

                    $asset.PSObject.TypeNames[0] | Should -Be 'GitHub.ReleaseAsset'
                    $asset.RepositoryUrl | Should -Be $repositoryUrl
                    $asset.AssetId | Should -Be $asset.id
                    $asset.uploader.PSObject.TypeNames[0] | Should -Be 'GitHub.User'
                }

                It 'Should not have the downloaded file yet' {
                    Test-Path -Path $saveFile -PathType Leaf | Should -BeFalse
                }

                Context 'Dowload parameters' {
                    BeforeAll {
                        $downloadParams = @{
                            OwnerName = $script:ownerName
                            RepositoryName = $repo.name
                            Asset = $txtFileAsset.id
                            Path = $saveFile
                        }

                        $null = Get-GitHubReleaseAsset @downloadParams
                    }

                    It 'Should be able to download the asset file' {
                        Test-Path -Path $saveFile -PathType Leaf | Should -BeTrue
                    }

                    It 'Should be able the same file' {
                        $compareParams = @{
                            ReferenceObject = (Get-Content -Path $txtFile)
                            DifferenceObject = (Get-Content -Path $saveFile)
                        }

                        Compare-Object @compareParams | Should -BeNullOrEmpty
                    }

                    It 'Should fail if the download location already exists' {
                        { Get-GitHubReleaseAsset @downloadParams } | Should -Throw
                    }

                    It 'Should work if the download location already exists and -Force is used' {
                        $null = Get-GitHubReleaseAsset @downloadParams -Force

                        $compareParams = @{
                            ReferenceObject = (Get-Content -Path $txtFile)
                            DifferenceObject = (Get-Content -Path $saveFile)
                        }

                        Compare-Object @compareParams | Should -BeNullOrEmpty
                    }
                }
            }
        }
    }

    Context 'Using the repo on the pipeline' {
        BeforeAll {
            $release = $repo | New-GitHubRelease -Tag $defaultTagName

            # We want to make sure we start out without the file being there.
            Remove-Item -Path $saveFile -ErrorAction SilentlyContinue | Out-Null

            $assets = @($repo | Get-GitHubReleaseAsset -Release $release.id)
        }

        AfterAll {
            $release | Remove-GitHubRelease -Force
        }

        It 'Should have no assets so far' {
            $assets.Count | Should -Be 0
        }

        Context 'Add zip file' {
            BeforeAll {
                $fileName = (Get-Item -Path $zipFile).Name
                $finalLabel = "$labelBase-$fileName"
                $asset = $repo | New-GitHubReleaseAsset -Release $release.id -Path $zipFile -Label $finalLabel
            }

            It "Can add a release asset" {
                $assetId = $asset.id

                $asset.name | Should -BeExactly $fileName
                $asset.label | Should -BeExactly $finalLabel
            }

            It 'Should have expected type and additional properties' {
                $elements = Split-GitHubUri -Uri $asset.url
                $repositoryUrl = Join-GitHubUri @elements

                $asset.PSObject.TypeNames[0] | Should -Be 'GitHub.ReleaseAsset'
                $asset.RepositoryUrl | Should -Be $repositoryUrl
                $asset.AssetId | Should -Be $asset.id
                $asset.uploader.PSObject.TypeNames[0] | Should -Be 'GitHub.User'
            }
        }

        Context 'Add txtFile' {
            BeforeAll {
                $fileName = (Get-Item -Path $txtFile).Name
                $finalLabel = "$labelBase-$fileName"
                $asset = $repo | New-GitHubReleaseAsset -Release $release.id -Path $txtFile -Label $finalLabel
            }

            It "Can add a release asset" {
                $assetId = $asset.id

                $asset.name | Should -BeExactly $fileName
                $asset.label | Should -BeExactly $finalLabel
            }

            It 'Should have expected type and additional properties' {
                $elements = Split-GitHubUri -Uri $asset.url
                $repositoryUrl = Join-GitHubUri @elements

                $asset.PSObject.TypeNames[0] | Should -Be 'GitHub.ReleaseAsset'
                $asset.RepositoryUrl | Should -Be $repositoryUrl
                $asset.AssetId | Should -Be $asset.id
                $asset.uploader.PSObject.TypeNames[0] | Should -Be 'GitHub.User'
            }
        }

        Context 'Retrieve Assets' {
            BeforeAll {
                $assets = @($repo | Get-GitHubReleaseAsset -Release $release.id)
            }

            It 'Should have both assets now' {
                $assets.Count | Should -Be 2
            }

            It 'Should have expected type and additional properties' {
                foreach ($asset in $assets)
                {
                    $elements = Split-GitHubUri -Uri $asset.url
                    $repositoryUrl = Join-GitHubUri @elements

                    $asset.PSObject.TypeNames[0] | Should -Be 'GitHub.ReleaseAsset'
                    $asset.RepositoryUrl | Should -Be $repositoryUrl
                    $asset.AssetId | Should -Be $asset.id
                    $asset.uploader.PSObject.TypeNames[0] | Should -Be 'GitHub.User'
                }
            }

            Context 'Retrieve txt assets' {
                BeforeAll {
                    $txtFileName = (Get-Item -Path $txtFile).Name
                    $txtFileAsset = $assets | Where-Object { $_.name -eq $txtFileName }
                    $asset = $repo | Get-GitHubReleaseAsset -Asset $txtFileAsset.id
                }

                It 'Should be able to query for a single asset' {
                    $asset.id | Should -Be $txtFileAsset.id
                }

                It 'Should have expected type and additional properties' {
                    $elements = Split-GitHubUri -Uri $asset.url
                    $repositoryUrl = Join-GitHubUri @elements

                    $asset.PSObject.TypeNames[0] | Should -Be 'GitHub.ReleaseAsset'
                    $asset.RepositoryUrl | Should -Be $repositoryUrl
                    $asset.AssetId | Should -Be $asset.id
                    $asset.uploader.PSObject.TypeNames[0] | Should -Be 'GitHub.User'
                }

                It 'Should not have the downloaded file yet' {
                    Test-Path -Path $saveFile -PathType Leaf | Should -BeFalse
                }

                Context 'Download parameters' {
                    BeforeAll {
                        $downloadParams = @{
                            Asset = $txtFileAsset.id
                            Path = $saveFile
                        }

                        $null = $repo | Get-GitHubReleaseAsset @downloadParams
                    }

                    It 'Should be able to download the asset file' {
                        Test-Path -Path $saveFile -PathType Leaf | Should -BeTrue
                    }

                    It 'Should be able the same file' {
                        $compareParams = @{
                            ReferenceObject = (Get-Content -Path $txtFile)
                            DifferenceObject = (Get-Content -Path $saveFile)
                        }

                        Compare-Object @compareParams | Should -BeNullOrEmpty
                    }

                    It 'Should fail if the download location already exists' {
                        { $repo | Get-GitHubReleaseAsset @downloadParams } | Should -Throw
                    }

                    It 'Should work if the download location already exists and -Force is used' {
                        $null = $repo | Get-GitHubReleaseAsset @downloadParams -Force

                        $compareParams = @{
                            ReferenceObject = (Get-Content -Path $txtFile)
                            DifferenceObject = (Get-Content -Path $saveFile)
                        }

                        Compare-Object @compareParams | Should -BeNullOrEmpty
                    }
                }
            }
        }
    }

    Context 'Using the release on the pipeline' {
        BeforeAll {
            $release = $repo | New-GitHubRelease -Tag $defaultTagName

            # We want to make sure we start out without the file being there.
            Remove-Item -Path $saveFile -ErrorAction SilentlyContinue | Out-Null

            $assets = @($release | Get-GitHubReleaseAsset)
        }

        AfterAll {
            $release | Remove-GitHubRelease -Force
        }

        It 'Should have no assets so far' {
            $assets.Count | Should -Be 0
        }

        Context 'Add zip file' {
            BeforeAll {
                $fileName = (Get-Item -Path $zipFile).Name
                $finalLabel = "$labelBase-$fileName"
                $asset = $release | New-GitHubReleaseAsset -Path $zipFile -Label $finalLabel
            }

            It "Can add a release asset" {
                $assetId = $asset.id

                $asset.name | Should -BeExactly $fileName
                $asset.label | Should -BeExactly $finalLabel
            }

            It 'Should have expected type and additional properties' {
                $elements = Split-GitHubUri -Uri $asset.url
                $repositoryUrl = Join-GitHubUri @elements

                $asset.PSObject.TypeNames[0] | Should -Be 'GitHub.ReleaseAsset'
                $asset.RepositoryUrl | Should -Be $repositoryUrl
                $asset.AssetId | Should -Be $asset.id
                $asset.uploader.PSObject.TypeNames[0] | Should -Be 'GitHub.User'
            }
        }

        Context 'Add txt file' {
            BeforeAll {
                $fileName = (Get-Item -Path $txtFile).Name
                $finalLabel = "$labelBase-$fileName"
                $asset = $release | New-GitHubReleaseAsset -Path $txtFile -Label $finalLabel
            }

            It "Can add a release asset" {
                $assetId = $asset.id

                $asset.name | Should -BeExactly $fileName
                $asset.label | Should -BeExactly $finalLabel
            }

            It 'Should have expected type and additional properties' {
                $elements = Split-GitHubUri -Uri $asset.url
                $repositoryUrl = Join-GitHubUri @elements

                $asset.PSObject.TypeNames[0] | Should -Be 'GitHub.ReleaseAsset'
                $asset.RepositoryUrl | Should -Be $repositoryUrl
                $asset.AssetId | Should -Be $asset.id
                $asset.uploader.PSObject.TypeNames[0] | Should -Be 'GitHub.User'
            }
        }

        Context 'Retrieve assets' {
            BeforeAll {
                $assets = @($release | Get-GitHubReleaseAsset)
            }

            It 'Should have both assets now' {
                $assets.Count | Should -Be 2
            }

            It 'Should have expected type and additional properties' {
                foreach ($asset in $assets)
                {
                    $elements = Split-GitHubUri -Uri $asset.url
                    $repositoryUrl = Join-GitHubUri @elements

                    $asset.PSObject.TypeNames[0] | Should -Be 'GitHub.ReleaseAsset'
                    $asset.RepositoryUrl | Should -Be $repositoryUrl
                    $asset.AssetId | Should -Be $asset.id
                    $asset.uploader.PSObject.TypeNames[0] | Should -Be 'GitHub.User'
                }
            }

            Context 'Retrieve txt file' {
                BeforeAll {
                    $txtFileName = (Get-Item -Path $txtFile).Name
                    $txtFileAsset = $assets | Where-Object { $_.name -eq $txtFileName }
                    $asset = $release | Get-GitHubReleaseAsset -Asset $txtFileAsset.id
                }

                It 'Should be able to query for a single asset' {
                    $asset.id | Should -Be $txtFileAsset.id
                }

                It 'Should have expected type and additional properties' {
                    $elements = Split-GitHubUri -Uri $asset.url
                    $repositoryUrl = Join-GitHubUri @elements

                    $asset.PSObject.TypeNames[0] | Should -Be 'GitHub.ReleaseAsset'
                    $asset.RepositoryUrl | Should -Be $repositoryUrl
                    $asset.AssetId | Should -Be $asset.id
                    $asset.uploader.PSObject.TypeNames[0] | Should -Be 'GitHub.User'
                }

                It 'Should not have the downloaded file yet' {
                    Test-Path -Path $saveFile -PathType Leaf | Should -BeFalse
                }

                Context 'Download file' {
                    BeforeAll {
                        $downloadParams = @{
                            Asset = $txtFileAsset.id
                            Path = $saveFile
                        }
                        $null = $release | Get-GitHubReleaseAsset @downloadParams
                    }

                    It 'Should be able to download the asset file' {
                        Test-Path -Path $saveFile -PathType Leaf | Should -BeTrue
                    }

                    It 'Should be able the same file' {
                        $compareParams = @{
                            ReferenceObject = (Get-Content -Path $txtFile)
                            DifferenceObject = (Get-Content -Path $saveFile)
                        }

                        Compare-Object @compareParams | Should -BeNullOrEmpty
                    }

                    It 'Should fail if the download location already exists' {
                        { $release | Get-GitHubReleaseAsset @downloadParams } | Should -Throw
                    }

                    It 'Should work if the download location already exists and -Force is used' {
                        $null = $release | Get-GitHubReleaseAsset @downloadParams -Force

                        $compareParams = @{
                            ReferenceObject = (Get-Content -Path $txtFile)
                            DifferenceObject = (Get-Content -Path $saveFile)
                        }

                        Compare-Object @compareParams | Should -BeNullOrEmpty
                    }
                }
            }
        }
    }

    Context 'Verifying a zip file' {
        BeforeAll {
            $release = $repo | New-GitHubRelease -Tag $defaultTagName

            # To get access to New-TemporaryDirectory
            $moduleRootPath = Split-Path -Path $PSScriptRoot -Parent
            . (Join-Path -Path $moduleRootPath -ChildPath 'Helpers.ps1')
            $tempPath = New-TemporaryDirectory

            $tempFile = New-TemporaryFile
            $downloadedZipFile = "$($tempFile.FullName).zip"
            Move-Item -Path $tempFile -Destination $downloadedZipFile

            $asset = $release | New-GitHubReleaseAsset -Path $zipFile -ContentType 'application/zip'
        }

        AfterAll {
            $release | Remove-GitHubRelease -Force

            Remove-Item -Path $tempPath -Recurse -ErrorAction SilentlyContinue -Force
            if (Get-Variable -Name downloadedZipFile -ErrorAction SilentlyContinue)
            {
                Remove-Item -Path $downloadedZipFile -ErrorAction SilentlyContinue
            }
        }

        It "Has the expected content inside" {
            $result = $asset | Get-GitHubReleaseAsset -Path $downloadedZipFile -Force
            Expand-Archive -Path $downloadedZipFile -DestinationPath $tempPath

            $result.FullName | Should -BeExactly $downloadedZipFile

            $txtFileName = (Get-Item -Path $txtFile).Name
            $downloadedTxtFile = (Get-ChildItem -Path $tempPath -Filter $txtFileName).FullName

            $compareParams = @{
                ReferenceObject = (Get-Content -Path $txtFile)
                DifferenceObject = (Get-Content -Path $downloadedTxtFile)
            }

            Compare-Object @compareParams | Should -BeNullOrEmpty
        }
    }
}

Describe 'Set-GitHubReleaseAsset' {
    BeforeAll {
        $defaultTagName = '0.2.0'

        $repo = New-GitHubRepository -RepositoryName ([Guid]::NewGuid().Guid) -AutoInit -Private
        $release = New-GitHubRelease -Uri $repo.svn_url -Tag $defaultTagName

        $tempFile = New-TemporaryFile
        $txtFile = "$($tempFile.FullName).txt"
        Move-Item -Path $tempFile -Destination $txtFile
        Out-File -FilePath $txtFile -InputObject "txt file content" -Encoding utf8

        $label = 'mylabel'
    }

    AfterAll {
        $txtFile | Remove-Item | Out-Null
        Remove-GitHubRepository -Uri $repo.svn_url -Confirm:$false
    }

    Context 'Using parameters' {
        BeforeAll {
            $fileName = (Get-Item -Path $txtFile).Name
            $asset = New-GitHubReleaseAsset -Uri $repo.svn_url -Release $release.id -Path $txtFile -Label $label
        }

        It 'Has the expected initial property values' {
            $asset.name | Should -BeExactly $fileName
            $asset.label | Should -BeExactly $label
        }

        Context 'Update release asset' {
            BeforeAll {
                $setParams = @{
                    OwnerName = $script:ownerName
                    RepositoryName = $repo.name
                    Asset = $asset.id
                    PassThru = $true
                }

                $updated = Set-GitHubReleaseAsset @setParams
            }

            It 'Should have the original property values' {
                $updated.name | Should -BeExactly $fileName
                $updated.label | Should -BeExactly $label
            }

            It 'Should have expected type and additional properties' {
                $elements = Split-GitHubUri -Uri $updated.url
                $repositoryUrl = Join-GitHubUri @elements

                $updated.PSObject.TypeNames[0] | Should -Be 'GitHub.ReleaseAsset'
                $updated.RepositoryUrl | Should -Be $repositoryUrl
                $updated.AssetId | Should -Be $updated.id
                $updated.uploader.PSObject.TypeNames[0] | Should -Be 'GitHub.User'
            }
        }

        It 'Should have a new name and the original label' {
            $updatedFileName = 'updated1.txt'
            $setParams = @{
                OwnerName = $script:ownerName
                RepositoryName = $repo.name
                Asset = $asset.id
                Name = $updatedFileName
                PassThru = $true
            }

            $updated = Set-GitHubReleaseAsset @setParams
            $updated.name | Should -BeExactly $updatedFileName
            $updated.label | Should -BeExactly $label
        }

        It 'Should have the current name and a new label' {
            $updatedFileName = 'updated1.txt'
            $updatedLabel = 'updatedLabel2'
            $setParams = @{
                OwnerName = $script:ownerName
                RepositoryName = $repo.name
                Asset = $asset.id
                Label = $updatedLabel
                PassThru = $true
            }

            $updated = Set-GitHubReleaseAsset @setParams
            $updated.name | Should -BeExactly $updatedFileName
            $updated.label | Should -BeExactly $updatedLabel
        }

        It 'Should have a new name and a new label' {
            $updatedFileName = 'updated3parameter.txt'
            $updatedLabel = 'updatedLabel3parameter'
            $setParams = @{
                OwnerName = $script:ownerName
                RepositoryName = $repo.name
                Asset = $asset.id
                Name = $updatedFileName
                Label = $updatedLabel
                PassThru = $true
            }

            $updated = Set-GitHubReleaseAsset @setParams
            $updated.name | Should -BeExactly $updatedFileName
            $updated.label | Should -BeExactly $updatedLabel
        }
    }

    Context 'Using the repo on the pipeline' {
        BeforeAll {
            $fileName = (Get-Item -Path $txtFile).Name
            $asset = $repo | New-GitHubReleaseAsset -Release $release.id -Path $txtFile -Label $label
        }

        It 'Has the expected initial property values' {
            $asset.name | Should -BeExactly $fileName
            $asset.label | Should -BeExactly $label
        }

        Context 'Update the release asset' {
            BeforeAll {
                $setParams = @{
                    Asset = $asset.id
                    PassThru = $true
                }

                $updated = $repo | Set-GitHubReleaseAsset @setParams
            }

            It 'Should have the original property values' {
                $updated.name | Should -BeExactly $fileName
                $updated.label | Should -BeExactly $label
            }

            It 'Should have expected type and additional properties' {
                $elements = Split-GitHubUri -Uri $updated.url
                $repositoryUrl = Join-GitHubUri @elements

                $updated.PSObject.TypeNames[0] | Should -Be 'GitHub.ReleaseAsset'
                $updated.RepositoryUrl | Should -Be $repositoryUrl
                $updated.AssetId | Should -Be $updated.id
                $updated.uploader.PSObject.TypeNames[0] | Should -Be 'GitHub.User'
            }
        }

        It 'Should have a new name and the original label' {
            $updatedFileName = 'updated1.txt'
            $setParams = @{
                Asset = $asset.id
                Name = $updatedFileName
                PassThru = $true
            }

            $updated = $repo | Set-GitHubReleaseAsset @setParams
            $updated.name | Should -BeExactly $updatedFileName
            $updated.label | Should -BeExactly $label
        }

        It 'Should have the current name and a new label' {
            $updatedFileName = 'updated1.txt'
            $updatedLabel = 'updatedLabel2'
            $setParams = @{
                Asset = $asset.id
                Label = $updatedLabel
                PassThru = $true
            }

            $updated = $repo | Set-GitHubReleaseAsset @setParams
            $updated.name | Should -BeExactly $updatedFileName
            $updated.label | Should -BeExactly $updatedLabel
        }

        It 'Should have a new name and a new label' {
            $updatedFileName = 'updated3repo.txt'
            $updatedLabel = 'updatedLabel3repo'
            $setParams = @{
                Asset = $asset.id
                Name = $updatedFileName
                Label = $updatedLabel
                PassThru = $true
            }

            $updated = $repo | Set-GitHubReleaseAsset @setParams
            $updated.name | Should -BeExactly $updatedFileName
            $updated.label | Should -BeExactly $updatedLabel
        }
    }

    Context 'Using the release on the pipeline' {
        BeforeAll {
            $fileName = (Get-Item -Path $txtFile).Name
            $asset = $release | New-GitHubReleaseAsset -Path $txtFile -Label $label
        }

        It 'Has the expected initial property values' {
            $asset.name | Should -BeExactly $fileName
            $asset.label | Should -BeExactly $label
        }

        Context 'Update release' {
            BeforeAll {
                $setParams = @{
                    Asset = $asset.id
                    PassThru = $true
                }

                $updated = $release | Set-GitHubReleaseAsset @setParams
            }

            It 'Should have the original property values' {
                $updated.name | Should -BeExactly $fileName
                $updated.label | Should -BeExactly $label
            }

            It 'Should have expected type and additional properties' {
                $elements = Split-GitHubUri -Uri $updated.url
                $repositoryUrl = Join-GitHubUri @elements

                $updated.PSObject.TypeNames[0] | Should -Be 'GitHub.ReleaseAsset'
                $updated.RepositoryUrl | Should -Be $repositoryUrl
                $updated.AssetId | Should -Be $updated.id
                $updated.uploader.PSObject.TypeNames[0] | Should -Be 'GitHub.User'
            }
        }

        It 'Should have a new name and the original label' {
            $updatedFileName = 'updated1.txt'
            $setParams = @{
                Asset = $asset.id
                Name = $updatedFileName
                PassThru = $true
            }

            $updated = $release | Set-GitHubReleaseAsset @setParams
            $updated.name | Should -BeExactly $updatedFileName
            $updated.label | Should -BeExactly $label
        }

        It 'Should have the current name and a new label' {
            $updatedFileName = 'updated1.txt'
            $updatedLabel = 'updatedLabel2'
            $setParams = @{
                Asset = $asset.id
                Label = $updatedLabel
                PassThru = $true
            }

            $updated = $release | Set-GitHubReleaseAsset @setParams
            $updated.name | Should -BeExactly $updatedFileName
            $updated.label | Should -BeExactly $updatedLabel
        }

        It 'Should have a new name and a new label' {
            $updatedFileName = 'updated3release.txt'
            $updatedLabel = 'updatedLabel3release'
            $setParams = @{
                Asset = $asset.id
                Name = $updatedFileName
                Label = $updatedLabel
                PassThru = $true
            }

            $updated = $release | Set-GitHubReleaseAsset @setParams
            $updated.name | Should -BeExactly $updatedFileName
            $updated.label | Should -BeExactly $updatedLabel
        }
    }

    Context 'Using the asset on the pipeline' {
        BeforeAll {
            $fileName = (Get-Item -Path $txtFile).Name
            $asset = $release | New-GitHubReleaseAsset -Path $txtFile -Label $label
            $updated = $asset | Set-GitHubReleaseAsset -PassThru
        }

        It 'Has the expected initial property values' {
            $asset.name | Should -BeExactly $fileName
            $asset.label | Should -BeExactly $label
        }

        It 'Should have the original property values' {
            $updated.name | Should -BeExactly $fileName
            $updated.label | Should -BeExactly $label
        }

        It 'Should have expected type and additional properties' {
            $elements = Split-GitHubUri -Uri $updated.url
            $repositoryUrl = Join-GitHubUri @elements

            $updated.PSObject.TypeNames[0] | Should -Be 'GitHub.ReleaseAsset'
            $updated.RepositoryUrl | Should -Be $repositoryUrl
            $updated.AssetId | Should -Be $updated.id
            $updated.uploader.PSObject.TypeNames[0] | Should -Be 'GitHub.User'
        }

        It 'Should have a new name and the original label' {
            $updatedFileName = 'updated1.txt'
            $updated = $asset | Set-GitHubReleaseAsset -Name $updatedFileName -PassThru
            $updated.name | Should -BeExactly $updatedFileName
            $updated.label | Should -BeExactly $label
        }

        It 'Should have the current name and a new label' {
            $updatedFileName = 'updated1.txt'
            $updatedLabel = 'updatedLabel2'
            $updated = $asset | Set-GitHubReleaseAsset -Label $updatedLabel -PassThru
            $updated.name | Should -BeExactly $updatedFileName
            $updated.label | Should -BeExactly $updatedLabel
        }

        It 'Should have a new name and a new label' {
            $updatedFileName = 'updated3asset.txt'
            $updatedLabel = 'updatedLabel3asset'
            $updated = $asset | Set-GitHubReleaseAsset -Name $updatedFileName -Label $updatedLabel -PassThru
            $updated.name | Should -BeExactly $updatedFileName
            $updated.label | Should -BeExactly $updatedLabel
        }
    }
}

Describe 'Remove-GitHubReleaseAsset' {
    BeforeAll {
        $defaultTagName = '0.2.0'

        $repo = New-GitHubRepository -RepositoryName ([Guid]::NewGuid().Guid) -AutoInit -Private
        $release = New-GitHubRelease -Uri $repo.svn_url -Tag $defaultTagName

        $tempFile = New-TemporaryFile
        $txtFile = "$($tempFile.FullName).txt"
        Move-Item -Path $tempFile -Destination $txtFile
        Out-File -FilePath $txtFile -InputObject "txt file content" -Encoding utf8
    }

    AfterAll {
        $txtFile | Remove-Item | Out-Null
        Remove-GitHubRepository -Uri $repo.svn_url -Confirm:$false
    }

    Context 'Using parameters' {
        BeforeAll {
            $asset = New-GitHubReleaseAsset -Uri $repo.svn_url -Release $release.id -Path $txtFile

            $params = @{
                OwnerName = $script:ownerName
                RepositoryName = $repo.name
                Asset = $asset.id
                Force = $true
            }

            Remove-GitHubReleaseAsset @params
        }

        It 'Should be successfully deleted' {
            { Remove-GitHubReleaseAsset @params } | Should -Throw
        }
    }

    Context 'Using the repo on the pipeline' {
        It 'Should be successfully deleted' {
            $asset = New-GitHubReleaseAsset -Uri $repo.svn_url -Release $release.id -Path $txtFile

            $repo | Remove-GitHubReleaseAsset -Asset $asset.id -Force
            { $repo | Remove-GitHubReleaseAsset -Asset $asset.id -Force } | Should -Throw
        }
    }

    Context 'Using the release on the pipeline' {
        It 'Should be successfully deleted' {
            $asset = New-GitHubReleaseAsset -Uri $repo.svn_url -Release $release.id -Path $txtFile

            $release | Remove-GitHubReleaseAsset -Asset $asset.id -Force
            { $release | Remove-GitHubReleaseAsset -Asset $asset.id -Force } | Should -Throw
        }
    }

    Context 'Using the asset on the pipeline' {
        It 'Should be successfully deleted' {
            $asset = New-GitHubReleaseAsset -Uri $repo.svn_url -Release $release.id -Path $txtFile

            $asset | Remove-GitHubReleaseAsset -Force
            { $asset | Remove-GitHubReleaseAsset -Force } | Should -Throw
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