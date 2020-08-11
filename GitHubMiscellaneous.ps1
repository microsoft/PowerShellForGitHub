# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

@{
    GitHubRateLimitTypeName = 'GitHub.RateLimit'
    GitHubLicenseTypeName = 'GitHub.License'
    GitHubEmojiTypeName = 'GitHub.Emoji'
    GitHubCodeOfConductTypeName = 'GitHub.CodeOfConduct'
    GitHubGitignoreTypeName = 'GitHub.Gitignore'
 }.GetEnumerator() | ForEach-Object {
     Set-Variable -Scope Script -Option ReadOnly -Name $_.Key -Value $_.Value
 }

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

    .OUTPUTS
        GitHub.RateLimit
        Limits returned are _per hour_.

        The Search API has a custom rate limit, separate from the rate limit
        governing the rest of the REST API. The GraphQL API also has a custom
        rate limit that is separate from and calculated differently than rate
        limits in the REST API.

        For these reasons, the Rate Limit API response categorizes your rate limit.
        Under resources, you'll see three objects:

        The core object provides your rate limit status for all non-search-related resources
        in the REST API.
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
    [CmdletBinding()]
    [OutputType({$script:GitHubRateLimitTypeName})]
    param(
        [string] $AccessToken
    )

    Write-InvocationLog

    $params = @{
        'UriFragment' = 'rate_limit'
        'Method' = 'Get'
        'Description' = "Getting your API rate limit"
        'AccessToken' = $AccessToken
        'TelemetryEventName' = $MyInvocation.MyCommand.Name
    }

    $result = Invoke-GHRestMethod @params
    $result.PSObject.TypeNames.Insert(0, $script:GitHubRateLimitTypeName)
    return $result
}

function ConvertFrom-GitHubMarkdown
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

    .INPUTS
        [String]

    .OUTPUTS
        [String] The HTML version of the Markdown content.

    .EXAMPLE
        ConvertFrom-GitHubMarkdown -Content '**Bolded Text**' -Mode Markdown

        Returns back '<p><strong>Bolded Text</strong></p>'
#>
    [CmdletBinding()]
    [OutputType([String])]
    param(
        [Parameter(
            Mandatory,
            ValueFromPipeline)]
        [ValidateNotNullOrEmpty()]
        [ValidateScript({
            if ([System.Text.Encoding]::UTF8.GetBytes($_).Count -lt 400000) { $true }
            else { throw "Content must be less than 400 KB." }})]
        [string] $Content,

        [ValidateSet('Markdown', 'GitHubFlavoredMarkdown')]
        [string] $Mode = 'markdown',

        [string] $Context,

        [string] $AccessToken
    )

    begin
    {
        Write-InvocationLog

        $telemetryProperties = @{
            'Mode' = $Mode
        }

        $modeConverter = @{
            'Markdown' = 'markdown'
            'GitHubFlavoredMarkdown' = 'gfm'
        }
    }

    process
    {
        $hashBody = @{
            'text' = $Content
            'mode' = $modeConverter[$Mode]
        }

        if (-not [String]::IsNullOrEmpty($Context)) { $hashBody['context'] = $Context }

        $params = @{
            'UriFragment' = 'markdown'
            'Body' = (ConvertTo-Json -InputObject $hashBody)
            'Method' = 'Post'
            'Description' = "Converting Markdown to HTML"
            'AccessToken' = $AccessToken
            'TelemetryEventName' = $MyInvocation.MyCommand.Name
            'TelemetryProperties' = $telemetryProperties
        }

        Write-Output -InputObject (Invoke-GHRestMethod @params)
    }
}

