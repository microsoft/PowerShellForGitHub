# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

filter Get-GitHubAssignee
{
<#
    .DESCRIPTION
        Lists the available assignees for issues in a repository.

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
        GitHub.ReleaseAsset
        GitHub.Repository
        GitHub.User

    .OUTPUTS
        GitHub.User

    .EXAMPLE
        Get-GitHubAssigneeList -OwnerName microsoft -RepositoryName PowerShellForGitHub

        Lists the available assignees for issues from the microsoft\PowerShellForGitHub project.

    .EXAMPLE
        $repo = Get-GitHubRepository -OwnerName microsoft -RepositoryName PowerShellForGitHub
        $repo | Get-GitHubAssigneeList

        Lists the available assignees for issues from the microsoft\PowerShellForGitHub project.
#>
    [CmdletBinding(DefaultParameterSetName = 'Elements')]
    [OutputType({$script:GitHubUserTypeName})]
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
        'UriFragment' = "repos/$OwnerName/$RepositoryName/assignees"
        'Description' = "Getting assignee list for $RepositoryName"
        'AccessToken' = $AccessToken
        'TelemetryEventName' = $MyInvocation.MyCommand.Name
        'TelemetryProperties' = $telemetryProperties
        'NoStatus' = (Resolve-ParameterWithDefaultConfigurationValue -Name NoStatus -ConfigValueName DefaultNoStatus)
    }

    return (Invoke-GHRestMethodMultipleResult @params | Add-GitHubUserAdditionalProperties)
}

filter Test-GitHubAssignee
{
<#
    .DESCRIPTION
        Checks if a user has permission to be assigned to an issue in this repository.

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

    .PARAMETER Assignee
        Username for the assignee

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
        GitHub.ReleaseAsset
        GitHub.Repository
        GitHub.User

    .OUTPUTS
        [bool]
        If the assignee can be assigned to issues in the repository.

    .EXAMPLE
        Test-GitHubAssignee -OwnerName microsoft -RepositoryName PowerShellForGitHub -Assignee "LoginID123"

        Checks if a user has permission to be assigned to an issue
        from the microsoft\PowerShellForGitHub project.

    .EXAMPLE
        $repo = Get-GitHubRepository -OwnerName microsoft -RepositoryName PowerShellForGitHub
        $repo | Test-GitHubAssignee -Assignee 'octocat'

        Checks if a user has permission to be assigned to an issue
        from the microsoft\PowerShellForGitHub project.

    .EXAMPLE
        $octocat = Get-GitHubUser -UserName 'octocat'
        $repo = $octocat | Test-GitHubAssignee -OwnerName microsoft -RepositoryName PowerShellForGitHub

        Checks if a user has permission to be assigned to an issue
        from the microsoft\PowerShellForGitHub project.
#>
    [CmdletBinding(DefaultParameterSetName = 'Elements')]
    [OutputType([bool])]
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

        [Parameter(ValueFromPipelineByPropertyName)]
        [Alias('UserName')]
        [string] $Assignee,

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
        'Assignee' = (Get-PiiSafeString -PlainText $Assignee)
    }

    $params = @{
        'UriFragment' = "repos/$OwnerName/$RepositoryName/assignees/$Assignee"
        'Method' = 'Get'
        'Description' = "Checking permission for $Assignee for $RepositoryName"
        'AccessToken' = $AccessToken
        'TelemetryEventName' = $MyInvocation.MyCommand.Name
        'TelemetryProperties' = $telemetryProperties
        'ExtendedResult'= $true
        'NoStatus' = (Resolve-ParameterWithDefaultConfigurationValue -Name NoStatus -ConfigValueName DefaultNoStatus)
    }

    try
    {
        $response = Invoke-GHRestMethod @params
        return $response.StatusCode -eq 204
    }
    catch
    {
        return $false
    }
}

