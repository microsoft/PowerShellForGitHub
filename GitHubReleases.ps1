# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

@{
    GitHubReleaseTypeName = 'GitHub.Release'
 }.GetEnumerator() | ForEach-Object {
     Set-Variable -Scope Script -Option ReadOnly -Name $_.Key -Value $_.Value
 }

filter Get-GitHubRelease
{
<#
    .SYNOPSIS
        Retrieves information about a release or list of releases on GitHub.

    .DESCRIPTION
        Retrieves information about a release or list of releases on GitHub.

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

    .PARAMETER Release
        The ID of a specific release.
        This is an optional parameter which can limit the results to a single release.

    .PARAMETER Latest
        Retrieve only the latest release.
        This is an optional parameter which can limit the results to a single release.

    .PARAMETER Tag
        Retrieves a list of releases with the associated tag.
        This is an optional parameter which can filter the list of releases.

    .PARAMETER AccessToken
        If provided, this will be used as the AccessToken for authentication with the
        REST Api.  Otherwise, will attempt to use the configured value or will run unauthenticated.

    .PARAMETER NoStatus
        If this switch is specified, long-running commands will run on the main thread
        with no commandline status update.  When not specified, those commands run in
        the background, enabling the command prompt to provide status information.
        If not supplied here, the DefaultNoStatus configuration property value will be used.

    .INPUTS
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
        GitHub.Repository

    .OUTPUTS
        GitHub.Release

    .EXAMPLE
        Get-GitHubRelease

        Gets all releases for the default configured owner/repository.

    .EXAMPLE
        Get-GitHubRelease -Release 12345

        Get a specific release for the default configured owner/repository

    .EXAMPLE
        Get-GitHubRelease -OwnerName dotnet -RepositoryName core

        Gets all releases from the dotnet\core repository.

    .EXAMPLE
        Get-GitHubRelease -Uri https://github.com/microsoft/PowerShellForGitHub

        Gets all releases from the microsoft/PowerShellForGitHub repository.

    .EXAMPLE
        Get-GitHubRelease -OwnerName dotnet -RepositoryName core -Latest

        Gets the latest release from the dotnet\core repository.

    .EXAMPLE
        Get-GitHubRelease -Uri https://github.com/microsoft/PowerShellForGitHub -Tag 0.8.0

        Gets the release tagged with 0.8.0 from the microsoft/PowerShellForGitHub repository.

    .NOTES
        Information about published releases are available to everyone. Only users with push
        access will receive listings for draft releases.
#>
    [CmdletBinding(
        SupportsShouldProcess,
        DefaultParameterSetName='Elements')]
    [OutputType({$script:GitHubReleaseTypeName})]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSShouldProcess", "", Justification="Methods called within here make use of PSShouldProcess, and the switch is passed on to them inherently.")]
    param(
        [Parameter(ParameterSetName='Elements')]
        [Parameter(ParameterSetName="Elements-ReleaseId")]
        [Parameter(ParameterSetName="Elements-Latest")]
        [Parameter(ParameterSetName="Elements-Tag")]
        [string] $OwnerName,

        [Parameter(ParameterSetName='Elements')]
        [Parameter(ParameterSetName="Elements-ReleaseId")]
        [Parameter(ParameterSetName="Elements-Latest")]
        [Parameter(ParameterSetName="Elements-Tag")]
        [string] $RepositoryName,

        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName='Uri')]
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName="Uri-ReleaseId")]
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName="Uri-Latest")]
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName="Uri-Tag")]
        [Alias('RepositoryUrl')]
        [string] $Uri,

        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName="Elements-ReleaseId")]
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName="Uri-ReleaseId")]
        [Alias('ReleaseId')]
        [int64] $Release,

        [Parameter(
            Mandatory,
            ParameterSetName="Elements-Latest")]
        [Parameter(
            Mandatory,
            ParameterSetName="Uri-Latest")]
        [switch] $Latest,

        [Parameter(
            Mandatory,
            ParameterSetName="Elements-Tag")]
        [Parameter(
            Mandatory,
            ParameterSetName="Uri-Tag")]
        [string] $Tag,

        [string] $AccessToken,

        [switch] $NoStatus
    )

    Write-InvocationLog -Invocation $MyInvocation

    $elements = Resolve-RepositoryElements
    $OwnerName = $elements.ownerName
    $RepositoryName = $elements.repositoryName

    $telemetryProperties = @{}

    $telemetryProperties['OwnerName'] = Get-PiiSafeString -PlainText $OwnerName
    $telemetryProperties['RepositoryName'] = Get-PiiSafeString -PlainText $RepositoryName

    $uriFragment = "repos/$OwnerName/$RepositoryName/releases"
    $description = "Getting releases for $OwnerName/$RepositoryName"

    if ($PSBoundParameters.ContainsKey('Release'))
    {
        $telemetryProperties['ProvidedRelease'] = $true

        $uriFragment += "/$Release"
        $description = "Getting release information for $Release from $OwnerName/$RepositoryName"
    }

    if($Latest)
    {
        $telemetryProperties['GetLatest'] = $true

        $uriFragment += "/latest"
        $description = "Getting latest release from $OwnerName/$RepositoryName"
    }

    if(-not [String]::IsNullOrEmpty($Tag))
    {
        $telemetryProperties['ProvidedTag'] = $true

        $uriFragment += "/tags/$Tag"
        $description = "Getting releases tagged with $Tag from $OwnerName/$RepositoryName"
    }

    $params = @{
        'UriFragment' = $uriFragment
        'Description' = $description
        'AccessToken' = $AccessToken
        'TelemetryEventName' = $MyInvocation.MyCommand.Name
        'TelemetryProperties' = $telemetryProperties
        'NoStatus' = (Resolve-ParameterWithDefaultConfigurationValue -Name NoStatus -ConfigValueName DefaultNoStatus)
    }

    return (Invoke-GHRestMethodMultipleResult @params | Add-GitHubReleaseAdditionalProperties)
}


