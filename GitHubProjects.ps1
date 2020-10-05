# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

@{
    GitHubProjectTypeName = 'GitHub.Project'
 }.GetEnumerator() | ForEach-Object {
     Set-Variable -Scope Script -Option ReadOnly -Name $_.Key -Value $_.Value
 }

filter Get-GitHubProject
{
<#
    .SYNOPSIS
        Get the projects for a given GitHub user, repository or organization.

    .DESCRIPTION
        Get the projects for a given GitHub user, repository or organization.

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
        The name of the organization to get projects for.

    .PARAMETER UserName
        The name of the user to get projects for.

    .PARAMETER Project
        ID of the project to retrieve.

    .PARAMETER State
        Only projects with this state are returned.

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
        GitHub.Project

    .EXAMPLE
        Get-GitHubProject -OwnerName microsoft -RepositoryName PowerShellForGitHub

        Get the projects for the microsoft\PowerShellForGitHub repository.

    .EXAMPLE
        Get-GitHubProject -OrganizationName Microsoft

        Get the projects for the Microsoft organization.

    .EXAMPLE
        Get-GitHubProject -Uri https://github.com/Microsoft/PowerShellForGitHub

        Get the projects for the microsoft\PowerShellForGitHub repository using the Uri.

    .EXAMPLE
        Get-GitHubProject -UserName GitHubUser

        Get the projects for the user GitHubUser.

    .EXAMPLE
        Get-GitHubProject -OwnerName microsoft -RepositoryName PowerShellForGitHub -State Closed

        Get closed projects from the microsoft\PowerShellForGitHub repo.

    .EXAMPLE
        Get-GitHubProject -Project 4378613

        Get a project by id, with this parameter you don't need any other information.
#>
    [CmdletBinding(DefaultParameterSetName = 'Elements')]
    [OutputType({$script:GitHubPullRequestTypeName})]
    param(
        [Parameter(
            Mandatory,
            ParameterSetName = 'Elements')]
        [string] $OwnerName,

        [Parameter(
            Mandatory,
            ParameterSetName = 'Elements')]
        [string] $RepositoryName,

        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName='Uri')]
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName='ProjectObject')]
        [Alias('RepositoryUrl')]
        [string] $Uri,

        [Parameter(
            Mandatory,
            ParameterSetName = 'Organization')]
        [string] $OrganizationName,

        [Parameter(
            Mandatory,
            ParameterSetName = 'User')]
        [string] $UserName,

        [Parameter(
            Mandatory,
            ValueFromPipeline,
            ValueFromPipelineByPropertyName,
            ParameterSetName = 'Project')]
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName='ProjectObject')]
        [Alias('ProjectId')]
        [int64] $Project,

        [ValidateSet('Open', 'Closed', 'All')]
        [string] $State,

        [string] $AccessToken
    )

    Write-InvocationLog

    $telemetryProperties = @{}

    $uriFragment = [String]::Empty
    $description = [String]::Empty
    if ($PSCmdlet.ParameterSetName -in @('Project', 'ProjectObject'))
    {
        $telemetryProperties['Project'] = Get-PiiSafeString -PlainText $Project

        $uriFragment = "/projects/$Project"
        $description = "Getting project $project"
    }
    elseif ($PSCmdlet.ParameterSetName -in ('Elements', 'Uri'))
    {
        $elements = Resolve-RepositoryElements
        $OwnerName = $elements.ownerName
        $RepositoryName = $elements.repositoryName

        $telemetryProperties['OwnerName'] = Get-PiiSafeString -PlainText $OwnerName
        $telemetryProperties['RepositoryName'] = Get-PiiSafeString -PlainText $RepositoryName

        $uriFragment = "/repos/$OwnerName/$RepositoryName/projects"
        $description = "Getting projects for $RepositoryName"
    }
    elseif ($PSCmdlet.ParameterSetName -eq 'Organization')
    {
        $telemetryProperties['OrganizationName'] = Get-PiiSafeString -PlainText $OrganizationName

        $uriFragment = "/orgs/$OrganizationName/projects"
        $description = "Getting projects for $OrganizationName"
    }
    elseif ($PSCmdlet.ParameterSetName -eq 'User')
    {
        $telemetryProperties['UserName'] = Get-PiiSafeString -PlainText $UserName

        $uriFragment = "/users/$UserName/projects"
        $description = "Getting projects for $UserName"
    }

    if ($PSBoundParameters.ContainsKey('State'))
    {
        $getParams = @()
        $State = $State.ToLower()
        $getParams += "state=$State"

        $uriFragment = "$uriFragment`?" + ($getParams -join '&')
        $description += " with state '$state'"
    }

    $params = @{
        'UriFragment' = $uriFragment
        'Description' = $description
        'AccessToken' = $AccessToken
        'TelemetryEventName' = $MyInvocation.MyCommand.Name
        'TelemetryProperties' = $telemetryProperties
        'AcceptHeader' = $script:inertiaAcceptHeader
    }

    return (Invoke-GHRestMethodMultipleResult @params | Add-GitHubProjectAdditionalProperties)

}

