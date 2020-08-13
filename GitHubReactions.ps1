# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

@{
    GitHubReactionTypeName = 'GitHub.Reaction'
 }.GetEnumerator() | ForEach-Object {
     Set-Variable -Scope Script -Option ReadOnly -Name $_.Key -Value $_.Value
 }

filter Get-GitHubReaction
{
<#
    .SYNOPSIS
        Retrieve reactions of a given GitHub Issue or Pull Request.

    .DESCRIPTION
        Retrieve reactions of a given GitHub Issue or Pull Request.

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
        The issue number.

    .PARAMETER PullRequest
        The pull request number.

    .PARAMETER ReactionType
        The type of reaction you want to retrieve. This is also called the 'content' in
        the GitHub API. Valid options are based off:
        https://developer.github.com/v3/reactions/#reaction-types

    .PARAMETER AccessToken
        If provided, this will be used as the AccessToken for authentication with the
        REST Api. Otherwise, will attempt to use the configured value or will run
        unauthenticated.

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
        GitHub.Reaction

    .EXAMPLE
        Get-GitHubReaction -OwnerName Microsoft -RepositoryName PowerShellForGitHub -Issue 157

        Gets the reactions for issue 157 from the Microsoft\PowerShellForGitHub
        project.

    .EXAMPLE
        Get-GitHubReaction -OwnerName Microsoft -RepositoryName PowerShellForGitHub -Issue 157 -ReactionType eyes

        Gets the 'eyes' reactions for issue 157 from the Microsoft\PowerShellForGitHub
        project.

    .EXAMPLE
        Get-GitHubIssue -OwnerName Microsoft -RepositoryName PowerShellForGitHub -Issue 157 | Get-GitHubReaction

        Gets a GitHub issue and pipe it into Get-GitHubReaction to get all
        the reactions for that issue.

    .EXAMPLE
        Get-GitHubPullRequest -Uri https://github.com/microsoft/PowerShellForGitHub -PullRequest 193 | Get-GitHubReaction

        Gets a GitHub pull request and pipes it into Get-GitHubReaction
        to get all the reactions for that pull request.

    .NOTES
        Currently, issue comments, pull request comments and commit comments are not supported.
#>
    [CmdletBinding(DefaultParameterSetName='ElementsIssue')]
    param(
        [Parameter(
            Mandatory,
            ParameterSetName='ElementsIssue')]
        [Parameter(
            Mandatory,
            ParameterSetName='ElementsPullRequest')]
        [string] $OwnerName,

        [Parameter(
            Mandatory,
            ParameterSetName='ElementsIssue')]
        [Parameter(
            Mandatory,
            ParameterSetName='ElementsPullRequest')]
        [string] $RepositoryName,

        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName='UriIssue')]
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName='UriPullRequest')]
        [Alias('RepositoryUrl')]
        [string] $Uri,

        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName='ElementsIssue')]
        [Parameter(
            Mandatory,
            ParameterSetName='UriIssue',
            ValueFromPipelineByPropertyName)]
        [Alias('IssueNumber')]
        [int64] $Issue,

        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName='ElementsPullRequest')]
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName='UriPullRequest')]
        [Alias('PullRequestNumber')]
        [int64] $PullRequest,

        [ValidateSet('+1', '-1', 'Laugh', 'Confused', 'Heart', 'Hooray', 'Rocket', 'Eyes')]
        [string] $ReactionType,

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

    $splatForAddedProperties = @{
        OwnerName = $OwnerName
        Repository = $RepositoryName
    }

    if ($Issue)
    {
        $splatForAddedProperties.Issue = $Issue
        $targetObjectNumber = $Issue
        $targetObjectTypeName = 'Issue'
        $uriFragment = "/repos/$OwnerName/$RepositoryName/issues/$targetObjectNumber/reactions"
    }
    else
    {
        # Pull Request
        $splatForAddedProperties.PullRequest = $PullRequest
        $targetObjectNumber = $PullRequest
        $targetObjectTypeName = 'Pull Request'
        $uriFragment = "/repos/$OwnerName/$RepositoryName/issues/$targetObjectNumber/reactions"
    }

    if ($PSBoundParameters.ContainsKey('ReactionType'))
    {
        $uriFragment += "?content=" + [Uri]::EscapeDataString($ReactionType.ToLower())
    }

    $description = "Getting reactions for $targetObjectTypeName $targetObjectNumber in $RepositoryName"

    $params = @{
        'UriFragment' = $uriFragment
        'Description' =  $description
        'AcceptHeader' = $script:squirrelGirlAcceptHeader
        'AccessToken' = $AccessToken
        'TelemetryEventName' = $MyInvocation.MyCommand.Name
        'TelemetryProperties' = $telemetryProperties
    }

    $result = Invoke-GHRestMethodMultipleResult @params
    return ($result | Add-GitHubReactionAdditionalProperties @splatForAddedProperties)
}