filter Add-GitHubReleaseAdditionalProperties
{
<#
    .SYNOPSIS
        Adds type name and additional properties to ease pipelining to GitHub Release objects.

    .PARAMETER InputObject
        The GitHub object to add additional properties to.

    .PARAMETER TypeName
        The type that should be assigned to the object.

    .INPUTS
        [PSCustomObject]

    .OUTPUTS
        GitHub.Release
#>
    [CmdletBinding()]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseSingularNouns", "", Justification="Internal helper that is definitely adding more than one property.")]
    param(
        [Parameter(
            Mandatory,
            ValueFromPipeline)]
        [AllowNull()]
        [AllowEmptyCollection()]
        [PSCustomObject[]] $InputObject,

        [ValidateNotNullOrEmpty()]
        [string] $TypeName = $script:GitHubReleaseTypeName
    )

    foreach ($item in $InputObject)
    {
        $item.PSObject.TypeNames.Insert(0, $TypeName)

        if (-not (Get-GitHubConfiguration -Name DisablePipelineSupport))
        {
            if (-not [String]::IsNullOrEmpty($item.html_url))
            {
                $elements = Split-GitHubUri -Uri $item.html_url
                $repositoryUrl = Join-GitHubUri @elements
                Add-Member -InputObject $item -Name 'RepositoryUrl' -Value $repositoryUrl -MemberType NoteProperty -Force
            }

            Add-Member -InputObject $item -Name 'ReleaseId' -Value $item.id -MemberType NoteProperty -Force

            if ($null -ne $item.author)
            {
                $null = Add-GitHubUserAdditionalProperties -InputObject $item.author
            }
        }

        Write-Output $item
    }
}

