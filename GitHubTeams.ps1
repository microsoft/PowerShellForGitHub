# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

@{
    GitHubTeamTypeName = 'GitHub.Team'
    GitHubTeamSummaryTypeName = 'GitHub.TeamSummary'
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
        The name of the organization.

    .PARAMETER TeamName
        The name of the specific team to retrieve.
        Note: This will be slower than querying by TeamSlug since it requires retrieving
        all teams first.

    .PARAMETER TeamSlug
        The slug (a unique key based on the team name) of the specific team to retrieve.

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
        GitHub.Organization
        GitHub.PullRequest
        GitHub.Project
        GitHub.ProjectCard
        GitHub.ProjectColumn
        GitHub.Reaction
        GitHub.Release
        GitHub.ReleaseAsset
        GitHub.Repository
        GitHub.Team

    .OUTPUTS
        GitHub.Team
        GitHub.TeamSummary

    .EXAMPLE
        Get-GitHubTeam -OrganizationName PowerShell
#>
    [CmdletBinding(DefaultParameterSetName = 'Elements')]
    [OutputType(
        {$script:GitHubTeamTypeName},
        {$script:GitHubTeamSummaryTypeName})]
    param
    (
        [Parameter(ParameterSetName='Elements')]
        [Parameter(ParameterSetName='TeamName')]
        [string] $OwnerName,

        [Parameter(ParameterSetName='Elements')]
        [Parameter(ParameterSetName='TeamName')]
        [string] $RepositoryName,

        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName='Uri')]
        [Parameter(
            ValueFromPipelineByPropertyName,
            ParameterSetName='TeamName')]
        [Alias('RepositoryUrl')]
        [string] $Uri,

        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName='Organization')]
        [Parameter(
            ValueFromPipelineByPropertyName,
            ParameterSetName='TeamName')]
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName='TeamSlug')]
        [ValidateNotNullOrEmpty()]
        [string] $OrganizationName,

        [Parameter(
            Mandatory,
            ParameterSetName='TeamName')]
        [ValidateNotNullOrEmpty()]
        [string] $TeamName,

        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName='TeamSlug')]
        [ValidateNotNullOrEmpty()]
        [string] $TeamSlug,

        [string] $AccessToken
    )

    Write-InvocationLog

    $telemetryProperties = @{}

    $uriFragment = [String]::Empty
    $description = [String]::Empty
    $teamType = [String]::Empty

    if ($PSBoundParameters.ContainsKey('TeamName') -and
        (-not $PSBoundParameters.ContainsKey('OrganizationName')))
    {
        $elements = Resolve-RepositoryElements
        $OwnerName = $elements.ownerName
        $RepositoryName = $elements.repositoryName
    }

    if ((-not [String]::IsNullOrEmpty($OwnerName)) -and
        (-not [String]::IsNullOrEmpty($RepositoryName)))
    {
        $telemetryProperties['OwnerName'] = Get-PiiSafeString -PlainText $OwnerName
        $telemetryProperties['RepositoryName'] = Get-PiiSafeString -PlainText $RepositoryName

        $uriFragment = "/repos/$OwnerName/$RepositoryName/teams"
        $description = "Getting teams for $RepositoryName"
        $teamType = $script:GitHubTeamSummaryTypeName
    }
    elseif ($PSCmdlet.ParameterSetName -eq 'TeamSlug')
    {
        $telemetryProperties['TeamSlug'] = Get-PiiSafeString -PlainText $TeamSlug

        $uriFragment = "/orgs/$OrganizationName/teams/$TeamSlug"
        $description = "Getting team $TeamSlug"
        $teamType = $script:GitHubTeamTypeName
    }
    else
    {
        $telemetryProperties['OrganizationName'] = Get-PiiSafeString -PlainText $OrganizationName

        $uriFragment = "/orgs/$OrganizationName/teams"
        $description = "Getting teams in $OrganizationName"
        $teamType = $script:GitHubTeamSummaryTypeName
    }

    $params = @{
        'UriFragment' = $uriFragment
        'AcceptHeader' = $script:hellcatAcceptHeader
        'Description' = $description
        'AccessToken' = $AccessToken
        'TelemetryEventName' = $MyInvocation.MyCommand.Name
        'TelemetryProperties' = $telemetryProperties
    }

    $result = Invoke-GHRestMethodMultipleResult @params |
        Add-GitHubTeamAdditionalProperties -TypeName $teamType

    if ($PSBoundParameters.ContainsKey('TeamName'))
    {
        $team = $result | Where-Object -Property name -eq $TeamName

        if ($null -eq $team)
        {
            $message = "Team '$TeamName' not found"
            Write-Log -Message $message -Level Error
            throw $message
        }
        else
        {
            $uriFragment = "/orgs/$($team.OrganizationName)/teams/$($team.slug)"
            $description = "Getting team $($team.slug)"

            $params = @{
                UriFragment = $uriFragment
                Description =  $description
                Method = 'Get'
                AccessToken = $AccessToken
                TelemetryEventName = $MyInvocation.MyCommand.Name
                TelemetryProperties = $telemetryProperties
            }

            $result = Invoke-GHRestMethod @params | Add-GitHubTeamAdditionalProperties
        }
    }

    return $result
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
        The name of the organization.

    .PARAMETER TeamName
        The name of the team in the organization.

    .PARAMETER TeamSlug
        The slug (a unique key based on the team name) of the team in the organization.

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
        GitHub.Team

    .OUTPUTS
        GitHub.User

    .EXAMPLE
        $members = Get-GitHubTeamMember -Organization PowerShell -TeamName Everybody
