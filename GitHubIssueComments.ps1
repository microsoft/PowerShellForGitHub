# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

@{
    GitHubCommentTypeName = 'GitHub.Comment'
    GitHubIssueCommentTypeName = 'GitHub.IssueComment'
 }.GetEnumerator() | ForEach-Object {
     Set-Variable -Scope Script -Option ReadOnly -Name $_.Key -Value $_.Value
 }

filter Get-GitHubIssueComment
{
<#
    .DESCRIPTION
        Get the Issue comments for a given GitHub repository.

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

    .PARAMETER Comment
        The ID of a specific comment to get. If not supplied, will return back all comments for this repository.

    .PARAMETER Issue
        Issue number to get comments for. If not supplied, will return back all comments for this repository.

    .PARAMETER Sort
        How to sort the results.

    .PARAMETER Direction
        How to list the results. Ignored without the sort parameter.

    .PARAMETER Since
        Only comments updated at or after this time are returned.

    .PARAMETER MediaType
        The format in which the API will return the body of the comment.

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

    .PARAMETER NoStatus
        If this switch is specified, long-running commands will run on the main thread
        with no commandline status update.  When not specified, those commands run in
        the background, enabling the command prompt to provide status information.
        If not supplied here, the DefaultNoStatus configuration property value will be used.

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
        GitHub.Repository

    .OUTPUTS
        GitHub.IssueComment

    .EXAMPLE
        Get-GitHubIssueComment -OwnerName microsoft -RepositoryName PowerShellForGitHub

        Get all of the Issue comments for the microsoft\PowerShellForGitHub project.

    .EXAMPLE
        $repo = Get-GitHubRepository -OwnerName microsoft -RepositoryName PowerShellForGitHub
        $repo | Get-GitHubIssueComment -Since ([DateTime]::Now).AddDays(-1)

        Get all of the Issue comments for the microsoft\PowerShellForGitHub project since yesterday.

    .EXAMPLE
        $issue = $repo | Get-GitHubIssueComment -OwnerName microsoft -RepositoryName PowerShellForGitHub -Issue 1

        Get the comments Issue #1 in the microsoft\PowerShellForGitHub project.

    .EXAMPLE
        $repo = Get-GitHubRepository -OwnerName microsoft -RepositoryName PowerShellForGitHub
        $issue = $repo | Get-GitHubIssue -Issue 1
        $issue | Get-GitHubIssueComment

        Get the comments Issue #1 in the microsoft\PowerShellForGitHub project.

    .EXAMPLE
        $repo = Get-GitHubRepository -OwnerName microsoft -RepositoryName PowerShellForGitHub
        $issue = $repo | Get-GitHubIssue -Issue 1
        $comments = $issue | Get-GitHubIssueComment
        $comment[0] | Get-GitHubIssueComment

        Get the most recent comment on Issue #1 in the microsoft\PowerShellForGitHub project by
        passing it in via the pipeline.  This shows some of the different types of objects you
        can pipe into this function.
#>
    [CmdletBinding(
        SupportsShouldProcess,
        DefaultParameterSetName='RepositoryElements')]
    [Alias('Get-GitHubComment')] # Aliased to avoid a breaking change after v0.14.0
    [OutputType({$script:GitHubIssueCommentTypeName})]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSShouldProcess", "", Justification="Methods called within here make use of PSShouldProcess, and the switch is passed on to them inherently.")]
    param(
        [Parameter(
            Mandatory,
            ParameterSetName='RepositoryElements')]
        [Parameter(
            Mandatory,
            ParameterSetName='IssueElements')]
        [Parameter(
            Mandatory,
            ParameterSetName='CommentElements')]
        [string] $OwnerName,

        [Parameter(
            Mandatory,
            ParameterSetName='RepositoryElements')]
        [Parameter(
            Mandatory,
            ParameterSetName='IssueElements')]
        [Parameter(
            Mandatory,
            ParameterSetName='CommentElements')]
        [string] $RepositoryName,

        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName='RepositoryUri')]
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName='IssueUri')]
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName='CommentUri')]
        [Alias('RepositoryUrl')]
        [string] $Uri,

        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName='CommentElements')]
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName='CommentUri')]
        [Alias('CommentId')]
        [string] $Comment,

        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName='IssueElements')]
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName='IssueUri')]
        [Alias('IssueNumber')]
        [int64] $Issue,

        [Parameter(ParameterSetName='RepositoryElements')]
        [Parameter(ParameterSetName='RepositoryUri')]
        [Parameter(ParameterSetName='IssueElements')]
        [Parameter(ParameterSetName='IssueUri')]
        [DateTime] $Since,

        [Parameter(ParameterSetName='RepositoryElements')]
        [Parameter(ParameterSetName='RepositoryUri')]
        [ValidateSet('Created', 'Updated')]
        [string] $Sort,

        [Parameter(ParameterSetName='RepositoryElements')]
        [Parameter(ParameterSetName='RepositoryUri')]
        [ValidateSet('Ascending', 'Descending')]
        [string] $Direction,

        [ValidateSet('Raw', 'Text', 'Html', 'Full')]
        [string] $MediaType ='Raw',

        [string] $AccessToken,

        [switch] $NoStatus
    )

    Write-InvocationLog

    $elements = Resolve-RepositoryElements
    $OwnerName = $elements.ownerName
    $RepositoryName = $elements.repositoryName
    $uriFragment = [String]::Empty
    $description = [String]::Empty

    $sinceFormattedTime = [String]::Empty
    if ($null -ne $Since)
    {
        $sinceFormattedTime = $Since.ToUniversalTime().ToString('o')
    }

    $telemetryProperties = @{
        'OwnerName' = (Get-PiiSafeString -PlainText $OwnerName)
        'RepositoryName' = (Get-PiiSafeString -PlainText $RepositoryName)
        'ProvidedIssue' = $PSBoundParameters.ContainsKey('Issue')
        'ProvidedComment' = $PSBoundParameters.ContainsKey('Comment')
    }

    if ($PSBoundParameters.ContainsKey('Comment'))
    {
        $uriFragment = "repos/$OwnerName/$RepositoryName/issues/comments/$Comment"
        $description = "Getting comment $Comment for $RepositoryName"
    }
    elseif ($PSBoundParameters.ContainsKey('Issue'))
    {
        $uriFragment = "repos/$OwnerName/$RepositoryName/issues/$Issue/comments`?"

        if ($PSBoundParameters.ContainsKey('Since'))
        {
            $uriFragment += "since=$sinceFormattedTime"
        }

        $description = "Getting comments for issue $Issue in $RepositoryName"
    }
    else
    {
        $getParams = @()

        if ($PSBoundParameters.ContainsKey('Sort'))
        {
            $getParams += "sort=$($Sort.ToLower())"
        }

        if ($PSBoundParameters.ContainsKey('Direction'))
        {
            $directionConverter = @{
                'Ascending' = 'asc'
                'Descending' = 'desc'
            }

            $getParams += "direction=$($directionConverter[$Direction])"
        }

        if ($PSBoundParameters.ContainsKey('Since'))
        {
            $getParams += "since=$sinceFormattedTime"
        }

        $uriFragment = "repos/$OwnerName/$RepositoryName/issues/comments`?" +  ($getParams -join '&')
        $description = "Getting comments for $RepositoryName"
    }

    $params = @{
        'UriFragment' = $uriFragment
        'Description' = $description
        'AccessToken' = $AccessToken
        'AcceptHeader' = (Get-MediaAcceptHeader -MediaType $MediaType -AsJson -AcceptHeader $squirrelGirlAcceptHeader)
        'TelemetryEventName' = $MyInvocation.MyCommand.Name
        'TelemetryProperties' = $telemetryProperties
        'NoStatus' = (Resolve-ParameterWithDefaultConfigurationValue -Name NoStatus -ConfigValueName DefaultNoStatus)
    }

    return (Invoke-GHRestMethodMultipleResult @params | Add-GitHubIssueCommentAdditionalProperties)
}

