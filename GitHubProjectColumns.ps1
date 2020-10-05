# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

@{
    GitHubProjectColumnTypeName = 'GitHub.ProjectColumn'
 }.GetEnumerator() | ForEach-Object {
     Set-Variable -Scope Script -Option ReadOnly -Name $_.Key -Value $_.Value
 }

filter Get-GitHubProjectColumn
{
<#
    .SYNOPSIS
        Get the columns for a given GitHub Project.

    .DESCRIPTION
        Get the columns for a given GitHub Project.

        The Git repo for this module can be found here: http://aka.ms/PowerShellForGitHub

    .PARAMETER Project
        ID of the project to retrieve a list of columns for.

    .PARAMETER Column
        ID of the column to retrieve.

    .PARAMETER AccessToken
        If provided, this will be used as the AccessToken for authentication with the
        REST Api.  Otherwise, will attempt to use the configured value or will run unauthenticated.

    .INPUTS
        GitHub.Project
        GitHub.ProjectCard
        GitHub.ProjectColumn

    .OUTPUTS
        GitHub.ProjectColumn

    .EXAMPLE
        Get-GitHubProjectColumn -Project 999999

        Get the columns for project 999999.

    .EXAMPLE
        Get-GitHubProjectColumn -Column 999999

        Get the column with ID 999999.
#>
    [CmdletBinding(DefaultParameterSetName = 'Column')]
    [OutputType({$script:GitHubProjectColumnTypeName})]
    param(
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName = 'Project')]
        [Alias('ProjectId')]
        [int64] $Project,

        [Parameter(
            Mandatory,
            ValueFromPipeline,
            ValueFromPipelineByPropertyName,
            ParameterSetName = 'Column')]
        [Alias('ColumnId')]
        [int64] $Column,

        [string] $AccessToken
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
        'AcceptHeader' = $script:inertiaAcceptHeader
    }

    return (Invoke-GHRestMethodMultipleResult @params | Add-GitHubProjectColumnAdditionalProperties)
}

filter New-GitHubProjectColumn
{
<#
    .SYNOPSIS
        Creates a new column for a GitHub project.

    .DESCRIPTION
        Creates a new column for a GitHub project.

        The Git repo for this module can be found here: http://aka.ms/PowerShellForGitHub

    .PARAMETER Project
        ID of the project to create a column for.

    .PARAMETER Name
        The name of the column to create.

    .PARAMETER AccessToken
        If provided, this will be used as the AccessToken for authentication with the
        REST Api.  Otherwise, will attempt to use the configured value or will run unauthenticated.

    .INPUTS
        [String]
        GitHub.Project
        GitHub.ProjectCard
        GitHub.ProjectColumn

    .OUTPUTS
        GitHub.ProjectColumn

    .EXAMPLE
        New-GitHubProjectColumn -Project 999999 -ColumnName 'Done'

        Creates a column called 'Done' for the project with ID 999999.
#>
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType({$script:GitHubProjectColumnTypeName})]
    param(

        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName)]
        [Alias('ProjectId')]
        [int64] $Project,

        [Parameter(
            Mandatory,
            ValueFromPipeline)]
        [Alias('Name')]
        [string] $ColumnName,

        [string] $AccessToken
    )

    Write-InvocationLog

    $telemetryProperties = @{}
    $telemetryProperties['Project'] = Get-PiiSafeString -PlainText $Project

    $uriFragment = "/projects/$Project/columns"
    $apiDescription = "Creating project column $ColumnName"

    $hashBody = @{
        'name' = $ColumnName
    }

    if (-not $PSCmdlet.ShouldProcess($ColumnName, 'Create GitHub Project Column'))
    {
        return
    }

    $params = @{
        'UriFragment' = $uriFragment
        'Body' = (ConvertTo-Json -InputObject $hashBody)
        'Method' = 'Post'
        'Description' = $apiDescription
        'AccessToken' = $AccessToken
        'TelemetryEventName' = $MyInvocation.MyCommand.Name
        'TelemetryProperties' = $telemetryProperties
        'AcceptHeader' = $script:inertiaAcceptHeader
    }

    return (Invoke-GHRestMethod @params | Add-GitHubProjectColumnAdditionalProperties)
}

filter Set-GitHubProjectColumn
{
<#
    .SYNOPSIS
        Modify a GitHub Project Column.

    .DESCRIPTION
        Modify a GitHub Project Column.

        The Git repo for this module can be found here: http://aka.ms/PowerShellForGitHub

    .PARAMETER Column
        ID of the column to modify.

    .PARAMETER Name
        The name for the column.

    .PARAMETER PassThru
        Returns the updated Project Column.  By default, this cmdlet does not generate any output.
        You can use "Set-GitHubConfiguration -DefaultPassThru" to control the default behavior
        of this switch.

    .PARAMETER AccessToken
        If provided, this will be used as the AccessToken for authentication with the
        REST Api.  Otherwise, will attempt to use the configured value or will run unauthenticated.

    .INPUTS
        GitHub.ProjectCard
        GitHub.ProjectColumn

    .OUTPUTS
        GitHub.ProjectColumn

    .EXAMPLE
        Set-GitHubProjectColumn -Column 999999 -ColumnName NewColumnName

        Set the project column name to 'NewColumnName' with column with ID 999999.
#>
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType({$script:GitHubProjectColumnTypeName})]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSReviewUnusedParameter", "", Justification="PassThru is accessed indirectly via Resolve-ParameterWithDefaultConfigurationValue")]
    param(
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName)]
        [Alias('ColumnId')]
        [int64] $Column,

        [Parameter(Mandatory)]
        [Alias('Name')]
        [string] $ColumnName,

        [switch] $PassThru,

        [string] $AccessToken
    )

    Write-InvocationLog

    $telemetryProperties = @{}

    $uriFragment = "/projects/columns/$Column"
    $apiDescription = "Updating column $Column"

    $hashBody = @{
        'name' = $ColumnName
    }

    if (-not $PSCmdlet.ShouldProcess($ColumnName, 'Set GitHub Project Column'))
    {
        return
    }

    $params = @{
        'UriFragment' = $uriFragment
        'Description' = $apiDescription
        'Body' = (ConvertTo-Json -InputObject $hashBody)
        'AccessToken' = $AccessToken
        'Method' = 'Patch'
        'TelemetryEventName' = $MyInvocation.MyCommand.Name
        'TelemetryProperties' = $telemetryProperties
        'AcceptHeader' = $script:inertiaAcceptHeader
    }

    $result = (Invoke-GHRestMethod @params | Add-GitHubProjectColumnAdditionalProperties)
    if (Resolve-ParameterWithDefaultConfigurationValue -Name PassThru -ConfigValueName DefaultPassThru)
    {
        return $result
    }
}

