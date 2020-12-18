# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

@{
    GitHubEventTypeName = 'GitHub.Event'
    GitHubLabelSummaryTypeName = 'GitHub.LabelSummary'
 }.GetEnumerator() | ForEach-Object {
     Set-Variable -Scope Script -Option ReadOnly -Name $_.Key -Value $_.Value
 }

filter Get-GitHubEvent
{
<#
    .SYNOPSIS
        Lists events for an issue, repository, or a single event.

    .DESCRIPTION
        Lists events for an issue, repository, or a single event.

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

    .PARAMETER EventId
        The ID of a specific event to get.
        If not supplied, will return back all events for this repository.

    .PARAMETER Issue
        Issue number to get events for.
        If not supplied, will return back all events for this repository.

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
        Get-GitHubEvent -OwnerName microsoft -RepositoryName PowerShellForGitHub

        Get the events for the microsoft\PowerShellForGitHub project.
#>
    [CmdletBinding(DefaultParameterSetName = 'RepositoryElements')]
    [OutputType({$script:GitHubEventTypeName})]
    param(
        [Parameter(
            Mandatory,
            ParameterSetName='RepositoryElements')]
        [Parameter(
            Mandatory,
            ParameterSetName='IssueElements')]
        [Parameter(
            Mandatory,
            ParameterSetName='EventElements')]
        [string] $OwnerName,

        [Parameter(
            Mandatory,
            ParameterSetName='RepositoryElements')]
        [Parameter(
            Mandatory,
            ParameterSetName='IssueElements')]
        [Parameter(
            Mandatory,
            ParameterSetName='EventElements')]
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
            ParameterSetName='EventUri')]
        [Alias('RepositoryUrl')]
        [string] $Uri,

        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName='EventUri')]
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName='EventElements')]
        [int64] $EventId,

        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName='IssueUri')]
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName='IssueElements')]
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
        'ProvidedIssue' = $PSBoundParameters.ContainsKey('Issue')
        'ProvidedEvent' = $PSBoundParameters.ContainsKey('EventId')
    }

    $uriFragment = "repos/$OwnerName/$RepositoryName/issues/events"
    $description = "Getting events for $RepositoryName"

    if ($PSBoundParameters.ContainsKey('EventId'))
    {
        $uriFragment = "repos/$OwnerName/$RepositoryName/issues/events/$EventId"
        $description = "Getting event $EventId for $RepositoryName"
    }
    elseif ($PSBoundParameters.ContainsKey('Issue'))
    {
        $uriFragment = "repos/$OwnerName/$RepositoryName/issues/$Issue/events"
        $description = "Getting events for issue $Issue in $RepositoryName"
    }

    $acceptHeaders = @(
        $script:starfoxAcceptHeader,
        $script:sailorVAcceptHeader,
        $script:symmetraAcceptHeader,
        $script:machineManAcceptHeader)

    $params = @{
        'UriFragment' = $uriFragment
        'Description' = $description
        'AccessToken' = $AccessToken
        'AcceptHeader' = $acceptHeaders -join ','
        'TelemetryEventName' = $MyInvocation.MyCommand.Name
        'TelemetryProperties' = $telemetryProperties
    }

    return (Invoke-GHRestMethodMultipleResult @params | Add-GitHubEventAdditionalProperties)
}

