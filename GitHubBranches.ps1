# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

@{
    GitHubBranchTypeName = 'GitHub.Branch'
    GitHubBranchProtectionRuleName = 'GitHub.BranchProtectionRule'
 }.GetEnumerator() | ForEach-Object {
     Set-Variable -Scope Script -Option ReadOnly -Name $_.Key -Value $_.Value
 }

filter Get-GitHubRepositoryBranch
{
<#
    .SYNOPSIS
        Retrieve branches for a given GitHub repository.

    .DESCRIPTION
        Retrieve branches for a given GitHub repository.

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

    .PARAMETER Name
        Name of the specific branch to be retrieved.  If not supplied, all branches will be retrieved.

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
        GitHub.Branch
        List of branches within the given repository.

    .EXAMPLE
        Get-GitHubRepositoryBranch -OwnerName microsoft -RepositoryName PowerShellForGitHub

        Gets all branches for the specified repository.

    .EXAMPLE
        $repo = Get-GitHubRepository -OwnerName microsoft -RepositoryName PowerShellForGitHub
        $repo | Get-GitHubRepositoryBranch

        Gets all branches for the specified repository.

    .EXAMPLE
        Get-GitHubRepositoryBranch -Uri 'https://github.com/PowerShell/PowerShellForGitHub' -BranchName master

        Gets information only on the master branch for the specified repository.

    .EXAMPLE
        $repo = Get-GitHubRepository -OwnerName microsoft -RepositoryName PowerShellForGitHub
        $repo | Get-GitHubRepositoryBranch -BranchName master

        Gets information only on the master branch for the specified repository.

    .EXAMPLE
        $repo = Get-GitHubRepository -OwnerName microsoft -RepositoryName PowerShellForGitHub
        $branch = $repo | Get-GitHubRepositoryBranch -BranchName master
        $branch | Get-GitHubRepositoryBranch

        Gets information only on the master branch for the specified repository, and then does it
        again.  This tries to show some of the different types of objects you can pipe into this
        function.
#>
    [CmdletBinding(
        SupportsShouldProcess,
        DefaultParameterSetName='Elements')]
    [OutputType({$script:GitHubBranchTypeName})]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSShouldProcess", "", Justification="Methods called within here make use of PSShouldProcess, and the switch is passed on to them inherently.")]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSReviewUnusedParameter", "", Justification="One or more parameters (like NoStatus) are only referenced by helper methods which get access to it from the stack via Get-Variable -Scope 1.")]
    [Alias('Get-GitHubBranch')]
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
        [string] $BranchName,

        [switch] $ProtectedOnly,

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

    $uriFragment = "repos/$OwnerName/$RepositoryName/branches"
    if (-not [String]::IsNullOrEmpty($BranchName)) { $uriFragment = $uriFragment + "/$BranchName" }

    $getParams = @()
    if ($ProtectedOnly) { $getParams += 'protected=true' }

    $params = @{
        'UriFragment' = $uriFragment + '?' + ($getParams -join '&')
        'Description' = "Getting branches for $RepositoryName"
        'AccessToken' = $AccessToken
        'TelemetryEventName' = $MyInvocation.MyCommand.Name
        'TelemetryProperties' = $telemetryProperties
        'NoStatus' = (Resolve-ParameterWithDefaultConfigurationValue -Name NoStatus -ConfigValueName DefaultNoStatus)
    }

    return (Invoke-GHRestMethodMultipleResult @params | Add-GitHubBranchAdditionalProperties)
}

