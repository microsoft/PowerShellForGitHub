# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

@{
    GitHubBranchTypeName = 'GitHub.Branch'
    GitHubBranchProtectionRuleTypeName = 'GitHub.BranchProtectionRule'
    GitHubBranchPatternProtectionRuleTypeName = 'GitHub.BranchPatternProtectionRule'
    MaxProtectionRules = 100
    MaxPushAllowances = 100
    MaxReviewDismissalAllowances = 100
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
    [CmdletBinding(DefaultParameterSetName = 'Elements')]
    [OutputType({$script:GitHubBranchTypeName})]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSReviewUnusedParameter", "", Justification="The Uri parameter is only referenced by Resolve-RepositoryElements which get access to it from the stack via Get-Variable -Scope 1.")]
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

    .PARAMETER Sha
        The SHA1 value of the commit that this branch should be based on.
        If not specified, will use the head of BranchName.

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

    .EXAMPLE
        $branch = Get-GitHubRepositoryBranch -OwnerName microsoft -RepositoryName PowerShellForGitHub -BranchName main
        $branch | New-GitHubRepositoryBranch -TargetBranchName beta

        You can also pipe in a branch that was returned from a previous command.

    .EXAMPLE
        New-GitHubRepositoryBranch -Uri 'https://github.com/microsoft/PowerShellForGitHub' -Sha 1c3b80b754a983f4da20e77cfb9bd7f0e4cb5da6 -TargetBranchName new-branch

        You can also create a new branch based off of a specific SHA1 commit value.
#>
    [CmdletBinding(
        SupportsShouldProcess,
        DefaultParameterSetName = 'Elements',
        PositionalBinding = $false
    )]
    [OutputType({$script:GitHubBranchTypeName})]
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

        [Parameter(ValueFromPipelineByPropertyName)]
        [string] $BranchName = 'master',

        [Parameter(
            Mandatory,
            ValueFromPipeline,
            Position = 2)]
        [string] $TargetBranchName,

        [Parameter(ValueFromPipelineByPropertyName)]
        [string] $Sha,

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

    $originBranch = $null

    if (-not $PSBoundParameters.ContainsKey('Sha'))
    {
        try
        {
            $getGitHubRepositoryBranchParms = @{
                OwnerName = $OwnerName
                RepositoryName = $RepositoryName
                BranchName = $BranchName
            }
            if ($PSBoundParameters.ContainsKey('AccessToken'))
            {
                $getGitHubRepositoryBranchParms['AccessToken'] = $AccessToken
            }

            Write-Log -Level Verbose "Getting $BranchName branch for sha reference"
            $originBranch = Get-GitHubRepositoryBranch @getGitHubRepositoryBranchParms
            $Sha = $originBranch.commit.sha
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
    }

    $uriFragment = "repos/$OwnerName/$RepositoryName/git/refs"

    $hashBody = @{
        ref = "refs/heads/$TargetBranchName"
        sha = $Sha
    }

    if (-not $PSCmdlet.ShouldProcess($BranchName, 'Create Repository Branch'))
    {
        return
    }

    $params = @{
        'UriFragment' = $uriFragment
        'Body' = (ConvertTo-Json -InputObject $hashBody)
        'Method' = 'Post'
        'Description' = "Creating branch $TargetBranchName for $RepositoryName"
        'AccessToken' = $AccessToken
        'TelemetryEventName' = $MyInvocation.MyCommand.Name
        'TelemetryProperties' = $telemetryProperties
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
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSReviewUnusedParameter", "", Justification="The Uri parameter is only referenced by Resolve-RepositoryElements which get access to it from the stack via Get-Variable -Scope 1.")]
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

    $uriFragment = "repos/$OwnerName/$RepositoryName/git/refs/heads/$BranchName"

    if ($Force -and (-not $Confirm))
    {
        $ConfirmPreference = 'None'
    }

    if (-not $PSCmdlet.ShouldProcess($BranchName, "Remove Repository Branch"))
    {
        return
    }

    $params = @{
        'UriFragment' = $uriFragment
        'Method' = 'Delete'
        'Description' = "Deleting branch $BranchName from $RepositoryName"
        'AccessToken' = $AccessToken
        'TelemetryEventName' = $MyInvocation.MyCommand.Name
        'TelemetryProperties' = $telemetryProperties
    }

    Invoke-GHRestMethod @params | Out-Null
}


filter Get-GitHubRepositoryBranchProtectionRule
{
    <#
    .SYNOPSIS
        Retrieve branch protection rules for a given GitHub repository.

    .DESCRIPTION
        Retrieve branch protection rules for a given GitHub repository.

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
        Name of the specific branch to be retrieved.  If not supplied, all branches will be retrieved.

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
        GitHub.Release
        GitHub.Repository

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
        DefaultParameterSetName = 'Elements')]
    [OutputType({ $script:GitHubBranchProtectionRuleTypeName })]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSReviewUnusedParameter", "", Justification="The Uri parameter is only referenced by Resolve-RepositoryElements which get access to it from the stack via Get-Variable -Scope 1.")]
    param(
        [Parameter(ParameterSetName = 'Elements')]
        [string] $OwnerName,

        [Parameter(ParameterSetName = 'Elements')]
        [string] $RepositoryName,

        [Parameter(
            Mandatory,
            Position = 1,
            ValueFromPipelineByPropertyName,
            ParameterSetName = 'Uri')]
        [Alias('RepositoryUrl')]
        [string] $Uri,

        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            Position = 2)]
        [string] $BranchName,

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
        UriFragment = "repos/$OwnerName/$RepositoryName/branches/$BranchName/protection"
        Description = "Getting branch protection status for $RepositoryName"
        Method = 'Get'
        AcceptHeader = $script:lukeCageAcceptHeader
        AccessToken = $AccessToken
        TelemetryEventName = $MyInvocation.MyCommand.Name
        TelemetryProperties = $telemetryProperties
    }

    return (Invoke-GHRestMethod @params | Add-GitHubBranchProtectionRuleAdditionalProperties)
}

