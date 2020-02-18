# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

# Caches if the tests are actively configured with an access token.
$script:accessTokenConfigured = $false

# The path to a file storing the contents of the user's config file before tests got underway
$script:originalConfigFile = $null

function Initialize-CommonTestSetup
{
<#
    .SYNOPSIS
        Configures the tests to run with the authentication information stored in the project's
        Azure DevOps pipeline (if that information exists in the environment).

    .DESCRIPTION
        Configures the tests to run with the authentication information stored in the project's
        Azure DevOps pipeline (if that information exists in the environment).

        The Git repo for this module can be found here: http://aka.ms/PowerShellForGitHub

    .NOTES
        Internal-only helper method.

        The only reason this exists is so that we can leverage CodeAnalysis.SuppressMessageAttribute,
        which can only be applied to functions.

        This method is invoked immediately after the declaration.
#>
    [CmdletBinding()]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingConvertToSecureStringWithPlainText", "", Justification="Needed to configure with the stored, encrypted string value in AppVeyor.")]
    param()

    $moduleRootPath = Split-Path -Path $PSScriptRoot -Parent
    $settingsPath = Join-Path -Path $moduleRootPath -ChildPath 'Tests/Config/Settings.ps1'
    . $settingsPath
    Import-Module -Name (Join-Path -Path $moduleRootPath -ChildPath 'PowerShellForGitHub.psd1') -Force

    $originalSettingsHash = (Get-GitHubConfiguration -Name TestConfigSettingsHash)
    $currentSettingsHash = Get-SHA512Hash -PlainText (Get-Content -Path $settingsPath -Raw -Encoding Utf8)
    $settingsAreUnaltered = $originalSettingsHash -eq $currentSettingsHash

    if ([string]::IsNullOrEmpty($env:ciAccessToken))
    {
        if ($settingsAreUnaltered)
        {
            $message = @(
                'The tests are using the configuration settings defined in Tests/Config/Settings.ps1.',
                'If you haven''t locally modified those values, your tests are going to fail since you',
                'don''t have access to the default accounts referenced.  If that is the case, you should',
                'cancel the existing tests, modify the values to ones you have access to, call',
                'Set-GitHubAuthentication to cache your AccessToken, and then try running the tests again.')
            Write-Warning -Message ($message -join [Environment]::NewLine)
        }
    }
    else
    {
        $secureString = $env:ciAccessToken | ConvertTo-SecureString -AsPlainText -Force
        $cred = New-Object System.Management.Automation.PSCredential "<username is ignored>", $secureString
        Set-GitHubAuthentication -Credential $cred

        $script:ownerName = $env:ciOwnerName
        $script:organizationName = $env:ciOrganizationName

        Write-Warning -Message 'This run is being executed in the Azure Dev Ops environment.'
    }

    $script:accessTokenConfigured = Test-GitHubAuthenticationConfigured
    if (-not $script:accessTokenConfigured)
    {
        $message = @(
            'GitHub API Token not defined.  Most of these tests are going to fail since they require authentication.',
            '403 errors may also start to occur due to the GitHub hourly limit for unauthenticated queries.')
        Write-Warning -Message ($message -join [Environment]::NewLine)
    }

    # Backup the user's configuration before we begin, and ensure we're at a pure state before running
    # the tests.  We'll restore it at the end.
    $script:originalConfigFile = New-TemporaryFile

    Backup-GitHubConfiguration -Path $script:originalConfigFile
    Set-GitHubConfiguration -DisableTelemetry # Avoid the telemetry event from calling Reset-GitHubConfiguration
    Reset-GitHubConfiguration
    Set-GitHubConfiguration -DisableTelemetry # We don't want UT's to impact telemetry
    Set-GitHubConfiguration -LogRequestBody # Make it easier to debug UT failures
}

Initialize-CommonTestSetup
