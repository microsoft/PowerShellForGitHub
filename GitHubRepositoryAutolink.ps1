# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

filter Get-GitHubRepositoryAutolink
{
<#
    .SYNOPSIS
        Gets the list of autolinks of the specified repository on GitHub.

    .DESCRIPTION
        Gets the list of autolinks of the specified repository on GitHub.

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

    .PARAMETER Sort
        The sort order for results.

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
        GitHub.Autolink

    .EXAMPLE
        Get-GitHubRepositoryAutolink -OwnerName microsoft -RepositoryName PowerShellForGitHub

        Gets all of the autolink references for the microsoft\PowerShellForGitHub repository.
#>
    [CmdletBinding(DefaultParameterSetName = 'Elements')]
    [OutputType({$script:GitHubRepositoryTypeName})]
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

        [ValidateSet('Newest', 'Oldest', 'Stargazers')]
        [string] $Sort = 'Newest',

        [string] $AccessToken
    )

    Write-InvocationLog

    $elements = Resolve-RepositoryElements
    $OwnerName = $elements.ownerName
    $RepositoryName = $elements.repositoryName

    $telemetryProperties = @{
        'OwnerName' = (Get-PiiSafeString -PlainText $OwnerName)
        'RepositoryName' = (Get-PiiSafeString -PlainText $RepositoryName)
        'Sort' = $Sort
    }

    $getParams = @(
        "sort=$($Sort.ToLower())"
    )

    $params = @{
        'UriFragment' = "repos/$OwnerName/$RepositoryName/autolinks`?" +  ($getParams -join '&')
        'Description' = "Getting all autolinks of $RepositoryName"
        'AccessToken' = $AccessToken
        'TelemetryEventName' = $MyInvocation.MyCommand.Name
        'TelemetryProperties' = $telemetryProperties
    }

    return (Invoke-GHRestMethodMultipleResult @params )
}

function New-GitHubRepositoryAutolink
{
<#
    .SYNOPSIS
        Creates a new autolink on given repository on GitHub.

    .DESCRIPTION
        Creates a new autolink on given repository on GitHub.

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

    .PARAMETER UriPrefix
        This prefix appended by certain characters will generate a link any time it is found in
        an issue, pull request, or commit.

    .PARAMETER Urltemplate
        The URL must contain <num> for the reference number. <num> matches different characters
        depending on the value of is_alphanumeric.

    .PARAMETER IsNumericOnly
        Whether this autolink reference matches numeric characters only.
        If true, the <num> parameter of the url_template matches numeric characters only.
        If false, this autolink reference only matches alphanumeric characters A-Z
        (case insensitive), 0-9, and -.

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
        GitHub.Autolink

    .EXAMPLE
        New-GitHubRepositoryAutolink -OwnerName microsoft -RepositoryName PowerShellForGitHub -UriPrefix PRJ- -Urltemplate https://company.issuetracker.com/browse/prj-<num>

        Creates an autlink reference on this repository under the current authenticated user's account.

    .EXAMPLE
        New-GitHubRepositoryAutolink -OwnerName microsoft -RepositoryName PowerShellForGitHub -OrganizationName OctoLabs -UriPrefix PRJ- -Urltemplate https://company.issuetracker.com/browse/prj-<num> -IsNumericOnly

        Creates an autlink reference on this repository under the OctoLabs organization.
#>
    [CmdletBinding(
        SupportsShouldProcess,
        DefaultParameterSetName='Elements')]
    [OutputType({$script:GitHubRepositoryTypeName})]
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
        #todo [ValidateScript({if ($_ -match '^#?[a-zA-Z0-9.-_+=:\/#]$') { $true } else { throw "Reference prefix must only contain letters, numbers, or .-_+=:/#." }})]
        [string] $UriPrefix,

        [Parameter(Mandatory)]
        #todo [ValidateScript({if ($_ -match '^#?[<num>]$') { $true } else { throw "Target URL is missing a <num> token." }})]
        [string] $Urltemplate,

        [switch] $IsNumericOnly,

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
        'key_prefix' = $UriPrefix
        'url_template' = $Urltemplate
        'is_alphanumeric' = $true
    }

    if ($PSBoundParameters.ContainsKey('IsNumericOnly')) { $hashBody['is_alphanumeric'] = $false }

    if (-not $PSCmdlet.ShouldProcess($UriPrefix, 'Create Repository Autolink'))
    {
        return
    }

    $params = @{
        'UriFragment' = "repos/$OwnerName/$RepositoryName/autolinks"
        'Body' = (ConvertTo-Json -InputObject $hashBody)
        'Method' = 'Post'
        'Description' = "Repository Autolink $UriPrefix in $RepositoryName"
        'AcceptHeader' = $script:symmetraAcceptHeader
        'AccessToken' = $AccessToken
        'TelemetryEventName' = $MyInvocation.MyCommand.Name
        'TelemetryProperties' = $telemetryProperties
    }

    return (Invoke-GHRestMethod @params)
}


function Remove-GitHubRepositoryAutolink
{
<#
    .SYNOPSIS
        Deletes an autolink reference from a given GitHub repository.

    .DESCRIPTION
        Deletes an autolink reference from a given GitHub repository.

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

    .PARAMETER AutolinkId
        The unique identifier of the autolink to be deleted.

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
        GitHub.ReleaseAsset
        GitHub.Repository

    .EXAMPLE
        Remove-GitHubRepositoryAutolink -OwnerName microsoft -RepositoryName PowerShellForGitHub -AutolinkId 1

        Removes the autolink reference with autolinkId 1 from the PowerShellForGitHub project.

    .EXAMPLE
        $autolink = $repo | New-GitHubRepositoryAutolink -KeyPrefix 'PRJ-123'
        $autolink | Remove-GitHubRepositoryAutolink

        Removes the autolink reference we just created using the pipeline, but will prompt for confirmation
        because neither -Confirm:$false nor -Force was specified.

    .EXAMPLE
        Remove-GitHubRepositoryAutolink -OwnerName microsoft -RepositoryName PowerShellForGitHub -AutolinkId 1 -Confirm:$false

        Removes the autolink reference with autolinkId 1 from the PowerShellForGitHub project.
        Will not prompt for confirmation, as -Confirm:$false was specified.

    .EXAMPLE
        Remove-GitHubRepositoryAutolink -OwnerName microsoft -RepositoryName PowerShellForGitHub -AutolinkId 1 -Force

        Removes the autolink reference with autolinkId 1 from the PowerShellForGitHub project.
        Will not prompt for confirmation, as -Force was specified.
#>
    [CmdletBinding(
        SupportsShouldProcess,
        DefaultParameterSetName='Elements',
        ConfirmImpact="High")]
    [Alias('Delete-GitHubRepositoryAutolink')]
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
        [string] $AutolinkId,

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

    if (-not $PSCmdlet.ShouldProcess($Label, 'Remove GitHub Repository Autolink Reference'))
    {
        return
    }

    $params = @{
        'UriFragment' = "repos/$OwnerName/$RepositoryName/autolinks/$AutolinkId"
        'Method' = 'Delete'
        'Description' = "Deleting GitHub Autolink Reference $AutolinkId from $RepositoryName"
        'AcceptHeader' = $script:symmetraAcceptHeader
        'AccessToken' = $AccessToken
        'TelemetryEventName' = $MyInvocation.MyCommand.Name
        'TelemetryProperties' = $telemetryProperties
    }

    return Invoke-GHRestMethod @params
}