filter New-GitHubRepositoryBranchProtectionRule
{
    <#
    .SYNOPSIS
        Creates a branch protection rule for a branch on a given GitHub repository.

    .DESCRIPTION
        Creates a branch protection rules for a branch on a given GitHub repository.

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
        Name of the specific branch to create the protection rule on.

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

    .INPUTS
        GitHub.Repository
        GitHub.Branch

    .OUTPUTS
        GitHub.BranchRepositoryRule

    .NOTES
        Protecting a branch requires admin or owner permissions to the repository.

    .EXAMPLE
        New-GitHubRepositoryBranchProtectionRule -OwnerName microsoft -RepositoryName PowerShellForGitHub -BranchName master -EnforceAdmins

        Creates a branch protection rule for the master branch of the PowerShellForGithub repository
        enforcing all configuration restrictions for administrators.

    .EXAMPLE
        New-GitHubRepositoryBranchProtectionRule -Uri 'https://github.com/microsoft/PowerShellForGitHub' -BranchName master -RequiredApprovingReviewCount 1

        Creates a branch protection rule for the master branch of the PowerShellForGithub repository
        requiring one approving review.
#>
    [CmdletBinding(
        PositionalBinding = $false,
        SupportsShouldProcess,
        DefaultParameterSetName = 'Elements')]
    [OutputType({$script:GitHubBranchProtectionRuleTypeName })]
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

        [switch] $RequireLinearHistory,

        [switch] $AllowForcePushes,

        [switch] $AllowDeletions,

        [string] $AccessToken
    )

    Write-InvocationLog

    $elements = Resolve-RepositoryElements
    $OwnerName = $elements.ownerName
    $RepositoryName = $elements.repositoryName

    $telemetryProperties = @{
        OwnerName = (Get-PiiSafeString -PlainText $OwnerName)
        RepositoryName = (Get-PiiSafeString -PlainText $RepositoryName)
    }

    $getGitHubRepositoryBranchProtectRuleParms = @{
        OwnerName = $OwnerName
        RepositoryName = $RepositoryName
        BranchName = $BranchName
    }

    $ruleExists = $true

    try
    {
        Get-GitHubRepositoryBranchProtectionRule @getGitHubRepositoryBranchProtectRuleParms |
            Out-Null
    }
    catch
    {
        # Temporary code to handle current differences in exception object between PS5 and PS7
        if ($PSVersionTable.PSedition -eq 'Core')
        {
            if ($_.Exception -is [Microsoft.PowerShell.Commands.HttpResponseException] -and
                ($_.ErrorDetails.Message | ConvertFrom-Json).message -eq 'Branch not protected')
            {
                $ruleExists = $false
            }
            else
            {
                throw $_
            }
        }
        else
        {
            if ($_.Exception.Message -like '*Branch not protected*')
            {
                $ruleExists = $false
            }
            else
            {
                throw $_
            }
        }
    }

    if ($ruleExists)
    {
        $message = ("Branch protection rule for branch $BranchName already exists on Repository " +
            $RepositoryName)
        Write-Log -Message $message -Level Error
        throw $message
    }

    if ($PSBoundParameters.ContainsKey('DismissalTeams') -or
        $PSBoundParameters.ContainsKey('RestrictPushTeams'))
    {
        $teams = Get-GitHubTeam -OwnerName $OwnerName -RepositoryName $RepositoryName
    }

    $requiredStatusChecks = $null
    if ($PSBoundParameters.ContainsKey('StatusChecks') -or
        $PSBoundParameters.ContainsKey('RequireUpToDateBranches'))
    {
        if ($null -eq $StatusChecks)
        {
            $StatusChecks = @()
        }
        $requiredStatusChecks = @{
            strict = $RequireUpToDateBranches.ToBool()
            contexts = $StatusChecks
        }
    }

    $dismissalRestrictions = @{}

    if ($PSBoundParameters.ContainsKey('DismissalUsers'))
    {
        $dismissalRestrictions['users'] = $DismissalUsers
    }
    if ($PSBoundParameters.ContainsKey('DismissalTeams'))
    {
        $dismissalTeamList = $teams | Where-Object -FilterScript { $DismissalTeams -contains $_.name }
        $dismissalRestrictions['teams'] = @($dismissalTeamList.slug)
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
    if ($dismissalRestrictions.count -gt 0)
    {
        $requiredPullRequestReviews['dismissal_restrictions'] = $dismissalRestrictions
    }
    if ($PSBoundParameters.ContainsKey('RequiredApprovingReviewCount'))
    {
        $requiredPullRequestReviews['required_approving_review_count'] = $RequiredApprovingReviewCount
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
            $restrictPushTeamList = $teams | Where-Object -FilterScript {
                $RestrictPushTeams -contains $_.name }
            $restrictPushTeamSlugs = @($restrictPushTeamList.slug)
        }

        $restrictions = @{
            users = $RestrictPushUsers
            teams = $restrictPushTeamSlugs
        }

        if ($PSBoundParameters.ContainsKey('RestrictPushApps'))
        {
            $restrictions['apps'] = $RestrictPushApps
        }
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

    if (-not $PSCmdlet.ShouldProcess(
            "'$BranchName' branch of repository '$RepositoryName'",
            'Create GitHub Repository Branch Protection Rule'))
    {
        return
    }

    $jsonConversionDepth = 3

    $params = @{
        UriFragment = "repos/$OwnerName/$RepositoryName/branches/$BranchName/protection"
        Body = (ConvertTo-Json -InputObject $hashBody -Depth $jsonConversionDepth)
        Description = "Setting $BranchName branch protection status for $RepositoryName"
        Method = 'Put'
        AcceptHeader = $script:lukeCageAcceptHeader
        AccessToken = $AccessToken
        TelemetryEventName = $MyInvocation.MyCommand.Name
        TelemetryProperties = $telemetryProperties
    }

    return (Invoke-GHRestMethod @params | Add-GitHubBranchProtectionRuleAdditionalProperties)
}