filter New-GitHubIssueComment
{
<#
    .DESCRIPTION
        Creates a new GitHub comment for an issue for the given repository

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
        The number for the issue that the comment will be filed under.

    .PARAMETER Body
        The contents of the comment.

    .PARAMETER MediaType
        The format in which the API will return the body of the comment.

        Raw - Return the raw markdown body. Response will include body. This is the default if you do not pass any specific media type.
        Text - Return a text only representation of the markdown body. Response will include body_text.
        Html - Return HTML rendered from the body's markdown. Response will include body_html.
        Full - Return raw, text and HTML representations. Response will include body, body_text, and body_html.

    .PARAMETER AccessToken
        If provided, this will be used as the AccessToken for authentication with the
        REST Api.  Otherwise, will attempt to use the configured value or will run unauthenticated.

    .PARAMETER NoStatus
        If this switch is specified, long-running commands will run on the main thread
        with no commandline status update.  When not specified, those commands run in
        the background, enabling the command prompt to provide status information.
        If not supplied here, the DefaultNoStatus configuration property value will be used.

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
        GitHub.Repository
        GitHub.User

    .OUTPUTS
        GitHub.IssueComment

    .EXAMPLE
        New-GitHubIssueComment -OwnerName microsoft -RepositoryName PowerShellForGitHub -Issue 1 -Body "Testing this API"

        Creates a new GitHub comment for an issue for the microsoft\PowerShellForGitHub project.
#>
    [CmdletBinding(
        SupportsShouldProcess,
        DefaultParameterSetName='Elements')]
    [Alias('New-GitHubComment')] # Aliased to avoid a breaking change after v0.14.0
    [OutputType({$script:GitHubIssueCommentTypeName})]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSShouldProcess", "", Justification="Methods called within here make use of PSShouldProcess, and the switch is passed on to them inherently.")]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSReviewUnusedParameter", "", Justification="One or more parameters (like NoStatus) are only referenced by helper methods which get access to it from the stack via Get-Variable -Scope 1.")]
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

        [Parameter(Mandatory)]
        [string] $Body,

        [ValidateSet('Raw', 'Text', 'Html', 'Full')]
        [string] $MediaType ='Raw',

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
        'Issue' =  (Get-PiiSafeString -PlainText $Issue)
    }

    $hashBody = @{
        'body' = $Body
    }

    $params = @{
        'UriFragment' = "repos/$OwnerName/$RepositoryName/issues/$Issue/comments"
        'Body' = (ConvertTo-Json -InputObject $hashBody)
        'Method' = 'Post'
        'Description' = "Creating comment under issue $Issue for $RepositoryName"
        'AccessToken' = $AccessToken
        'AcceptHeader' = (Get-MediaAcceptHeader -MediaType $MediaType -AsJson -AcceptHeader $squirrelGirlAcceptHeader)
        'TelemetryEventName' = $MyInvocation.MyCommand.Name
        'TelemetryProperties' = $telemetryProperties
        'NoStatus' = (Resolve-ParameterWithDefaultConfigurationValue -Name NoStatus -ConfigValueName DefaultNoStatus)
    }

    return (Invoke-GHRestMethod @params | Add-GitHubIssueCommentAdditionalProperties)
}

