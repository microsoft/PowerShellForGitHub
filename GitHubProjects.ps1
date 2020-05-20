# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

function Get-GitHubProject
{
<#
    .DESCRIPTION
        Get the projects for a given Github user, repository or organization.

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

    .PARAMETER NoStatus
        If this switch is specified, long-running commands will run on the main thread
        with no command line status update.  When not specified, those commands run in
        the background, enabling the command prompt to provide status information.
        If not supplied here, the DefaultNoStatus configuration property value will be used.

    .EXAMPLE
        Get-GitHubProject -OwnerName Microsoft -RepositoryName PowerShellForGitHub

        Get the projects for the Microsoft\PowerShellForGitHub repository.

    .EXAMPLE
        Get-GitHubProject -OrganizationName Microsoft

        Get the projects for the Microsoft organization.

    .EXAMPLE
        Get-GitHubProject -Uri https://github.com/Microsoft/PowerShellForGitHub

        Get the projects for the Microsoft\PowerShellForGitHub repository using the Uri.

    .EXAMPLE
        Get-GitHubProject -UserName GitHubUser

        Get the projects for the user GitHubUser.

    .EXAMPLE
        Get-GitHubProject -OwnerName Microsoft -RepositoryName PowerShellForGitHub -State Closed

        Get closed projects from the Microsoft\PowerShellForGitHub repo.

    .EXAMPLE
        Get-GitHubProject -Project 4378613

        Get a project by id, with this parameter you don't need any other information.
#>
    [CmdletBinding(
        SupportsShouldProcess,
        DefaultParameterSetName = 'Elements')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSShouldProcess", "", Justification = "Methods called within here make use of PSShouldProcess, and the switch is passed on to them inherently.")]
    param(
        [Parameter(Mandatory, ParameterSetName = 'Elements')]
        [string] $OwnerName,

        [Parameter(Mandatory, ParameterSetName = 'Elements')]
        [string] $RepositoryName,

        [Parameter(Mandatory, ParameterSetName = 'Uri')]
        [string] $Uri,

        [Parameter(Mandatory, ParameterSetName = 'Organization')]
        [string] $OrganizationName,

        [Parameter(Mandatory, ParameterSetName = 'User')]
        [string] $UserName,

        [Parameter(Mandatory, ParameterSetName = 'Project')]
        [int64] $Project,

        [ValidateSet('Open', 'Closed', 'All')]
        [string] $State,

        [string] $AccessToken,

        [switch] $NoStatus
    )

    Write-InvocationLog

    $telemetryProperties = @{}

    $uriFragment = [String]::Empty
    $description = [String]::Empty
    if ($PSCmdlet.ParameterSetName -eq 'Project')
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
        'NoStatus' = (Resolve-ParameterWithDefaultConfigurationValue -Name NoStatus -ConfigValueName DefaultNoStatus)
        'AcceptHeader' = 'application/vnd.github.inertia-preview+json'
    }

    return Invoke-GHRestMethodMultipleResult @params

}

function New-GitHubProject
{
<#
    .DESCRIPTION
        Creates a new Github project for the given repository

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

    .PARAMETER NoStatus
        If this switch is specified, long-running commands will run on the main thread
        with no command line status update.  When not specified, those commands run in
        the background, enabling the command prompt to provide status information.
        If not supplied here, the DefaultNoStatus configuration property value will be used.

    .EXAMPLE
        New-GitHubProject -OwnerName Microsoft -RepositoryName PowerShellForGitHub -Name TestProject

        Creates a project called 'TestProject' for the Microsoft\PowerShellForGitHub repository.

    .EXAMPLE
        New-GitHubProject -OrganizationName Microsoft -Name TestProject -Description 'This is just a test project'

        Create a project for the Microsoft organization called 'TestProject' with a description.

    .EXAMPLE
        New-GitHubProject -Uri https://github.com/Microsoft/PowerShellForGitHub -Name TestProject

        Create a project for the Microsoft\PowerShellForGitHub repository using the Uri called 'TestProject'.

    .EXAMPLE
        New-GitHubProject -UserProject -Name 'TestProject'

        Creates a project for the signed in user called 'TestProject'.
#>
    [CmdletBinding(
        SupportsShouldProcess,
        DefaultParameterSetName = 'Elements')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSShouldProcess", "", Justification = "Methods called within here make use of PSShouldProcess, and the switch is passed on to them inherently.")]
    param(
        [Parameter(Mandatory, ParameterSetName = 'Elements')]
        [string] $OwnerName,

        [Parameter(Mandatory, ParameterSetName = 'Elements')]
        [string] $RepositoryName,

        [Parameter(Mandatory, ParameterSetName = 'Uri')]
        [string] $Uri,

        [Parameter(Mandatory, ParameterSetName = 'Organization')]
        [string] $OrganizationName,

        [Parameter(Mandatory, ParameterSetName = 'User')]
        [switch] $UserProject,

        [Parameter(Mandatory)]
        [string] $Name,

        [string] $Description,

        [string] $AccessToken,

        [switch] $NoStatus
    )

    Write-InvocationLog

    $telemetryProperties = @{}
    $telemetryProperties['Name'] = Get-PiiSafeString -PlainText $Name

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
        'name' = $Name
    }

    if ($PSBoundParameters.ContainsKey('Description'))
    {
        $hashBody.add('body', $Description)
    }

    $params = @{
        'UriFragment' = $uriFragment
        'Body' = (ConvertTo-Json -InputObject $hashBody)
        'Method' = 'Post'
        'Description' = $apiDescription
        'AccessToken' = $AccessToken
        'TelemetryEventName' = $MyInvocation.MyCommand.Name
        'TelemetryProperties' = $telemetryProperties
        'NoStatus' = (Resolve-ParameterWithDefaultConfigurationValue -Name NoStatus -ConfigValueName DefaultNoStatus)
        'AcceptHeader' = 'application/vnd.github.inertia-preview+json'
    }

    return Invoke-GHRestMethod @params
}