#>
    [CmdletBinding(DefaultParameterSetName = 'Slug')]
    [OutputType({$script:GitHubUserTypeName})]
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
            ParameterSetName='Slug')]
        [string] $TeamSlug,

        [string] $AccessToken
    )

    Write-InvocationLog

    if ($PSCmdlet.ParameterSetName -eq 'Name')
    {
        $teams = Get-GitHubTeam -OrganizationName $OrganizationName -AccessToken $AccessToken
        $team = $teams | Where-Object {$_.name -eq $TeamName}
        if ($null -eq $team)
        {
            $message = "Unable to find the team [$TeamName] within the organization [$OrganizationName]."
            Write-Log -Message $message -Level Error
            throw $message
        }

        $TeamSlug = $team.slug
    }

    $telemetryProperties = @{
        'OrganizationName' = (Get-PiiSafeString -PlainText $OrganizationName)
        'TeamName' = (Get-PiiSafeString -PlainText $TeamName)
        'TeamSlug' = (Get-PiiSafeString -PlainText $TeamSlug)
    }

    $params = @{
        'UriFragment' = "orgs/$OrganizationName/teams/$TeamSlug/members"
        'Description' = "Getting members of team $TeamSlug"
        'AccessToken' = $AccessToken
        'TelemetryEventName' = $MyInvocation.MyCommand.Name
        'TelemetryProperties' = $telemetryProperties
    }

    return (Invoke-GHRestMethodMultipleResult @params | Add-GitHubUserAdditionalProperties)
}

