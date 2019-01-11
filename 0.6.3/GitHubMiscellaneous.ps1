# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

function Get-GitHubRateLimit
{
<#
    .SYNOPSIS
        Gets the current rate limit status for the GitHub API based on the currently configured
        authentication (Access Token).

    .DESCRIPTION
        Gets the current rate limit status for the GitHub API based on the currently configured
        authentication (Access Token).

        Use Set-GitHubAuthentication to change your current authentication (Access Token).

        The Git repo for this module can be found here: http://aka.ms/PowerShellForGitHub

    .PARAMETER AccessToken
        If provided, this will be used as the AccessToken for authentication with the
        REST Api.  Otherwise, will attempt to use the configured value or will run unauthenticated.

    .PARAMETER NoStatus
        If this switch is specified, long-running commands will run on the main thread
        with no commandline status update.  When not specified, those commands run in
        the background, enabling the command prompt to provide status information.
        If not supplied here, the DefaultNoStatus configuration property value will be used.

    .OUTPUTS
        [PSCustomObject]
        Limits returned are _per hour_.

        The Search API has a custom rate limit, separate from the rate limit
        governing the rest of the REST API. The GraphQL API also has a custom
        rate limit that is separate from and calculated differently than rate
        limits in the REST API.

        For these reasons, the Rate Limit API response categorizes your rate limit.
        Under resources, you'll see three objects:

        The core object provides your rate limit status for all non-search-related resources in the REST API.
        The search object provides your rate limit status for the Search API.
        The graphql object provides your rate limit status for the GraphQL API.

        Deprecation notice
        The rate object is deprecated.
        If you're writing new API client code or updating existing code,
        you should use the core object instead of the rate object.
        The core object contains the same information that is present in the rate object.

    .EXAMPLE
        Get-GitHubRateLimit
#>
    [CmdletBinding(SupportsShouldProcess)]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSShouldProcess", "", Justification="Methods called within here make use of PSShouldProcess, and the switch is passed on to them inherently.")]
    param(
        [string] $AccessToken,

        [switch] $NoStatus
    )

    Write-InvocationLog

    $params = @{
        'UriFragment' = 'rate_limit'
        'Method' = 'Get'
        'Description' =  "Getting your API rate limit"
        'AccessToken' = $AccessToken
        'TelemetryEventName' = $MyInvocation.MyCommand.Name
        'NoStatus' = (Resolve-ParameterWithDefaultConfigurationValue -Name NoStatus -ConfigValueName DefaultNoStatus)
    }

    return Invoke-GHRestMethod @params
}

function ConvertFrom-Markdown
{
<#
    .SYNOPSIS
        Converts arbitrary Markdown into HTML.

    .DESCRIPTION
        Converts arbitrary Markdown into HTML.

        The Git repo for this module can be found here: http://aka.ms/PowerShellForGitHub

    .PARAMETER Content
        The Markdown text to render to HTML.  Content must be 400 KB or less.

    .PARAMETER Mode
        The rendering mode for the Markdown content.

        Markdown - Renders Content in plain Markdown, just like README.md files are rendered

        GitHubFlavoredMarkdown - Creates links for user mentions as well as references to
        SHA-1 hashes, issues, and pull requests.

    .PARAMETER Context
        The repository to use when creating references in 'githubFlavoredMarkdown' mode.
        Specify as [ownerName]/[repositoryName].

    .PARAMETER AccessToken
        If provided, this will be used as the AccessToken for authentication with the
        REST Api.  Otherwise, will attempt to use the configured value or will run unauthenticated.

    .PARAMETER NoStatus
        If this switch is specified, long-running commands will run on the main thread
        with no commandline status update.  When not specified, those commands run in
        the background, enabling the command prompt to provide status information.
        If not supplied here, the DefaultNoStatus configuration property value will be used.

    .OUTPUTS
        [String] The HTML version of the Markdown content.

    .EXAMPLE
        ConvertFrom-Markdown -Content '**Bolded Text**' -Mode Markdown

        Returns back '<p><strong>Bolded Text</strong></p>'
#>
    [CmdletBinding(SupportsShouldProcess)]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSShouldProcess", "", Justification="Methods called within here make use of PSShouldProcess, and the switch is passed on to them inherently.")]
    param(
        [Parameter(
            Mandatory,
            ValueFromPipeline)]
        [ValidateNotNullOrEmpty()]
        [ValidateScript({if ([System.Text.Encoding]::UTF8.GetBytes($_).Count -lt 400000) { $true } else { throw "Content must be less than 400 KB." }})]
        [string] $Content,

        [ValidateSet('Markdown', 'GitHubFlavoredMarkdown')]
        [string] $Mode = 'markdown',

        [string] $Context,

        [string] $AccessToken,

        [switch] $NoStatus
    )

    Write-InvocationLog

    $telemetryProperties = @{
        'Mode' = $Mode
    }

    $modeConverter = @{
        'Markdown' = 'markdown'
        'GitHubFlavoredMarkdown' = 'gfm'
    }

    $hashBody = @{
        'text' = $Content
        'mode' = $modeConverter[$Mode]
    }

    if (-not [String]::IsNullOrEmpty($Context)) { $hashBody['context'] = $Context }

    $params = @{
        'UriFragment' = 'markdown'
        'Body' = (ConvertTo-Json -InputObject $hashBody)
        'Method' = 'Post'
        'Description' =  "Converting Markdown to HTML"
        'AccessToken' = $AccessToken
        'TelemetryEventName' = $MyInvocation.MyCommand.Name
        'TelemetryProperties' = $telemetryProperties
        'NoStatus' = (Resolve-ParameterWithDefaultConfigurationValue -Name NoStatus -ConfigValueName DefaultNoStatus)
    }

    return Invoke-GHRestMethod @params
}

