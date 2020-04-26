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

    .PARAMETER Name
        The name of the project to retrieve.

    .PARAMETER Project
        Id of the project to retrieve.

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
        Get-GitHubProject -OrganizationName Microsoft -Name TeamCloud

        Get a specific project by name from the Microsoft organization.

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

        [Parameter()]
        [string] $Name,

        [Parameter(Mandatory, ParameterSetName = 'Project')]
        [int64] $Project,

        [Parameter(ParameterSetName = 'Elements')]
        [Parameter(ParameterSetName = 'Organization')]
        [Parameter(ParameterSetName = 'User')]
        [Parameter(ParameterSetName = 'Uri')]
        [ValidateSet('Open', 'Closed', 'All')]
        [string] $State,

        [Parameter()]
        [string] $AccessToken,

        [Parameter()]
        [switch] $NoStatus
    )

    Write-InvocationLog

    $telemetryProperties = @{}

    $uriFragment = [String]::Empty
    $description = [String]::Empty
    if ($PSCmdlet.ParameterSetName -eq 'Project')
    {

        $telemetryProperties['Project'] = $Project

        $uriFragment = "/projects/$Project"
        $description = "Getting project $project"
    }
    else
    {
        if ($PSCmdlet.ParameterSetName -in ('Elements', 'Uri'))
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

        if ($PSBoundParameters.ContainsKey('Project'))
        {
            $uriFragment = "$uriFragment/$Project"
            $description = "Getting project $Project"
        }
        elseif ($PSBoundParameters.ContainsKey('State'))
        {
            $getParams = @()
            $State = $State.ToLower()
            $getParams += "state=$State"

            $uriFragment = "$uriFragment`?" + ($getParams -join '&')
            $description = "Getting projects for $RepositoryName"
        }
    }

    $params = @{
        'UriFragment' = $uriFragment
        'Description' = $description
        'AccessToken' = $AccessToken
        'Method' = 'Get'
        'TelemetryEventName' = $MyInvocation.MyCommand.Name
        'TelemetryProperties' = $telemetryProperties
        'NoStatus' = (Resolve-ParameterWithDefaultConfigurationValue -Name NoStatus -ConfigValueName DefaultNoStatus)
        'AcceptHeader' = 'application/vnd.github.inertia-preview+json'
    }

    $results = Invoke-GHRestMethod @params

    if ($PSBoundParameters.ContainsKey('Name'))
    {
        $results | Where-Object Name -eq $Name
    }
    else
    {
        $results
    }
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
        New-GitHubProject -UserProject -Name TestProject'

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

        [Parameter()]
        [string] $Description,

        [Parameter()]
        [string] $AccessToken,

        [Parameter()]
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
        The name of the organization that owns the project.

    .PARAMETER UserName
        The name of the user that owns the project.

    .PARAMETER Project
        Id of the project to modify.

    .PARAMETER Name
        The name of the project to modify.

    .PARAMETER Description
        Short description for the project.

    .PARAMETER State
        Set the state of the project.

    .PARAMETER OrganizationPermission
        Set the permission level that determines whether all members of the project's
        organization can see and/or make changes to the project.

    .PARAMETER Private
        Sets the visibility of a project board.
        Only available for organization and user projects.

    .PARAMETER AccessToken
        If provided, this will be used as the AccessToken for authentication with the
        REST Api.  Otherwise, will attempt to use the configured value or will run unauthenticated.

    .PARAMETER NoStatus
        If this switch is specified, long-running commands will run on the main thread
        with no command line status update.  When not specified, those commands run in
        the background, enabling the command prompt to provide status information.
        If not supplied here, the DefaultNoStatus configuration property value will be used.

    .EXAMPLE
        Set-GitHubProject -OwnerName Microsoft -RepositoryName PowerShellForGitHub -Name TestProject -State Closed

        Set the 'TestProject' project state to closed for the Microsoft\PowerShellForGitHub
        repository.

    .EXAMPLE
        Set-GitHubProject -OrganizationName Microsoft -Name TestProject -Description 'Updated description'

        Updates the description of the 'TestProject' that's owned by the Microsoft organization.

    .EXAMPLE
        Set-GitHubProject -Uri https://github.com/Microsoft/PowerShellForGitHub -Name TestProject -State Closed

        Updates the state to closed for the Microsoft\PowerShellForGitHub repository project
        by using the uri.

    .EXAMPLE
        Set-GitHubProject -UserName GitHubUser -Name TestProject' -State Closed

        Updates the state to closed for the user project.

