# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

<#
.Synopsis
   Tests for GitHubContents.ps1 module
#>

# This is common test code setup logic for all Pester test files
$moduleRootPath = Split-Path -Path $PSScriptRoot -Parent
. (Join-Path -Path $moduleRootPath -ChildPath 'Tests\Common.ps1')

try
{
    # Define Script-scoped, readonly, hidden variables.
    @{
        repoGuid = [Guid]::NewGuid().Guid
    }.GetEnumerator() | ForEach-Object {
        Set-Variable -Force -Scope Script -Option ReadOnly -Visibility Private -Name $_.Key -Value $_.Value
    }

    Describe 'Getting file content' {
        $repo = New-GitHubRepository -RepositoryName ($repoGuid) -AutoInit

        Context 'For getting raw (default) file contents' {

            # AutoInit will create a readme with the GUID of the repo name
            $readmeFileBytes = Get-GitHubContent -OwnerName $script:ownerName -RepositoryName $repo.name -Path "README.md"
            $readmeFileString = [System.Text.Encoding]::UTF8.GetString($readmeFileBytes)

            It "Should have the expected file text" {
                $readmeFileString | Should be "# $repoGuid"
            }
        }

        Remove-GitHubRepository -Uri $repo.svn_url
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
