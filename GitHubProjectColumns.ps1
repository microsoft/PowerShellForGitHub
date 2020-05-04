# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

function Get-GitHubProjectColumn
{
<#
    .DESCRIPTION
        Get the columns for a given Github Project.

        The Git repo for this module can be found here: http://aka.ms/PowerShellForGitHub

    .PARAMETER Project
        Id of the project to retrieve a list of columns for.

    .PARAMETER Column
        Id of the column to retrieve.

    .PARAMETER AccessToken
        If provided, this will be used as the AccessToken for authentication with the
        REST Api.  Otherwise, will attempt to use the configured value or will run unauthenticated.

    .PARAMETER NoStatus
        If this switch is specified, long-running commands will run on the main thread
        with no command line status update.  When not specified, those commands run in
        the background, enabling the command prompt to provide status information.
        If not supplied here, the DefaultNoStatus configuration property value will be used.

    .EXAMPLE
        Get-GitHubProjectColumn -Project 999999

        Get the columns for project 999999.

    .EXAMPLE
        Get-GitHubProjectColumn -Column 999999

        Get the column with id 999999.
#>
    [CmdletBinding(
        SupportsShouldProcess,
        DefaultParameterSetName = 'Project')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSShouldProcess", "", Justification = "Methods called within here make use of PSShouldProcess, and the switch is passed on to them inherently.")]
    param(
        [Parameter(Mandatory, ParameterSetName = 'Project')]
        [int64] $Project,

        [Parameter(Mandatory, ParameterSetName = 'Column')]
        [int64] $Column,

        [string] $AccessToken,

        [switch] $NoStatus
    )

    Write-InvocationLog

    $telemetryProperties = @{}

    $uriFragment = [String]::Empty
    $description = [String]::Empty
    if ($PSCmdlet.ParameterSetName -eq 'Project')
    {
        $telemetryProperties['Project'] = Get-PiiSafeString -PlainText $Project

        $uriFragment = "/projects/$Project/columns"
        $description = "Getting project columns for $Project"
    }
    if ($PSCmdlet.ParameterSetName -eq 'Column')
    {
        $telemetryProperties['Column'] = Get-PiiSafeString -PlainText $Column

        $uriFragment = "/projects/columns/$Column"
        $description = "Getting project column $Column"
    }

    $params = @{
        'UriFragment' = $uriFragment
        'Description' = $description
        'AccessToken' = $AccessToken
        'TelemetryEventName' = $MyInvocation.MyCommand.Name
        'TelemetryProperties' = $telemetryProperties
        'NoStatus' = (Resolve-ParameterWithDefaultConfigurationValue -Name NoStatus -ConfigValueName DefaultNoStatus)
        'AcceptHeader' = 'application/vnd.github.inertia-preview+json'
    }

    return Invoke-GHRestMethodMultipleResult @params
}

function New-GitHubProjectColumn
{
<#
    .DESCRIPTION
        Creates a new column for a Github project.

        The Git repo for this module can be found here: http://aka.ms/PowerShellForGitHub

    .PARAMETER Project
        Id of the project to create a column for.

    .PARAMETER Name
        The name of the column to create.

    .PARAMETER AccessToken
        If provided, this will be used as the AccessToken for authentication with the
        REST Api.  Otherwise, will attempt to use the configured value or will run unauthenticated.

    .PARAMETER NoStatus
        If this switch is specified, long-running commands will run on the main thread
        with no command line status update.  When not specified, those commands run in
        the background, enabling the command prompt to provide status information.
        If not supplied here, the DefaultNoStatus configuration property value will be used.

    .EXAMPLE
        New-GitHubProjectColumn -Project 999999 -Name 'Done'

        Creates a column called 'Done' for the project with id 999999.
#>
    [CmdletBinding(
        SupportsShouldProcess)]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSShouldProcess", "", Justification = "Methods called within here make use of PSShouldProcess, and the switch is passed on to them inherently.")]
    param(

        [Parameter(Mandatory)]
        [int64] $Project,

        [Parameter(Mandatory)]
        [string] $Name,

        [string] $AccessToken,

        [switch] $NoStatus
    )

    Write-InvocationLog

    $telemetryProperties = @{}
    $telemetryProperties['Name'] = Get-PiiSafeString -PlainText $Name

    $uriFragment = "/projects/$Project/columns"
    $apiDescription = "Creating project column $Name"

    $hashBody = @{
        'name' = $Name
    }

    $params = @{
        'UriFragment' = $uriFragment
        'Body' = (ConvertTo-Json -InputObject $hashBody)
        'Method' = 'Post'
        'Description' = $apiDescription
        'AccessToken' = $AccessToken
        'TelemetryEventName' = $MyInvocation.MyCommand.Name
        'TelemetryProperties' = $telemetryProperties
        'NoStatus' = (Resolve-ParameterWithDefaultConfigurationValue -Name NoStatus -ConfigValueName DefaultNoStatus)
        'AcceptHeader' = 'application/vnd.github.inertia-preview+json'
    }

    return Invoke-GHRestMethod @params
}

function Set-GitHubProjectColumn
{
<#
    .DESCRIPTION
        Modify a GitHub Project Column.

        The Git repo for this module can be found here: http://aka.ms/PowerShellForGitHub

    .PARAMETER Column
        Id of the column to retrieve.

    .PARAMETER Name
        The name for the column.

    .PARAMETER AccessToken
        If provided, this will be used as the AccessToken for authentication with the
        REST Api.  Otherwise, will attempt to use the configured value or will run unauthenticated.

    .PARAMETER NoStatus
        If this switch is specified, long-running commands will run on the main thread
        with no command line status update.  When not specified, those commands run in
        the background, enabling the command prompt to provide status information.
        If not supplied here, the DefaultNoStatus configuration property value will be used.

    .EXAMPLE
        Set-GitHubProjectColumn -Column 999999 -Name NewColumnName

        Set the project column name to 'NewColumnName' with column with id 999999.
#>
    [CmdletBinding(
        SupportsShouldProcess)]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSShouldProcess", "", Justification = "Methods called within here make use of PSShouldProcess, and the switch is passed on to them inherently.")]
    param(
        [Parameter(Mandatory)]
        [int64] $Column,

        [Parameter(Mandatory)]
        [string] $Name,

        [string] $AccessToken,

        [switch] $NoStatus
    )

    Write-InvocationLog

    $telemetryProperties = @{}

    $uriFragment = "/projects/columns/$Column"
    $apiDescription = "Updating column $Column"

    $hashBody = @{
        'name' = $Name
    }

    $params = @{
    'UriFragment' = $uriFragment
        'Description' = $apiDescription
        'Body' = (ConvertTo-Json -InputObject $hashBody)
        'AccessToken' = $AccessToken
        'Method' = 'Patch'
        'TelemetryEventName' = $MyInvocation.MyCommand.Name
        'TelemetryProperties' = $telemetryProperties
        'NoStatus' = (Resolve-ParameterWithDefaultConfigurationValue -Name NoStatus -ConfigValueName DefaultNoStatus)
        'AcceptHeader' = 'application/vnd.github.inertia-preview+json'
    }

    return Invoke-GHRestMethod @params
}

function Remove-GitHubProjectColumn
{
<#
    .DESCRIPTION
        Removes the column for a project.

        The Git repo for this module can be found here: http://aka.ms/PowerShellForGitHub

    .PARAMETER Column
        Id of the column to remove.

    .PARAMETER AccessToken
        If provided, this will be used as the AccessToken for authentication with the
        REST Api.  Otherwise, will attempt to use the configured value or will run unauthenticated.

    .PARAMETER NoStatus
        If this switch is specified, long-running commands will run on the main thread
        with no command line status update.  When not specified, those commands run in
        the background, enabling the command prompt to provide status information.
        If not supplied here, the DefaultNoStatus configuration property value will be used.

    .EXAMPLE
        Remove-GitHubProjectColumn -Column 999999

        Remove project column with id 999999.
#>
    [CmdletBinding(
        SupportsShouldProcess,
        ConfirmImpact = 'High')]
    [Alias('Delete-GitHubProjectColumn')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSShouldProcess", "", Justification = "Methods called within here make use of PSShouldProcess, and the switch is passed on to them inherently.")]
    param(
        [Parameter(Mandatory)]
        [int64] $Column,

        [string] $AccessToken,

        [switch] $NoStatus
    )

    Write-InvocationLog

    $telemetryProperties = @{}

    $uriFragment = "/projects/columns/$Column"
    $description = "Deleting column $Column"

    if ($PSCmdlet.ShouldProcess($Column, "Remove column"))
    {
        $params = @{
            'UriFragment' = $uriFragment
            'Description' = $description
            'AccessToken' = $AccessToken
            'Method' = 'Delete'
            'TelemetryEventName' = $MyInvocation.MyCommand.Name
            'TelemetryProperties' = $telemetryProperties
            'NoStatus' = (Resolve-ParameterWithDefaultConfigurationValue -Name NoStatus -ConfigValueName DefaultNoStatus)
            'AcceptHeader' = 'application/vnd.github.inertia-preview+json'
        }

        return Invoke-GHRestMethod @params
    }
}

function Move-GitHubProjectColumn
{
<#
    .DESCRIPTION
        Move a GitHub Project Column.

        The Git repo for this module can be found here: http://aka.ms/PowerShellForGitHub

    .PARAMETER Column
        Id of the column to move.

    .PARAMETER Position
        The new position of th column.
        Can be one of first, last, or after:<column_id>, where <column_id> is the id value of a
        column in the same project.

    .PARAMETER AccessToken
        If provided, this will be used as the AccessToken for authentication with the
        REST Api.  Otherwise, will attempt to use the configured value or will run unauthenticated.

    .PARAMETER NoStatus
        If this switch is specified, long-running commands will run on the main thread
        with no command line status update.  When not specified, those commands run in
        the background, enabling the command prompt to provide status information.
        If not supplied here, the DefaultNoStatus configuration property value will be used.

    .EXAMPLE
        Move-GitHubProjectColumn -Column 999999 -Position First

        Moves the project column with id 999999 to the first position.

    .EXAMPLE
        Move-GitHubProjectColumn -Column 999999 -Position First

        Moves the project column with id 999999 to the first position.

    .EXAMPLE
        Move-GitHubProjectColumn -Column 999999 -Position Last

        Moves the project column with id 999999 to the Last position.

    .EXAMPLE
        Move-GitHubProjectColumn -Column 999999 -Position After:888888

        Moves the project column with id 999999 to the position after column with id 888888.
#>
    [CmdletBinding(
        SupportsShouldProcess)]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSShouldProcess", "", Justification = "Methods called within here make use of PSShouldProcess, and the switch is passed on to them inherently.")]
    param(
        [Parameter(Mandatory)]
        [int64] $Column,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string] $Position,

        [string] $AccessToken,

        [switch] $NoStatus
    )

    Write-InvocationLog

    $telemetryProperties = @{}

    $uriFragment = "/projects/columns/$Column/moves"
    $apiDescription = "Updating column $Column"

    $hashBody = @{
        'position' = $Position.ToLower()
    }

    $params = @{
    'UriFragment' = $uriFragment
        'Description' = $apiDescription
        'Body' = (ConvertTo-Json -InputObject $hashBody)
        'AccessToken' = $AccessToken
        'Method' = 'Post'
        'TelemetryEventName' = $MyInvocation.MyCommand.Name
        'TelemetryProperties' = $telemetryProperties
        'NoStatus' = (Resolve-ParameterWithDefaultConfigurationValue -Name NoStatus -ConfigValueName DefaultNoStatus)
        'AcceptHeader' = 'application/vnd.github.inertia-preview+json'
    }

    return Invoke-GHRestMethod @params
}