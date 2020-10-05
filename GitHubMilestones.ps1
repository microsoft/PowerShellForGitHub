# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

@{
    GitHubMilestoneTypeName = 'GitHub.Milestone'
 }.GetEnumerator() | ForEach-Object {
     Set-Variable -Scope Script -Option ReadOnly -Name $_.Key -Value $_.Value
 }

# For more information refer to:
#  https://github.community/t5/How-to-use-Git-and-GitHub/Milestone-quot-Due-On-quot-field-defaults-to-7-00-when-set-by-v3/m-p/6901
$script:minimumHoursToEnsureDesiredDateInPacificTime = 9

filter Get-GitHubMilestone
{
<#
    .SYNOPSIS
        Get the milestones for a given GitHub repository.

    .DESCRIPTION
        Get the milestones for a given GitHub repository.

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
        The number of a specific milestone to get. If not supplied, will return back all milestones
        for this repository.

    .PARAMETER Sort
        How to sort the results.

    .PARAMETER Direction
        How to list the results. Ignored without the sort parameter.

    .PARAMETER State
        Only milestones with this state are returned.

    .PARAMETER AccessToken
        If provided, this will be used as the AccessToken for authentication with the
        REST Api.  Otherwise, will attempt to use the configured value or will run unauthenticated.

    .INPUTS
        GitHub.Branch
        GitHub.Content
        GitHub.Event
        GitHub.Issue
        GitHub.IssueComment
        GitHub.Label
        GitHub.Milestone
        GitHub.PullRequest
        GitHub.Project
        GitHub.ProjectCard
        GitHub.ProjectColumn
        GitHub.Reaction
        GitHub.Release
        GitHub.ReleaseAsset
        GitHub.Repository

    .OUTPUTS
        GitHub.Milestone

    .EXAMPLE
        Get-GitHubMilestone -OwnerName microsoft -RepositoryName PowerShellForGitHub
        Get the milestones for the microsoft\PowerShellForGitHub project.

    .EXAMPLE
        Get-GitHubMilestone -Uri 'https://github.com/PowerShell/PowerShellForGitHub' -Milestone 1
        Get milestone number 1 for the microsoft\PowerShellForGitHub project.
#>
    [CmdletBinding(DefaultParameterSetName = 'RepositoryElements')]
    param(
        [Parameter(
            Mandatory,
            ParameterSetName='MilestoneElements')]
        [Parameter(
            Mandatory,
            ParameterSetName='RepositoryElements')]
        [string] $OwnerName,

        [Parameter(
            Mandatory,
            ParameterSetName='MilestoneElements')]
        [Parameter(
            Mandatory,
            ParameterSetName='RepositoryElements')]
        [string] $RepositoryName,

        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName='MilestoneUri')]
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName='RepositoryUri')]
        [Alias('RepositoryUrl')]
        [string] $Uri,

        [Parameter(
            Mandatory,
            ValueFromPipeline,
            ValueFromPipelineByPropertyName,
            ParameterSetName='MilestoneUri')]
        [Parameter(
            Mandatory,
            ValueFromPipeline,
            ValueFromPipelineByPropertyName,
            ParameterSetName='MilestoneElements')]
        [Alias('MilestoneNumber')]
        [int64] $Milestone,

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

        [string] $AccessToken
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

            # We only look at this parameter if the user provided Sort as well.
            if ($PSBoundParameters.ContainsKey('Direction'))
            {
                $directionConverter = @{
                    'Ascending' = 'asc'
                    'Descending' = 'desc'
                }

                $getParams += "direction=$($directionConverter[$Direction])"
            }
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
    }

    return (Invoke-GHRestMethodMultipleResult @params | Add-GitHubMilestoneAdditionalProperties)
}