filter New-GitHubProject
{
<#
    .SYNOPSIS
        Creates a new GitHub project for the given repository.

    .DESCRIPTION
        Creates a new GitHub project for the given repository.

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
        The name of the organization to create the project under.

    .PARAMETER UserProject
        If this switch is specified creates a project for your user.

    .PARAMETER Name
        The name of the project to create.

    .PARAMETER Description
        Short description for the new project.

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
        GitHub.Project

    .EXAMPLE
        New-GitHubProject -OwnerName microsoft -RepositoryName PowerShellForGitHub -ProjectName TestProject

        Creates a project called 'TestProject' for the microsoft\PowerShellForGitHub repository.

    .EXAMPLE
        New-GitHubProject -OrganizationName Microsoft -ProjectName TestProject -Description 'This is just a test project'

        Create a project for the Microsoft organization called 'TestProject' with a description.

    .EXAMPLE
        New-GitHubProject -Uri https://github.com/Microsoft/PowerShellForGitHub -ProjectName TestProject

        Create a project for the microsoft\PowerShellForGitHub repository
        using the Uri called 'TestProject'.

    .EXAMPLE
        New-GitHubProject -UserProject -ProjectName 'TestProject'

        Creates a project for the signed in user called 'TestProject'.
#>
    [CmdletBinding(
        SupportsShouldProcess,
        DefaultParameterSetName = 'Elements')]
    [OutputType({$script:GitHubPullRequestTypeName})]
    param(
        [Parameter(
            Mandatory,
            ParameterSetName = 'Elements')]
        [string] $OwnerName,

        [Parameter(
            Mandatory,
            ParameterSetName = 'Elements')]
        [string] $RepositoryName,

        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName='Uri')]
        [Alias('RepositoryUrl')]
        [string] $Uri,

        [Parameter(
            Mandatory,
            ParameterSetName = 'Organization')]
        [string] $OrganizationName,

        [Parameter(
            Mandatory,
            ParameterSetName = 'User')]
        [switch] $UserProject,

        [Parameter(
            Mandatory,
            ValueFromPipeline)]
        [Alias('Name')]
        [string] $ProjectName,

        [string] $Description,

        [string] $AccessToken
    )

    Write-InvocationLog

    $telemetryProperties = @{}
    $telemetryProperties['ProjectName'] = Get-PiiSafeString -PlainText $ProjectName

    $uriFragment = [String]::Empty
    $apiDescription = [String]::Empty
    if ($PSCmdlet.ParameterSetName -in ('Elements', 'Uri'))
    {
        $elements = Resolve-RepositoryElements
        $OwnerName = $elements.ownerName
        $RepositoryName = $elements.repositoryName

        $telemetryProperties['OwnerName'] = Get-PiiSafeString -PlainText $OwnerName
        $telemetryProperties['RepositoryName'] = Get-PiiSafeString -PlainText $RepositoryName

        $uriFragment = "/repos/$OwnerName/$RepositoryName/projects"
        $apiDescription = "Creating project for $RepositoryName"
    }
    elseif ($PSCmdlet.ParameterSetName -eq 'Organization')
    {
        $telemetryProperties['OrganizationName'] = Get-PiiSafeString -PlainText $OrganizationName

        $uriFragment = "/orgs/$OrganizationName/projects"
        $apiDescription = "Creating project for $OrganizationName"
    }
    elseif ($PSCmdlet.ParameterSetName -eq 'User')
    {
        $telemetryProperties['User'] = $true

        $uriFragment = "/user/projects"
        $apiDescription = "Creating project for user"
    }

    $hashBody = @{
        'name' = $ProjectName
    }

    if ($PSBoundParameters.ContainsKey('Description'))
    {
        $hashBody.add('body', $Description)
    }

    if (-not $PSCmdlet.ShouldProcess($ProjectName, 'Create GitHub Project'))
    {
        return
    }

    $params = @{
        'UriFragment' = $uriFragment
        'Body' = (ConvertTo-Json -InputObject $hashBody)
        'Method' = 'Post'
        'Description' = $apiDescription
        'AccessToken' = $AccessToken
        'TelemetryEventName' = $MyInvocation.MyCommand.Name
        'TelemetryProperties' = $telemetryProperties
        'AcceptHeader' = $script:inertiaAcceptHeader
    }

    return (Invoke-GHRestMethod @params | Add-GitHubProjectAdditionalProperties)
}

