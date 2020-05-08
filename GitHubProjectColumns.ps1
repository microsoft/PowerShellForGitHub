# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

function Get-GitHubProjectColumn
{
<#
    .DESCRIPTION
        Get the columns for a given Github Project.

        The Git repo for this module can be found here: http://aka.ms/PowerShellForGitHub

    .PARAMETER Project
        ID of the project to retrieve a list of columns for.

    .PARAMETER Column
        ID of the column to retrieve.

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

        Get the column with ID 999999.
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
    elseif ($PSCmdlet.ParameterSetName -eq 'Column')
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
        ID of the project to create a column for.

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

        Creates a column called 'Done' for the project with ID 999999.
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
    $telemetryProperties['Name'] = Get-PiiSafeString -PlainText $Project

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
        ID of the column to modify.

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

        Set the project column name to 'NewColumnName' with column with ID 999999.
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
        ID of the column to remove.

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

        Remove project column with ID 999999.

    .EXAMPLE
        Remove-GitHubProjectColumn -Column 999999 -Confirm:$False

        Removes the project column with ID 999999 without prompting for confirmation.
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
        ID of the column to move.

    .PARAMETER First
        Moves the column to be the first for the project.

    .PARAMETER Last
        Moves the column to be the last for the project.

    .PARAMETER After
        Moves the column to the position after the column ID specified.
        Must be within the same project.

    .PARAMETER AccessToken
        If provided, this will be used as the AccessToken for authentication with the
        REST Api.  Otherwise, will attempt to use the configured value or will run unauthenticated.

    .PARAMETER NoStatus
        If this switch is specified, long-running commands will run on the main thread
        with no command line status update.  When not specified, those commands run in
        the background, enabling the command prompt to provide status information.
        If not supplied here, the DefaultNoStatus configuration property value will be used.

    .EXAMPLE
        Move-GitHubProjectColumn -Column 999999 -First

        Moves the project column with ID 999999 to the first position.

    .EXAMPLE
        Move-GitHubProjectColumn -Column 999999 -Last

        Moves the project column with ID 999999 to the Last position.

    .EXAMPLE
        Move-GitHubProjectColumn -Column 999999 -After 888888

        Moves the project column with ID 999999 to the position after column with ID 888888.
#>
    [CmdletBinding(
        SupportsShouldProcess)]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSShouldProcess", "", Justification = "Methods called within here make use of PSShouldProcess, and the switch is passed on to them inherently.")]
    param(
        [Parameter(Mandatory)]
        [int64] $Column,

        [switch] $First,

        [switch] $Last,

        [int64] $After,

        [string] $AccessToken,

        [switch] $NoStatus
    )

    Write-InvocationLog

    $telemetryProperties = @{}

    $uriFragment = "/projects/columns/$Column/moves"
    $apiDescription = "Updating column $Column"

    if (-not ($First -xor $Last -xor ($After -gt 0)))
    {
        $message = 'You must use one (and only one) of the parameters First, Last or After.'
        Write-Log -Message $message -level Error
        throw $message
    }
    elseif($First)
    {
        $position = 'first'
    }
    elseif($Last)
    {
        $position = 'last'
    }
    else
    {
        $position = "after:$After"
    }

    $hashBody = @{
        'position' = $Position
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