filter New-GitHubMilestone
{
<#
    .SYNOPSIS
        Creates a new GitHub milestone for the given repository.

    .DESCRIPTION
        Creates a new GitHub milestone for the given repository.

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
        GitHub will drop any time provided with this value, therefore please ensure that the
        UTC version of this value has your desired date.

    .PARAMETER AccessToken
        If provided, this will be used as the AccessToken for authentication with the
        REST Api.  Otherwise, will attempt to use the configured value or will run unauthenticated.

    .INPUTS
        GitHub.Branch
        GitHub.Content
        GitHub.Event
        GitHub.Issue
        GitHub.IssueComment
        GitHub.Label
        GitHub.Milestone
        GitHub.PullRequest
        GitHub.Project
        GitHub.ProjectCard
        GitHub.ProjectColumn
        GitHub.Reaction
        GitHub.Release
        GitHub.ReleaseAsset
        GitHub.Repository

    .OUTPUTS
        GitHub.Milestone

    .EXAMPLE
        New-GitHubMilestone -OwnerName microsoft -RepositoryName PowerShellForGitHub -Title "Testing this API"

        Creates a new GitHub milestone for the microsoft\PowerShellForGitHub project.

    .NOTES
        For more information on how GitHub handles the dates specified in DueOn, please refer to
        this support forum post:
        https://github.community/t5/How-to-use-Git-and-GitHub/Milestone-quot-Due-On-quot-field-defaults-to-7-00-when-set-by-v3/m-p/6901

        Please note that due to artifacts of how GitHub was originally designed, all timestamps
        in the GitHub database are normalized to Pacific Time.  This means that any dates specified
        that occur before 7am UTC will be considered timestamps for the _previous_ day.

        Given that GitHub drops the _time_ aspect of this DateTime, this function will ensure that
        the requested DueOn date specified is honored by manipulating the time as needed.
#>
    [CmdletBinding(
        SupportsShouldProcess,
        DefaultParameterSetName='Elements')]
    param(
        [Parameter(
            Mandatory,
            ParameterSetName='Elements')]
        [string] $OwnerName,

        [Parameter(
            Mandatory,
            ParameterSetName='Elements')]
        [string] $RepositoryName,

        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName='Uri')]
        [Alias('RepositoryUrl')]
        [string] $Uri,

        [Parameter(
            Mandatory,
            ValueFromPipeline,
            ParameterSetName='Uri')]
        [Parameter(
            Mandatory,
            ValueFromPipeline,
            ParameterSetName='Elements')]
        [string] $Title,

        [ValidateSet('Open', 'Closed')]
        [string] $State,

        [string] $Description,

        [DateTime] $DueOn,

        [string] $AccessToken
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
        # If you set 'due_on' to be '2020-09-24T06:59:00Z', GitHub considers that to be '2020-09-23T07:00:00Z'
        # And if you set 'due_on' to be '2020-09-24T07:01:00Z', GitHub considers that to be '2020-09-24T07:00:00Z'
        # SO....we can't depend on the typical definition of midnight when trying to specify a specific day.
        # Instead, we'll use 9am on the designated date to ensure we're always dealing with the
        # same date that GitHub uses, regardless of the current state of Daylight Savings Time.
        # (See .NOTES for more info)
        $modifiedDueOn = $DueOn.ToUniversalTime().date.AddHours($script:minimumHoursToEnsureDesiredDateInPacificTime)
        $dueOnFormattedTime = $modifiedDueOn.ToString('o')
        $hashBody.add('due_on', $dueOnFormattedTime)
    }

    if (-not $PSCmdlet.ShouldProcess($Title, 'Create GitHub Milestone'))
    {
        return
    }

    $params = @{
        'UriFragment' = "repos/$OwnerName/$RepositoryName/milestones"
        'Body' = (ConvertTo-Json -InputObject $hashBody)
        'Method' = 'Post'
        'Description' = "Creating milestone for $RepositoryName"
        'AccessToken' = $AccessToken
        'TelemetryEventName' = $MyInvocation.MyCommand.Name
        'TelemetryProperties' = $telemetryProperties
    }

    return (Invoke-GHRestMethod @params | Add-GitHubMilestoneAdditionalProperties)
}

