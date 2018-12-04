# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

function Get-GitHubMilestone
{
<#
    .DESCRIPTION
        Get the milestones for a given Github repository.

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

    .PARAMETER MilestoneNumber
        The number of a specific milestone to get. If not supplied, will return back all milestones for this repository.

    .PARAMETER Sort
        How to sort the results, either due_on or completeness. Default: due_on

    .PARAMETER Direction
        How to list the results, either asc or desc. Ignored without the sort parameter.

    .PARAMETER State
        Only milestones with this state are returned, either open, closed, or all. Default: open

    .PARAMETER AccessToken
        If provided, this will be used as the AccessToken for authentication with the
        REST Api.  Otherwise, will attempt to use the configured value or will run unauthenticated.

    .PARAMETER NoStatus
        If this switch is specified, long-running commands will run on the main thread
        with no commandline status update.  When not specified, those commands run in
        the background, enabling the command prompt to provide status information.
        If not supplied here, the DefaultNoStatus configuration property value will be used.

    .EXAMPLE
        Get-GitHubMilestone -OwnerName Powershell -RepositoryName PowerShellForGitHub

        Get the milestones for the PowerShell\PowerShellForGitHub project.
#>
    [CmdletBinding(
        SupportsShouldProcess,
        DefaultParametersetName='RepositoryElements')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSShouldProcess", "", Justification="Methods called within here make use of PSShouldProcess, and the switch is passed on to them inherently.")]
    param(
        [Parameter(Mandatory, ParameterSetName='RepositoryElements')]
        [string] $OwnerName,

        [Parameter(Mandatory, ParameterSetName='RepositoryElements')]
        [string] $RepositoryName,

        [Parameter(Mandatory, ParameterSetName='RepositoryUri')]
        [string] $Uri,

        [Parameter(ParameterSetName='RepositoryUri')]
        [Parameter(ParameterSetName='RepositoryElements')]
        [string] $MilestoneNumber,

        [Parameter(ParameterSetName='RepositoryUri')]
        [Parameter(ParameterSetName='RepositoryElements')]
        [ValidateSet('open', 'closed', 'all')]
        [DateTime] $State,

        [Parameter(ParameterSetName='RepositoryUri')]
        [Parameter(ParameterSetName='RepositoryElements')]
        [ValidateSet('created', 'updated')]
        [string] $Sort,

        [Parameter(ParameterSetName='RepositoryUri')]
        [Parameter(ParameterSetName='RepositoryElements')]
        [ValidateSet('asc', 'desc')]
        [string] $Direction,

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
        'ProvidedMilestone' = $PSBoundParameters.ContainsKey('MilestoneNumber')
    }

    if ($PSBoundParameters.ContainsKey('MilestoneNumber'))
    {
        $uriFragment = "repos/$OwnerName/$RepositoryName/milestones/$MilestoneNumber"
        $description = "Getting milestone $MilestoneNumber for $RepositoryName"
    }
    else
    {
        $getParams = @()

        if ($PSBoundParameters.ContainsKey('Sort'))
        {
            $getParams += "sort=$Sort"
        }

        if ($PSBoundParameters.ContainsKey('Direction'))
        {
            $getParams += "direction=$Direction"
        }

        if ($PSBoundParameters.ContainsKey('State'))
        {
            $getParams += "state=$State"
        }

        $uriFragment = "repos/$OwnerName/$RepositoryName/milestones`?" +  ($getParams -join '&')
        $description = "Getting milestones for $RepositoryName"
    }

    $params = @{
        'UriFragment' = $uriFragment
        'Description' = $description
        'AccessToken' = $AccessToken
        'TelemetryEventName' = $MyInvocation.MyCommand.Name
        'TelemetryProperties' = $telemetryProperties
        'NoStatus' = (Resolve-ParameterWithDefaultConfigurationValue -Name NoStatus -ConfigValueName DefaultNoStatus)
    }

    return Invoke-GHRestMethodMultipleResult @params
}

function New-GitHubMilestone
{
<#
    .DESCRIPTION
        Creates a new Github milestone in an issue for the given repository

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

    .PARAMETER Title
        The title of the milestone.

    .PARAMETER State
        Only milestones with this state are returned, either open or closed. Default: open

    .PARAMETER Description
        A description of the milestone.

    .PARAMETER Due_On
        The milestone due date.

    .PARAMETER AccessToken
        If provided, this will be used as the AccessToken for authentication with the
        REST Api.  Otherwise, will attempt to use the configured value or will run unauthenticated.

    .PARAMETER NoStatus
        If this switch is specified, long-running commands will run on the main thread
        with no commandline status update.  When not specified, those commands run in
        the background, enabling the command prompt to provide status information.
        If not supplied here, the DefaultNoStatus configuration property value will be used.

    .EXAMPLE
        New-GitHubMilestone -OwnerName Powershell -RepositoryName PowerShellForGitHub -Title "Testing this API"

        Creates a new Github milestone in an issue for the PowerShell\PowerShellForGitHub project.
#>
    [CmdletBinding(
        SupportsShouldProcess,
        DefaultParametersetName='Elements')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSShouldProcess", "", Justification="Methods called within here make use of PSShouldProcess, and the switch is passed on to them inherently.")]
    param(
        [Parameter(Mandatory, ParameterSetName='Elements')]
        [string] $OwnerName,

        [Parameter(Mandatory, ParameterSetName='Elements')]
        [string] $RepositoryName,

        [Parameter(Mandatory, ParameterSetName='Uri')]
        [string] $Uri,

        [Parameter(Mandatory, ParameterSetName='Uri')]
        [Parameter(Mandatory, ParameterSetName='Elements')]
        [string] $Title,

        [Parameter(ParameterSetName='Uri')]
        [Parameter(ParameterSetName='Elements')]
        [string] $State,

        [Parameter(ParameterSetName='Uri')]
        [Parameter(ParameterSetName='Elements')]
        [string] $Description,

        [Parameter(ParameterSetName='Uri')]
        [Parameter(ParameterSetName='Elements')]
        [string] $Due_On,

        [string] $AccessToken,

        [switch] $NoStatus
    )

    Write-InvocationLog

    $elements = Resolve-RepositoryElements
    $OwnerName = $elements.ownerName
    $RepositoryName = $elements.repositoryName

    if ($null -ne $Due_On)
    {
        $DueOnFormattedTime = $Since.ToUniversalTime().ToString('o')
    }

    $telemetryProperties = @{
        'OwnerName' = (Get-PiiSafeString -PlainText $OwnerName)
        'RepositoryName' = (Get-PiiSafeString -PlainText $RepositoryName)
        'Title' =  (Get-PiiSafeString -PlainText $Title)
    }

    $hashBody = @{
        'title' = $Title
        'state' = $State
        'description' = $Description
        'due_on' = $DueOnFormattedTime
    }

    $params = @{
        'UriFragment' = "repos/$OwnerName/$RepositoryName/milestones"
        'Body' = (ConvertTo-Json -InputObject $hashBody)
        'Method' = 'Post'
        'Description' =  "Creating milestone for $RepositoryName"
        'AccessToken' = $AccessToken
        'TelemetryEventName' = $MyInvocation.MyCommand.Name
        'TelemetryProperties' = $telemetryProperties
        'NoStatus' = (Resolve-ParameterWithDefaultConfigurationValue -Name NoStatus -ConfigValueName DefaultNoStatus)
    }

    return Invoke-GHRestMethod @params
}

function Set-GitHubMilestone
{
<#
    .DESCRIPTION
        Set an existing milestone for the given repository

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

    .PARAMETER Title
        The title of the milestone.

    .PARAMETER State
        Only milestones with this state are returned, either open or closed. Default: open

    .PARAMETER Description
        A description of the milestone.

    .PARAMETER Due_On
        The milestone due date.

    .PARAMETER AccessToken
        If provided, this will be used as the AccessToken for authentication with the
        REST Api.  Otherwise, will attempt to use the configured value or will run unauthenticated.

    .PARAMETER NoStatus
        If this switch is specified, long-running commands will run on the main thread
        with no commandline status update.  When not specified, those commands run in
        the background, enabling the command prompt to provide status information.
        If not supplied here, the DefaultNoStatus configuration property value will be used.

    .EXAMPLE
        Set-GitHubMilestone -OwnerName Powershell -RepositoryName PowerShellForGitHub -Title "Testing this API"

        Update an existing milestone for the PowerShell\PowerShellForGitHub project.
#>
    [CmdletBinding(
        SupportsShouldProcess,
        DefaultParametersetName='Elements')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSShouldProcess", "", Justification="Methods called within here make use of PSShouldProcess, and the switch is passed on to them inherently.")]
    param(
        [Parameter(Mandatory, ParameterSetName='Elements')]
        [string] $OwnerName,

        [Parameter(Mandatory, ParameterSetName='Elements')]
        [string] $RepositoryName,

        [Parameter(Mandatory, ParameterSetName='Uri')]
        [string] $Uri,

        [Parameter(Mandatory, ParameterSetName='Uri')]
        [Parameter(Mandatory, ParameterSetName='Elements')]
        [string] $Title,

        [Parameter(ParameterSetName='Uri')]
        [Parameter(ParameterSetName='Elements')]
        [string] $State,

        [Parameter(ParameterSetName='Uri')]
        [Parameter(ParameterSetName='Elements')]
        [string] $Description,

        [Parameter(ParameterSetName='Uri')]
        [Parameter(ParameterSetName='Elements')]
        [string] $Due_On,

        [string] $AccessToken,

        [switch] $NoStatus
    )

    Write-InvocationLog

    $elements = Resolve-RepositoryElements
    $OwnerName = $elements.ownerName
    $RepositoryName = $elements.repositoryName

    if ($null -ne $Due_On)
    {
        $DueOnFormattedTime = $Since.ToUniversalTime().ToString('o')
    }

    $telemetryProperties = @{
        'OwnerName' = (Get-PiiSafeString -PlainText $OwnerName)
        'RepositoryName' = (Get-PiiSafeString -PlainText $RepositoryName)
        'Title' =  (Get-PiiSafeString -PlainText $Title)
    }

    $hashBody = @{
        'title' = $Title
        'state' = $State
        'description' = $Description
        'due_on' = $DueOnFormattedTime
    }

    $params = @{
        'UriFragment' = "repos/$OwnerName/$RepositoryName/milestones"
        'Body' = (ConvertTo-Json -InputObject $hashBody)
        'Method' = 'Patch'
        'Description' =  "Creating milestone for $RepositoryName"
        'AccessToken' = $AccessToken
        'TelemetryEventName' = $MyInvocation.MyCommand.Name
        'TelemetryProperties' = $telemetryProperties
        'NoStatus' = (Resolve-ParameterWithDefaultConfigurationValue -Name NoStatus -ConfigValueName DefaultNoStatus)
    }

    return Invoke-GHRestMethod @params
}

function Remove-GitHubMilestone
{
<#
    .DESCRIPTION
        Deletes a Github milestone for the given repository

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

    .PARAMETER MilestoneNumber
        The number of a specific milestone to get.

    .PARAMETER AccessToken
        If provided, this will be used as the AccessToken for authentication with the
        REST Api.  Otherwise, will attempt to use the configured value or will run unauthenticated.

    .PARAMETER NoStatus
        If this switch is specified, long-running commands will run on the main thread
        with no commandline status update.  When not specified, those commands run in
        the background, enabling the command prompt to provide status information.
        If not supplied here, the DefaultNoStatus configuration property value will be used.

    .EXAMPLE
        Remove-GitHubMilestone -OwnerName Powershell -RepositoryName PowerShellForGitHub -MilestoneNumber 1

        Deletes a Github milestone from the PowerShell\PowerShellForGitHub project.
#>
    [CmdletBinding(
        SupportsShouldProcess,
        DefaultParametersetName='Elements')]
    [Alias('Delete-GitHubMilestone')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSShouldProcess", "", Justification="Methods called within here make use of PSShouldProcess, and the switch is passed on to them inherently.")]
    param(
        [Parameter(Mandatory, ParameterSetName='Elements')]
        [string] $OwnerName,

        [Parameter(Mandatory, ParameterSetName='Elements')]
        [string] $RepositoryName,

        [Parameter(Mandatory, ParameterSetName='Uri')]
        [string] $Uri,

        [Parameter(Mandatory, ParameterSetName='Uri')]
        [Parameter(Mandatory, ParameterSetName='Elements')]
        [string] $MilestoneNumber,

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
        'MilestoneNumber' =  (Get-PiiSafeString -PlainText $MilestoneNumber)
    }

    $params = @{
        'UriFragment' = "repos/$OwnerName/$RepositoryName/milestones/$MilestoneNumber"
        'Method' = 'Delete'
        'Description' =  "Removing milestone $MilestoneNumber for $RepositoryName"
        'AccessToken' = $AccessToken
        'TelemetryEventName' = $MyInvocation.MyCommand.Name
        'TelemetryProperties' = $telemetryProperties
        'NoStatus' = (Resolve-ParameterWithDefaultConfigurationValue -Name NoStatus -ConfigValueName DefaultNoStatus)
    }

    return Invoke-GHRestMethod @params
}