function New-GitHubRelease
{
<#
    .SYNOPSIS
        Create a new release for a repository on GitHub.

    .DESCRIPTION
        Create a new release for a repository on GitHub.

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

    .PARAMETER TagName
        The name of the tag.

    .PARAMETER Commitish
        The commitsh value that determines where the Git tag is created from.
        Cn be any branch or commit SHA.  Unused if the Git tag already exists.
        Will default to the repository's default branch (usually 'master').

    .PARAMETER Name
        The name of the release.

    .PARAMETER Body
        Text describing the contents of the tag.

    .PARAMETER Draft
        Specifies if this should be a draft (unpublished) release or a published one.

    .PARAMETER PreRelease
        Indicates if this should be identified as a pre-release or as a full release.

    .PARAMETER AccessToken
        If provided, this will be used as the AccessToken for authentication with the
        REST Api.  Otherwise, will attempt to use the configured value or will run unauthenticated.

    .PARAMETER NoStatus
        If this switch is specified, long-running commands will run on the main thread
        with no commandline status update.  When not specified, those commands run in
        the background, enabling the command prompt to provide status information.
        If not supplied here, the DefaultNoStatus configuration property value will be used.

    .EXAMPLE
        New-GitHubRelease -OwnerName microsoft -RepositoryName PowerShellForGitHub -TagName 0.12.0

    .NOTES
        Users of this method must have push access.

        This endpoind triggers notifications.  Creating content too quickly using this endpoint
        may result in abuse rate limiting.
#>
    [CmdletBinding(
        SupportsShouldProcess,
        DefaultParameterSetName='Elements')]
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

        [Parameter(Mandatory)]
        [string] $TagName,

        [string] $Commitish,

        [string] $Name,

        [string] $Body,

        [switch] $Draft,

        [switch] $PreRelease,

        [string] $AccessToken,

        [switch] $NoStatus
    )

    Write-InvocationLog

    $elements = Resolve-RepositoryElements
    $OwnerName = $elements.ownerName
    $RepositoryName = $elements.repositoryName

    $telemetryProperties = @{
        'OwnerName' = (Get-PiiSafeString -PlainText $OwnerName)
        'RepositoryName' = (Get-PiiSafeString -PlainText $RepositoryName)
        'ProvidedCommitish' = (-not [String]::IsNullOrWhiteSpace($Commitish))
        'ProvidedName' = (-not [String]::IsNullOrWhiteSpace($Name))
        'ProvidedBody' = (-not [String]::IsNullOrWhiteSpace($Body))
        'ProvidedDraft' = ($PSBoundParameters.ContainsKey('Draft'))
        'ProvidedPreRelease' = ($PSBoundParameters.ContainsKey('PreRelease'))
    }

    $hashBody = @{
        'tag_name' = $TagName
    }

    if (-not [String]::IsNullOrWhiteSpace($Commitish)) { $hashBody['target_commitish'] = $Commitish }
    if (-not [String]::IsNullOrWhiteSpace($Name)) { $hashBody['name'] = $Name }
    if (-not [String]::IsNullOrWhiteSpace($Body)) { $hashBody['body'] = $Body }
    if ($PSBoundParameters.ContainsKey('Draft')) { $hashBody['draft'] = $Draft.ToBool() }
    if ($PSBoundParameters.ContainsKey('PreRelease')) { $hashBody['prerelease'] = $PreRelease.ToBool() }

    $params = @{
        'UriFragment' =  "/repos/$OwnerName/$RepositoryName/releases"
        'Body' = (ConvertTo-Json -InputObject $hashBody)
        'Method' = 'Post'
        'Description' =  "Creating release at $TagName"
        'AccessToken' = $AccessToken
        'TelemetryEventName' = $MyInvocation.MyCommand.Name
        'TelemetryProperties' = $telemetryProperties
        'NoStatus' = (Resolve-ParameterWithDefaultConfigurationValue -Name NoStatus -ConfigValueName DefaultNoStatus)
    }

    return Invoke-GHRestMethod @params
}

