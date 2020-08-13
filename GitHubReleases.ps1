# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

@{
    GitHubReleaseTypeName = 'GitHub.Release'
    GitHubReleaseAssetTypeName = 'GitHub.ReleaseAsset'
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
        GitHub.ReleaseAsset
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
    [CmdletBinding(DefaultParameterSetName='Elements')]
    [OutputType({$script:GitHubReleaseTypeName})]
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
            ParameterSetName='Elements-Latest')]
        [Parameter(
            Mandatory,
            ParameterSetName='Uri-Latest')]
        [switch] $Latest,

        [Parameter(
            Mandatory,
            ParameterSetName='Elements-Tag')]
        [Parameter(
            Mandatory,
            ParameterSetName='Uri-Tag')]
        [string] $Tag,

        [string] $AccessToken
    )

    Write-InvocationLog

    $elements = Resolve-RepositoryElements
    $OwnerName = $elements.ownerName
    $RepositoryName = $elements.repositoryName

    $telemetryProperties = @{
        'OwnerName' = (Get-PiiSafeString -PlainText $OwnerName)
        'RepositoryName' = (Get-PiiSafeString -PlainText $RepositoryName)
    }

    $uriFragment = "repos/$OwnerName/$RepositoryName/releases"
    $description = "Getting releases for $OwnerName/$RepositoryName"

    if ($PSBoundParameters.ContainsKey('Release'))
    {
        $telemetryProperties['ProvidedRelease'] = $true

        $uriFragment += "/$Release"
        $description = "Getting release information for $Release from $OwnerName/$RepositoryName"
    }

    if ($Latest)
    {
        $telemetryProperties['GetLatest'] = $true

        $uriFragment += "/latest"
        $description = "Getting latest release from $OwnerName/$RepositoryName"
    }

    if (-not [String]::IsNullOrEmpty($Tag))
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
    }

    return (Invoke-GHRestMethodMultipleResult @params | Add-GitHubReleaseAdditionalProperties)
}

filter New-GitHubRelease
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

    .PARAMETER Tag
        The name of the tag.  The tag will be created around the committish if it doesn't exist
        in the remote, and will need to be synced back to the local repository afterwards.

    .PARAMETER Committish
        The committish value that determines where the Git tag is created from.
        Can be any branch or commit SHA.  Unused if the Git tag already exists.
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
        GitHub.Release
        GitHub.ReleaseAsset
        GitHub.Repository

    .OUTPUTS
        GitHub.Release

    .EXAMPLE
        New-GitHubRelease -OwnerName microsoft -RepositoryName PowerShellForGitHub -Tag 0.12.0

    .NOTES
        Requires push access to the repository.

        This endpoind triggers notifications.  Creating content too quickly using this endpoint
        may result in abuse rate limiting.