function Get-GitHubLicense
{
<#
    .SYNOPSIS
        Gets a license list or license content from GitHub.

    .DESCRIPTION
        Gets a license list or license content from GitHub.

        The Git repo for this module can be found here: http://aka.ms/PowerShellForGitHub

    .PARAMETER OwnerName
        Owner of the repository.
        If not supplied here, the DefaultOwnerName configuration property value will be used.

    .PARAMETER RepositoryName
        Name of the repository.
        If not supplied here, the DefaultRepositoryName configuration property value will be used.

    .PARAMETER Uri
        Uri for the repository.
        The OwnerName and RepositoryName will be extracted from here instead of needing to provide
        them individually.

    .PARAMETER Name
        The name of the license to retrieve the content for.  If not specified, all licenses
        will be returned.

    .PARAMETER AccessToken
        If provided, this will be used as the AccessToken for authentication with the
        REST Api.  Otherwise, will attempt to use the configured value or will run unauthenticated.

    .PARAMETER NoStatus
        If this switch is specified, long-running commands will run on the main thread
        with no commandline status update.  When not specified, those commands run in
        the background, enabling the command prompt to provide status information.
        If not supplied here, the DefaultNoStatus configuration property value will be used.

    .EXAMPLE
        Get-GitHubLicense

        Returns metadata about popular open source licenses

    .EXAMPLE
        Get-GitHubLicense -Name mit

        Gets the content of the mit license file

    .EXAMPLE
        Get-GitHubLicense -OwnerName PowerShell -RepositoryName PowerShellForGitHub

        Gets the content of the license file for the PowerShell\PowerShellForGitHub repository.
        It may be necessary to convert the content of the file.  Check the 'encoding' property of
        the result to know how 'content' is encoded.  As an example, to convert from Base64, do
        the following:

        [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($result.content))
#>
    [CmdletBinding(SupportsShouldProcess)]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSShouldProcess", "", Justification="Methods called within here make use of PSShouldProcess, and the switch is passed on to them inherently.")]
    param(
        [Parameter(ParameterSetName='Elements')]
        [string] $OwnerName,

        [Parameter(ParameterSetName='Elements')]
        [string] $RepositoryName,

        [Parameter(
            Mandatory,
            ParameterSetName='Uri')]
        [string] $Uri,

        [Parameter(
            Mandatory,
            ParameterSetName='Individual')]
        [string] $Name,

        [string] $AccessToken,

        [switch] $NoStatus
    )

    Write-InvocationLog

    $elements = Resolve-RepositoryElements -DisableValidation
    $OwnerName = $elements.ownerName
    $RepositoryName = $elements.repositoryName

    $telemetryProperties = @{}

    $uriFragment = 'licenses'
    $description = 'Getting all licenses'
    if ($PSBoundParameters.ContainsKey('Name'))
    {
        $telemetryProperties['Name'] = $Name
        $uriFragment = "licenses/$Name"
        $description = "Getting the $Name license"
    }
    elseif ((-not [String]::IsNullOrEmpty($OwnerName)) -and (-not [String]::IsNullOrEmpty($RepositoryName)))
    {
        $telemetryProperties['OwnerName'] = Get-PiiSafeString -PlainText $OwnerName
        $telemetryProperties['RepositoryName'] = Get-PiiSafeString -PlainText $RepositoryName
        $uriFragment = "repos/$OwnerName/$RepositoryName/license"
        $description = "Getting the license for $RepositoryName"
    }

    $params = @{
        'UriFragment' = $uriFragment
        'Method' = 'Get'
        'Description' =  $description
        'AccessToken' = $AccessToken
        'TelemetryEventName' = $MyInvocation.MyCommand.Name
        'TelemetryProperties' = $telemetryProperties
        'NoStatus' = (Resolve-ParameterWithDefaultConfigurationValue -Name NoStatus -ConfigValueName DefaultNoStatus)
    }

    return Invoke-GHRestMethod @params
}

