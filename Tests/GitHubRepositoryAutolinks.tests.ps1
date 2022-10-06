# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

<#
.Synopsis
   Tests for GitHubRepositoryAutolink.ps1 module
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
    # Define Script-scoped, readonly, hidden variables.
    @{
        defaultRepoDesc = "This is a description."
        defaultRepoHomePage = "https://www.microsoft.com/"
        defaultRepoTopic = "microsoft"
    }.GetEnumerator() | ForEach-Object {
        Set-Variable -Force -Scope Script -Option ReadOnly -Visibility Private -Name $_.Key -Value $_.Value
    }

    Describe 'GitHubRepositoryAutolink\Get-GitHubRepositoryAutolink' {
        BeforeAll {
            $organizationName = $script:organizationName
        }

        Context 'When getting a GitHub Repository Autolinks by repository' {
            BeforeAll {
                $repoName = [Guid]::NewGuid().Guid

                $repo = New-GitHubRepository -RepositoryName $repoName -OrganizationName $organizationName

                $keyPrefix = 'PRJ-'
                $urlTemplate = 'https://company.issuetracker.com/browse/prj-<num>'
                $isNumericOnly = $true

                $newGitHubRepositoryAutolinkParms = @{
                    OrganizationName = $organizationName
                    KeyPrefix = $keyPrefix
                    UrlTemplate = $urlTemplate
                    IsNumericOnly = $isNumericOnly
                }

                New-GitHubRepositoryAutolink @newGitHubRepositoryAutolinkParms | Out-Null

                $autoLinks = Get-GitHubRepositoryAutolink -OwnerName $organizationName -RepositoryName $repoName
                $autolink = $autoLinks | Where-Object -Property AutolinkKeyPrefix -eq $keyPrefix
            }

            It 'Should have the expected type and additional properties' {
                $team.PSObject.TypeNames[0] | Should -Be 'GitHub.RepositoryAutolink'
                $team.AutolinkKeyPrefix | Should -Be $keyPrefix
                $team.AutolinkUrlTemplate | Should -Be $urlTemplate
                $team.IsNumericOnly | Should -BeTrue
                $team.AutolinkId | Should -BeGreaterThan 0
                $team.KeyPrefix | Should -Be $autolink.keyPrefix
                $team.UrlTemplate | Should -Be $autolink.urlTemplate
                $team.AutolinkId | Should -Be $autolink.id
                $team.OrganizationName | Should -Be $organizationName
            }

            AfterAll {
                if (Get-Variable -Name repo -ErrorAction SilentlyContinue)
                {
                    $repo | Remove-GitHubRepository -Force
                }

                if (Get-Variable -Name team -ErrorAction SilentlyContinue)
                {
                    $autolink | Remove-GitHubRepositoryAutolink -Force
                }
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