#>
    [CmdletBinding(
        SupportsShouldProcess,
        PositionalBinding = $false)]
    [OutputType({$script:GitHubReleaseTypeName})]
    param(
        [Parameter(ParameterSetName='Elements')]
        [string] $OwnerName,

        [Parameter(ParameterSetName='Elements')]
        [string] $RepositoryName,

        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName='Uri',
            Position = 1)]
        [Alias('RepositoryUrl')]
        [string] $Uri,

        [Parameter(
            Mandatory,
            Position = 2)]
        [string] $Tag,

        [Alias('Sha')]
        [Alias('BranchName')]
        [Alias('Commitish')] # git documentation says "committish", but GitHub uses "commitish"
        [string] $Committish,

        [string] $Name,

        [Alias('Description')]
        [string] $Body,

        [switch] $Draft,

        [switch] $PreRelease,

        [string] $AccessToken
    )

    Write-InvocationLog

    $elements = Resolve-RepositoryElements
    $OwnerName = $elements.ownerName
    $RepositoryName = $elements.repositoryName

    $telemetryProperties = @{
        'OwnerName' = (Get-PiiSafeString -PlainText $OwnerName)
        'RepositoryName' = (Get-PiiSafeString -PlainText $RepositoryName)
        'ProvidedCommittish' = ($PSBoundParameters.ContainsKey('Committish'))
        'ProvidedName' = ($PSBoundParameters.ContainsKey('Name'))
        'ProvidedBody' = ($PSBoundParameters.ContainsKey('Body'))
        'ProvidedDraft' = ($PSBoundParameters.ContainsKey('Draft'))
        'ProvidedPreRelease' = ($PSBoundParameters.ContainsKey('PreRelease'))
    }

    $hashBody = @{
        'tag_name' = $Tag
    }

    if ($PSBoundParameters.ContainsKey('Committish')) { $hashBody['target_commitish'] = $Committish }
    if ($PSBoundParameters.ContainsKey('Name')) { $hashBody['name'] = $Name }
    if ($PSBoundParameters.ContainsKey('Body')) { $hashBody['body'] = $Body }
    if ($PSBoundParameters.ContainsKey('Draft')) { $hashBody['draft'] = $Draft.ToBool() }
    if ($PSBoundParameters.ContainsKey('PreRelease')) { $hashBody['prerelease'] = $PreRelease.ToBool() }

    $params = @{
        'UriFragment' = "/repos/$OwnerName/$RepositoryName/releases"
        'Body' = (ConvertTo-Json -InputObject $hashBody)
        'Method' = 'Post'
        'Description' = "Creating release at $Tag"
        'AccessToken' = $AccessToken
        'TelemetryEventName' = $MyInvocation.MyCommand.Name
        'TelemetryProperties' = $telemetryProperties
    }

    if (-not $PSCmdlet.ShouldProcess($Tag, "Create release for $RepositoryName at tag"))
    {
        return
    }

    return (Invoke-GHRestMethod @params | Add-GitHubReleaseAdditionalProperties)
}

filter Set-GitHubRelease
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

    .PARAMETER Tag
        The name of the tag.

    .PARAMETER Committish
        The committish value that determines where the Git tag is created from.
        Can be any branch or commit SHA.  Unused if the Git tag already exists.
        Will default to the repository's default branch (usually 'master').

    .PARAMETER Name
        The name of the release.

    .PARAMETER Body
        Text describing the contents of the tag.

    .PARAMETER Draft
        Specifies if this should be a draft (unpublished) release or a published one.

    .PARAMETER PreRelease
        Indicates if this should be identified as a pre-release or as a full release.

    .PARAMETER PassThru
        Returns the updated GitHub Release.  By default, this cmdlet does not generate any output.
        You can use "Set-GitHubConfiguration -DefaultPassThru" to control the default behavior
        of this switch.

    .PARAMETER AccessToken
        If provided, this will be used as the AccessToken for authentication with the
        REST Api.  Otherwise, will attempt to use the configured value or will run unauthenticated.

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
        GitHub.Release
        GitHub.ReleaseAsset
        GitHub.Repository

    .OUTPUTS
        GitHub.Release

    .EXAMPLE
        Set-GitHubRelease -OwnerName microsoft -RepositoryName PowerShellForGitHub -Tag 0.12.0 -Body 'Adds core support for Projects'

    .NOTES
        Requires push access to the repository.