filter Set-GitHubMilestone
{
<#
    .SYNOPSIS
        Update an existing milestone for the given repository.

    .DESCRIPTION
        Update an existing milestone for the given repository.

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
        GitHub will drop any time provided with this value, therefore please ensure that the
        UTC version of this value has your desired date.

    .PARAMETER PassThru
        Returns the updated Milestone.  By default, this cmdlet does not generate any output.
        You can use "Set-GitHubConfiguration -DefaultPassThru" to control the default behavior
        of this switch.

    .PARAMETER AccessToken
        If provided, this will be used as the AccessToken for authentication with the
        REST Api.  Otherwise, will attempt to use the configured value or will run unauthenticated.

    .INPUTS
        GitHub.Branch
        GitHub.Content
        GitHub.Event
        GitHub.Issue
        GitHub.IssueComment
        GitHub.Label
        GitHub.Milestone
        GitHub.PullRequest
        GitHub.Project
        GitHub.ProjectCard
        GitHub.ProjectColumn
        GitHub.Reaction
        GitHub.Release
        GitHub.ReleaseAsset
        GitHub.Repository

    .OUTPUTS
        GitHub.Milestone

    .EXAMPLE
        Set-GitHubMilestone -OwnerName microsoft -RepositoryName PowerShellForGitHub -Milestone 1 -Title "Testing this API"

        Update an existing milestone for the microsoft\PowerShellForGitHub project.

    .NOTES
        For more information on how GitHub handles the dates specified in DueOn, please refer to
        this support forum post:
        https://github.community/t5/How-to-use-Git-and-GitHub/Milestone-quot-Due-On-quot-field-defaults-to-7-00-when-set-by-v3/m-p/6901

        Please note that due to artifacts of how GitHub was originally designed, all timestamps
        in the GitHub database are normalized to Pacific Time.  This means that any dates specified
        that occur before 7am UTC will be considered timestamps for the _previous_ day.

        Given that GitHub drops the _time_ aspect of this DateTime, this function will ensure that
        the requested DueOn date specified is honored by manipulating the time as needed.
#>
    [CmdletBinding(
        SupportsShouldProcess,
        DefaultParameterSetName='Elements')]
    param(
        [Parameter(
            Mandatory,
            ParameterSetName='Elements')]
        [string] $OwnerName,

        [Parameter(
            Mandatory,
            ParameterSetName='Elements')]
        [string] $RepositoryName,

        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName='Uri')]
        [Alias('RepositoryUrl')]
        [string] $Uri,

        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName='Uri')]
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName='Elements')]
        [Alias('MilestoneNumber')]
        [int64] $Milestone,

        [Parameter(
            Mandatory,
            ParameterSetName='Uri')]
        [Parameter(
            Mandatory,
            ParameterSetName='Elements')]
        [string] $Title,

        [ValidateSet('Open', 'Closed')]
        [string] $State,

        [string] $Description,

        [DateTime] $DueOn,

        [switch] $PassThru,

        [string] $AccessToken
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
        # If you set 'due_on' to be '2020-09-24T06:59:00Z', GitHub considers that to be '2020-09-23T07:00:00Z'
        # And if you set 'due_on' to be '2020-09-24T07:01:00Z', GitHub considers that to be '2020-09-24T07:00:00Z'
        # SO....we can't depend on the typical definition of midnight when trying to specify a specific day.
        # Instead, we'll use 9am on the designated date to ensure we're always dealing with the
        # same date that GitHub uses, regardless of the current state of Daylight Savings Time.
        # (See .NOTES for more info)
        $modifiedDueOn = $DueOn.ToUniversalTime().date.AddHours($script:minimumHoursToEnsureDesiredDateInPacificTime)
        $dueOnFormattedTime = $modifiedDueOn.ToString('o')
        $hashBody.add('due_on', $dueOnFormattedTime)
    }

    if (-not $PSCmdlet.ShouldProcess($Milestone, 'Set GitHub Milestone'))
    {
        return
    }

    $params = @{
        'UriFragment' = "repos/$OwnerName/$RepositoryName/milestones/$Milestone"
        'Body' = (ConvertTo-Json -InputObject $hashBody)
        'Method' = 'Patch'
        'Description' = "Setting milestone $Milestone for $RepositoryName"
        'AccessToken' = $AccessToken
        'TelemetryEventName' = $MyInvocation.MyCommand.Name
        'TelemetryProperties' = $telemetryProperties
    }

    $result = (Invoke-GHRestMethod @params | Add-GitHubMilestoneAdditionalProperties)
    if (Resolve-ParameterWithDefaultConfigurationValue -Name PassThru -ConfigValueName DefaultPassThru)
    {
        return $result
    }
}