filter Remove-GitHubProjectColumn
{
<#
    .SYNOPSIS
        Removes the column for a project.

    .DESCRIPTION
        Removes the column for a project.

        The Git repo for this module can be found here: http://aka.ms/PowerShellForGitHub

    .PARAMETER Column
        ID of the column to remove.

    .PARAMETER Force
        If this switch is specified, you will not be prompted for confirmation of command execution.

    .PARAMETER AccessToken
        If provided, this will be used as the AccessToken for authentication with the
        REST Api.  Otherwise, will attempt to use the configured value or will run unauthenticated.

    .INPUTS
        GitHub.ProjectCard
        GitHub.ProjectColumn

    .EXAMPLE
        Remove-GitHubProjectColumn -Column 999999

        Remove project column with ID 999999.

    .EXAMPLE
        Remove-GitHubProjectColumn -Column 999999 -Confirm:$False

        Removes the project column with ID 999999 without prompting for confirmation.

    .EXAMPLE
        Remove-GitHubProjectColumn -Column 999999 -Force

        Removes the project column with ID 999999 without prompting for confirmation.
#>
    [CmdletBinding(
        SupportsShouldProcess,
        ConfirmImpact = 'High')]
    [Alias('Delete-GitHubProjectColumn')]
    param(
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName)]
        [Alias('ColumnId')]
        [int64] $Column,

        [switch] $Force,

        [string] $AccessToken
    )

    Write-InvocationLog

    $telemetryProperties = @{}

    $uriFragment = "/projects/columns/$Column"
    $description = "Deleting column $Column"

    if ($Force -and (-not $Confirm))
    {
        $ConfirmPreference = 'None'
    }

    if (-not $PSCmdlet.ShouldProcess($Column, 'Remove GitHub Project Column'))
    {
        return
    }

    $params = @{
        'UriFragment' = $uriFragment
        'Description' = $description
        'AccessToken' = $AccessToken
        'Method' = 'Delete'
        'TelemetryEventName' = $MyInvocation.MyCommand.Name
        'TelemetryProperties' = $telemetryProperties
        'AcceptHeader' = $script:inertiaAcceptHeader
    }

    return Invoke-GHRestMethod @params
}

filter Move-GitHubProjectColumn
{
<#
    .SYNOPSIS
        Move a GitHub Project Column.

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

    .INPUTS
        GitHub.ProjectCard
        GitHub.ProjectColumn

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
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName)]
        [Alias('ColumnId')]
        [int64] $Column,

        [switch] $First,

        [switch] $Last,

        [int64] $After,

        [string] $AccessToken
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

    if (-not $PSCmdlet.ShouldProcess($Column, 'Move GitHub Project Column'))
    {
        return
    }

    $params = @{
        'UriFragment' = $uriFragment
        'Description' = $apiDescription
        'Body' = (ConvertTo-Json -InputObject $hashBody)
        'AccessToken' = $AccessToken
        'Method' = 'Post'
        'TelemetryEventName' = $MyInvocation.MyCommand.Name
        'TelemetryProperties' = $telemetryProperties
        'AcceptHeader' = $script:inertiaAcceptHeader
    }

    return Invoke-GHRestMethod @params
}

filter Add-GitHubProjectColumnAdditionalProperties
{
<#
    .SYNOPSIS
        Adds type name and additional properties to ease pipelining to GitHub Project Column objects.

    .PARAMETER InputObject
        The GitHub object to add additional properties to.

    .PARAMETER TypeName
        The type that should be assigned to the object.

    .INPUTS
        [PSCustomObject]

    .OUTPUTS
        GitHub.ProjectColumn
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
        [string] $TypeName = $script:GitHubProjectColumnTypeName
    )

    foreach ($item in $InputObject)
    {
        $item.PSObject.TypeNames.Insert(0, $TypeName)

        if (-not (Get-GitHubConfiguration -Name DisablePipelineSupport))
        {
            Add-Member -InputObject $item -Name 'ColumnId' -Value $item.id -MemberType NoteProperty -Force
            Add-Member -InputObject $item -Name 'ColumnName' -Value $item.name -MemberType NoteProperty -Force

            if ($item.project_url -match '^.*/projects/(\d+)$')
            {
                $projectId = $Matches[1]
                Add-Member -InputObject $item -Name 'ProjectId' -Value $projectId -MemberType NoteProperty -Force
            }
        }

        Write-Output $item
    }
}
