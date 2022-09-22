# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

<#
.Synopsis
   Tests for GitHubMiscellaneous.ps1 module
#>

[CmdletBinding()]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '',
    Justification = 'Suppress false positives in Pester code blocks')]
param()

Describe 'Get-GitHubRateLimit' {
    BeforeAll {
        # This is common test code setup logic for all Pester test files
        $moduleRootPath = Split-Path -Path $PSScriptRoot -Parent
        . (Join-Path -Path $moduleRootPath -ChildPath 'Tests\Common.ps1')
    }

    AfterAll {
        # Restore the user's configuration to its pre-test state
        Restore-GitHubConfiguration -Path $script:originalConfigFile
        $script:originalConfigFile = $null
    }

    Context 'Is working' {
        BeforeAll {
            $result = Get-GitHubRateLimit
        }

        It 'Has the expected type' {
            $result.PSObject.TypeNames[0] | Should -Be 'GitHub.RateLimit'
        }
    }
}

Describe 'ConvertFrom-GitHubMarkdown' {
    BeforeAll {
        # This is common test code setup logic for all Pester test files
        $moduleRootPath = Split-Path -Path $PSScriptRoot -Parent
        . (Join-Path -Path $moduleRootPath -ChildPath 'Tests\Common.ps1')
    }

    AfterAll {
        # Restore the user's configuration to its pre-test state
        Restore-GitHubConfiguration -Path $script:originalConfigFile
        $script:originalConfigFile = $null
    }

    Context 'Works with the parameter' {
        BeforeAll {
            $markdown = '**PowerShellForGitHub**'
            $expectedHtml = '<p><strong>PowerShellForGitHub</strong></p>'
        }

        It 'Has the expected result as a parameter' {
            $result = ConvertFrom-GitHubMarkdown -Content $markdown

            # Replace newlines with empty for comparison purposes
            $result.Replace("`n", "").Replace("`r", "") | Should -Be $expectedHtml
        }

        It 'Has the expected result with the pipeline' {
            $result = $markdown | ConvertFrom-GitHubMarkdown

            # Replace newlines with empty for comparison purposes
            $result.Replace("`n", "").Replace("`r", "") | Should -Be $expectedHtml
        }
    }
}