function Get-GitHubEmoji
{
<#
    .SYNOPSIS
        Gets all the emojis available to use on GitHub.

    .DESCRIPTION
        Gets all the emojis available to use on GitHub.

        The Git repo for this module can be found here: http://aka.ms/PowerShellForGitHub

    .PARAMETER AccessToken
        If provided, this will be used as the AccessToken for authentication with the
        REST Api.  Otherwise, will attempt to use the configured value or will run unauthenticated.

    .PARAMETER NoStatus
        If this switch is specified, long-running commands will run on the main thread
        with no commandline status update.  When not specified, those commands run in
        the background, enabling the command prompt to provide status information.
        If not supplied here, the DefaultNoStatus configuration property value will be used.

    .OUTPUTS
        [PSCustomObject]
        The emoji name and a link to its image.

    .EXAMPLE
        Get-GitHubEmoji
#>
    [CmdletBinding(SupportsShouldProcess)]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSShouldProcess", "", Justification="Methods called within here make use of PSShouldProcess, and the switch is passed on to them inherently.")]
    param(
        [string] $AccessToken,

        [switch] $NoStatus
    )

    Write-InvocationLog

    $params = @{
        'UriFragment' = 'emojis'
        'Method' = 'Get'
        'Description' =  "Getting all GitHub emojis"
        'AccessToken' = $AccessToken
        'TelemetryEventName' = $MyInvocation.MyCommand.Name
        'NoStatus' = (Resolve-ParameterWithDefaultConfigurationValue -Name NoStatus -ConfigValueName DefaultNoStatus)
    }

    return Invoke-GHRestMethod @params
}

function Get-GitHubCodeOfConduct
{
<#
    .SYNOPSIS
        Gets license or license content from GitHub.

    .DESCRIPTION
        Gets license or license content from GitHub.

        The Git repo for this module can be found here: http://aka.ms/PowerShellForGitHub

    .PARAMETER OwnerName
        Owner of the repository.
        If not supplied here, the DefaultOwnerName configuration property value will be used.

    .PARAMETER RepositoryName
        Name of the repository.
        If not supplied here, the DefaultRepositoryName configuration property value will be used.

    .PARAMETER Uri
        Uri for the repository.
        The OwnerName and RepositoryName will be extracted from here instead of needing to provide
        them individually.

    .PARAMETER Name
        The name of the license to retrieve the content for.  If not specified, all licenses
        will be returned.

    .PARAMETER AccessToken
        If provided, this will be used as the AccessToken for authentication with the
        REST Api.  Otherwise, will attempt to use the configured value or will run unauthenticated.

    .PARAMETER NoStatus
        If this switch is specified, long-running commands will run on the main thread
        with no commandline status update.  When not specified, those commands run in
        the background, enabling the command prompt to provide status information.
        If not supplied here, the DefaultNoStatus configuration property value will be used.

    .EXAMPLE
        Get-GitHubCodeOfConduct

        Returns metadata about popular Codes of Conduct

    .EXAMPLE
        Get-GitHubCodeOfConduct -Name citizen_code_of_conduct

        Gets the content of the 'Citizen Code of Conduct'

    .EXAMPLE
        Get-GitHubCodeOfConduct -OwnerName PowerShell -RepositoryName PowerShellForGitHub

        Gets the content of the Code of Coduct file for the PowerShell\PowerShellForGitHub repository
        if one is detected.

        It may be necessary to convert the content of the file.  Check the 'encoding' property of
        the result to know how 'content' is encoded.  As an example, to convert from Base64, do
        the following:

        [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($result.content))
#>
    [CmdletBinding(SupportsShouldProcess)]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSShouldProcess", "", Justification="Methods called within here make use of PSShouldProcess, and the switch is passed on to them inherently.")]
    param(
        [Parameter(ParameterSetName='Elements')]
        [string] $OwnerName,

        [Parameter(ParameterSetName='Elements')]
        [string] $RepositoryName,

        [Parameter(
            Mandatory,
            ParameterSetName='Uri')]
        [string] $Uri,

        [Parameter(
            Mandatory,
            ParameterSetName='Individual')]
        [string] $Name,

        [string] $AccessToken,

        [switch] $NoStatus
    )

    Write-InvocationLog

    $elements = Resolve-RepositoryElements -DisableValidation
    $OwnerName = $elements.ownerName
    $RepositoryName = $elements.repositoryName

    $telemetryProperties = @{}

    $uriFragment = 'codes_of_conduct'
    $description = 'Getting all Codes of Conduct'
    if ($PSBoundParameters.ContainsKey('Name'))
    {
        $telemetryProperties['Name'] = $Name
        $uriFragment = "codes_of_conduct/$Name"
        $description = "Getting the $Name Code of Conduct"
    }
    elseif ((-not [String]::IsNullOrEmpty($OwnerName)) -and (-not [String]::IsNullOrEmpty($RepositoryName)))
    {
        $telemetryProperties['OwnerName'] = Get-PiiSafeString -PlainText $OwnerName
        $telemetryProperties['RepositoryName'] = Get-PiiSafeString -PlainText $RepositoryName
        $uriFragment = "repos/$OwnerName/$RepositoryName/community/code_of_conduct"
        $description = "Getting the Code of Conduct for $RepositoryName"
    }

    $params = @{
        'UriFragment' = $uriFragment
        'Method' = 'Get'
        'AcceptHeader' = 'application/vnd.github.scarlet-witch-preview+json'
        'Description' =  $description
        'AccessToken' = $AccessToken
        'TelemetryEventName' = $MyInvocation.MyCommand.Name
        'TelemetryProperties' = $telemetryProperties
        'NoStatus' = (Resolve-ParameterWithDefaultConfigurationValue -Name NoStatus -ConfigValueName DefaultNoStatus)
    }

    return Invoke-GHRestMethod @params
}

