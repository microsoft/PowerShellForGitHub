# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

@{
    GitHubDeploymentEnvironmentTypeName = 'GitHub.DeploymentEnvironment'
}.GetEnumerator() | ForEach-Object {
    Set-Variable -Scope Script -Option ReadOnly -Name $_.Key -Value $_.Value
}

filter New-GitHubDeploymentEnvironment
{
    <#
    .SYNOPSIS
        Creates or updates a deployment environment on a GitHub repository.

    .DESCRIPTION
        Creates or updates a deployment environment on a GitHub repository.

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

    .PARAMETER EnvironmentName
        The name of the environment.

    .PARAMETER WaitTimer
        The amount of time to delay a job after the job is initially triggered.
        The time (in minutes) must be an integer between 0 and 43,200 (30 days).

    .PARAMETER DeploymentBranchPolicy
        Whether only branches with branch protection rules or that match the specified name patterns
        can deploy to this environment.

    .PARAMETER ReviewerTeamId
        The teams that may review jobs that reference the environment.
        You can list up to six users and/or teams as reviewers.
        The reviewers must have at least read access to the repository.
        Only one of the required reviewers needs to approve the job for it to proceed.

    .PARAMETER ReviewerUserId
        The users that may review jobs that reference the environment.
        You can list up to six users and/or teams as reviewers.
        The reviewers must have at least read access to the repository.
        Only one of the required reviewers needs to approve the job for it to proceed.

    .PARAMETER PassThru
        Returns the updated environment.  By default, the Set-GitHubDeploymentEnvironment cmdlet
        does not generate any output.
        You can use "Set-GitHubConfiguration -DefaultPassThru" to control the default behavior
        of this switch.

    .PARAMETER AccessToken
        If provided, this will be used as the AccessToken for authentication with the
        REST Api.  Otherwise, will attempt to use the configured value or will run unauthenticated.

    .INPUTS
        GitHub.Branch
        GitHub.Content
        GitHub.DeploymentEnvironment
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
        GitHub.DeploymentEnvironment

    .EXAMPLE
        New-GitHubDeploymentEnvironment -OwnerName microsoft -RepositoryName PowerShellForGitHub -EnvironmentName 'Test'

        Creates or updates a deployment environment called 'Test' for the specified repo.
#>
    [CmdletBinding(
        SupportsShouldProcess,
        DefaultParameterSetName = 'Elements')]
    [OutputType({ $script:GitHubDeploymentEnvironmentTypeName })]
    [Alias('Set-GitHubDeploymentEnvironment')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSReviewUnusedParameter", "", Justification="The Uri parameter is only referenced by Resolve-RepositoryElements which get access to it from the stack via Get-Variable -Scope 1.")]
    param(
        [Parameter(ParameterSetName = 'Elements')]
        [string] $OwnerName,

        [Parameter(ParameterSetName = 'Elements')]
        [string] $RepositoryName,

        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName = 'Uri')]
        [Alias('RepositoryUrl')]
        [string] $Uri,

        [Parameter(
            Mandatory,
            ValueFromPipeline,
            ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [string] $EnvironmentName,

        [ValidateRange(0, 43200)]
        [int32] $WaitTimer,

        [ValidateSet('ProtectedBranches', 'CustomBranchPolicies', 'None')]
        [string] $DeploymentBranchPolicy,

        [int64[]] $ReviewerTeamId,

        [int64[]] $ReviewerUserId,

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

    if ($MyInvocation.InvocationName -eq 'Set-GitHubDeploymentEnvironment')
    {
        $shouldProcessMessage = "Update GitHub Deployment Environment '$EnvironmentName'"
    }
    else
    {
        $shouldProcessMessage = "Create GitHub Deployment Environment '$EnvironmentName'"
    }

    $hashBody = @{}

    if ($PSBoundParameters.ContainsKey('WaitTimer')) { $hashBody['wait_timer'] = $WaitTimer }
    if ($PSBoundParameters.ContainsKey('DeploymentBranchPolicy')) {
        $deploymentBranchPolicyHash = @{}
        switch ($DeploymentBranchPolicy) {
            'ProtectedBranches' {
                $deploymentBranchPolicyHash['protected_branches'] = $true
                $deploymentBranchPolicyHash['custom_branch_policies'] = $false
            }
            'CustomBranchPolicies' {
                $deploymentBranchPolicyHash['protected_branches'] = $false
                $deploymentBranchPolicyHash['custom_branch_policies'] = $true
            }
            'None' {
                $deploymentBranchPolicyHash = $null
            }
        }
        $hashBody['deployment_branch_policy'] = $deploymentBranchPolicyHash
    }
    if ($PSBoundParameters.ContainsKey('ReviewerTeamId') -or
        $PSBoundParameters.ContainsKey('ReviewerUserId'))
    {
        $reviewers = @()
        foreach ($teamId in $ReviewerTeamId) {
            $reviewers += @{ 'type' = 'Team'; 'id' = $teamId}
        }
        foreach ($userId in $ReviewerUserId) {
            $reviewers += @{ 'type' = 'User'; 'id' = $userId}
        }
        $hashBody['reviewers'] = $reviewers
    }

    $params = @{
        'UriFragment' = "repos/$OwnerName/$RepositoryName/environments/$EnvironmentName"
        'Body' = (ConvertTo-Json -InputObject $hashBody)
        'Method' = 'Put'
        'Description' = "Creating Deployment Environment $EnvironmentName"
        'AccessToken' = $AccessToken
        'TelemetryEventName' = $MyInvocation.MyCommand.Name
        'TelemetryProperties' = $telemetryProperties
    }

    Write-Debug -Message ('UriFragment: ' + $params.UriFragment)
    Write-Debug -Message ('Body: ' + $params.Body)

    if (-not $PSCmdlet.ShouldProcess($RepositoryName, $shouldProcessMessage))
    {
        return
    }

    $result = (Invoke-GHRestMethod @params | Add-GitHubDeploymentEnvironmentAdditionalProperties)

    if (($MyInvocation.InvocationName -eq 'New-GitHubDeploymentEnvironment') -or
        (Resolve-ParameterWithDefaultConfigurationValue -Name PassThru -ConfigValueName DefaultPassThru))
    {
        return $result
    }
}

filter Remove-GitHubDeploymentEnvironment
{
<#
    .SYNOPSIS
        Removes a deployment environment from a GitHub repository.

    .DESCRIPTION
        Removes a deployment environment from a GitHub repository.

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

    .PARAMETER EnvironmentName
        The name of the deployment environment to remove.

    .PARAMETER Force
        If this switch is specified, you will not be prompted for confirmation of command execution.

    .PARAMETER AccessToken
        If provided, this will be used as the AccessToken for authentication with the
        REST Api.  Otherwise, will attempt to use the configured value or will run unauthenticated.

    .INPUTS
        GitHub.Branch
        GitHub.Content
        GitHub.DeploymentEnvironment
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
        Remove-GitHubDeploymentEnvironment -OwnerName You -RepositoryName RepoName -EnvironmentName EnvToDelete

    .EXAMPLE
        Remove-GitHubDeploymentEnvironment -Uri https://github.com/You/YourRepo -EnvironmentName EnvToDelete

    .EXAMPLE
        Remove-GitHubDeploymentEnvironment -Uri https://github.com/You/YourRepo -EnvironmentName EnvToDelete -Confirm:$false

        Remove the deployment environment from the repository without prompting for confirmation.

    .EXAMPLE
        Remove-GitHubDeploymentEnvironment -Uri https://github.com/You/YourRepo -EnvironmentName EnvToDelete -Force

        Remove the deployment environment from the repository without prompting for confirmation.

    .EXAMPLE
        $repo = Get-GitHubRepository -Uri https://github.com/You/YourRepo
        $repo | Remove-GitHubDeploymentEnvironment -EnvironmentName EnvToDelete -Force

        You can also pipe in a repo that was returned from a previous command.
#>
    [CmdletBinding(
        SupportsShouldProcess,
        DefaultParameterSetName='Elements',
        ConfirmImpact = 'High')]
    [Alias('Delete-GitHubDeploymentEnvironment')]
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
            ValueFromPipeline,
            ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [string] $EnvironmentName,

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

    $params = @{
        'UriFragment' = "repos/$OwnerName/$RepositoryName/environments/$EnvironmentName"
        'Method' = 'Delete'
        'Description' = "Deleting $EnvironmentName from $RepositoryName"
        'AccessToken' = $AccessToken
        'TelemetryEventName' = $MyInvocation.MyCommand.Name
        'TelemetryProperties' = $telemetryProperties
    }

    Write-Debug -Message ('UriFragment: ' + $params.UriFragment)

    if ($Force -and (-not $Confirm))
    {
        $ConfirmPreference = 'None'
    }

    if (-not $PSCmdlet.ShouldProcess($RepositoryName, "Remove Deployment Environment '$EnvironmentName'"))
    {
        return
    }

    return Invoke-GHRestMethod @params
}

filter Get-GitHubDeploymentEnvironment
{
<#
    .SYNOPSIS
        Retrieves information about a deployment environment or list of deployment environments on GitHub.

    .DESCRIPTION
        Retrieves information about a deployment environment or list of deployment environments on GitHub.

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

    .PARAMETER EnvironmentName
        The name of the deployment environment.

    .PARAMETER AccessToken
        If provided, this will be used as the AccessToken for authentication with the
        REST Api.  Otherwise, will attempt to use the configured value or will run unauthenticated.

    .INPUTS
        GitHub.Branch
        GitHub.Content
        GitHub.DeploymentEnvironment
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
        GitHub.DeploymentEnvironment

    .EXAMPLE
        Get-GitHubDeploymentEnvironment -OwnerName microsoft -RepositoryName PowerShellForGitHub

        Gets details of all of the deployment environments for the specified repository.

    .EXAMPLE
        Get-GitHubDeploymentEnvironment -OwnerName microsoft -RepositoryName PowerShellForGitHub -EnvironmentName Test

        Gets details of the Test deployment environment for the specified repository.
#>
[CmdletBinding(DefaultParameterSetName = 'Elements')]
    [OutputType({$script:GitHubRepositoryTypeName})]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSReviewUnusedParameter", "", Justification="The Uri parameter is only referenced by Resolve-RepositoryElements which get access to it from the stack via Get-Variable -Scope 1.")]
    param(
        [Parameter(
            ValueFromPipelineByPropertyName,
            ParameterSetName='Elements')]
        [Alias('UserName')]
        [string] $OwnerName,

        [Parameter(ParameterSetName='Elements')]
        [string] $RepositoryName,

        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName='Uri')]
        [Alias('RepositoryUrl')]
        [string] $Uri,

        [string] $EnvironmentName,

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

    if ($PSBoundParameters.ContainsKey('EnvironmentName'))
    {
        $uriFragment = "repos/$OwnerName/$RepositoryName/environments/$EnvironmentName"
    }
    else
    {
        $uriFragment = "repos/$OwnerName/$RepositoryName/environments"
    }

    $params = @{
        'UriFragment' = $uriFragment
        'Method' = 'Get'
        'Description' = "Getting $EnvironmentName from $RepositoryName"
        'AccessToken' = $AccessToken
        'TelemetryEventName' = $MyInvocation.MyCommand.Name
        'TelemetryProperties' = $telemetryProperties
    }

    Write-Debug -Message ('UriFragment: ' + $params.UriFragment)

    $result =  Invoke-GHRestMethod @params

    if ($PSBoundParameters.ContainsKey('EnvironmentName'))
    {
        return ($result | Add-GitHubDeploymentEnvironmentAdditionalProperties)
    }
    else
    {
        return ($result.environments | Add-GitHubDeploymentEnvironmentAdditionalProperties)
    }
}

filter Add-GitHubDeploymentEnvironmentAdditionalProperties
{
<#
    .SYNOPSIS
        Adds type name and additional properties to ease pipelining to GitHub Deployment Environment
        objects.

    .PARAMETER InputObject
        The GitHub object to add additional properties to.

    .PARAMETER TypeName
        The type that should be assigned to the object.

    .PARAMETER OwnerName
        Owner of the repository.  This information might be obtainable from InputObject, so this
        is optional based on what InputObject contains.

    .PARAMETER RepositoryName
        Name of the repository.  This information might be obtainable from InputObject, so this
        is optional based on what InputObject contains.

    .INPUTS
        [PSCustomObject]

    .OUTPUTS
        GitHub.Repository
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
        [string] $TypeName = $script:GitHubDeploymentEnvironmentTypeName,

        [string] $OwnerName,

        [string] $RepositoryName
    )

    foreach ($item in $InputObject)
    {
        $item.PSObject.TypeNames.Insert(0, $TypeName)

        if (-not (Get-GitHubConfiguration -Name DisablePipelineSupport))
        {
            $repositoryUrl = [String]::Empty
            if ([String]::IsNullOrEmpty($item.html_url))
            {
                if ($PSBoundParameters.ContainsKey('OwnerName') -and
                    $PSBoundParameters.ContainsKey('RepositoryName'))
                {
                    $repositoryUrl = (Join-GitHubUri -OwnerName $OwnerName -RepositoryName $RepositoryName)
                }
            }
            else
            {
                $elements = Split-GitHubUri -Uri $item.html_url
                $repositoryUrl = Join-GitHubUri @elements
            }

            if (-not [String]::IsNullOrEmpty($repositoryUrl))
            {
                Add-Member -InputObject $item -Name 'RepositoryUrl' -Value $repositoryUrl -MemberType NoteProperty -Force
            }
        }

        Add-Member -InputObject $item -Name 'EnvironmentName' -Value $item.name -MemberType NoteProperty -Force

        # Add additional properties for any user or team reviewers
        if ($null -ne $item.protection_rules)
        {
            foreach ($protectionRule in $item.protection_rules)
            {
                if ($protectionRule.type -eq 'required_reviewers')
                {
                    $reviewerUser = @()
                    $reviewerTeam = @()

                    foreach ($reviewer in $protectionRule.reviewers)
                    {
                        if ($reviewer.type -eq 'User')
                        {
                            $reviewerUser += Add-GitHubUserAdditionalProperties -InputObject $reviewer.reviewer
                        }
                        if ($reviewer.type -eq 'Team')
                        {
                            $reviewerTeam += Add-GitHubTeamAdditionalProperties -InputObject $reviewer.reviewer
                        }
                    }

                    if ($reviewerUser.count -gt 0)
                    {
                        Add-Member -InputObject $item -Name 'ReviewerUser' -Value $reviewerUser -MemberType NoteProperty -Force
                    }

                    if ($reviewerTeam.count -gt 0)
                    {
                        Add-Member -InputObject $item -Name 'ReviewerTeam' -Value $reviewerTeam -MemberType NoteProperty -Force
                    }
                }

                if ($protectionRule.type -eq 'wait_timer')
                {
                    Add-Member -InputObject $item -Name 'WaitTimer' -Value $protectionRule.wait_timer -MemberType NoteProperty -Force
                }
            }
        }

        if ($null -eq $item.deployment_branch_policy)
        {
            $deploymentBranchPolicy = 'None'
        }
        elseif ($item.deployment_branch_policy.protected_branches -eq $true)
        {
            $deploymentBranchPolicy = 'ProtectedBranches'
        }
        elseif ($item.deployment_branch_policy.custom_branch_policies -eq $true)
        {
            $deploymentBranchPolicy = 'CustomBranchPolicies'
        }
        Add-Member -InputObject $item -Name 'DeploymentBranchPolicy' -Value $deploymentBranchPolicy -MemberType NoteProperty -Force

        Write-Output $item
    }
}
