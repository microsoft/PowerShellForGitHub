# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

function Get-GitHubRelease
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

    .PARAMETER ReleaseId
        Specific releaseId of a release.
        This is an option parameter which can limit the results to a single release.

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

    .EXAMPLE
        Get-GitHubRelease -OwnerName

        Gets all releases for the current owner/repository.

    .EXAMPLE
        Get-GitHubRelease -ReleaseId 12345

        Get

    .EXAMPLE
        Get-GitHubRelease -OctoCat OctoCat

    .EXAMPLE
        Get-GitHubRelease -Uri https://github.com/PowerShell/PowerShellForGitHub

    .EXAMPLE
        Get-GitHubRelease -OrganizationName PowerShell

#>
    [CmdletBinding(
        SupportsShouldProcess,
        DefaultParametersetName='Elements')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSShouldProcess", "", Justification="Methods called within here make use of PSShouldProcess, and the switch is passed on to them inherently.")]
    param(
        [Parameter(
            ParameterSetName='Elements')]
        [Parameter(
            ParameterSetName="Elements-ReleaseId")]
        [Parameter(
            ParameterSetName="Elements-Latest")]
        [Parameter(
            ParameterSetName="Elements-Tag")]
        [string] $OwnerName,

        [Parameter(
            ParameterSetName='Elements')]
        [Parameter(
            ParameterSetName="Elements-ReleaseId")]
        [Parameter(
            ParameterSetName="Elements-Latest")]
        [Parameter(
            ParameterSetName="Elements-Tag")]
        [string] $RepositoryName,

        [Parameter(
            Mandatory,
            ParameterSetName='Uri')]
        [Parameter(
            Mandatory,
            ParameterSetName="Uri-ReleaseId")]
        [Parameter(
            Mandatory,
            ParameterSetName="Uri-Latest")]
        [Parameter(
            Mandatory,
            ParameterSetName="Uri-Tag")]
        [string] $Uri,

        [Parameter(
            Mandatory,
            ParameterSetName="Elements-ReleaseId")]
        [Parameter(
            Mandatory,
            ParameterSetName="Uri-ReleaseId")]
        [string] $ReleaseId,

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

    $elements = Resolve-RepositoryElements -BoundParameters $PSBoundParameters -DisableValidation
    $OwnerName = $elements.ownerName
    $RepositoryName = $elements.repositoryName

    $telemetryProperties = @{}

    $telemetryProperties['OwnerName'] = Get-PiiSafeString -PlainText $OwnerName
    $telemetryProperties['RepositoryName'] = Get-PiiSafeString -PlainText $RepositoryName

    $uriFragment = "repos/$OwnerName/$RepositoryName/releases"
    $description = "Getting releases for $OwnerName/$RepositoryName"

    if(-not [String]::IsNullOrEmpty($ReleaseId))
    {
        $telemetryProperties['ReleaseId'] = Get-PiiSafeString -PlainText $ReleaseId

        $uriFragment += "/$ReleaseId"
        $description = "Getting releases for $OwnerName/$RepositoryName/releases/$ReleaseId"
    }

    if($Latest)
    {
        $telemetryProperties['Latest'] = Get-PiiSafeString -PlainText "latest"

        $uriFragment += "/latest"
        $description = "Getting releases for $OwnerName/$RepositoryName/releases/latest"
    }

    if(-not [String]::IsNullOrEmpty($Tag))
    {
        $telemetryProperties['Tag'] = Get-PiiSafeString -PlainText $Tag

        $uriFragment += "/tags/$Tag"
        $description = "Getting releases for $OwnerName/$RepositoryName/releases/tag/$Tag"
    }

    $params = @{
        'UriFragment' = $uriFragment
        'Description' =  $description
        'AccessToken' = $AccessToken
        'TelemetryEventName' = $MyInvocation.MyCommand.Name
        'TelemetryProperties' = $telemetryProperties
        'NoStatus' = (Resolve-ParameterWithDefaultConfigurationValue -BoundParameters $PSBoundParameters -Name NoStatus -ConfigValueName DefaultNoStatus)
    }

    return Invoke-GHRestMethodMultipleResult @params
}