filter Set-GitHubIssueComment
{
<#
    .DESCRIPTION
        Modifies an existing comment in an issue for the given repository

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

    .PARAMETER Comment
        The ID of the comment to edit.

    .PARAMETER Body
        The new contents of the comment.

    .PARAMETER MediaType
        The format in which the API will return the body of the comment.

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

    .PARAMETER NoStatus
        If this switch is specified, long-running commands will run on the main thread
        with no commandline status update.  When not specified, those commands run in
        the background, enabling the command prompt to provide status information.
        If not supplied here, the DefaultNoStatus configuration property value will be used.

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
        GitHub.Repository
        GitHub.User

    .OUTPUTS
        GitHub.IssueComment

    .EXAMPLE
        Set-GitHubIssueComment -OwnerName microsoft -RepositoryName PowerShellForGitHub -Comment 1 -Body "Testing this API"

        Updates an existing comment in an issue for the microsoft\PowerShellForGitHub project.
#>
    [CmdletBinding(
        SupportsShouldProcess,
        DefaultParameterSetName='Elements')]
    [Alias('Set-GitHubComment')] # Aliased to avoid a breaking change after v0.14.0
    [OutputType({$script:GitHubIssueCommentTypeName})]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSShouldProcess", "", Justification="Methods called within here make use of PSShouldProcess, and the switch is passed on to them inherently.")]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSReviewUnusedParameter", "", Justification="One or more parameters (like NoStatus) are only referenced by helper methods which get access to it from the stack via Get-Variable -Scope 1.")]
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
        [Alias('CommentId')]
        [int64] $Comment,

        [Parameter(Mandatory)]
        [string] $Body,

        [ValidateSet('Raw', 'Text', 'Html', 'Full')]
        [string] $MediaType ='Raw',

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
        'Comment' =  (Get-PiiSafeString -PlainText $Comment)
    }

    $hashBody = @{
        'body' = $Body
    }

    $params = @{
        'UriFragment' = "repos/$OwnerName/$RepositoryName/issues/comments/$Comment"
        'Body' = (ConvertTo-Json -InputObject $hashBody)
        'Method' = 'Patch'
        'Description' = "Update comment $Comment for $RepositoryName"
        'AccessToken' = $AccessToken
        'AcceptHeader' = (Get-MediaAcceptHeader -MediaType $MediaType -AsJson -AcceptHeader $squirrelGirlAcceptHeader)
        'TelemetryEventName' = $MyInvocation.MyCommand.Name
        'TelemetryProperties' = $telemetryProperties
        'NoStatus' = (Resolve-ParameterWithDefaultConfigurationValue -Name NoStatus -ConfigValueName DefaultNoStatus)
    }

    return (Invoke-GHRestMethod @params | Add-GitHubIssueCommentAdditionalProperties)
}