#>
    [CmdletBinding(
        SupportsShouldProcess,
        PositionalBinding = $false)]
    [OutputType({$script:GitHubReleaseTypeName})]
    param(
        [Parameter(ParameterSetName='Elements')]
        [string] $OwnerName,

        [Parameter(ParameterSetName='Elements')]
        [string] $RepositoryName,

        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName='Uri',
            Position = 1)]
        [Alias('RepositoryUrl')]
        [string] $Uri,

        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            Position = 2)]
        [Alias('ReleaseId')]
        [int64] $Release,

        [string] $Tag,

        [Alias('Sha')]
        [Alias('BranchName')]
        [Alias('Commitish')] # git documentation says "committish", but GitHub uses "commitish"
        [string] $Committish,

        [string] $Name,

        [Alias('Description')]
        [string] $Body,

        [switch] $Draft,

        [switch] $PreRelease,

        [switch] $PassThru,

        [string] $AccessToken
    )

    Write-InvocationLog

    $elements = Resolve-RepositoryElements
    $OwnerName = $elements.ownerName
    $RepositoryName = $elements.repositoryName

    $telemetryProperties = @{
        'OwnerName' = (Get-PiiSafeString -PlainText $OwnerName)
        'RepositoryName' = (Get-PiiSafeString -PlainText $RepositoryName)
        'ProvidedTag' = ($PSBoundParameters.ContainsKey('Tag'))
        'ProvidedCommittish' = ($PSBoundParameters.ContainsKey('Committish'))
        'ProvidedName' = ($PSBoundParameters.ContainsKey('Name'))
        'ProvidedBody' = ($PSBoundParameters.ContainsKey('Body'))
        'ProvidedDraft' = ($PSBoundParameters.ContainsKey('Draft'))
        'ProvidedPreRelease' = ($PSBoundParameters.ContainsKey('PreRelease'))
    }

    $hashBody = @{}
    if ($PSBoundParameters.ContainsKey('Tag')) { $hashBody['tag_name'] = $Tag }
    if ($PSBoundParameters.ContainsKey('Committish')) { $hashBody['target_commitish'] = $Committish }
    if ($PSBoundParameters.ContainsKey('Name')) { $hashBody['name'] = $Name }
    if ($PSBoundParameters.ContainsKey('Body')) { $hashBody['body'] = $Body }
    if ($PSBoundParameters.ContainsKey('Draft')) { $hashBody['draft'] = $Draft.ToBool() }
    if ($PSBoundParameters.ContainsKey('PreRelease')) { $hashBody['prerelease'] = $PreRelease.ToBool() }

    $params = @{
        'UriFragment' = "/repos/$OwnerName/$RepositoryName/releases/$Release"
        'Body' = (ConvertTo-Json -InputObject $hashBody)
        'Method' = 'Patch'
        'Description' = "Creating release at $Tag"
        'AccessToken' = $AccessToken
        'TelemetryEventName' = $MyInvocation.MyCommand.Name
        'TelemetryProperties' = $telemetryProperties
    }

    if (-not $PSCmdlet.ShouldProcess($Release, "Update GitHub Release"))
    {
        return
    }

    $result = (Invoke-GHRestMethod @params | Add-GitHubReleaseAdditionalProperties)
    if (Resolve-ParameterWithDefaultConfigurationValue -Name PassThru -ConfigValueName DefaultPassThru)
    {
        return $result
    }
}

filter Remove-GitHubRelease
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

    .PARAMETER Force
        If this switch is specified, you will not be prompted for confirmation of command execution.

    .PARAMETER AccessToken
        If provided, this will be used as the AccessToken for authentication with the
        REST Api.  Otherwise, will attempt to use the configured value or will run unauthenticated.

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
        GitHub.Release
        GitHub.ReleaseAsset
        GitHub.Repository

    .EXAMPLE
        Remove-GitHubRelease -OwnerName microsoft -RepositoryName PowerShellForGitHub -Release 1234567890

    .EXAMPLE
        Remove-GitHubRelease -OwnerName microsoft -RepositoryName PowerShellForGitHub -Release 1234567890 -Confirm:$false

        Will not prompt for confirmation, as -Confirm:$false was specified.

    .NOTES
        Requires push access to the repository.
#>
    [CmdletBinding(
        SupportsShouldProcess,
        PositionalBinding = $false,
        ConfirmImpact='High')]
    [Alias('Delete-GitHubRelease')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSReviewUnusedParameter", "", Justification="The Uri parameter is only referenced by Resolve-RepositoryElements which get access to it from the stack via Get-Variable -Scope 1.")]
    param(
        [Parameter(ParameterSetName='Elements')]
        [string] $OwnerName,

        [Parameter(ParameterSetName='Elements')]
        [string] $RepositoryName,

        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName='Uri',
            Position = 1)]
        [Alias('RepositoryUrl')]
        [string] $Uri,

        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            Position = 2)]
        [Alias('ReleaseId')]
        [int64] $Release,

        [switch] $Force,

        [string] $AccessToken
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
        'UriFragment' = "/repos/$OwnerName/$RepositoryName/releases/$Release"
        'Method' = 'Delete'
        'Description' = "Deleting release $Release"
        'AccessToken' = $AccessToken
        'TelemetryEventName' = $MyInvocation.MyCommand.Name
        'TelemetryProperties' = $telemetryProperties
    }

    if ($Force -and (-not $Confirm))
    {
        $ConfirmPreference = 'None'
    }

    if (-not $PSCmdlet.ShouldProcess($Release, "Remove GitHub Release"))
    {
        return
    }

    return Invoke-GHRestMethod @params
}

