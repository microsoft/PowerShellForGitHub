# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

@{
    GitHubBranchTypeName = 'GitHub.Branch'
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
        GitHub.Release
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
        'Description' =  "Getting branches for $RepositoryName"
        'AccessToken' = $AccessToken
        'TelemetryEventName' = $MyInvocation.MyCommand.Name
        'TelemetryProperties' = $telemetryProperties
        'NoStatus' = (Resolve-ParameterWithDefaultConfigurationValue -Name NoStatus -ConfigValueName DefaultNoStatus)
    }

    return (Invoke-GHRestMethodMultipleResult @params | Add-GitHubBranchAdditionalProperties)
}

function Get-GitHubRepositoryBranchProtectionRule
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
        None

    .OUTPUTS
        PSCustomObject

    .EXAMPLE
        Get-GitHubRepositoryBranchProtectionRule  -Name master -OwnerName Microsoft -RepositoryName PowerShellForGitHub

        Retrieves branch protection rules for the master branch of the PowerShellForGithub repository.

    .EXAMPLE
        Get-GitHubRepositoryBranchProtectionRule  -Name master -Uri 'https://github.com/PowerShell/PowerShellForGitHub'

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
            Position = 1)]
        [string] $Name,

        [Parameter(
            Mandatory,
            Position = 2,
            ParameterSetName='Uri')]
        [string] $Uri,

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
        UriFragment = "repos/$OwnerName/$RepositoryName/branches/$Name/protection"
        Description =  "Getting branch protection status for $RepositoryName"
        Method = 'Get'
        AcceptHeader = $script:lukeCageAcceptHeader
        AccessToken = $AccessToken
        TelemetryEventName = $MyInvocation.MyCommand.Name
        TelemetryProperties = $telemetryProperties
        NoStatus = (Resolve-ParameterWithDefaultConfigurationValue -Name NoStatus -ConfigValueName DefaultNoStatus)
    }

    return Invoke-GHRestMethod @params
}

