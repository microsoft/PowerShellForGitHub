# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

@{
    GitHubIssueTypeName = 'GitHub.Issue'
 }.GetEnumerator() | ForEach-Object {
     Set-Variable -Scope Script -Option ReadOnly -Name $_.Key -Value $_.Value
 }

filter Get-GitHubIssue
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
        all: Retrieve issues across owned, member and org repositories
        ownedAndMember: Retrieve issues across owned and member repositories

    .PARAMETER Issue
        The number of specific Issue to retrieve.  If not supplied, will return back all
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

    .PARAMETER MilestoneNumber
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

    .PARAMETER MediaType
        The format in which the API will return the body of the issue.

        Raw  - Return the raw markdown body.
               Response will include body.
               This is the default if you do not pass any specific media type.
        Text - Return a text only representation of the markdown body.
               Response will include body_text.
        Html - Return HTML rendered from the body's markdown.
               Response will include body_html.
        Full - Return raw, text and HTML representations.
               Response will include body, body_text, and body_html.

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
        GitHub.User

    .OUTPUTS
        GitHub.Issue

    .EXAMPLE
        Get-GitHubIssue -OwnerName microsoft -RepositoryName PowerShellForGitHub -State Open

        Gets all the currently open issues in the microsoft\PowerShellForGitHub repository.

    .EXAMPLE
        Get-GitHubIssue -OwnerName microsoft -RepositoryName PowerShellForGitHub -State All -Assignee Octocat

        Gets every issue in the microsoft\PowerShellForGitHub repository that is assigned to Octocat.
#>
    [CmdletBinding(DefaultParameterSetName = 'Elements')]
    [OutputType({$script:GitHubIssueTypeName})]
    param(
        [Parameter(ParameterSetName='Elements')]
        [string] $OwnerName,

        [Parameter(ParameterSetName='Elements')]
        [string] $RepositoryName,

        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName='Uri')]
        [Alias('RepositoryUrl')]
        [string] $Uri,

        [Parameter(ValueFromPipelineByPropertyName)]
        [string] $OrganizationName,

        [ValidateSet('All', 'OwnedAndMember')]
        [string] $RepositoryType = 'All',

        [Parameter(ValueFromPipelineByPropertyName)]
        [Alias('IssueNumber')]
        [int64] $Issue,

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

        [Parameter(ValueFromPipelineByPropertyName)]
        [int64] $MilestoneNumber,

        [ValidateSet('Specific', 'All', 'None')]
        [string] $AssigneeType,

        [string] $Assignee,

        [Parameter(ValueFromPipelineByPropertyName)]
        [Alias('UserName')]
        [string] $Creator,

        [string] $Mentioned,

        [ValidateSet('Raw', 'Text', 'Html', 'Full')]
        [string] $MediaType ='Raw',

        [string] $AccessToken
    )

    Write-InvocationLog

    # Intentionally disabling validation here because parameter sets exist that do not require
    # an OwnerName and RepositoryName.  Therefore, we will do futher parameter validation further
    # into the function.
    $elements = Resolve-RepositoryElements -DisableValidation
    $OwnerName = $elements.ownerName
    $RepositoryName = $elements.repositoryName

    $telemetryProperties = @{
        'OwnerName' = (Get-PiiSafeString -PlainText $OwnerName)
        'RepositoryName' = (Get-PiiSafeString -PlainText $RepositoryName)
        'OrganizationName' = (Get-PiiSafeString -PlainText $OrganizationName)
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
        elseif ($PSBoundParameters.ContainsKey('$MilestoneNumber'))
        {
            $message = "MilestoneType was set to [$MilestoneType], but no value for MilestoneNumber was provided."
            Write-Log -Message $message -Level Error
            throw $message
        }
    }

    if ($PSBoundParameters.ContainsKey('MilestoneNumber'))
    {
        $getParams += "milestone=$MilestoneNumber"
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
        'Description' = $description
        'AcceptHeader' = (Get-MediaAcceptHeader -MediaType $MediaType -AsJson -AcceptHeader $symmetraAcceptHeader)
        'AccessToken' = $AccessToken
        'TelemetryEventName' = $MyInvocation.MyCommand.Name
        'TelemetryProperties' = $telemetryProperties
    }

    try
    {
        $result = (Invoke-GHRestMethodMultipleResult @params | Add-GitHubIssueAdditionalProperties)

        if ($IgnorePullRequests)
        {
            return ($result | Where-Object { $null -eq (Get-Member -InputObject $_ -Name pull_request) })
        }
        else
        {
            return $result
        }

    }
    finally {}
}