filter Get-GitHubReleaseAsset
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

    .PARAMETER Release
        The ID of a specific release to see the assets for.

    .PARAMETER Asset
        The ID of the specific asset to download.

    .PARAMETER Path
        The path where the downloaded asset should be stored.

    .PARAMETER Force
        If specified, will overwrite any file located at Path when downloading Asset.

    .PARAMETER AccessToken
        If provided, this will be used as the AccessToken for authentication with the
        REST Api.  Otherwise, will attempt to use the configured value or will run unauthenticated.

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
        GitHub.Release
        GitHub.ReleaseAsset
        GitHub.Repository

    .OUTPUTS
        GitHub.ReleaseAsset

    .EXAMPLE
        Get-GitHubReleaseAsset -OwnerName microsoft -RepositoryName PowerShellForGitHub -Release 1234567890

        Gets a list of all the assets associated with this release

    .EXAMPLE
        Get-GitHubReleaseAsset -OwnerName microsoft -RepositoryName PowerShellForGitHub -Asset 1234567890 -Path 'c:\users\PowerShellForGitHub\downloads\asset.zip' -Force

        Downloads the asset 1234567890 to 'c:\users\PowerShellForGitHub\downloads\asset.zip' and
        overwrites the file that may already be there.
#>
    [CmdletBinding(PositionalBinding = $false)]
    [OutputType({$script:GitHubReleaseAssetTypeName})]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSReviewUnusedParameter", "", Justification="The Uri parameter is only referenced by Resolve-RepositoryElements which get access to it from the stack via Get-Variable -Scope 1.")]
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
            ValueFromPipelineByPropertyName,
            ParameterSetName='Uri-Info',
            Position = 1)]
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName='Uri-Download',
            Position = 1)]
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName='Uri-List',
            Position = 1)]
        [Alias('RepositoryUrl')]
        [string] $Uri,

        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName='Elements-List',
            Position = 1)]
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName='Uri-List',
            Position = 2)]
        [Alias('ReleaseId')]
        [int64] $Release,

        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName='Elements-Info',
            Position = 1)]
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName='Elements-Download',
            Position = 1)]
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName='Uri-Info',
            Position = 2)]
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName='Uri-Download',
            Position = 2)]
        [Alias('AssetId')]
        [int64] $Asset,

        [Parameter(
            Mandatory,
            ParameterSetName='Elements-Download',
            Position = 2)]
        [Parameter(
            Mandatory,
            ParameterSetName='Uri-Download',
            Position = 3)]
        [string] $Path,

        [Parameter(ParameterSetName='Elements-Download')]
        [Parameter(ParameterSetName='Uri-Download')]
        [switch] $Force,

        [string] $AccessToken
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
        'UriFragment' = $uriFragment
        'Method' = 'Get'
        'Description' = $description
        'AcceptHeader' = $acceptHeader
        'Save' = $shouldSave
        'AccessToken' = $AccessToken
        'TelemetryEventName' = $MyInvocation.MyCommand.Name
        'TelemetryProperties' = $telemetryProperties
    }

    $result = Invoke-GHRestMethod @params

    if ($PSCmdlet.ParameterSetName -in ('Elements-Download', 'Uri-Download'))
    {
        Write-Log -Message "Moving [$($result.FullName)] to [$Path]" -Level Verbose
        return (Move-Item -Path $result -Destination $Path -Force:$Force -ErrorAction Stop -PassThru)
    }
    else
    {
        return ($result | Add-GitHubReleaseAssetAdditionalProperties)
    }
}

