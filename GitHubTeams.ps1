# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

@{
    GitHubTeamTypeName = 'GitHub.Team'
 }.GetEnumerator() | ForEach-Object {
     Set-Variable -Scope Script -Option ReadOnly -Name $_.Key -Value $_.Value
 }

filter Get-GitHubTeam
{
<#
    .SYNOPSIS
        Retrieve a team or teams within an organization or repository on GitHub.

    .DESCRIPTION
        Retrieve a team or teams within an organization or repository on GitHub.

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
        The name of the organization

    .PARAMETER TeamName
        The name of the specific team to retrieve

    .PARAMETER TeamId
        The ID of the specific team to retrieve

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
        GitHub.Organization
        GitHub.PullRequest
        GitHub.Project
        GitHub.ProjectCard
        GitHub.ProjectColumn
        GitHub.Release
        GitHub.Repository
        GitHub.Team

    .OUTPUTS
        GitHub.Team

    .EXAMPLE
        Get-GitHubTeam -OrganizationName PowerShell
#>
    [CmdletBinding(
        SupportsShouldProcess,
        DefaultParameterSetName='Elements')]
    [OutputType({$script:GitHubTeamTypeName})]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSShouldProcess", "", Justification="Methods called within here make use of PSShouldProcess, and the switch is passed on to them inherently.")]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSReviewUnusedParameter", "", Justification="One or more parameters (like NoStatus) are only referenced by helper methods which get access to it from the stack via Get-Variable -Scope 1.")]
    param
    (
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
            ValueFromPipelineByPropertyName,
            ParameterSetName='Organization')]
        [ValidateNotNullOrEmpty()]
        [string] $OrganizationName,

        [Parameter(ParameterSetName='Organization')]
        [Parameter(ParameterSetName='Elements')]
        [Parameter(ParameterSetName='Uri')]
        [string] $TeamName,

        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName='Single')]
        [ValidateNotNullOrEmpty()]
        [string] $TeamId,

        [string] $AccessToken,

        [switch] $NoStatus
    )

    Write-InvocationLog

    $telemetryProperties = @{}

    $uriFragment = [String]::Empty
    $description = [String]::Empty
    if ($PSCmdlet.ParameterSetName -in ('Elements', 'Uri'))
    {
        $elements = Resolve-RepositoryElements
        $OwnerName = $elements.ownerName
        $RepositoryName = $elements.repositoryName

        $telemetryProperties['OwnerName'] = Get-PiiSafeString -PlainText $OwnerName
        $telemetryProperties['RepositoryName'] = Get-PiiSafeString -PlainText $RepositoryName

        $uriFragment = "/repos/$OwnerName/$RepositoryName/teams"
        $description = "Getting teams for $RepositoryName"
    }
    elseif ($PSCmdlet.ParameterSetName -eq 'Organization')
    {
        $telemetryProperties['OrganizationName'] = Get-PiiSafeString -PlainText $OrganizationName

        $uriFragment = "/orgs/$OrganizationName/teams"
        $description = "Getting teams in $OrganizationName"
    }
    else
    {
        $telemetryProperties['TeamId'] = Get-PiiSafeString -PlainText $TeamId

        $uriFragment = "/teams/$TeamId"
        $description = "Getting team $TeamId"
    }

    $params = @{
        'UriFragment' = $uriFragment
        'AcceptHeader' = $script:hellcatAcceptHeader
        'Description' =  $description
        'AccessToken' = $AccessToken
        'TelemetryEventName' = $MyInvocation.MyCommand.Name
        'TelemetryProperties' = $telemetryProperties
        'NoStatus' = (Resolve-ParameterWithDefaultConfigurationValue -Name NoStatus -ConfigValueName DefaultNoStatus)
    }

    return (Invoke-GHRestMethodMultipleResult @params |
        Add-GitHubTeamAdditionalProperties)
}

