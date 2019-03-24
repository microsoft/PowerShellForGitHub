# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

<#
.Synopsis
   Tests for GitHubRepositoryMerge.ps1 module
#>

[String] $root = Split-Path -Parent (Split-Path -Parent $Script:MyInvocation.MyCommand.Path)
. (Join-Path -Path $root -ChildPath 'Tests\Config\Settings.ps1')
Import-Module -Name $root -Force

function Create-Branch($repoName, $branchName)
{
    $existingref = @(Get-GitHubReference -OwnerName $ownerName -RepositoryName $repoName -Reference "heads/master")
    $sha = $existingref.object.sha
    New-GitHubReference -OwnerName $ownerName -RepositoryName $repoName -Reference $branchName -Sha $sha
}

function Initialize-AppVeyor
{
<#
    .SYNOPSIS
        Configures the tests to run with the authentication information stored in AppVeyor
        (if that information exists in the environment).

    .DESCRIPTION
        Configures the tests to run with the authentication information stored in AppVeyor
        (if that information exists in the environment).

        The Git repo for this module can be found here: http://aka.ms/PowerShellForGitHub

    .NOTES
        Internal-only helper method.

        The only reason this exists is so that we can leverage CodeAnalysis.SuppressMessageAttribute,
        which can only be applied to functions.

        We call this immediately after the declaration so that AppVeyor initialization can heppen
        (if applicable).

#>
    [CmdletBinding()]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingConvertToSecureStringWithPlainText", "", Justification="Needed to configure with the stored, encrypted string value in AppVeyor.")]
    param()

    if ($env:AppVeyor)
    {
        $secureString = $env:avAccessToken | ConvertTo-SecureString -AsPlainText -Force
        $cred = New-Object System.Management.Automation.PSCredential "<username is ignored>", $secureString
        Set-GitHubAuthentication -Credential $cred

        $script:ownerName = $env:avOwnerName
        $script:organizationName = $env:avOrganizationName

        $message = @(
            'This run is executed in the AppVeyor environment.',
            'The GitHub Api Token won''t be decrypted in PR runs causing some tests to fail.',
            '403 errors possible due to GitHub hourly limit for unauthenticated queries.',
            'Use Set-GitHubAuthentication manually. modify the values in Tests\Config\Settings.ps1,',
            'and run tests on your machine first.')
        Write-Warning -Message ($message -join [Environment]::NewLine)
    }
}

Initialize-AppVeyor

$script:accessTokenConfigured = Test-GitHubAuthenticationConfigured
if (-not $script:accessTokenConfigured)
{
    $message = @(
        'GitHub API Token not defined, some of the tests will be skipped.',
        '403 errors possible due to GitHub hourly limit for unauthenticated queries.')
    Write-Warning -Message ($message -join [Environment]::NewLine)
}

# Backup the user's configuration before we begin, and ensure we're at a pure state before running
# the tests.  We'll restore it at the end.
$configFile = New-TemporaryFile
try
{
    Backup-GitHubConfiguration -Path $configFile
    Reset-GitHubConfiguration
    Set-GitHubConfiguration -DisableTelemetry # We don't want UT's to impact telemetry
    Set-GitHubConfiguration -LogRequestBody # Make it easier to debug UT failures

    Describe 'Creating and merging a branch to master' {
        #TODO: Remove the below note before merging
        #NOTE: These changes depend on the GitHubReference changes
        # and should be merged only after those changes are merged
        $repoName = [Guid]::NewGuid().Guid
        $repo = New-GitHubRepository -RepositoryName $repoName -AutoInit
        $branchName = "refs/heads/" + $([Guid]::NewGuid().Guid).ToString()
        Create-Branch $repoName $branchName

        Context 'Merging a branch with the same changes as base' {
            $result = Merge-GitHubRepositoryBranch -OwnerName $ownerName -RepositoryName $repoName -Base 'master' -Head $branchName -CommitMessage 'This merge isnt needed'

            It "Should return null" {
                $result | Should be $null
            }
        }

        Context 'Merging a branch to non-existent base' {
            $result = Merge-GitHubRepositoryBranch -OwnerName $ownerName -RepositoryName $repoName -Base ([Guid]::NewGuid().Guid) -Head $branchName -CommitMessage 'This base doesnt exist'

            It "Should return null" {
                $result | Should be $null
            }
        }

        Context 'Merging a non-existent branch to base' {
            $result = Merge-GitHubRepositoryBranch -OwnerName $ownerName -RepositoryName $repoName -Base 'master' -Head ([Guid]::NewGuid().Guid) -CommitMessage 'This merge isnt happening'

            It "Should return null" {
                $result | Should be $null
            }
        }

        #TODO: Test cases for
        # 1. merge conflict
        # 2. actual merging
        # 3. Empty commit message

        Remove-GitHubRepository -Uri $repo.svn_url
    }
}
finally
{
    # Restore the user's configuration to its pre-test state
    Restore-GitHubConfiguration -Path $configFile
}