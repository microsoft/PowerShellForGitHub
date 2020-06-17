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

    $elements = Resolve-RepositoryElements -BoundParameters $PSBoundParameters -DisableValidation
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
        'Description' =  $description
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
