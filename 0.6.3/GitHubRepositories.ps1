# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

function New-GitHubRepository
{
<#
    .SYNOPSIS
        Creates a new repository on GitHub.

    .DESCRIPTION
        Creates a new repository on GitHub.

        The Git repo for this module can be found here: http://aka.ms/PowerShellForGitHub

    .PARAMETER RepositoryName
        Name of the repository to be created.

    .PARAMETER OrganizationName
        Name of the organization that the repository should be created under.
        If not specified, will be created under the current user's account.

    .PARAMETER Description
        A short description of the repository.

    .PARAMETER Homepage
        A URL with more information about the repository.

    .PARAMETER GitIgnoreTemplate
        Desired language or platform .gitignore template to apply.
        For supported values, call Get-GitHubGitIgnore.
        Values are case-sensitive.

    .PARAMETER LicenseTemplate
        Choose an open source license template that best suits your needs.
        For supported values, call Get-GitHubLicense
        Values are case-sensitive.

    .PARAMETER TeamId
        The id of the team that will be granted access to this repository.
        This is only valid when creating a repository in an organization.

    .PARAMETER Private
        By default, this repository will created Public.  Specify this to create
        a private repository.  Creating private repositories requires a paid GitHub account.

    .PARAMETER NoIssues
        By default, this repository will support Issues.  Specify this to disable Issues.

    .PARAMETER NoProjects
        By default, this repository will support Projects.  Specify this to disable Projects.
        If you're creating a repository in an organization that has disabled repository projects,
        this will be true by default.

    .PARAMETER NoWiki
        By default, this repository will have a Wiki.  Specify this to disable the Wiki.

    .PARAMETER AutoInit
        Specify this to create an initial commit with an empty README.

    .PARAMETER DisallowSquashMerge
        By default, squash-merging pull requests will be allowed.
        Specify this to disallow.

    .PARAMETER DisallowMergeCommit
        By default, merging pull requests with a merge commit will be allowed.
        Specify this to disallow.

    .PARAMETER DisallowRebaseMerge
        By default, rebase-merge pull requests will be allowed.
        Specify this to disallow.

    .PARAMETER AccessToken
        If provided, this will be used as the AccessToken for authentication with the
        REST Api.  Otherwise, will attempt to use the configured value or will run unauthenticated.

    .PARAMETER NoStatus
        If this switch is specified, long-running commands will run on the main thread
        with no commandline status update.  When not specified, those commands run in
        the background, enabling the command prompt to provide status information.
        If not supplied here, the DefaultNoStatus configuration property value will be used.

    .EXAMPLE
        New-GitHubRepository -RepositoryName MyNewRepo -AutoInit

    .EXAMPLE
        New-GitHubRepository -RepositoryName MyNewRepo -Organization MyOrg -DisallowRebaseMerge
#>
    [CmdletBinding(SupportsShouldProcess)]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSShouldProcess", "", Justification="Methods called within here make use of PSShouldProcess, and the switch is passed on to them inherently.")]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string] $RepositoryName,

        [string] $OrganizationName,

        [string] $Description,

        [string] $Homepage,

        [string] $GitIgnoreTemplate,

        [string] $LicenseTemplate,

        [int] $TeamId,

        [switch] $Private,

        [switch] $NoIssues,

        [switch] $NoProjects,

        [switch] $NoWiki,

        [switch] $AutoInit,

        [switch] $DisallowSquashMerge,

        [switch] $DisallowMergeCommit,

        [switch] $DisallowRebaseMerge,

        [string] $AccessToken,

        [switch] $NoStatus
    )

    Write-InvocationLog -Invocation $MyInvocation

    $telemetryProperties = @{
        'RepositoryName' = (Get-PiiSafeString -PlainText $RepositoryName)
    }

    $uriFragment = 'user/repos'
    if ($PSBoundParameters.ContainsKey('OrganizationName') -and
        (-not [String]::IsNullOrEmpty($OrganizationName)))
    {
        $telemetryProperties['OrganizationName'] = Get-PiiSafeString -PlainText $OrganizationName
        $uriFragment = "orgs/$OrganizationName/repos"
    }

    if ($PSBoundParameters.ContainsKey('TeamId') -and (-not $PSBoundParameters.Contains('OrganizationName')))
    {
        $message = 'TeamId may only be specified when creating a repository under an organization.'
        Write-Log -Message $message -Level Error
        throw $message
    }

    $hashBody = @{
        'name' = $RepositoryName
    }

    if ($PSBoundParameters.ContainsKey('Description')) { $hashBody['description'] = $Description }
    if ($PSBoundParameters.ContainsKey('Homepage')) { $hashBody['homepage'] = $Homepage }
    if ($PSBoundParameters.ContainsKey('GitIgnoreTemplate')) { $hashBody['gitignore_template'] = $GitIgnoreTemplate }
    if ($PSBoundParameters.ContainsKey('LicenseTemplate')) { $hashBody['license_template'] = $LicenseTemplate }
    if ($PSBoundParameters.ContainsKey('TeamId')) { $hashBody['team_id'] = $TeamId }
    if ($PSBoundParameters.ContainsKey('Private')) { $hashBody['private'] = $Private.ToBool() }
    if ($PSBoundParameters.ContainsKey('NoIssues')) { $hashBody['has_issues'] = (-not $NoIssues.ToBool()) }
    if ($PSBoundParameters.ContainsKey('NoProjects')) { $hashBody['has_projects'] = (-not $NoProjects.ToBool()) }
    if ($PSBoundParameters.ContainsKey('NoWiki')) { $hashBody['has_wiki'] = (-not $NoWiki.ToBool()) }
    if ($PSBoundParameters.ContainsKey('AutoInit')) { $hashBody['auto_init'] = $AutoInit.ToBool() }
    if ($PSBoundParameters.ContainsKey('DisallowSquashMerge')) { $hashBody['allow_squash_merge'] = (-not $DisallowSquashMerge.ToBool()) }
    if ($PSBoundParameters.ContainsKey('DisallowMergeCommit')) { $hashBody['allow_merge_commit'] = (-not $DisallowMergeCommit.ToBool()) }
    if ($PSBoundParameters.ContainsKey('DisallowRebaseMerge')) { $hashBody['allow_rebase_merge'] = (-not $DisallowRebaseMerge.ToBool()) }

    $params = @{
        'UriFragment' = $uriFragment
        'Body' = (ConvertTo-Json -InputObject $hashBody)
        'Method' = 'Post'
        'Description' =  "Creating $RepositoryName"
        'AccessToken' = $AccessToken
        'TelemetryEventName' = $MyInvocation.MyCommand.Name
        'TelemetryProperties' = $telemetryProperties
        'NoStatus' = (Resolve-ParameterWithDefaultConfigurationValue -BoundParameters $PSBoundParameters -Name NoStatus -ConfigValueName DefaultNoStatus)
    }

    return Invoke-GHRestMethod @params
}

