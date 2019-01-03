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

    .PARAMETER Milestone
        The number of a specific milestone to get. If not supplied, will return back all milestones for this repository.

    .PARAMETER Sort
        How to sort the results.

    .PARAMETER Direction
        How to list the results. Ignored without the sort parameter.

    .PARAMETER State
        Only milestones with this state are returned.

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

    .EXAMPLE
        Get-GitHubMilestone -Uri 'https://github.com/PowerShell/PowerShellForGitHub' -Milestone 1
        Get milestone number 1 for the PowerShell\PowerShellForGitHub project.
#>
    [CmdletBinding(
        SupportsShouldProcess,
        DefaultParametersetName='RepositoryElements')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSShouldProcess", "", Justification="Methods called within here make use of PSShouldProcess, and the switch is passed on to them inherently.")]
    param(
        [Parameter(Mandatory, ParameterSetName='MilestoneElements')]
        [Parameter(Mandatory, ParameterSetName='RepositoryElements')]
        [string] $OwnerName,

        [Parameter(Mandatory, ParameterSetName='MilestoneElements')]
        [Parameter(Mandatory, ParameterSetName='RepositoryElements')]
        [string] $RepositoryName,

        [Parameter(Mandatory, ParameterSetName='MilestoneUri')]
        [Parameter(Mandatory, ParameterSetName='RepositoryUri')]
        [string] $Uri,

        [Parameter(Mandatory, ParameterSetName='MilestoneUri')]
        [Parameter(Mandatory, ParameterSetName='MilestoneElements')]
        [int] $Milestone,

        [Parameter(ParameterSetName='RepositoryUri')]
        [Parameter(ParameterSetName='RepositoryElements')]
        [ValidateSet('Open', 'Closed', 'All')]
        [string] $State,

        [Parameter(ParameterSetName='RepositoryUri')]
        [Parameter(ParameterSetName='RepositoryElements')]
        [ValidateSet('DueOn', 'Completeness')]
        [string] $Sort,

        [Parameter(ParameterSetName='RepositoryUri')]
        [Parameter(ParameterSetName='RepositoryElements')]
        [ValidateSet('Ascending', 'Descending')]
        [string] $Direction,

        [string] $AccessToken,

        [switch] $NoStatus
    )

    Write-InvocationLog

    $elements = Resolve-RepositoryElements
    $OwnerName = $elements.ownerName
    $RepositoryName = $elements.repositoryName
    $uriFragment = [String]::Empty
    $description = [String]::Empty

    $telemetryProperties = @{
        'OwnerName' = (Get-PiiSafeString -PlainText $OwnerName)
        'RepositoryName' = (Get-PiiSafeString -PlainText $RepositoryName)
        'ProvidedMilestone' = $PSBoundParameters.ContainsKey('Milestone')
    }

    if ($PSBoundParameters.ContainsKey('Milestone'))
    {
        $uriFragment = "repos/$OwnerName/$RepositoryName/milestones/$Milestone"
        $description = "Getting milestone $Milestone for $RepositoryName"
    }
    else
    {
        $getParams = @()

        if ($PSBoundParameters.ContainsKey('Sort'))
        {
            $sortConverter = @{
                'Completeness' = 'completeness'
                'DueOn' = 'due_on'
            }

            $getParams += "sort=$($sortConverter[$Sort])"
        }

        if ($PSBoundParameters.ContainsKey('Direction'))
        {
            $directionConverter = @{
                'Ascending' = 'asc'
                'Descending' = 'desc'
            }

            $getParams += "direction=$($directionConverter[$Direction])"
        }

        if ($PSBoundParameters.ContainsKey('State'))
        {
            $State = $State.ToLower()
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
        Creates a new Github milestone for the given repository

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
        The state of the milestone.

    .PARAMETER Description
        A description of the milestone.

    .PARAMETER DueOn
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

        Creates a new Github milestone for the PowerShell\PowerShellForGitHub project.
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

        [ValidateSet('Open', 'Closed')]
        [string] $State,

        [string] $Description,

        [DateTime] $DueOn,

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
        'Title' =  (Get-PiiSafeString -PlainText $Title)
    }

    $hashBody = @{
        'title' = $Title
    }

    if ($PSBoundParameters.ContainsKey('State'))
    {
        $State = $State.ToLower()
        $hashBody.add('state', $State)
    }

    if ($PSBoundParameters.ContainsKey('Description'))
    {
        $hashBody.add('description', $Description)
    }

    if ($PSBoundParameters.ContainsKey('DueOn'))
    {
        $DueOnFormattedTime = $DueOn.ToUniversalTime().ToString('o')
        $hashBody.add('due_on', $DueOnFormattedTime)
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
        Update an existing milestone for the given repository

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

    .PARAMETER Milestone
        The number of a specific milestone to get.

    .PARAMETER Title
        The title of the milestone.

    .PARAMETER State
        The state of the milestone.

    .PARAMETER Description
        A description of the milestone.

    .PARAMETER DueOn
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
        Set-GitHubMilestone -OwnerName Powershell -RepositoryName PowerShellForGitHub -Milestone 1 -Title "Testing this API"

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
        [int] $Milestone,

        [Parameter(Mandatory, ParameterSetName='Uri')]
        [Parameter(Mandatory, ParameterSetName='Elements')]
        [string] $Title,

        [ValidateSet('Open', 'Closed')]
        [string] $State,

        [string] $Description,

        [DateTime] $DueOn,

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
        'Title' =  (Get-PiiSafeString -PlainText $Title)
        'Milestone' =  (Get-PiiSafeString -PlainText $Milestone)
    }

    $hashBody = @{
        'title' = $Title
    }

    if ($PSBoundParameters.ContainsKey('State'))
    {
        $State = $State.ToLower()
        $hashBody.add('state', $State)
    }

    if ($PSBoundParameters.ContainsKey('Description'))
    {
        $hashBody.add('description', $Description)
    }

    if ($PSBoundParameters.ContainsKey('DueOn'))
    {
        $DueOnFormattedTime = $DueOn.ToUniversalTime().ToString('o')
        $hashBody.add('due_on', $DueOnFormattedTime)
    }

    $params = @{
        'UriFragment' = "repos/$OwnerName/$RepositoryName/milestones/$Milestone"
        'Body' = (ConvertTo-Json -InputObject $hashBody)
        'Method' = 'Patch'
        'Description' =  "Setting milestone $Milestone for $RepositoryName"
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

    .PARAMETER Milestone
        The number of a specific milestone to delete.

    .PARAMETER AccessToken
        If provided, this will be used as the AccessToken for authentication with the
        REST Api.  Otherwise, will attempt to use the configured value or will run unauthenticated.

    .PARAMETER NoStatus
        If this switch is specified, long-running commands will run on the main thread
        with no commandline status update.  When not specified, those commands run in
        the background, enabling the command prompt to provide status information.
        If not supplied here, the DefaultNoStatus configuration property value will be used.

    .EXAMPLE
        Remove-GitHubMilestone -OwnerName Powershell -RepositoryName PowerShellForGitHub -Milestone 1

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
        [string] $Milestone,

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
        'Milestone' =  (Get-PiiSafeString -PlainText $Milestone)
    }

    $params = @{
        'UriFragment' = "repos/$OwnerName/$RepositoryName/milestones/$Milestone"
        'Method' = 'Delete'
        'Description' =  "Removing milestone $Milestone for $RepositoryName"
        'AccessToken' = $AccessToken
        'TelemetryEventName' = $MyInvocation.MyCommand.Name
        'TelemetryProperties' = $telemetryProperties
        'NoStatus' = (Resolve-ParameterWithDefaultConfigurationValue -Name NoStatus -ConfigValueName DefaultNoStatus)
    }

    return Invoke-GHRestMethod @params
}
