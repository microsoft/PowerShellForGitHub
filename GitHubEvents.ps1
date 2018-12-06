# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

function Get-GitHubEvent
{
<#
    .DESCRIPTION
        Lists events for an issue, repository, or a single event

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

    .PARAMETER EventID
        The ID of a specific event to get. If not supplied, will return back all events for this repository.

    .PARAMETER Issue
        Issue number to get events for. If not supplied, will return back all events for this repository.

    .PARAMETER AccessToken
        If provided, this will be used as the AccessToken for authentication with the
        REST Api.  Otherwise, will attempt to use the configured value or will run unauthenticated.

    .PARAMETER NoStatus
        If this switch is specified, long-running commands will run on the main thread
        with no commandline status update.  When not specified, those commands run in
        the background, enabling the command prompt to provide status information.
        If not supplied here, the DefaultNoStatus configuration property value will be used.

    .EXAMPLE
        Get-GitHubEvent -OwnerName Powershell -RepositoryName PowerShellForGitHub

        Get the events for the PowerShell\PowerShellForGitHub project.
#>
    [CmdletBinding(
        SupportsShouldProcess,
        DefaultParametersetName='RepositoryElements')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSShouldProcess", "", Justification="Methods called within here make use of PSShouldProcess, and the switch is passed on to them inherently.")]
    param(
        [Parameter(Mandatory, ParameterSetName='RepositoryElements')]
        [Parameter(Mandatory, ParameterSetName='IssueElements')]
        [Parameter(Mandatory, ParameterSetName='EventElements')]
        [string] $OwnerName,

        [Parameter(Mandatory, ParameterSetName='RepositoryElements')]
        [Parameter(Mandatory, ParameterSetName='IssueElements')]
        [Parameter(Mandatory, ParameterSetName='EventElements')]
        [string] $RepositoryName,

        [Parameter(Mandatory, ParameterSetName='RepositoryUri')]
        [Parameter(Mandatory, ParameterSetName='IssueUri')]
        [Parameter(Mandatory, ParameterSetName='EventUri')]
        [string] $Uri,

        [Parameter(Mandatory, ParameterSetName='EventUri')]
        [Parameter(Mandatory, ParameterSetName='EventElements')]
        [string] $EventID,

        [Parameter(Mandatory, ParameterSetName='IssueUri')]
        [Parameter(Mandatory, ParameterSetName='IssueElements')]
        [int] $Issue,

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
        'ProvidedIssue' = $PSBoundParameters.ContainsKey('Issue')
        'ProvidedEvent' = $PSBoundParameters.ContainsKey('EventID')
    }

    if ($PSBoundParameters.ContainsKey('EventID'))
    {
        $uriFragment = "repos/$OwnerName/$RepositoryName/issues/events/$EventID"
        $description = "Getting event $EventID for $RepositoryName"
    }
    elseif ($PSBoundParameters.ContainsKey('Issue'))
    {
        $uriFragment = "repos/$OwnerName/$RepositoryName/issues/$Issue/events`?"
        $description = "Getting events for issue $Issue in $RepositoryName"
    }
    else
    {
        $uriFragment = "repos/$OwnerName/$RepositoryName/issues/events"
        $description = "Getting events for $RepositoryName"
    }

    $params = @{
        'UriFragment' = $uriFragment
        'Description' = $description
        'AccessToken' = $AccessToken
        'AcceptHeader' = 'application/vnd.github.starfox-preview+json,application/vnd.github.sailor-v-preview+json,application/vnd.github.symmetra-preview+json,application/vnd.github.machine-man-preview'
        'TelemetryEventName' = $MyInvocation.MyCommand.Name
        'TelemetryProperties' = $telemetryProperties
        'NoStatus' = (Resolve-ParameterWithDefaultConfigurationValue -Name NoStatus -ConfigValueName DefaultNoStatus)
    }

    return Invoke-GHRestMethodMultipleResult @params
}