function Set-GitHubRelease
{
<#
    .SYNOPSIS
        Edits a release for a repository on GitHub.

    .DESCRIPTION
        Edits a release for a repository on GitHub.

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

    .PARAMETER Release
        The ID of the release to edit.

    .PARAMETER TagName
        The name of the tag.

    .PARAMETER Commitish
        The commitsh value that determines where the Git tag is created from.
        Cn be any branch or commit SHA.  Unused if the Git tag already exists.
        Will default to the repository's default branch (usually 'master').

    .PARAMETER Name
        The name of the release.

    .PARAMETER Body
        Text describing the contents of the tag.

    .PARAMETER Draft
        Specifies if this should be a draft (unpublished) release or a published one.

    .PARAMETER PreRelease
        Indicates if this should be identified as a pre-release or as a full release.

    .PARAMETER AccessToken
        If provided, this will be used as the AccessToken for authentication with the
        REST Api.  Otherwise, will attempt to use the configured value or will run unauthenticated.

    .PARAMETER NoStatus
        If this switch is specified, long-running commands will run on the main thread
        with no commandline status update.  When not specified, those commands run in
        the background, enabling the command prompt to provide status information.
        If not supplied here, the DefaultNoStatus configuration property value will be used.

    .EXAMPLE
        Set-GitHubRelease -OwnerName microsoft -RepositoryName PowerShellForGitHub -TagName 0.12.0 -Body 'Adds core support for Projects'

    .NOTES
        Users of this method must have push access.
#>
    [CmdletBinding(
        SupportsShouldProcess,
        DefaultParameterSetName='Elements')]
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

        [Parameter(Mandatory)]
        [int64] $Release,

        [string] $TagName,

        [string] $Commitish,

        [string] $Name,

        [string] $Body,

        [switch] $Draft,

        [switch] $PreRelease,

        [string] $AccessToken,

        [switch] $NoStatus
    )

    Write-InvocationLog

    $elements = Resolve-RepositoryElements
    $OwnerName = $elements.ownerName
    $RepositoryName = $elements.repositoryName

    $telemetryProperties = @{
        'OwnerName' = (Get-PiiSafeString -PlainText $OwnerName)
        'RepositoryName' = (Get-PiiSafeString -PlainText $RepositoryName)
        'ProvidedTagName' = (-not [String]::IsNullOrWhiteSpace($TagName))
        'ProvidedCommitish' = (-not [String]::IsNullOrWhiteSpace($Commitish))
        'ProvidedName' = (-not [String]::IsNullOrWhiteSpace($Name))
        'ProvidedBody' = (-not [String]::IsNullOrWhiteSpace($Body))
        'ProvidedDraft' = ($PSBoundParameters.ContainsKey('Draft'))
        'ProvidedPreRelease' = ($PSBoundParameters.ContainsKey('PreRelease'))
    }

    $hashBody = @{}
    if (-not [String]::IsNullOrWhiteSpace($TagName)) { $hashBody['tag_name'] = $TagName }
    if (-not [String]::IsNullOrWhiteSpace($Commitish)) { $hashBody['target_commitish'] = $Commitish }
    if (-not [String]::IsNullOrWhiteSpace($Name)) { $hashBody['name'] = $Name }
    if (-not [String]::IsNullOrWhiteSpace($Body)) { $hashBody['body'] = $Body }
    if ($PSBoundParameters.ContainsKey('Draft')) { $hashBody['draft'] = $Draft.ToBool() }
    if ($PSBoundParameters.ContainsKey('PreRelease')) { $hashBody['prerelease'] = $PreRelease.ToBool() }

    $params = @{
        'UriFragment' =  "/repos/$OwnerName/$RepositoryName/releases/$Release"
        'Body' = (ConvertTo-Json -InputObject $hashBody)
        'Method' = 'Patch'
        'Description' =  "Creating release at $TagName"
        'AccessToken' = $AccessToken
        'TelemetryEventName' = $MyInvocation.MyCommand.Name
        'TelemetryProperties' = $telemetryProperties
        'NoStatus' = (Resolve-ParameterWithDefaultConfigurationValue -Name NoStatus -ConfigValueName DefaultNoStatus)
    }

    return Invoke-GHRestMethod @params
}

