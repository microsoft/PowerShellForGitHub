# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

# PSScriptAnalyzer incorrectly flags a number of variables as PSUseDeclaredVarsMoreThanAssignments
# since it doesn't work well with variables defined in BeforeAll{} but only referenced in a later Context.
# We are suppressing that rule in Test files, which means that we are then losing out on catching
# scenarios where we might be assigning to a variable and then referencing it with a typo.
# By setting StrictMode, the test file will immediately fail if there are any variables that are
# being referenced before they were assigned.  It won't catch variables that are assigned to but
# never referenced, but that's not as big of a deal for tests.
Set-StrictMode -Version 1.0

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
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingConvertToSecureStringWithPlainText", "", Justification = "Needed to configure with the stored, encrypted string value in Azure DevOps.")]
    param()

    $script:moduleName = 'PowerShellForGitHub'
    $moduleRootPath = Split-Path -Path $PSScriptRoot -Parent
    $settingsPath = Join-Path -Path $moduleRootPath -ChildPath 'Tests/Config/Settings.ps1'
    . $settingsPath
    Import-Module -Name (Join-Path -Path $moduleRootPath -ChildPath 'PowerShellForGitHub.psd1') -Force

    # Get-SHA512 is an internal helper function that is not normally exposed.
    # We need to explicitly load it into our execution context in order to use it below.
    $moduleRootPath = Split-Path -Path $PSScriptRoot -Parent
    . (Join-Path -Path $moduleRootPath -ChildPath 'Helpers.ps1')

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
    Set-GitHubConfiguration -MultiRequestProgressThreshold 0 # Status corrupts the raw CI logs for Linux and Mac, and makes runs take slightly longer.
    Set-GitHubConfiguration -DisableUpdateCheck # The update check is unnecessary during tests.

    # We execute so many successive state changing commands on the same object that sometimes
    # GitHub gets confused.  We'll add an intentional delay to slow down our execution in an effort
    # to increase the reliability of the tests.
    Set-GitHubConfiguration -StateChangeDelaySeconds 3
}

Initialize-CommonTestSetup
