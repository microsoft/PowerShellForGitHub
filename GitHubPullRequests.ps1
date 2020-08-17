# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

@{
    GitHubPullRequestTypeName = 'GitHub.PullRequest'
 }.GetEnumerator() | ForEach-Object {
     Set-Variable -Scope Script -Option ReadOnly -Name $_.Key -Value $_.Value
 }

filter Get-GitHubPullRequest
{
<#
    .SYNOPSIS
        Retrieve the pull requests in the specified repository.

    .DESCRIPTION
        Retrieve the pull requests in the specified repository.

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

    .PARAMETER PullRequest
        The specific pull request id to return back.  If not supplied, will return back all
        pull requests for the specified Repository.

    .PARAMETER State
        The state of the pull requests that should be returned back.

    .PARAMETER Head
        Filter pulls by head user and branch name in the format of 'user:ref-name'

    .PARAMETER Base
        Base branch name to filter the pulls by.

    .PARAMETER Sort
        What to sort the results by.
        * created
        * updated
        * popularity (comment count)
        * long-running (age, filtering by pulls updated in the last month)

    .PARAMETER Direction
        The direction to be used for Sort.

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
        GitHub.PulLRequest

    .EXAMPLE
        $pullRequests = Get-GitHubPullRequest -Uri 'https://github.com/PowerShell/PowerShellForGitHub'

    .EXAMPLE
        $pullRequests = Get-GitHubPullRequest -OwnerName microsoft -RepositoryName PowerShellForGitHub -State Closed
#>
    [CmdletBinding(DefaultParameterSetName = 'Elements')]
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
            ValueFromPipeline,
            ValueFromPipelineByPropertyName)]
        [Alias('PullRequestNumber')]
        [int64] $PullRequest,

        [ValidateSet('Open', 'Closed', 'All')]
        [string] $State = 'Open',

        [string] $Head,

        [string] $Base,

        [ValidateSet('Created', 'Updated', 'Popularity', 'LongRunning')]
        [string] $Sort = 'Created',

        [ValidateSet('Ascending', 'Descending')]
        [string] $Direction = 'Descending',

        [string] $AccessToken
    )

    Write-InvocationLog

    $elements = Resolve-RepositoryElements
    $OwnerName = $elements.ownerName
    $RepositoryName = $elements.repositoryName

    $telemetryProperties = @{
        'OwnerName' = (Get-PiiSafeString -PlainText $OwnerName)
        'RepositoryName' = (Get-PiiSafeString -PlainText $RepositoryName)
        'ProvidedPullRequest' = $PSBoundParameters.ContainsKey('PullRequest')
    }

    $uriFragment = "/repos/$OwnerName/$RepositoryName/pulls"
    $description = "Getting pull requests for $RepositoryName"
    if ($PSBoundParameters.ContainsKey('PullRequest'))
    {
        $uriFragment = $uriFragment + "/$PullRequest"
        $description = "Getting pull request $PullRequest for $RepositoryName"
    }

    $sortConverter = @{
        'Created' = 'created'
        'Updated' = 'updated'
        'Popularity' = 'popularity'
        'LongRunning' = 'long-running'
    }

    $directionConverter = @{
        'Ascending' = 'asc'
        'Descending' = 'desc'
    }

    $getParams = @(
        "state=$($State.ToLower())",
        "sort=$($sortConverter[$Sort])",
        "direction=$($directionConverter[$Direction])"
    )

    if ($PSBoundParameters.ContainsKey('Head'))
    {
        $getParams += "head=$Head"
    }

    if ($PSBoundParameters.ContainsKey('Base'))
    {
        $getParams += "base=$Base"
    }

    $params = @{
        'UriFragment' = $uriFragment + '?' +  ($getParams -join '&')
        'Description' = $description
        'AcceptHeader' = $script:symmetraAcceptHeader
        'AccessToken' = $AccessToken
        'TelemetryEventName' = $MyInvocation.MyCommand.Name
        'TelemetryProperties' = $telemetryProperties
    }

    return (Invoke-GHRestMethodMultipleResult @params | Add-GitHubPullRequestAdditionalProperties)
}

