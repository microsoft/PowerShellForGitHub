# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.
@{
    GitHubRepositoryAutolinkTypeName = 'GitHub.RepositoryAutolink'
 }.GetEnumerator() | ForEach-Object {
     Set-Variable -Scope Script -Option ReadOnly -Name $_.Key -Value $_.Value
 }

filter Get-GitHubRepositoryAutolink
{
<#
    .SYNOPSIS
        Gets the list of autolinks of the specified GitHub repository.

    .DESCRIPTION
        Gets the list of autolinks of the specified GitHub repository.

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
        Optional, the unique identifier of the autolink to be retrieved

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
        GitHub.RepositoryAutolink

    .EXAMPLE
        Get-GitHubRepositoryAutolink -OwnerName microsoft -RepositoryName PowerShellForGitHub

        Gets all of the autolink references for the microsoft\PowerShellForGitHub repository.

    .EXAMPLE
        Get-GitHubRepositoryAutolink -OwnerName microsoft -RepositoryName PowerShellForGitHub -AutolinkId 42

        Gets autolink reference with autolinkId 42 from the microsoft\PowerShellForGitHub repository.

    .NOTES
        Information about autolinks are only available to repository administrators.
#>
    [CmdletBinding(DefaultParameterSetName = 'Elements')]
    [OutputType({$script:GitHubRepositoryAutolinkTypeName})]
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
            ValueFromPipeline,
            ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [int64] $AutolinkId,

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

    $uriFragment = [String]::Empty
    if ($AutolinkId -gt 0) {
        $uriFragment = "repos/$OwnerName/$RepositoryName/autolinks/$AutolinkId"
    } else {
        $uriFragment = "repos/$OwnerName/$RepositoryName/autolinks"
    }

    $params = @{
        'UriFragment' = $uriFragment + "?" +  ($getParams -join '&')
        'Description' = "Getting all autolinks of $RepositoryName"
        'AccessToken' = $AccessToken
        'TelemetryEventName' = $MyInvocation.MyCommand.Name
        'TelemetryProperties' = $telemetryProperties
    }

    return (Invoke-GHRestMethodMultipleResult @params | Add-GitHubRepositoryAutolinkAdditionalProperties)
}

filter New-GitHubRepositoryAutolink
{
<#
    .SYNOPSIS
        Creates a new autolink on given GitHub repository.

    .DESCRIPTION
        Creates a new autolink on given GitHub repository.

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

    .PARAMETER KeyPrefix
        This prefix appended by certain characters will generate a link any time it is found in
        an issue, pull request, or commit.

    .PARAMETER UrlTemplate
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
        GitHub.RepositoryAutolink

    .EXAMPLE
        New-GitHubRepositoryAutolink -OwnerName microsoft -RepositoryName PowerShellForGitHub -KeyPrefix 'PRJ-' -UrlTemplate 'https://company.issuetracker.com/browse/prj-<num>'

        Creates an autlink reference on this repository under the current authenticated user's account.

    .EXAMPLE
        New-GitHubRepositoryAutolink -OwnerName microsoft -RepositoryName PowerShellForGitHub -OrganizationName OctoLabs -KeyPrefix 'PRJ-' -UrlTemplate 'https://company.issuetracker.com/browse/prj-<num>' -IsNumericOnly

        Creates an autlink reference on this repository under the OctoLabs organization.

    .NOTES
        Only users with admin access to the repository can create an autolink.
#>
    [CmdletBinding(
        SupportsShouldProcess,
        DefaultParameterSetName='Elements')]
    [OutputType({$script:GitHubRepositoryAutolinkTypeName})]
    param(
        [Parameter(ParameterSetName='Elements')]
        [string] $OwnerName,

        [Parameter(ParameterSetName='Elements')]
        [string] $RepositoryName,

        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName)]
        [string] $KeyPrefix,

        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName)]
        [ValidateScript({if ($_ -match '^https?://([^\s,]+<num>)') { $true } else { throw "Target URL invalid or is missing a <num> token." }})]
        [string] $UrlTemplate,

        [Parameter(
            ValueFromPipelineByPropertyName)]
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
        'IsNumericOnly' = $IsNumericOnly.IsPresent
    }

    $hashBody = @{
        'key_prefix' = $KeyPrefix
        'url_template' = $UrlTemplate
        'is_alphanumeric' = (-not $IsNumericOnly.IsPresent)
    }

    if (-not $PSCmdlet.ShouldProcess($KeyPrefix, 'Create Repository Autolink'))
    {
        return
    }

    $params = @{
        'UriFragment' = "repos/$OwnerName/$RepositoryName/autolinks"
        'Body' = (ConvertTo-Json -InputObject $hashBody)
        'Method' = 'Post'
        'Description' = "Repository Autolink $KeyPrefix in $RepositoryName"
        'AcceptHeader' = $script:symmetraAcceptHeader
        'AccessToken' = $AccessToken
        'TelemetryEventName' = $MyInvocation.MyCommand.Name
        'TelemetryProperties' = $telemetryProperties
    }

    return (Invoke-GHRestMethod @params | Add-GitHubRepositoryAutolinkAdditionalProperties)
}

filter Remove-GitHubRepositoryAutolink
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

    .NOTES
        Only users with admin access to the repository can delete an autolink.
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
        [int64] $AutolinkId,

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


filter Add-GitHubRepositoryAutolinkAdditionalProperties
{
<#
    .SYNOPSIS
        Adds type name and additional properties to ease pipelining to GitHub Autolink objects.

    .PARAMETER InputObject
        The GitHub object to add additional properties to.

    .PARAMETER RepositoryUrl
        Optionally supplied if the Autolink object doesn't have this value already.

    .PARAMETER TypeName
        The type that should be assigned to the object.

    .INPUTS
        [PSCustomObject]

    .OUTPUTS
        GitHub.RepositoryAutolink
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
        [string] $TypeName = $script:GitHubRepositoryAutolinkTypeName
    )

    foreach ($item in $InputObject)
    {
        $item.PSObject.TypeNames.Insert(0, $TypeName)

        if (-not (Get-GitHubConfiguration -Name DisablePipelineSupport))
        {
            if ($null -ne $item.id)
            {
                Add-Member -InputObject $item -Name 'AutolinkId' -Value $item.id -MemberType NoteProperty -Force
            }

            Add-Member -InputObject $item -Name 'KeyPrefix' -Value $item.key_prefix -MemberType NoteProperty -Force
            Add-Member -InputObject $item -Name 'UrlTemplate' -Value $item.url_template -MemberType NoteProperty -Force

            Add-Member -InputObject $item -Name 'IsNumericOnly' -Value (-not $item.is_alphanumeric) -MemberType NoteProperty -Force
        }

        Write-Output $item
    }
}