filter Set-GitHubProject
{
<#
    .SYNOPSIS
        Modify a GitHub Project.

    .DESCRIPTION
        Modify a GitHub Project.

        The Git repo for this module can be found here: http://aka.ms/PowerShellForGitHub

    .PARAMETER Project
        ID of the project to modify.

    .PARAMETER Description
        Short description for the project.

    .PARAMETER State
        Set the state of the project.

    .PARAMETER OrganizationPermission
        Set the permission level that determines whether all members of the project's
        organization can see and/or make changes to the project.
        Only available for organization projects.

    .PARAMETER Private
        Sets the visibility of a project board.
        Only available for organization and user projects.
        Note: Updating a project's visibility requires admin access to the project.

    .PARAMETER PassThru
        Returns the updated Project.  By default, this cmdlet does not generate any output.
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
        GitHub.Release
        GitHub.ReleaseAsset
        GitHub.Repository

    .OUTPUTS
        GitHub.Project

    .EXAMPLE
        Set-GitHubProject -Project 999999 -State Closed

        Set the project with ID '999999' to closed.

    .EXAMPLE
        $project = Get-GitHubProject -OwnerName microsoft -RepositoryName PowerShellForGitHub | Where-Object Name -eq 'TestProject'
        Set-GitHubProject -Project $project.id -State Closed

        Get the ID for the 'TestProject' project for the microsoft\PowerShellForGitHub
        repository and set state to closed.
#>
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType({$script:GitHubPullRequestTypeName})]
    param(
        [Parameter(
            Mandatory,
            ValueFromPipeline,
            ValueFromPipelineByPropertyName)]
        [Alias('ProjectId')]
        [int64] $Project,

        [string] $Description,

        [ValidateSet('Open', 'Closed')]
        [string] $State,

        [ValidateSet('Read', 'Write', 'Admin', 'None')]
        [string] $OrganizationPermission,

        [switch] $Private,

        [switch] $PassThru,

        [string] $AccessToken
    )

    Write-InvocationLog

    $telemetryProperties = @{}

    $uriFragment = "projects/$Project"
    $apiDescription = "Updating project $Project"

    $hashBody = @{}

    if ($PSBoundParameters.ContainsKey('Description'))
    {
        $hashBody.add('body', $Description)
        $apiDescription += " description"
    }

    if ($PSBoundParameters.ContainsKey('State'))
    {
        $hashBody.add('state', $State)
        $apiDescription += ", state to '$State'"
    }

    if ($PSBoundParameters.ContainsKey('Private'))
    {
       $hashBody.add('private', $Private.ToBool())
       $apiDescription += ", private to '$Private'"
    }

    if ($PSBoundParameters.ContainsKey('OrganizationPermission'))
    {
        $hashBody.add('organization_permission', $OrganizationPermission.ToLower())
        $apiDescription += ", organization_permission to '$OrganizationPermission'"
    }

    if (-not $PSCmdlet.ShouldProcess($Project, 'Set GitHub Project'))
    {
        return
    }

    $params = @{
        'UriFragment' = $uriFragment
        'Description' = $apiDescription
        'Body' = (ConvertTo-Json -InputObject $hashBody)
        'AccessToken' = $AccessToken
        'Method' = 'Patch'
        'TelemetryEventName' = $MyInvocation.MyCommand.Name
        'TelemetryProperties' = $telemetryProperties
        'AcceptHeader' = $script:inertiaAcceptHeader
    }

    $result = (Invoke-GHRestMethod @params | Add-GitHubProjectAdditionalProperties)
    if (Resolve-ParameterWithDefaultConfigurationValue -Name PassThru -ConfigValueName DefaultPassThru)
    {
        return $result
    }
}