filter Get-GitHubLicense
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

    .PARAMETER Key
        The key of the license to retrieve the content for.  If not specified, all licenses
        will be returned.

    .PARAMETER AccessToken
        If provided, this will be used as the AccessToken for authentication with the
        REST Api.  Otherwise, will attempt to use the configured value or will run unauthenticated.

    .INPUTS
        [String]
        GitHub.Branch
        GitHub.Content
        GitHub.Event
        GitHub.Issue
        GitHub.IssueComment
        GitHub.Label
        GitHub.Milestone
        GitHub.PullRequest
        GitHub.Project
        GitHub.ProjectCard
        GitHub.ProjectColumn
        GitHub.Reaction
        GitHub.Release
        GitHub.ReleaseAsset
        GitHub.Repository

    .OUTPUTS
        GitHub.License

    .EXAMPLE
        Get-GitHubLicense

        Returns metadata about popular open source licenses

    .EXAMPLE
        Get-GitHubLicense -Key mit

        Gets the content of the mit license file

    .EXAMPLE
        Get-GitHubLicense -OwnerName microsoft -RepositoryName PowerShellForGitHub

        Gets the content of the license file for the microsoft\PowerShellForGitHub repository.
        It may be necessary to convert the content of the file.  Check the 'encoding' property of
        the result to know how 'content' is encoded.  As an example, to convert from Base64, do
        the following:

        [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($result.content))
#>
    [CmdletBinding(DefaultParameterSetName = 'All')]
    [OutputType({$script:GitHubLicenseTypeName})]
    [OutputType({$script:GitHubContentTypeName})]
    param(
        [Parameter(ParameterSetName='Elements')]
        [string] $OwnerName,

        [Parameter(ParameterSetName='Elements')]
        [string] $RepositoryName,

        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName='Uri')]
        [Alias('RepositoryUrl')]
        [string] $Uri,

        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName='Individual')]
        [Alias('LicenseKey')]
        [string] $Key,

        [string] $AccessToken
    )

    Write-InvocationLog

    $telemetryProperties = @{}

    # Intentionally disabling validation because parameter sets exist that both require
    # OwnerName/RepositoryName (to get that repo's License) as well as don't (to get
    # all known Licenses).  We'll do additional parameter validation within the function.
    $elements = Resolve-RepositoryElements -DisableValidation
    $OwnerName = $elements.ownerName
    $RepositoryName = $elements.repositoryName

    $uriFragment = 'licenses'
    $description = 'Getting all licenses'

    if ($PSBoundParameters.ContainsKey('Key'))
    {
        $telemetryProperties['Key'] = $Name
        $uriFragment = "licenses/$Key"
        $description = "Getting the $Key license"
    }
    elseif ((-not [String]::IsNullOrEmpty($OwnerName)) -and (-not [String]::IsNullOrEmpty($RepositoryName)))
    {
        $telemetryProperties['OwnerName'] = Get-PiiSafeString -PlainText $OwnerName
        $telemetryProperties['RepositoryName'] = Get-PiiSafeString -PlainText $RepositoryName
        $uriFragment = "repos/$OwnerName/$RepositoryName/license"
        $description = "Getting the license for $RepositoryName"
    }
    elseif ([String]::IsNullOrEmpty($OwnerName) -xor [String]::IsNullOrEmpty($RepositoryName))
    {
        $message = 'When specifying OwnerName and/or RepositorName, BOTH must be specified.'
        Write-Log -Message $message -Level Error
        throw $message
    }

    $params = @{
        'UriFragment' = $uriFragment
        'Method' = 'Get'
        'Description' = $description
        'AccessToken' = $AccessToken
        'TelemetryEventName' = $MyInvocation.MyCommand.Name
        'TelemetryProperties' = $telemetryProperties
    }

    $result = Invoke-GHRestMethod @params
    foreach ($item in $result)
    {
        if ($PSCmdlet.ParameterSetName -in ('Elements', 'Uri'))
        {
            $null = $item | Add-GitHubContentAdditionalProperties

            # Add the decoded Base64 content directly to the object as an additional String property
            $decoded = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($item.content))
            Add-Member -InputObject $item -NotePropertyName "contentAsString" -NotePropertyValue $decoded

            $item.license.PSObject.TypeNames.Insert(0, $script:GitHubLicenseTypeName)

            if (-not (Get-GitHubConfiguration -Name DisablePipelineSupport))
            {
                Add-Member -InputObject $item -Name 'LicenseKey' -Value $item.license.key -MemberType NoteProperty -Force
            }
        }
        else
        {
            $item.PSObject.TypeNames.Insert(0, $script:GitHubLicenseTypeName)
            if (-not (Get-GitHubConfiguration -Name DisablePipelineSupport))
            {
                Add-Member -InputObject $item -Name 'LicenseKey' -Value $item.key -MemberType NoteProperty -Force
            }
        }
    }

    return $result
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

    .OUTPUTS
        GitHub.Emoji

    .EXAMPLE
        Get-GitHubEmoji