Describe 'Get-GitHubLicense' {
    BeforeAll {
        # This is common test code setup logic for all Pester test files
        $moduleRootPath = Split-Path -Path $PSScriptRoot -Parent
        . (Join-Path -Path $moduleRootPath -ChildPath 'Tests\Common.ps1')
    }

    AfterAll {
        # Restore the user's configuration to its pre-test state
        Restore-GitHubConfiguration -Path $script:originalConfigFile
        $script:originalConfigFile = $null
    }

    Context 'Can get the license for a repo with parameters' {
        BeforeAll {
            $result = Get-GitHubLicense -OwnerName 'PowerShell' -RepositoryName 'PowerShell'
        }

        It 'Has the expected result' {
            $result.license.key | Should -Be 'mit'
        }

        It 'Has the expected type and additional properties' {
            $result.PSObject.TypeNames[0] | Should -Be 'GitHub.Content'
            $result.LicenseKey | Should -Be $result.license.key
            $result.license.PSObject.TypeNames[0] | Should -Be 'GitHub.License'
        }
    }

    Context 'Will fail if not provided both OwnerName and RepositoryName' {
        It 'Should fail if only OwnerName is specified' {
            { Get-GitHubLicense -OwnerName 'PowerShell' } | Should -Throw
        }

        It 'Should fail if only RepositoryName is specified' {
            { Get-GitHubLicense -RepositoryName 'PowerShell' } | Should -Throw
        }
    }

    Context 'Can get the license for a repo with the repo on the pipeline' {
        BeforeAll {
            $result = Get-GitHubRepository -OwnerName 'PowerShell' -RepositoryName 'PowerShell' | Get-GitHubLicense
        }

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
        BeforeAll {
            $results = @(Get-GitHubLicense)
        }

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
        BeforeAll {
            $result = Get-GitHubLicense -Key 'mit'
            $again = $result | Get-GitHubLicense
        }

        It 'Has the expected result' {
            $result.key | Should -Be 'mit'
        }

        It 'Has the expected type and additional properties' {
            $result.PSObject.TypeNames[0] | Should -Be 'GitHub.License'
            $result.LicenseKey | Should -Be $result.key
        }

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
    BeforeAll {
        # This is common test code setup logic for all Pester test files
        $moduleRootPath = Split-Path -Path $PSScriptRoot -Parent
        . (Join-Path -Path $moduleRootPath -ChildPath 'Tests\Common.ps1')
    }

    AfterAll {
        # Restore the user's configuration to its pre-test state
        Restore-GitHubConfiguration -Path $script:originalConfigFile
        $script:originalConfigFile = $null
    }

    Context 'Is working' {
        BeforeAll {
            $result = Get-GitHubEmoji
        }

        It 'Has the expected type' {
            $result.PSObject.TypeNames[0] | Should -Be 'GitHub.Emoji'
        }
    }
}

Describe 'Get-GitHubCodeOfConduct' {
    BeforeAll {
        # This is common test code setup logic for all Pester test files
        $moduleRootPath = Split-Path -Path $PSScriptRoot -Parent
        . (Join-Path -Path $moduleRootPath -ChildPath 'Tests\Common.ps1')
    }

    AfterAll {
        # Restore the user's configuration to its pre-test state
        Restore-GitHubConfiguration -Path $script:originalConfigFile
        $script:originalConfigFile = $null
    }

    Context 'Can get all of the codes of conduct' {
        BeforeAll {
            $results = @(Get-GitHubCodeOfConduct)
        }

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
        BeforeAll {
            $key = 'contributor_covenant'
            $result = Get-GitHubCodeOfConduct -Key $key
            $again = $result | Get-GitHubCodeOfConduct
        }

        It 'Has the expected result' {
            $result.key | Should -Be $key
        }

        It 'Has the expected type and additional properties' {
            $result.PSObject.TypeNames[0] | Should -Be 'GitHub.CodeOfConduct'
            $result.CodeOfConductKey | Should -Be $result.key
        }

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
    BeforeAll {
        # This is common test code setup logic for all Pester test files
        $moduleRootPath = Split-Path -Path $PSScriptRoot -Parent
        . (Join-Path -Path $moduleRootPath -ChildPath 'Tests\Common.ps1')
    }

    AfterAll {
        # Restore the user's configuration to its pre-test state
        Restore-GitHubConfiguration -Path $script:originalConfigFile
        $script:originalConfigFile = $null
    }

    Context 'Gets all the known .gitignore files' {
        BeforeAll {
            $result = Get-GitHubGitIgnore
        }

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
        BeforeAll {
            $name = 'C'
            $result = Get-GitHubGitIgnore -Name $name
        }

        It 'Has the expected value' {
            $result.name | Should -Be $name
            $result.source | Should -Not -BeNullOrEmpty
        }

        It 'Has the expected type' {
            $result.PSObject.TypeNames[0] | Should -Be 'GitHub.Gitignore'
        }
    }

    Context 'Gets a specific one via the pipeline' {
        BeforeAll {
            $name = 'C'
            $result = $name | Get-GitHubGitIgnore
        }

        It 'Has the expected value' {
            $result.name | Should -Be $name
            $result.source | Should -Not -BeNullOrEmpty
        }

        It 'Has the expected type' {
            $result.PSObject.TypeNames[0] | Should -Be 'GitHub.Gitignore'
        }
    }

    Context 'Gets a specific one as raw content via the pipeline' {
        BeforeAll {
            $name = 'C'
            $result = $name | Get-GitHubGitIgnore -RawContent
        }

        It 'Has the expected value' {
            $result | Should -Not -BeNullOrEmpty
        }

        It 'Has the expected type' {
            $result.PSObject.TypeNames[0] | Should -Not -Be 'GitHub.Gitignore'
        }
    }
}