filter Get-GitHubIssueTimeline
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
        GitHub.Event

    .EXAMPLE
        Get-GitHubIssueTimeline -OwnerName microsoft -RepositoryName PowerShellForGitHub -Issue 24
#>
    [CmdletBinding(DefaultParameterSetName = 'Elements')]
    [OutputType({$script:GitHubEventTypeName})]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSReviewUnusedParameter", "", Justification="The Uri parameter is only referenced by Resolve-RepositoryElements which get access to it from the stack via Get-Variable -Scope 1.")]
    param(
        [Parameter(ParameterSetName='Elements')]
        [string] $OwnerName,

        [Parameter(ParameterSetName='Elements')]
        [string] $RepositoryName,

        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName='Uri')]
        [Alias('RepositoryUrl')]
        [string] $Uri,

        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName)]
        [Alias('IssueNumber')]
        [int64] $Issue,

        [string] $AccessToken
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
        'Description' = "Getting timeline for Issue #$Issue in $RepositoryName"
        'AcceptHeader' = $script:mockingbirdAcceptHeader
        'AccessToken' = $AccessToken
        'TelemetryEventName' = $MyInvocation.MyCommand.Name
        'TelemetryProperties' = $telemetryProperties
    }

    return (Invoke-GHRestMethodMultipleResult @params | Add-GitHubEventAdditionalProperties)
}

filter New-GitHubIssue
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
        The number of the milestone to associate this issue with.

    .PARAMETER Label
        Label(s) to associate with this issue.

    .PARAMETER MediaType
        The format in which the API will return the body of the issue.

        Raw  - Return the raw markdown body.
               Response will include body.
               This is the default if you do not pass any specific media type.
        Text - Return a text only representation of the markdown body.
               Response will include body_text.
        Html - Return HTML rendered from the body's markdown.
               Response will include body_html.
        Full - Return raw, text and HTML representations.
               Response will include body, body_text, and body_html.

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
        GitHub.Issue

    .EXAMPLE
        New-GitHubIssue -OwnerName microsoft -RepositoryName PowerShellForGitHub -Title 'Test Issue'
#>
    [CmdletBinding(
        SupportsShouldProcess,
        DefaultParameterSetName='Elements')]
    [OutputType({$script:GitHubIssueTypeName})]
    param(
        [Parameter(ParameterSetName='Elements')]
        [string] $OwnerName,

        [Parameter(ParameterSetName='Elements')]
        [string] $RepositoryName,

        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName='Uri')]
        [Alias('RepositoryUrl')]
        [string] $Uri,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string] $Title,

        [string] $Body,

        [string[]] $Assignee,

        [Parameter(ValueFromPipelineByPropertyName)]
        [Alias('MilestoneNumber')]
        [int64] $Milestone,

        [string[]] $Label,

        [ValidateSet('Raw', 'Text', 'Html', 'Full')]
        [string] $MediaType ='Raw',

        [string] $AccessToken
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

    if (-not $PSCmdlet.ShouldProcess($Title, 'Create GitHub Issue'))
    {
        return
    }

    $params = @{
        'UriFragment' = "/repos/$OwnerName/$RepositoryName/issues"
        'Body' = (ConvertTo-Json -InputObject $hashBody)
        'Method' = 'Post'
        'Description' = "Creating new Issue ""$Title"" on $RepositoryName"
        'AcceptHeader' = (Get-MediaAcceptHeader -MediaType $MediaType -AsJson -AcceptHeader $symmetraAcceptHeader)
        'AccessToken' = $AccessToken
        'TelemetryEventName' = $MyInvocation.MyCommand.Name
        'TelemetryProperties' = $telemetryProperties
    }

    return (Invoke-GHRestMethod @params | Add-GitHubIssueAdditionalProperties)
}

