# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

@{
    GitHubProjectCardTypeName = 'GitHub.ProjectCard'
 }.GetEnumerator() | ForEach-Object {
     Set-Variable -Scope Script -Option ReadOnly -Name $_.Key -Value $_.Value
 }

filter Get-GitHubProjectCard
{
<#
    .DESCRIPTION
        Get the cards for a given GitHub Project Column.

        The Git repo for this module can be found here: http://aka.ms/PowerShellForGitHub

    .PARAMETER Column
        ID of the column to retrieve cards for.

    .PARAMETER State
        Only cards with this State are returned.
        Options are all, archived, or NotArchived (default).

    .PARAMETER AccessToken
        If provided, this will be used as the AccessToken for authentication with the
        REST Api.  Otherwise, will attempt to use the configured value or will run unauthenticated.

    .PARAMETER NoStatus
        If this switch is specified, long-running commands will run on the main thread
        with no command line status update.  When not specified, those commands run in
        the background, enabling the command prompt to provide status information.
        If not supplied here, the DefaultNoStatus configuration property value will be used.

    .OUTPUTS
        GitHub.ProjectCard

    .EXAMPLE
        Get-GitHubProjectCard -Column 999999

        Get the the not_archived cards for column 999999.

    .EXAMPLE
        Get-GitHubProjectCard -Column 999999 -State All

        Gets all the cards for column 999999, no matter the State.

    .EXAMPLE
        Get-GitHubProjectCard -Column 999999 -State Archived

        Gets the archived cards for column 999999.

    .EXAMPLE
        Get-GitHubProjectCard -Card 999999

        Gets the card with ID 999999.
#>
    [CmdletBinding(
        SupportsShouldProcess,
        DefaultParameterSetName = 'Card')]
    [OutputType({$script:GitHubProjectCardTypeName})]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSShouldProcess", "", Justification = "Methods called within here make use of PSShouldProcess, and the switch is passed on to them inherently.")]
    param(
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName = 'Column')]
        [Alias('ColumnId')]
        [int64] $Column,

        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName = 'Card')]
        [Alias('CardId')]
        [int64] $Card,

        [ValidateSet('All', 'Archived', 'NotArchived')]
        [Alias('ArchivedState')]
        [string] $State = 'NotArchived',

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

    if ($PSBoundParameters.ContainsKey('State'))
    {
        $getParams = @()
        $Archived = $State.ToLower().Replace('notarchived','not_archived')
        $getParams += "archived_state=$Archived"

        $uriFragment = "$uriFragment`?" + ($getParams -join '&')
        $description += " with State '$Archived'"
    }

    $params = @{
        'UriFragment' = $uriFragment
        'Description' = $description
        'AccessToken' = $AccessToken
        'TelemetryEventName' = $MyInvocation.MyCommand.Name
        'TelemetryProperties' = $telemetryProperties
        'NoStatus' = (Resolve-ParameterWithDefaultConfigurationValue -Name NoStatus -ConfigValueName DefaultNoStatus)
        'AcceptHeader' = $script:inertiaAcceptHeader
    }

    return (Invoke-GHRestMethodMultipleResult @params | Add-GitHubProjectCardAdditionalProperties)
}