function Add-GitHubAssignee
{
<#
    .DESCRIPTION
       Adds a list of assignees to a GitHub Issue for the given repository.

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
        Issue number to add the assignees to.

    .PARAMETER Assignee
        Usernames of users to assign this issue to.

        NOTE: Only users with push access can add assignees to an issue.
        Assignees are silently ignored otherwise.

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
        GitHub.ReleaseAsset
        GitHub.Repository
        GitHub.User

    .OUTPUTS
        GitHub.Issue

    .EXAMPLE
        $assignees = @('octocat')
        Add-GitHubAssignee -OwnerName microsoft -RepositoryName PowerShellForGitHub -Issue 1 -Assignee $assignee

        Additionally assigns the usernames in $assignee to Issue #1
        from the microsoft\PowerShellForGitHub project.

    .EXAMPLE
        $assignees = @('octocat')
        $repo = Get-GitHubRepository -OwnerName microsoft -RepositoryName PowerShellForGitHub
        $repo | Add-GitHubAssignee -Issue 1 -Assignee $assignee

        Additionally assigns the usernames in $assignee to Issue #1
        from the microsoft\PowerShellForGitHub project.

    .EXAMPLE
        $assignees = @('octocat')
        Get-GitHubRepository -OwnerName microsoft -RepositoryName PowerShellForGitHub |
            Get-GitHubIssue -Issue 1 |
            Add-GitHubAssignee -Assignee $assignee

        Additionally assigns the usernames in $assignee to Issue #1
        from the microsoft\PowerShellForGitHub project.

    .EXAMPLE
        $octocat = Get-GitHubUser -UserName 'octocat'
        $octocat | Add-GitHubAssignee -OwnerName microsoft -RepositoryName PowerShellForGitHub -Issue 1

        Additionally assigns the user 'octocat' to Issue #1
        from the microsoft\PowerShellForGitHub project.
#>
    [CmdletBinding(
        SupportsShouldProcess,
        DefaultParameterSetName='Elements')]
    [OutputType({$script:GitHubIssueTypeName})]
    [Alias('New-GitHubAssignee')] # Non-standard usage of the New verb, but done to avoid a breaking change post 0.14.0
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

        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName)]
        [ValidateCount(1, 10)]
        [Alias('UserName')]
        [string[]] $Assignee,

        [string] $AccessToken,

        [switch] $NoStatus
    )

    begin
    {
        $userNames = @()
    }

    process
    {
        foreach ($name in $Assignee)
        {
            $userNames += $name
        }
    }

    end
    {
        $elements = Resolve-RepositoryElements
        $OwnerName = $elements.ownerName
        $RepositoryName = $elements.repositoryName

        $telemetryProperties = @{
            'OwnerName' = (Get-PiiSafeString -PlainText $OwnerName)
            'RepositoryName' = (Get-PiiSafeString -PlainText $RepositoryName)
            'AssigneeCount' = $userNames.Count
            'Issue' =  (Get-PiiSafeString -PlainText $Issue)
        }

        $hashBody = @{
            'assignees' = $userNames
        }

        $params = @{
            'UriFragment' = "repos/$OwnerName/$RepositoryName/issues/$Issue/assignees"
            'Body' = (ConvertTo-Json -InputObject $hashBody)
            'Method' = 'Post'
            'Description' = "Add assignees to issue $Issue for $RepositoryName"
            'AccessToken' = $AccessToken
            'AcceptHeader' = $script:symmetraAcceptHeader
            'TelemetryEventName' = $MyInvocation.MyCommand.Name
            'TelemetryProperties' = $telemetryProperties
            'NoStatus' = (Resolve-ParameterWithDefaultConfigurationValue -Name NoStatus -ConfigValueName DefaultNoStatus)
        }

        if (-not $PSCmdlet.ShouldProcess($Issue, "Add Assignee(s) $($userNames -join ',')"))
        {
            return
        }

        Write-InvocationLog

        return (Invoke-GHRestMethod @params | Add-GitHubIssueAdditionalProperties)
    }
}