filter Remove-GitHubRepositoryBranchProtectionRule
{
    <#
    .SYNOPSIS
        Remove branch protection rules from a given GitHub repository.

    .DESCRIPTION
        Remove branch protection rules from a given GitHub repository.

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
        Name of the specific branch to remove the branch protection rule from.

    .PARAMETER AccessToken
        If provided, this will be used as the AccessToken for authentication with the
        REST Api.  Otherwise, will attempt to use the configured value or will run unauthenticated.

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
        DefaultParameterSetName = 'Elements',
        ConfirmImpact = "High")]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSReviewUnusedParameter", "", Justification="The Uri parameter is only referenced by Resolve-RepositoryElements which get access to it from the stack via Get-Variable -Scope 1.")]
    [Alias('Delete-GitHubRepositoryBranchProtectionRule')]
    param(
        [Parameter(ParameterSetName = 'Elements')]
        [string] $OwnerName,

        [Parameter(ParameterSetName = 'Elements')]
        [string] $RepositoryName,

        [Parameter(
            Mandatory,
            Position = 1,
            ValueFromPipelineByPropertyName,
            ParameterSetName = 'Uri')]
        [Alias('RepositoryUrl')]
        [string] $Uri,

        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            Position = 2)]
        [string] $BranchName,

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

    if ($Force -and (-not $Confirm))
    {
        $ConfirmPreference = 'None'
    }

    if (-not $PSCmdlet.ShouldProcess("'$BranchName' branch of repository '$RepositoryName'",
            'Remove GitHub Repository Branch Protection Rule'))
    {
        return
    }

    $params = @{
        UriFragment = "repos/$OwnerName/$RepositoryName/branches/$BranchName/protection"
        Description = "Removing $BranchName branch protection rule for $RepositoryName"
        Method = 'Delete'
        AcceptHeader = $script:lukeCageAcceptHeader
        AccessToken = $AccessToken
        TelemetryEventName = $MyInvocation.MyCommand.Name
        TelemetryProperties = $telemetryProperties
    }

    return Invoke-GHRestMethod @params | Out-Null
}

