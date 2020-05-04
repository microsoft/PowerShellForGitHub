# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

function Get-GitHubProjectCard
{
<#
    .DESCRIPTION
        Get the cards for a given Github Project Column.

        The Git repo for this module can be found here: http://aka.ms/PowerShellForGitHub

    .PARAMETER Column
        Id of the column to retrieve cards for.

    .PARAMETER ArchivedState
        Only cards with this archived_state are returned.
        Options are all, archived, or not_archived (default).

    .PARAMETER AccessToken
        If provided, this will be used as the AccessToken for authentication with the
        REST Api.  Otherwise, will attempt to use the configured value or will run unauthenticated.

    .PARAMETER NoStatus
        If this switch is specified, long-running commands will run on the main thread
        with no command line status update.  When not specified, those commands run in
        the background, enabling the command prompt to provide status information.
        If not supplied here, the DefaultNoStatus configuration property value will be used.

    .EXAMPLE
        Get-GitHubProjectCard -Column 999999

        Get the the not_archived cards for column 999999.

    .EXAMPLE
        Get-GitHubProjectCard -Column 999999 -ArchivedState All

        Gets all the cards for column 999999, no matter the archived_state.

    .EXAMPLE
        Get-GitHubProjectCard -Column 999999 -ArchivedState Archived

        Gets the archived cards for column 999999.

    .EXAMPLE
        Get-GitHubProjectCard -Card 999999

        Gets the card with id 999999.
#>
    [CmdletBinding(
        SupportsShouldProcess,
        DefaultParameterSetName = 'Column')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSShouldProcess", "", Justification = "Methods called within here make use of PSShouldProcess, and the switch is passed on to them inherently.")]
    param(
        [Parameter(Mandatory, ParameterSetName = 'Column')]
        [int64] $Column,

        [Parameter(Mandatory, ParameterSetName = 'Card')]
        [int64] $Card,

        [ValidateSet('All', 'Archived', 'Not_Archived')]
        [string] $ArchivedState,

        [string] $AccessToken,

        [switch] $NoStatus
    )

    Write-InvocationLog

    $telemetryProperties = @{}

    $uriFragment = [String]::Empty
    $description = [String]::Empty

    if ($PSCmdlet.ParameterSetName -eq 'Column')
    {
        $telemetryProperties['Column'] = $true

        $uriFragment = "/projects/columns/$Column/cards"
        $description = "Getting cards for column $Column"
    }
    elseif ($PSCmdlet.ParameterSetName -eq 'Card')
    {
        $telemetryProperties['Card'] = $true

        $uriFragment = "/projects/columns/cards/$Card"
        $description = "Getting project card $Card"
    }

    if ($PSBoundParameters.ContainsKey('ArchivedState'))
    {
        $getParams = @()
        $ArchivedState = $ArchivedState.ToLower()
        $getParams += "archived_state=$ArchivedState"

        $uriFragment = "$uriFragment`?" + ($getParams -join '&')
        $description += " with archived_state '$Archived_State'"
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

function New-GitHubProjectCard
{
<#
    .DESCRIPTION
        Creates a new card for a Github project.

        The Git repo for this module can be found here: http://aka.ms/PowerShellForGitHub

    .PARAMETER Column
        Id of the column to create a card for.

    .PARAMETER Note
        The name of the column to create.

    .PARAMETER ContentId
        The issue or pull request id you want to associate with this card.

    .PARAMETER ContentType
        The type of content you want to associate with this card.
        Required if you provide ContentId.
        Use Issue when ContentId is an issue id and use PullRequest when ContentId is a pull request id.

    .PARAMETER AccessToken
        If provided, this will be used as the AccessToken for authentication with the
        REST Api.  Otherwise, will attempt to use the configured value or will run unauthenticated.

    .PARAMETER NoStatus
        If this switch is specified, long-running commands will run on the main thread
        with no command line status update.  When not specified, those commands run in
        the background, enabling the command prompt to provide status information.
        If not supplied here, the DefaultNoStatus configuration property value will be used.

    .EXAMPLE
        New-GitHubProjectCard -Column 999999 -Note 'Note on card'

        Creates a card on column 999999 with the note 'Note on card'.

    .EXAMPLE
        New-GitHubProjectCard -Column 999999 -ContentId 888888 -ContentType Issue

        Creates a card on column 999999 for the issue with id 888888.

    .EXAMPLE
        New-GitHubProjectCard -Column 999999 -ContentId 888888 -ContentType Issue

        Creates a card on column 999999 for the issue with id 888888.

    .EXAMPLE
        New-GitHubProjectCard -Column 999999 -ContentId 777777 -ContentType PullRequest

        Creates a card on column 999999 for the pull request with id 777777.
#>
    [CmdletBinding(
        SupportsShouldProcess,
        DefaultParameterSetName = 'Note')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSShouldProcess", "", Justification = "Methods called within here make use of PSShouldProcess, and the switch is passed on to them inherently.")]
    param(

        [Parameter(Mandatory)]
        [int64] $Column,

        [Parameter(Mandatory, ParameterSetName = 'Note')]
        [string] $Note,

        [Parameter(Mandatory, ParameterSetName = 'Content')]
        [int] $ContentId,

        [Parameter(Mandatory, ParameterSetName = 'Content')]
        [ValidateSet('Issue', 'PullRequest')]
        [string] $ContentType,

        [string] $AccessToken,

        [switch] $NoStatus
    )

    Write-InvocationLog

    $telemetryProperties = @{}

    $uriFragment = "/projects/columns/$Column/cards"
    $apiDescription = "Creating project card"

    if ($PSCmdlet.ParameterSetName -eq 'Note')
    {
        $telemetryProperties['Note'] = $true

        $hashBody = @{
            'note' = $Note
        }
    }
    elseif ($PSCmdlet.ParameterSetName -eq 'Content')
    {
        $telemetryProperties['Content'] = $true

        $hashBody = @{
            'content_id' = $ContentId
            'content_type' = $ContentType
        }
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

function Set-GitHubProjectCard
{
<#
    .DESCRIPTION
        Modify a GitHub Project Card.

        The Git repo for this module can be found here: http://aka.ms/PowerShellForGitHub

    .PARAMETER Card
        Id of the card to modify.

    .PARAMETER Note
        The note content for the card.

    .PARAMETER Archived
        Archive or restore a project card.

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
        [int64] $Card,

        [string] $Note,

        [switch] $Archived,

        [switch] $NoStatus
    )

    Write-InvocationLog

    $telemetryProperties = @{}

    $uriFragment = "/projects/columns/cards/$Card"
    $apiDescription = "Updating card $Card"

    $hashBody = @{}

    if ($PSBoundParameters.ContainsKey('Note'))
    {
        $telemetryProperties['Note'] = $true
        $hashBody.add('note', $Note)
    }
    if ($PSBoundParameters.ContainsKey('Archived'))
    {
        $telemetryProperties['Archived'] = $true
        $hashBody.add('archived', $Archived.ToBool())
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

function Remove-GitHubProjectCard
{
<#
    .DESCRIPTION
        Removes a project card.

        The Git repo for this module can be found here: http://aka.ms/PowerShellForGitHub

    .PARAMETER Card
        Id of the card to remove.

    .PARAMETER AccessToken
        If provided, this will be used as the AccessToken for authentication with the
        REST Api.  Otherwise, will attempt to use the configured value or will run unauthenticated.

    .PARAMETER NoStatus
        If this switch is specified, long-running commands will run on the main thread
        with no command line status update.  When not specified, those commands run in
        the background, enabling the command prompt to provide status information.
        If not supplied here, the DefaultNoStatus configuration property value will be used.

    .EXAMPLE
        Remove-GitHubProjectCard -Card 999999

        Remove project card with id 999999.
#>
    [CmdletBinding(
        SupportsShouldProcess,
        ConfirmImpact = 'High')]
    [Alias('Delete-GitHubProjectCard')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSShouldProcess", "", Justification = "Methods called within here make use of PSShouldProcess, and the switch is passed on to them inherently.")]
    param(
        [Parameter(Mandatory)]
        [int64] $Card,

        [string] $AccessToken,

        [switch] $NoStatus
    )

    Write-InvocationLog

    $telemetryProperties = @{}

    $uriFragment = "/projects/columns/cards/$Card"
    $description = "Deleting card $Card"

    if ($PSCmdlet.ShouldProcess($Card, "Remove card"))
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

function Move-GitHubProjectCard
{
<#
    .DESCRIPTION
        Move a GitHub Project Card.

        The Git repo for this module can be found here: http://aka.ms/PowerShellForGitHub

    .PARAMETER Card
        Id of the card to move.

   .PARAMETER Position
        The new position of the card.
        Can be one of top, bottom, or after:<card_id>, where <card_id> is the id value of a
        card in the same column, or in the new column specified by ColumnId.

    .PARAMETER ColumnId
        The id of a column in the same project to move the card to.

    .PARAMETER AccessToken
        If provided, this will be used as the AccessToken for authentication with the
        REST Api.  Otherwise, will attempt to use the configured value or will run unauthenticated.

    .PARAMETER NoStatus
        If this switch is specified, long-running commands will run on the main thread
        with no command line status update.  When not specified, those commands run in
        the background, enabling the command prompt to provide status information.
        If not supplied here, the DefaultNoStatus configuration property value will be used.

    .EXAMPLE
        Move-GitHubProjectCard -Card 999999 -Position Top

        Moves the project card with id 999999 to the top of the column.

    .EXAMPLE
        Move-GitHubProjectCard -Card 999999 -Position Bottom

        Moves the project card with id 999999 to the bottom of the column.

    .EXAMPLE
        Move-GitHubProjectCard -Card 999999 -ColumnId 123456

        Moves the project card with id 999999 to the column with id 123456.

    .EXAMPLE
        Move-GitHubProjectCard -Column 999999 -Position After:888888

        Moves the project card with id 999999 to the position after the card id 888888.
        Within the same column.

    .EXAMPLE
        Move-GitHubProjectCard -Column 999999 -Position After:888888 -ColumnId 123456

        Moves the project card with id 999999 to the position after the card id 888888, in
        the column with id 123456.
#>
    [CmdletBinding(
        SupportsShouldProcess)]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSShouldProcess", "", Justification = "Methods called within here make use of PSShouldProcess, and the switch is passed on to them inherently.")]
    param(
        [Parameter(Mandatory)]
        [int64] $Card,

        [string] $Position,

        [int64] $ColumnId,

        [string] $AccessToken,

        [switch] $NoStatus
    )

    Write-InvocationLog

    $telemetryProperties = @{}

    $uriFragment = "/projects/columns/cards/$Card/moves"
    $apiDescription = "Updating card $Card"

    $hashBody = @{}

    if ($PSBoundParameters.ContainsKey('Position'))
    {
        $telemetryProperties['Position'] = $true
        $hashBody.add('position', $Position.ToLower())
    }

    if ($PSBoundParameters.ContainsKey('ColumnId'))
    {
        if (!$PSBoundParameters.ContainsKey('Position'))
        {
            $message = "When specifying ColumnId, you must also specify Position."
            Write-Log -Message $message -Level Error
            throw $message
        }
        $telemetryProperties['ColumnId'] = $true
        $hashBody.add('column_id', $ColumnId)
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