#>
    [CmdletBinding(
        SupportsShouldProcess,
        DefaultParameterSetName = 'Elements'
        )]
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

        [Parameter()]
        [string] $Name,

        [Parameter()]
        [string] $Description,

        [Parameter()]
        [ValidateSet('Open', 'Closed')]
        [string] $State,

        [Parameter()]
        [ValidateSet('Read', 'Write', 'Admin', 'None')]
        [string] $OrganizationPermission,

        [Parameter()]
        [bool] $Private,

        [Parameter()]
        [string] $AccessToken,

        [Parameter()]
        [switch] $NoStatus
    )
    Write-InvocationLog

    $telemetryProperties = @{}

    $uriFragment = [String]::Empty
    $apiDescription = [String]::Empty

    if ($PSBoundParameters.ContainsKey('Project'))
    {
        $projectObj = Get-GitHubProject -Project $Project
    }
    else
    {
        $projectDetails = @{}
        foreach ($k in $($PSBoundParameters.Keys))
        {
            if($k -in ('OwnerName','RepositoryName','OrganizationName','UserName','Name','Uri')) {
                $projectDetails[$k] = $PSBoundParameters[$k]
            }
        }

        $projectObj = Get-GitHubProject @projectDetails -State All
        if (-not $projectObj)
        {
            $message = 'Project was not found.'
            Write-Log -Message $message -Level Error
            throw $message
        }
        elseif (($projectObj | Measure-Object).count -ne 1)
        {
            $message = 'More than one project was returned, narrow down the criteria.'
            Write-Log -Message $message -Level Error
            throw $message
        }
    }

    $uriFragment = "projects/$($projectObj.Id)"
    $apiDescription = "Updating project $($projectObj.Id)"

    $hashBody = @{}

    if ($PSBoundParameters.ContainsKey('Description'))
    {
        $hashBody.add('body', $Description)
        $apiDescription = "Updating project $($projectObj.Id)"
    }

    if ($PSBoundParameters.ContainsKey('State'))
    {
        $hashBody.add('state', $State)
        $apiDescription = "Updating project $($projectObj.Id)"
    }

    if ($PSBoundParameters.ContainsKey('Private'))
    {
        if ($projectObj.owner_url.Split('/') -contains ('repos'))
        {
            $message = 'Visibility can only be set for user or organization projects'
            Write-Log -Message $message -Level Error
            throw $message
        }
        else
        {
            $hashBody.add('private', $Private)
            $apiDescription = "Updating project $($projectObj.Id)"
        }
    }

    if ($PSBoundParameters.ContainsKey('OrganizationPermission'))
    {
        if ($projectObj.owner_url.Split('/') -contains ('orgs'))
        {
            $hashBody.add('organization_permission', $OrganizationPermission.ToLower())
            $apiDescription = "Updating project $($projectObj.Id)"
        }
        else
        {
            $message = 'Organization permission can only be set for organization projects'
            Write-Log -Message $message -Level Error
            throw $message
        }
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
        The name of the organization that owns the project.

    .PARAMETER UserName
        The name of the user that owns the project.

    .PARAMETER Project
        Id of the project to remove.

    .PARAMETER Name
        The name of the project to remove.

    .PARAMETER AccessToken
        If provided, this will be used as the AccessToken for authentication with the
        REST Api.  Otherwise, will attempt to use the configured value or will run unauthenticated.

    .PARAMETER NoStatus
        If this switch is specified, long-running commands will run on the main thread
        with no command line status update.  When not specified, those commands run in
        the background, enabling the command prompt to provide status information.
        If not supplied here, the DefaultNoStatus configuration property value will be used.

    .EXAMPLE
        Remove-GitHubProject -OwnerName Microsoft -RepositoryName PowerShellForGitHub -Name TestProject

        Removes the project called 'TestProject' from the Microsoft\PowerShellForGitHub repository.

    .EXAMPLE
        Remove-GitHubProject -OrganizationName Microsoft -Name TestProject

        Removes the project from the Microsoft organization called 'TestProject'.

    .EXAMPLE
        Remove-GitHubProject -Uri https://github.com/Microsoft/PowerShellForGitHub -Name TestProject

        Create a project for the Microsoft\PowerShellForGitHub repository using
        the Uri called 'TestProject'.

    .EXAMPLE
        Remove-GitHubProject -UserName GitHubUser -Name TestProject

        Removes a user project from GitHubUser.

    .EXAMPLE
        Remove-GitHubProject -Project 4387531

        Remove a project by id, with this parameter you don't need any other information.

#>
    [CmdletBinding(
        SupportsShouldProcess,
        DefaultParameterSetName = 'Elements')]
    [Alias('Delete-GitHubProject')]
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

        [string] $Name,

        [Parameter()]
        [string] $AccessToken,

        [Parameter()]
        [switch] $NoStatus
    )

    Write-InvocationLog

    $telemetryProperties = @{}

    $uriFragment = [String]::Empty
    $apiDescription = [String]::Empty

    if ($PSBoundParameters.ContainsKey('Project'))
    {
        $projectObj = Get-GitHubProject -Project $Project
    }
    else
    {
        $projectDetails = @{}
        foreach ($k in $($PSBoundParameters.Keys))
        {
            if($k -in ('OwnerName','RepositoryName','OrganizationName','UserName','Name','Uri'))
            {
                $projectDetails[$k] = $PSBoundParameters[$k]
            }
        }

        $projectObj = Get-GitHubProject @projectDetails -State All
        if (-not $projectObj)
        {
            $message = 'Project was not found.'
            Write-Log -Message $message -Level Error
            throw $message
        }
        elseif (($projectObj | Measure-Object).count -ne 1)
        {
            $message = 'More than one project was returned, narrow down the criteria.'
            Write-Log -Message $message -Level Error
            throw $message
        }
    }

    $uriFragment = "projects/$($projectObj.Id)"
    $apiDescription = "Deleting project $($projectObj.Id)"

    $params = @{
        'UriFragment' = $uriFragment
        'Description' = $apiDescription
        'AccessToken' = $AccessToken
        'Method' = 'Delete'
        'TelemetryEventName' = $MyInvocation.MyCommand.Name
        'TelemetryProperties' = $telemetryProperties
        'NoStatus' = (Resolve-ParameterWithDefaultConfigurationValue -Name NoStatus -ConfigValueName DefaultNoStatus)
        'AcceptHeader' = 'application/vnd.github.inertia-preview+json'
    }

    return Invoke-GHRestMethod @params
}