filter New-GitHubRepositoryBranchPatternProtectionRule
{
    <#
    .SYNOPSIS
        Creates a branch protection rule for a branch on a given GitHub repository.

    .DESCRIPTION
        Creates a branch protection rules for a branch on a given GitHub repository.

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
        Name of the Organization.

    .PARAMETER BranchPatternName
        The branch name pattern to create the protection rule on.

    .PARAMETER StatusCheck
        The list of status checks to require in order to merge into the branch.

    .PARAMETER RequireStrictStatusChecks
        Require branches to be up to date before merging. This setting will not take effect unless
        at least one status check is defined.

    .PARAMETER IsAdminEnforced
        Enforce all configured restrictions for administrators.

    .PARAMETER DismissalUser
        Specify the user names of users who can dismiss pull request reviews.

    .PARAMETER DismissalTeam
        Specify which teams can dismiss pull request reviews. This can only be
        specified for organization-owned repositories.

    .PARAMETER DismissStaleReviews
        If specified, approving reviews when someone pushes a new commit are automatically
        dismissed.

    .PARAMETER RequireCodeOwnerReviews
        Blocks merging pull requests until code owners review them.

    .PARAMETER RequiredApprovingReviewCount
        Specify the number of reviewers required to approve pull requests. Use a number between 1
        and 6.

    .PARAMETER RestrictPushUser
        Specify which users have push access.

    .PARAMETER RestrictPushTeam
        Specify which teams have push access.

    .PARAMETER RestrictPushApp
        Specify which apps have push access.

    .PARAMETER RequireLinearHistory
        Enforces a linear commit Git history, which prevents anyone from pushing merge commits to a
        branch. Your repository must allow squash merging or rebase merging before you can enable a
        linear commit history.

    .PARAMETER RequireCommitSignatures
        Specifies whether commits are required to be signed.

    .PARAMETER AllowForcePushes
        Permits force pushes to the protected branch by anyone with write access to the repository.

    .PARAMETER AllowDeletions
        Allows deletion of the protected branch by anyone with write access to the repository.

    .PARAMETER AccessToken
        If provided, this will be used as the AccessToken for authentication with the
        REST Api.  Otherwise, will attempt to use the configured value or will run unauthenticated.

    .INPUTS
        GitHub.Repository
        GitHub.Branch

    .OUTPUTS
        GitHub.BranchPatternProtectionRule

    .NOTES
        Protecting a branch requires admin or owner permissions to the repository.

    .EXAMPLE
        New-GitHubRepositoryBranchPatternProtectionRule -OwnerName microsoft -RepositoryName PowerShellForGitHub -BranchName release/**/* -EnforceAdmins

        Creates a branch protection rule for the 'release/**/*' branch pattern of the PowerShellForGithub repository
        enforcing all configuration restrictions for administrators.

    .EXAMPLE
        New-GitHubRepositoryBranchPatternProtectionRule -Uri 'https://github.com/microsoft/PowerShellForGitHub' -BranchName master -RequiredApprovingReviewCount 1

        Creates a branch protection rule for the master branch of the PowerShellForGithub repository
        requiring one approving review.
#>
    [CmdletBinding(
        PositionalBinding = $false,
        SupportsShouldProcess,
        DefaultParameterSetName = 'Elements')]
    [OutputType( { $script:GitHubBranchPatternProtectionRuleTypeName })]
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

        [string] $OrganizationName,

        [Parameter(
            Mandatory,
            Position = 2)]
        [string] $BranchPatternName,

        [ValidateNotNullOrEmpty()]
        [string[]] $StatusCheck,

        [switch] $RequireStrictStatusChecks,

        [switch] $IsAdminEnforced,

        [ValidateNotNullOrEmpty()]
        [string[]] $DismissalUser,

        [ValidateNotNullOrEmpty()]
        [string[]] $DismissalTeam,

        [switch] $DismissStaleReviews,

        [switch] $RequireCodeOwnerReviews,

        [ValidateRange(1, 6)]
        [int] $RequiredApprovingReviewCount,

        [ValidateNotNullOrEmpty()]
        [string[]] $RestrictPushUser,

        [ValidateNotNullOrEmpty()]
        [string[]] $RestrictPushTeam,

        [ValidateNotNullOrEmpty()]
        [string[]] $RestrictPushApp,

        [switch] $RequireLinearHistory,

        [switch] $AllowForcePushes,

        [switch] $AllowDeletions,

        [switch] $RequireCommitSignatures,

        [string] $AccessToken
    )

    Write-InvocationLog

    $elements = Resolve-RepositoryElements
    $OwnerName = $elements.ownerName
    $RepositoryName = $elements.repositoryName

    if ([System.String]::IsNullOrEmpty($OrganizationName))
    {
        $OrganizationName = $OwnerName
    }

    $telemetryProperties = @{
        OwnerName = (Get-PiiSafeString -PlainText $OwnerName)
        RepositoryName = (Get-PiiSafeString -PlainText $RepositoryName)
    }

    $hashbody = @{query = "query repo { repository(name: ""$RepositoryName"", owner: ""$OwnerName"") { id } }" }

    $params = @{
        Body = ConvertTo-Json -InputObject $hashBody
        Description = "Querying Repository $RepositoryName, Owner $OwnerName"
        AccessToken = $AccessToken
        TelemetryEventName = 'Get-GitHubRepositoryQ1'
        TelemetryProperties = $telemetryProperties
    }

    try
    {
        $result = Invoke-GHGraphQl @params
    }
    catch
    {
        $PSCmdlet.ThrowTerminatingError($_)
    }

    $repoId = $result.data.repository.id

    $mutationList = @(
        "repositoryId: ""$repoId"", pattern: ""$BranchPatternName"""
    )

    if ($PSBoundParameters.ContainsKey('DismissalTeam') -or
        $PSBoundParameters.ContainsKey('RestrictPushTeam'))
    {
        Write-Debug -Message "Getting details for all GitHub Teams in Organization '$OrganizationName'"

        try
        {
            $orgTeams = Get-GitHubTeam -OrganizationName $OrganizationName -Verbose:$false
        }
        catch
        {
            $PSCmdlet.ThrowTerminatingError($_)
        }
    }

    # Process 'Require pull request reviews before merging' properties
    if ($PSBoundParameters.ContainsKey('RequiredApprovingReviewCount') -or
        $PSBoundParameters.ContainsKey('DismissStaleReviews') -or
        $PSBoundParameters.ContainsKey('RequireCodeOwnerReviews') -or
        $PSBoundParameters.ContainsKey('DismissalUser') -or
        $PSBoundParameters.ContainsKey('DismissalTeam'))
    {
        $mutationList += 'requiresApprovingReviews: true'

        if ($PSBoundParameters.ContainsKey('RequiredApprovingReviewCount'))
        {
            $mutationList += 'requiredApprovingReviewCount: ' + $RequiredApprovingReviewCount
        }

        if ($PSBoundParameters.ContainsKey('DismissStaleReviews'))
        {
            $mutationList += 'dismissesStaleReviews: ' + $DismissStaleReviews.ToBool().ToString().ToLower()
        }

        if ($PSBoundParameters.ContainsKey('RequireCodeOwnerReviews'))
        {
            $mutationList += 'requiresCodeOwnerReviews: ' + $RequireCodeOwnerReviews.ToBool().ToString().ToLower()
        }

        if ($PSBoundParameters.ContainsKey('DismissalUser') -or
            $PSBoundParameters.ContainsKey('DismissalTeam'))
        {
            $reviewDismissalActorIds = @()

            if ($PSBoundParameters.ContainsKey('DismissalUser'))
            {
                foreach ($user in $DismissalUser)
                {
                    $hashbody = @{query = "query user { user(login: ""$user"") { id } }"}

                    $params = @{
                        Body = ConvertTo-Json -InputObject $hashBody
                        Description = "Querying for user $user"
                        AccessToken = $AccessToken
                        TelemetryEventName = 'Get-GitHubUserQ1'
                        TelemetryProperties = $telemetryProperties
                    }

                    try
                    {
                        $result = Invoke-GHGraphQl @params
                    }
                    catch
                    {
                        $PSCmdlet.ThrowTerminatingError($_)
                    }

                    $reviewDismissalActorIds += $result.data.user.id
                }
            }

            if ($PSBoundParameters.ContainsKey('DismissalTeam'))
            {
                foreach ($team in $DismissalTeam)
                {
                    $teamDetail = $orgTeams | Where-Object -Property Name -eq $team

                    if ($teamDetail.Count -eq 0)
                    {
                        $newErrorRecordParms = @{
                            ErrorMessage = "Team '$team' not found in organization '$OrganizationName'"
                            ErrorId = 'DismissalTeamNotFound'
                            ErrorCategory = [System.Management.Automation.ErrorCategory]::ObjectNotFound
                            TargetObject = $team
                        }
                        $errorRecord = New-ErrorRecord @newErrorRecordParms

                        Write-Log -Exception $errorRecord -Level Error

                        $PSCmdlet.ThrowTerminatingError($errorRecord)
                    }

                    $getGitHubRepositoryTeamPermissionParms = @{
                        TeamSlug = $teamDetail.TeamSlug
                        OwnerName = $ownerName
                        RepositoryName = $repositoryName
                        Verbose = $false
                    }

                    Write-Debug -Message "Getting GitHub Permissions for Team '$team' on Repository '$OwnerName/$RepositoryName'"

                    try
                    {
                        $teamPermission = Get-GitHubRepositoryTeamPermission @getGitHubRepositoryTeamPermissionParms
                    }
                    catch
                    {
                        Write-Debug -Message "Team '$team' has no permissions on Repository '$OwnerName/$RepositoryName'"
                    }

                    if (($teamPermission.permissions.push -eq $true) -or ($teamPermission.permissions.maintain -eq $true))
                    {
                        $reviewDismissalActorIds += $teamDetail.node_id
                    }
                    else
                    {
                        $newErrorRecordParms = @{
                            ErrorMessage = "Team '$team' does not have push or maintain permissions on repository '$OwnerName/$RepositoryName'"
                            ErrorId = 'DismissalTeamNoPermissions'
                            ErrorCategory = [System.Management.Automation.ErrorCategory]::PermissionDenied
                            TargetObject = $team
                        }
                        $errorRecord = New-ErrorRecord @newErrorRecordParms

                        Write-Log -Exception $errorRecord -Level Error

                        $PSCmdlet.ThrowTerminatingError($errorRecord)
                    }
                }
            }

            $mutationList += 'restrictsReviewDismissals: true'
            $mutationList += 'reviewDismissalActorIds: [ "' + ($reviewDismissalActorIds -join ('","')) + '" ]'
        }
    }

    # Process 'Require status checks to pass before merging' properties
    if ($PSBoundParameters.ContainsKey('StatusCheck') -or
        $PSBoundParameters.ContainsKey('RequireStrictStatusChecks'))
    {
        $mutationList += 'requiresStatusChecks: true'

        if ($PSBoundParameters.ContainsKey('RequireStrictStatusChecks'))
        {
            $mutationList += 'requiresStrictStatusChecks: ' + $RequireStrictStatusChecks.ToBool().ToString().ToLower()
        }

        if ($PSBoundParameters.ContainsKey('StatusCheck'))
        {
            $mutationList += 'requiredStatusCheckContexts: [ "' + ($StatusCheck -join ('","')) + '" ]'
        }
    }

    if ($PSBoundParameters.ContainsKey('RequireCommitSignatures'))
    {
        $mutationList += 'requiresCommitSignatures: ' + $RequireCommitSignatures.ToBool().ToString().ToLower()
    }

    if ($PSBoundParameters.ContainsKey('RequireLinearHistory'))
    {
        $mutationList += 'requiresLinearHistory: ' + $RequireLinearHistory.ToBool().ToString().ToLower()
    }

    if ($PSBoundParameters.ContainsKey('IsAdminEnforced'))
    {
        $mutationList += 'isAdminEnforced: ' + $IsAdminEnforced.ToBool().ToString().ToLower()
    }

    # Process 'Restrict who can push to matching branches' properties
    if ($PSBoundParameters.ContainsKey('RestrictPushUser') -or
        $PSBoundParameters.ContainsKey('RestrictPushTeam') -or
        $PSBoundParameters.ContainsKey('RestrictPushApp'))
    {
        $restrictPushActorIds = @()

        if ($PSBoundParameters.ContainsKey('RestrictPushUser'))
        {
            foreach ($user in $RestrictPushUser)
            {
                $hashbody = @{query = "query user { user(login: ""$user"") { id } }" }

                $params = @{
                    Body = ConvertTo-Json -InputObject $hashBody
                    Description = "Querying for User $user"
                    AccessToken = $AccessToken
                    TelemetryEventName = 'GetGitHubUserQ1'
                    TelemetryProperties = $telemetryProperties
                }

                try
                {
                    $result = Invoke-GHGraphQl @params
                }
                catch
                {
                    $PSCmdlet.ThrowTerminatingError($_)
                }

                $restrictPushActorIds += $result.data.user.id
            }
        }

        if ($PSBoundParameters.ContainsKey('RestrictPushTeam'))
        {
            foreach ($team in $RestrictPushTeam)
            {
                $teamDetail = $orgTeams | Where-Object -Property Name -eq $team

                if ($teamDetail.Count -eq 0)
                {
                    $newErrorRecordParms = @{
                        ErrorMessage = "Team '$team' not found in organization '$OrganizationName'"
                        ErrorId = 'RestrictPushTeamNotFound'
                        ErrorCategory = [System.Management.Automation.ErrorCategory]::ObjectNotFound
                        TargetObject = $team
                    }
                    $errorRecord = New-ErrorRecord @newErrorRecordParms

                    Write-Log -Exception $errorRecord -Level Error

                    $PSCmdlet.ThrowTerminatingError($errorRecord)
                }

                $getGitHubRepositoryTeamPermissionParms = @{
                    TeamSlug = $teamDetail.TeamSlug
                    OwnerName = $ownerName
                    RepositoryName = $repositoryName
                    Verbose = $false
                }

                Write-Debug -Message "Getting GitHub Permissions for Team '$team' on Repository '$OwnerName/$RepositoryName'"
                try
                {
                    $teamPermission = Get-GitHubRepositoryTeamPermission @getGitHubRepositoryTeamPermissionParms
                }
                catch
                {
                    Write-Debug -Message "Team '$team' has no permissions on Repository '$OwnerName/$RepositoryName'"
                }

                if ($teamPermission.permissions.push -eq $true -or $teamPermission.permissions.maintain -eq $true)
                {
                    $restrictPushActorIds += $teamDetail.node_id
                }
                else
                {
                    $newErrorRecordParms = @{
                        ErrorMessage = "Team '$team' does not have push or maintain permissions on repository '$OwnerName/$RepositoryName'"
                        ErrorId = 'RestrictPushTeamNoPermissions'
                        ErrorCategory = [System.Management.Automation.ErrorCategory]::PermissionDenied
                        TargetObject = $team
                    }
                    $errorRecord = New-ErrorRecord @newErrorRecordParms

                    Write-Log -Exception $errorRecord -Level Error

                    $PSCmdlet.ThrowTerminatingError($errorRecord)
                }
            }
        }

        if ($PSBoundParameters.ContainsKey('RestrictPushApp'))
        {
            foreach ($app in $RestrictPushApp)
            {
                $hashbody = @{query = "query app { marketplaceListing(slug: ""$app"") { app { id } } }" }

                $params = @{
                    Body = ConvertTo-Json -InputObject $hashBody
                    Description = "Querying for app $app"
                    AccessToken = $AccessToken
                    TelemetryEventName = 'Get-GitHubAppQ1'
                    TelemetryProperties = $telemetryProperties
                }

                try
                {
                    $result = Invoke-GHGraphQl @params
                }
                catch
                {
                    $PSCmdlet.ThrowTerminatingError($_)
                }

                if ($result.data.marketplaceListing)
                {
                    $restrictPushActorIds += $result.data.marketplaceListing.app.id
                }
                else
                {
                    $newErrorRecordParms = @{
                        ErrorMessage = "App '$app' not found in GitHub Marketplace"
                        ErrorId = 'RestictPushAppNotFound'
                        ErrorCategory = [System.Management.Automation.ErrorCategory]::ObjectNotFound
                        TargetObject = $app
                    }
                    $errorRecord = New-ErrorRecord @newErrorRecordParms

                    Write-Log -Exception $errorRecord -Level Error

                    $PSCmdlet.ThrowTerminatingError($errorRecord)
                }
            }
        }

        $mutationList += 'restrictsPushes: true'
        $mutationList += 'pushActorIds: [ "' + ($restrictPushActorIds -join ('","')) + '" ]'
    }

    if ($PSBoundParameters.ContainsKey('AllowForcePushes'))
    {
        $mutationList += 'allowsForcePushes: ' + $AllowForcePushes.ToBool().ToString().ToLower()
    }

    if ($PSBoundParameters.ContainsKey('AllowDeletions'))
    {
        $mutationList += 'allowsDeletions: ' + $AllowDeletions.ToBool().ToString().ToLower()
    }

    $mutationInput = $mutationList -join (',')
    $hashbody = @{query = "mutation ProtectionRule { createBranchProtectionRule(input: { $mutationInput }) " +
        "{ clientMutationId  } } "
    }

    $body = ConvertTo-Json -InputObject $hashBody

    if (-not $PSCmdlet.ShouldProcess(
            "$OwnerName/$RepositoryName",
            "Create GitHub Repository Branch Pattern Protection Rule '$BranchPatternName'"))
    {
        return
    }

    $params = @{
        Body = $body
        Description = "Creating GitHub Repository Branch Pattern Protection Rule '$BranchPatternName' on $OwnerName/$RepositoryName"
        AccessToken = $AccessToken
        TelemetryEventName = $MyInvocation.MyCommand.Name
        TelemetryProperties = $telemetryProperties
    }

    try
    {
        $result = Invoke-GHGraphQl @params
    }
    catch
    {
        $PSCmdlet.ThrowTerminatingError($_)
    }
}

