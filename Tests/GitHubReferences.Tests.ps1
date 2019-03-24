# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

<#
.Synopsis
   Tests for GitHubReferences.ps1 module
#>

[String] $root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
. (Join-Path -Path $root -ChildPath 'Tests\Config\Settings.ps1')
Import-Module -Name $root -Force

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

$accessTokenConfigured = Test-GitHubAuthenticationConfigured
if (-not $accessTokenConfigured)
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

    if ($accessTokenConfigured)
    {

        Describe 'Create a new reference(branch) in repository' {
            $repositoryName = [Guid]::NewGuid()
            $repo = New-GitHubRepository -RepositoryName $repositoryName -AutoInit
            $existingref = @(Get-GitHubReference -OwnerName $ownerName -RepositoryName $repositoryName -Reference "heads/master")
            $sha = $existingref.object.sha

            Context 'On creating a valid reference in a new repository from a given SHA' {
                $refName = "refs/heads/" + [Guid]::NewGuid().ToString()
                $result = @(New-GitHubReference -OwnerName $ownerName -RepositoryName $repositoryName -Reference $refName -Sha $sha)

                It 'Should successfully create the reference' {
                    $result.ref | Should Be $refName
                }
            }

            Context 'On creating a valid reference in a new repository (specified by Uri) from a given SHA' {
                $refName = "refs/heads/" + [Guid]::NewGuid().ToString()
                $result = @(New-GitHubReference -Uri $repo.svn_url -Reference $refName -Sha $sha)

                It 'Should successfully create the reference' {
                    $result.ref | Should Be $refName
                }
            }

            Context 'On creating an existing reference in a new repository from a given SHA' {
                $refName = "refs/heads/master"

                It 'Should throw an Exception' {
                    { @(New-GitHubReference -OwnerName $ownerName -RepositoryName $repositoryName -Reference $refName -Sha $sha) } | Should Throw
                }
            }

            Context 'On creating an existing reference in a new repository (specified by Uri) from a given SHA' {
                $refName = "refs/heads/master"

                It 'Should throw an exception' {
                    { @(New-GitHubReference -Uri $repo.svn_url -Reference $refName -Sha $sha) }  | Should Throw
                }
            }



            $null = Remove-GitHubRepository -OwnerName $ownerName -RepositoryName $repositoryName
        }

        Describe 'Getting a reference(branch) from repository' {
            $repositoryName = [Guid]::NewGuid()
            $repo = New-GitHubRepository -RepositoryName $repositoryName -AutoInit

            Context 'On getting a valid reference from a new repository' {
                $reference = @(Get-GitHubReference -OwnerName $ownerName -RepositoryName $repositoryName -Reference "heads/master")

                It 'Should return details of the reference' {
                    $reference.ref | Should be "refs/heads/master"
                }
            }

            Context 'On getting an invalid reference from a new repository' {
                $reference = @(Get-GitHubReference -OwnerName $ownerName -RepositoryName $repositoryName -Reference "heads/someRandomRef")

                It 'Should not return any details' {
                    $reference | Should be $null
                }
            }

            Context 'On getting a valid reference using Uri from a new repository' {
                $reference = @(Get-GitHubReference -Uri $repo.svn_url -Reference "heads/master")

                It 'Should return details of the reference' {
                    $reference.ref | Should be "refs/heads/master"
                }
            }

            Context 'On getting an invalid reference using Uri from a new repository' {
                $reference = @(Get-GitHubReference -Uri $repo.svn_url -Reference "heads/someRandomRef")

                It 'Should not return any details' {
                    $reference | Should be $null
                }
            }
            $null = Remove-GitHubRepository -OwnerName $ownerName -RepositoryName $repositoryName
        }
    }
}
catch
{
    # Restore the user's configuration to its pre-test state
    Restore-GitHubConfiguration -Path $configFile
}

