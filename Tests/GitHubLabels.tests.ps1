# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

<#
.Synopsis
   Tests for GitHubLabels.ps1 module
#>

[String] $root = Split-Path -Parent (Split-Path -Parent $Script:MyInvocation.MyCommand.Path)
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
Backup-GitHubConfiguration -Path $configFile
Reset-GitHubConfiguration

$script:defaultLabels = @(
    @{
        'name' = 'pri:lowest'
        'color' = '4285F4'
    },
    @{
        'name' = 'pri:low'
        'color' = '4285F4'
    },
    @{
        'name' = 'pri:medium'
        'color' = '4285F4'
    },
    @{
        'name' = 'pri:high'
        'color' = '4285F4'
    },
    @{
        'name' = 'pri:highest'
        'color' = '4285F4'
    },
    @{
        'name' = 'bug'
        'color' = 'fc2929'
    },
    @{
        'name' = 'duplicate'
        'color' = 'cccccc'
    },
    @{
        'name' = 'enhancement'
        'color' = '121459'
    },
    @{
        'name' = 'up for grabs'
        'color' = '159818'
    },
    @{
        'name' = 'question'
        'color' = 'cc317c'
    },
    @{
        'name' = 'discussion'
        'color' = 'fe9a3d'
    },
    @{
        'name' = 'wontfix'
        'color' = 'dcb39c'
    },
    @{
        'name' = 'in progress'
        'color' = 'f0d218'
    },
    @{
        'name' = 'ready'
        'color' = '145912'
    }
)