filter Get-GitHubRepositoryBranchPatternProtectionRule
{
    <#
    .SYNOPSIS
        Retrieve a branch pattern protection rule for a given GitHub repository.

    .DESCRIPTION
        Retrieve a branch pattern protection rule for a given GitHub repository.

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

    .PARAMETER BranchPatternName
        Name of the specific branch Pattern to be retrieved.

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
        GitHub.Release
        GitHub.Repository

    .OUTPUTS
        GitHub.BranchPatternProtectionRule

    .EXAMPLE
        Get-GitHubRepositoryBranchPatternProtectionRule -OwnerName microsoft -RepositoryName PowerShellForGitHub -BranchPatternName release/**/*

        Retrieves branch protection rules for the release/**/* branch pattern of the PowerShellForGithub repository.

    .EXAMPLE
        Get-GitHubQlRepositoryBranchPatternProtectionRule -Uri 'https://github.com/microsoft/PowerShellForGitHub' -BranchPatternName master

        Retrieves branch protection rules for the master branch pattern of the PowerShellForGithub repository.
#>
    [CmdletBinding(
        PositionalBinding = $false,
        DefaultParameterSetName = 'Elements')]
    [OutputType( { $script:GitHubBranchProtectionRuleTypeName })]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSReviewUnusedParameter", "",
        Justification = "The Uri parameter is only referenced by Resolve-RepositoryElements which get access to it from the stack via Get-Variable -Scope 1.")]
    param(
        [Parameter(ParameterSetName = 'Elements')]
        [string] $OwnerName,

        [Parameter(ParameterSetName = 'Elements')]
        [string] $RepositoryName,

        [Parameter(
            Mandatory,
            Position = 1,
            ValueFromPipelineByPropertyName,
            ParameterSetName = 'Uri')]
        [Alias('RepositoryUrl')]
        [string] $Uri,

        [Parameter(Position = 2)]
        [string] $BranchPatternName,

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

    $branchProtectionRuleFields = ('allowsDeletions allowsForcePushes dismissesStaleReviews id ' +
        'isAdminEnforced pattern requiredApprovingReviewCount requiredStatusCheckContexts ' +
        'requiresApprovingReviews requiresCodeOwnerReviews requiresCommitSignatures requiresLinearHistory ' +
        'requiresStatusChecks requiresStrictStatusChecks restrictsPushes restrictsReviewDismissals ' +
        "pushAllowances(first: $script:MaxPushAllowances) { nodes { actor { ... on App { __typename name } " +
        '... on Team { __typename name } ... on User { __typename login } } } }' +
        "reviewDismissalAllowances(first: $script:MaxReviewDismissalAllowances)" +
        '{ nodes { actor { ... on Team { __typename name } ... on User { __typename login } } } } ' +
        'repository { url }')

    $hashbody = @{query = "query branchProtectionRule { repository(name: ""$RepositoryName"", " +
        "owner: ""$OwnerName"") { branchProtectionRules(first: $script:MaxProtectionRules) { nodes { " +
        "$branchProtectionRuleFields } } } }"}

    $params = @{
        Body = ConvertTo-Json -InputObject $hashBody
        Description = "Querying $OwnerName/$RepositoryName repository for branch protection rules"
        AccessToken = $AccessToken
        TelemetryEventName = $MyInvocation.MyCommand.Name
        TelemetryProperties = $telemetryProperties
    }

    try
    {
        $result = Invoke-GHGraphQl @params
    }
    catch
    {
        $PSCmdlet.ThrowTerminatingError($_)
    }

    if ($result.data.repository.branchProtectionRules)
    {
        if ($PSBoundParameters.ContainsKey('BranchPatternName'))
        {
            $rule = ($result.data.repository.branchProtectionRules.nodes |
                Where-Object -Property pattern -eq $BranchPatternName)
        }
        else
        {
            $rule = $result.data.repository.branchProtectionRules.nodes
        }
    }

    if (!$rule -and $PSBoundParameters.ContainsKey('BranchPatternName'))
    {
        $newErrorRecordParms = @{
            ErrorMessage = "Branch Protection Rule '$BranchPatternName' not found on repository '$OwnerName/$RepositoryName'"
            ErrorId = 'BranchProtectionRuleNotFound'
            ErrorCategory = [System.Management.Automation.ErrorCategory]::ObjectNotFound
            TargetObject = $BranchPatternName
        }
        $errorRecord = New-ErrorRecord @newErrorRecordParms

        Write-Log -Exception $errorRecord -Level Error

        $PSCmdlet.ThrowTerminatingError($errorRecord)
    }

    return ($rule | Add-GitHubBranchPatternProtectionRuleAdditionalProperties)
}