function Get-GitHubGitIgnore
{
<#
    .SYNOPSIS
        Gets the list of available .gitignore templates, or their content, from GitHub.

    .DESCRIPTION
        Gets the list of available .gitignore templates, or their content, from GitHub.

        The Git repo for this module can be found here: http://aka.ms/PowerShellForGitHub

    .PARAMETER Name
        The name of the .gitignore template whose content should be fetched.
        Not providing this will cause a list of all available templates to be returned.

    .PARAMETER AccessToken
        If provided, this will be used as the AccessToken for authentication with the
        REST Api.  Otherwise, will attempt to use the configured value or will run unauthenticated.

    .PARAMETER NoStatus
        If this switch is specified, long-running commands will run on the main thread
        with no commandline status update.  When not specified, those commands run in
        the background, enabling the command prompt to provide status information.
        If not supplied here, the DefaultNoStatus configuration property value will be used.

    .EXAMPLE
        Get-GitHubGitIgnore

        Returns the list of all available .gitignore templates.

    .EXAMPLE
        Get-GitHubGitIgnore -Name VisualStudio

        Returns the content of the VisualStudio.gitignore template.
#>
    [CmdletBinding(SupportsShouldProcess)]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSShouldProcess", "", Justification="Methods called within here make use of PSShouldProcess, and the switch is passed on to them inherently.")]
    param(
        [string] $Name,

        [string] $AccessToken,

        [switch] $NoStatus
    )

    Write-InvocationLog

    $telemetryProperties = @{}

    $uriFragment = 'gitignore/templates'
    $description = 'Getting all gitignore templates'
    if ($PSBoundParameters.ContainsKey('Name'))
    {
        $telemetryProperties['Name'] = $Name
        $uriFragment = "gitignore/templates/$Name"
        $description = "Getting $Name.gitignore"
    }

    $params = @{
        'UriFragment' = $uriFragment
        'Method' = 'Get'
        'Description' =  $description
        'AccessToken' = $AccessToken
        'TelemetryEventName' = $MyInvocation.MyCommand.Name
        'TelemetryProperties' = $telemetryProperties
        'NoStatus' = (Resolve-ParameterWithDefaultConfigurationValue -Name NoStatus -ConfigValueName DefaultNoStatus)
    }

    return Invoke-GHRestMethod @params
}