function Remove-GitHubRelease
{
<#
    .SYNOPSIS
        Removes a release from a repository on GitHub.

    .DESCRIPTION
        Removes a release from a repository on GitHub.

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

    .PARAMETER Release
        The ID of the release to remove.

    .PARAMETER AccessToken
        If provided, this will be used as the AccessToken for authentication with the
        REST Api.  Otherwise, will attempt to use the configured value or will run unauthenticated.

    .PARAMETER NoStatus
        If this switch is specified, long-running commands will run on the main thread
        with no commandline status update.  When not specified, those commands run in
        the background, enabling the command prompt to provide status information.
        If not supplied here, the DefaultNoStatus configuration property value will be used.

    .EXAMPLE
        Remove-GitHubRelease -OwnerName microsoft -RepositoryName PowerShellForGitHub -Release 1234567890

    .NOTES
        Users of this method must have push access.
#>
    [CmdletBinding(
        SupportsShouldProcess,
        DefaultParameterSetName='Elements')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSShouldProcess", "", Justification="Methods called within here make use of PSShouldProcess, and the switch is passed on to them inherently.")]
    [Alias('Delete-GitHubRelease')]
    param(
        [Parameter(ParameterSetName='Elements')]
        [string] $OwnerName,

        [Parameter(ParameterSetName='Elements')]
        [string] $RepositoryName,

        [Parameter(
            Mandatory,
            ParameterSetName='Uri')]
        [string] $Uri,

        [Parameter(Mandatory)]
        [int64] $Release,

        [string] $AccessToken,

        [switch] $NoStatus
    )

    Write-InvocationLog

    $elements = Resolve-RepositoryElements
    $OwnerName = $elements.ownerName
    $RepositoryName = $elements.repositoryName

    $telemetryProperties = @{
        'OwnerName' = (Get-PiiSafeString -PlainText $OwnerName)
        'RepositoryName' = (Get-PiiSafeString -PlainText $RepositoryName)
    }

    $params = @{
        'UriFragment' =  "/repos/$OwnerName/$RepositoryName/releases/$Release"
        'Method' = 'Delete'
        'Description' =  "Deleting release $Release"
        'AccessToken' = $AccessToken
        'TelemetryEventName' = $MyInvocation.MyCommand.Name
        'TelemetryProperties' = $telemetryProperties
        'NoStatus' = (Resolve-ParameterWithDefaultConfigurationValue -Name NoStatus -ConfigValueName DefaultNoStatus)
    }

    return Invoke-GHRestMethod @params
}

function Get-GitHubReleaseAsset
{
<#
    .SYNOPSIS
        Gets a a list of assets for a release, or downloads a single release asset.

    .DESCRIPTION
        Gets a a list of assets for a release, or downloads a single release asset.

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

    .PARAMETER Asset
        The ID of the specific asset to download.

    .PARAMETER Path
        The path where the downloaded asset should be stored.

    .PARAMETER Force
        If specified, will overwrite any file located at Path when downloading Asset.

    .PARAMETER AccessToken
        If provided, this will be used as the AccessToken for authentication with the
        REST Api.  Otherwise, will attempt to use the configured value or will run unauthenticated.

    .PARAMETER NoStatus
        If this switch is specified, long-running commands will run on the main thread
        with no commandline status update.  When not specified, those commands run in
        the background, enabling the command prompt to provide status information.
        If not supplied here, the DefaultNoStatus configuration property value will be used.

    .EXAMPLE
        Remove-GitHubRelease -OwnerName microsoft -RepositoryName PowerShellForGitHub -Release 1234567890

    .NOTES
        Users of this method must have push access.
#>
    [CmdletBinding(
        SupportsShouldProcess,
        DefaultParameterSetName='Elements-List')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSShouldProcess", "", Justification="Methods called within here make use of PSShouldProcess, and the switch is passed on to them inherently.")]
    [Alias('Get-GitHubAsset')]
    param(
        [Parameter(ParameterSetName='Elements-List')]
        [Parameter(ParameterSetName='Elements-Info')]
        [Parameter(ParameterSetName='Elements-Download')]
        [string] $OwnerName,

        [Parameter(ParameterSetName='Elements-List')]
        [Parameter(ParameterSetName='Elements-Info')]
        [Parameter(ParameterSetName='Elements-Download')]
        [string] $RepositoryName,

        [Parameter(
            Mandatory,
            ParameterSetName='Uri-Info')]
        [Parameter(
            Mandatory,
            ParameterSetName='Uri-Download')]
        [Parameter(
            Mandatory,
            ParameterSetName='Uri-List')]
        [string] $Uri,

        [Parameter(
            Mandatory,
            ParameterSetName='Elements-List')]
        [Parameter(
            Mandatory,
            ParameterSetName='Uri-List')]
        [int64] $Release,

        [Parameter(
            Mandatory,
            ParameterSetName='Elements-Info')]
        [Parameter(
            Mandatory,
            ParameterSetName='Elements-Download')]
        [Parameter(
            Mandatory,
            ParameterSetName='Uri-Info')]
        [Parameter(
            Mandatory,
            ParameterSetName='Uri-Download')]
        [int64] $Asset,

        [Parameter(
            Mandatory,
            ParameterSetName='Elements-Download')]
        [Parameter(
            Mandatory,
            ParameterSetName='Uri-Download')]
        [string] $Path,

        [Parameter(ParameterSetName='Elements-Download')]
        [Parameter(ParameterSetName='Uri-Download')]
        [switch] $Force,

        [string] $AccessToken,

        [switch] $NoStatus
    )

    Write-InvocationLog

    $elements = Resolve-RepositoryElements
    $OwnerName = $elements.ownerName
    $RepositoryName = $elements.repositoryName

    $telemetryProperties = @{
        'OwnerName' = (Get-PiiSafeString -PlainText $OwnerName)
        'RepositoryName' = (Get-PiiSafeString -PlainText $RepositoryName)
    }

    $uriFragment = [String]::Empty
    $description = [String]::Empty
    $shouldSave = $false
    $acceptHeader = $script:defaultAcceptHeader
    if ($PSCmdlet.ParameterSetName -in ('Elements-List', 'Uri-List'))
    {
        $uriFragment = "/repos/$OwnerName/$RepositoryName/releases/$Release/assets"
        $description = "Getting list of assets for release $Release"
    }
    elseif ($PSCmdlet.ParameterSetName -in ('Elements-Info', 'Uri-Info'))
    {
        $uriFragment = "/repos/$OwnerName/$RepositoryName/releases/assets/$Asset"
        $description = "Getting information about release asset $Asset"
    }
    elseif ($PSCmdlet.ParameterSetName -in ('Elements-Download', 'Uri-Download'))
    {
        $uriFragment = "/repos/$OwnerName/$RepositoryName/releases/assets/$Asset"
        $description = "Downloading release asset $Asset"
        $shouldSave = $true
        $acceptHeader = 'application/octet-stream'

        $Path = Resolve-UnverifiedPath -Path $Path
    }

    $params = @{
        'UriFragment' =  $uriFragment
        'Method' = 'Get'
        'Description' =  $description
        'AcceptHeader' = $acceptHeader
        'Save' = $shouldSave
        'AccessToken' = $AccessToken
        'TelemetryEventName' = $MyInvocation.MyCommand.Name
        'TelemetryProperties' = $telemetryProperties
        'NoStatus' = (Resolve-ParameterWithDefaultConfigurationValue -Name NoStatus -ConfigValueName DefaultNoStatus)
    }

    $result = Invoke-GHRestMethod @params

    if ($PSCmdlet.ParameterSetName -in ('Elements-Download', 'Uri-Download'))
    {
        return (Move-Item -Path $result -Destination $Path -Force:$Force -PassThru)
    }
    else
    {
        return $result
    }
}

function Remove-GitHubReleaseAsset
{
<#
    .SYNOPSIS
        Removes an asset from a release on GitHub.

    .DESCRIPTION
        Removes an asset from a release on GitHub.

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

    .PARAMETER Asset
        The ID of the asset to remove.

    .PARAMETER AccessToken
        If provided, this will be used as the AccessToken for authentication with the
        REST Api.  Otherwise, will attempt to use the configured value or will run unauthenticated.

    .PARAMETER NoStatus
        If this switch is specified, long-running commands will run on the main thread
        with no commandline status update.  When not specified, those commands run in
        the background, enabling the command prompt to provide status information.
        If not supplied here, the DefaultNoStatus configuration property value will be used.

    .EXAMPLE
        Remove-GitHubReleaseAsset -OwnerName microsoft -RepositoryName PowerShellForGitHub -Release 1234567890
#>
    [CmdletBinding(
        SupportsShouldProcess,
        DefaultParameterSetName='Elements')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSShouldProcess", "", Justification="Methods called within here make use of PSShouldProcess, and the switch is passed on to them inherently.")]
    [Alias('Delete-GitHubAsset')]
    [Alias('Delete-GitHubReleaseAsset')]
    [Alias('Remove-GitHubAsset')]
    param(
        [Parameter(ParameterSetName='Elements')]
        [string] $OwnerName,

        [Parameter(ParameterSetName='Elements')]
        [string] $RepositoryName,

        [Parameter(
            Mandatory,
            ParameterSetName='Uri')]
        [string] $Uri,

        [Parameter(Mandatory)]
        [int64] $Asset,

        [string] $AccessToken,

        [switch] $NoStatus
    )

    Write-InvocationLog

    $elements = Resolve-RepositoryElements
    $OwnerName = $elements.ownerName
    $RepositoryName = $elements.repositoryName

    $telemetryProperties = @{
        'OwnerName' = (Get-PiiSafeString -PlainText $OwnerName)
        'RepositoryName' = (Get-PiiSafeString -PlainText $RepositoryName)
    }

    $params = @{
        'UriFragment' =  "/repos/$OwnerName/$RepositoryName/releases/assets/$Asset"
        'Method' = 'Delete'
        'Description' =  "Deleting asset $Asset"
        'AccessToken' = $AccessToken
        'TelemetryEventName' = $MyInvocation.MyCommand.Name
        'TelemetryProperties' = $telemetryProperties
        'NoStatus' = (Resolve-ParameterWithDefaultConfigurationValue -Name NoStatus -ConfigValueName DefaultNoStatus)
    }

    return Invoke-GHRestMethod @params
}