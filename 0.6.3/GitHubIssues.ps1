# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

function Get-GitHubIssue
{
<#
    .SYNOPSIS
        Retrieve Issues from GitHub.

    .DESCRIPTION
        Retrieve Issues from GitHub.

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

    .PARAMETER OrganizationName
        The organization whose issues should be retrieved.

    .PARAMETER RepositoryType
        all: Retrieve issues  across owned, member and org repositories
        ownedAndMember: Retrieve issues across owned and member repositories

    .PARAMETER Issue
        The number of specic Issue to retrieve.  If not supplied, will return back all
        Issues for this Repository that match the specified criteria.

    .PARAMETER IgnorePullRequests
        GitHub treats Pull Requests as Issues.  Specify this switch to skip over any
        Issue that is actually a Pull Request.

    .PARAMETER Filter
        Indicates the type of Issues to return:
        assigned: Issues assigned to the authenticated user.
        created: Issues created by the authenticated user.
        mentioned: Issues mentioning the authenticated user.
        subscribed: Issues the authenticated user has been subscribed to updates for.
        all: All issues the authenticated user can see, regardless of participation or creation.

    .PARAMETER State
        Indicates the state of the issues to return.

    .PARAMETER Label
        The label (or labels) that returned Issues should have.

    .PARAMETER Sort
        The property to sort the returned Issues by.

    .PARAMETER Direction
        The direction of the sort.

    .PARAMETER Since
        If specified, returns only issues updated at or after this time.

    .PARAMETER MilestoneType
        If specified, indicates what milestone Issues must be a part of to be returned:
          specific: Only issues with the milestone specified via the Milestone parameter will be returned.
          all: All milestones will be returned.
          none: Only issues without milestones will be returned.

    .PARAMETER Milestone
        Only issues with this milestone will be returned.

    .PARAMETER AssigneeType
        If specified, indicates who Issues must be assigned to in order to be returned:
          specific: Only issues assigned to the user specified by the Assignee parameter will be returned.
          all: Issues assigned to any user will be returned.
          none: Only issues without an assigned user will be returned.

    .PARAMETER Assignee
        Only issues assigned to this user will be returned.

    .PARAMETER Creator
        Only issues created by this specified user will be returned.

    .PARAMETER Mentioned
          Only issues that mention this specified user will be returned.

    .PARAMETER AccessToken
        If provided, this will be used as the AccessToken for authentication with the
        REST Api.  Otherwise, will attempt to use the configured value or will run unauthenticated.

    .PARAMETER NoStatus
        If this switch is specified, long-running commands will run on the main thread
        with no commandline status update.  When not specified, those commands run in
        the background, enabling the command prompt to provide status information.
        If not supplied here, the DefaultNoStatus configuration property value will be used.

    .EXAMPLE
        Get-GitHubIssue -OwnerName PowerShell -RepositoryName PowerShellForGitHub -State Open

        Gets all the currently open issues in the PowerShell\PowerShellForGitHub repository.

    .EXAMPLE
        Get-GitHubIssue -OwnerName PowerShell -RepositoryName PowerShellForGitHub -State All -Assignee Octocat

        Gets every issue in the PowerShell\PowerShellForGitHub repository that is assigned to Octocat.
#>
    [CmdletBinding(
        SupportsShouldProcess,
        DefaultParametersetName='Elements')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSShouldProcess", "", Justification="Methods called within here make use of PSShouldProcess, and the switch is passed on to them inherently.")]
    param(
        [Parameter(ParameterSetName='Elements')]
        [string] $OwnerName,

        [Parameter(ParameterSetName='Elements')]
        [string] $RepositoryName,

        [Parameter(
            Mandatory,
            ParameterSetName='Uri')]
        [string] $Uri,

        [string] $OrganizationName,

        [ValidateSet('All', 'OwnedAndMember')]
        [string] $RepositoryType = 'All',

        [int] $Issue,

        [switch] $IgnorePullRequests,

        [ValidateSet('Assigned', 'Created', 'Mentioned', 'Subscribed', 'All')]
        [string] $Filter = 'Assigned',

        [ValidateSet('Open', 'Closed', 'All')]
        [string] $State = 'Open',

        [string[]] $Label,

        [ValidateSet('Created', 'Updated', 'Comments')]
        [string] $Sort = 'Created',

        [ValidateSet('Ascending', 'Descending')]
        [string] $Direction = 'Descending',

        [DateTime] $Since,

        [ValidateSet('Specific', 'All', 'None')]
        [string] $MilestoneType,

        [string] $Milestone,

        [ValidateSet('Specific', 'All', 'None')]
        [string] $AssigneeType,

        [string] $Assignee,

        [string] $Creator,

        [string] $Mentioned,

        [string] $AccessToken,

        [switch] $NoStatus
    )

    Write-InvocationLog

    $elements = Resolve-RepositoryElements -DisableValidation
    $OwnerName = $elements.ownerName
    $RepositoryName = $elements.repositoryName

    $telemetryProperties = @{
        'OwnerName' = (Get-PiiSafeString -PlainText $OwnerName)
        'RepositoryName' = (Get-PiiSafeString -PlainText $RepositoryName)
        'ProvidedIssue' = $PSBoundParameters.ContainsKey('Issue')
    }

    $uriFragment = [String]::Empty
    $description = [String]::Empty
    if ($OwnerName -xor $RepositoryName)
    {
        $message = 'You must specify BOTH Owner Name and Repository Name when one is provided.'
        Write-Log -Message $message -Level Error
        throw $message
    }

    if (-not [String]::IsNullOrEmpty($RepositoryName))
    {
        $uriFragment = "/repos/$OwnerName/$RepositoryName/issues"
        $description = "Getting issues for $RepositoryName"
        if ($PSBoundParameters.ContainsKey('Issue'))
        {
            $uriFragment = $uriFragment + "/$Issue"
            $description = "Getting issue $Issue for $RepositoryName"
        }
    }
    elseif (-not [String]::IsNullOrEmpty($OrganizationName))
    {
        $uriFragment = "/orgs/$OrganizationName/issues"
        $description = "Getting issues for $OrganizationName"
    }
    elseif ($RepositoryType -eq 'All')
    {
        $uriFragment = "/issues"
        $description = "Getting issues across owned, member and org repositories"
    }
    elseif ($RepositoryType -eq 'OwnedAndMember')
    {
        $uriFragment = "/user/issues"
        $description = "Getting issues across owned and member repositories"
    }
    else
    {
        throw "Parameter set not supported."
    }

    $directionConverter = @{
        'Ascending' = 'asc'
        'Descending' = 'desc'
    }

    $getParams = @(
        "filter=$($Filter.ToLower())",
        "state=$($State.ToLower())",
        "sort=$($Sort.ToLower())",
        "direction=$($directionConverter[$Direction])"
    )

    if ($PSBoundParameters.ContainsKey('Label'))
    {
        $getParams += "labels=$($Label -join ',')"
    }

    if ($PSBoundParameters.ContainsKey('Since'))
    {
        $getParams += "since=$($Since.ToUniversalTime().ToString('o'))"
    }

    if ($PSBoundParameters.ContainsKey('Mentioned'))
    {
        $getParams += "mentioned=$Mentioned"
    }

    if ($PSBoundParameters.ContainsKey('MilestoneType'))
    {
        if ($MilestoneType -eq 'All')
        {
            $getParams += 'mentioned=*'
        }
        elseif ($MilestoneType -eq 'None')
        {
            $getParams += 'mentioned=none'
        }
        elseif ([String]::IsNullOrEmpty($Milestone))
        {
            $message = "MilestoneType was set to [$MilestoneType], but no value for Milestone was provided."
            Write-Log -Message $message -Level Error
            throw $message
        }
    }

    if ($PSBoundParameters.ContainsKey('Milestone'))
    {
        $getParams += "milestone=$Milestone"
    }

    if ($PSBoundParameters.ContainsKey('AssigneeType'))
    {
        if ($AssigneeType -eq 'all')
        {
            $getParams += 'assignee=*'
        }
        elseif ($AssigneeType -eq 'none')
        {
            $getParams += 'assignee=none'
        }
        elseif ([String]::IsNullOrEmpty($Assignee))
        {
            $message = "AssigneeType was set to [$AssigneeType], but no value for Assignee was provided."
            Write-Log -Message $message -Level Error
            throw $message
        }
    }

    if ($PSBoundParameters.ContainsKey('Assignee'))
    {
        $getParams += "assignee=$Assignee"
    }

    if ($PSBoundParameters.ContainsKey('Creator'))
    {
        $getParams += "creator=$Creator"
    }

    if ($PSBoundParameters.ContainsKey('Mentioned'))
    {
        $getParams += "mentioned=$Mentioned"
    }

    $params = @{
        'UriFragment' = $uriFragment + '?' +  ($getParams -join '&')
        'Description' =  $description
        'AcceptHeader' = 'application/vnd.github.symmetra-preview+json'
        'AccessToken' = $AccessToken
        'TelemetryEventName' = $MyInvocation.MyCommand.Name
        'TelemetryProperties' = $telemetryProperties
        'NoStatus' = (Resolve-ParameterWithDefaultConfigurationValue -Name NoStatus -ConfigValueName DefaultNoStatus)
    }

    $result = Invoke-GHRestMethodMultipleResult @params

    if ($IgnorePullRequests)
    {
        return ($result | Where-Object { $null -eq (Get-Member -InputObject $_ -Name pull_request) })
    }
    else
    {
        return $result
    }
}

function Get-GitHubIssueTimeline
{
<#
    .SYNOPSIS
        Retrieves various events that occur around an issue or pull request on GitHub.

    .DESCRIPTION
        Retrieves various events that occur around an issue or pull request on GitHub.

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

    .PARAMETER Issue
        The Issue to get the timeline for.

    .PARAMETER AccessToken
        If provided, this will be used as the AccessToken for authentication with the
        REST Api.  Otherwise, will attempt to use the configured value or will run unauthenticated.

    .PARAMETER NoStatus
        If this switch is specified, long-running commands will run on the main thread
        with no commandline status update.  When not specified, those commands run in
        the background, enabling the command prompt to provide status information.
        If not supplied here, the DefaultNoStatus configuration property value will be used.

    .EXAMPLE
        Get-GitHubIssueTimeline -OwnerName PowerShell -RepositoryName PowerShellForGitHub -Issue 24
#>
    [CmdletBinding(
        SupportsShouldProcess,
        DefaultParametersetName='Elements')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSShouldProcess", "", Justification="Methods called within here make use of PSShouldProcess, and the switch is passed on to them inherently.")]
    param(
        [Parameter(ParameterSetName='Elements')]
        [string] $OwnerName,

        [Parameter(ParameterSetName='Elements')]
        [string] $RepositoryName,

        [Parameter(
            Mandatory,
            ParameterSetName='Uri')]
        [string] $Uri,

        [Parameter(Mandatory)]
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
    }

    $params = @{
        'UriFragment' = "repos/$OwnerName/$RepositoryName/issues/$Issue/timeline"
        'Description' =  "Getting timeline for Issue #$Issue in $RepositoryName"
        'AcceptHeader' = 'application/vnd.github.mockingbird-preview'
        'AccessToken' = $AccessToken
        'TelemetryEventName' = $MyInvocation.MyCommand.Name
        'TelemetryProperties' = $telemetryProperties
        'NoStatus' = (Resolve-ParameterWithDefaultConfigurationValue -Name NoStatus -ConfigValueName DefaultNoStatus)
    }

    return Invoke-GHRestMethodMultipleResult @params
}

function New-GitHubIssue
{
<#
    .SYNOPSIS
        Create a new Issue on GitHub.

    .DESCRIPTION
        Create a new Issue on GitHub.

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
        The title of the issue

    .PARAMETER Body
        The contents of the issue

    .PARAMETER Assignee
        Login(s) for Users to assign to the issue.

    .PARAMETER Milestone
        The number of the mileston to associate this issue with.

    .PARAMETER Label
        Label(s) to associate with this issue.

    .PARAMETER AccessToken
        If provided, this will be used as the AccessToken for authentication with the
        REST Api.  Otherwise, will attempt to use the configured value or will run unauthenticated.

    .PARAMETER NoStatus
        If this switch is specified, long-running commands will run on the main thread
        with no commandline status update.  When not specified, those commands run in
        the background, enabling the command prompt to provide status information.
        If not supplied here, the DefaultNoStatus configuration property value will be used.

    .EXAMPLE
        New-GitHubIssue -OwnerName PowerShell -RepositoryName PowerShellForGitHub -Title 'Test Issue'
#>
    [CmdletBinding(
        SupportsShouldProcess,
        DefaultParametersetName='Elements')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSShouldProcess", "", Justification="Methods called within here make use of PSShouldProcess, and the switch is passed on to them inherently.")]
    param(
        [Parameter(ParameterSetName='Elements')]
        [string] $OwnerName,

        [Parameter(ParameterSetName='Elements')]
        [string] $RepositoryName,

        [Parameter(
            Mandatory,
            ParameterSetName='Uri')]
        [string] $Uri,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string] $Title,

        [string] $Body,

        [string[]] $Assignee,

        [int] $Milestone,

        [string[]] $Label,

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
    }

    $hashBody = @{
        'title' = $Title
    }

    if ($PSBoundParameters.ContainsKey('Body')) { $hashBody['body'] = $Body }
    if ($PSBoundParameters.ContainsKey('Assignee')) { $hashBody['assignees'] = @($Assignee) }
    if ($PSBoundParameters.ContainsKey('Milestone')) { $hashBody['milestone'] = $Milestone }
    if ($PSBoundParameters.ContainsKey('Label')) { $hashBody['labels'] = @($Label) }

    $params = @{
        'UriFragment' = "/repos/$OwnerName/$RepositoryName/issues"
        'Body' = (ConvertTo-Json -InputObject $hashBody)
        'Method' = 'Post'
        'Description' =  "Creating new Issue ""$Title"" on $RepositoryName"
        'AcceptHeader' = 'application/vnd.github.symmetra-preview+json'
        'AccessToken' = $AccessToken
        'TelemetryEventName' = $MyInvocation.MyCommand.Name
        'TelemetryProperties' = $telemetryProperties
        'NoStatus' = (Resolve-ParameterWithDefaultConfigurationValue -Name NoStatus -ConfigValueName DefaultNoStatus)
    }

    return Invoke-GHRestMethod @params
}

function Update-GitHubIssue
{
<#
    .SYNOPSIS
        Create a new Issue on GitHub.

    .DESCRIPTION
        Create a new Issue on GitHub.

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

    .PARAMETER Issue
        The issue to be updated.

    .PARAMETER Title
        The title of the issue

    .PARAMETER Body
        The contents of the issue

    .PARAMETER Assignee
        Login(s) for Users to assign to the issue.
        Provide an empty array to clear all existing assignees.

    .PARAMETER Milestone
        The number of the mileston to associate this issue with.
        Set to 0/$null to remove current.

    .PARAMETER Label
        Label(s) to associate with this issue.
        Provide an empty array to clear all existing labels.

    .PARAMETER State
        Modify the current state of the issue.

    .PARAMETER AccessToken
        If provided, this will be used as the AccessToken for authentication with the
        REST Api.  Otherwise, will attempt to use the configured value or will run unauthenticated.

    .PARAMETER NoStatus
        If this switch is specified, long-running commands will run on the main thread
        with no commandline status update.  When not specified, those commands run in
        the background, enabling the command prompt to provide status information.
        If not supplied here, the DefaultNoStatus configuration property value will be used.

    .EXAMPLE
        Update-GitHubIssue -OwnerName PowerShell -RepositoryName PowerShellForGitHub -Issue 4 -Title 'Test Issue' -State Closed
#>
    [CmdletBinding(
        SupportsShouldProcess,
        DefaultParametersetName='Elements')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSShouldProcess", "", Justification="Methods called within here make use of PSShouldProcess, and the switch is passed on to them inherently.")]
    param(
        [Parameter(ParameterSetName='Elements')]
        [string] $OwnerName,

        [Parameter(ParameterSetName='Elements')]
        [string] $RepositoryName,

        [Parameter(
            Mandatory,
            ParameterSetName='Uri')]
        [string] $Uri,

        [Parameter(Mandatory)]
        [int] $Issue,

        [string] $Title,

        [string] $Body,

        [string[]] $Assignee,

        [int] $Milestone,

        [string[]] $Label,

        [ValidateSet('Open', 'Closed')]
        [string] $State,

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
    }

    $hashBody = @{}

    if ($PSBoundParameters.ContainsKey('Title')) { $hashBody['title'] = $Title }
    if ($PSBoundParameters.ContainsKey('Body')) { $hashBody['body'] = $Body }
    if ($PSBoundParameters.ContainsKey('Assignee')) { $hashBody['assignees'] = @($Assignee) }
    if ($PSBoundParameters.ContainsKey('Label')) { $hashBody['labels'] = @($Label) }
    if ($PSBoundParameters.ContainsKey('State')) { $hashBody['state'] = $State.ToLower() }
    if ($PSBoundParameters.ContainsKey('Milestone'))
    {
        $hashBody['milestone'] = $Milestone
        if ($Milestone -in (0, $null))
        {
            $hashBody['milestone'] = $null
        }
    }

    $params = @{
        'UriFragment' = "/repos/$OwnerName/$RepositoryName/issues/$Issue"
        'Body' = (ConvertTo-Json -InputObject $hashBody)
        'Method' = 'Patch'
        'Description' =  "Updating Issue #$Issue on $RepositoryName"
        'AcceptHeader' = 'application/vnd.github.symmetra-preview+json'
        'AccessToken' = $AccessToken
        'TelemetryEventName' = $MyInvocation.MyCommand.Name
        'TelemetryProperties' = $telemetryProperties
        'NoStatus' = (Resolve-ParameterWithDefaultConfigurationValue -Name NoStatus -ConfigValueName DefaultNoStatus)
    }

    return Invoke-GHRestMethod @params
}

function Lock-GitHubIssue
{
<#
    .SYNOPSIS
        Lock an Issue or Pull Request conversation on GitHub.

    .DESCRIPTION
        Lock an Issue or Pull Request conversation on GitHub.

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

    .PARAMETER Issue
        The issue to be locked.

    .PARAMETER Reason
        The reason for locking the issue or pull request conversation.

    .PARAMETER AccessToken
        If provided, this will be used as the AccessToken for authentication with the
        REST Api.  Otherwise, will attempt to use the configured value or will run unauthenticated.

    .PARAMETER NoStatus
        If this switch is specified, long-running commands will run on the main thread
        with no commandline status update.  When not specified, those commands run in
        the background, enabling the command prompt to provide status information.
        If not supplied here, the DefaultNoStatus configuration property value will be used.

    .EXAMPLE
        Lock-GitHubIssue -OwnerName PowerShell -RepositoryName PowerShellForGitHub -Issue 4 -Title 'Test Issue' -Reason Spam
#>
    [CmdletBinding(
        SupportsShouldProcess,
        DefaultParametersetName='Elements')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSShouldProcess", "", Justification="Methods called within here make use of PSShouldProcess, and the switch is passed on to them inherently.")]
    param(
        [Parameter(ParameterSetName='Elements')]
        [string] $OwnerName,

        [Parameter(ParameterSetName='Elements')]
        [string] $RepositoryName,

        [Parameter(
            Mandatory,
            ParameterSetName='Uri')]
        [string] $Uri,

        [Parameter(Mandatory)]
        [int] $Issue,

        [ValidateSet('OffTopic', 'TooHeated', 'Resolved', 'Spam')]
        [string] $Reason,

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
    }

    $hashBody = @{
        'locked' = $true
    }

    if ($PSBoundParameters.ContainsKey('Reason'))
    {
        $reasonConverter = @{
            'OffTopic' = 'off-topic'
            'TooHeated' = 'too heated'
            'Resolved' = 'resolved'
            'Spam' = 'spam'
        }

        $telemetryProperties['Reason'] = $Reason
        $hashBody['active_lock_reason'] = $reasonConverter[$Reason]
    }

    $params = @{
        'UriFragment' = "/repos/$OwnerName/$RepositoryName/issues/$Issue/lock"
        'Body' = (ConvertTo-Json -InputObject $hashBody)
        'Method' = 'Put'
        'Description' =  "Locking Issue #$Issue on $RepositoryName"
        'AcceptHeader' = 'application/vnd.github.sailor-v-preview+json'
        'AccessToken' = $AccessToken
        'TelemetryEventName' = $MyInvocation.MyCommand.Name
        'TelemetryProperties' = $telemetryProperties
        'NoStatus' = (Resolve-ParameterWithDefaultConfigurationValue -Name NoStatus -ConfigValueName DefaultNoStatus)
    }

    return Invoke-GHRestMethod @params
}

function Unlock-GitHubIssue
{
<#
    .SYNOPSIS
        Unlocks an Issue or Pull Request conversation on GitHub.

    .DESCRIPTION
        Unlocks an Issue or Pull Request conversation on GitHub.

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

    .PARAMETER Issue
        The issue to be unlocked.

    .PARAMETER AccessToken
        If provided, this will be used as the AccessToken for authentication with the
        REST Api.  Otherwise, will attempt to use the configured value or will run unauthenticated.

    .PARAMETER NoStatus
        If this switch is specified, long-running commands will run on the main thread
        with no commandline status update.  When not specified, those commands run in
        the background, enabling the command prompt to provide status information.
        If not supplied here, the DefaultNoStatus configuration property value will be used.

    .EXAMPLE
        Unlock-GitHubIssue -OwnerName PowerShell -RepositoryName PowerShellForGitHub -Issue 4
#>
[CmdletBinding(
    SupportsShouldProcess,
    DefaultParametersetName='Elements')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSShouldProcess", "", Justification="Methods called within here make use of PSShouldProcess, and the switch is passed on to them inherently.")]
param(
    [Parameter(ParameterSetName='Elements')]
    [string] $OwnerName,

    [Parameter(ParameterSetName='Elements')]
    [string] $RepositoryName,

    [Parameter(
        Mandatory,
        ParameterSetName='Uri')]
    [string] $Uri,

    [Parameter(Mandatory)]
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
}

$params = @{
    'UriFragment' = "/repos/$OwnerName/$RepositoryName/issues/$Issue/lock"
    'Method' = 'Delete'
    'Description' =  "Unlocking Issue #$Issue on $RepositoryName"
    'AcceptHeader' = 'application/vnd.github.sailor-v-preview+json'
    'AccessToken' = $AccessToken
    'TelemetryEventName' = $MyInvocation.MyCommand.Name
    'TelemetryProperties' = $telemetryProperties
    'NoStatus' = (Resolve-ParameterWithDefaultConfigurationValue -Name NoStatus -ConfigValueName DefaultNoStatus)
}

return Invoke-GHRestMethod @params
}

# SIG # Begin signature block
# MIIdkgYJKoZIhvcNAQcCoIIdgzCCHX8CAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQU/5KQoiDrBVpndpjDM4uqGcpq
# 0v+gghhuMIIE2jCCA8KgAwIBAgITMwAAAQdjpRkqESfl2QAAAAABBzANBgkqhkiG
# 9w0BAQUFADB3MQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4G
# A1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSEw
# HwYDVQQDExhNaWNyb3NvZnQgVGltZS1TdGFtcCBQQ0EwHhcNMTgwODIzMjAyMDI2
# WhcNMTkxMTIzMjAyMDI2WjCByjELMAkGA1UEBhMCVVMxCzAJBgNVBAgTAldBMRAw
# DgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24x
# LTArBgNVBAsTJE1pY3Jvc29mdCBJcmVsYW5kIE9wZXJhdGlvbnMgTGltaXRlZDEm
# MCQGA1UECxMdVGhhbGVzIFRTUyBFU046QUI0MS00QjI3LUYwMjYxJTAjBgNVBAMT
# HE1pY3Jvc29mdCBUaW1lLVN0YW1wIHNlcnZpY2UwggEiMA0GCSqGSIb3DQEBAQUA
# A4IBDwAwggEKAoIBAQCx4jFPYPLORcJ9TE+rvtOh7IQ4/db/zAzVBmzhKIcvrg0l
# fI61buwA3740F66FFMqxZgMedFov74GNlZ/7y6eIiy1pVdQown+yA+EnB8lEVvKE
# H0J1xReHlQAJr11l/zzjHux30VkA/BBOLfe9uZ+CLAP8F1Wt/aZAkTuxC4rdYSJt
# WGcTyiSyR50fPLtEZqyihPi7g/dJB7R4BCCL/pO7trsI/AA98LSHcOydoGmO852f
# KgtAEV0NbZyVphn+c/5H3qPHcifpB/D47n43wUXkjgrqLlgqdm1Op8fuTNlrHoRV
# 1NBfB8v/zK7RrYP4oVEztN29akvlxUzl062e/oGLAgMBAAGjggEJMIIBBTAdBgNV
# HQ4EFgQUj3Lnp1uB5EjhiEY9QThjCuJYBoowHwYDVR0jBBgwFoAUIzT42VJGcArt
# QPt2+7MrsMM1sw8wVAYDVR0fBE0wSzBJoEegRYZDaHR0cDovL2NybC5taWNyb3Nv
# ZnQuY29tL3BraS9jcmwvcHJvZHVjdHMvTWljcm9zb2Z0VGltZVN0YW1wUENBLmNy
# bDBYBggrBgEFBQcBAQRMMEowSAYIKwYBBQUHMAKGPGh0dHA6Ly93d3cubWljcm9z
# b2Z0LmNvbS9wa2kvY2VydHMvTWljcm9zb2Z0VGltZVN0YW1wUENBLmNydDATBgNV
# HSUEDDAKBggrBgEFBQcDCDANBgkqhkiG9w0BAQUFAAOCAQEAVTCQ9vD8tkOVyPlU
# Na4Y3EfCkpzjliJMKA0uaRy2igxvK4KWoIUTMi4l+fgiVU6ugnn9/meg+COBw2M6
# XmX/+2j57RQgYXcTK5McXlszt3tzvSp2age1sOKPNtfzdxzUgDl1Sh4a8KZf82nJ
# 5mbWe41sVDIHSCSUftMZG+3a8w98HIp7J/upmmpD+K4n/uaYB+UmIWVusJkD9Afv
# IrJAjXWCIYxbIjKnzOMy5JMCoZYGY5npi7u99/Ku/WvsJWtjRC2UxZvMSA5B2YEv
# xvFpKv9qCzbmv/C9fbyhEFO2aLoKpwx97B7PxC50Y9dVtPg6TRWOEeGEopv24YLw
# sBIGlDCCBgMwggProAMCAQICEzMAAAEEaeLbufuKDYMAAAAAAQQwDQYJKoZIhvcN
# AQELBQAwfjELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNV
# BAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEoMCYG
# A1UEAxMfTWljcm9zb2Z0IENvZGUgU2lnbmluZyBQQ0EgMjAxMTAeFw0xODA3MTIy
# MDA4NDlaFw0xOTA3MjYyMDA4NDlaMHQxCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpX
# YXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3NvZnQg
# Q29ycG9yYXRpb24xHjAcBgNVBAMTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjCCASIw
# DQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBAJvFlfKX9v8jamydc1lzOJvTtOOE
# rY24PiXnoLggWkqRcDjYFKi9msD9DWse7OH8/wQ84mFgrlVqYZL71wB9nuppNtb9
# V3kZl/6EkfbHVa2mrgKK7bGRR1bNSodmRacwGxrtrHtrBdIzgnO+xm8czNToGgUV
# AC6Rl7ZLyGFnIovnExJowhcUryZatu5Vc3z1RLMhJwYA67U2+fwmiq0/f0QUw3q7
# I8iL3r4WisEhogIB2X+YkuIxU4+HsZAkmxf6FU3KAWwQbFICopNfYgNBJIxwp3As
# jUsv1zNZXP1d4D/X5IQXu30+edOCQ2JUQMibXs9wFDtgPGk/nzfn+BaSM4sCAwEA
# AaOCAYIwggF+MB8GA1UdJQQYMBYGCisGAQQBgjdMCAEGCCsGAQUFBwMDMB0GA1Ud
# DgQWBBS6F+MlaPS71Xsjpri2fOemgqtXrjBUBgNVHREETTBLpEkwRzEtMCsGA1UE
# CxMkTWljcm9zb2Z0IElyZWxhbmQgT3BlcmF0aW9ucyBMaW1pdGVkMRYwFAYDVQQF
# Ew0yMzAwMTIrNDM3OTY2MB8GA1UdIwQYMBaAFEhuZOVQBdOCqhc3NyK1bajKdQKV
# MFQGA1UdHwRNMEswSaBHoEWGQ2h0dHA6Ly93d3cubWljcm9zb2Z0LmNvbS9wa2lv
# cHMvY3JsL01pY0NvZFNpZ1BDQTIwMTFfMjAxMS0wNy0wOC5jcmwwYQYIKwYBBQUH
# AQEEVTBTMFEGCCsGAQUFBzAChkVodHRwOi8vd3d3Lm1pY3Jvc29mdC5jb20vcGtp
# b3BzL2NlcnRzL01pY0NvZFNpZ1BDQTIwMTFfMjAxMS0wNy0wOC5jcnQwDAYDVR0T
# AQH/BAIwADANBgkqhkiG9w0BAQsFAAOCAgEAKcWCCzmZIAzoJFuJOzhQkoOV25Hy
# O9Kk8NqBW3OOZ0gatsmKB3labM7D/GaYF7K716YWtQNWhXsqfS9ABk6eaddpFBWO
# Y/vMgPXbEZxQ7ksCcUxrBwX+Z1PxGbZubizyj9RFKeE2CLIceIEnloeZQhh3lNzG
# vJ2k21amNtBDSF9ABH5n6YjYAMfrMv/eCndgA3P+nqHHHfPAsy1hh8jxN4Xc/G08
# SxNKEna1UEpN513zTyHkmBKBgf7pXKj8FIzRAp9l+3Z1t2JTx33ax7pC4m57Jkoj
# gjLYjXUeEW+Lf3oG1aofGKVwE+fuaJ0HvAbpiQOWDGriIaslA9i3ARHhxCKWKTF8
# w1VO0BznRcZmAIoVIcTFAXAd4mgBOQ8iIcmoc39w2Cz09WnlSWw5paKpyns51fl3
# bzBzg5bAo4uu5X/dY03aFct7+R3ljsQ6qkr0LUVmn/JeuEkXOePfHUmJYYu6M69e
# Quoa1PVRU/GlXZKbh2e4dqsGVeGu1YOvOf8gMYtc5vq1B8+GJ8dBAiM5bVlOLsB4
# rzpJY2zieOAjdtQrqGcAPGVSWDDSeOl47e27KX2iHzjl7FnHk5lF+QCIykR6R9Ym
# R83UCcK1epAMPRYWfreU20ZSAEoeuT1pyVFlatU/EcQtN5dfksINMQya1ll38FBI
# h4l2k9jzfUqwItgwggYHMIID76ADAgECAgphFmg0AAAAAAAcMA0GCSqGSIb3DQEB
# BQUAMF8xEzARBgoJkiaJk/IsZAEZFgNjb20xGTAXBgoJkiaJk/IsZAEZFgltaWNy
# b3NvZnQxLTArBgNVBAMTJE1pY3Jvc29mdCBSb290IENlcnRpZmljYXRlIEF1dGhv
# cml0eTAeFw0wNzA0MDMxMjUzMDlaFw0yMTA0MDMxMzAzMDlaMHcxCzAJBgNVBAYT
# AlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYD
# VQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xITAfBgNVBAMTGE1pY3Jvc29mdCBU
# aW1lLVN0YW1wIFBDQTCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBAJ+h
# bLHf20iSKnxrLhnhveLjxZlRI1Ctzt0YTiQP7tGn0UytdDAgEesH1VSVFUmUG0KS
# rphcMCbaAGvoe73siQcP9w4EmPCJzB/LMySHnfL0Zxws/HvniB3q506jocEjU8qN
# +kXPCdBer9CwQgSi+aZsk2fXKNxGU7CG0OUoRi4nrIZPVVIM5AMs+2qQkDBuh/NZ
# MJ36ftaXs+ghl3740hPzCLdTbVK0RZCfSABKR2YRJylmqJfk0waBSqL5hKcRRxQJ
# gp+E7VV4/gGaHVAIhQAQMEbtt94jRrvELVSfrx54QTF3zJvfO4OToWECtR0Nsfz3
# m7IBziJLVP/5BcPCIAsCAwEAAaOCAaswggGnMA8GA1UdEwEB/wQFMAMBAf8wHQYD
# VR0OBBYEFCM0+NlSRnAK7UD7dvuzK7DDNbMPMAsGA1UdDwQEAwIBhjAQBgkrBgEE
# AYI3FQEEAwIBADCBmAYDVR0jBIGQMIGNgBQOrIJgQFYnl+UlE/wq4QpTlVnkpKFj
# pGEwXzETMBEGCgmSJomT8ixkARkWA2NvbTEZMBcGCgmSJomT8ixkARkWCW1pY3Jv
# c29mdDEtMCsGA1UEAxMkTWljcm9zb2Z0IFJvb3QgQ2VydGlmaWNhdGUgQXV0aG9y
# aXR5ghB5rRahSqClrUxzWPQHEy5lMFAGA1UdHwRJMEcwRaBDoEGGP2h0dHA6Ly9j
# cmwubWljcm9zb2Z0LmNvbS9wa2kvY3JsL3Byb2R1Y3RzL21pY3Jvc29mdHJvb3Rj
# ZXJ0LmNybDBUBggrBgEFBQcBAQRIMEYwRAYIKwYBBQUHMAKGOGh0dHA6Ly93d3cu
# bWljcm9zb2Z0LmNvbS9wa2kvY2VydHMvTWljcm9zb2Z0Um9vdENlcnQuY3J0MBMG
# A1UdJQQMMAoGCCsGAQUFBwMIMA0GCSqGSIb3DQEBBQUAA4ICAQAQl4rDXANENt3p
# tK132855UU0BsS50cVttDBOrzr57j7gu1BKijG1iuFcCy04gE1CZ3XpA4le7r1ia
# HOEdAYasu3jyi9DsOwHu4r6PCgXIjUji8FMV3U+rkuTnjWrVgMHmlPIGL4UD6ZEq
# JCJw+/b85HiZLg33B+JwvBhOnY5rCnKVuKE5nGctxVEO6mJcPxaYiyA/4gcaMvnM
# MUp2MT0rcgvI6nA9/4UKE9/CCmGO8Ne4F+tOi3/FNSteo7/rvH0LQnvUU3Ih7jDK
# u3hlXFsBFwoUDtLaFJj1PLlmWLMtL+f5hYbMUVbonXCUbKw5TNT2eb+qGHpiKe+i
# myk0BncaYsk9Hm0fgvALxyy7z0Oz5fnsfbXjpKh0NbhOxXEjEiZ2CzxSjHFaRkMU
# vLOzsE1nyJ9C/4B5IYCeFTBm6EISXhrIniIh0EPpK+m79EjMLNTYMoBMJipIJF9a
# 6lbvpt6Znco6b72BJ3QGEe52Ib+bgsEnVLaxaj2JoXZhtG6hE6a/qkfwEm/9ijJs
# sv7fUciMI8lmvZ0dhxJkAj0tr1mPuOQh5bWwymO0eFQF1EEuUKyUsKV4q7OglnUa
# 2ZKHE3UiLzKoCG6gW4wlv6DvhMoh1useT8ma7kng9wFlb4kLfchpyOZu6qeXzjEp
# /w7FW1zYTRuh2Povnj8uVRZryROj/TCCB3owggVioAMCAQICCmEOkNIAAAAAAAMw
# DQYJKoZIhvcNAQELBQAwgYgxCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5n
# dG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9y
# YXRpb24xMjAwBgNVBAMTKU1pY3Jvc29mdCBSb290IENlcnRpZmljYXRlIEF1dGhv
# cml0eSAyMDExMB4XDTExMDcwODIwNTkwOVoXDTI2MDcwODIxMDkwOVowfjELMAkG
# A1UEBhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQx
# HjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEoMCYGA1UEAxMfTWljcm9z
# b2Z0IENvZGUgU2lnbmluZyBQQ0EgMjAxMTCCAiIwDQYJKoZIhvcNAQEBBQADggIP
# ADCCAgoCggIBAKvw+nIQHC6t2G6qghBNNLrytlghn0IbKmvpWlCquAY4GgRJun/D
# DB7dN2vGEtgL8DjCmQawyDnVARQxQtOJDXlkh36UYCRsr55JnOloXtLfm1OyCizD
# r9mpK656Ca/XllnKYBoF6WZ26DJSJhIv56sIUM+zRLdd2MQuA3WraPPLbfM6XKEW
# 9Ea64DhkrG5kNXimoGMPLdNAk/jj3gcN1Vx5pUkp5w2+oBN3vpQ97/vjK1oQH01W
# KKJ6cuASOrdJXtjt7UORg9l7snuGG9k+sYxd6IlPhBryoS9Z5JA7La4zWMW3Pv4y
# 07MDPbGyr5I4ftKdgCz1TlaRITUlwzluZH9TupwPrRkjhMv0ugOGjfdf8NBSv4yU
# h7zAIXQlXxgotswnKDglmDlKNs98sZKuHCOnqWbsYR9q4ShJnV+I4iVd0yFLPlLE
# tVc/JAPw0XpbL9Uj43BdD1FGd7P4AOG8rAKCX9vAFbO9G9RVS+c5oQ/pI0m8GLhE
# fEXkwcNyeuBy5yTfv0aZxe/CHFfbg43sTUkwp6uO3+xbn6/83bBm4sGXgXvt1u1L
# 50kppxMopqd9Z4DmimJ4X7IvhNdXnFy/dygo8e1twyiPLI9AN0/B4YVEicQJTMXU
# pUMvdJX3bvh4IFgsE11glZo+TzOE2rCIF96eTvSWsLxGoGyY0uDWiIwLAgMBAAGj
# ggHtMIIB6TAQBgkrBgEEAYI3FQEEAwIBADAdBgNVHQ4EFgQUSG5k5VAF04KqFzc3
# IrVtqMp1ApUwGQYJKwYBBAGCNxQCBAweCgBTAHUAYgBDAEEwCwYDVR0PBAQDAgGG
# MA8GA1UdEwEB/wQFMAMBAf8wHwYDVR0jBBgwFoAUci06AjGQQ7kUBU7h6qfHMdEj
# iTQwWgYDVR0fBFMwUTBPoE2gS4ZJaHR0cDovL2NybC5taWNyb3NvZnQuY29tL3Br
# aS9jcmwvcHJvZHVjdHMvTWljUm9vQ2VyQXV0MjAxMV8yMDExXzAzXzIyLmNybDBe
# BggrBgEFBQcBAQRSMFAwTgYIKwYBBQUHMAKGQmh0dHA6Ly93d3cubWljcm9zb2Z0
# LmNvbS9wa2kvY2VydHMvTWljUm9vQ2VyQXV0MjAxMV8yMDExXzAzXzIyLmNydDCB
# nwYDVR0gBIGXMIGUMIGRBgkrBgEEAYI3LgMwgYMwPwYIKwYBBQUHAgEWM2h0dHA6
# Ly93d3cubWljcm9zb2Z0LmNvbS9wa2lvcHMvZG9jcy9wcmltYXJ5Y3BzLmh0bTBA
# BggrBgEFBQcCAjA0HjIgHQBMAGUAZwBhAGwAXwBwAG8AbABpAGMAeQBfAHMAdABh
# AHQAZQBtAGUAbgB0AC4gHTANBgkqhkiG9w0BAQsFAAOCAgEAZ/KGpZjgVHkaLtPY
# dGcimwuWEeFjkplCln3SeQyQwWVfLiw++MNy0W2D/r4/6ArKO79HqaPzadtjvyI1
# pZddZYSQfYtGUFXYDJJ80hpLHPM8QotS0LD9a+M+By4pm+Y9G6XUtR13lDni6WTJ
# RD14eiPzE32mkHSDjfTLJgJGKsKKELukqQUMm+1o+mgulaAqPyprWEljHwlpblqY
# luSD9MCP80Yr3vw70L01724lruWvJ+3Q3fMOr5kol5hNDj0L8giJ1h/DMhji8MUt
# zluetEk5CsYKwsatruWy2dsViFFFWDgycScaf7H0J/jeLDogaZiyWYlobm+nt3TD
# QAUGpgEqKD6CPxNNZgvAs0314Y9/HG8VfUWnduVAKmWjw11SYobDHWM2l4bf2vP4
# 8hahmifhzaWX0O5dY0HjWwechz4GdwbRBrF1HxS+YWG18NzGGwS+30HHDiju3mUv
# 7Jf2oVyW2ADWoUa9WfOXpQlLSBCZgB/QACnFsZulP0V3HjXG0qKin3p6IvpIlR+r
# +0cjgPWe+L9rt0uX4ut1eBrs6jeZeRhL/9azI2h15q/6/IvrC4DqaTuv/DDtBEyO
# 3991bWORPdGdVk5Pv4BXIqF4ETIheu9BCrE/+6jMpF3BoYibV3FWTkhFwELJm3Zb
# CoBIa/15n8G9bW1qyVJzEw16UM0xggSOMIIEigIBATCBlTB+MQswCQYDVQQGEwJV
# UzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UE
# ChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSgwJgYDVQQDEx9NaWNyb3NvZnQgQ29k
# ZSBTaWduaW5nIFBDQSAyMDExAhMzAAABBGni27n7ig2DAAAAAAEEMAkGBSsOAwIa
# BQCggaIwGQYJKoZIhvcNAQkDMQwGCisGAQQBgjcCAQQwHAYKKwYBBAGCNwIBCzEO
# MAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFLvZ81T5sChGhS5fFEDpVEtS
# thygMEIGCisGAQQBgjcCAQwxNDAyoBSAEgBNAGkAYwByAG8AcwBvAGYAdKEagBho
# dHRwOi8vd3d3Lm1pY3Jvc29mdC5jb20wDQYJKoZIhvcNAQEBBQAEggEAVr/UudXF
# yIla45Xu6KadPOPMNfpA+5rfVUDM+fs73tM8Fy0n/lMe5vsieFBcoUxL1jVg7vRi
# sQnCABQ1GOgIuGk2ws++RWb8JFEqi6MejI3mkUcF8UCOA3Xi+h/S+ChOlODzm3F8
# LPHv9MoE5YMmQUDhfMLlkMbkfyzUK1uLxGcdtPZ8YULa5sLdUCtI39EIH2SQ8daR
# nO9MDiHrOHkrTvlks2qYQuQ0NB5XxYUPmbyQvmeP+VhQHAvFYHuvF++nd5LtVI6l
# 3ODJTU/S/VQM+zLOJtJDxMYelmFKOYRlhsiqP2cOrPWGqPKPY0XIkAh8auQRbyMR
# GF+UOXBpNntOYaGCAigwggIkBgkqhkiG9w0BCQYxggIVMIICEQIBATCBjjB3MQsw
# CQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9u
# ZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSEwHwYDVQQDExhNaWNy
# b3NvZnQgVGltZS1TdGFtcCBQQ0ECEzMAAAEHY6UZKhEn5dkAAAAAAQcwCQYFKw4D
# AhoFAKBdMBgGCSqGSIb3DQEJAzELBgkqhkiG9w0BBwEwHAYJKoZIhvcNAQkFMQ8X
# DTE5MDEwNzE3Mjk0NVowIwYJKoZIhvcNAQkEMRYEFJEG+qcAunH0tUTlRCz8TwBB
# M6r/MA0GCSqGSIb3DQEBBQUABIIBACs6teOeTrtumIuHUj94rEEojSZkqqF97rhQ
# FFSdfPf0hRjHWhwBR3+dz3dlXPpwdem8vZmRzeoqdEXNqD1qHFv/fLje3qMCVj2N
# aj2BwV1QJk40ADlmbLi6QGQ6kcDpD9k2OeasbTyRrZu9u2uBSSBxPmWKBEt+GgFh
# Y1c1itVOsp7MewBzjMrbZDcNAOYzHrVymMO+xC/Q9Rr7f2CCbhkxIvhlReE4RhoF
# x0j3+bvGiX3ccZQKvLxXv2GLvpLayJ1L3wpN0ber86yu6SFhUDaWMpMlxhPCS4bT
# 5Tg3NZx9PQ//Vyclt1l1Zt6Ea3FmG4SdK6LksDnEJUr6dANd+eY=
# SIG # End signature block