filter Remove-GitHubIssueComment
{
<#
    .DESCRIPTION
        Deletes a GitHub comment from an Issue in the given repository

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

    .PARAMETER Comment
        The ID of the comment to delete.

    .PARAMETER Force
        If this switch is specified, you will not be prompted for confirmation of command execution.

    .PARAMETER AccessToken
        If provided, this will be used as the AccessToken for authentication with the
        REST Api.  Otherwise, will attempt to use the configured value or will run unauthenticated.

    .PARAMETER NoStatus
        If this switch is specified, long-running commands will run on the main thread
        with no commandline status update.  When not specified, those commands run in
        the background, enabling the command prompt to provide status information.
        If not supplied here, the DefaultNoStatus configuration property value will be used.

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
        GitHub.Repository

    .EXAMPLE
        Remove-GitHubIssueComment -OwnerName microsoft -RepositoryName PowerShellForGitHub -Comment 1

        Deletes a GitHub comment from an Issue in the microsoft\PowerShellForGitHub project.

    .EXAMPLE
        Remove-GitHubIssueComment -OwnerName microsoft -RepositoryName PowerShellForGitHub -Comment 1 -Confirm:$false

        Deletes a Github comment from an Issue in the microsoft\PowerShellForGitHub project
        without prompting confirmation.

    .EXAMPLE
        Remove-GitHubIssueComment -OwnerName microsoft -RepositoryName PowerShellForGitHub -Comment 1 -Force

        Deletes a GitHub comment from an Issue in the microsoft\PowerShellForGitHub project
        without prompting confirmation.
#>
    [CmdletBinding(
        SupportsShouldProcess,
        DefaultParameterSetName='Elements',
        ConfirmImpact="High")]
    [Alias('Delete-GitHubComment')]
    [Alias('Delete-GitHubIssueComment')]
    [Alias('Remove-GitHubComment')] # Aliased to avoid a breaking change after v0.14.0
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSReviewUnusedParameter", "", Justification="One or more parameters (like NoStatus) are only referenced by helper methods which get access to it from the stack via Get-Variable -Scope 1.")]
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
        [Alias('CommentId')]
        [int64] $Comment,

        [switch] $Force,

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
        'Comment' =  (Get-PiiSafeString -PlainText $Comment)
    }

    if ($Force -and (-not $Confirm))
    {
        $ConfirmPreference = 'None'
    }

    if ($PSCmdlet.ShouldProcess($Comment, "Remove comment"))
    {
        $params = @{
            'UriFragment' = "repos/$OwnerName/$RepositoryName/issues/comments/$Comment"
            'Method' = 'Delete'
            'Description' = "Removing comment $Comment for $RepositoryName"
            'AccessToken' = $AccessToken
            'TelemetryEventName' = $MyInvocation.MyCommand.Name
            'TelemetryProperties' = $telemetryProperties
            'NoStatus' = (Resolve-ParameterWithDefaultConfigurationValue -Name NoStatus -ConfigValueName DefaultNoStatus)
        }

        return Invoke-GHRestMethod @params
    }
}

filter Add-GitHubIssueCommentAdditionalProperties
{
<#
    .SYNOPSIS
        Adds type name and additional properties to ease pipelining to GitHub Issue Comment objects.

    .PARAMETER InputObject
        The GitHub object to add additional properties to.

    .PARAMETER TypeName
        The type that should be assigned to the object.

    .INPUTS
        [PSCustomObject]

    .OUTPUTS
        GitHub.IssueComment
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
        [string] $TypeName = $script:GitHubIssueCommentTypeName
    )

    foreach ($item in $InputObject)
    {
        # Provide a generic comment type too
        $item.PSObject.TypeNames.Insert(0, $script:GitHubCommentTypeName)

        # But we want the specific type on top
        $item.PSObject.TypeNames.Insert(0, $TypeName)

        if (-not (Get-GitHubConfiguration -Name DisablePipelineSupport))
        {
            $elements = Split-GitHubUri -Uri $item.html_url
            $repositoryUrl = Join-GitHubUri @elements
            Add-Member -InputObject $item -Name 'RepositoryUrl' -Value $repositoryUrl -MemberType NoteProperty -Force

            Add-Member -InputObject $item -Name 'CommentId' -Value $item.id -MemberType NoteProperty -Force

            if ($null -ne $item.user)
            {
                $null = Add-GitHubUserAdditionalProperties -InputObject $item.user
            }
        }

        Write-Output $item
    }
}