function Set-GitHubRepositoryBranchProtectionRule
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
        Require branches to be up to date before merging.

    .PARAMETER EnforceAdmins
        Enforce all configured restrictions for administrators.

    .PARAMETER DismissalUsers
        Specify which users can dismiss pull request reviews.

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

    .PARAMETER RequiredLinearHistory
        Enforces a linear commit Git history, which prevents anyone from pushing merge commits to a
        branch.

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
        None

    .OUTPUTS
        PSCustomObject

    .EXAMPLE
        Set-GitHubRepositoryBranchProtectionRule  -Name master -OwnerName Microsoft -RepositoryName PowerShellForGitHub -EnforceAdmins

        Sets a branch protection rule for the master branch of the PowerShellForGithub repository
        enforcing all configuration restrictions for administrators.

    .EXAMPLE
        Set-GitHubRepositoryBranchProtectionRule  -Name master -Uri 'https://github.com/PowerShell/PowerShellForGitHub' -RequiredApprovingReviewCount 1

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
            Position = 1)]
        [string] $Name,

        [Parameter(
            Mandatory,
            Position = 2,
            ParameterSetName='Uri')]
        [string] $Uri,

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

        [ValidateRange(1,6)]
        [int] $RequiredApprovingReviewCount,

        [string[]] $RestrictPushUsers,

        [string[]] $RestrictPushTeams,

        [string[]] $RestrictPushApps,

        [switch]$RequiredLinearHistory,

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

    if ($PSBoundParameters.ContainsKey('DismissalUsers')) {
       $dismissalRestrictions['users'] = $DismissalUsers }
    if ($PSBoundParameters.ContainsKey('DismissalTeams'))
    {
        $teams = Get-GitHubTeam -OwnerName $OwnerName -RepositoryName $RepositoryName |
            Where-Object -FilterScript { $DismissalTeams -contains $_.name }
        $dismissalRestrictions['teams'] = @($teams.slug)
    }

    $requiredPullRequestReviews = @{}

    if ($PSBoundParameters.ContainsKey('DismissStaleReviews')) {
        $requiredPullRequestReviews['dismiss_stale_reviews'] = $DismissStaleReviews.ToBool() }
    if ($PSBoundParameters.ContainsKey('RequireCodeOwnerReviews')) {
        $requiredPullRequestReviews['require_code_owner_reviews'] = $RequireCodeOwnerReviews.ToBool() }
    if ($PSBoundParameters.ContainsKey('RequiredApprovingReviewCount')) {
        $requiredPullRequestReviews['required_approving_review_count'] = $RequiredApprovingReviewCount }

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
            $RestrictPushTeams = @()
        }

        $restrictions = @{
            users = $RestrictPushUsers
            teams = $RestrictPushTeams
        }

        if ($PSBoundParameters.ContainsKey('RestrictPushApps')) {
            $restrictions['apps'] = $RestrictPushApps }
    }
    else
    {
        $restrictions = $null
    }

    $hashBody = @{
        name = $RepositoryName
        required_status_checks = $requiredStatusChecks
        enforce_admins = $EnforceAdmins.ToBool()
        required_pull_request_reviews = $requiredPullRequestReviews
        restrictions = $restrictions
    }

    if ($PSBoundParameters.ContainsKey('RequiredLinearHistory')) {
        $hashBody['required_linear_history'] = $RequiredLinearHistory.ToBool() }
    if ($PSBoundParameters.ContainsKey('AllowForcePushes')) {
        $hashBody['allow_force_pushes'] = $AllowForcePushes.ToBool() }
    if ($PSBoundParameters.ContainsKey('AllowDeletions')) {
        $hashBody['allow_deletions'] = $AllowDeletions.ToBool() }

    if ($PSCmdlet.ShouldProcess("'$Name' branch of repository '$RepositoryName'",
        'Set GitHub Repository Branch Protection'))
    {
        Write-InvocationLog

        $params = @{
            UriFragment = "repos/$OwnerName/$RepositoryName/branches/$Name/protection"
            Body = (ConvertTo-Json -InputObject $hashBody -Depth 3)
            Description =  "Setting $Name branch protection status for $RepositoryName"
            Method = 'Put'
            AcceptHeader = $script:lukeCageAcceptHeader
            AccessToken = $AccessToken
            TelemetryEventName = $MyInvocation.MyCommand.Name
            TelemetryProperties = $telemetryProperties
            NoStatus = (Resolve-ParameterWithDefaultConfigurationValue -Name NoStatus `
                -ConfigValueName DefaultNoStatus)
        }

        return Invoke-GHRestMethod @params
    }
}

function Remove-GitHubRepositoryBranchProtectionRule
{
<#
    .SYNOPSIS
        Remove branch protection rules for a given GitHub repository.

    .DESCRIPTION
        Remove branch protection rules for a given GitHub repository.

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
        None

    .OUTPUTS
        None

    .EXAMPLE
        Remove-GitHubRepositoryBranchProtectionRule  -Name master -OwnerName Microsoft -RepositoryName PowerShellForGitHub

        Removes branch protection rules from the master branch of the PowerShellForGithub repository.

    .EXAMPLE
        Removes-GitHubRepositoryBranchProtection  -Name master -Uri 'https://github.com/PowerShell/PowerShellForGitHub'

        Removes branch protection rules from the master branch of the PowerShellForGithub repository.

    .EXAMPLE
        Removes-GitHubRepositoryBranchProtection  -Name master -Uri 'https://github.com/PowerShell/PowerShellForGitHub' -Confirm:$false

        Removes branch protection rules from the master branch of the PowerShellForGithub repository
        without prompting for confirmation.

    .EXAMPLE
        Removes-GitHubRepositoryBranchProtection  -Name master -Uri 'https://github.com/PowerShell/PowerShellForGitHub' -Force

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
            Position = 1)]
        [string] $Name,

        [Parameter(
            Mandatory,
            Position = 2,
            ParameterSetName='Uri')]
        [string] $Uri,

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

    if ($PSCmdlet.ShouldProcess("'$Name' branch of repository '$RepositoryName'",
        'Remove GitHub Repository Branch Protection Rule'))
    {
        Write-InvocationLog

        $params = @{
            UriFragment = "repos/$OwnerName/$RepositoryName/branches/$Name/protection"
            Description =  "Removing $Name branch protection rule for $RepositoryName"
            Method = 'Delete'
            AcceptHeader = $script:lukeCageAcceptHeader
            AccessToken = $AccessToken
            TelemetryEventName = $MyInvocation.MyCommand.Name
            TelemetryProperties = $telemetryProperties
            NoStatus = (Resolve-ParameterWithDefaultConfigurationValue -Name NoStatus `
                -ConfigValueName DefaultNoStatus)
        }

        return Invoke-GHRestMethod @params
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
            $elements = Split-GitHubUri -Uri $item.commit.url
            $repositoryUrl = Join-GitHubUri @elements
            Add-Member -InputObject $item -Name 'RepositoryUrl' -Value $repositoryUrl -MemberType NoteProperty -Force

            Add-Member -InputObject $item -Name 'BranchName' -Value $item.name -MemberType NoteProperty -Force
        }

        Write-Output $item
    }
}