filter New-GitHubReleaseAsset
{
<#
    .SYNOPSIS
        Uploads a new asset for a release on GitHub.

    .DESCRIPTION
        Uploads a new asset for a release on GitHub.

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
        The ID of the release that the asset is for.

    .PARAMETER UploadUrl
        The value of 'upload_url' from getting the asset details.

    .PARAMETER Path
        The path to the file to upload as a new asset.

    .PARAMETER Label
        An alternate short description of the asset.  Used in place of the filename.

    .PARAMETER ContentType
        The MIME Media Type for the file being uploaded.  By default, this will be inferred based
        on the file's extension.  If the extension is not known by this module, it will fallback to
        using text/plain.  You may specify a ContentType here to override the module's logic.

    .PARAMETER AccessToken
        If provided, this will be used as the AccessToken for authentication with the
        REST Api.  Otherwise, will attempt to use the configured value or will run unauthenticated.

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
        GitHub.Release
        GitHub.ReleaseAsset
        GitHub.Repository

    .OUTPUTS
        GitHub.ReleaseAsset

    .EXAMPLE
        New-GitHubReleaseAsset -OwnerName microsoft -RepositoryName PowerShellForGitHub -Release 123456 -Path 'c:\foo.zip'

        Uploads the file located at 'c:\foo.zip' to the 123456 release in microsoft/PowerShellForGitHub

    .EXAMPLE
        $release = New-GitHubRelease -OwnerName microsoft -RepositoryName PowerShellForGitHub -Tag 'stable'
        $release | New-GitHubReleaseAsset -Path 'c:\bar.txt'

        Creates a new release tagged as 'stable' and then uploads 'c:\bar.txt' as an asset for
        that release.

    .NOTES
        GitHub renames asset filenames that have special characters, non-alphanumeric characters,
        and leading or trailing periods. Get-GitHubReleaseAsset lists the renamed filenames.

        If you upload an asset with the same filename as another uploaded asset, you'll receive
        an error and must delete the old file before you can re-upload the new asset.
#>
    [CmdletBinding(
        SupportsShouldProcess,
        PositionalBinding = $false)]
    [OutputType({$script:GitHubReleaseAssetTypeName})]
    param(
        [Parameter(ParameterSetName='Elements')]
        [string] $OwnerName,

        [Parameter(ParameterSetName='Elements')]
        [string] $RepositoryName,

        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName='Uri',
            Position = 1)]
        [Parameter(
            ValueFromPipelineByPropertyName,
            ParameterSetName='UploadUrl')]
        [Alias('RepositoryUrl')]
        [string] $Uri,

        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName='Elements',
            Position = 1)]
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName='Uri',
            Position = 2)]
        [Parameter(
            ValueFromPipelineByPropertyName,
            ParameterSetName='UploadUrl')]
        [Alias('ReleaseId')]
        [int64] $Release,

        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName='UploadUrl',
            Position = 1)]
        [string] $UploadUrl,

        [Parameter(
            Mandatory,
            ValueFromPipeline)]
        [ValidateScript(
            {if (Test-Path -Path $_ -PathType Leaf) { $true }
            else { throw "$_ does not exist or is inaccessible." }})]
        [string] $Path,

        [string] $Label,

        [string] $ContentType,

        [string] $AccessToken
    )

    Write-InvocationLog

    $telemetryProperties = @{
        'ProvidedUploadUrl' = ($PSBoundParameters.ContainsKey('UploadUrl'))
        'ProvidedLabel' = ($PSBoundParameters.ContainsKey('Label'))
        'ProvidedContentType' = ($PSBoundParameters.ContainsKey('ContentType'))
    }

    # If UploadUrl wasn't provided, we'll need to query for it first.
    if ([String]::IsNullOrEmpty($UploadUrl))
    {
        $elements = Resolve-RepositoryElements
        $OwnerName = $elements.ownerName
        $RepositoryName = $elements.repositoryName

        $telemetryProperties['OwnerName'] = (Get-PiiSafeString -PlainText $OwnerName)
        $telemetryProperties['RepositoryName'] = (Get-PiiSafeString -PlainText $RepositoryName)

        $params = @{
            'OwnerName' = $OwnerName
            'RepositoryName' = $RepositoryName
            'Release' = $Release
            'AccessToken' = $AccessToken
        }

        $releaseInfo = Get-GitHubRelease @params
        $UploadUrl = $releaseInfo.upload_url
    }

    # Remove the '{name,label}' from the Url if it's there
    if ($UploadUrl -match '(.*){')
    {
        $UploadUrl = $Matches[1]
    }

    $Path = Resolve-UnverifiedPath -Path $Path
    $file = Get-Item -Path $Path
    $fileName = $file.Name
    $fileNameEncoded = [Uri]::EscapeDataString($fileName)
    $queryParams = @("name=$fileNameEncoded")

    if ($PSBoundParameters.ContainsKey('Label'))
    {
        $labelEncoded = [Uri]::EscapeDataString($Label)
        $queryParams += "label=$labelEncoded"
    }

    if (-not $PSCmdlet.ShouldProcess($Path, "Create new GitHub Release Asset"))
    {
        return
    }

    $params = @{
        'UriFragment' = $UploadUrl + '?' + ($queryParams -join '&')
        'Method' = 'Post'
        'Description' = "Uploading release asset: $fileName"
        'InFile' = $Path
        'ContentType' = $ContentType
        'AccessToken' = $AccessToken
        'TelemetryEventName' = $MyInvocation.MyCommand.Name
        'TelemetryProperties' = $telemetryProperties
    }

    return (Invoke-GHRestMethod @params | Add-GitHubReleaseAssetAdditionalProperties)
}