if ($script:accessTokenConfigured)
{
    Describe 'Getting labels from repository' {
        $repositoryName = [Guid]::NewGuid().Guid
        $null = New-GitHubRepository -RepositoryName $repositoryName
        Set-GitHubLabel -OwnerName $script:ownerName -RepositoryName $repositoryName -Label $script:defaultLabels

        Context 'When querying for all labels' {
            $labels = Get-GitHubLabel -OwnerName $script:ownerName -RepositoryName $repositoryName

            It 'Should return expected number of labels' {
                $($labels).Count | Should be $script:defaultLabels.Count
            }
        }

        Context 'When querying for specific label' {
            $label = Get-GitHubLabel -OwnerName $script:ownerName -RepositoryName $repositoryName -Name bug

            It 'Should return expected label' {
                $label.name | Should be "bug"
            }
        }

        $null = Remove-GitHubRepository -OwnerName $script:ownerName -RepositoryName $repositoryName
    }

    Describe 'Creating new label' {
        $repositoryName = [Guid]::NewGuid().Guid
        $null = New-GitHubRepository -RepositoryName $repositoryName

        $labelName = [Guid]::NewGuid().Guid
        New-GitHubLabel -OwnerName $script:ownerName -RepositoryName $repositoryName -Name $labelName -Color BBBBBB
        $label = Get-GitHubLabel -OwnerName $script:ownerName -RepositoryName $repositoryName -Name $labelName

        It 'New label should be created' {
            $label.name | Should be $labelName
        }

        AfterEach {
            Remove-GitHubLabel -OwnerName $script:ownerName -RepositoryName $repositoryName -Name $labelName
        }

        $null = Remove-GitHubRepository -OwnerName $script:ownerName -RepositoryName $repositoryName
    }

    Describe 'Removing label' {
        $repositoryName = [Guid]::NewGuid().Guid
        $null = New-GitHubRepository -RepositoryName $repositoryName
        Set-GitHubLabel -OwnerName $script:ownerName -RepositoryName $repositoryName -Label $script:defaultLabels

        $labelName = [Guid]::NewGuid().Guid
        New-GitHubLabel -OwnerName $script:ownerName -RepositoryName $repositoryName -Name $labelName -Color BBBBBB
        $labels = Get-GitHubLabel -OwnerName $script:ownerName -RepositoryName $repositoryName

        It 'Should return increased number of labels' {
            $($labels).Count | Should be ($script:defaultLabels.Count + 1)
        }

        Remove-GitHubLabel -OwnerName $script:ownerName -RepositoryName $repositoryName -Name $labelName
        $labels = Get-GitHubLabel -OwnerName $script:ownerName -RepositoryName $repositoryName

        It 'Should return expected number of labels' {
            $($labels).Count | Should be $script:defaultLabels.Count
        }

        $null = Remove-GitHubRepository -OwnerName $script:ownerName -RepositoryName $repositoryName
    }

    Describe 'Updating label' {
        $repositoryName = [Guid]::NewGuid().Guid
        $null = New-GitHubRepository -RepositoryName $repositoryName

        $labelName = [Guid]::NewGuid().Guid

        Context 'Updating label color' {
            New-GitHubLabel -OwnerName $script:ownerName -RepositoryName $repositoryName -Name $labelName -Color BBBBBB
            Update-GitHubLabel -OwnerName $script:ownerName -RepositoryName $repositoryName -Name $labelName -NewName $labelName -Color AAAAAA
            $label = Get-GitHubLabel -OwnerName $script:ownerName -RepositoryName $repositoryName -Name $labelName

            AfterEach {
                Remove-GitHubLabel -OwnerName $script:ownerName -RepositoryName $repositoryName -Name $labelName
            }

            It 'Label should have different color' {
                $label.color | Should be AAAAAA
            }
        }

        Context 'Updating label name' {
            $newLabelName = $labelName + "2"
            New-GitHubLabel -OwnerName $script:ownerName -RepositoryName $repositoryName -Name $labelName -Color BBBBBB
            Update-GitHubLabel -OwnerName $script:ownerName -RepositoryName $repositoryName -Name $labelName -NewName $newLabelName -Color BBBBBB
            $label = Get-GitHubLabel -OwnerName $script:ownerName -RepositoryName $repositoryName -Name $newLabelName

            AfterEach {
                Remove-GitHubLabel -OwnerName $script:ownerName -RepositoryName $repositoryName -Name $newLabelName
            }

            It 'Label should have different color' {
                $label | Should not be $null
                $label.color | Should be BBBBBB
            }
        }

        $null = Remove-GitHubRepository -OwnerName $script:ownerName -RepositoryName $repositoryName
    }

    Describe 'Applying set of labels on repository' {
        $repositoryName = [Guid]::NewGuid().Guid
        $null = New-GitHubRepository -RepositoryName $repositoryName

        $labelName = [Guid]::NewGuid().Guid
        Set-GitHubLabel -OwnerName $script:ownerName -RepositoryName $repositoryName -Label $script:defaultLabels

        # Add new label
        New-GitHubLabel -OwnerName $script:ownerName -RepositoryName $repositoryName -Name $labelName -Color BBBBBB
        $labels = Get-GitHubLabel -OwnerName $script:ownerName -RepositoryName $repositoryName

        # Change color of existing label
        Update-GitHubLabel -OwnerName $script:ownerName -RepositoryName $repositoryName -Name "bug" -NewName "bug" -Color BBBBBB

        # Remove one of approved labels"
        Remove-GitHubLabel -OwnerName $script:ownerName -RepositoryName $repositoryName -Name "discussion"

        It 'Should return increased number of labels' {
            $($labels).Count | Should be ($script:defaultLabels.Count + 1)
        }

        Set-GitHubLabel -OwnerName $script:ownerName -RepositoryName $repositoryName -Label $script:defaultLabels
        $labels = Get-GitHubLabel -OwnerName $script:ownerName -RepositoryName $repositoryName

        It 'Should return expected number of labels' {
            $($labels).Count | Should be $script:defaultLabels.Count
            $bugLabel = $labels | Where-Object {$_.name -eq "bug"}
            $bugLabel.color | Should be "fc2929"
        }

        $null = Remove-GitHubRepository -OwnerName $script:ownerName -RepositoryName $repositoryName
    }
}

# Restore the user's configuration to its pre-test state
Restore-GitHubConfiguration -Path $configFile