function New-GitHubTeam
{
<#
    .SYNOPSIS
        Creates a team within an organization on GitHub.

    .DESCRIPTION
        Creates a team within an organization on GitHub.

        The Git repo for this module can be found here: http://aka.ms/PowerShellForGitHub

    .PARAMETER OrganizationName
        The name of the organization to create the team in.

    .PARAMETER TeamName
        The name of the team.

    .PARAMETER Description
        The description for the team.

    .PARAMETER MaintainerName
        A list of GitHub user names for organization members who will become team maintainers.

    .PARAMETER RepositoryName
        The name of repositories to add the team to.

    .PARAMETER Privacy
        The level of privacy this team should have.

    .PARAMETER ParentTeamName
        The name of a team to set as the parent team.

    .PARAMETER ParentTeamId
        The ID of the team to set as the parent team.

    .PARAMETER AccessToken
        If provided, this will be used as the AccessToken for authentication with the
        REST Api.  Otherwise, will attempt to use the configured value or will run unauthenticated.

    .INPUTS
        GitHub.Team
        GitHub.User
        System.String

    .OUTPUTS
        GitHub.Team

    .EXAMPLE
        New-GitHubTeam -OrganizationName PowerShell -TeamName 'Developers'

        Creates a new GitHub team called 'Developers' in the 'PowerShell' organization.

    .EXAMPLE
        $teamName = 'Team1'
        $teamName | New-GitHubTeam -OrganizationName PowerShell

        You can also pipe in a team name that was returned from a previous command.

    .EXAMPLE
        $users = Get-GitHubUsers -OrganizationName PowerShell
        $users | New-GitHubTeam -OrganizationName PowerShell -TeamName 'Team1'

        You can also pipe in a list of GitHub users that were returned from a previous command.
#>
    [CmdletBinding(
        SupportsShouldProcess,
        PositionalBinding = $false,
        DefaultParameterSetName = 'ParentId'
    )]
    [OutputType({$script:GitHubTeamTypeName})]
    param
    (
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            Position = 1)]
        [ValidateNotNullOrEmpty()]
        [string] $OrganizationName,

        [Parameter(
            Mandatory,
            ValueFromPipeline,
            Position = 2)]
        [ValidateNotNullOrEmpty()]
        [string] $TeamName,

        [string] $Description,

        [Parameter(ValueFromPipelineByPropertyName)]
        [Alias('UserName')]
        [string[]] $MaintainerName,

        [string[]] $RepositoryName,

        [ValidateSet('Secret', 'Closed')]
        [string] $Privacy,

        [Parameter(ParameterSetName='ParentName')]
        [string] $ParentTeamName,

        [Parameter(
            ValueFromPipelineByPropertyName,
            ParameterSetName='ParentId')]
        [Alias('TeamId')]
        [int64] $ParentTeamId,

        [string] $AccessToken
    )

    begin
    {
        $maintainerNames = @()
    }

    process
    {
        foreach ($user in $MaintainerName)
        {
            $maintainerNames += $user
        }
    }

    end
    {
        Write-InvocationLog

        $telemetryProperties = @{
            OrganizationName = (Get-PiiSafeString -PlainText $OrganizationName)
            TeamName = (Get-PiiSafeString -PlainText $TeamName)
        }

        $uriFragment = "/orgs/$OrganizationName/teams"

        $hashBody = @{
            name = $TeamName
        }

        if ($PSBoundParameters.ContainsKey('Description')) { $hashBody['description'] = $Description }
        if ($PSBoundParameters.ContainsKey('RepositoryName'))
        {
            $repositoryFullNames = @()
            foreach ($repository in $RepositoryName)
            {
                $repositoryFullNames += "$OrganizationName/$repository"
            }
            $hashBody['repo_names'] = $repositoryFullNames
        }
        if ($PSBoundParameters.ContainsKey('Privacy')) { $hashBody['privacy'] = $Privacy.ToLower() }
        if ($MaintainerName.Count -gt 0)
        {
            $hashBody['maintainers'] = $maintainerNames
        }
        if ($PSBoundParameters.ContainsKey('ParentTeamName'))
        {
            $getGitHubTeamParms = @{
                OrganizationName = $OrganizationName
                TeamName = $ParentTeamName
            }
            if ($PSBoundParameters.ContainsKey('AccessToken'))
            {
                $getGitHubTeamParms['AccessToken'] = $AccessToken
            }

            $team = Get-GitHubTeam @getGitHubTeamParms
            $ParentTeamId = $team.id
        }

        if ($ParentTeamId -gt 0)
        {
            $hashBody['parent_team_id'] = $ParentTeamId
        }

        if (-not $PSCmdlet.ShouldProcess($TeamName, 'Create GitHub Team'))
        {
            return
        }

        $params = @{
            UriFragment = $uriFragment
            Body = (ConvertTo-Json -InputObject $hashBody)
            Method = 'Post'
            Description =  "Creating $TeamName"
            AccessToken = $AccessToken
            TelemetryEventName = $MyInvocation.MyCommand.Name
            TelemetryProperties = $telemetryProperties
        }

        return (Invoke-GHRestMethod @params | Add-GitHubTeamAdditionalProperties)
    }
}