#>
    [CmdletBinding()]
    [OutputType({$script:GitHubEmojiTypeName})]
    param(
        [string] $AccessToken
    )

    Write-InvocationLog

    $params = @{
        'UriFragment' = 'emojis'
        'Method' = 'Get'
        'Description' = "Getting all GitHub emojis"
        'AccessToken' = $AccessToken
        'TelemetryEventName' = $MyInvocation.MyCommand.Name
    }

    $result = Invoke-GHRestMethod @params
    $result.PSObject.TypeNames.Insert(0, $script:GitHubEmojiTypeName)
    return $result
}

filter Get-GitHubCodeOfConduct
{
<#
    .SYNOPSIS
        Gets Codes of Conduct or a specific Code of Conduct from GitHub.

    .DESCRIPTION
        Gets Codes of Conduct or a specific Code of Conduct from GitHub.

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

    .PARAMETER Key
        The unique key of the Code of Conduct to retrieve the content for.  If not specified, all
        Codes of Conduct will be returned.

    .PARAMETER AccessToken
        If provided, this will be used as the AccessToken for authentication with the
        REST Api.  Otherwise, will attempt to use the configured value or will run unauthenticated.

    .INPUTS
        [String]
        GitHub.Branch
        GitHub.Content
        GitHub.Event
        GitHub.Issue
        GitHub.IssueComment
        GitHub.Label
        GitHub.Milestone
        GitHub.PullRequest
        GitHub.Project
        GitHub.ProjectCard
        GitHub.ProjectColumn
        GitHub.Reaction
        GitHub.Release
        GitHub.ReleaseAsset
        GitHub.Repository

    .OUTPUTS
        GitHub.CodeOfConduct

    .EXAMPLE
        Get-GitHubCodeOfConduct

        Returns metadata about popular Codes of Conduct

    .EXAMPLE
        Get-GitHubCodeOfConduct -Key citizen_code_of_conduct

        Gets the content of the 'Citizen Code of Conduct'

    .EXAMPLE
        Get-GitHubCodeOfConduct -OwnerName microsoft -RepositoryName PowerShellForGitHub

        Gets the content of the Code of Conduct file for the microsoft\PowerShellForGitHub repository
        if one is detected.

        It may be necessary to convert the content of the file.  Check the 'encoding' property of
        the result to know how 'content' is encoded.  As an example, to convert from Base64, do
        the following:

        [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($result.content))
#>
    [CmdletBinding()]
    [OutputType({$script:GitHubCodeOfConductTypeName})]
    param(
        [Parameter(ParameterSetName='Elements')]
        [string] $OwnerName,

        [Parameter(ParameterSetName='Elements')]
        [string] $RepositoryName,

        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName='Uri')]
        [Alias('RepositoryUrl')]
        [string] $Uri,

        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName='Individual')]
        [Alias('CodeOfConductKey')]
        [string] $Key,

        [string] $AccessToken
    )

    Write-InvocationLog

    # Intentionally disabling validation because parameter sets exist that both require
    # OwnerName/RepositoryName (to get that repo's Code of Conduct) as well as don't (to get
    # all known Codes of Conduct).  We'll do additional parameter validation within the function.
    $elements = Resolve-RepositoryElements -DisableValidation
    $OwnerName = $elements.ownerName
    $RepositoryName = $elements.repositoryName

    $telemetryProperties = @{}

    $uriFragment = 'codes_of_conduct'
    $description = 'Getting all Codes of Conduct'

    if ($PSBoundParameters.ContainsKey('Key'))
    {
        $telemetryProperties['Key'] = $Name
        $uriFragment = "codes_of_conduct/$Key"
        $description = "Getting the $Key Code of Conduct"
    }
    elseif ((-not [String]::IsNullOrEmpty($OwnerName)) -and (-not [String]::IsNullOrEmpty($RepositoryName)))
    {
        $telemetryProperties['OwnerName'] = Get-PiiSafeString -PlainText $OwnerName
        $telemetryProperties['RepositoryName'] = Get-PiiSafeString -PlainText $RepositoryName
        $uriFragment = "repos/$OwnerName/$RepositoryName/community/code_of_conduct"
        $description = "Getting the Code of Conduct for $RepositoryName"
    }
    elseif ([String]::IsNullOrEmpty($OwnerName) -xor [String]::IsNullOrEmpty($RepositoryName))
    {
        $message = 'When specifying OwnerName and/or RepositorName, BOTH must be specified.'
        Write-Log -Message $message -Level Error
        throw $message
    }

    $params = @{
        'UriFragment' = $uriFragment
        'Method' = 'Get'
        'AcceptHeader' = $script:scarletWitchAcceptHeader
        'Description' = $description
        'AccessToken' = $AccessToken
        'TelemetryEventName' = $MyInvocation.MyCommand.Name
        'TelemetryProperties' = $telemetryProperties
    }

    $result = Invoke-GHRestMethod @params
    foreach ($item in $result)
    {
        $item.PSObject.TypeNames.Insert(0, $script:GitHubCodeOfConductTypeName)
        if (-not (Get-GitHubConfiguration -Name DisablePipelineSupport))
        {
            Add-Member -InputObject $item -Name 'CodeOfConductKey' -Value $item.key -MemberType NoteProperty -Force
        }
    }

    return $result
}