filter New-GitHubRepositoryBranch
{
    <#
    .SYNOPSIS
        Creates a new branch for a given GitHub repository.

    .DESCRIPTION
        Creates a new branch for a given GitHub repository.

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

    .PARAMETER BranchName
        The name of the origin branch to create the new branch from.

    .PARAMETER TargetBranchName
        Name of the branch to be created.

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
        GitHub.Release
        GitHub.Repository

    .OUTPUTS
        GitHub.Branch

    .EXAMPLE
        New-GitHubRepositoryBranch -OwnerName microsoft -RepositoryName PowerShellForGitHub -TargetBranchName new-branch

        Creates a new branch in the specified repository from the master branch.

    .EXAMPLE
        New-GitHubRepositoryBranch -Uri 'https://github.com/microsoft/PowerShellForGitHub' -BranchName develop -TargetBranchName new-branch

        Creates a new branch in the specified repository from the 'develop' origin branch.

    .EXAMPLE
        $repo = Get-GithubRepository -Uri https://github.com/You/YourRepo
        $repo | New-GitHubRepositoryBranch -TargetBranchName new-branch

        You can also pipe in a repo that was returned from a previous command.
#>
    [CmdletBinding(
        SupportsShouldProcess,
        DefaultParameterSetName = 'Elements',
        PositionalBinding = $false
    )]
    [OutputType({$script:GitHubBranchTypeName})]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSShouldProcess', '',
        Justification = 'Methods called within here make use of PSShouldProcess, and the switch is
        passed on to them inherently.')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '',
        Justification = 'One or more parameters (like NoStatus) are only referenced by helper
        methods which get access to it from the stack via Get-Variable -Scope 1.')]
    [Alias('New-GitHubBranch')]
    param(
        [Parameter(ParameterSetName = 'Elements')]
        [string] $OwnerName,

        [Parameter(ParameterSetName = 'Elements')]
        [string] $RepositoryName,

        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            Position = 1,
            ParameterSetName = 'Uri')]
        [Alias('RepositoryUrl')]
        [string] $Uri,

        [string] $BranchName = 'master',

        [Parameter(
            Mandatory,
            ValueFromPipeline,
            Position = 2)]
        [string] $TargetBranchName,

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

    $originBranch = $null

    try
    {
        $getGitHubRepositoryBranchParms = @{
            OwnerName = $OwnerName
            RepositoryName = $RepositoryName
            BranchName = $BranchName
            Whatif = $false
            Confirm = $false
        }
        if ($PSBoundParameters.ContainsKey('AccessToken'))
        {
            $getGitHubRepositoryBranchParms['AccessToken'] = $AccessToken
        }
        if ($PSBoundParameters.ContainsKey('NoStatus'))
        {
            $getGitHubRepositoryBranchParms['NoStatus'] = $NoStatus
        }

        Write-Log -Level Verbose "Getting $BranchName branch for sha reference"
        $originBranch = Get-GitHubRepositoryBranch  @getGitHubRepositoryBranchParms
    }
    catch
    {
        # Temporary code to handle current differences in exception object between PS5 and PS7
        $throwObject = $_

        if ($PSVersionTable.PSedition -eq 'Core')
        {
            if ($_.Exception -is [Microsoft.PowerShell.Commands.HttpResponseException] -and
            ($_.ErrorDetails.Message | ConvertFrom-Json).message -eq 'Branch not found')
            {
                $throwObject = "Origin branch $BranchName not found"
            }
        }
        else
        {
            if ($_.Exception.Message -like '*Not Found*')
            {
                $throwObject = "Origin branch $BranchName not found"
            }
        }

        Write-Log -Message $throwObject -Level Error
        throw $throwObject
    }

    $uriFragment = "repos/$OwnerName/$RepositoryName/git/refs"

    $hashBody = @{
        ref = "refs/heads/$TargetBranchName"
        sha = $originBranch.commit.sha
    }

    $params = @{
        'UriFragment' = $uriFragment
        'Body' = (ConvertTo-Json -InputObject $hashBody)
        'Method' = 'Post'
        'Description' = "Creating branch $TargetBranchName for $RepositoryName"
        'AccessToken' = $AccessToken
        'TelemetryEventName' = $MyInvocation.MyCommand.Name
        'TelemetryProperties' = $telemetryProperties
        'NoStatus' = (Resolve-ParameterWithDefaultConfigurationValue -Name NoStatus -ConfigValueName DefaultNoStatus)
    }

    return (Invoke-GHRestMethod @params | Add-GitHubBranchAdditionalProperties)
}