filter New-GitHubProjectCard
{
<#
    .DESCRIPTION
        Creates a new card for a GitHub project.

        The Git repo for this module can be found here: http://aka.ms/PowerShellForGitHub

    .PARAMETER Column
        ID of the column to create a card for.

    .PARAMETER Note
        The name of the column to create.

    .PARAMETER IssueId
        The ID of the issue you want to associate with this card (not to be confused with
        the Issue _number_ which you see in the URL and can refer to with a hashtag).

    .PARAMETER PullRequestId
        The ID of the pull request you want to associate with this card (not to be confused with
        the Pull Request _number_ which you see in the URL and can refer to with a hashtag).

    .PARAMETER AccessToken
        If provided, this will be used as the AccessToken for authentication with the
        REST Api.  Otherwise, will attempt to use the configured value or will run unauthenticated.

    .PARAMETER NoStatus
        If this switch is specified, long-running commands will run on the main thread
        with no command line status update.  When not specified, those commands run in
        the background, enabling the command prompt to provide status information.
        If not supplied here, the DefaultNoStatus configuration property value will be used.

    .OUTPUTS
        GitHub.ProjectCard

    .EXAMPLE
        New-GitHubProjectCard -Column 999999 -Note 'Note on card'

        Creates a card on column 999999 with the note 'Note on card'.

    .EXAMPLE
        New-GitHubProjectCard -Column 999999 -IssueId 888888

        Creates a card on column 999999 for the issue with ID 888888.

    .EXAMPLE
        New-GitHubProjectCard -Column 999999 -PullRequestId 888888

        Creates a card on column 999999 for the pull request with ID 888888.
#>
    [CmdletBinding(
        SupportsShouldProcess,
        DefaultParameterSetName = 'Note')]
    [OutputType({$script:GitHubProjectCardTypeName})]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSShouldProcess", "", Justification = "Methods called within here make use of PSShouldProcess, and the switch is passed on to them inherently.")]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSReviewUnusedParameter", "", Justification="One or more parameters (like NoStatus) are only referenced by helper methods which get access to it from the stack via Get-Variable -Scope 1.")]
    param(
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName)]
        [Alias('ColumnId')]
        [int64] $Column,

        [Parameter(
            Mandatory,
            ParameterSetName = 'Note')]
        [Alias('Content')]
        [string] $Note,

        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName = 'Issue')]
        [int64] $IssueId,

        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName = 'PullRequest')]
        [int64] $PullRequestId,

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
    elseif ($PSCmdlet.ParameterSetName -in ('Issue', 'PullRequest'))
    {
        $contentType = $PSCmdlet.ParameterSetName
        $telemetryProperties['ContentType'] = $contentType

        $hashBody = @{
            'content_type' = $contentType
        }

        if ($PSCmdlet.ParameterSetName -eq 'Issue')
        {
            $hashBody['content_id'] = $IssueId
        }
        else
        {
            $hashBody['content_id'] = $PullRequestId
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
        'AcceptHeader' = $script:inertiaAcceptHeader
    }

    return (Invoke-GHRestMethod @params | Add-GitHubProjectCardAdditionalProperties)
}

filter Set-GitHubProjectCard
{
<#
    .DESCRIPTION
        Modify a GitHub Project Card.

        The Git repo for this module can be found here: http://aka.ms/PowerShellForGitHub

    .PARAMETER Card
        ID of the card to modify.

    .PARAMETER Note
        The note content for the card.  Only valid for cards without another type of content,
        so this cannot be specified if the card already has a content_id and content_type.

    .PARAMETER Archive
        Archive a project card.

    .PARAMETER Restore
        Restore a project card.

    .PARAMETER AccessToken
        If provided, this will be used as the AccessToken for authentication with the
        REST Api.  Otherwise, will attempt to use the configured value or will run unauthenticated.

    .PARAMETER NoStatus
        If this switch is specified, long-running commands will run on the main thread
        with no command line status update.  When not specified, those commands run in
        the background, enabling the command prompt to provide status information.
        If not supplied here, the DefaultNoStatus configuration property value will be used.

    .OUTPUTS
        GitHub.ProjectCard

    .EXAMPLE
        Set-GitHubProjectCard -Card 999999 -Note UpdatedNote

        Sets the card note to 'UpdatedNote' for the card with ID 999999.

    .EXAMPLE
        Set-GitHubProjectCard -Card 999999 -Archive

        Archives the card with ID 999999.

    .EXAMPLE
        Set-GitHubProjectCard -Card 999999 -Restore

        Restores the card with ID 999999.
#>
    [CmdletBinding(
        SupportsShouldProcess,
        DefaultParameterSetName = 'Note')]
    [OutputType({$script:GitHubProjectCardTypeName})]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSShouldProcess", "", Justification = "Methods called within here make use of PSShouldProcess, and the switch is passed on to them inherently.")]
    param(
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName)]
        [Alias('CardId')]
        [int64] $Card,

        [Alias('Content')]
        [string] $Note,

        [Parameter(ParameterSetName = 'Archive')]
        [switch] $Archive,

        [Parameter(ParameterSetName = 'Restore')]
        [switch] $Restore,

        [string] $AccessToken,

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

    if ($Archive)
    {
        $telemetryProperties['Archive'] = $true
        $hashBody.add('archived', $true)
    }

    if ($Restore)
    {
        $telemetryProperties['Restore'] = $true
        $hashBody.add('archived', $false)
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
        'AcceptHeader' = $script:inertiaAcceptHeader
    }

    return (Invoke-GHRestMethod @params | Add-GitHubProjectCardAdditionalProperties)
}