filter Get-GitHubTeamMember
{
<#
    .SYNOPSIS
        Retrieve list of team members within an organization.

    .DESCRIPTION
        Retrieve list of team members within an organization.

        The Git repo for this module can be found here: http://aka.ms/PowerShellForGitHub

    .PARAMETER OrganizationName
        The name of the organization

    .PARAMETER TeamName
        The name of the team in the organization

    .PARAMETER TeamId
        The ID of the team in the organization

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
        GitHub.Team

    .OUTPUTS
        GitHub.User

    .EXAMPLE
        $members = Get-GitHubTeamMember -Organization PowerShell -TeamName Everybody
#>
    [CmdletBinding(
        SupportsShouldProcess,
        DefaultParameterSetName='ID')]
    [OutputType({$script:GitHubUserTypeName})]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSShouldProcess", "", Justification="Methods called within here make use of PSShouldProcess, and the switch is passed on to them inherently.")]
    param
    (
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [String] $OrganizationName,

        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName='Name')]
        [ValidateNotNullOrEmpty()]
        [String] $TeamName,

        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName='ID')]
        [int64] $TeamId,

        [string] $AccessToken,

        [switch] $NoStatus
    )

    Write-InvocationLog

    $NoStatus = Resolve-ParameterWithDefaultConfigurationValue -Name NoStatus -ConfigValueName DefaultNoStatus

    if ($PSCmdlet.ParameterSetName -eq 'Name')
    {
        $teams = Get-GitHubTeam -OrganizationName $OrganizationName -AccessToken $AccessToken -NoStatus:$NoStatus
        $team = $teams | Where-Object {$_.name -eq $TeamName}
        if ($null -eq $team)
        {
            $message = "Unable to find the team [$TeamName] within the organization [$OrganizationName]."
            Write-Log -Message $message -Level Error
            throw $message
        }

        $TeamId = $team.id
    }

    $telemetryProperties = @{
        'OrganizationName' = (Get-PiiSafeString -PlainText $OrganizationName)
        'TeamName' = (Get-PiiSafeString -PlainText $TeamName)
        'TeamId' = (Get-PiiSafeString -PlainText $TeamId)
    }

    $params = @{
        'UriFragment' = "teams/$TeamId/members"
        'Description' =  "Getting members of team $TeamId"
        'AccessToken' = $AccessToken
        'TelemetryEventName' = $MyInvocation.MyCommand.Name
        'TelemetryProperties' = $telemetryProperties
        'NoStatus' = $NoStatus
    }

    return (Invoke-GHRestMethodMultipleResult @params | Add-GitHubUserAdditionalProperties)
}

function New-GitHubTeam
{
<#
    .SYNOPSIS
        Creates a team within an organization on GitHub.

    .DESCRIPTION
        Creates a team or within an organization on GitHub.

        The Git repo for this module can be found here: http://aka.ms/PowerShellForGitHub

    .PARAMETER OrganizationName
        The name of the organization to create the team in.

    .PARAMETER TeamName
        The name of the team.

    .PARAMETER Description
        The description for the team.

    .PARAMETER Maintainers
        A list of GitHub IDs for organization members who will become team maintainers.

    .PARAMETER RepositoryName
        A list of repositories to add the team to.

    .PARAMETER Privacy
        The level of privacy this team should have.

    .PARAMETER ParentTeamName
        The name of a team to set as the parent team.

    .PARAMETER AccessToken
        If provided, this will be used as the AccessToken for authentication with the
        REST Api.  Otherwise, will attempt to use the configured value or will run unauthenticated.

    .PARAMETER NoStatus
        If this switch is specified, long-running commands will run on the main thread
        with no commandline status update.  When not specified, those commands run in
        the background, enabling the command prompt to provide status information.
        If not supplied here, the DefaultNoStatus configuration property value will be used.

    .OUTPUTS
        PSCustomObject

    .EXAMPLE
        New-GitHubTeam -OrganizationName PowerShell -TeamName MyTeam

        Creates a new GitHub team in the specified organization
#>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSShouldProcess', '',
        Justification = 'Methods called within here make use of PSShouldProcess, and the switch is passed on to them inherently.')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '',
        Justification = 'One or more parameters (like NoStatus) are only referenced by helper methods which get access to it from the stack via Get-Variable -Scope 1.')]
    [CmdletBinding(
        SupportsShouldProcess,
        PositionalBinding = $false
        )]
    param
    (
        [Parameter(Mandatory, Position = 1)]
        [ValidateNotNullOrEmpty()]
        [string] $OrganizationName,

        [Parameter(Mandatory, Position = 2)]
        [ValidateNotNullOrEmpty()]
        [string] $TeamName,

        [string] $Description,

        [string[]] $Maintainers,

        [string[]] $RepositoryName,

        [ValidateSet('Secret','Closed')]
        [string] $Privacy,

        [string] $ParentTeamName,

        [string] $AccessToken,

        [switch] $NoStatus
    )

    Write-InvocationLog -Invocation $MyInvocation

    $telemetryProperties = @{
        OrganizationName = (Get-PiiSafeString -PlainText $OrganizationName)
        TeamName = (Get-PiiSafeString -PlainText $TeamName)
    }

    $uriFragment = "/orgs/$OrganizationName/teams"

    $hashBody = @{
        name = $TeamName
    }

    if ($PSBoundParameters.ContainsKey('Description')) { $hashBody['description'] = $Description }
    if ($PSBoundParameters.ContainsKey('Maintainers')) { $hashBody['maintainers'] = $Maintainers }
    if ($PSBoundParameters.ContainsKey('RepositoryName')) { $hashBody['repo_names'] = $RepositoryName }
    if ($PSBoundParameters.ContainsKey('Privacy')) { $hashBody['privacy'] = $Privacy.ToLower() }
    if ($PSBoundParameters.ContainsKey('ParentTeamName'))
    {
        $getGitHubTeamParms = @{
            OrganizationName = $OrganizationName
            TeamName = $ParentTeamName
            AccessToken = $AccessToken
            NoStatus = $NoStatus
            Whatif = $false
            Confirm = $false
        }
        $team = Get-GitHubTeam @getGitHubTeamParms
        $hashBody['parent_team_id'] = $team.id
    }

    $params = @{
        UriFragment = $uriFragment
        Body = (ConvertTo-Json -InputObject $hashBody)
        Method = 'Post'
        Description =  "Creating $TeamName"
        AccessToken = $AccessToken
        TelemetryEventName = $MyInvocation.MyCommand.Name
        TelemetryProperties = $telemetryProperties
        NoStatus = (Resolve-ParameterWithDefaultConfigurationValue -Name NoStatus -ConfigValueName DefaultNoStatus)
    }

    return Invoke-GHRestMethod @params
}