filter New-GitHubPullRequest
{
    <#
    .SYNOPSIS
        Create a new pull request in the specified repository.

    .DESCRIPTION
        Opens a new pull request from the given branch into the given branch
        in the specified repository.

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
        The title of the pull request to be created.

    .PARAMETER Body
        The text description of the pull request.

    .PARAMETER Issue
        The GitHub issue number to open the pull request to address.

    .PARAMETER Head
        The name of the head branch (the branch containing the changes to be merged).

        May also include the name of the owner fork, in the form "${fork}:${branch}".

    .PARAMETER Base
        The name of the target branch of the pull request
        (where the changes in the head will be merged to).

    .PARAMETER HeadOwner
        The name of fork that the change is coming from.

        Used as the prefix of $Head parameter in the form "${HeadOwner}:${Head}".

        If unspecified, the unprefixed branch name is used,
        creating a pull request from the $OwnerName fork of the repository.

    .PARAMETER MaintainerCanModify
        If set, allows repository maintainers to commit changes to the
        head branch of this pull request.

    .PARAMETER Draft
        If set, opens the pull request as a draft.

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
        GitHub.PullRequest

    .EXAMPLE
        $prParams = @{
            OwnerName = 'Microsoft'
            Repository = 'PowerShellForGitHub'
            Title = 'Add simple file to root'
            Head = 'octocat:simple-file'
            Base = 'master'
            Body = "Adds a simple text file to the repository root.`n`nThis is an automated PR!"
            MaintainerCanModify = $true
        }
        $pr = New-GitHubPullRequest @prParams

    .EXAMPLE
        New-GitHubPullRequest -Uri 'https://github.com/PowerShell/PSScriptAnalyzer' -Title 'Add test' -Head simple-test -HeadOwner octocat -Base development -Draft -MaintainerCanModify

    .EXAMPLE
        New-GitHubPullRequest -Uri 'https://github.com/PowerShell/PSScriptAnalyzer' -Issue 642 -Head simple-test -HeadOwner octocat -Base development -Draft
    #>

    [CmdletBinding(
        SupportsShouldProcess,
        DefaultParameterSetName='Elements_Title')]
    param(
        [Parameter(ParameterSetName='Elements_Title')]
        [Parameter(ParameterSetName='Elements_Issue')]
        [string] $OwnerName,

        [Parameter(ParameterSetName='Elements_Title')]
        [Parameter(ParameterSetName='Elements_Issue')]
        [string] $RepositoryName,

        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName='Uri_Title')]
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName='Uri_Issue')]
        [Alias('RepositoryUrl')]
        [string] $Uri,

        [Parameter(
            Mandatory,
            ParameterSetName='Elements_Title')]
        [Parameter(
            Mandatory,
            ParameterSetName='Uri_Title')]
        [ValidateNotNullOrEmpty()]
        [string] $Title,

        [Parameter(ParameterSetName='Elements_Title')]
        [Parameter(ParameterSetName='Uri_Title')]
        [string] $Body,

        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName='Elements_Issue')]
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName='Uri_Issue')]
        [Alias('IssueNumber')]
        [int64] $Issue,

        [Parameter(Mandatory)]
        [string] $Head,

        [Parameter(Mandatory)]
        [string] $Base,

        [string] $HeadOwner,

        [switch] $MaintainerCanModify,

        [switch] $Draft,

        [string] $AccessToken
    )

    Write-InvocationLog

    if (-not [string]::IsNullOrWhiteSpace($HeadOwner))
    {
        if ($Head.Contains(':'))
        {
            $message = "`$Head ('$Head') was specified with an owner prefix, but `$HeadOwner ('$HeadOwner') was also specified." +
                " Either specify `$Head in '<owner>:<branch>' format, or set `$Head = '<branch>' and `$HeadOwner = '<owner>'."

            Write-Log -Message $message -Level Error
            throw $message
        }

        # $Head does not contain ':' - add the owner fork prefix
        $Head = "${HeadOwner}:${Head}"
    }

    $elements = Resolve-RepositoryElements
    $OwnerName = $elements.ownerName
    $RepositoryName = $elements.repositoryName

    $telemetryProperties = @{
        'OwnerName' = (Get-PiiSafeString -PlainText $OwnerName)
        'RepositoryName' = (Get-PiiSafeString -PlainText $RepositoryName)
    }

    $uriFragment = "/repos/$OwnerName/$RepositoryName/pulls"

    $postBody = @{
        'head' = $Head
        'base' = $Base
    }

    if ($PSBoundParameters.ContainsKey('Title'))
    {
        $description = "Creating pull request $Title in $RepositoryName"
        $shouldProcessAction = "Create GitHub Pull Request: $Title"
        $postBody['title'] = $Title

        # Body may be whitespace, although this might not be useful
        if ($Body)
        {
            $postBody['body'] = $Body
        }
    }
    else
    {
        $description = "Creating pull request for issue $Issue in $RepositoryName"
        $shouldProcessAction = "Create GitHub Pull Request for Issue $Issue"
        $postBody['issue'] = $Issue
    }

    if ($MaintainerCanModify)
    {
        $postBody['maintainer_can_modify'] = $true
    }

    if ($Draft)
    {
        $postBody['draft'] = $true
        $acceptHeader = 'application/vnd.github.shadow-cat-preview+json'
    }

    if (-not $PSCmdlet.ShouldProcess($RepositoryName, $shouldProcessAction))
    {
        return
    }

    $restParams = @{
        'UriFragment' = $uriFragment
        'Method' = 'Post'
        'Description' = $description
        'Body' = ConvertTo-Json -InputObject $postBody -Compress
        'AccessToken' = $AccessToken
        'TelemetryEventName' = $MyInvocation.MyCommand.Name
        'TelemetryProperties' = $telemetryProperties
    }

    if ($acceptHeader)
    {
        $restParams['AcceptHeader'] = $acceptHeader
    }

    return (Invoke-GHRestMethod @restParams | Add-GitHubPullRequestAdditionalProperties)
}

filter Add-GitHubPullRequestAdditionalProperties
{
<#
    .SYNOPSIS
        Adds type name and additional properties to ease pipelining to GitHub Repository objects.

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
        [string] $TypeName = $script:GitHubPullRequestTypeName
    )

    foreach ($item in $InputObject)
    {
        $item.PSObject.TypeNames.Insert(0, $TypeName)

        if (-not (Get-GitHubConfiguration -Name DisablePipelineSupport))
        {
            $elements = Split-GitHubUri -Uri $item.html_url
            $repositoryUrl = Join-GitHubUri @elements
            Add-Member -InputObject $item -Name 'RepositoryUrl' -Value $repositoryUrl -MemberType NoteProperty -Force
            Add-Member -InputObject $item -Name 'PullRequestId' -Value $item.id -MemberType NoteProperty -Force
            Add-Member -InputObject $item -Name 'PullRequestNumber' -Value $item.number -MemberType NoteProperty -Force

            @('assignee', 'assignees', 'requested_reviewers', 'merged_by', 'user') |
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

            if ($null -ne $item.requested_teams)
            {
                $null = Add-GitHubTeamAdditionalProperties -InputObject $item.requested_teams
            }

            # TODO: What type are item.head and item.base?
        }

        Write-Output $item
    }
}