filter Remove-GitHubRepositoryBranchPatternProtectionRule
{
    <#
    .SYNOPSIS
        Remove a branch pattern protection rule from a given GitHub repository.

    .DESCRIPTION
        Remove a branch pattern protection rule from a given GitHub repository.

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

    .PARAMETER BranchPatternName
        Name of the specific branch protection rule pattern to remove.

    .PARAMETER AccessToken
        If provided, this will be used as the AccessToken for authentication with the
        REST Api.  Otherwise, will attempt to use the configured value or will run unauthenticated.

    .INPUTS
        GitHub.Repository

    .OUTPUTS
        None

    .EXAMPLE
        Remove-GitHubRepositoryBranchPatternProtectionRule -OwnerName microsoft -RepositoryName PowerShellForGitHub -BranchPatternName release/**/*

        Removes branch pattern 'release/**/*' protection rules from the PowerShellForGithub repository.

    .EXAMPLE
        Remove-GitHubRepositoryBranchPatternProtectionRule -Uri 'https://github.com/microsoft/PowerShellForGitHub' -BranchPatternName release/**/*

        Removes branch pattern 'release/**/*' protection rules from the PowerShellForGithub repository.

    .EXAMPLE
        Remove-GitHubRepositoryBranchPatternProtectionRule -Uri 'https://github.com/master/PowerShellForGitHub' -BranchPatternName release/**/* -Force

        Removes branch pattern 'release/**/*' protection rules from the PowerShellForGithub repository
        without prompting for confirmation.
#>
    [CmdletBinding(
        PositionalBinding = $false,
        SupportsShouldProcess,
        DefaultParameterSetName = 'Elements',
        ConfirmImpact = "High")]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSReviewUnusedParameter", "",
        Justification = "The Uri parameter is only referenced by Resolve-RepositoryElements which get access to it from the stack via Get-Variable -Scope 1.")]
    [Alias('Delete-GitHubRepositoryBranchPatternProtectionRule')]
    param(
        [Parameter(ParameterSetName = 'Elements')]
        [string] $OwnerName,

        [Parameter(ParameterSetName = 'Elements')]
        [string] $RepositoryName,

        [Parameter(
            Mandatory,
            Position = 1,
            ValueFromPipelineByPropertyName,
            ParameterSetName = 'Uri')]
        [Alias('RepositoryUrl')]
        [string] $Uri,

        [Parameter(
            Mandatory,
            Position = 2)]
        [string] $BranchPatternName,

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

    $hashbody = @{query = "query branchProtectionRule { repository(name: ""$RepositoryName"", " +
        "owner: ""$OwnerName"") { branchProtectionRules(first: $script:MaxProtectionRules) { nodes { id pattern } } } }"
    }

    $params = @{
        Body = ConvertTo-Json -InputObject $hashBody
        Description = "Querying $OwnerName/$RepositoryName repository for branch protection rules"
        AccessToken = $AccessToken
        TelemetryEventName = 'Get-GitHubRepositoryQ1'
        TelemetryProperties = $telemetryProperties
    }

    try
    {
        $result = Invoke-GHGraphQl @params
    }
    catch
    {
        $PSCmdlet.ThrowTerminatingError($_)
    }

    if ($result.data.repository.branchProtectionRules)
    {
        $ruleId = ($result.data.repository.branchProtectionRules.nodes |
            Where-Object -Property pattern -eq $BranchPatternName).id
    }

    if (!$ruleId)
    {
        $newErrorRecordParms = @{
            ErrorMessage = "Branch Protection Rule '$BranchPatternName' not found on repository '$OwnerName/$RepositoryName'"
            ErrorId = 'BranchProtectionRuleNotFound'
            ErrorCategory = [System.Management.Automation.ErrorCategory]::ObjectNotFound
            TargetObject = $BranchPatternName
        }
        $errorRecord = New-ErrorRecord @newErrorRecordParms

        Write-Log -Exception $errorRecord -Level Error

        $PSCmdlet.ThrowTerminatingError($errorRecord)
    }

    if ($Force -and (-not $Confirm))
    {
        $ConfirmPreference = 'None'
    }

    $hashbody = @{query = "mutation ProtectionRule { deleteBranchProtectionRule(input: " +
        "{ branchProtectionRuleId: ""$ruleId"" } ) { clientMutationId } }"
    }

    $body = ConvertTo-Json -InputObject $hashBody

    if (-not $PSCmdlet.ShouldProcess("$OwnerName/$RepositoryName",
            "Remove GitHub Repository Branch Pattern Protection Rule '$BranchPatternName'"))
    {
        return
    }

    $params = @{
        Body = $body
        Description = "Removing GitHub Repository Branch Pattern Protection Rule '$BranchPatternName' from $OwnerName/$RepositoryName"
        AccessToken = $AccessToken
        TelemetryEventName = $MyInvocation.MyCommand.Name
        TelemetryProperties = $telemetryProperties
    }

    try
    {
        $result = Invoke-GHGraphQl @params
    }
    catch
    {
        $PSCmdlet.ThrowTerminatingError($_)
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
        [PSCustomObject]

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

            if ($null -ne $item.commit)
            {
                Add-Member -InputObject $item -Name 'Sha' -Value $item.commit.sha -MemberType NoteProperty -Force
            }
            elseif ($null -ne $item.object)
            {
                Add-Member -InputObject $item -Name 'Sha' -Value $item.object.sha -MemberType NoteProperty -Force
            }
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
        Justification = 'Internal helper that is definitely adding more than one property.')]
    param(
        [Parameter(
            Mandatory,
            ValueFromPipeline)]
        [AllowNull()]
        [AllowEmptyCollection()]
        [PSCustomObject[]] $InputObject,

        [ValidateNotNullOrEmpty()]
        [string] $TypeName = $script:GitHubBranchProtectionRuleTypeName
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

            if ($item.url -match "^https?://(?:www\.|api\.|)$hostName/repos/(?:[^/]+)/(?:[^/]+)/branches/([^/]+)/.*$")
            {
                Add-Member -InputObject $item -Name 'BranchName' -Value $Matches[1] -MemberType NoteProperty -Force
            }
        }

        Write-Output $item
    }
}