filter Add-GitHubEventAdditionalProperties
{
<#
    .SYNOPSIS
        Adds type name and additional properties to ease pipelining to GitHub Event objects.

    .PARAMETER InputObject
        The GitHub object to add additional properties to.

    .PARAMETER TypeName
        The type that should be assigned to the object.

    .INPUTS
        [PSCustomObject]

    .OUTPUTS
        GitHub.Event
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
        [string] $TypeName = $script:GitHubEventTypeName
    )

    foreach ($item in $InputObject)
    {
        $item.PSObject.TypeNames.Insert(0, $TypeName)

        if (-not (Get-GitHubConfiguration -Name DisablePipelineSupport))
        {
            $elements = Split-GitHubUri -Uri $item.url
            $repositoryUrl = Join-GitHubUri @elements
            Add-Member -InputObject $item -Name 'RepositoryUrl' -Value $repositoryUrl -MemberType NoteProperty -Force
            Add-Member -InputObject $item -Name 'EventId' -Value $item.id -MemberType NoteProperty -Force

            @('actor', 'assignee', 'assigner', 'assignees', 'committer', 'requested_reviewer', 'review_requester', 'user') |
                ForEach-Object {
                    if ($null -ne $item.$_)
                    {
                        $null = Add-GitHubUserAdditionalProperties -InputObject $item.$_
                    }
                }

            if ($null -ne $item.issue)
            {
                $null = Add-GitHubIssueAdditionalProperties -InputObject $item.issue
                Add-Member -InputObject $item -Name 'IssueId' -Value $item.issue.id -MemberType NoteProperty -Force
                Add-Member -InputObject $item -Name 'IssueNumber' -Value $item.issue.number -MemberType NoteProperty -Force
            }

            if ($null -ne $item.label)
            {
                $null = Add-GitHubLabelAdditionalProperties -InputObject $item.label -TypeName $script:GitHubLabelSummaryTypeName -RepositoryUrl $repositoryUrl
            }

            if ($null -ne $item.labels)
            {
                $null = Add-GitHubLabelAdditionalProperties -InputObject $item.labels -TypeName $script:GitHubLabelSummaryTypeName -RepositoryUrl $repositoryUrl
            }

            if ($null -ne $item.milestone)
            {
                $null = Add-GitHubMilestoneAdditionalProperties -InputObject $item.milestone
            }

            if ($null -ne $item.project_id)
            {
                Add-Member -InputObject $item -Name 'ProjectId' -Value $item.project_id -MemberType NoteProperty -Force
            }

            if ($null -ne $item.project_card)
            {
                $null = Add-GitHubProjectCardAdditionalProperties -InputObject $item.project_card
                Add-Member -InputObject $item -Name 'CardId' -Value $item.project_card.id -MemberType NoteProperty -Force
            }

            if ($null -ne $item.column_name)
            {
                Add-Member -InputObject $item -Name 'ColumnName' -Value $item.column_name -MemberType NoteProperty -Force
            }

            if ($null -ne $item.source)
            {
                $null = Add-GitHubIssueAdditionalProperties -InputObject $item.source
                if ($item.source.PSObject.TypeNames[0] -eq 'GitHub.PullRequest')
                {
                    Add-Member -InputObject $item -Name 'PullRequestId' -Value $item.source.id -MemberType NoteProperty -Force
                    Add-Member -InputObject $item -Name 'PullRequestNumber' -Value $item.source.number -MemberType NoteProperty -Force
                }
                else
                {
                    Add-Member -InputObject $item -Name 'IssueId' -Value $item.source.id -MemberType NoteProperty -Force
                    Add-Member -InputObject $item -Name 'IssueNumber' -Value $item.source.number -MemberType NoteProperty -Force
                }
            }

            if ($item.issue_url -match '^.*/issues/(\d+)$')
            {
                $issueNumber = $Matches[1]
                Add-Member -InputObject $item -Name 'IssueNumber' -Value $issueNumber -MemberType NoteProperty -Force
            }

            if ($item.pull_request_url -match '^.*/pull/(\d+)$')
            {
                $pullRequestNumber = $Matches[1]
                Add-Member -InputObject $item -Name 'PullRequestNumber' -Value $pullRequestNumber -MemberType NoteProperty -Force
            }

            if ($null -ne $item.dismissed_review)
            {
                # TODO: Add dismissed_review (object) and dismissed_review[review_id] once Reviews are supported

                # $null = Add-GitHubPullRequestReviewAdditionalProperties -InputObject $item.dismissed_review
                # Add-Member -InputObject $item -Name 'ReviewId' -Value $item.dismissed_review.review_id -MemberType NoteProperty -Force
            }
        }

        Write-Output $item
    }
}