filter Get-GitHubGitIgnore
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

    .PARAMETER RawContent
        If specified, the raw content of the specified .gitignore file will be returned.

    .PARAMETER AccessToken
        If provided, this will be used as the AccessToken for authentication with the
        REST Api.  Otherwise, will attempt to use the configured value or will run unauthenticated.

    .INPUTS
        [String]

    .OUTPUTS
        GitHub.Gitignore

    .EXAMPLE
        Get-GitHubGitIgnore

        Returns the list of all available .gitignore templates.

    .EXAMPLE
        Get-GitHubGitIgnore -Name VisualStudio

        Returns the content of the VisualStudio.gitignore template.
#>
    [CmdletBinding()]
    [OutputType({$script:GitHubGitignoreTypeName})]
    param(
        [Parameter(
            ValueFromPipeline,
            ParameterSetName='Individual')]
        [string] $Name,

        [Parameter(ParameterSetName='Individual')]
        [switch] $RawContent,

        [string] $AccessToken
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
        'Description' = $description
        'AccessToken' = $AccessToken
        'TelemetryEventName' = $MyInvocation.MyCommand.Name
        'TelemetryProperties' = $telemetryProperties
    }

    if ($RawContent)
    {
        $params['AcceptHeader'] = (Get-MediaAcceptHeader -MediaType 'Raw')
    }

    $result = Invoke-GHRestMethod @params
    if ($PSBoundParameters.ContainsKey('Name') -and (-not $RawContent))
    {
        $result.PSObject.TypeNames.Insert(0, $script:GitHubGitignoreTypeName)
    }

    if ($RawContent)
    {
        $result = [System.Text.Encoding]::UTF8.GetString($result)
    }

    return $result
}