filter Set-GitHubReaction
{
<#
    .SYNOPSIS
        Sets a reaction of a given GitHub Issue or Pull Request.

    .DESCRIPTION
        Sets a reaction of a given GitHub Issue or Pull Request.

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
        The issue number.

    .PARAMETER PullRequest
        The pull request number.

    .PARAMETER ReactionType
        The type of reaction you want to set. This is aslo called the 'content' in the GitHub API.
        Valid options are based off: https://developer.github.com/v3/reactions/#reaction-types

    .PARAMETER PassThru
        Returns the updated Reaction.  By default, this cmdlet does not generate any output.
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
        GitHub.Repository

    .OUTPUTS
        GitHub.Reaction

    .EXAMPLE
        Set-GitHubReaction -OwnerName PowerShell -RepositoryName PowerShell -Issue 12626 -ReactionType rocket

        Sets the 'rocket' reaction for issue 12626 of the PowerShell\PowerShell project.

    .EXAMPLE
        Get-GitHubPullRequest -Uri https://github.com/microsoft/PowerShellForGitHub -PullRequest 193 | Set-GitHubReaction -ReactionType Heart

        Gets a GitHub pull request and pipes it into Set-GitHubReaction to set the
        'heart' reaction for that pull request.

    .NOTES
        Currently, issue comments, pull request comments and commit comments are not supported.
#>
    [CmdletBinding(
        SupportsShouldProcess,
        DefaultParameterSetName='ElementsIssue')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSReviewUnusedParameter", "", Justification="The Uri parameter is only referenced by Resolve-RepositoryElements which get access to it from the stack via Get-Variable -Scope 1.")]
    param(
        [Parameter(
            Mandatory,
            ParameterSetName='ElementsIssue')]
        [Parameter(
            Mandatory,
            ParameterSetName='ElementsPullRequest')]
        [string] $OwnerName,

        [Parameter(
            Mandatory,
            ParameterSetName='ElementsIssue')]
        [Parameter(
            Mandatory,
            ParameterSetName='ElementsPullRequest')]
        [string] $RepositoryName,

        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName='UriIssue')]
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName='UriPullRequest')]
        [Alias('RepositoryUrl')]
        [string] $Uri,

        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName='ElementsIssue')]
        [Parameter(
            Mandatory,
            ParameterSetName='UriIssue',
            ValueFromPipelineByPropertyName)]
        [Alias('IssueNumber')]
        [int64] $Issue,

        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName='ElementsPullRequest')]
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName='UriPullRequest')]
        [Alias('PullRequestNumber')]
        [int64] $PullRequest,

        [ValidateSet('+1', '-1', 'Laugh', 'Confused', 'Heart', 'Hooray', 'Rocket', 'Eyes')]
        [Parameter(Mandatory)]
        [string] $ReactionType,

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

    $splatForAddedProperties = @{
        OwnerName = $OwnerName
        Repository = $RepositoryName
    }

    if ($Issue)
    {
        $splatForAddedProperties.Issue = $Issue
        $targetObjectNumber = $Issue
        $targetObjectTypeName = 'Issue'
        $uriFragment = "/repos/$OwnerName/$RepositoryName/issues/$targetObjectNumber/reactions"
    }
    else
    {
        # Pull request
        $splatForAddedProperties.PullRequest = $PullRequest
        $targetObjectNumber = $PullRequest
        $targetObjectTypeName = 'Pull Request'
        $uriFragment = "/repos/$OwnerName/$RepositoryName/issues/$targetObjectNumber/reactions"
    }

    $description = "Setting reaction $ReactionType for $targetObjectTypeName $targetObjectNumber in $RepositoryName"

    if (-not $PSCmdlet.ShouldProcess(
        $ReactionId,
        "Setting reaction for $targetObjectTypeName $targetObjectNumber in $RepositoryName"))
    {
        return
    }

    $params = @{
        'UriFragment' = $uriFragment
        'Description' =  $description
        'Method' = 'Post'
        'Body' = ConvertTo-Json -InputObject @{ content = $ReactionType.ToLower() }
        'AcceptHeader' = $script:squirrelGirlAcceptHeader
        'AccessToken' = $AccessToken
        'TelemetryEventName' = $MyInvocation.MyCommand.Name
        'TelemetryProperties' = $telemetryProperties
    }

    $result = (Invoke-GHRestMethod @params |
        Add-GitHubReactionAdditionalProperties @splatForAddedProperties)

    if (Resolve-ParameterWithDefaultConfigurationValue -Name PassThru -ConfigValueName DefaultPassThru)
    {
        return $result
    }
}