filter Set-GitHubTeam
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

        When TeamSlug is specified, specifying a name here that is different from the existing
        name will cause the team to be renamed. TeamSlug and TeamName are specified for you
        automatically when piping in a GitHub.Team object, so a rename would only occur if
        intentionally specify this parameter and provide a different name.

    .PARAMETER TeamSlug
        The slug (a unique key based on the team name) of the team to update.

    .PARAMETER Description
        The description for the team.

    .PARAMETER Privacy
        The level of privacy this team should have.

    .PARAMETER ParentTeamName
        The name of a team to set as the parent team.

    .PARAMETER ParentTeamId
        The ID of the team to set as the parent team.

    .PARAMETER PassThru
        Returns the updated GitHub Team.  By default, this cmdlet does not generate any output.
        You can use "Set-GitHubConfiguration -DefaultPassThru" to control the default behavior
        of this switch.

    .PARAMETER AccessToken
        If provided, this will be used as the AccessToken for authentication with the
        REST Api.  Otherwise, will attempt to use the configured value or will run unauthenticated.

    .INPUTS
        GitHub.Organization
        GitHub.Team

    .OUTPUTS
        GitHub.Team

    .EXAMPLE
        Set-GitHubTeam -OrganizationName PowerShell -TeamName Developers -Description 'New Description'

        Updates the description for the 'Developers' GitHub team in the 'PowerShell' organization.

    .EXAMPLE
        $team = Get-GitHubTeam -OrganizationName PowerShell -TeamName Developers
        $team | Set-GitHubTeam -Description 'New Description'

        You can also pipe in a GitHub team that was returned from a previous command.
#>
    [CmdletBinding(
        SupportsShouldProcess,
        PositionalBinding = $false,
        DefaultParameterSetName = 'ParentName'
    )]
    [OutputType( { $script:GitHubTeamTypeName } )]
    param
    (
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            Position = 1)]
        [ValidateNotNullOrEmpty()]
        [string] $OrganizationName,

        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            Position = 2)]
        [ValidateNotNullOrEmpty()]
        [string] $TeamName,

        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [string] $TeamSlug,

        [string] $Description,

        [ValidateSet('Secret','Closed')]
        [string] $Privacy,

        [Parameter(ParameterSetName='ParentTeamName')]
        [string] $ParentTeamName,

        [Parameter(ParameterSetName='ParentTeamId')]
        [int64] $ParentTeamId,

        [switch] $PassThru,

        [string] $AccessToken
    )

    Write-InvocationLog

    $telemetryProperties = @{
        OrganizationName = (Get-PiiSafeString -PlainText $OrganizationName)
        TeamSlug = (Get-PiiSafeString -PlainText $TeamSlug)
        TeamName = (Get-PiiSafeString -PlainText $TeamName)
    }

    if ((-not $PSBoundParameters.ContainsKey('TeamSlug')) -or
        $PSBoundParameters.ContainsKey('ParentTeamName'))
    {
        $getGitHubTeamParms = @{
            OrganizationName = $OrganizationName
        }
        if ($PSBoundParameters.ContainsKey('AccessToken'))
        {
            $getGitHubTeamParms['AccessToken'] = $AccessToken
        }

        $orgTeams = Get-GitHubTeam @getGitHubTeamParms

        if ($PSBoundParameters.ContainsKey('TeamName'))
        {
            $team = $orgTeams | Where-Object -Property name -eq $TeamName
            $TeamSlug = $team.slug
        }
    }

    $uriFragment = "/orgs/$OrganizationName/teams/$TeamSlug"

    $hashBody = @{
        name = $TeamName
    }

    if ($PSBoundParameters.ContainsKey('Description')) { $hashBody['description'] = $Description }
    if ($PSBoundParameters.ContainsKey('Privacy')) { $hashBody['privacy'] = $Privacy.ToLower() }
    if ($PSBoundParameters.ContainsKey('ParentTeamName'))
    {
        $parentTeam = $orgTeams | Where-Object -Property name -eq $ParentTeamName
        $hashBody['parent_team_id'] = $parentTeam.id
    }
    elseif ($PSBoundParameters.ContainsKey('ParentTeamId'))
    {
        if ($ParentTeamId -gt 0)
        {
            $hashBody['parent_team_id'] = $ParentTeamId
        }
        else
        {
            $hashBody['parent_team_id'] = $null
        }
    }

    if (-not $PSCmdlet.ShouldProcess($TeamSlug, 'Set GitHub Team'))
    {
        return
    }

    $params = @{
        UriFragment = $uriFragment
        Body = (ConvertTo-Json -InputObject $hashBody)
        Method = 'Patch'
        Description =  "Updating $TeamName"
        AccessToken = $AccessToken
        TelemetryEventName = $MyInvocation.MyCommand.Name
        TelemetryProperties = $telemetryProperties
    }

    $result = (Invoke-GHRestMethod @params | Add-GitHubTeamAdditionalProperties)
    if (Resolve-ParameterWithDefaultConfigurationValue -Name PassThru -ConfigValueName DefaultPassThru)
    {
        return $result
    }
}

