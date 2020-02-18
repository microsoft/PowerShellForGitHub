# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

<#
    .NOTES
    A hash of this file is stored in GitHubConfiguration.ps1 within the Import-GitHubConfiguration function
    as TestConfigSettingsHash (and can be retrieved by calling Get-GitHubConfiguration -Name TestConfigSettingsHash).
    It is used when trying to detect if the file has been updated with personal settings before unit tests
    are run locally (since unit tests will otherwise fail because users do not have account permissions to
    access the accounts below).

    If this file is being modified as part of an intended change to the official repo, please be sure to
    additionally update the value of TestConfigSettingsHash in GitHubConfiguration.ps1 by running:

        . ./Helpers.ps1; Get-Sha512Hash -PlainText (Get-Content -Path ./Tests/Config/Settings.ps1 -Raw -Encoding Utf8)
#>

# The account that the tests will be running under
$script:ownerName = 'PowerShellForGitHubTeam'

# The organization that the tests will be running under
$script:organizationName = 'PowerShellForGitHubTeamTestOrg'