filter Remove-GitHubProject
{
<#
    .SYNOPSIS
        Removes the projects for a given GitHub repository.

    .DESCRIPTION
        Removes the projects for a given GitHub repository.

        The Git repo for this module can be found here: http://aka.ms/PowerShellForGitHub

    .PARAMETER Project
        ID of the project to remove.

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
        GitHub.ReleaseAsset
        GitHub.Repository

    .EXAMPLE
        Remove-GitHubProject -Project 4387531

        Remove project with ID '4387531'.

    .EXAMPLE
        Remove-GitHubProject -Project 4387531 -Confirm:$false

        Remove project with ID '4387531' without prompting for confirmation.

    .EXAMPLE
        Remove-GitHubProject -Project 4387531 -Force

        Remove project with ID '4387531' without prompting for confirmation.

    .EXAMPLE
        $project = Get-GitHubProject -OwnerName microsoft -RepositoryName PowerShellForGitHub | Where-Object Name -eq 'TestProject'
        Remove-GitHubProject -Project $project.id

        Get the ID for the 'TestProject' project for the microsoft\PowerShellForGitHub
        repository and then remove the project.
#>
    [CmdletBinding(
        SupportsShouldProcess,
        ConfirmImpact = 'High')]
    [Alias('Delete-GitHubProject')]
    param(
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName)]
        [Alias('ProjectId')]
        [int64] $Project,

        [switch] $Force,

        [string] $AccessToken
    )

    Write-InvocationLog

    $telemetryProperties = @{}

    $uriFragment = "projects/$Project"
    $description = "Deleting project $Project"

    if ($Force -and (-not $Confirm))
    {
        $ConfirmPreference = 'None'
    }

    if (-not $PSCmdlet.ShouldProcess($Project, 'Remove GitHub Project'))
    {
        return
    }

    $params = @{
        'UriFragment' = $uriFragment
        'Description' = $description
        'AccessToken' = $AccessToken
        'Method' = 'Delete'
        'TelemetryEventName' = $MyInvocation.MyCommand.Name
        'TelemetryProperties' = $telemetryProperties
        'AcceptHeader' = $script:inertiaAcceptHeader
    }

    return Invoke-GHRestMethod @params
}

filter Add-GitHubProjectAdditionalProperties
{
<#
    .SYNOPSIS
        Adds type name and additional properties to ease pipelining to GitHub Project objects.

    .PARAMETER InputObject
        The GitHub object to add additional properties to.

    .PARAMETER TypeName
        The type that should be assigned to the object.

    .INPUTS
        [PSCustomObject]

    .OUTPUTS
        GitHub.Project
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
        [string] $TypeName = $script:GitHubProjectTypeName
    )

    foreach ($item in $InputObject)
    {
        $item.PSObject.TypeNames.Insert(0, $TypeName)

        if (-not (Get-GitHubConfiguration -Name DisablePipelineSupport))
        {
            $elements = Split-GitHubUri -Uri $item.html_url
            $repositoryUrl = Join-GitHubUri @elements

            # A "user" project has no associated repository, and adding this in that scenario
            # would cause API-level errors with piping further on,
            if ($elements.OwnerName -ne 'users')
            {
                Add-Member -InputObject $item -Name 'RepositoryUrl' -Value $repositoryUrl -MemberType NoteProperty -Force
            }

            Add-Member -InputObject $item -Name 'ProjectId' -Value $item.id -MemberType NoteProperty -Force

            if ($null -ne $item.creator)
            {
                $null = Add-GitHubUserAdditionalProperties -InputObject $item.creator
            }
        }

        Write-Output $item
    }
}