filter Set-GitHubReleaseAsset
{
<#
    .SYNOPSIS
        Edits an existing asset for a release on GitHub.

    .DESCRIPTION
        Edits an existing asset for a release on GitHub.

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
        The ID of the asset being updated.

    .PARAMETER Name
        The new filename of the asset.

    .PARAMETER Label
        An alternate short description of the asset.  Used in place of the filename.

    .PARAMETER PassThru
        Returns the updated Release Asset.  By default, this cmdlet does not generate any output.
        You can use "Set-GitHubConfiguration -DefaultPassThru" to control the default behavior
        of this switch.

    .PARAMETER AccessToken
        If provided, this will be used as the AccessToken for authentication with the
        REST Api.  Otherwise, will attempt to use the configured value or will run unauthenticated.

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
        GitHub.Release
        GitHub.ReleaseAsset
        GitHub.Repository

    .OUTPUTS
        GitHub.ReleaseAsset

    .EXAMPLE
        Set-GitHubReleaseAsset -OwnerName microsoft -RepositoryName PowerShellForGitHub -Asset 123456 -Name bar.zip

        Renames the asset 123456 to be 'bar.zip'.

    .NOTES
        Requires push access to the repository.
#>
    [CmdletBinding(
        SupportsShouldProcess,
        PositionalBinding = $false)]
    [OutputType({$script:GitHubReleaseAssetTypeName})]
    param(
        [Parameter(ParameterSetName='Elements')]
        [string] $OwnerName,

        [Parameter(ParameterSetName='Elements')]
        [string] $RepositoryName,

        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName='Uri',
            Position = 1)]
        [Alias('RepositoryUrl')]
        [string] $Uri,

        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            Position = 2)]
        [Alias('AssetId')]
        [int64] $Asset,

        [string] $Name,

        [string] $Label,

        [switch] $PassThru,

        [string] $AccessToken
    )

    Write-InvocationLog

    $elements = Resolve-RepositoryElements
    $OwnerName = $elements.ownerName
    $RepositoryName = $elements.repositoryName

    $telemetryProperties = @{
        'OwnerName' = (Get-PiiSafeString -PlainText $OwnerName)
        'RepositoryName' = (Get-PiiSafeString -PlainText $RepositoryName)
        'ProvidedName' = ($PSBoundParameters.ContainsKey('Name'))
        'ProvidedLabel' = ($PSBoundParameters.ContainsKey('Label'))
    }

    $hashBody = @{}
    if ($PSBoundParameters.ContainsKey('Name')) { $hashBody['name'] = $Name }
    if ($PSBoundParameters.ContainsKey('Label')) { $hashBody['label'] = $Label }

    if (-not $PSCmdlet.ShouldProcess($Asset, "Update GitHub Release Asset"))
    {
        return
    }

    $params = @{
        'UriFragment' = "/repos/$OwnerName/$RepositoryName/releases/assets/$Asset"
        'Body' = (ConvertTo-Json -InputObject $hashBody)
        'Method' = 'Patch'
        'Description' = "Editing asset $Asset"
        'AccessToken' = $AccessToken
        'TelemetryEventName' = $MyInvocation.MyCommand.Name
        'TelemetryProperties' = $telemetryProperties
    }

    $result = (Invoke-GHRestMethod @params | Add-GitHubReleaseAssetAdditionalProperties)
    if (Resolve-ParameterWithDefaultConfigurationValue -Name PassThru -ConfigValueName DefaultPassThru)
    {
        return $result
    }
}