function Update-GitHubTeam
{
<#
    .SYNOPSIS
        Updates a team within an organization on GitHub.

    .DESCRIPTION
        Updates a team within an organization on GitHub.

        The Git repo for this module can be found here: http://aka.ms/PowerShellForGitHub

    .PARAMETER OrganizationName
        The name of the team's organization.

    .PARAMETER TeamName
        The name of the team.

    .PARAMETER Description
        The description for the team.

    .PARAMETER Privacy
        The level of privacy this team should have.

    .PARAMETER ParentTeamName
        The name of a team to set as the parent team.

    .PARAMETER AccessToken
        If provided, this will be used as the AccessToken for authentication with the
        REST Api.  Otherwise, will attempt to use the configured value or will run unauthenticated.

    .PARAMETER NoStatus
        If this switch is specified, long-running commands will run on the main thread
        with no commandline status update.  When not specified, those commands run in
        the background, enabling the command prompt to provide status information.
        If not supplied here, the DefaultNoStatus configuration property value will be used.

    .OUTPUTS
        PSCustomObject

    .EXAMPLE
        Update-GitHubTeam -OrganizationName PowerShell -TeamName MyTeam -Description 'New Description'

        Updates the description for the specified GitHub team in the specified organization.
#>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSShouldProcess', '',
        Justification = 'Methods called within here make use of PSShouldProcess, and the switch is passed on to them inherently.')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '',
        Justification = 'One or more parameters (like NoStatus) are only referenced by helper methods which get access to it from the stack via Get-Variable -Scope 1.')]
        [CmdletBinding(
            SupportsShouldProcess,
            PositionalBinding = $false
            )]
        param
    (
        [Parameter(Mandatory, Position = 1)]
        [ValidateNotNullOrEmpty()]
        [string] $OrganizationName,

        [Parameter(Mandatory, Position = 2)]
        [ValidateNotNullOrEmpty()]
        [string] $TeamName,

        [string] $Description,

        [ValidateSet('Secret','Closed')]
        [string] $Privacy,

        [string] $ParentTeamName,

        [string] $AccessToken,

        [switch] $NoStatus
    )

    Write-InvocationLog -Invocation $MyInvocation

    $telemetryProperties = @{
        OrganizationName = (Get-PiiSafeString -PlainText $OrganizationName)
        TeamName = (Get-PiiSafeString -PlainText $TeamName)
    }

    $getGitHubTeamParms = @{
        OrganizationName = $OrganizationName
        TeamName = $teamName
        AccessToken = $AccessToken
        NoStatus = $NoStatus
        Whatif = $false
        Confirm = $false
    }
    $team = Get-GitHubTeam @getGitHubTeamParms

    $uriFragment = "/orgs/$OrganizationName/teams/$($team.slug)"

    $hashBody = @{
        name = $TeamName
    }

    if ($PSBoundParameters.ContainsKey('Description')) { $hashBody['description'] = $Description }
    if ($PSBoundParameters.ContainsKey('Privacy')) { $hashBody['privacy'] = $Privacy.ToLower() }
    if ($PSBoundParameters.ContainsKey('ParentTeamName'))
    {
        $getGitHubTeamParms = @{
            OrganizationName = $OrganizationName
            TeamName = $ParentTeamName
            AccessToken = $AccessToken
            NoStatus = $NoStatus
            Whatif = $false
            Confirm = $false
        }
        $team = Get-GitHubTeam @getGitHubTeamParms

        $hashBody['parent_team_id'] = $team.id
    }

    $params = @{
        UriFragment = $uriFragment
        Body = (ConvertTo-Json -InputObject $hashBody)
        Method = 'Patch'
        Description =  "Updating $TeamName"
        AccessToken = $AccessToken
        TelemetryEventName = $MyInvocation.MyCommand.Name
        TelemetryProperties = $telemetryProperties
        NoStatus = (Resolve-ParameterWithDefaultConfigurationValue -Name NoStatus -ConfigValueName DefaultNoStatus)
    }

    return Invoke-GHRestMethod @params
}