filter Remove-GitHubMilestone
{
<#
    .SYNOPSIS
        Deletes a GitHub milestone for the given repository.

    .DESCRIPTION
        Deletes a GitHub milestone for the given repository.

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

    .PARAMETER Force
        If this switch is specified, you will not be prompted for confirmation of command execution.

    .PARAMETER AccessToken
        If provided, this will be used as the AccessToken for authentication with the
        REST Api.  Otherwise, will attempt to use the configured value or will run unauthenticated.

    .INPUTS
        GitHub.Branch
        GitHub.Content
        GitHub.Event
        GitHub.Issue
        GitHub.IssueComment
        GitHub.Label
        GitHub.Milestone
        GitHub.PullRequest
        GitHub.Project
        GitHub.ProjectCard
        GitHub.ProjectColumn
        GitHub.Reaction
        GitHub.Release
        GitHub.ReleaseAsset
        GitHub.Repository

    .EXAMPLE
        Remove-GitHubMilestone -OwnerName microsoft -RepositoryName PowerShellForGitHub -Milestone 1

        Deletes a GitHub milestone from the microsoft\PowerShellForGitHub project.

    .EXAMPLE
        Remove-GitHubMilestone -OwnerName microsoft -RepositoryName PowerShellForGitHub -Milestone 1 -Confirm:$false

        Deletes a Github milestone from the microsoft\PowerShellForGitHub project. Will not prompt
        for confirmation, as -Confirm:$false was specified.

    .EXAMPLE
        Remove-GitHubMilestone -OwnerName microsoft -RepositoryName PowerShellForGitHub -Milestone 1 -Force

        Deletes a Github milestone from the microsoft\PowerShellForGitHub project. Will not prompt
        for confirmation, as -Force was specified.
#>
    [CmdletBinding(
        SupportsShouldProcess,
        DefaultParameterSetName='Elements',
        ConfirmImpact="High")]
    [Alias('Delete-GitHubMilestone')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSReviewUnusedParameter", "", Justification="The Uri parameter is only referenced by Resolve-RepositoryElements which get access to it from the stack via Get-Variable -Scope 1.")]
    param(
        [Parameter(
            Mandatory,
            ParameterSetName='Elements')]
        [string] $OwnerName,

        [Parameter(
            Mandatory,
            ParameterSetName='Elements')]
        [string] $RepositoryName,

        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName='Uri')]
        [Alias('RepositoryUrl')]
        [string] $Uri,

        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName='Uri')]
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName='Elements')]
        [Alias('MilestoneNumber')]
        [int64] $Milestone,

        [switch] $Force,

        [string] $AccessToken
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

    if ($Force -and (-not $Confirm))
    {
        $ConfirmPreference = 'None'
    }

    if (-not $PSCmdlet.ShouldProcess($Milestone, 'Remove GitHub Milestone'))
    {
        return
    }

    $params = @{
        'UriFragment' = "repos/$OwnerName/$RepositoryName/milestones/$Milestone"
        'Method' = 'Delete'
        'Description' = "Removing milestone $Milestone for $RepositoryName"
        'AccessToken' = $AccessToken
        'TelemetryEventName' = $MyInvocation.MyCommand.Name
        'TelemetryProperties' = $telemetryProperties
    }

    return Invoke-GHRestMethod @params
}

filter Add-GitHubMilestoneAdditionalProperties
{
<#
    .SYNOPSIS
        Adds type name and additional properties to ease pipelining to GitHub Milestone objects.

    .PARAMETER InputObject
        The GitHub object to add additional properties to.

    .PARAMETER TypeName
        The type that should be assigned to the object.

    .INPUTS
        [PSCustomObject]

    .OUTPUTS
        GitHub.Milestone
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
        [string] $TypeName = $script:GitHubMilestoneTypeName
    )

    foreach ($item in $InputObject)
    {
        $item.PSObject.TypeNames.Insert(0, $TypeName)

        if (-not (Get-GitHubConfiguration -Name DisablePipelineSupport))
        {
            $elements = Split-GitHubUri -Uri $item.html_url
            $repositoryUrl = Join-GitHubUri @elements
            Add-Member -InputObject $item -Name 'RepositoryUrl' -Value $repositoryUrl -MemberType NoteProperty -Force
            Add-Member -InputObject $item -Name 'MilestoneId' -Value $item.id -MemberType NoteProperty -Force
            Add-Member -InputObject $item -Name 'MilestoneNumber' -Value $item.number -MemberType NoteProperty -Force

            if ($null -ne $item.creator)
            {
                $null = Add-GitHubUserAdditionalProperties -InputObject $item.creator
            }
        }

        Write-Output $item
    }
}