filter Set-GitHubIssue
{
<#
    .SYNOPSIS
        Updates an Issue on GitHub.

    .DESCRIPTION
        Updates an Issue on GitHub.

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

    .PARAMETER MilestoneNumber
        The number of the milestone to associate this issue with.
        Set to 0/$null to remove current.

    .PARAMETER Label
        Label(s) to associate with this issue.
        Provide an empty array to clear all existing labels.

    .PARAMETER State
        Modify the current state of the issue.

    .PARAMETER MediaType
        The format in which the API will return the body of the issue.

        Raw  - Return the raw markdown body.
               Response will include body.
               This is the default if you do not pass any specific media type.
        Text - Return a text only representation of the markdown body.
               Response will include body_text.
        Html - Return HTML rendered from the body's markdown.
               Response will include body_html.
        Full - Return raw, text and HTML representations.
               Response will include body, body_text, and body_html.

    .PARAMETER PassThru
        Returns the updated Issue.  By default, this cmdlet does not generate any output.
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
        GitHub.Issue

    .EXAMPLE
        Set-GitHubIssue -OwnerName microsoft -RepositoryName PowerShellForGitHub -Issue 4 -Title 'Test Issue' -State Closed
#>
    [CmdletBinding(
        SupportsShouldProcess,
        DefaultParameterSetName='Elements')]
    [OutputType({$script:GitHubIssueTypeName})]
    [Alias('Update-GitHubIssue')] # Non-standard usage of the Update verb, but done to avoid a breaking change post 0.14.0
    param(
        [Parameter(ParameterSetName='Elements')]
        [string] $OwnerName,

        [Parameter(ParameterSetName='Elements')]
        [string] $RepositoryName,

        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName='Uri')]
        [Alias('RepositoryUrl')]
        [string] $Uri,

        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName)]
        [Alias('IssueNumber')]
        [int64] $Issue,

        [string] $Title,

        [string] $Body,

        [string[]] $Assignee,

        [int64] $MilestoneNumber,

        [string[]] $Label,

        [ValidateSet('Open', 'Closed')]
        [string] $State,

        [ValidateSet('Raw', 'Text', 'Html', 'Full')]
        [string] $MediaType ='Raw',

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
    }

    $hashBody = @{}

    if ($PSBoundParameters.ContainsKey('Title')) { $hashBody['title'] = $Title }
    if ($PSBoundParameters.ContainsKey('Body')) { $hashBody['body'] = $Body }
    if ($PSBoundParameters.ContainsKey('Assignee')) { $hashBody['assignees'] = @($Assignee) }
    if ($PSBoundParameters.ContainsKey('Label')) { $hashBody['labels'] = @($Label) }
    if ($PSBoundParameters.ContainsKey('State')) { $hashBody['state'] = $State.ToLower() }
    if ($PSBoundParameters.ContainsKey('MilestoneNumber'))
    {
        $hashBody['milestone'] = $MilestoneNumber
        if ($MilestoneNumber -in (0, $null))
        {
            $hashBody['milestone'] = $null
        }
    }

    if (-not $PSCmdlet.ShouldProcess($Issue, 'Update GitHub Issue'))
    {
        return
    }

    $params = @{
        'UriFragment' = "/repos/$OwnerName/$RepositoryName/issues/$Issue"
        'Body' = (ConvertTo-Json -InputObject $hashBody)
        'Method' = 'Patch'
        'Description' = "Updating Issue #$Issue on $RepositoryName"
        'AcceptHeader' = (Get-MediaAcceptHeader -MediaType $MediaType -AsJson -AcceptHeader $symmetraAcceptHeader)
        'AccessToken' = $AccessToken
        'TelemetryEventName' = $MyInvocation.MyCommand.Name
        'TelemetryProperties' = $telemetryProperties
    }

    $result = (Invoke-GHRestMethod @params | Add-GitHubIssueAdditionalProperties)
    if (Resolve-ParameterWithDefaultConfigurationValue -Name PassThru -ConfigValueName DefaultPassThru)
    {
        return $result
    }
}

filter Lock-GitHubIssue
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
        Lock-GitHubIssue -OwnerName microsoft -RepositoryName PowerShellForGitHub -Issue 4 -Title 'Test Issue' -Reason Spam
#>
    [CmdletBinding(
        SupportsShouldProcess,
        DefaultParameterSetName='Elements')]
    param(
        [Parameter(ParameterSetName='Elements')]
        [string] $OwnerName,

        [Parameter(ParameterSetName='Elements')]
        [string] $RepositoryName,

        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName='Uri')]
        [Alias('RepositoryUrl')]
        [string] $Uri,

        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName)]
        [Alias('IssueNumber')]
        [int64] $Issue,

        [ValidateSet('OffTopic', 'TooHeated', 'Resolved', 'Spam')]
        [string] $Reason,

        [string] $AccessToken
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
        $hashBody['lock_reason'] = $reasonConverter[$Reason]
    }

    if (-not $PSCmdlet.ShouldProcess($Issue, 'Lock GitHub Issue'))
    {
        return
    }

    $params = @{
        'UriFragment' = "/repos/$OwnerName/$RepositoryName/issues/$Issue/lock"
        'Body' = (ConvertTo-Json -InputObject $hashBody)
        'Method' = 'Put'
        'Description' = "Locking Issue #$Issue on $RepositoryName"
        'AcceptHeader' = $script:sailorVAcceptHeader
        'AccessToken' = $AccessToken
        'TelemetryEventName' = $MyInvocation.MyCommand.Name
        'TelemetryProperties' = $telemetryProperties
    }

    return Invoke-GHRestMethod @params
}