function Remove-GitHubTeam
{
<#
    .SYNOPSIS
        Removes a team within an organization on GitHub.

    .DESCRIPTION
        Removes a team within an organization on GitHub.

        The Git repo for this module can be found here: http://aka.ms/PowerShellForGitHub

    .PARAMETER OrganizationName
        The name of the organization the team is in.

    .PARAMETER TeamName
        The name of the team.

    .PARAMETER AccessToken
        If provided, this will be used as the AccessToken for authentication with the
        REST Api.  Otherwise, will attempt to use the configured value or will run unauthenticated.

    .PARAMETER NoStatus
        If this switch is specified, long-running commands will run on the main thread
        with no commandline status update.  When not specified, those commands run in
        the background, enabling the command prompt to provide status information.
        If not supplied here, the DefaultNoStatus configuration property value will be used.

    .OUTPUTS
        PSCustomObject

    .EXAMPLE
        Remove-GitHubTeam -OrganizationName PowerShell -TeamName MyTeam

        Removes the specified GitHub team from the specified organization
#>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSShouldProcess', '',
        Justification = 'Methods called within here make use of PSShouldProcess, and the switch is passed on to them inherently.')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '',
        Justification = 'One or more parameters (like NoStatus) are only referenced by helper methods which get access to it from the stack via Get-Variable -Scope 1.')]
    [CmdletBinding(
        SupportsShouldProcess,
        PositionalBinding = $false,
        ConfirmImpact = 'High'
        )]
    [Alias('Delete-GitHubTeam')]
    param
    (
        [Parameter(Mandatory, Position = 1)]
        [ValidateNotNullOrEmpty()]
        [string] $OrganizationName,

        [Parameter(Mandatory, Position = 2)]
        [ValidateNotNullOrEmpty()]
        [string] $TeamName,

        [string] $AccessToken,

        [switch] $NoStatus
    )

    Write-InvocationLog -Invocation $MyInvocation

    $telemetryProperties = @{
        OrganizationName = (Get-PiiSafeString -PlainText $RepositoryName)
        TeamName = (Get-PiiSafeString -PlainText $TeamName)
    }

    $getGitHubTeamParms = @{
        OrganizationName = $OrganizationName
        TeamName = $TeamName
        AccessToken = $AccessToken
        NoStatus = $NoStatus
        Whatif = $false
        Confirm = $false
    }
    $team = Get-GitHubTeam @getGitHubTeamParms

    $uriFragment = "/orgs/$OrganizationName/teams/$($team.slug)"

    if ($PSCmdlet.ShouldProcess($TeamName, "Remove Team"))
    {
        $params = @{
            UriFragment = $uriFragment
            Method = 'Delete'
            Description =  "Deleting $TeamName"
            AccessToken = $AccessToken
            TelemetryEventName = $MyInvocation.MyCommand.Name
            TelemetryProperties = $telemetryProperties
            NoStatus = (Resolve-ParameterWithDefaultConfigurationValue -Name NoStatus -ConfigValueName DefaultNoStatus)
        }

        return Invoke-GHRestMethod @params
    }
}

filter Add-GitHubTeamAdditionalProperties
{
<#
    .SYNOPSIS
        Adds type name and additional properties to ease pipelining to GitHub Team objects.

    .PARAMETER InputObject
        The GitHub object to add additional properties to.

    .PARAMETER TypeName
        The type that should be assigned to the object.

    .INPUTS
        [PSCustomObject]

    .OUTPUTS
        GitHub.Team
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
        [string] $TypeName = $script:GitHubTeamTypeName
    )

    foreach ($item in $InputObject)
    {
        $item.PSObject.TypeNames.Insert(0, $TypeName)

        if (-not (Get-GitHubConfiguration -Name DisablePipelineSupport))
        {
            Add-Member -InputObject $item -Name 'TeamName' -Value $item.name -MemberType NoteProperty -Force
            Add-Member -InputObject $item -Name 'TeamId' -Value $item.id -MemberType NoteProperty -Force

            # Apply these properties to any embedded parent teams as well.
            if ($null -ne $item.parent)
            {
                $null = Add-GitHubTeamAdditionalProperties -InputObject $item.parent
            }
        }

        Write-Output $item
    }
}