filter Add-GitHubBranchPatternProtectionRuleAdditionalProperties
{
    <#
    .SYNOPSIS
        Adds type name and additional properties to ease pipelining to GitHub Branch Pattern Protection Rule objects.

    .PARAMETER InputObject
        The GitHub object to add additional properties to.

    .PARAMETER TypeName
        The type that should be assigned to the object.

    .INPUTS
        PSCustomObject

    .OUTPUTS
        GitHub.BranchPatternProtection Rule
#>
    [CmdletBinding()]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseSingularNouns', '',
        Justification = 'Internal helper that is definitely adding more than one property.')]
    param(
        [Parameter(
            Mandatory,
            ValueFromPipeline)]
        [AllowNull()]
        [AllowEmptyCollection()]
        [PSCustomObject[]] $InputObject,

        [ValidateNotNullOrEmpty()]
        [string] $TypeName = $script:GitHubBranchPatternProtectionRuleTypeName
    )

    foreach ($item in $InputObject)
    {
        $item.PSObject.TypeNames.Insert(0, $TypeName)

        if (-not (Get-GitHubConfiguration -Name DisablePipelineSupport))
        {
            $elements = Split-GitHubUri -Uri $item.repository.url
            $repositoryUrl = Join-GitHubUri @elements
            Add-Member -InputObject $item -Name 'RepositoryUrl' -Value $repositoryUrl -MemberType NoteProperty -Force
        }

        $restrictPushApps = @()
        $restrictPushTeams = @()
        $restrictPushUsers = @()

        foreach ($actor in $item.pushAllowances.nodes.actor)
        {
            if ($actor.__typename -eq 'App')
            {
                $restrictPushApps += $actor.name
            }
            elseif ($actor.__typename -eq 'Team')
            {
                $restrictPushTeams += $actor.name
            }
            elseif ($actor.__typename -eq 'User')
            {
                $restrictPushUsers += $actor.login
            }
            else
            {
                Write-Log -Message "Unknown restrict push actor type found $($actor.__typename). Ignoring" -Level Warning
            }
        }

        Add-Member -InputObject $item -Name 'RestrictPushApps' -Value $restrictPushApps -MemberType NoteProperty -Force
        Add-Member -InputObject $item -Name 'RestrictPushTeams' -Value $restrictPushTeams -MemberType NoteProperty -Force
        Add-Member -InputObject $item -Name 'RestrictPushUsers' -Value $restrictPushUsers -MemberType NoteProperty -Force

        $dismissalTeams = @()
        $dismissalUsers = @()

        foreach ($actor in $item.reviewDismissalAllowances.nodes.actor)
        {
            if ($actor.__typename -eq 'Team')
            {
                $dismissalTeams += $actor.name
            }
            elseif ($actor.__typename -eq 'User')
            {
                $dismissalUsers += $actor.login
            }
            else
            {
                Write-Log -Message "Unknown dismissal actor type found $($actor.__typename). Ignoring" -Level Warning
            }
        }

        Add-Member -InputObject $item -Name 'DismissalTeams' -Value $dismissalTeams -MemberType NoteProperty -Force
        Add-Member -InputObject $item -Name 'DismissalUsers' -Value $dismissalUsers -MemberType NoteProperty -Force

        Write-Output $item
    }
}