function Set-GitHubProject
{
<#
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

    .PARAMETER AccessToken
        If provided, this will be used as the AccessToken for authentication with the
        REST Api.  Otherwise, will attempt to use the configured value or will run unauthenticated.

    .PARAMETER NoStatus
        If this switch is specified, long-running commands will run on the main thread
        with no command line status update.  When not specified, those commands run in
        the background, enabling the command prompt to provide status information.
        If not supplied here, the DefaultNoStatus configuration property value will be used.

    .EXAMPLE
        Set-GitHubProject -Project 999999 -State Closed

        Set the project with ID '999999' to closed.

    .EXAMPLE
        $project = Get-GitHubProject -OwnerName Microsoft -RepositoryName PowerShellForGitHub | Where-Object Name -eq 'TestProject'
        Set-GitHubProject -Project $project.id -State Closed

        Get the ID for the 'TestProject' project for the Microsoft\PowerShellForGitHub
        repository and set state to closed.
#>
    [CmdletBinding(
        SupportsShouldProcess)]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSShouldProcess", "", Justification = "Methods called within here make use of PSShouldProcess, and the switch is passed on to them inherently.")]
    param(
        [Parameter(Mandatory)]
        [int64] $Project,

        [string] $Description,

        [ValidateSet('Open', 'Closed')]
        [string] $State,

        [ValidateSet('Read', 'Write', 'Admin', 'None')]
        [string] $OrganizationPermission,

        [switch] $Private,

        [string] $AccessToken,

        [switch] $NoStatus
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

    $params = @{
        'UriFragment' = $uriFragment
        'Description' = $apiDescription
        'Body' = (ConvertTo-Json -InputObject $hashBody)
        'AccessToken' = $AccessToken
        'Method' = 'Patch'
        'TelemetryEventName' = $MyInvocation.MyCommand.Name
        'TelemetryProperties' = $telemetryProperties
        'NoStatus' = (Resolve-ParameterWithDefaultConfigurationValue -Name NoStatus -ConfigValueName DefaultNoStatus)
        'AcceptHeader' = 'application/vnd.github.inertia-preview+json'
    }

    return Invoke-GHRestMethod @params
}

function Remove-GitHubProject
{
<#
    .DESCRIPTION
        Removes the projects for a given Github repository.

        The Git repo for this module can be found here: http://aka.ms/PowerShellForGitHub

    .PARAMETER Project
        ID of the project to remove.

    .PARAMETER AccessToken
        If provided, this will be used as the AccessToken for authentication with the
        REST Api.  Otherwise, will attempt to use the configured value or will run unauthenticated.

    .PARAMETER NoStatus
        If this switch is specified, long-running commands will run on the main thread
        with no command line status update.  When not specified, those commands run in
        the background, enabling the command prompt to provide status information.
        If not supplied here, the DefaultNoStatus configuration property value will be used.

    .EXAMPLE
        Remove-GitHubProject -Project 4387531

        Remove project with ID '4387531'.

    .EXAMPLE
        Remove-GitHubProject -Project 4387531 -Confirm:$false

        Remove project with ID '4387531' without prompting for confirmation.

    .EXAMPLE
        $project = Get-GitHubProject -OwnerName Microsoft -RepositoryName PowerShellForGitHub | Where-Object Name -eq 'TestProject'
        Remove-GitHubProject -Project $project.id

        Get the ID for the 'TestProject' project for the Microsoft\PowerShellForGitHub
        repository and then remove the project.
#>
    [CmdletBinding(
        SupportsShouldProcess,
        ConfirmImpact = 'High')]
    [Alias('Delete-GitHubProject')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSShouldProcess", "", Justification = "Methods called within here make use of PSShouldProcess, and the switch is passed on to them inherently.")]
    param(
        [Parameter(Mandatory)]
        [int64] $Project,

        [string] $AccessToken,

        [switch] $NoStatus
    )

    Write-InvocationLog

    $telemetryProperties = @{}

    $uriFragment = "projects/$Project"
    $description = "Deleting project $Project"

    if ($PSCmdlet.ShouldProcess($project, "Remove project"))
    {
        $params = @{
            'UriFragment' = $uriFragment
            'Description' = $description
            'AccessToken' = $AccessToken
            'Method' = 'Delete'
            'TelemetryEventName' = $MyInvocation.MyCommand.Name
            'TelemetryProperties' = $telemetryProperties
            'NoStatus' = (Resolve-ParameterWithDefaultConfigurationValue -Name NoStatus -ConfigValueName DefaultNoStatus)
            'AcceptHeader' = 'application/vnd.github.inertia-preview+json'
        }

        return Invoke-GHRestMethod @params
    }

}