filter Remove-GitHubRepositoryBranch
{
    <#
    .SYNOPSIS
        Removes a branch from a given GitHub repository.

    .DESCRIPTION
        Removes a branch from a given GitHub repository.

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

    .PARAMETER BranchName
        Name of the branch to be removed.

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
        GitHub.Release
        GitHub.Repository

    .OUTPUTS
        None

    .EXAMPLE
        Remove-GitHubRepositoryBranch -OwnerName microsoft -RepositoryName PowerShellForGitHub -BranchName develop

        Removes the 'develop' branch from the specified repository.

    .EXAMPLE
        Remove-GitHubRepositoryBranch -OwnerName microsoft -RepositoryName PowerShellForGitHub -BranchName develop -Force

        Removes the 'develop' branch from the specified repository without prompting for confirmation.

    .EXAMPLE
        $branch = Get-GitHubRepositoryBranch -Uri https://github.com/You/YourRepo -BranchName BranchToDelete
        $branch | Remove-GitHubRepositoryBranch -Force

        You can also pipe in a repo that was returned from a previous command.
#>
    [CmdletBinding(
        SupportsShouldProcess,
        DefaultParameterSetName = 'Elements',
        PositionalBinding = $false,
        ConfirmImpact = 'High')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSShouldProcess", "",
        Justification = "Methods called within here make use of PSShouldProcess, and the switch is
        passed on to them inherently.")]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSReviewUnusedParameter", "",
        Justification = "One or more parameters (like NoStatus) are only referenced by helper
        methods which get access to it from the stack via Get-Variable -Scope 1.")]
    [Alias('Remove-GitHubBranch')]
    [Alias('Delete-GitHubRepositoryBranch')]
    [Alias('Delete-GitHubBranch')]
    param(
        [Parameter(ParameterSetName = 'Elements')]
        [string] $OwnerName,

        [Parameter(ParameterSetName = 'Elements')]
        [string] $RepositoryName,

        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            Position = 1,
            ParameterSetName = 'Uri')]
        [Alias('RepositoryUrl')]
        [string] $Uri,

        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            Position = 2)]
        [string] $BranchName,

        [switch] $Force,

        [string] $AccessToken,

        [switch] $NoStatus
    )

    $elements = Resolve-RepositoryElements
    $OwnerName = $elements.ownerName
    $RepositoryName = $elements.repositoryName

    $telemetryProperties = @{
        'OwnerName' = (Get-PiiSafeString -PlainText $OwnerName)
        'RepositoryName' = (Get-PiiSafeString -PlainText $RepositoryName)
    }

    $uriFragment = "repos/$OwnerName/$RepositoryName/git/refs/heads/$BranchName"

    if ($Force -and (-not $Confirm))
    {
        $ConfirmPreference = 'None'
    }

    if ($PSCmdlet.ShouldProcess($BranchName, "Remove Repository Branch"))
    {
        Write-InvocationLog

        $params = @{
            'UriFragment' = $uriFragment
            'Method' = 'Delete'
            'Description' = "Deleting branch $BranchName from $RepositoryName"
            'AccessToken' = $AccessToken
            'TelemetryEventName' = $MyInvocation.MyCommand.Name
            'TelemetryProperties' = $telemetryProperties
            'NoStatus' = (Resolve-ParameterWithDefaultConfigurationValue `
                -Name NoStatus -ConfigValueName DefaultNoStatus)
        }

        Invoke-GHRestMethod @params | Out-Null
    }
}

chProtectionRule
filter Get-GitHubRepositoryBranchProtectionRule
{
<#
    .SYNOPSIS
        Retrieve branch protection rules for a given GitHub repository.

    .DESCRIPTION
        Retrieve branch protection rules for a given GitHub repository.

        The Git repo for this module can be found here: http://aka.ms/PowerShellForGitHub

    .PARAMETER Name
        Name of the specific branch to be retrieved.  If not supplied, all branches will be retrieved.

    .PARAMETER Uri
        Uri for the repository.
        The OwnerName and RepositoryName will be extracted from here instead of needing to provide
        them individually.

    .PARAMETER OwnerName
        Owner of the repository.
        If not supplied here, the DefaultOwnerName configuration property value will be used.

    .PARAMETER RepositoryName
        Name of the repository.
        If not supplied here, the DefaultRepositoryName configuration property value will be used.

    .PARAMETER AccessToken
        If provided, this will be used as the AccessToken for authentication with the
        REST Api.  Otherwise, will attempt to use the configured value or will run unauthenticated.

    .PARAMETER NoStatus
        If this switch is specified, long-running commands will run on the main thread
        with no commandline status update.  When not specified, those commands run in
        the background, enabling the command prompt to provide status information.
        If not supplied here, the DefaultNoStatus configuration property value will be used.

    .INPUTS
        GitHub.Repository
        GitHub.Branch

    .OUTPUTS
        GitHub.BranchProtectionRule

    .EXAMPLE
        Get-GitHubRepositoryBranchProtectionRule -OwnerName microsoft -RepositoryName PowerShellForGitHub -BranchName master

        Retrieves branch protection rules for the master branch of the PowerShellForGithub repository.

    .EXAMPLE
        Get-GitHubRepositoryBranchProtectionRule -Uri 'https://github.com/microsoft/PowerShellForGitHub' -BranchName master

        Retrieves branch protection rules for the master branch of the PowerShellForGithub repository.
#>
    [CmdletBinding(
        PositionalBinding = $false,
        DefaultParameterSetName='Elements')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '',
        Justification='One or more parameters (like NoStatus) are only referenced by helper methods which get access to it from the stack via Get-Variable -Scope 1.')]
    param(
        [Parameter(
            Mandatory,
            Position = 1,
            ValueFromPipelineByPropertyName,
            ParameterSetName='Uri')]
        [string] $Uri,

        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            Position = 2)]
        [string] $BranchName,

        [Parameter(ParameterSetName='Elements')]
        [string] $OwnerName,

        [Parameter(ParameterSetName='Elements')]
        [string] $RepositoryName,

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
        UriFragment = "repos/$OwnerName/$RepositoryName/branches/$BranchName/protection"
        Description = "Getting branch protection status for $RepositoryName"
        Method = 'Get'
        AcceptHeader = $script:lukeCageAcceptHeader
        AccessToken = $AccessToken
        TelemetryEventName = $MyInvocation.MyCommand.Name
        TelemetryProperties = $telemetryProperties
        NoStatus = (Resolve-ParameterWithDefaultConfigurationValue -Name NoStatus -ConfigValueName DefaultNoStatus)
    }

    return (Invoke-GHRestMethod @params | Add-GitHubBranchProtectionRuleAdditionalProperties)
}

filter Set-GitHubRepositoryBranchProtectionRule
{
<#
    .SYNOPSIS
        Set branch protection rules for a given GitHub repository.

    .DESCRIPTION
        Set branch protection rules for a given GitHub repository.

        The Git repo for this module can be found here: http://aka.ms/PowerShellForGitHub

    .PARAMETER Name
        Name of the specific branch to be retrieved.  If not supplied, all branches will be retrieved.

    .PARAMETER Uri
        Uri for the repository.
        The OwnerName and RepositoryName will be extracted from here instead of needing to provide
        them individually.

    .PARAMETER OwnerName
        Owner of the repository.
        If not supplied here, the DefaultOwnerName configuration property value will be used.

    .PARAMETER RepositoryName
        Name of the repository.
        If not supplied here, the DefaultRepositoryName configuration property value will be used.

    .PARAMETER StatusChecks
        The list of status checks to require in order to merge into the branch.

    .PARAMETER RequireUpToDateBranches
        Require branches to be up to date before merging. This setting will not take effect unless
        at least one status check is defined.

    .PARAMETER EnforceAdmins
        Enforce all configured restrictions for administrators.

    .PARAMETER DismissalUsers
        Specify the user names of users who can dismiss pull request reviews. This can only be
        specified for organization-owned repositories.

    .PARAMETER DismissalTeams
        Specify which teams can dismiss pull request reviews.

    .PARAMETER DismissStaleReviews
        If specified, approving reviews when someone pushes a new commit are automatically
        dismissed.

    .PARAMETER RequireCodeOwnerReviews
        Blocks merging pull requests until code owners review them.

    .PARAMETER RequiredApprovingReviewCount
        Specify the number of reviewers required to approve pull requests. Use a number between 1
        and 6.

    .PARAMETER RestrictPushUsers
        Specify which users have push access.

    .PARAMETER RestrictPushTeams
        Specify which teams have push access.

    .PARAMETER RestrictPushApps
        Specify which apps have push access.

    .PARAMETER RequireLinearHistory
        Enforces a linear commit Git history, which prevents anyone from pushing merge commits to a
        branch. Your repository must allow squash merging or rebase merging before you can enable a
        linear commit history.

    .PARAMETER AllowForcePushes
        Permits force pushes to the protected branch by anyone with write access to the repository.

    .PARAMETER AllowDeletions
        Allows deletion of the protected branch by anyone with write access to the repository.

    .PARAMETER AccessToken
        If provided, this will be used as the AccessToken for authentication with the
        REST Api.  Otherwise, will attempt to use the configured value or will run unauthenticated.

    .PARAMETER NoStatus
        If this switch is specified, long-running commands will run on the main thread
        with no commandline status update.  When not specified, those commands run in
        the background, enabling the command prompt to provide status information.
        If not supplied here, the DefaultNoStatus configuration property value will be used.

    .INPUTS
        GitHub.Repository
        GitHub.Branch
        GitHub.BranchRepositoryRule

    .OUTPUTS
        GitHub.BranchRepositoryRule

    .NOTES
        Protecting a branch requires admin or owner permissions to the repository.

    .EXAMPLE
        Set-GitHubRepositoryBranchProtectionRule -OwnerName microsoft -RepositoryName PowerShellForGitHub -BranchName master -EnforceAdmins

        Sets a branch protection rule for the master branch of the PowerShellForGithub repository
        enforcing all configuration restrictions for administrators.

    .EXAMPLE
        Set-GitHubRepositoryBranchProtectionRule -Uri 'https://github.com/microsoft/PowerShellForGitHub' -BranchName master -RequiredApprovingReviewCount 1

        Sets a branch protection rule for the master branch of the PowerShellForGithub repository
        requiring one approving review.
#>
    [CmdletBinding(
        PositionalBinding = $false,
        SupportsShouldProcess,
        DefaultParameterSetName='Elements')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '',
        Justification='One or more parameters (like NoStatus) are only referenced by helper methods which get access to it from the stack via Get-Variable -Scope 1.')]
    param(
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            Position = 1,
            ParameterSetName='Uri')]
        [string] $Uri,

        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            Position = 2)]
        [string] $BranchName,

        [Parameter(ParameterSetName='Elements')]
        [string] $OwnerName,

        [Parameter(ParameterSetName='Elements')]
        [string] $RepositoryName,

        [string[]] $StatusChecks,

        [switch] $RequireUpToDateBranches,

        [switch] $EnforceAdmins,

        [string[]] $DismissalUsers,

        [string[]] $DismissalTeams,

        [switch] $DismissStaleReviews,

        [switch] $RequireCodeOwnerReviews,

        [ValidateRange(1, 6)]
        [int] $RequiredApprovingReviewCount,

        [string[]] $RestrictPushUsers,

        [string[]] $RestrictPushTeams,

        [string[]] $RestrictPushApps,

        [switch]$RequireLinearHistory,

        [switch] $AllowForcePushes,

        [switch] $AllowDeletions,

        [string] $AccessToken,

        [switch] $NoStatus
    )

    $elements = Resolve-RepositoryElements
    $OwnerName = $elements.ownerName
    $RepositoryName = $elements.repositoryName

    $telemetryProperties = @{
        OwnerName = (Get-PiiSafeString -PlainText $OwnerName)
        RepositoryName = (Get-PiiSafeString -PlainText $RepositoryName)
    }

    if ($PSBoundParameters.ContainsKey('StatusChecks'))
    {
        $requiredStatusChecks = @{
            strict = $RequireUpToDateBranches.ToBool()
            contexts = $StatusChecks
        }
    }
    else
    {
        $requiredStatusChecks = $null
    }

    $dismissalRestrictions = @{}

    if ($PSBoundParameters.ContainsKey('DismissalUsers'))
    {
       $dismissalRestrictions['users'] = $DismissalUsers
    }
    if ($PSBoundParameters.ContainsKey('DismissalTeams'))
    {
        $teams = Get-GitHubTeam -OwnerName $OwnerName -RepositoryName $RepositoryName |
            Where-Object -FilterScript { $DismissalTeams -contains $_.name }
        $dismissalRestrictions['teams'] = @($teams.slug)
    }

    $requiredPullRequestReviews = @{}

    if ($PSBoundParameters.ContainsKey('DismissStaleReviews'))
    {
        $requiredPullRequestReviews['dismiss_stale_reviews'] = $DismissStaleReviews.ToBool()
    }
    if ($PSBoundParameters.ContainsKey('RequireCodeOwnerReviews'))
    {
        $requiredPullRequestReviews['require_code_owner_reviews'] = $RequireCodeOwnerReviews.ToBool()
    }
    if ($PSBoundParameters.ContainsKey('RequiredApprovingReviewCount'))
    {
        $requiredPullRequestReviews['required_approving_review_count'] = $RequiredApprovingReviewCount
    }

    if ($dismissalRestrictions.count -gt 0)
    {
        $requiredPullRequestReviews['dismissal_restrictions'] = $dismissalRestrictions
    }

    if ($requiredPullRequestReviews.count -eq 0)
    {
        $requiredPullRequestReviews = $null
    }

    if ($PSBoundParameters.ContainsKey('RestrictPushUsers') -or
        $PSBoundParameters.ContainsKey('RestrictPushTeams') -or
        $PSBoundParameters.ContainsKey('RestrictPushApps'))
    {
        if ($null -eq $RestrictPushUsers)
        {
            $RestrictPushUsers = @()
        }

        if ($null -eq $RestrictPushTeams)
        {
            $restrictPushTeamSlugs = @()
        }
        else
        {
            $teams = Get-GitHubTeam -OwnerName $OwnerName -RepositoryName $RepositoryName |
                Where-Object -FilterScript { $RestrictPushTeams -contains $_.name }
            $restrictPushTeamSlugs['teams'] = @($teams.slug)
        }

        $restrictions = @{
            users = $RestrictPushUsers
            teams = $restrictPushTeamSlugs
        }

        if ($PSBoundParameters.ContainsKey('RestrictPushApps')) {
            $restrictions['apps'] = $RestrictPushApps }
    }
    else
    {
        $restrictions = $null
    }

    $hashBody = @{
        required_status_checks = $requiredStatusChecks
        enforce_admins = $EnforceAdmins.ToBool()
        required_pull_request_reviews = $requiredPullRequestReviews
        restrictions = $restrictions
    }

    if ($PSBoundParameters.ContainsKey('RequireLinearHistory'))
    {
        $hashBody['required_linear_history'] = $RequireLinearHistory.ToBool()
    }
    if ($PSBoundParameters.ContainsKey('AllowForcePushes'))
    {
        $hashBody['allow_force_pushes'] = $AllowForcePushes.ToBool()
    }
    if ($PSBoundParameters.ContainsKey('AllowDeletions'))
    {
        $hashBody['allow_deletions'] = $AllowDeletions.ToBool()
    }

    if ($PSCmdlet.ShouldProcess("'$BranchName' branch of repository '$RepositoryName'",
        'Set GitHub Repository Branch Protection'))
    {
        Write-InvocationLog

        $jsonConversionDepth = 3

        $params = @{
            UriFragment = "repos/$OwnerName/$RepositoryName/branches/$BranchName/protection"
            Body = (ConvertTo-Json -InputObject $hashBody -Depth $jsonConversionDepth)
            Description =  "Setting $BranchName branch protection status for $RepositoryName"
            Method = 'Put'
            AcceptHeader = $script:lukeCageAcceptHeader
            AccessToken = $AccessToken
            TelemetryEventName = $MyInvocation.MyCommand.Name
            TelemetryProperties = $telemetryProperties
            NoStatus = (Resolve-ParameterWithDefaultConfigurationValue -Name NoStatus `
                -ConfigValueName DefaultNoStatus)
        }

        return (Invoke-GHRestMethod @params | Add-GitHubBranchProtectionRuleAdditionalProperties)
    }
}