function Remove-GitHubRepository
{
<#
    .SYNOPSIS
        Removes/deletes a repository from GitHub.

    .DESCRIPTION
        Removes/deletes a repository from GitHub.

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

    .EXAMPLE
        Remove-GitHubRepository -OwnerName You -RepositoryName YourRepoToDelete

    .EXAMPLE
        Remove-GitHubRepository -Uri https://github.com/You/YourRepoToDelete
#>
    [CmdletBinding(
        SupportsShouldProcess,
        DefaultParametersetName='Elements')]
    [Alias('Delete-GitHubRepository')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSShouldProcess", "", Justification="Methods called within here make use of PSShouldProcess, and the switch is passed on to them inherently.")]
    param(
        [Parameter(ParameterSetName='Elements')]
        [string] $OwnerName,

        [Parameter(ParameterSetName='Elements')]
        [string] $RepositoryName,

        [Parameter(
            Mandatory,
            ParameterSetName='Uri')]
        [string] $Uri,

        [string] $AccessToken,

        [switch] $NoStatus
    )

    Write-InvocationLog -Invocation $MyInvocation

    $elements = Resolve-RepositoryElements -BoundParameters $PSBoundParameters
    $OwnerName = $elements.ownerName
    $RepositoryName = $elements.repositoryName

    $telemetryProperties = @{
        'OwnerName' = (Get-PiiSafeString -PlainText $OwnerName)
        'RepositoryName' = (Get-PiiSafeString -PlainText $RepositoryName)
    }

    $params = @{
        'UriFragment' = "repos/$OwnerName/$RepositoryName"
        'Method' = 'Delete'
        'Description' =  "Deleting $RepositoryName"
        'AccessToken' = $AccessToken
        'TelemetryEventName' = $MyInvocation.MyCommand.Name
        'TelemetryProperties' = $telemetryProperties
        'NoStatus' = (Resolve-ParameterWithDefaultConfigurationValue -BoundParameters $PSBoundParameters -Name NoStatus -ConfigValueName DefaultNoStatus)
    }

    return Invoke-GHRestMethod @params
}

function Get-GitHubRepository
{
<#
    .SYNOPSIS
        Retrieves information about a repository or list of repoistories on GitHub.

    .DESCRIPTION
        Retrieves information about a repository or list of repoistories on GitHub.

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
        The name of the organization to retrieve the repositories for.

    .PARAMETER Visibility
        The type of visibility/accessibility for the repositories to return.

    .PARAMETER Affiliation
        Can be one or more of:

        owner - Repositories that are owned by the authenticated user

        collaborator - Repositories that the user has been added to as a collaborator

        organization_member - Repositories that the user has access to through being
        a member of an organization.  This includes every repository on every team that the user
        is on.

    .PARAMETER Type
        The type of repository to return.

    .PARAMETER Sort
        Property that the results should be sorted by

    .PARAMETER Direction
        Direction of the sort that is to be applied to the results.

    .PARAMETER GetAllPublicRepositories
        If this is specified with no other parameter, then instead of returning back all
        repositories for the current authenticated user, it will instead return back all
        public repositories on GitHub.

    .PARAMETER AccessToken
        If provided, this will be used as the AccessToken for authentication with the
        REST Api.  Otherwise, will attempt to use the configured value or will run unauthenticated.

    .PARAMETER NoStatus
        If this switch is specified, long-running commands will run on the main thread
        with no commandline status update.  When not specified, those commands run in
        the background, enabling the command prompt to provide status information.
        If not supplied here, the DefaultNoStatus configuration property value will be used.

    .EXAMPLE
        Get-GitHubRepository

        Gets all repositories for the current authenticated user.

    .EXAMPLE
        Get-GitHubRepository -GetAllPublicRepositories

        Gets all public repositories on GitHub.

    .EXAMPLE
        Get-GitHubRepository -OctoCat OctoCat

    .EXAMPLE
        Get-GitHubRepository -Uri https://github.com/PowerShell/PowerShellForGitHub

    .EXAMPLE
        Get-GitHubRepository -OrganizationName PowerShell

#>
    [CmdletBinding(
        SupportsShouldProcess,
        DefaultParametersetName='Elements')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSShouldProcess", "", Justification="Methods called within here make use of PSShouldProcess, and the switch is passed on to them inherently.")]
    param(
        [Parameter(ParameterSetName='Elements')]
        [string] $OwnerName,

        [Parameter(ParameterSetName='Elements')]
        [string] $RepositoryName,

        [Parameter(
            Mandatory,
            ParameterSetName='Uri')]
        [string] $Uri,

        [Parameter(ParameterSetName='Organization')]
        [string] $OrganizationName,

        [ValidateSet('All', 'Public', 'Private')]
        [string] $Visibility,

        [string[]] $Affiliation,

        [ValidateSet('All', 'Owner', 'Public', 'Private', 'Member', 'Forks', 'Sources')]
        [string] $Type,

        [ValidateSet('Created', 'Updated', 'Pushed', 'FullName')]
        [string] $Sort,

        [ValidateSet('Ascending', 'Descending')]
        [string] $Direction,

        [switch] $GetAllPublicRepositories,

        [string] $AccessToken,

        [switch] $NoStatus
    )

    Write-InvocationLog -Invocation $MyInvocation

    $elements = Resolve-RepositoryElements -BoundParameters $PSBoundParameters -DisableValidation
    $OwnerName = $elements.ownerName
    $RepositoryName = $elements.repositoryName

    $telemetryProperties = @{}

    $uriFragment = [String]::Empty
    $description = [String]::Empty
    if ((-not [String]::IsNullOrEmpty($OwnerName)) -and (-not [String]::IsNullOrEmpty($RepositoryName)))
    {
        $telemetryProperties['OwnerName'] = Get-PiiSafeString -PlainText $OwnerName
        $telemetryProperties['RepositoryName'] = Get-PiiSafeString -PlainText $RepositoryName

        $uriFragment = "repos/$OwnerName/$RepositoryName"
        $description = "Getting repo $RepositoryName"
    }
    elseif ([String]::IsNullOrEmpty($OwnerName) -and [String]::IsNullOrEmpty($OrganizationName))
    {
        $uriFragment = 'user/repos'
        $description = 'Getting repos for current authenticated user'
    }
    elseif ([String]::IsNullOrEmpty($OwnerName))
    {
        $telemetryProperties['OrganizationName'] = Get-PiiSafeString -PlainText $OrganizationName

        $uriFragment = "orgs/$OrganizationName/repos"
        $description = "Getting repos for $OrganizationName"
    }
    else
    {
        $telemetryProperties['OwnerName'] = Get-PiiSafeString -PlainText $OwnerName

        $uriFragment = "users/$OwnerName/repos"
        $description = "Getting repos for $OwnerName"
    }

    $sortConverter = @{
        'Created' = 'created'
        'Updated' = 'updated'
        'Pushed' = 'pushed'
        'FullName' = 'full_name'
    }

    $directionConverter = @{
        'Ascending' = 'asc'
        'Descending' = 'desc'
    }

    $getParams = @()
    if ($PSBoundParameters.ContainsKey('Visibility')) { $getParams += "visibility=$($Visibility.ToLower())" }
    if ($PSBoundParameters.ContainsKey('Sort')) { $getParams += "sort=$($sortConverter[$Sort])" }
    if ($PSBoundParameters.ContainsKey('Type')) { $getParams += "type=$($Type.ToLower())" }
    if ($PSBoundParameters.ContainsKey('Direction')) { $getParams += "direction=$($directionConverter[$Direction])" }
    if ($PSBoundParameters.ContainsKey('Affiliation') -and $Affiliation.Count -gt 0)
    {
        $getParams += "affiliation=$($Affiliation -join ',')"
    }

    $params = @{
        'UriFragment' = $uriFragment + '?' +  ($getParams -join '&')
        'Description' =  $description
        'AccessToken' = $AccessToken
        'TelemetryEventName' = $MyInvocation.MyCommand.Name
        'TelemetryProperties' = $telemetryProperties
        'NoStatus' = (Resolve-ParameterWithDefaultConfigurationValue -BoundParameters $PSBoundParameters -Name NoStatus -ConfigValueName DefaultNoStatus)
    }

    return Invoke-GHRestMethodMultipleResult @params
}

function Update-GitHubRepository
{
<#
    .SYNOPSIS
        Updates the details of an existing repository on GitHub.

    .DESCRIPTION
        Updates the details of an existing repository on GitHub.

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

    .PARAMETER Description
        A short description of the repository.

    .PARAMETER Homepage
        A URL with more information about the repository.

    .PARAMETER DefaultBranch
        Update the default branch for this repository.

    .PARAMETER Private
        Specify this to make the repository repository.  Creating private repositories requires a
        paid GitHub account.
        To change a repository to be public, specify -Private:$false

    .PARAMETER NoIssues
        By default, this repository will support Issues.  Specify this to disable Issues.

    .PARAMETER NoProjects
        By default, this repository will support Projects.  Specify this to disable Projects.
        If you're creating a repository in an organization that has disabled repository projects,
        this will be true by default.

    .PARAMETER NoWiki
        By default, this repository will have a Wiki.  Specify this to disable the Wiki.

    .PARAMETER DisallowSquashMerge
        By default, squash-merging pull requests will be allowed.
        Specify this to disallow.

    .PARAMETER DisallowMergeCommit
        By default, merging pull requests with a merge commit will be allowed.
        Specify this to disallow.

    .PARAMETER DisallowRebaseMerge
        By default, rebase-merge pull requests will be allowed.
        Specify this to disallow.

    .PARAMETER DisallowRebaseMerge
        Specify this to archive this repository.
        NOTE: You cannot unarchive repositories through the API / this module.

    .PARAMETER AccessToken
        If provided, this will be used as the AccessToken for authentication with the
        REST Api.  Otherwise, will attempt to use the configured value or will run unauthenticated.

    .PARAMETER NoStatus
        If this switch is specified, long-running commands will run on the main thread
        with no commandline status update.  When not specified, those commands run in
        the background, enabling the command prompt to provide status information.
        If not supplied here, the DefaultNoStatus configuration property value will be used.

    .EXAMPLE
        Update-GitHubRepository -OwnerName PowerShell -RepositoryName PowerShellForGitHub -Description 'The best way to automate your GitHub interactions'

    .EXAMPLE
        Update-GitHubRepository -Uri https://github.com/PowerShell/PowerShellForGitHub -Private:$false
#>
    [CmdletBinding(
        SupportsShouldProcess,
        DefaultParametersetName='Elements')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSShouldProcess", "", Justification="Methods called within here make use of PSShouldProcess, and the switch is passed on to them inherently.")]
    param(
        [Parameter(ParameterSetName='Elements')]
        [string] $OwnerName,

        [Parameter(ParameterSetName='Elements')]
        [string] $RepositoryName,

        [Parameter(
            Mandatory,
            ParameterSetName='Uri')]
        [string] $Uri,

        [string] $Description,

        [string] $Homepage,

        [string] $DefaultBranch,

        [switch] $Private,

        [switch] $NoIssues,

        [switch] $NoProjects,

        [switch] $NoWiki,

        [switch] $DisallowSquashMerge,

        [switch] $DisallowMergeCommit,

        [switch] $DisallowRebaseMerge,

        [switch] $Archived,

        [string] $AccessToken,

        [switch] $NoStatus
    )

    Write-InvocationLog -Invocation $MyInvocation

    $elements = Resolve-RepositoryElements -BoundParameters $PSBoundParameters
    $OwnerName = $elements.ownerName
    $RepositoryName = $elements.repositoryName

    $telemetryProperties = @{
        'OwnerName' = (Get-PiiSafeString -PlainText $OwnerName)
        'RepositoryName' = (Get-PiiSafeString -PlainText $RepositoryName)
    }

    $hashBody = @{
        'name' = $RepositoryName
    }

    if ($PSBoundParameters.ContainsKey('Description')) { $hashBody['description'] = $Description }
    if ($PSBoundParameters.ContainsKey('Homepage')) { $hashBody['homepage'] = $Homepage }
    if ($PSBoundParameters.ContainsKey('DefaultBranch')) { $hashBody['default_branch'] = $DefaultBranch }
    if ($PSBoundParameters.ContainsKey('Private')) { $hashBody['private'] = $Private.ToBool() }
    if ($PSBoundParameters.ContainsKey('NoIssues')) { $hashBody['has_issues'] = (-not $NoIssues.ToBool()) }
    if ($PSBoundParameters.ContainsKey('NoProjects')) { $hashBody['has_projects'] = (-not $NoProjects.ToBool()) }
    if ($PSBoundParameters.ContainsKey('NoWiki')) { $hashBody['has_wiki'] = (-not $NoWiki.ToBool()) }
    if ($PSBoundParameters.ContainsKey('DisallowSquashMerge')) { $hashBody['allow_squash_merge'] = (-not $DisallowSquashMerge.ToBool()) }
    if ($PSBoundParameters.ContainsKey('DisallowMergeCommit')) { $hashBody['allow_merge_commit'] = (-not $DisallowMergeCommit.ToBool()) }
    if ($PSBoundParameters.ContainsKey('DisallowRebaseMerge')) { $hashBody['allow_rebase_merge'] = (-not $DisallowRebaseMerge.ToBool()) }
    if ($PSBoundParameters.ContainsKey('Archived')) { $hashBody['archived'] = (-not $Archived.ToBool()) }

    $params = @{
        'UriFragment' = "repos/$OwnerName/$ReposistoryName"
        'Body' = (ConvertTo-Json -InputObject $hashBody)
        'Method' = 'Patch'
        'Description' =  "Updating $RepositoryName"
        'AccessToken' = $AccessToken
        'TelemetryEventName' = $MyInvocation.MyCommand.Name
        'TelemetryProperties' = $telemetryProperties
        'NoStatus' = (Resolve-ParameterWithDefaultConfigurationValue -BoundParameters $PSBoundParameters -Name NoStatus -ConfigValueName DefaultNoStatus)
    }

    return Invoke-GHRestMethod @params
}

function Get-GitHubRepositoryTopic
{
<#
    .SYNOPSIS
        Retrieves information about a repository on GitHub.

    .DESCRIPTION
        Retrieves information about a repository on GitHub.

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

    .EXAMPLE
        Get-GitHubRepositoryTopic -OwnerName PowerShell -RepositoryName PowerShellForGitHub

    .EXAMPLE
        Get-GitHubRepositoryTopic -Uri https://github.com/PowerShell/PowerShellForGitHub
#>
    [CmdletBinding(
        SupportsShouldProcess,
        DefaultParametersetName='Elements')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSShouldProcess", "", Justification="Methods called within here make use of PSShouldProcess, and the switch is passed on to them inherently.")]
    param(
        [Parameter(ParameterSetName='Elements')]
        [string] $OwnerName,

        [Parameter(ParameterSetName='Elements')]
        [string] $RepositoryName,

        [Parameter(
            Mandatory,
            ParameterSetName='Uri')]
        [string] $Uri,

        [string] $AccessToken,

        [switch] $NoStatus
    )

    Write-InvocationLog -Invocation $MyInvocation

    $elements = Resolve-RepositoryElements -BoundParameters $PSBoundParameters
    $OwnerName = $elements.ownerName
    $RepositoryName = $elements.repositoryName

    $telemetryProperties = @{
        'OwnerName' = (Get-PiiSafeString -PlainText $OwnerName)
        'RepositoryName' = (Get-PiiSafeString -PlainText $RepositoryName)
    }

    $params = @{
        'UriFragment' = "repos/$OwnerName/$RepositoryName/topics"
        'Method' = 'Get'
        'Description' =  "Getting topics for $RepositoryName"
        'AcceptHeader' = 'application/vnd.github.mercy-preview+json'
        'AccessToken' = $AccessToken
        'TelemetryEventName' = $MyInvocation.MyCommand.Name
        'TelemetryProperties' = $telemetryProperties
        'NoStatus' = (Resolve-ParameterWithDefaultConfigurationValue -BoundParameters $PSBoundParameters -Name NoStatus -ConfigValueName DefaultNoStatus)
    }

    return Invoke-GHRestMethod @params
}

function Set-GitHubRepositoryTopic
{
<#
    .SYNOPSIS
        Replaces all topics for a repository on GitHub.

    .DESCRIPTION
        Replaces all topics for a repository on GitHub.

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
        Array of topics to add to the repository.

    .PARAMETER Clear
        Specify this to clear all topics from the repository.

    .PARAMETER AccessToken
        If provided, this will be used as the AccessToken for authentication with the
        REST Api.  Otherwise, will attempt to use the configured value or will run unauthenticated.

    .PARAMETER NoStatus
        If this switch is specified, long-running commands will run on the main thread
        with no commandline status update.  When not specified, those commands run in
        the background, enabling the command prompt to provide status information.
        If not supplied here, the DefaultNoStatus configuration property value will be used.

    .EXAMPLE
        Set-GitHubRepositoryTopic -OwnerName PowerShell -RepositoryName PowerShellForGitHub -Clear

    .EXAMPLE
        Set-GitHubRepositoryTopic -Uri https://github.com/PowerShell/PowerShellForGitHub -Name ('octocat', 'powershell', 'github')
#>
    [CmdletBinding(
        SupportsShouldProcess,
        DefaultParametersetName='ElementsName')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSShouldProcess", "", Justification="Methods called within here make use of PSShouldProcess, and the switch is passed on to them inherently.")]
    param(
        [Parameter(ParameterSetName='ElementsName')]
        [Parameter(ParameterSetName='ElementsClear')]
        [string] $OwnerName,

        [Parameter(ParameterSetName='ElementsName')]
        [Parameter(ParameterSetName='ElementsClear')]
        [string] $RepositoryName,

        [Parameter(
            Mandatory,
            ParameterSetName='UriName')]
        [Parameter(
            Mandatory,
            ParameterSetName='UriClear')]
        [string] $Uri,

        [Parameter(
            Mandatory,
            ParameterSetName='ElementsName')]
        [Parameter(
            Mandatory,
            ParameterSetName='UriName')]
        [string[]] $Name,

        [Parameter(
            Mandatory,
            ParameterSetName='ElementsClear')]
        [Parameter(
            Mandatory,
            ParameterSetName='UriClear')]
        [switch] $Clear,

        [string] $AccessToken,

        [switch] $NoStatus
    )

    Write-InvocationLog -Invocation $MyInvocation

    $elements = Resolve-RepositoryElements -BoundParameters $PSBoundParameters
    $OwnerName = $elements.ownerName
    $RepositoryName = $elements.repositoryName

    $telemetryProperties = @{
        'OwnerName' = (Get-PiiSafeString -PlainText $OwnerName)
        'RepositoryName' = (Get-PiiSafeString -PlainText $RepositoryName)
        'Clear' = $PSBoundParameters.ContainsKey('Clear')
    }

    $description = "Replacing topics in $RepositoryName"
    if ($Clear) { $description = "Clearing topics in $RepositoryName" }

    $names = @($Name)
    $hashBody = @{
        'names' = $names
    }

    $params = @{
        'UriFragment' = "repos/$OwnerName/$RepositoryName/topics"
        'Body' = (ConvertTo-Json -InputObject $hashBody)
        'Method' = 'Put'
        'Description' =  $description
        'AcceptHeader' = 'application/vnd.github.mercy-preview+json'
        'AccessToken' = $AccessToken
        'TelemetryEventName' = $MyInvocation.MyCommand.Name
        'TelemetryProperties' = $telemetryProperties
        'NoStatus' = (Resolve-ParameterWithDefaultConfigurationValue -BoundParameters $PSBoundParameters -Name NoStatus -ConfigValueName DefaultNoStatus)
    }

    return Invoke-GHRestMethod @params
}

function Get-GitHubRepositoryContributor
{
<#
    .SYNOPSIS
        Retrieve list of contributors for a given repository.

    .DESCRIPTION
        Retrieve list of contributors for a given repository.

        GitHub identifies contributors by author email address.
        This groups contribution counts by GitHub user, which includes all associated email addresses.
        To improve performance, only the first 500 author email addresses in the repository link to
        GitHub users. The rest will appear as anonymous contributors without associated GitHub user
        information.

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

    .PARAMETER IncludeAnonymousContributors
        If specified, anonymous contributors will be included in the results.

    .PARAMETER IncludeStatistics
        If specified, each result will include statistics for the number of additions, deletions
        and commit counts, by week (excluding merge commits and empty commits).

    .PARAMETER AccessToken
        If provided, this will be used as the AccessToken for authentication with the
        REST Api.  Otherwise, will attempt to use the configured value or will run unauthenticated.

    .PARAMETER NoStatus
        If this switch is specified, long-running commands will run on the main thread
        with no commandline status update.  When not specified, those commands run in
        the background, enabling the command prompt to provide status information.
        If not supplied here, the DefaultNoStatus configuration property value will be used.

    .OUTPUTS
        [PSCustomObject[]] List of contributors for the repository.

    .EXAMPLE
        Get-GitHubRepositoryContributor -OwnerName PowerShell -RepositoryName PowerShellForGitHub

    .EXAMPLE
        Get-GitHubRepositoryContributor -Uri 'https://github.com/PowerShell/PowerShellForGitHub' -IncludeStatistics
#>
    [CmdletBinding(
        SupportsShouldProcess,
        DefaultParametersetName='Elements')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSShouldProcess", "", Justification="Methods called within here make use of PSShouldProcess, and the switch is passed on to them inherently.")]
    param(
        [Parameter(ParameterSetName='Elements')]
        [string] $OwnerName,

        [Parameter(ParameterSetName='Elements')]
        [string] $RepositoryName,

        [Parameter(
            Mandatory,
            ParameterSetName='Uri')]
        [string] $Uri,

        [switch] $IncludeAnonymousContributors,

        [switch] $IncludeStatistics,

        [string] $AccessToken,

        [switch] $NoStatus
    )

    Write-InvocationLog -Invocation $MyInvocation

    $elements = Resolve-RepositoryElements -BoundParameters $PSBoundParameters
    $OwnerName = $elements.ownerName
    $RepositoryName = $elements.repositoryName

    $telemetryProperties = @{
        'OwnerName' = (Get-PiiSafeString -PlainText $OwnerName)
        'RepositoryName' = (Get-PiiSafeString -PlainText $RepositoryName)
        'IncludeAnonymousContributors' = $IncludeAnonymousContributors.ToBool()
        'IncludeStatistics' = $IncludeStatistics.ToBool()
    }

    $getParams = @()
    if ($IncludeAnonymousContributors) { $getParams += 'anon=true' }

    $uriFragment = "repos/$OwnerName/$RepositoryName/contributors"
    if ($IncludeStatistics) { $uriFragment = "repos/$OwnerName/$RepositoryName/stats/contributors" }

    $params = @{
        'UriFragment' = $uriFragment + '?' + ($getParams -join '&')
        'Description' =  "Getting contributors for $RepositoryName"
        'AccessToken' = $AccessToken
        'TelemetryEventName' = $MyInvocation.MyCommand.Name
        'TelemetryProperties' = $telemetryProperties
        'NoStatus' = (Resolve-ParameterWithDefaultConfigurationValue -BoundParameters $PSBoundParameters -Name NoStatus -ConfigValueName DefaultNoStatus)
    }

    return Invoke-GHRestMethodMultipleResult @params
}

function Get-GitHubRepositoryCollaborator
{
<#
    .SYNOPSIS
        Retrieve list of contributors for a given repository.

    .DESCRIPTION
        Retrieve list of contributors for a given repository.

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

    .OUTPUTS
        [PSCustomObject[]] List of collaborators for the repository.

    .EXAMPLE
        Get-GitHubRepositoryCollaborator -OwnerName PowerShell -RepositoryName PowerShellForGitHub

    .EXAMPLE
        Get-GitHubRepositoryCollaborator -Uri 'https://github.com/PowerShell/PowerShellForGitHub'
#>
    [CmdletBinding(
        SupportsShouldProcess,
        DefaultParametersetName='Elements')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSShouldProcess", "", Justification="Methods called within here make use of PSShouldProcess, and the switch is passed on to them inherently.")]
    param(
        [Parameter(ParameterSetName='Elements')]
        [string] $OwnerName,

        [Parameter(ParameterSetName='Elements')]
        [string] $RepositoryName,

        [Parameter(
            Mandatory,
            ParameterSetName='Uri')]
        [string] $Uri,

        [string] $AccessToken,

        [switch] $NoStatus
    )

    Write-InvocationLog -Invocation $MyInvocation

    $elements = Resolve-RepositoryElements -BoundParameters $PSBoundParameters
    $OwnerName = $elements.ownerName
    $RepositoryName = $elements.repositoryName

    $telemetryProperties = @{
        'OwnerName' = (Get-PiiSafeString -PlainText $OwnerName)
        'RepositoryName' = (Get-PiiSafeString -PlainText $RepositoryName)
    }

    $params = @{
        'UriFragment' = "repos/$OwnerName/$RepositoryName/collaborators"
        'Description' =  "Getting collaborators for $RepositoryName"
        'AccessToken' = $AccessToken
        'TelemetryEventName' = $MyInvocation.MyCommand.Name
        'TelemetryProperties' = $telemetryProperties
        'NoStatus' = (Resolve-ParameterWithDefaultConfigurationValue -BoundParameters $PSBoundParameters -Name NoStatus -ConfigValueName DefaultNoStatus)
    }

    return Invoke-GHRestMethodMultipleResult @params
}

function Get-GitHubRepositoryLanguage
{
<#
    .SYNOPSIS
        Retrieves a list of the programming languages used in a repository on GitHub.

    .DESCRIPTION
        Retrieves a list of the programming languages used in a repository on GitHub.

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

    .OUTPUTS
        [PSCustomObject[]] List of languages for the specified repository.  The value shown
        for each language is the number of bytes of code written in that language.

    .EXAMPLE
        Get-GitHubRepositoryLanguage -OwnerName PowerShell -RepositoryName PowerShellForGitHub

    .EXAMPLE
        Get-GitHubRepositoryLanguage -Uri https://github.com/PowerShell/PowerShellForGitHub
#>
    [CmdletBinding(
        SupportsShouldProcess,
        DefaultParametersetName='Elements')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSShouldProcess", "", Justification="Methods called within here make use of PSShouldProcess, and the switch is passed on to them inherently.")]
    param(
        [Parameter(ParameterSetName='Elements')]
        [string] $OwnerName,

        [Parameter(ParameterSetName='Elements')]
        [string] $RepositoryName,

        [Parameter(
            Mandatory,
            ParameterSetName='Uri')]
        [string] $Uri,

        [string] $AccessToken,

        [switch] $NoStatus
    )

    Write-InvocationLog -Invocation $MyInvocation

    $elements = Resolve-RepositoryElements -BoundParameters $PSBoundParameters
    $OwnerName = $elements.ownerName
    $RepositoryName = $elements.repositoryName

    $telemetryProperties = @{
        'OwnerName' = (Get-PiiSafeString -PlainText $OwnerName)
        'RepositoryName' = (Get-PiiSafeString -PlainText $RepositoryName)
    }

    $params = @{
        'UriFragment' = "repos/$OwnerName/$RepositoryName/languages"
        'Description' =  "Getting languages for $RepositoryName"
        'AccessToken' = $AccessToken
        'TelemetryEventName' = $MyInvocation.MyCommand.Name
        'TelemetryProperties' = $telemetryProperties
        'NoStatus' = (Resolve-ParameterWithDefaultConfigurationValue -BoundParameters $PSBoundParameters -Name NoStatus -ConfigValueName DefaultNoStatus)
    }

    return Invoke-GHRestMethodMultipleResult @params
}

function Get-GitHubRepositoryTag
{
<#
    .SYNOPSIS
        Retrieves tags for a repository on GitHub.

    .DESCRIPTION
        Retrieves tags for a repository on GitHub.

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

    .EXAMPLE
        Get-GitHubRepositoryTag -OwnerName PowerShell -RepositoryName PowerShellForGitHub

    .EXAMPLE
        Get-GitHubRepositoryTag -Uri https://github.com/PowerShell/PowerShellForGitHub
#>
    [CmdletBinding(
        SupportsShouldProcess,
        DefaultParametersetName='Elements')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSShouldProcess", "", Justification="Methods called within here make use of PSShouldProcess, and the switch is passed on to them inherently.")]
    param(
        [Parameter(ParameterSetName='Elements')]
        [string] $OwnerName,

        [Parameter(ParameterSetName='Elements')]
        [string] $RepositoryName,

        [Parameter(
            Mandatory,
            ParameterSetName='Uri')]
        [string] $Uri,

        [string] $AccessToken,

        [switch] $NoStatus
    )

    Write-InvocationLog -Invocation $MyInvocation

    $elements = Resolve-RepositoryElements -BoundParameters $PSBoundParameters
    $OwnerName = $elements.ownerName
    $RepositoryName = $elements.repositoryName

    $telemetryProperties = @{
        'OwnerName' = (Get-PiiSafeString -PlainText $OwnerName)
        'RepositoryName' = (Get-PiiSafeString -PlainText $RepositoryName)
    }

    $params = @{
        'UriFragment' = "repos/$OwnerName/$RepositoryName/tags"
        'Description' =  "Getting tags for $RepositoryName"
        'AccessToken' = $AccessToken
        'TelemetryEventName' = $MyInvocation.MyCommand.Name
        'TelemetryProperties' = $telemetryProperties
        'NoStatus' = (Resolve-ParameterWithDefaultConfigurationValue -BoundParameters $PSBoundParameters -Name NoStatus -ConfigValueName DefaultNoStatus)
    }

    return Invoke-GHRestMethodMultipleResult @params
}

function Move-GitHubRepositoryOwnership
{
<#
    .SYNOPSIS
        Creates a new repository on GitHub.

    .DESCRIPTION
        Creates a new repository on GitHub.

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

    .PARAMETER NewOwnerName
        The username or organization name the repository will be transferred to.

    .PARAMETER TeamId
        ID of the team or teams to add to the repository.  Teams can only be added to
        organization-owned repositories.

    .PARAMETER AccessToken
        If provided, this will be used as the AccessToken for authentication with the
        REST Api.  Otherwise, will attempt to use the configured value or will run unauthenticated.

    .PARAMETER NoStatus
        If this switch is specified, long-running commands will run on the main thread
        with no commandline status update.  When not specified, those commands run in
        the background, enabling the command prompt to provide status information.
        If not supplied here, the DefaultNoStatus configuration property value will be used.

    .EXAMPLE
        Move-GitHubRepositoryOwnership -OwnerName PowerShell -RepositoryName PowerShellForGitHub -NewOwnerName OctoCat
#>
    [CmdletBinding(
        SupportsShouldProcess,
        DefaultParametersetName='Elements')]
    [Alias('Transfer-GitHubRepositoryOwnership')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSShouldProcess", "", Justification="Methods called within here make use of PSShouldProcess, and the switch is passed on to them inherently.")]
    param(
        [Parameter(ParameterSetName='Elements')]
        [string] $OwnerName,

        [Parameter(ParameterSetName='Elements')]
        [string] $RepositoryName,

        [Parameter(
            Mandatory,
            ParameterSetName='Uri')]
        [string] $Uri,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string] $NewOwnerName,

        [int[]] $TeamId,

        [string] $AccessToken,

        [switch] $NoStatus
    )

    Write-InvocationLog -Invocation $MyInvocation

    $elements = Resolve-RepositoryElements -BoundParameters $PSBoundParameters
    $OwnerName = $elements.ownerName
    $RepositoryName = $elements.repositoryName

    $telemetryProperties = @{
        'OwnerName' = (Get-PiiSafeString -PlainText $OwnerName)
        'RepositoryName' = (Get-PiiSafeString -PlainText $RepositoryName)
    }

    $hashBody = @{
        'new_owner' = $NewOwnerName
    }

    if ($TeamId.Count -gt 0) { $hashBody['team_ids'] = @($TeamId) }

    $params = @{
        'UriFragment' = "repos/$OwnerName/$RepositoryName/transfer"
        'Body' = (ConvertTo-Json -InputObject $hashBody)
        'Method' = 'Post'
        'Description' =  "Transferring ownership of $RepositoryName to $NewOwnerName"
        'AccessToken' = $AccessToken
        'TelemetryEventName' = $MyInvocation.MyCommand.Name
        'TelemetryProperties' = $telemetryProperties
        'NoStatus' = (Resolve-ParameterWithDefaultConfigurationValue -BoundParameters $PSBoundParameters -Name NoStatus -ConfigValueName DefaultNoStatus)
    }

    return Invoke-GHRestMethod @params
}

# SIG # Begin signature block
# MIIdkgYJKoZIhvcNAQcCoIIdgzCCHX8CAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUHjDaXW+RVsEhuvXez36MCrm/
# HaGgghhuMIIE2jCCA8KgAwIBAgITMwAAAQF4QskMs6jYswAAAAABATANBgkqhkiG
# 9w0BAQUFADB3MQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4G
# A1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSEw
# HwYDVQQDExhNaWNyb3NvZnQgVGltZS1TdGFtcCBQQ0EwHhcNMTgwODIzMjAyMDIx
# WhcNMTkxMTIzMjAyMDIxWjCByjELMAkGA1UEBhMCVVMxCzAJBgNVBAgTAldBMRAw
# DgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24x
# LTArBgNVBAsTJE1pY3Jvc29mdCBJcmVsYW5kIE9wZXJhdGlvbnMgTGltaXRlZDEm
# MCQGA1UECxMdVGhhbGVzIFRTUyBFU046RTA0MS00QkVFLUZBN0UxJTAjBgNVBAMT
# HE1pY3Jvc29mdCBUaW1lLVN0YW1wIHNlcnZpY2UwggEiMA0GCSqGSIb3DQEBAQUA
# A4IBDwAwggEKAoIBAQCbadtQJVLLJBRVaOm+saBSd4ZWqY5+RiSwRqn5bL2kIKit
# 3IaJnDDxJ/PhLOVEZbiA0GgHLkOZEn8CnBOpv0q0Au3JuVhKJzveWh/Zlt8WM+vY
# GlOgXiIzSv4iH9xFa+GgfuEhBZtZv8aWQET8/QXH0Z07rlflaRHw8v93r/SqoA63
# sGYXJh49kovbKY8/lLqq1ves7OeStSFssS7r2svjMWxXhpKgcA1fZmmMa/IyfT/2
# QEhya5LK04/PNZFSXS7Yfz0kP7cA17X41j25zHsDkdiFiULO00+uOhdvH1+slnQH
# Scz0tAQHoKiqYkdUNy37oxJjIeGHICB/zz6/X8T/AgMBAAGjggEJMIIBBTAdBgNV
# HQ4EFgQUgk5O3GQeGZVd8TZu73LWf4S95BkwHwYDVR0jBBgwFoAUIzT42VJGcArt
# QPt2+7MrsMM1sw8wVAYDVR0fBE0wSzBJoEegRYZDaHR0cDovL2NybC5taWNyb3Nv
# ZnQuY29tL3BraS9jcmwvcHJvZHVjdHMvTWljcm9zb2Z0VGltZVN0YW1wUENBLmNy
# bDBYBggrBgEFBQcBAQRMMEowSAYIKwYBBQUHMAKGPGh0dHA6Ly93d3cubWljcm9z
# b2Z0LmNvbS9wa2kvY2VydHMvTWljcm9zb2Z0VGltZVN0YW1wUENBLmNydDATBgNV
# HSUEDDAKBggrBgEFBQcDCDANBgkqhkiG9w0BAQUFAAOCAQEAPojiCg/OLTqboQdZ
# 1oZO1HabJrLJyQY6Ry+AQue5Fg7dmjEfuBYbARQ3yorUyU4OwlLbzbelhdZDOkWR
# RIALTP2Dq6TwRb2oOIMzXdHbr0Svxv4xgrcC5mu4MeoyMRl3b52llEFIxjIAP3sG
# 4wZE2oMLFuJsv3thspy8q5gP+65E32zYRwhrBtdgrJJ1fn9T4z3nMMCDzfkojAEe
# AtKPA1rcYUEdRa2sRICD/sEnk4kNL+HrLmW7ksog83O9Js2KHxET/pKy8yf6bayP
# JgttOKwk+HyFRWoILkGMcFXT1b3S2G8EfHKY7NCfoHgYNffyRXQnXg433YKBOmqj
# n/aRATCCBgMwggProAMCAQICEzMAAAEEaeLbufuKDYMAAAAAAQQwDQYJKoZIhvcN
# AQELBQAwfjELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNV
# BAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEoMCYG
# A1UEAxMfTWljcm9zb2Z0IENvZGUgU2lnbmluZyBQQ0EgMjAxMTAeFw0xODA3MTIy
# MDA4NDlaFw0xOTA3MjYyMDA4NDlaMHQxCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpX
# YXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3NvZnQg
# Q29ycG9yYXRpb24xHjAcBgNVBAMTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjCCASIw
# DQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBAJvFlfKX9v8jamydc1lzOJvTtOOE
# rY24PiXnoLggWkqRcDjYFKi9msD9DWse7OH8/wQ84mFgrlVqYZL71wB9nuppNtb9
# V3kZl/6EkfbHVa2mrgKK7bGRR1bNSodmRacwGxrtrHtrBdIzgnO+xm8czNToGgUV
# AC6Rl7ZLyGFnIovnExJowhcUryZatu5Vc3z1RLMhJwYA67U2+fwmiq0/f0QUw3q7
# I8iL3r4WisEhogIB2X+YkuIxU4+HsZAkmxf6FU3KAWwQbFICopNfYgNBJIxwp3As
# jUsv1zNZXP1d4D/X5IQXu30+edOCQ2JUQMibXs9wFDtgPGk/nzfn+BaSM4sCAwEA
# AaOCAYIwggF+MB8GA1UdJQQYMBYGCisGAQQBgjdMCAEGCCsGAQUFBwMDMB0GA1Ud
# DgQWBBS6F+MlaPS71Xsjpri2fOemgqtXrjBUBgNVHREETTBLpEkwRzEtMCsGA1UE
# CxMkTWljcm9zb2Z0IElyZWxhbmQgT3BlcmF0aW9ucyBMaW1pdGVkMRYwFAYDVQQF
# Ew0yMzAwMTIrNDM3OTY2MB8GA1UdIwQYMBaAFEhuZOVQBdOCqhc3NyK1bajKdQKV
# MFQGA1UdHwRNMEswSaBHoEWGQ2h0dHA6Ly93d3cubWljcm9zb2Z0LmNvbS9wa2lv
# cHMvY3JsL01pY0NvZFNpZ1BDQTIwMTFfMjAxMS0wNy0wOC5jcmwwYQYIKwYBBQUH
# AQEEVTBTMFEGCCsGAQUFBzAChkVodHRwOi8vd3d3Lm1pY3Jvc29mdC5jb20vcGtp
# b3BzL2NlcnRzL01pY0NvZFNpZ1BDQTIwMTFfMjAxMS0wNy0wOC5jcnQwDAYDVR0T
# AQH/BAIwADANBgkqhkiG9w0BAQsFAAOCAgEAKcWCCzmZIAzoJFuJOzhQkoOV25Hy
# O9Kk8NqBW3OOZ0gatsmKB3labM7D/GaYF7K716YWtQNWhXsqfS9ABk6eaddpFBWO
# Y/vMgPXbEZxQ7ksCcUxrBwX+Z1PxGbZubizyj9RFKeE2CLIceIEnloeZQhh3lNzG
# vJ2k21amNtBDSF9ABH5n6YjYAMfrMv/eCndgA3P+nqHHHfPAsy1hh8jxN4Xc/G08
# SxNKEna1UEpN513zTyHkmBKBgf7pXKj8FIzRAp9l+3Z1t2JTx33ax7pC4m57Jkoj
# gjLYjXUeEW+Lf3oG1aofGKVwE+fuaJ0HvAbpiQOWDGriIaslA9i3ARHhxCKWKTF8
# w1VO0BznRcZmAIoVIcTFAXAd4mgBOQ8iIcmoc39w2Cz09WnlSWw5paKpyns51fl3
# bzBzg5bAo4uu5X/dY03aFct7+R3ljsQ6qkr0LUVmn/JeuEkXOePfHUmJYYu6M69e
# Quoa1PVRU/GlXZKbh2e4dqsGVeGu1YOvOf8gMYtc5vq1B8+GJ8dBAiM5bVlOLsB4
# rzpJY2zieOAjdtQrqGcAPGVSWDDSeOl47e27KX2iHzjl7FnHk5lF+QCIykR6R9Ym
# R83UCcK1epAMPRYWfreU20ZSAEoeuT1pyVFlatU/EcQtN5dfksINMQya1ll38FBI
# h4l2k9jzfUqwItgwggYHMIID76ADAgECAgphFmg0AAAAAAAcMA0GCSqGSIb3DQEB
# BQUAMF8xEzARBgoJkiaJk/IsZAEZFgNjb20xGTAXBgoJkiaJk/IsZAEZFgltaWNy
# b3NvZnQxLTArBgNVBAMTJE1pY3Jvc29mdCBSb290IENlcnRpZmljYXRlIEF1dGhv
# cml0eTAeFw0wNzA0MDMxMjUzMDlaFw0yMTA0MDMxMzAzMDlaMHcxCzAJBgNVBAYT
# AlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYD
# VQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xITAfBgNVBAMTGE1pY3Jvc29mdCBU
# aW1lLVN0YW1wIFBDQTCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBAJ+h
# bLHf20iSKnxrLhnhveLjxZlRI1Ctzt0YTiQP7tGn0UytdDAgEesH1VSVFUmUG0KS
# rphcMCbaAGvoe73siQcP9w4EmPCJzB/LMySHnfL0Zxws/HvniB3q506jocEjU8qN
# +kXPCdBer9CwQgSi+aZsk2fXKNxGU7CG0OUoRi4nrIZPVVIM5AMs+2qQkDBuh/NZ
# MJ36ftaXs+ghl3740hPzCLdTbVK0RZCfSABKR2YRJylmqJfk0waBSqL5hKcRRxQJ
# gp+E7VV4/gGaHVAIhQAQMEbtt94jRrvELVSfrx54QTF3zJvfO4OToWECtR0Nsfz3
# m7IBziJLVP/5BcPCIAsCAwEAAaOCAaswggGnMA8GA1UdEwEB/wQFMAMBAf8wHQYD
# VR0OBBYEFCM0+NlSRnAK7UD7dvuzK7DDNbMPMAsGA1UdDwQEAwIBhjAQBgkrBgEE
# AYI3FQEEAwIBADCBmAYDVR0jBIGQMIGNgBQOrIJgQFYnl+UlE/wq4QpTlVnkpKFj
# pGEwXzETMBEGCgmSJomT8ixkARkWA2NvbTEZMBcGCgmSJomT8ixkARkWCW1pY3Jv
# c29mdDEtMCsGA1UEAxMkTWljcm9zb2Z0IFJvb3QgQ2VydGlmaWNhdGUgQXV0aG9y
# aXR5ghB5rRahSqClrUxzWPQHEy5lMFAGA1UdHwRJMEcwRaBDoEGGP2h0dHA6Ly9j
# cmwubWljcm9zb2Z0LmNvbS9wa2kvY3JsL3Byb2R1Y3RzL21pY3Jvc29mdHJvb3Rj
# ZXJ0LmNybDBUBggrBgEFBQcBAQRIMEYwRAYIKwYBBQUHMAKGOGh0dHA6Ly93d3cu
# bWljcm9zb2Z0LmNvbS9wa2kvY2VydHMvTWljcm9zb2Z0Um9vdENlcnQuY3J0MBMG
# A1UdJQQMMAoGCCsGAQUFBwMIMA0GCSqGSIb3DQEBBQUAA4ICAQAQl4rDXANENt3p
# tK132855UU0BsS50cVttDBOrzr57j7gu1BKijG1iuFcCy04gE1CZ3XpA4le7r1ia
# HOEdAYasu3jyi9DsOwHu4r6PCgXIjUji8FMV3U+rkuTnjWrVgMHmlPIGL4UD6ZEq
# JCJw+/b85HiZLg33B+JwvBhOnY5rCnKVuKE5nGctxVEO6mJcPxaYiyA/4gcaMvnM
# MUp2MT0rcgvI6nA9/4UKE9/CCmGO8Ne4F+tOi3/FNSteo7/rvH0LQnvUU3Ih7jDK
# u3hlXFsBFwoUDtLaFJj1PLlmWLMtL+f5hYbMUVbonXCUbKw5TNT2eb+qGHpiKe+i
# myk0BncaYsk9Hm0fgvALxyy7z0Oz5fnsfbXjpKh0NbhOxXEjEiZ2CzxSjHFaRkMU
# vLOzsE1nyJ9C/4B5IYCeFTBm6EISXhrIniIh0EPpK+m79EjMLNTYMoBMJipIJF9a
# 6lbvpt6Znco6b72BJ3QGEe52Ib+bgsEnVLaxaj2JoXZhtG6hE6a/qkfwEm/9ijJs
# sv7fUciMI8lmvZ0dhxJkAj0tr1mPuOQh5bWwymO0eFQF1EEuUKyUsKV4q7OglnUa
# 2ZKHE3UiLzKoCG6gW4wlv6DvhMoh1useT8ma7kng9wFlb4kLfchpyOZu6qeXzjEp
# /w7FW1zYTRuh2Povnj8uVRZryROj/TCCB3owggVioAMCAQICCmEOkNIAAAAAAAMw
# DQYJKoZIhvcNAQELBQAwgYgxCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5n
# dG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9y
# YXRpb24xMjAwBgNVBAMTKU1pY3Jvc29mdCBSb290IENlcnRpZmljYXRlIEF1dGhv
# cml0eSAyMDExMB4XDTExMDcwODIwNTkwOVoXDTI2MDcwODIxMDkwOVowfjELMAkG
# A1UEBhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQx
# HjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEoMCYGA1UEAxMfTWljcm9z
# b2Z0IENvZGUgU2lnbmluZyBQQ0EgMjAxMTCCAiIwDQYJKoZIhvcNAQEBBQADggIP
# ADCCAgoCggIBAKvw+nIQHC6t2G6qghBNNLrytlghn0IbKmvpWlCquAY4GgRJun/D
# DB7dN2vGEtgL8DjCmQawyDnVARQxQtOJDXlkh36UYCRsr55JnOloXtLfm1OyCizD
# r9mpK656Ca/XllnKYBoF6WZ26DJSJhIv56sIUM+zRLdd2MQuA3WraPPLbfM6XKEW
# 9Ea64DhkrG5kNXimoGMPLdNAk/jj3gcN1Vx5pUkp5w2+oBN3vpQ97/vjK1oQH01W
# KKJ6cuASOrdJXtjt7UORg9l7snuGG9k+sYxd6IlPhBryoS9Z5JA7La4zWMW3Pv4y
# 07MDPbGyr5I4ftKdgCz1TlaRITUlwzluZH9TupwPrRkjhMv0ugOGjfdf8NBSv4yU
# h7zAIXQlXxgotswnKDglmDlKNs98sZKuHCOnqWbsYR9q4ShJnV+I4iVd0yFLPlLE
# tVc/JAPw0XpbL9Uj43BdD1FGd7P4AOG8rAKCX9vAFbO9G9RVS+c5oQ/pI0m8GLhE
# fEXkwcNyeuBy5yTfv0aZxe/CHFfbg43sTUkwp6uO3+xbn6/83bBm4sGXgXvt1u1L
# 50kppxMopqd9Z4DmimJ4X7IvhNdXnFy/dygo8e1twyiPLI9AN0/B4YVEicQJTMXU
# pUMvdJX3bvh4IFgsE11glZo+TzOE2rCIF96eTvSWsLxGoGyY0uDWiIwLAgMBAAGj
# ggHtMIIB6TAQBgkrBgEEAYI3FQEEAwIBADAdBgNVHQ4EFgQUSG5k5VAF04KqFzc3
# IrVtqMp1ApUwGQYJKwYBBAGCNxQCBAweCgBTAHUAYgBDAEEwCwYDVR0PBAQDAgGG
# MA8GA1UdEwEB/wQFMAMBAf8wHwYDVR0jBBgwFoAUci06AjGQQ7kUBU7h6qfHMdEj
# iTQwWgYDVR0fBFMwUTBPoE2gS4ZJaHR0cDovL2NybC5taWNyb3NvZnQuY29tL3Br
# aS9jcmwvcHJvZHVjdHMvTWljUm9vQ2VyQXV0MjAxMV8yMDExXzAzXzIyLmNybDBe
# BggrBgEFBQcBAQRSMFAwTgYIKwYBBQUHMAKGQmh0dHA6Ly93d3cubWljcm9zb2Z0
# LmNvbS9wa2kvY2VydHMvTWljUm9vQ2VyQXV0MjAxMV8yMDExXzAzXzIyLmNydDCB
# nwYDVR0gBIGXMIGUMIGRBgkrBgEEAYI3LgMwgYMwPwYIKwYBBQUHAgEWM2h0dHA6
# Ly93d3cubWljcm9zb2Z0LmNvbS9wa2lvcHMvZG9jcy9wcmltYXJ5Y3BzLmh0bTBA
# BggrBgEFBQcCAjA0HjIgHQBMAGUAZwBhAGwAXwBwAG8AbABpAGMAeQBfAHMAdABh
# AHQAZQBtAGUAbgB0AC4gHTANBgkqhkiG9w0BAQsFAAOCAgEAZ/KGpZjgVHkaLtPY
# dGcimwuWEeFjkplCln3SeQyQwWVfLiw++MNy0W2D/r4/6ArKO79HqaPzadtjvyI1
# pZddZYSQfYtGUFXYDJJ80hpLHPM8QotS0LD9a+M+By4pm+Y9G6XUtR13lDni6WTJ
# RD14eiPzE32mkHSDjfTLJgJGKsKKELukqQUMm+1o+mgulaAqPyprWEljHwlpblqY
# luSD9MCP80Yr3vw70L01724lruWvJ+3Q3fMOr5kol5hNDj0L8giJ1h/DMhji8MUt
# zluetEk5CsYKwsatruWy2dsViFFFWDgycScaf7H0J/jeLDogaZiyWYlobm+nt3TD
# QAUGpgEqKD6CPxNNZgvAs0314Y9/HG8VfUWnduVAKmWjw11SYobDHWM2l4bf2vP4
# 8hahmifhzaWX0O5dY0HjWwechz4GdwbRBrF1HxS+YWG18NzGGwS+30HHDiju3mUv
# 7Jf2oVyW2ADWoUa9WfOXpQlLSBCZgB/QACnFsZulP0V3HjXG0qKin3p6IvpIlR+r
# +0cjgPWe+L9rt0uX4ut1eBrs6jeZeRhL/9azI2h15q/6/IvrC4DqaTuv/DDtBEyO
# 3991bWORPdGdVk5Pv4BXIqF4ETIheu9BCrE/+6jMpF3BoYibV3FWTkhFwELJm3Zb
# CoBIa/15n8G9bW1qyVJzEw16UM0xggSOMIIEigIBATCBlTB+MQswCQYDVQQGEwJV
# UzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UE
# ChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSgwJgYDVQQDEx9NaWNyb3NvZnQgQ29k
# ZSBTaWduaW5nIFBDQSAyMDExAhMzAAABBGni27n7ig2DAAAAAAEEMAkGBSsOAwIa
# BQCggaIwGQYJKoZIhvcNAQkDMQwGCisGAQQBgjcCAQQwHAYKKwYBBAGCNwIBCzEO
# MAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFHpbxLPXvYi+4hBGeQ375GaX
# oJ5rMEIGCisGAQQBgjcCAQwxNDAyoBSAEgBNAGkAYwByAG8AcwBvAGYAdKEagBho
# dHRwOi8vd3d3Lm1pY3Jvc29mdC5jb20wDQYJKoZIhvcNAQEBBQAEggEAfD5hhA5c
# ehxdv328b05EKCAn8FMJ3pDrOJqnIIQEiB5ZJKd6phCy7M0VZxgxJ20eWb5dhoGS
# BIlMSKGjuUU+24Qlkx/wKjdth1i8KWbsHyEK+y981uxw5VKiHpB4l7ExfjUFQuec
# DCgNxa4qFRgAm3MWQrJzt1z4y7HaJY/T435HLgJDL4TS8CWPH9A2fuOMh21OF0gH
# SYQKLPqZXHqfC9FfHEMnOTdml9mdFNdKeuwky+x9jYJznypLlGpZ/CfMTuCxcSZl
# bQ2ugStF7fD/yHgYnEcaz9E0DA34I8hAGEFIJxMpuNbXnCefxQcIORlrLt5U2p9J
# O6jNIlgYgFqRbKGCAigwggIkBgkqhkiG9w0BCQYxggIVMIICEQIBATCBjjB3MQsw
# CQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9u
# ZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSEwHwYDVQQDExhNaWNy
# b3NvZnQgVGltZS1TdGFtcCBQQ0ECEzMAAAEBeELJDLOo2LMAAAAAAQEwCQYFKw4D
# AhoFAKBdMBgGCSqGSIb3DQEJAzELBgkqhkiG9w0BBwEwHAYJKoZIhvcNAQkFMQ8X
# DTE5MDEwNzE3Mjk0NVowIwYJKoZIhvcNAQkEMRYEFFxxRPHPcYemBdCDJYOGk9V8
# ZSMPMA0GCSqGSIb3DQEBBQUABIIBAHpoKuXD+bqI8kM2xF7+nMyvNVPBHdH855BS
# YeRM3pwRwlNOtoRk5k3P/UHOf2HFa6XFhO+NoMfoDXEqXMlWziRAsshcJ1RDcu1D
# /X0Xr7FSNPLGXFAxHhDRpokqUkA9Vr4ntCuyhhByOxb9JWp5Gn7/lBadUojxcfOC
# UmqoK0IEwkj9NHZqhaD0W7yf3minr0UXeaZjAlzOl8/qlzYW3C0DWcPn8ZaCO7SO
# 3m1xIXfTblaJa6oD93Y6SLDBDl3cR/3OkdkKpZbv6FmQ1r23sSIDdp4VW7Fydoyc
# tuvyqrnZchkN8y2d9Q01ctGPYG6igEX87MYNEL1vEM5zWosbG2Y=
# SIG # End signature block