filter Remove-GitHubProjectCard
{
<#
    .DESCRIPTION
        Removes a project card.

        The Git repo for this module can be found here: http://aka.ms/PowerShellForGitHub

    .PARAMETER Card
        ID of the card to remove.

    .PARAMETER Force
        If this switch is specified, you will not be prompted for confirmation of command execution.

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

        Remove project card with ID 999999.

    .EXAMPLE
        Remove-GitHubProjectCard -Card 999999 -Confirm:$False

        Remove project card with ID 999999 without prompting for confirmation.

    .EXAMPLE
        Remove-GitHubProjectCard -Card 999999 -Force

        Remove project card with ID 999999 without prompting for confirmation.
#>
    [CmdletBinding(
        SupportsShouldProcess,
        ConfirmImpact = 'High')]
    [Alias('Delete-GitHubProjectCard')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSReviewUnusedParameter", "", Justification="One or more parameters (like NoStatus) are only referenced by helper methods which get access to it from the stack via Get-Variable -Scope 1.")]
    param(
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName)]
        [Alias('CardId')]
        [int64] $Card,

        [switch] $Force,

        [string] $AccessToken,

        [switch] $NoStatus
    )

    Write-InvocationLog

    $telemetryProperties = @{}

    $uriFragment = "/projects/columns/cards/$Card"
    $description = "Deleting card $Card"

    if ($Force -and (-not $Confirm))
    {
        $ConfirmPreference = 'None'
    }

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
            'AcceptHeader' = $script:inertiaAcceptHeader
        }

        return Invoke-GHRestMethod @params
    }
}