filter Unlock-GitHubIssue
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
        Unlock-GitHubIssue -OwnerName microsoft -RepositoryName PowerShellForGitHub -Issue 4
#>
    [CmdletBinding(
        SupportsShouldProcess,
        DefaultParameterSetName='Elements')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSReviewUnusedParameter", "", Justification="The Uri parameter is only referenced by Resolve-RepositoryElements which get access to it from the stack via Get-Variable -Scope 1.")]
    param(
        [Parameter(ParameterSetName='Elements')]
        [string] $OwnerName,

        [Parameter(ParameterSetName='Elements')]
        [string] $RepositoryName,

        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName='Uri')]
        [Alias('RepositoryUrl')]
        [string] $Uri,

        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName)]
        [Alias('IssueNumber')]
        [int64] $Issue,

        [string] $AccessToken
    )

    Write-InvocationLog

    $elements = Resolve-RepositoryElements
    $OwnerName = $elements.ownerName
    $RepositoryName = $elements.repositoryName

    $telemetryProperties = @{
        'OwnerName' = (Get-PiiSafeString -PlainText $OwnerName)
        'RepositoryName' = (Get-PiiSafeString -PlainText $RepositoryName)
    }

    if (-not $PSCmdlet.ShouldProcess($Issue, 'Unlock GitHub Issue'))
    {
        return
    }

    $params = @{
        'UriFragment' = "/repos/$OwnerName/$RepositoryName/issues/$Issue/lock"
        'Method' = 'Delete'
        'Description' = "Unlocking Issue #$Issue on $RepositoryName"
        'AcceptHeader' = $script:sailorVAcceptHeader
        'AccessToken' = $AccessToken
        'TelemetryEventName' = $MyInvocation.MyCommand.Name
        'TelemetryProperties' = $telemetryProperties
    }

    return Invoke-GHRestMethod @params
}

filter Add-GitHubIssueAdditionalProperties
{
<#
    .SYNOPSIS
        Adds type name and additional properties to ease pipelining to GitHub Issue objects.

    .PARAMETER InputObject
        The GitHub object to add additional properties to.

    .PARAMETER TypeName
        The type that should be assigned to the object.

    .INPUTS
        [PSCustomObject]

    .OUTPUTS
        GitHub.Issue
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
        [string] $TypeName = $script:GitHubIssueTypeName
    )

    foreach ($item in $InputObject)
    {
        # Pull requests are _also_ issues.  A pull request that is retrieved through the
        # Issue endpoint will also have a 'pull_request' property.  Let's make sure that
        # we mark it up appropriately.
        if ($null -ne $item.pull_request)
        {
            $null = Add-GitHubPullRequestAdditionalProperties -InputObject $item
            Write-Output $item
            continue
        }

        $item.PSObject.TypeNames.Insert(0, $TypeName)

        if (-not (Get-GitHubConfiguration -Name DisablePipelineSupport))
        {
            $elements = Split-GitHubUri -Uri $item.html_url
            $repositoryUrl = Join-GitHubUri @elements
            Add-Member -InputObject $item -Name 'RepositoryUrl' -Value $repositoryUrl -MemberType NoteProperty -Force
            Add-Member -InputObject $item -Name 'IssueId' -Value $item.id -MemberType NoteProperty -Force
            Add-Member -InputObject $item -Name 'IssueNumber' -Value $item.number -MemberType NoteProperty -Force

            @('assignee', 'assignees', 'user') |
                ForEach-Object {
                    if ($null -ne $item.$_)
                    {
                        $null = Add-GitHubUserAdditionalProperties -InputObject $item.$_
                    }
                }

            if ($null -ne $item.labels)
            {
                $null = Add-GitHubLabelAdditionalProperties -InputObject $item.labels
            }

            if ($null -ne $item.milestone)
            {
                $null = Add-GitHubMilestoneAdditionalProperties -InputObject $item.milestone
            }

            if ($null -ne $item.closed_by)
            {
                $null = Add-GitHubUserAdditionalProperties -InputObject $item.closed_by
            }

            if ($null -ne $item.repository)
            {
                $null = Add-GitHubRepositoryAdditionalProperties -InputObject $item.repository
            }
        }

        Write-Output $item
    }
}