function Remove-GitHubAssignee
{
<#
    .DESCRIPTION
        Removes an assignee from a GitHub issue.

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
        Issue number to remove the assignees from.

    .PARAMETER Assignee
        Usernames of assignees to remove from an issue.

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
        GitHub.ReleaseAsset
        GitHub.Repository

    .OUTPUTS
        GitHub.Issue

    .EXAMPLE
        $assignees = @('octocat')
        Remove-GitHubAssignee -OwnerName microsoft -RepositoryName PowerShellForGitHub -Issue 1 -Assignee $assignee

        Removes the specified usernames from the assignee list for Issue #1
        in the microsoft\PowerShellForGitHub project.

    .EXAMPLE
        $assignees = @('octocat')
        $repo = Get-GitHubRepository -OwnerName microsoft -RepositoryName PowerShellForGitHub
        $repo | Remove-GitHubAssignee -Issue 1 -Assignee $assignee

        Removes the specified usernames from the assignee list for Issue #1
        in the microsoft\PowerShellForGitHub project.

        Will not prompt for confirmation because -Confirm:$false was specified

    .EXAMPLE
        $assignees = @('octocat')
        Get-GitHubRepository -OwnerName microsoft -RepositoryName PowerShellForGitHub |
            Get-GitHubIssue -Issue 1 |
            Remove-GitHubAssignee -Assignee $assignee

        Removes the specified usernames from the assignee list for Issue #1
        in the microsoft\PowerShellForGitHub project.

        Will not prompt for confirmation because -Force was specified

    .EXAMPLE
        $octocat = Get-GitHubUser -UserName 'octocat'
        $octocat | Remove-GitHubAssignee -OwnerName microsoft -RepositoryName PowerShellForGitHub -Issue 1

        Removes the specified usernames from the assignee list for Issue #1
        in the microsoft\PowerShellForGitHub project.

    .NOTES
        Only users with push access can remove assignees from an issue.
        Assignees are silently ignored otherwise.
#>
    [CmdletBinding(
        SupportsShouldProcess,
        DefaultParameterSetName='Elements',
        ConfirmImpact="High")]
    [OutputType({$script:GitHubIssueTypeName})]
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

        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [Alias('UserName')]
        [string[]] $Assignee,

        [switch] $Force,

        [string] $AccessToken,

        [switch] $NoStatus
    )

    begin
    {
        $userNames = @()
    }

    process
    {
        foreach ($name in $Assignee)
        {
            $userNames += $name
        }
    }

    end
    {
        $elements = Resolve-RepositoryElements
        $OwnerName = $elements.ownerName
        $RepositoryName = $elements.repositoryName

        $telemetryProperties = @{
            'OwnerName' = (Get-PiiSafeString -PlainText $OwnerName)
            'RepositoryName' = (Get-PiiSafeString -PlainText $RepositoryName)
            'AssigneeCount' = $Assignee.Count
            'Issue' =  (Get-PiiSafeString -PlainText $Issue)
        }

        $hashBody = @{
            'assignees' = $userNames
        }

        if ($Force -and (-not $Confirm))
        {
            $ConfirmPreference = 'None'
        }

        if (-not $PSCmdlet.ShouldProcess($Issue, "Remove assignee(s) $($userNames -join ', ')"))
        {
            return
        }

        Write-InvocationLog

        $params = @{
            'UriFragment' = "repos/$OwnerName/$RepositoryName/issues/$Issue/assignees"
            'Body' = (ConvertTo-Json -InputObject $hashBody)
            'Method' = 'Delete'
            'Description' = "Removing assignees from issue $Issue for $RepositoryName"
            'AccessToken' = $AccessToken
            'AcceptHeader' = $script:symmetraAcceptHeader
            'TelemetryEventName' = $MyInvocation.MyCommand.Name
            'TelemetryProperties' = $telemetryProperties
            'NoStatus' = (Resolve-ParameterWithDefaultConfigurationValue -Name NoStatus -ConfigValueName DefaultNoStatus)
        }

        return (Invoke-GHRestMethod @params | Add-GitHubIssueAdditionalProperties)
    }
}
