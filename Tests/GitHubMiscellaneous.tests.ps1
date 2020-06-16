# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

<#
.Synopsis
   Tests for GitHubMiscellaneous.ps1 module
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
    Describe 'Get-GitHubRateLimit' {
        Context 'Is working' {
            $result = Get-GitHubRateLimit

            It 'Has the expected type' {
                $result.PSObject.TypeNames[0] | Should -Be 'GitHub.RateLimit'
            }
        }
    }

    Describe 'ConvertFrom-GitHubMarkdown' {
        BeforeAll {
            $markdown = '**PowerShellForGitHub**'
            $expectedHtml = '<p><strong>PowerShellForGitHub</strong></p>'
        }

        Context 'Works with the parameter' {
            $result = ConvertFrom-GitHubMarkdown -Content $markdown

            It 'Has the expected result' {
                # Replace newlines with empty for comparison purposes
                $result.Replace("`n", "").Replace("`r", "") | Should -Be $expectedHtml
            }
        }

        Context 'Works with the pipeline' {
            $result = $markdown | ConvertFrom-GitHubMarkdown

            It 'Has the expected result' {
                # Replace newlines with empty for comparison purposes
                $result.Replace("`n", "").Replace("`r", "") | Should -Be $expectedHtml
            }
        }
    }

    Describe 'Get-GitHubLicense' {
        Context 'Can get the license for a repo with parameters' {
            $result = Get-GitHubLicense -OwnerName 'PowerShell' -RepositoryName 'PowerShell'

            It 'Has the expected result' {
                $result.license.key | Should -Be 'mit'
            }

            It 'Has the expected type and additional properties' {
                $result.PSObject.TypeNames[0] | Should -Be 'GitHub.Content'
                $result.LicenseKey | Should -Be $result.license.key
                $result.license.PSObject.TypeNames[0] | Should -Be 'GitHub.License'
            }
        }

        Context 'Can get the license for a repo with the repo on the pipeline' {
            $result = Get-GitHubRepository -OwnerName 'PowerShell' -RepositoryName 'PowerShell' |
                Get-GitHubLicense

            It 'Has the expected result' {
                $result.license.key | Should -Be 'mit'
            }

            It 'Has the expected type and additional properties' {
                $result.PSObject.TypeNames[0] | Should -Be 'GitHub.Content'
                $result.LicenseKey | Should -Be $result.license.key
                $result.license.PSObject.TypeNames[0] | Should -Be 'GitHub.License'
            }
        }

        Context 'Can get all of the licenses' {
            $results = @(Get-GitHubLicense)

            It 'Has the expected result' {
                # The number of licenses on GitHub is unlikely to remain static.
                # Let's just make sure that we have a few results
                $results.Count | Should -BeGreaterThan 3
            }

            It 'Has the expected type and additional properties' {
                foreach ($license in $results)
                {
                    $license.PSObject.TypeNames[0] | Should -Be 'GitHub.License'
                    $license.LicenseKey | Should -Be $license.key
                }
            }
        }

        Context 'Can get a specific license' {
            $result = Get-GitHubLicense -Key 'mit'

            It 'Has the expected result' {
                $result.key | Should -Be 'mit'
            }

            It 'Has the expected type and additional properties' {
                $result.PSObject.TypeNames[0] | Should -Be 'GitHub.License'
                $result.LicenseKey | Should -Be $result.key
            }

            $again = $result | Get-GitHubLicense
            It 'Has the expected result' {
                $again.key | Should -Be 'mit'
            }

            It 'Has the expected type and additional properties' {
                $again.PSObject.TypeNames[0] | Should -Be 'GitHub.License'
                $again.LicenseKey | Should -Be $again.key
            }
        }
    }

    Describe 'Get-GitHubEmoji' {
        Context 'Is working' {
            $result = Get-GitHubEmoji

            It 'Has the expected type' {
                $result.PSObject.TypeNames[0] | Should -Be 'GitHub.Emoji'
            }
        }
    }

    Describe 'Get-GitHubCodeOfConduct' {
        Context 'Can get the code of conduct for a repo with parameters' {
            $result = Get-GitHubCodeOfConduct -OwnerName 'PowerShell' -RepositoryName 'PowerShell'

            It 'Has the expected result' {
                $result.key | Should -Be 'other'
            }

            It 'Has the expected type and additional properties' {
                $result.PSObject.TypeNames[0] | Should -Be 'GitHub.CodeOfConduct'
                $result.CodeOfConductKey | Should -Be $result.key
            }
        }

        Context 'Can get the code of conduct for a repo with the repo on the pipeline' {
            $result = Get-GitHubRepository -OwnerName 'PowerShell' -RepositoryName 'PowerShell' |
                Get-GitHubCodeOfConduct

            It 'Has the expected result' {
                $result.key | Should -Be 'other'
            }

            It 'Has the expected type and additional properties' {
                $result.PSObject.TypeNames[0] | Should -Be 'GitHub.CodeOfConduct'
                $result.CodeOfConductKey | Should -Be $result.key
            }
        }

        Context 'Can get all of the codes of conduct' {
            $results = @(Get-GitHubCodeOfConduct)

            It 'Has the expected results' {
                # The number of codes of conduct on GitHub is unlikely to remain static.
                # Let's just make sure that we have a couple results
                $results.Count | Should -BeGreaterOrEqual 2
            }

            It 'Has the expected type and additional properties' {
                foreach ($item in $results)
                {
                    $item.PSObject.TypeNames[0] | Should -Be 'GitHub.CodeOfConduct'
                    $item.CodeOfConductKey | Should -Be $item.key
                }
            }
        }

        Context 'Can get a specific code of conduct' {
            $key = 'contributor_covenant'
            $result = Get-GitHubCodeOfConduct -Key $key

            It 'Has the expected result' {
                $result.key | Should -Be $key
            }

            It 'Has the expected type and additional properties' {
                $result.PSObject.TypeNames[0] | Should -Be 'GitHub.CodeOfConduct'
                $result.CodeOfConductKey | Should -Be $result.key
            }

            $again = $result | Get-GitHubCodeOfConduct
            It 'Has the expected result' {
                $again.key | Should -Be $key
            }

            It 'Has the expected type and additional properties' {
                $again.PSObject.TypeNames[0] | Should -Be 'GitHub.CodeOfConduct'
                $again.CodeOfConductKey | Should -Be $again.key
            }
        }
    }

    Describe 'Get-GitHubGitIgnore' {
        Context 'Gets all the known .gitignore files' {
            $result = Get-GitHubGitIgnore

            It 'Has the expected values' {
                # The number of .gitignore files on GitHub is unlikely to remain static.
                # Let's just make sure that we have a bunch of results
                $result.Count | Should -BeGreaterOrEqual 5
            }
            It 'Has the expected type' {
                $result.PSObject.TypeNames[0] | Should -Not -Be 'GitHub.Gitignore'
            }
        }

        Context 'Gets a specific one via parameter' {
            $name = 'C'
            $result = Get-GitHubGitIgnore -Name $name

            It 'Has the expected value' {
                $result.name | Should -Be $name
                $result.source | Should -Not -BeNullOrEmpty
            }

            It 'Has the expected type' {
                $result.PSObject.TypeNames[0] | Should -Be 'GitHub.Gitignore'
            }
        }

        Context 'Gets a specific one via the pipeline' {
            $name = 'C'
            $result = $name | Get-GitHubGitIgnore

            It 'Has the expected value' {
                $result.name | Should -Be $name
                $result.source | Should -Not -BeNullOrEmpty
            }

            It 'Has the expected type' {
                $result.PSObject.TypeNames[0] | Should -Be 'GitHub.Gitignore'
            }
        }

        Context 'Gets a specific one as raw content via the pipeline' {
            $name = 'C'
            $result = $name | Get-GitHubGitIgnore -RawContent

            It 'Has the expected value' {
                $result | Should -Not -BeNullOrEmpty
            }

            It 'Has the expected type' {
                $result.PSObject.TypeNames[0] | Should -Not -Be 'GitHub.Gitignore'
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
