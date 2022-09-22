# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

<#
.Synopsis
   Tests for GitHubOrganizations.ps1 module
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

# TODO once more capabilities exist in the module's API set

# TODO: Re-enable these tests once the module has sufficient support getting the Organization
# and repository into the required state for testing, and to recover back to the original state
# at the conclusion of the test.

# Describe 'Obtaining organization members' {
#     $members = Get-GitHubOrganizationMember -OrganizationName $script:organizationName

#     It 'Should return expected number of organization members' {
#         @($members).Count | Should -Be 1
#     }
# }

# Describe 'Obtaining organization teams' {
#     $teams = Get-GitHubTeam -OrganizationName $script:organizationName

#     It 'Should return expected number of organization teams' {
#         @($teams).Count | Should -Be 2
#     }
# }

# Describe 'Obtaining organization team members' {
#     $members = Get-GitHubTeamMember -OrganizationName $script:organizationName -TeamName $script:organizationTeamName

#     It 'Should return expected number of organization team members' {
#         @($members).Count | Should -Be 1
#     }
# }

AfterAll {
    if (Test-Path -Path $script:originalConfigFile -PathType Leaf)
    {
        # Restore the user's configuration to its pre-test state
        Restore-GitHubConfiguration -Path $script:originalConfigFile
        $script:originalConfigFile = $null
    }
}