filter Rename-GitHubTeam
{
<#
    .SYNOPSIS
        Renames a team within an organization on GitHub.

    .DESCRIPTION
        Renames a team within an organization on GitHub.

        The Git repo for this module can be found here: http://aka.ms/PowerShellForGitHub

    .PARAMETER OrganizationName
        The name of the team's organization.

    .PARAMETER TeamName
        The existing name of the team.

    .PARAMETER TeamSlug
        The slug (a unique key based on the team name) of the team to update.

    .PARAMETER NewTeamName
        The new name for the team.

    .PARAMETER PassThru
        Returns the updated GitHub Team.  By default, this cmdlet does not generate any output.
        You can use "Set-GitHubConfiguration -DefaultPassThru" to control the default behavior
        of this switch.

    .PARAMETER AccessToken
        If provided, this will be used as the AccessToken for authentication with the
        REST Api.  Otherwise, will attempt to use the configured value or will run unauthenticated.

    .INPUTS
        GitHub.Organization
        GitHub.Team

    .OUTPUTS
        GitHub.Team

    .EXAMPLE
        Rename-GitHubTeam -OrganizationName PowerShell -TeamName Developers -NewTeamName DeveloperTeam

        Renames the 'Developers' GitHub team in the 'PowerShell' organization to be 'DeveloperTeam'.

    .EXAMPLE
        $team = Get-GitHubTeam -OrganizationName PowerShell -TeamName Developers
        $team | Rename-GitHubTeam -NewTeamName 'DeveloperTeam'

        You can also pipe in a GitHub team that was returned from a previous command.

    .NOTES
        This is a helper/wrapper for Set-GitHubTeam which can also rename a GitHub Team.
#>
    [CmdletBinding(
        PositionalBinding = $false,
        DefaultParameterSetName = 'TeamSlug')]
    [OutputType( { $script:GitHubTeamTypeName } )]
    param
    (
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            Position = 1)]
        [ValidateNotNullOrEmpty()]
        [string] $OrganizationName,

        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            Position = 2,
            ParameterSetName='TeamName')]
        [ValidateNotNullOrEmpty()]
        [string] $TeamName,

        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName='TeamSlug')]
        [ValidateNotNullOrEmpty()]
        [string] $TeamSlug,

        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            Position = 3)]
        [ValidateNotNullOrEmpty()]
        [string] $NewTeamName,

        [switch] $PassThru,

        [string] $AccessToken
    )

    Write-InvocationLog

    if (-not $PSBoundParameters.ContainsKey('TeamSlug'))
    {
        $team = Get-GitHubTeam -OrganizationName $OrganizationName -TeamName $TeamName -AccessToken:$AccessToken
        $TeamSlug = $team.slug
    }

    $params = @{
        OrganizationName = $OrganizationName
        TeamSlug = $TeamSlug
        TeamName = $NewTeamName
        PassThru = (Resolve-ParameterWithDefaultConfigurationValue -Name PassThru -ConfigValueName DefaultPassThru)
        AccessToken = $AccessToken
    }

    return Set-GitHubTeam @params
}