filter Remove-GitHubReaction
{
<#
    .SYNOPSIS
        Removes a reaction on a given GitHub Issue or Pull Request.

    .DESCRIPTION
        Removes a reaction on a given GitHub Issue or Pull Request.

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
        The issue number.

    .PARAMETER PullRequest
        The pull request number.

    .PARAMETER ReactionId
        The Id of the reaction. You can get this from using Get-GitHubReaction.

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
        GitHub.Repository

    .OUTPUTS
        None

    .EXAMPLE
        Remove-GitHubReaction -OwnerName PowerShell -RepositoryName PowerShell -Issue 12626 `
            -ReactionId 1234

        Remove a reaction by Id on Issue 12626 from the PowerShell\PowerShell project
        interactively.

    .EXAMPLE
        Remove-GitHubReaction -OwnerName PowerShell -RepositoryName PowerShell -Issue 12626 -ReactionId 1234 -Confirm:$false

        Remove a reaction by Id on Issue 12626 from the PowerShell\PowerShell project
        non-interactively.

    .EXAMPLE
        Get-GitHubReaction -OwnerName PowerShell -RepositoryName PowerShell -Issue 12626 -ReactionType rocket | Remove-GitHubReaction -Confirm:$false

        Gets a reaction using Get-GitHubReaction and pipes it into Remove-GitHubReaction.

    .NOTES
        Currently, issue comments, pull request comments and commit comments are not supported.
#>
    [CmdletBinding(
        SupportsShouldProcess,
        DefaultParameterSetName='ElementsIssue',
        ConfirmImpact='High')]
    [Alias('Delete-GitHubReaction')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSReviewUnusedParameter", "", Justification="The Uri parameter is only referenced by Resolve-RepositoryElements which get access to it from the stack via Get-Variable -Scope 1.")]
    param(
        [Parameter(
            Mandatory,
            ParameterSetName='ElementsIssue')]
        [Parameter(
            Mandatory,
            ParameterSetName='ElementsPullRequest')]
        [string] $OwnerName,

        [Parameter(
            Mandatory,
            ParameterSetName='ElementsIssue')]
        [Parameter(
            Mandatory,
            ParameterSetName='ElementsPullRequest')]
        [string] $RepositoryName,

        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName='UriIssue')]
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName='UriPullRequest')]
        [Alias('RepositoryUrl')]
        [string] $Uri,

        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName='ElementsIssue')]
        [Parameter(
            Mandatory,
            ParameterSetName='UriIssue',
            ValueFromPipelineByPropertyName)]
        [Alias('IssueNumber')]
        [int64] $Issue,

        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName='ElementsPullRequest')]
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName='UriPullRequest')]
        [Alias('PullRequestNumber')]
        [int64] $PullRequest,

        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ValueFromPipeline)]
        [int64] $ReactionId,

        [Parameter()]
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
    }

    if ($Issue)
    {
        $targetObjectNumber = $Issue
        $targetObjectTypeName = 'Issue'
        $uriFragment = "/repos/$OwnerName/$RepositoryName/issues/$targetObjectNumber/reactions/$ReactionId"
    }
    else
    {
        # Pull request
        $targetObjectNumber = $PullRequest
        $targetObjectTypeName = 'Pull Request'
        $uriFragment = "/repos/$OwnerName/$RepositoryName/issues/$targetObjectNumber/reactions/$ReactionId"
    }

    $description = "Removing reaction $ReactionId for $targetObjectTypeName $targetObjectNumber in $RepositoryName"

    if ($Force -and (-not $Confirm))
    {
        $ConfirmPreference = 'None'
    }

    if (-not $PSCmdlet.ShouldProcess(
        $ReactionId,
        "Removing reaction for $targetObjectTypeName $targetObjectNumber in $RepositoryName"))
    {
        return
    }

    $params = @{
        'UriFragment' = $uriFragment
        'Description' =  $description
        'Method' = 'Delete'
        'AcceptHeader' = $script:squirrelGirlAcceptHeader
        'AccessToken' = $AccessToken
        'TelemetryEventName' = $MyInvocation.MyCommand.Name
        'TelemetryProperties' = $telemetryProperties
    }

    return Invoke-GHRestMethod @params
}

filter Add-GitHubReactionAdditionalProperties
{
<#
    .SYNOPSIS
        Adds type name and additional properties to ease pipelining to GitHub Reaction objects.

    .PARAMETER InputObject
        The GitHub object to add additional properties to.

    .PARAMETER TypeName
        The type that should be assigned to the object.

    .PARAMETER OwnerName
        Owner of the repository.

    .PARAMETER RepositoryName
        Name of the repository.

    .PARAMETER Issue
        The issue number.

    .PARAMETER PullRequest
        The pull request number.

    .INPUTS
        [PSCustomObject]

    .OUTPUTS
        GitHub.Reaction
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
        [string] $TypeName = $script:GitHubReactionTypeName,

        [Parameter(Mandatory)]
        [string] $OwnerName,

        [Parameter(Mandatory)]
        [string] $RepositoryName,

        [Parameter(
            Mandatory,
            ParameterSetName='Issue')]
        [Alias('IssueNumber')]
        [int64] $Issue,

        [Parameter(
            Mandatory,
            ParameterSetName='PullRequest')]
        [Alias('PullRequestNumber')]
        [int64] $PullRequest
    )

    foreach ($item in $InputObject)
    {
        $item.PSObject.TypeNames.Insert(0, $TypeName)

        if (-not (Get-GitHubConfiguration -Name DisablePipelineSupport))
        {
            $repositoryUrl = Join-GitHubUri -OwnerName $OwnerName -RepositoryName $RepositoryName
            Add-Member -InputObject $item -Name 'RepositoryUrl' -Value $repositoryUrl -MemberType NoteProperty -Force
            Add-Member -InputObject $item -Name 'ReactionId' -Value $item.id -MemberType NoteProperty -Force

            if ($PullRequest)
            {
                Add-Member -InputObject $item -Name 'PullRequestNumber' -Value $PullRequest -MemberType NoteProperty -Force
            }
            else
            {
                # Issue
                Add-Member -InputObject $item -Name 'IssueNumber' -Value $Issue -MemberType NoteProperty -Force
            }

            @('assignee', 'assignees', 'user') |
                ForEach-Object {
                    if ($null -ne $item.$_)
                    {
                        $null = Add-GitHubUserAdditionalProperties -InputObject $item.$_
                    }
                }
        }

        Write-Output $item
    }
}