filter Move-GitHubProjectCard
{
<#
    .DESCRIPTION
        Move a GitHub Project Card.

        The Git repo for this module can be found here: http://aka.ms/PowerShellForGitHub

    .PARAMETER Card
        ID of the card to move.

    .PARAMETER Top
        Moves the card to the top of the column.

    .PARAMETER Bottom
        Moves the card to the bottom of the column.

    .PARAMETER After
        Moves the card to the position after the card ID specified.

    .PARAMETER Column
        The ID of a column in the same project to move the card to.

    .PARAMETER AccessToken
        If provided, this will be used as the AccessToken for authentication with the
        REST Api.  Otherwise, will attempt to use the configured value or will run unauthenticated.

    .PARAMETER NoStatus
        If this switch is specified, long-running commands will run on the main thread
        with no command line status update.  When not specified, those commands run in
        the background, enabling the command prompt to provide status information.
        If not supplied here, the DefaultNoStatus configuration property value will be used.

    .EXAMPLE
        Move-GitHubProjectCard -Card 999999 -Top

        Moves the project card with ID 999999 to the top of the column.

    .EXAMPLE
        Move-GitHubProjectCard -Card 999999 -Bottom

        Moves the project card with ID 999999 to the bottom of the column.

    .EXAMPLE
        Move-GitHubProjectCard -Card 999999 -After 888888

        Moves the project card with ID 999999 to the position after the card ID 888888.
        Within the same column.

    .EXAMPLE
        Move-GitHubProjectCard -Card 999999 -After 888888 -Column 123456

        Moves the project card with ID 999999 to the position after the card ID 888888, in
        the column with ID 123456.
#>
    [CmdletBinding(SupportsShouldProcess)]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSShouldProcess", "", Justification = "Methods called within here make use of PSShouldProcess, and the switch is passed on to them inherently.")]
    param(
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName)]
        [Alias('CardId')]
        [int64] $Card,

        [switch] $Top,

        [switch] $Bottom,

        [int64] $After,

        [Parameter(ValueFromPipelineByPropertyName)]
        [Alias('ColumnId')]
        [int64] $Column,

        [string] $AccessToken,

        [switch] $NoStatus
    )

    Write-InvocationLog

    $telemetryProperties = @{}

    $uriFragment = "/projects/columns/cards/$Card/moves"
    $apiDescription = "Updating card $Card"

    if (-not ($Top -xor $Bottom -xor ($After -gt 0)))
    {
        $message = 'You must use one (and only one) of the parameters Top, Bottom or After.'
        Write-Log -Message $message -level Error
        throw $message
    }
    elseif ($Top)
    {
        $position = 'top'
    }
    elseif ($Bottom)
    {
        $position = 'bottom'
    }
    else
    {
        $position = "after:$After"
    }

    $hashBody = @{
        'position' = $Position
    }

    if ($PSBoundParameters.ContainsKey('Column'))
    {
        $telemetryProperties['Column'] = $true
        $hashBody.add('column_id', $Column)
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
        'AcceptHeader' = $script:inertiaAcceptHeader
    }

    return Invoke-GHRestMethod @params
}


filter Add-GitHubProjectCardAdditionalProperties
{
<#
    .SYNOPSIS
        Adds type name and additional properties to ease pipelining to GitHub Project Card objects.

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
        [string] $TypeName = $script:GitHubProjectCardTypeName
    )

    foreach ($item in $InputObject)
    {
        $item.PSObject.TypeNames.Insert(0, $TypeName)

        if (-not (Get-GitHubConfiguration -Name DisablePipelineSupport))
        {
            Add-Member -InputObject $item -Name 'CardId' -Value $item.id -MemberType NoteProperty -Force

            if ($item.project_url -match '^.*/projects/(\d+)$')
            {
                $projectId = $Matches[1]
                Add-Member -InputObject $item -Name 'ProjectId' -Value $projectId -MemberType NoteProperty -Force
            }

            if ($item.column_url -match '^.*/columns/(\d+)$')
            {
                $columnId = $Matches[1]
                Add-Member -InputObject $item -Name 'ColumnId' -Value $columnId -MemberType NoteProperty -Force
            }

            if ($null -ne $item.content_url)
            {
                $elements = Split-GitHubUri -Uri $item.content_url
                $repositoryUrl = Join-GitHubUri @elements
                Add-Member -InputObject $item -Name 'RepositoryUrl' -Value $repositoryUrl -MemberType NoteProperty -Force

                if ($item.content_url -match '^.*/issues/(\d+)$')
                {
                    $issueNumber = $Matches[1]
                    Add-Member -InputObject $item -Name 'IssueNumber' -Value $issueNumber -MemberType NoteProperty -Force
                }
                elseif ($item.content_url -match '^.*/pull/(\d+)$')
                {
                    $pullRequestNumber = $Matches[1]
                    Add-Member -InputObject $item -Name 'PullRequestNumber' -Value $pullRequestNumber -MemberType NoteProperty -Force
                }
            }

            if ($null -ne $item.creator)
            {
                $null = Add-GitHubUserAdditionalProperties -InputObject $item.creator
            }
        }

        Write-Output $item
    }
}