filter Remove-GitHubReleaseAsset
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

    .PARAMETER Force
        If this switch is specified, you will not be prompted for confirmation of command execution.

    .PARAMETER AccessToken
        If provided, this will be used as the AccessToken for authentication with the
        REST Api.  Otherwise, will attempt to use the configured value or will run unauthenticated.

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
        GitHub.Release
        GitHub.ReleaseAsset
        GitHub.Repository

    .EXAMPLE
        Remove-GitHubReleaseAsset -OwnerName microsoft -RepositoryName PowerShellForGitHub -Asset 1234567890

    .EXAMPLE
        Remove-GitHubReleaseAsset -OwnerName microsoft -RepositoryName PowerShellForGitHub -Asset 1234567890 -Confirm:$false

        Will not prompt for confirmation, as -Confirm:$false was specified.
#>
    [CmdletBinding(
        SupportsShouldProcess,
        PositionalBinding = $false,
        ConfirmImpact='High')]
    [Alias('Delete-GitHubReleaseAsset')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSReviewUnusedParameter", "", Justification="The Uri parameter is only referenced by Resolve-RepositoryElements which get access to it from the stack via Get-Variable -Scope 1.")]
    param(
        [Parameter(ParameterSetName='Elements')]
        [string] $OwnerName,

        [Parameter(ParameterSetName='Elements')]
        [string] $RepositoryName,

        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName='Uri',
            Position = 1)]
        [Alias('RepositoryUrl')]
        [string] $Uri,

        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            Position = 2)]
        [Alias('AssetId')]
        [int64] $Asset,

        [switch] $Force,

        [string] $AccessToken
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
        'UriFragment' = "/repos/$OwnerName/$RepositoryName/releases/assets/$Asset"
        'Method' = 'Delete'
        'Description' = "Deleting asset $Asset"
        'AccessToken' = $AccessToken
        'TelemetryEventName' = $MyInvocation.MyCommand.Name
        'TelemetryProperties' = $telemetryProperties
    }

    if ($Force -and (-not $Confirm))
    {
        $ConfirmPreference = 'None'
    }

    if (-not $PSCmdlet.ShouldProcess($Asset, "Delete GitHub Release Asset"))
    {
        return
    }

    return Invoke-GHRestMethod @params
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
            Add-Member -InputObject $item -Name 'UploadUrl' -Value $item.upload_url -MemberType NoteProperty -Force

            if ($null -ne $item.author)
            {
                $null = Add-GitHubUserAdditionalProperties -InputObject $item.author
            }
        }

        Write-Output $item
    }
}

filter Add-GitHubReleaseAssetAdditionalProperties
{
<#
    .SYNOPSIS
        Adds type name and additional properties to ease pipelining to GitHub Release Asset objects.

    .PARAMETER InputObject
        The GitHub object to add additional properties to.

    .PARAMETER TypeName
        The type that should be assigned to the object.

    .INPUTS
        [PSCustomObject]

    .OUTPUTS
        GitHub.ReleaseAsset
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
        [string] $TypeName = $script:GitHubReleaseAssetTypeName
    )

    foreach ($item in $InputObject)
    {
        $item.PSObject.TypeNames.Insert(0, $TypeName)

        if (-not (Get-GitHubConfiguration -Name DisablePipelineSupport))
        {
            $elements = Split-GitHubUri -Uri $item.url
            $repositoryUrl = Join-GitHubUri @elements
            Add-Member -InputObject $item -Name 'RepositoryUrl' -Value $repositoryUrl -MemberType NoteProperty -Force

            Add-Member -InputObject $item -Name 'AssetId' -Value $item.id -MemberType NoteProperty -Force

            if ($null -ne $item.uploader)
            {
                $null = Add-GitHubUserAdditionalProperties -InputObject $item.uploader
            }
        }

        Write-Output $item
    }
}
