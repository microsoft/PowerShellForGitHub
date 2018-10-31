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
        Get-GitHubIssue -OwnerName PowerShell -RepositoryName PowerShellForGitHub -State open

        Gets all the currently open issues in the PowerShell\PowerShellForGitHub repository.

    .EXAMPLE
        Get-GitHubIssue -OwnerName PowerShell -RepositoryName PowerShellForGitHub -State all -Assignee Octocat

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

        [ValidateSet('all', 'ownedAndMember')]
        [string] $RepositoryType = 'all',

        [string] $Issue,

        [switch] $IgnorePullRequests,

        [ValidateSet('assigned', 'created', 'mentioned', 'subscribed', 'all')]
        [string] $Filter = 'assigned',

        [ValidateSet('open', 'closed', 'all')]
        [string] $State = 'open',

        [string[]] $Label,

        [ValidateSet('created', 'updated', 'comments')]
        [string] $Sort = 'created',

        [ValidateSet('asc', 'desc')]
        [string] $Direction = 'desc',

        [DateTime] $Since,

        [ValidateSet('specific', 'all', 'none')]
        [string] $MilestoneType,

        [string] $Milestone,

        [ValidateSet('specific', 'all', 'none')]
        [string] $AssigneeType,

        [string] $Assignee,

        [string] $Creator,

        [string] $Mentioned,

        [string] $AccessToken,

        [switch] $NoStatus
    )

    Write-InvocationLog -Invocation $MyInvocation

    $elements = Resolve-RepositoryElements -BoundParameters $PSBoundParameters -DisableValidation
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
        if (-not [String]::IsNullOrEmpty($Issue))
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
    elseif ($RepositoryType -eq 'all')
    {
        $uriFragment = "/issues"
        $description = "Getting issues across owned, member and org repositories"
    }
    elseif ($RepositoryType -eq 'ownedAndMember')
    {
        $uriFragment = "/user/issues"
        $description = "Getting issues across owned and member repositories"
    }
    else
    {
        throw "Parameter set not supported."
    }

    $getParams = @(
        "filter=$Filter",
        "state=$State",
        "sort=$Sort",
        "direction=$Direction"
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
        if ($MilestoneType -eq 'all')
        {
            $getParams += 'mentioned=*'
        }
        elseif ($MilestoneType -eq 'none')
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
        'NoStatus' = (Resolve-ParameterWithDefaultConfigurationValue -BoundParameters $PSBoundParameters -Name NoStatus -ConfigValueName DefaultNoStatus)
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
        [ValidateNotNullOrEmpty()]
        [string] $Issue,

        [string] $AccessToken,

        [switch] $NoStatus
    )

    Write-InvocationLog -Invocation $MyInvocation

    $elements = Resolve-RepositoryElements -BoundParameters $PSBoundParameters
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
        'NoStatus' = (Resolve-ParameterWithDefaultConfigurationValue -BoundParameters $PSBoundParameters -Name NoStatus -ConfigValueName DefaultNoStatus)
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

    Write-InvocationLog -Invocation $MyInvocation

    $elements = Resolve-RepositoryElements -BoundParameters $PSBoundParameters
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
    if ($PSBoundParameters.ContainsKey('Label')) { $hashBody['label'] = @($Label) }

    $params = @{
        'UriFragment' = "/repos/$OwnerName/$RepositoryName/issues"
        'Body' = ($hashBody | ConvertTo-Json)
        'Method' = 'Post'
        'Description' =  "Creating new Issue ""$Title"" on $RepositoryName"
        'AcceptHeader' = 'application/vnd.github.symmetra-preview+json'
        'AccessToken' = $AccessToken
        'TelemetryEventName' = $MyInvocation.MyCommand.Name
        'TelemetryProperties' = $telemetryProperties
        'NoStatus' = (Resolve-ParameterWithDefaultConfigurationValue -BoundParameters $PSBoundParameters -Name NoStatus -ConfigValueName DefaultNoStatus)
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
        Update-GitHubIssue -OwnerName PowerShell -RepositoryName PowerShellForGitHub -Issue 4 -Title 'Test Issue' -State closed
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

        [ValidateSet('open', 'closed')]
        [string] $State,

        [string] $AccessToken,

        [switch] $NoStatus
    )

    Write-InvocationLog -Invocation $MyInvocation

    $elements = Resolve-RepositoryElements -BoundParameters $PSBoundParameters
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
    if ($PSBoundParameters.ContainsKey('Label')) { $hashBody['label'] = @($Label) }
    if ($PSBoundParameters.ContainsKey('State')) { $hashBody['state'] = $State }
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
        'Body' = ($hashBody | ConvertTo-Json)
        'Method' = 'Patch'
        'Description' =  "Updating Issue #$Issue on $RepositoryName"
        'AcceptHeader' = 'application/vnd.github.symmetra-preview+json'
        'AccessToken' = $AccessToken
        'TelemetryEventName' = $MyInvocation.MyCommand.Name
        'TelemetryProperties' = $telemetryProperties
        'NoStatus' = (Resolve-ParameterWithDefaultConfigurationValue -BoundParameters $PSBoundParameters -Name NoStatus -ConfigValueName DefaultNoStatus)
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
        Lock-GitHubIssue -OwnerName PowerShell -RepositoryName PowerShellForGitHub -Issue 4 -Title 'Test Issue' -Reason spam
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

        [ValidateSet('off-topic', 'too heated', 'resolved', 'spam')]
        [string] $Reason,

        [string] $AccessToken,

        [switch] $NoStatus
    )

    Write-InvocationLog -Invocation $MyInvocation

    $elements = Resolve-RepositoryElements -BoundParameters $PSBoundParameters
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
        $telemetryProperties['Reason'] = $Reason
        $hashBody['active_lock_reason'] = $Reason
    }

    $params = @{
        'UriFragment' = "/repos/$OwnerName/$RepositoryName/issues/$Issue/lock"
        'Body' = ($hashBody | ConvertTo-Json)
        'Method' = 'Put'
        'Description' =  "Locking Issue #$Issue on $RepositoryName"
        'AcceptHeader' = 'application/vnd.github.sailor-v-preview+json'
        'AccessToken' = $AccessToken
        'TelemetryEventName' = $MyInvocation.MyCommand.Name
        'TelemetryProperties' = $telemetryProperties
        'NoStatus' = (Resolve-ParameterWithDefaultConfigurationValue -BoundParameters $PSBoundParameters -Name NoStatus -ConfigValueName DefaultNoStatus)
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

Write-InvocationLog -Invocation $MyInvocation

$elements = Resolve-RepositoryElements -BoundParameters $PSBoundParameters
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
    'NoStatus' = (Resolve-ParameterWithDefaultConfigurationValue -BoundParameters $PSBoundParameters -Name NoStatus -ConfigValueName DefaultNoStatus)
}

return Invoke-GHRestMethod @params
}