filter Remove-GitHubTeam
{
<#
    .SYNOPSIS
        Removes a team from an organization on GitHub.

    .DESCRIPTION
        Removes a team from an organization on GitHub.

        The Git repo for this module can be found here: http://aka.ms/PowerShellForGitHub

    .PARAMETER OrganizationName
        The name of the organization the team is in.

    .PARAMETER TeamName
        The name of the team to remove.

    .PARAMETER TeamSlug
        The slug (a unique key based on the team name) of the team to remove.

    .PARAMETER Force
        If this switch is specified, you will not be prompted for confirmation of command execution.

    .PARAMETER AccessToken
        If provided, this will be used as the AccessToken for authentication with the
        REST Api.  Otherwise, will attempt to use the configured value or will run unauthenticated.

    .INPUTS
        GitHub.Organization
        GitHub.Team

    .OUTPUTS
        None

    .EXAMPLE
        Remove-GitHubTeam -OrganizationName PowerShell -TeamName Developers

        Removes the 'Developers' GitHub team from the 'PowerShell' organization.

    .EXAMPLE
        Remove-GitHubTeam -OrganizationName PowerShell -TeamName Developers -Force

        Removes the 'Developers' GitHub team from the 'PowerShell' organization without prompting.

    .EXAMPLE
        $team = Get-GitHubTeam -OrganizationName PowerShell -TeamName Developers
        $team | Remove-GitHubTeam -Force

        You can also pipe in a GitHub team that was returned from a previous command.
#>
    [CmdletBinding(
        SupportsShouldProcess,
        PositionalBinding = $false,
        ConfirmImpact = 'High',
        DefaultParameterSetName = 'TeamSlug')]
    [Alias('Delete-GitHubTeam')]
    param
    (
        [Parameter(
            Mandatory,
            ValueFromPipeline,
            ValueFromPipelineByPropertyName,
            Position = 1)]
        [ValidateNotNullOrEmpty()]
        [string] $OrganizationName,

        [Parameter(
            Mandatory,
            ValueFromPipeline,
            ValueFromPipelineByPropertyName,
            Position = 2,
            ParameterSetName='TeamName')]
        [ValidateNotNullOrEmpty()]
        [string] $TeamName,

        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName='TeamSlug')]
        [ValidateNotNullOrEmpty()]
        [string] $TeamSlug,

        [switch] $Force,

        [string] $AccessToken
    )

    Write-InvocationLog

    $telemetryProperties = @{
        OrganizationName = (Get-PiiSafeString -PlainText $RepositoryName)
        TeamSlug = (Get-PiiSafeString -PlainText $TeamSlug)
        TeamName = (Get-PiiSafeString -PlainText $TeamName)
    }

    if ($PSBoundParameters.ContainsKey('TeamName'))
    {
        $getGitHubTeamParms = @{
            OrganizationName = $OrganizationName
            TeamName = $TeamName
        }
        if ($PSBoundParameters.ContainsKey('AccessToken'))
        {
            $getGitHubTeamParms['AccessToken'] = $AccessToken
        }

        $team = Get-GitHubTeam @getGitHubTeamParms
        $TeamSlug = $team.slug
    }

    $uriFragment = "/orgs/$OrganizationName/teams/$TeamSlug"

    if ($Force -and (-not $Confirm))
    {
        $ConfirmPreference = 'None'
    }

    if (-not $PSCmdlet.ShouldProcess($TeamName, 'Remove Github Team'))
    {
        return
    }

    $params = @{
        UriFragment = $uriFragment
        Method = 'Delete'
        Description =  "Deleting $TeamSlug"
        AccessToken = $AccessToken
        TelemetryEventName = $MyInvocation.MyCommand.Name
        TelemetryProperties = $telemetryProperties
    }

    Invoke-GHRestMethod @params | Out-Null
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
            Add-Member -InputObject $item -Name 'TeamSlug' -Value $item.slug -MemberType NoteProperty -Force

            $organizationName = [String]::Empty
            if ($item.organization)
            {
                $organizationName = $item.organization.login
            }
            else
            {
                $hostName = $(Get-GitHubConfiguration -Name 'ApiHostName')

                if ($item.html_url -match "^https?://$hostName/orgs/([^/]+)/.*$")
                {
                    $organizationName = $Matches[1]
                }
            }

            Add-Member -InputObject $item -Name 'OrganizationName' -Value $organizationName -MemberType NoteProperty -Force

            # Apply these properties to any embedded parent teams as well.
            if ($null -ne $item.parent)
            {
                $null = Add-GitHubTeamAdditionalProperties -InputObject $item.parent
            }
        }

        Write-Output $item
    }
}