filter Remove-GitHubRepositoryBranchProtectionRule
{
<#
    .SYNOPSIS
        Remove branch protection rules from a given GitHub repository.

    .DESCRIPTION
        Remove branch protection rules from a given GitHub repository.

        The Git repo for this module can be found here: http://aka.ms/PowerShellForGitHub

    .PARAMETER Name
        Name of the specific branch to be removed.

    .PARAMETER Uri
        Uri for the repository.
        The OwnerName and RepositoryName will be extracted from here instead of needing to provide
        them individually.

    .PARAMETER OwnerName
        Owner of the repository.
        If not supplied here, the DefaultOwnerName configuration property value will be used.

    .PARAMETER RepositoryName
        Name of the repository.
        If not supplied here, the DefaultRepositoryName configuration property value will be used.

    .PARAMETER AccessToken
        If provided, this will be used as the AccessToken for authentication with the
        REST Api.  Otherwise, will attempt to use the configured value or will run unauthenticated.

    .PARAMETER NoStatus
        If this switch is specified, long-running commands will run on the main thread
        with no commandline status update.  When not specified, those commands run in
        the background, enabling the command prompt to provide status information.
        If not supplied here, the DefaultNoStatus configuration property value will be used.

    .INPUTS
        GitHub.Repository
        GitHub.Branch

    .OUTPUTS
        None

    .EXAMPLE
        Remove-GitHubRepositoryBranchProtectionRule -OwnerName microsoft -RepositoryName PowerShellForGitHub -BranchName master

        Removes branch protection rules from the master branch of the PowerShellForGithub repository.

    .EXAMPLE
        Removes-GitHubRepositoryBranchProtection -Uri 'https://github.com/microsoft/PowerShellForGitHub' -BranchName master

        Removes branch protection rules from the master branch of the PowerShellForGithub repository.

    .EXAMPLE
        Removes-GitHubRepositoryBranchProtection -Uri 'https://github.com/master/PowerShellForGitHub' -BranchName master -Force

        Removes branch protection rules from the master branch of the PowerShellForGithub repository
        without prompting for confirmation.
#>
    [CmdletBinding(
        PositionalBinding = $false,
        SupportsShouldProcess,
        DefaultParameterSetName='Elements',
        ConfirmImpact="High")]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '',
        Justification='One or more parameters (like NoStatus) are only referenced by helper methods which get access to it from the stack via Get-Variable -Scope 1.')]
    [Alias('Delete-GitHubRepositoryBranchProtectionRule')]
    param(
        [Parameter(
            Mandatory,
            Position = 1,
            ValueFromPipelineByPropertyName,
            ParameterSetName='Uri')]
        [string] $Uri,

        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            Position = 2)]
        [string] $BranchName,

        [Parameter(ParameterSetName='Elements')]
        [string] $OwnerName,

        [Parameter(ParameterSetName='Elements')]
        [string] $RepositoryName,

        [switch] $Force,

        [string] $AccessToken,

        [switch] $NoStatus
    )

    $elements = Resolve-RepositoryElements
    $OwnerName = $elements.ownerName
    $RepositoryName = $elements.repositoryName

    $telemetryProperties = @{
        'OwnerName' = (Get-PiiSafeString -PlainText $OwnerName)
        'RepositoryName' = (Get-PiiSafeString -PlainText $RepositoryName)
    }

    if ($Force -and (-not $Confirm))
    {
        $ConfirmPreference = 'None'
    }

    if ($PSCmdlet.ShouldProcess("'$BranchName' branch of repository '$RepositoryName'",
        'Remove GitHub Repository Branch Protection Rule'))
    {
        Write-InvocationLog

        $params = @{
            UriFragment = "repos/$OwnerName/$RepositoryName/branches/$BranchName/protection"
            Description =  "Removing $BranchName branch protection rule for $RepositoryName"
            Method = 'Delete'
            AcceptHeader = $script:lukeCageAcceptHeader
            AccessToken = $AccessToken
            TelemetryEventName = $MyInvocation.MyCommand.Name
            TelemetryProperties = $telemetryProperties
            NoStatus = (Resolve-ParameterWithDefaultConfigurationValue -Name NoStatus `
                -ConfigValueName DefaultNoStatus)
        }

        return Invoke-GHRestMethod @params | Out-Null
    }
}

filter Add-GitHubBranchAdditionalProperties
{
<#
    .SYNOPSIS
        Adds type name and additional properties to ease pipelining to GitHub Branch objects.

    .PARAMETER InputObject
        The GitHub object to add additional properties to.

    .PARAMETER TypeName
        The type that should be assigned to the object.

    .INPUTS
        PSCustomObject

    .OUTPUTS
        GitHub.Branch
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
        [string] $TypeName = $script:GitHubBranchTypeName
    )

    foreach ($item in $InputObject)
    {
        $item.PSObject.TypeNames.Insert(0, $TypeName)

        if (-not (Get-GitHubConfiguration -Name DisablePipelineSupport))
        {
            if ($null -ne $item.url)
            {
                $elements = Split-GitHubUri -Uri $item.url
            }
            else
            {
                $elements = Split-GitHubUri -Uri $item.commit.url
            }
            $repositoryUrl = Join-GitHubUri @elements

            Add-Member -InputObject $item -Name 'RepositoryUrl' -Value $repositoryUrl -MemberType NoteProperty -Force

            $branchName = $item.name
            if ($null -eq $branchName)
            {
                $branchName = $item.ref -replace ('refs/heads/', '')
            }

            Add-Member -InputObject $item -Name 'BranchName' -Value $branchName -MemberType NoteProperty -Force
        }

        Write-Output $item
    }
}

filter Add-GitHubBranchProtectionRuleAdditionalProperties
{
<#
    .SYNOPSIS
        Adds type name and additional properties to ease pipelining to GitHub Branch Protection Rule objects.

    .PARAMETER InputObject
        The GitHub object to add additional properties to.

    .PARAMETER TypeName
        The type that should be assigned to the object.

    .INPUTS
        PSCustomObject

    .OUTPUTS
        GitHub.Branch
#>
    [CmdletBinding()]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseSingularNouns', '',
        Justification='Internal helper that is definitely adding more than one property.')]
    param(
        [Parameter(
            Mandatory,
            ValueFromPipeline)]
        [AllowNull()]
        [AllowEmptyCollection()]
        [PSCustomObject[]] $InputObject,

        [ValidateNotNullOrEmpty()]
        [string] $TypeName = $script:GitHubBranchTypeName
    )

    foreach ($item in $InputObject)
    {
        $item.PSObject.TypeNames.Insert(0, $TypeName)

        if (-not (Get-GitHubConfiguration -Name DisablePipelineSupport))
        {
            $elements = Split-GitHubUri -Uri $item.url
            $repositoryUrl = Join-GitHubUri @elements
            Add-Member -InputObject $item -Name 'RepositoryUrl' -Value $repositoryUrl -MemberType NoteProperty -Force

            $hostName = $(Get-GitHubConfiguration -Name 'ApiHostName')

            if ($item.html_url -match "^https?://api.$hostName/repos/([^/]+)/?([^/]+)/?([^/]+)/?([^/]+)?(?:/.*)?$")
            {
                $branchName = $Matches[4]
            }
            else
            {
                $branchName = ''
            }

            Add-Member -InputObject $item -Name 'BranchName' -Value $branchName -MemberType NoteProperty -Force
        }

        Write-Output $item
    }
}