# SIG # Begin signature block
# MIIdkgYJKoZIhvcNAQcCoIIdgzCCHX8CAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUAXirqaJzPWFpEj0rjEgvzk7R
# x8mgghhuMIIE2jCCA8KgAwIBAgITMwAAAQWOyikiHmo0WwAAAAABBTANBgkqhkiG
# 9w0BAQUFADB3MQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4G
# A1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSEw
# HwYDVQQDExhNaWNyb3NvZnQgVGltZS1TdGFtcCBQQ0EwHhcNMTgwODIzMjAyMDI0
# WhcNMTkxMTIzMjAyMDI0WjCByjELMAkGA1UEBhMCVVMxCzAJBgNVBAgTAldBMRAw
# DgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24x
# LTArBgNVBAsTJE1pY3Jvc29mdCBJcmVsYW5kIE9wZXJhdGlvbnMgTGltaXRlZDEm
# MCQGA1UECxMdVGhhbGVzIFRTUyBFU046M0JENC00QjgwLTY5QzMxJTAjBgNVBAMT
# HE1pY3Jvc29mdCBUaW1lLVN0YW1wIHNlcnZpY2UwggEiMA0GCSqGSIb3DQEBAQUA
# A4IBDwAwggEKAoIBAQCffZs9uGatv9jfpb3g0Q0muReKdfyO+ND1cMPAHg/+ltXc
# 1XcUSSvbtE2sQOpyzJ6lAdbDHTouZnya8uI0AYAipfNXEnp0eB1l5b5mnVvKumye
# nWxzU1YLanf9rzp4HKHxuhl8kP8VlcJd0x0zBxj1JAHHO8jVI35U3v08cVReLMw5
# QWdlWQz/Swutiuhde2k613yzR4I5M7gsm4S0xcuC+vB1SzjwqSoYXCnRfhXvz+wB
# FvXlUycvp+9dnjfQFuoJdy/9yppx9EGLW86fsLqnkEZO9kKACU22tZusBpioC3+w
# jd96i5SkflDjVjLxHbMKFIKD3XIgx1oxrBVO4Yl/AgMBAAGjggEJMIIBBTAdBgNV
# HQ4EFgQUS/krKiFv0JlX9HMQH8enXOKF3c0wHwYDVR0jBBgwFoAUIzT42VJGcArt
# QPt2+7MrsMM1sw8wVAYDVR0fBE0wSzBJoEegRYZDaHR0cDovL2NybC5taWNyb3Nv
# ZnQuY29tL3BraS9jcmwvcHJvZHVjdHMvTWljcm9zb2Z0VGltZVN0YW1wUENBLmNy
# bDBYBggrBgEFBQcBAQRMMEowSAYIKwYBBQUHMAKGPGh0dHA6Ly93d3cubWljcm9z
# b2Z0LmNvbS9wa2kvY2VydHMvTWljcm9zb2Z0VGltZVN0YW1wUENBLmNydDATBgNV
# HSUEDDAKBggrBgEFBQcDCDANBgkqhkiG9w0BAQUFAAOCAQEAcLcxL0JQzfHT3vPE
# OVH1qIuPJjuI+CmWyxzaqMn9K8XLFjBEguHUo818JoDzFujQTVYHFnB+Me4EQBj3
# eAKz4WIOndt6nEtyZq8w/k1iJCJfR+r36dRZjkbpBpyezdPAUAVwzrzuKYvsYlT8
# xb9EyItAsLIog5zxfixxaJFD9lWLytcMOV1if3T3M4ASsV/UcakF2RtaSyav9i8d
# Du9xMWM9OxQjzWNOUEtbuditPvUG7y3dLYBsTfG3EzlbKxd0fp5a/Kq4OhQosnbF
# 7mxNnsCc7QDMVYiM5bpv7AJsxMUC9/5upsjhATVvG1COGLlY07O+w7Yp8f+cP/7e
# 6Y30xDCCBgMwggProAMCAQICEzMAAAEEaeLbufuKDYMAAAAAAQQwDQYJKoZIhvcN
# AQELBQAwfjELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNV
# BAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEoMCYG
# A1UEAxMfTWljcm9zb2Z0IENvZGUgU2lnbmluZyBQQ0EgMjAxMTAeFw0xODA3MTIy
# MDA4NDlaFw0xOTA3MjYyMDA4NDlaMHQxCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpX
# YXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3NvZnQg
# Q29ycG9yYXRpb24xHjAcBgNVBAMTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjCCASIw
# DQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBAJvFlfKX9v8jamydc1lzOJvTtOOE
# rY24PiXnoLggWkqRcDjYFKi9msD9DWse7OH8/wQ84mFgrlVqYZL71wB9nuppNtb9
# V3kZl/6EkfbHVa2mrgKK7bGRR1bNSodmRacwGxrtrHtrBdIzgnO+xm8czNToGgUV
# AC6Rl7ZLyGFnIovnExJowhcUryZatu5Vc3z1RLMhJwYA67U2+fwmiq0/f0QUw3q7
# I8iL3r4WisEhogIB2X+YkuIxU4+HsZAkmxf6FU3KAWwQbFICopNfYgNBJIxwp3As
# jUsv1zNZXP1d4D/X5IQXu30+edOCQ2JUQMibXs9wFDtgPGk/nzfn+BaSM4sCAwEA
# AaOCAYIwggF+MB8GA1UdJQQYMBYGCisGAQQBgjdMCAEGCCsGAQUFBwMDMB0GA1Ud
# DgQWBBS6F+MlaPS71Xsjpri2fOemgqtXrjBUBgNVHREETTBLpEkwRzEtMCsGA1UE
# CxMkTWljcm9zb2Z0IElyZWxhbmQgT3BlcmF0aW9ucyBMaW1pdGVkMRYwFAYDVQQF
# Ew0yMzAwMTIrNDM3OTY2MB8GA1UdIwQYMBaAFEhuZOVQBdOCqhc3NyK1bajKdQKV
# MFQGA1UdHwRNMEswSaBHoEWGQ2h0dHA6Ly93d3cubWljcm9zb2Z0LmNvbS9wa2lv
# cHMvY3JsL01pY0NvZFNpZ1BDQTIwMTFfMjAxMS0wNy0wOC5jcmwwYQYIKwYBBQUH
# AQEEVTBTMFEGCCsGAQUFBzAChkVodHRwOi8vd3d3Lm1pY3Jvc29mdC5jb20vcGtp
# b3BzL2NlcnRzL01pY0NvZFNpZ1BDQTIwMTFfMjAxMS0wNy0wOC5jcnQwDAYDVR0T
# AQH/BAIwADANBgkqhkiG9w0BAQsFAAOCAgEAKcWCCzmZIAzoJFuJOzhQkoOV25Hy
# O9Kk8NqBW3OOZ0gatsmKB3labM7D/GaYF7K716YWtQNWhXsqfS9ABk6eaddpFBWO
# Y/vMgPXbEZxQ7ksCcUxrBwX+Z1PxGbZubizyj9RFKeE2CLIceIEnloeZQhh3lNzG
# vJ2k21amNtBDSF9ABH5n6YjYAMfrMv/eCndgA3P+nqHHHfPAsy1hh8jxN4Xc/G08
# SxNKEna1UEpN513zTyHkmBKBgf7pXKj8FIzRAp9l+3Z1t2JTx33ax7pC4m57Jkoj
# gjLYjXUeEW+Lf3oG1aofGKVwE+fuaJ0HvAbpiQOWDGriIaslA9i3ARHhxCKWKTF8
# w1VO0BznRcZmAIoVIcTFAXAd4mgBOQ8iIcmoc39w2Cz09WnlSWw5paKpyns51fl3
# bzBzg5bAo4uu5X/dY03aFct7+R3ljsQ6qkr0LUVmn/JeuEkXOePfHUmJYYu6M69e
# Quoa1PVRU/GlXZKbh2e4dqsGVeGu1YOvOf8gMYtc5vq1B8+GJ8dBAiM5bVlOLsB4
# rzpJY2zieOAjdtQrqGcAPGVSWDDSeOl47e27KX2iHzjl7FnHk5lF+QCIykR6R9Ym
# R83UCcK1epAMPRYWfreU20ZSAEoeuT1pyVFlatU/EcQtN5dfksINMQya1ll38FBI
# h4l2k9jzfUqwItgwggYHMIID76ADAgECAgphFmg0AAAAAAAcMA0GCSqGSIb3DQEB
# BQUAMF8xEzARBgoJkiaJk/IsZAEZFgNjb20xGTAXBgoJkiaJk/IsZAEZFgltaWNy
# b3NvZnQxLTArBgNVBAMTJE1pY3Jvc29mdCBSb290IENlcnRpZmljYXRlIEF1dGhv
# cml0eTAeFw0wNzA0MDMxMjUzMDlaFw0yMTA0MDMxMzAzMDlaMHcxCzAJBgNVBAYT
# AlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYD
# VQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xITAfBgNVBAMTGE1pY3Jvc29mdCBU
# aW1lLVN0YW1wIFBDQTCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBAJ+h
# bLHf20iSKnxrLhnhveLjxZlRI1Ctzt0YTiQP7tGn0UytdDAgEesH1VSVFUmUG0KS
# rphcMCbaAGvoe73siQcP9w4EmPCJzB/LMySHnfL0Zxws/HvniB3q506jocEjU8qN
# +kXPCdBer9CwQgSi+aZsk2fXKNxGU7CG0OUoRi4nrIZPVVIM5AMs+2qQkDBuh/NZ
# MJ36ftaXs+ghl3740hPzCLdTbVK0RZCfSABKR2YRJylmqJfk0waBSqL5hKcRRxQJ
# gp+E7VV4/gGaHVAIhQAQMEbtt94jRrvELVSfrx54QTF3zJvfO4OToWECtR0Nsfz3
# m7IBziJLVP/5BcPCIAsCAwEAAaOCAaswggGnMA8GA1UdEwEB/wQFMAMBAf8wHQYD
# VR0OBBYEFCM0+NlSRnAK7UD7dvuzK7DDNbMPMAsGA1UdDwQEAwIBhjAQBgkrBgEE
# AYI3FQEEAwIBADCBmAYDVR0jBIGQMIGNgBQOrIJgQFYnl+UlE/wq4QpTlVnkpKFj
# pGEwXzETMBEGCgmSJomT8ixkARkWA2NvbTEZMBcGCgmSJomT8ixkARkWCW1pY3Jv
# c29mdDEtMCsGA1UEAxMkTWljcm9zb2Z0IFJvb3QgQ2VydGlmaWNhdGUgQXV0aG9y
# aXR5ghB5rRahSqClrUxzWPQHEy5lMFAGA1UdHwRJMEcwRaBDoEGGP2h0dHA6Ly9j
# cmwubWljcm9zb2Z0LmNvbS9wa2kvY3JsL3Byb2R1Y3RzL21pY3Jvc29mdHJvb3Rj
# ZXJ0LmNybDBUBggrBgEFBQcBAQRIMEYwRAYIKwYBBQUHMAKGOGh0dHA6Ly93d3cu
# bWljcm9zb2Z0LmNvbS9wa2kvY2VydHMvTWljcm9zb2Z0Um9vdENlcnQuY3J0MBMG
# A1UdJQQMMAoGCCsGAQUFBwMIMA0GCSqGSIb3DQEBBQUAA4ICAQAQl4rDXANENt3p
# tK132855UU0BsS50cVttDBOrzr57j7gu1BKijG1iuFcCy04gE1CZ3XpA4le7r1ia
# HOEdAYasu3jyi9DsOwHu4r6PCgXIjUji8FMV3U+rkuTnjWrVgMHmlPIGL4UD6ZEq
# JCJw+/b85HiZLg33B+JwvBhOnY5rCnKVuKE5nGctxVEO6mJcPxaYiyA/4gcaMvnM
# MUp2MT0rcgvI6nA9/4UKE9/CCmGO8Ne4F+tOi3/FNSteo7/rvH0LQnvUU3Ih7jDK
# u3hlXFsBFwoUDtLaFJj1PLlmWLMtL+f5hYbMUVbonXCUbKw5TNT2eb+qGHpiKe+i
# myk0BncaYsk9Hm0fgvALxyy7z0Oz5fnsfbXjpKh0NbhOxXEjEiZ2CzxSjHFaRkMU
# vLOzsE1nyJ9C/4B5IYCeFTBm6EISXhrIniIh0EPpK+m79EjMLNTYMoBMJipIJF9a
# 6lbvpt6Znco6b72BJ3QGEe52Ib+bgsEnVLaxaj2JoXZhtG6hE6a/qkfwEm/9ijJs
# sv7fUciMI8lmvZ0dhxJkAj0tr1mPuOQh5bWwymO0eFQF1EEuUKyUsKV4q7OglnUa
# 2ZKHE3UiLzKoCG6gW4wlv6DvhMoh1useT8ma7kng9wFlb4kLfchpyOZu6qeXzjEp
# /w7FW1zYTRuh2Povnj8uVRZryROj/TCCB3owggVioAMCAQICCmEOkNIAAAAAAAMw
# DQYJKoZIhvcNAQELBQAwgYgxCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5n
# dG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9y
# YXRpb24xMjAwBgNVBAMTKU1pY3Jvc29mdCBSb290IENlcnRpZmljYXRlIEF1dGhv
# cml0eSAyMDExMB4XDTExMDcwODIwNTkwOVoXDTI2MDcwODIxMDkwOVowfjELMAkG
# A1UEBhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQx
# HjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEoMCYGA1UEAxMfTWljcm9z
# b2Z0IENvZGUgU2lnbmluZyBQQ0EgMjAxMTCCAiIwDQYJKoZIhvcNAQEBBQADggIP
# ADCCAgoCggIBAKvw+nIQHC6t2G6qghBNNLrytlghn0IbKmvpWlCquAY4GgRJun/D
# DB7dN2vGEtgL8DjCmQawyDnVARQxQtOJDXlkh36UYCRsr55JnOloXtLfm1OyCizD
# r9mpK656Ca/XllnKYBoF6WZ26DJSJhIv56sIUM+zRLdd2MQuA3WraPPLbfM6XKEW
# 9Ea64DhkrG5kNXimoGMPLdNAk/jj3gcN1Vx5pUkp5w2+oBN3vpQ97/vjK1oQH01W
# KKJ6cuASOrdJXtjt7UORg9l7snuGG9k+sYxd6IlPhBryoS9Z5JA7La4zWMW3Pv4y
# 07MDPbGyr5I4ftKdgCz1TlaRITUlwzluZH9TupwPrRkjhMv0ugOGjfdf8NBSv4yU
# h7zAIXQlXxgotswnKDglmDlKNs98sZKuHCOnqWbsYR9q4ShJnV+I4iVd0yFLPlLE
# tVc/JAPw0XpbL9Uj43BdD1FGd7P4AOG8rAKCX9vAFbO9G9RVS+c5oQ/pI0m8GLhE
# fEXkwcNyeuBy5yTfv0aZxe/CHFfbg43sTUkwp6uO3+xbn6/83bBm4sGXgXvt1u1L
# 50kppxMopqd9Z4DmimJ4X7IvhNdXnFy/dygo8e1twyiPLI9AN0/B4YVEicQJTMXU
# pUMvdJX3bvh4IFgsE11glZo+TzOE2rCIF96eTvSWsLxGoGyY0uDWiIwLAgMBAAGj
# ggHtMIIB6TAQBgkrBgEEAYI3FQEEAwIBADAdBgNVHQ4EFgQUSG5k5VAF04KqFzc3
# IrVtqMp1ApUwGQYJKwYBBAGCNxQCBAweCgBTAHUAYgBDAEEwCwYDVR0PBAQDAgGG
# MA8GA1UdEwEB/wQFMAMBAf8wHwYDVR0jBBgwFoAUci06AjGQQ7kUBU7h6qfHMdEj
# iTQwWgYDVR0fBFMwUTBPoE2gS4ZJaHR0cDovL2NybC5taWNyb3NvZnQuY29tL3Br
# aS9jcmwvcHJvZHVjdHMvTWljUm9vQ2VyQXV0MjAxMV8yMDExXzAzXzIyLmNybDBe
# BggrBgEFBQcBAQRSMFAwTgYIKwYBBQUHMAKGQmh0dHA6Ly93d3cubWljcm9zb2Z0
# LmNvbS9wa2kvY2VydHMvTWljUm9vQ2VyQXV0MjAxMV8yMDExXzAzXzIyLmNydDCB
# nwYDVR0gBIGXMIGUMIGRBgkrBgEEAYI3LgMwgYMwPwYIKwYBBQUHAgEWM2h0dHA6
# Ly93d3cubWljcm9zb2Z0LmNvbS9wa2lvcHMvZG9jcy9wcmltYXJ5Y3BzLmh0bTBA
# BggrBgEFBQcCAjA0HjIgHQBMAGUAZwBhAGwAXwBwAG8AbABpAGMAeQBfAHMAdABh
# AHQAZQBtAGUAbgB0AC4gHTANBgkqhkiG9w0BAQsFAAOCAgEAZ/KGpZjgVHkaLtPY
# dGcimwuWEeFjkplCln3SeQyQwWVfLiw++MNy0W2D/r4/6ArKO79HqaPzadtjvyI1
# pZddZYSQfYtGUFXYDJJ80hpLHPM8QotS0LD9a+M+By4pm+Y9G6XUtR13lDni6WTJ
# RD14eiPzE32mkHSDjfTLJgJGKsKKELukqQUMm+1o+mgulaAqPyprWEljHwlpblqY
# luSD9MCP80Yr3vw70L01724lruWvJ+3Q3fMOr5kol5hNDj0L8giJ1h/DMhji8MUt
# zluetEk5CsYKwsatruWy2dsViFFFWDgycScaf7H0J/jeLDogaZiyWYlobm+nt3TD
# QAUGpgEqKD6CPxNNZgvAs0314Y9/HG8VfUWnduVAKmWjw11SYobDHWM2l4bf2vP4
# 8hahmifhzaWX0O5dY0HjWwechz4GdwbRBrF1HxS+YWG18NzGGwS+30HHDiju3mUv
# 7Jf2oVyW2ADWoUa9WfOXpQlLSBCZgB/QACnFsZulP0V3HjXG0qKin3p6IvpIlR+r
# +0cjgPWe+L9rt0uX4ut1eBrs6jeZeRhL/9azI2h15q/6/IvrC4DqaTuv/DDtBEyO
# 3991bWORPdGdVk5Pv4BXIqF4ETIheu9BCrE/+6jMpF3BoYibV3FWTkhFwELJm3Zb
# CoBIa/15n8G9bW1qyVJzEw16UM0xggSOMIIEigIBATCBlTB+MQswCQYDVQQGEwJV
# UzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UE
# ChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSgwJgYDVQQDEx9NaWNyb3NvZnQgQ29k
# ZSBTaWduaW5nIFBDQSAyMDExAhMzAAABBGni27n7ig2DAAAAAAEEMAkGBSsOAwIa
# BQCggaIwGQYJKoZIhvcNAQkDMQwGCisGAQQBgjcCAQQwHAYKKwYBBAGCNwIBCzEO
# MAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFD+XB/UIUPh+DhIw6HCZShNm
# HPC6MEIGCisGAQQBgjcCAQwxNDAyoBSAEgBNAGkAYwByAG8AcwBvAGYAdKEagBho
# dHRwOi8vd3d3Lm1pY3Jvc29mdC5jb20wDQYJKoZIhvcNAQEBBQAEggEAAJNIqFyw
# whYFj9TgQjatIfDfi/ejMXcN0Z3Xp3VaM8WA4bP9Da2ylxb3p9pJqWNCXEqtMHry
# WWD/gUPx5bKHcrYZimYKzq+5kntlscGzGZsxfnFWYJOHIch08am5NyueWb4/ONkk
# Dpc4C4USbqJv6Dl69NFqbgDeQ60pWIXaYP+yNK5YBPkeOt9JfZLQQzR/tUdHNToc
# WkqF9mr2Ju0Yt724bhMQyvO0Z2bL+GxKiJ7a6sktfLQYeVCwTXLh6UZpJ0geTws9
# 4pE4OO9l2TnM0H4jznj/xz5DpLh59EJuzkFcX9ajQpfyaKb2WUN72ODX6cnV9GIQ
# 26VqHduR+P9bV6GCAigwggIkBgkqhkiG9w0BCQYxggIVMIICEQIBATCBjjB3MQsw
# CQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9u
# ZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSEwHwYDVQQDExhNaWNy
# b3NvZnQgVGltZS1TdGFtcCBQQ0ECEzMAAAEFjsopIh5qNFsAAAAAAQUwCQYFKw4D
# AhoFAKBdMBgGCSqGSIb3DQEJAzELBgkqhkiG9w0BBwEwHAYJKoZIhvcNAQkFMQ8X
# DTE5MDEwNzE3Mjk0NFowIwYJKoZIhvcNAQkEMRYEFPsPh2qFrJHMAf9prwAtCJ8P
# i/WNMA0GCSqGSIb3DQEBBQUABIIBAFI+97xhOHL+KTfjJOR6y9tOaexRBvuuDdJW
# Wb6H/bpIXVKoAlwDGHdc0lQL2IGLaaTBvVJa1t4tHxSXNukj/6XCVMkFurN1/H77
# VeGl/uBxh7jiQkAbcGxrxsSQ0cYEoq1jYOYqNRM4g6SkrIzRXD56MGIgpMTibJA/
# Kdss+erC09tJxlawdMQske4WNNlXe51mcHY9QUDIYbxCJSrWHNTQOn2Hkzy5oX1U
# fEPeJEwYo0/2axC6rUCaOEMFY/4oYkYJXESG5B4Bk2rj67X2IfIEqJBk74w9SzT0
# CZgo9ekj3whws7p3bODOwmP92Og6dNtxF8g3mp6abKLFdT0xtmA=
# SIG # End signature block
