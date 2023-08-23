# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

@{
    GitHubCodespaceTypeName = 'GitHub.Codespace'
}.GetEnumerator() | ForEach-Object {
    Set-Variable -Scope Script -Option ReadOnly -Name $_.Key -Value $_.Value
}

filter Get-GitHubCodespace
{
    <#
    .SYNOPSIS
        Retrieves information about a Codespace or list of codespaces on GitHub.

    .DESCRIPTION
        Retrieves information about a Codespace or list of codespaces on GitHub.

        The Git repo for this module can be found here: http://aka.ms/PowerShellForGitHub

    .PARAMETER OwnerName
        Owner of the Codespace.
        If not supplied here, the DefaultOwnerName configuration property value will be used.

    .PARAMETER RepositoryName
        Name of the repository.
        If not supplied here, the DefaultRepositoryName configuration property value will be used.

    .PARAMETER Uri
        Uri for the Codespace.
        The OwnerName and CodespaceName will be extracted from here instead of needing to provide
        them individually.

    .PARAMETER OrganizationName
        Name of the Organization.

    .PARAMETER UserName
        The handle for the GitHub user account.

    .PARAMETER CodespaceName
        Name of the Codespace.

    .PARAMETER AccessToken
        If provided, this will be used as the AccessToken for authentication with the
        REST Api.  Otherwise, will attempt to use the configured value or will run unauthenticated.

    .INPUTS
        GitHub.Codespace
        GitHub.Project
        GitHub.Repository
        GitHub.User

    .OUTPUTS
        GitHub.Codespace

    .EXAMPLE
        Get-GitHubCodespace

        Gets all codespaces for the current authenticated user.

    .EXAMPLE
        Get-GitHubCodespace -OwnerName octocat

        Gets all of the codespaces for the user octocat

    .EXAMPLE
        Get-GitHubUser -UserName octocat | Get-GitHubCodespace

        Gets all of the codespaces for the user octocat

    .EXAMPLE
        Get-GitHubCodespace -Uri https://github.com/microsoft/PowerShellForGitHub

        Gets information about the microsoft/PowerShellForGitHub Codespace.

    .EXAMPLE
        $repo | Get-GitHubCodespace

        You can pipe in a previous Codespace to get its refreshed information.

    .EXAMPLE
        Get-GitHubCodespace -OrganizationName PowerShell

        Gets all of the codespaces in the PowerShell organization.

    .LINK
        https://docs.github.com/en/rest/codespaces/codespaces?apiVersion=2022-11-28#get-a-codespace-for-the-authenticated-user

    .LINK
        https://docs.github.com/en/rest/codespaces/codespaces?apiVersion=2022-11-28#list-codespaces-in-a-repository-for-the-authenticated-user

    .LINK
        https://docs.github.com/en/rest/codespaces/codespaces?apiVersion=2022-11-28#list-codespaces-for-the-authenticated-user

    .LINK
        https://docs.github.com/en/rest/codespaces/organizations?apiVersion=2022-11-28#list-codespaces-for-the-organization

    .LINK
        https://docs.github.com/en/rest/codespaces/organizations?apiVersion=2022-11-28#list-codespaces-for-a-user-in-organization
#>
    [CmdletBinding(DefaultParameterSetName = 'AuthenticatedUser')]
    [OutputType({ $script:GitHubCodespaceTypeName })]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '', Justification = 'The Uri parameter is only referenced by Resolve-RepositoryElements which get access to it from the stack via Get-Variable -Scope 1.')]
    param(
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName = 'Elements')]
        [string] $OwnerName,

        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName = 'Elements')]
        [string] $RepositoryName,

        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName = 'Uri')]
        [Alias('RepositoryUrl')]
        [string] $Uri,

        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName = 'Organization')]
        [string] $OrganizationName,

        [Parameter(
            ValueFromPipelineByPropertyName,
            ParameterSetName = 'Organization')]
        [ValidateNotNullOrEmpty()]
        [String] $UserName,

        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName = 'CodespaceName')]
        [string] $CodespaceName,

        [string] $AccessToken
    )

    Write-InvocationLog

    $telemetryProperties = @{
        UsageType = $PSCmdlet.ParameterSetName
    }

    $uriFragment = [String]::Empty
    $description = [String]::Empty
    switch ($PSCmdlet.ParameterSetName)
    {
        'AuthenticatedUser'
        {
            $uriFragment = 'user/codespaces'
            $description = 'Getting codespaces for current authenticated user'

            break
        }

        'CodespaceName'
        {
            $telemetryProperties['CodespaceName'] = Get-PiiSafeString -PlainText $CodespaceName

            $uriFragment = "user/codespaces/$CodespaceName"
            $description = "Getting user/codespaces/$CodespaceName"

            break
        }

        'Organization'
        {
            $telemetryProperties['OrganizationName'] = Get-PiiSafeString -PlainText $OrganizationName
            if ([string]::IsNullOrWhiteSpace($UserName))
            {
                $uriFragment = "orgs/$OrganizationName/codespaces"
                $description = "Getting codespaces for $OrganizationName"
            }
            else
            {
                $telemetryProperties['UserName'] = Get-PiiSafeString -PlainText $UserName
                $uriFragment = "orgs/$OrganizationName/members/$UserName/codespaces"
                $description = "Getting codespaces for $OrganizationName"
            }

            break
        }

        { $_ -in ('Elements', 'Uri') }
        {
            $elements = Resolve-RepositoryElements
            $OwnerName = $elements.ownerName
            $RepositoryName = $elements.repositoryName

            $telemetryProperties['OwnerName'] = Get-PiiSafeString -PlainText $OwnerName
            $telemetryProperties['RepositoryName'] = Get-PiiSafeString -PlainText $RepositoryName

            $uriFragment = "repos/$OwnerName/$RepositoryName/codespaces"
            $description = "Getting $OwnerName/$RepositoryName/codespaces"

            break
        }
    }

    $params = @{
        UriFragment = $uriFragment
        Description = $description
        AccessToken = $AccessToken
        TelemetryEventName = $MyInvocation.MyCommand.Name
        TelemetryProperties = $telemetryProperties
    }

    $result = Invoke-GHRestMethodMultipleResult @params
    if ($null -ne $result.codespaces)
    {
        $result = $result.codespaces
    }

    return ($result | Add-GitHubCodespaceAdditionalProperties)
}

function New-GitHubCodespace
{
    <#
    .SYNOPSIS
        Creates a codespace.

    .DESCRIPTION
        Creates a codespace.

        The Git repo for this module can be found here: http://aka.ms/PowerShellForGitHub

    .PARAMETER OwnerName
        Owner of the Codespace.
        If not supplied here, the DefaultOwnerName configuration property value will be used.

    .PARAMETER RepositoryName
        Name of the repository.
        If not supplied here, the DefaultRepositoryName configuration property value will be used.

    .PARAMETER Uri
        Uri for the Codespace.
        The OwnerName and CodespaceName will be extracted from here instead of needing to provide
        them individually.

    .PARAMETER PullRequest
        The pull request number for this codespace.

    .PARAMETER RepositoryId
        The ID for a Repository.  Only applicable when creating a codespace for the current authenticated user.

    .PARAMETER Ref
        Git ref (typically a branch name) for this codespace

    .PARAMETER ClientIp
        IP for geo auto-detection when proxying a request.

    .PARAMETER DevContainerPath
        Path to devcontainer.json config to use for this codespace.

    .PARAMETER DisplayName
        Display name for this codespace

    .PARAMETER Geo
        The geographic area for this codespace.
        Assigned by IP if not provided.

    .PARAMETER Machine
        Machine type to use for this codespace.

    .PARAMETER NoMultipleRepoPermissions
        Whether to authorize requested permissions to other repos from devcontainer.json.

    .PARAMETER IdleRetentionPeriodMinutes
        Duration in minutes (up to 30 days) after codespace has gone idle in which it will be deleted.

    .PARAMETER TimeoutMinutes
        Time in minutes before codespace stops from inactivity.

    .PARAMETER WorkingDirectory
        Working directory for this codespace.

    .PARAMETER Wait
        If present will wait for the codespace to be available.

    .PARAMETER AccessToken
        If provided, this will be used as the AccessToken for authentication with the
        REST Api.  Otherwise, will attempt to use the configured value or will run unauthenticated.

    .INPUTS
        GitHub.Codespace
        GitHub.Project
        GitHub.PullRequest
        GitHub.Repository

    .OUTPUTS
        GitHub.Codespace

    .EXAMPLE
        New-GitHubCodespace -RepositoryId 582779513

        Creates a new codespace for the current authenticated user in the specified repository.

    .EXAMPLE
        New-GitHubCodespace -RepositoryId 582779513 -PullRequest 508

        Creates a new codespace for the current authenticated user in the specified repository from a pull request.

    .EXAMPLE
        New-GitHubCodespace -OwnerName marykay -RepositoryName one

        Creates a codespace owned by the authenticated user in the specified repository.

    .LINK
        https://docs.github.com/en/rest/codespaces/codespaces?apiVersion=2022-11-28#create-a-codespace-for-the-authenticated-user

    .LINK
        https://docs.github.com/en/rest/codespaces/codespaces?apiVersion=2022-11-28#create-a-codespace-in-a-repository

    .LINK
        https://docs.github.com/en/rest/codespaces/codespaces?apiVersion=2022-11-28#create-a-codespace-from-a-pull-request
#>
    [CmdletBinding(
        SupportsShouldProcess,
        DefaultParameterSetName = 'AuthenticatedUser')]
    [OutputType({ $script:GitHubCodespaceTypeName })]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '', Justification = 'The Uri parameter is only referenced by Resolve-RepositoryElements which get access to it from the stack via Get-Variable -Scope 1, and most of the others get dynamically accessed via $propertyMap.')]
    param(
        [Parameter(
            Mandatory,
            ParameterSetName = 'Elements')]
        [Parameter(
            Mandatory,
            ParameterSetName = 'ElementsPullRequest')]
        [string] $OwnerName,

        [Parameter(
            Mandatory,
            ParameterSetName = 'Elements')]
        [Parameter(
            Mandatory,
            ParameterSetName = 'ElementsPullRequest')]
        [string] $RepositoryName,

        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName = 'Uri')]
        [Alias('RepositoryUrl')]
        [Alias('PullRequestUrl')]
        [string] $Uri,

        [Parameter(ParameterSetName = 'AuthenticatedUser')]
        [Parameter(
            Mandatory,
            ParameterSetName = 'ElementsPullRequest')]
        [Alias('PullRequestNumber')]
        [int64] $PullRequest,

        [Parameter(
            Mandatory,
            ParameterSetName = 'AuthenticatedUser')]
        [Int64] $RepositoryId,

        [Parameter(ParameterSetName = 'AuthenticatedUser')]
        [Parameter(ParameterSetName = 'Elements')]
        [string] $Ref,

        [string] $ClientIp,

        [string] $DevContainerPath,

        [string] $DisplayName,

        [ValidateSet('EuropeWest', 'SoutheastAsia', 'UsEast', 'UsWest')]
        [string] $Geo,

        [string] $Machine,

        [switch] $NoMultipleRepoPermissions,

        [ValidateRange(0, 43200)]
        [int] $IdleRetentionPeriodMinutes,

        [ValidateRange(5, 240)]
        [int] $TimeoutMinutes,

        [string] $WorkingDirectory,

        [switch] $Wait,

        [string] $AccessToken
    )

    begin
    {
        Write-InvocationLog

        $propertyMap = @{
            ClientIp = 'client_ip'
            DevContainerPath = 'devcontainer_path'
            DisplayName = 'display_name'
            Geo = 'geo'
            Machine = 'machine'
            Ref = 'ref'
            IdleRetentionPeriodMinutes = 'retention_period_minutes'
            TimeoutMinutes = 'idle_timeout_minutes'
            WorkingDirectory = 'working_directory'
        }
    }

    process
    {
        $telemetryProperties = @{
            UsageType = $PSCmdlet.ParameterSetName
            Wait = $Wait.IsPresent
        }

        $uriFragment = [String]::Empty
        $description = [String]::Empty
        if ($PSCmdlet.ParameterSetName -eq 'AuthenticatedUser')
        {
            $uriFragment = 'user/codespaces'
            $description = 'Create a codespace for current authenticated user'
        }
        else
        {
            # ParameterSets: Elements, ElementsPullRequest, Uri
            # ElementsPullRequest prevents Ref for /repos/{owner}/{repo}/pulls/{pull_number}/codespaces
            $elements = Resolve-RepositoryElements
            $OwnerName = $elements.ownerName
            $RepositoryName = $elements.repositoryName

            $telemetryProperties['OwnerName'] = Get-PiiSafeString -PlainText $OwnerName
            $telemetryProperties['RepositoryName'] = Get-PiiSafeString -PlainText $RepositoryName

            if ($PSCmdlet.ParameterSetName -eq 'ElementsPullRequest')
            {
                $description = "Create a codespace from $OwnerName/$RepositoryName/pulls/$PullRequest"
                $telemetryProperties['PullRequest'] = $PullRequest
                $uriFragment = "repos/$OwnerName/$RepositoryName/pulls/$PullRequest/codespaces"
            }
            else
            {
                $description = "Create a codepace in $OwnerName/$RepositoryName"
                $uriFragment = "repos/$OwnerName/$RepositoryName/codespaces"
            }
        }

        $hashBody = @{
            multi_repo_permissions_opt_out = $NoMultipleRepoPermissions.IsPresent
        }

        # Map params to hashBody properties
        foreach ($p in $PSBoundParameters.GetEnumerator())
        {
            if ($propertyMap.ContainsKey($p.Key) -and (-not [string]::IsNullOrWhiteSpace($p.Value)))
            {
                $hashBody.Add($propertyMap[$p.Key], $p.Value)
            }
        }

        if ($PSCmdlet.ParameterSetName -eq 'AuthenticatedUser')
        {
            if ($PSBoundParameters.ContainsKey('PullRequest'))
            {
                $hashBody.Add('pull_request',
                    [PSCustomObject]@{
                        pull_request_number = $PullRequest
                        repository_id = $RepositoryId
                    }
                )
            }
            else
            {
                $hashBody.Add('repository_id', $RepositoryId)
            }
        }

        $params = @{
            UriFragment = $uriFragment
            Body = (ConvertTo-Json -InputObject $hashBody -Depth 5)
            Method = 'Post'
            Description = $description
            AccessToken = $AccessToken
            TelemetryEventName = $MyInvocation.MyCommand.Name
            TelemetryProperties = $telemetryProperties
        }

        if (-not $PSCmdlet.ShouldProcess($RepositoryName, 'Create GitHub Codespace'))
        {
            return
        }

        $result = (Invoke-GHRestMethod @params | Add-GitHubCodespaceAdditionalProperties)

        if ($Wait.IsPresent)
        {
            $waitParams = @{
                CodespaceName = $result.CodespaceName
                AccessToken = $AccessToken
            }

            $result = Wait-GitHubCodespaceAction @waitParams
        }

        return $result
    }
}

filter Remove-GitHubCodespace
{
    <#
    .SYNOPSIS
        Remove a Codespace.

    .DESCRIPTION
        Remove a Codespace.

        The Git repo for this module can be found here: http://aka.ms/PowerShellForGitHub

    .PARAMETER OrganizationName
        Name of the Organization.

    .PARAMETER UserName
        The handle for the GitHub user account.

    .PARAMETER CodespaceName
        Name of the Codespace.

    .PARAMETER Force
        If this switch is specified, you will not be prompted for confirmation of command execution.

    .PARAMETER AccessToken
        If provided, this will be used as the AccessToken for authentication with the
        REST Api.  Otherwise, will attempt to use the configured value or will run unauthenticated.

    .INPUTS
        GitHub.Codespace

    .OUTPUTS
        None

    .EXAMPLE
        Get-GitHubCodespace -Name vercellone-effective-goggles-qrv997q6j9929jx8 | Remove-GitHubCodespace

    .EXAMPLE
        Remove-GitHubCodespace -Name vercellone-effective-goggles-qrv997q6j9929jx8

    .EXAMPLE
        Remove-GitHubCodespace -OrganizationName myorg -UserName jetsong -Name jetsong-button-masher-zzz788y6j8288xp1

    .LINK
        https://docs.github.com/en/rest/codespaces/codespaces?apiVersion=2022-11-28#delete-a-codespace-for-the-authenticated-user

    .LINK
        https://docs.github.com/en/rest/codespaces/organizations?apiVersion=2022-11-28#delete-a-codespace-from-the-organization
#>
    [CmdletBinding(
        DefaultParameterSetName = 'AuthenticatedUser',
        SupportsShouldProcess,
        ConfirmImpact = 'High')]
    [Alias('Delete-GitHubCodespace')]
    param(
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName = 'Organization')]
        [string] $OrganizationName,

        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName = 'Organization')]
        [ValidateNotNullOrEmpty()]
        [String] $UserName,

        [Parameter(
            Mandatory,
            ValueFromPipeline,
            ValueFromPipelineByPropertyName)]
        [string] $CodespaceName,

        [switch] $Force,

        [string] $AccessToken
    )

    Write-InvocationLog

    $telemetryProperties = @{
        CodespaceName = Get-PiiSafeString -PlainText $CodespaceName
    }

    $uriFragment = [String]::Empty
    if ($PSCmdlet.ParameterSetName -eq 'AuthenticatedUser')
    {
        $uriFragment = "user/codespaces/$CodespaceName"
    }
    else
    {
        $uriFragment = "orgs/$OrganizationName/members/$UserName/codespaces/$CodespaceName"
    }

    $params = @{
        UriFragment = $uriFragment
        Method = 'Delete'
        Description = "Remove Codespace $CodespaceName"
        AccessToken = $AccessToken
        TelemetryEventName = $MyInvocation.MyCommand.Name
        TelemetryProperties = $telemetryProperties
    }

    if ($Force -and (-not $Confirm))
    {
        $ConfirmPreference = 'None'
    }

    if (-not $PSCmdlet.ShouldProcess($CodespaceName, "Remove Codespace $CodespaceName"))
    {
        return
    }

    Invoke-GHRestMethod @params | Out-Null
}

filter Start-GitHubCodespace
{
    <#
    .SYNOPSIS
        Start a Codespace for the currently authenticated user.

    .DESCRIPTION
        Start a Codespace for the currently authenticated user.

        The Git repo for this module can be found here: http://aka.ms/PowerShellForGitHub

    .PARAMETER CodespaceName
        Name of the Codespace.

    .PARAMETER Wait
        If present will wait for the codespace to start.

    .PARAMETER PassThru
        Returns the start action result.  By default, this cmdlet does not generate any output.
        You can use "Set-GitHubConfiguration -DefaultPassThru" to control the default behavior
        of this switch.

    .PARAMETER AccessToken
        If provided, this will be used as the AccessToken for authentication with the
        REST Api.  Otherwise, will attempt to use the configured value or will run unauthenticated.

    .INPUTS
        GitHub.Codespace

    .OUTPUTS
        GitHub.Codespace

    .EXAMPLE
        Start-GitHubCodespace -Name vercellone-effective-goggles-qrv997q6j9929jx8

    .LINK
        https://docs.github.com/en/rest/codespaces/codespaces?apiVersion=2022-11-28#start-a-codespace-for-the-authenticated-user

    .NOTES
        You must authenticate using an access token with the codespace scope to use this endpoint.
        GitHub Apps must have write access to the codespaces_lifecycle_admin repository permission to use this endpoint.
#>
    [CmdletBinding(
        SupportsShouldProcess,
        ConfirmImpact = 'Low')]
    [OutputType({ $script:GitHubCodespaceTypeName })]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '', Justification = 'PassThru is accessed indirectly via Resolve-ParameterWithDefaultConfigurationValue')]
    param(
        [Parameter(
            Mandatory,
            ValueFromPipeline,
            ValueFromPipelineByPropertyName)]
        [string] $CodespaceName,

        [switch] $Wait,

        [switch] $PassThru,

        [string] $AccessToken
    )

    Write-InvocationLog

    $telemetryProperties = @{
        CodespaceName = Get-PiiSafeString -PlainText $CodespaceName
        Wait = $Wait.IsPresent
    }

    $params = @{
        UriFragment = "user/codespaces/$CodespaceName/start"
        Method = 'Post'
        Description = "Start Codespace $CodespaceName"
        AccessToken = $AccessToken
        TelemetryEventName = $MyInvocation.MyCommand.Name
        TelemetryProperties = $telemetryProperties
    }

    if (-not $PSCmdlet.ShouldProcess($CodespaceName, "Start Codespace $CodespaceName"))
    {
        return
    }

    $result = (Invoke-GHRestMethod @params | Add-GitHubCodespaceAdditionalProperties)

    if ($Wait.IsPresent)
    {
        $waitParams = @{
            CodespaceName = $CodespaceName
            AccessToken = $AccessToken
        }

        $result = Wait-GitHubCodespaceAction @waitParams
    }

    if (Resolve-ParameterWithDefaultConfigurationValue -Name PassThru -ConfigValueName DefaultPassThru)
    {
        return $result
    }
}

filter Stop-GitHubCodespace
{
    <#
    .SYNOPSIS
        Stop a Codespace for the currently authenticated user.

    .DESCRIPTION
        Stop a Codespace for the currently authenticated user.

        The Git repo for this module can be found here: http://aka.ms/PowerShellForGitHub

    .PARAMETER CodespaceName
        Name of the Codespace.

    .PARAMETER Wait
        If present will wait for the codespace to stop.

    .PARAMETER PassThru
        Returns the updated GitHub Issue.  By default, this cmdlet does not generate any output.
        You can use "Set-GitHubConfiguration -DefaultPassThru" to control the default behavior
        of this switch.

    .PARAMETER AccessToken
        If provided, this will be used as the AccessToken for authentication with the
        REST Api.  Otherwise, will attempt to use the configured value or will run unauthenticated.

    .INPUTS
        GitHub.Codespace

    .OUTPUTS
        GitHub.Codespace

    .EXAMPLE
        Stop-GitHubCodespace -Name vercellone-effective-goggles-qrv997q6j9929jx8

    .LINK
        https://docs.github.com/en/rest/codespaces/codespaces?apiVersion=2022-11-28#stop-a-codespace-for-the-authenticated-user

    .NOTES
        You must authenticate using an access token with the codespace scope to use this endpoint.
        GitHub Apps must have write access to the codespaces_lifecycle_admin repository permission to use this endpoint.
#>
    [CmdletBinding(
        SupportsShouldProcess,
        ConfirmImpact = 'Low')]
    [OutputType({ $script:GitHubCodespaceTypeName })]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '', Justification = 'PassThru is accessed indirectly via Resolve-ParameterWithDefaultConfigurationValue')]
    param(
        [Parameter(
            Mandatory,
            ValueFromPipeline,
            ValueFromPipelineByPropertyName)]
        [string] $CodespaceName,

        [switch] $Wait,

        [switch] $PassThru,

        [string] $AccessToken
    )

    Write-InvocationLog

    $telemetryProperties = @{
        CodespaceName = Get-PiiSafeString -PlainText $CodespaceName
        Wait = $Wait.IsPresent
    }

    $params = @{
        UriFragment = "user/codespaces/$CodespaceName/stop"
        Method = 'Post'
        Description = "Stop Codespace $CodespaceName"
        AccessToken = $AccessToken
        TelemetryEventName = $MyInvocation.MyCommand.Name
        TelemetryProperties = $telemetryProperties
    }

    if (-not $PSCmdlet.ShouldProcess($CodespaceName, "Stop Codespace $CodespaceName"))
    {
        return
    }

    $result = (Invoke-GHRestMethod @params | Add-GitHubCodespaceAdditionalProperties)

    if ($Wait.IsPresent)
    {
        $waitParams = @{
            CodespaceName = $CodespaceName
            AccessToken = $AccessToken
        }

        $result = Wait-GitHubCodespaceAction @waitParams
    }

    if (Resolve-ParameterWithDefaultConfigurationValue -Name PassThru -ConfigValueName DefaultPassThru)
    {
        return $result
    }
}

function Wait-GitHubCodespaceAction
{
    <#
    .SYNOPSIS
        Wait for a Codespace start or stop action.

    .PARAMETER CodespaceName
        Name of the Codespace.

    .PARAMETER AccessToken
        If provided, this will be used as the AccessToken for authentication with the
        REST Api.  Otherwise, will attempt to use the configured value or will run unauthenticated.

    .INPUTS
        GitHub.Codespace

    .OUTPUTS
        GitHub.Codespace

    .EXAMPLE
        Wait-GitHubCodespace -Name vercellone-effective-goggles-qrv997q6j9929jx8

     .NOTES
        Internal-only helper method.
#>
    [CmdletBinding()]
    [OutputType({ $script:GitHubCodespaceTypeName })]
    param(
        [Parameter(
            Mandatory,
            ValueFromPipeline,
            ValueFromPipelineByPropertyName)]
        [string] $CodespaceName,

        [string] $AccessToken
    )

    begin
    {
        $sleepSeconds = $(Get-GitHubConfiguration -Name 'StateChangeDelaySeconds')

        # 2s minimum
        if ($sleepSeconds -lt 2)
        {
            $sleepSeconds = 2
        }
    }

    process
    {
        Write-InvocationLog

        # Expected states for happy paths:
        # Shutdown  > Queued > Starting     > Available
        # Available > Queued > ShuttingDown > ShutDown
        #
        # To allow for unexpected results, loop until the state is something other than Queued or *ing
        # All known states:
        # *ings: Awaiting, Exporting, Provisioning, Rebuilding, ShuttingDown, Starting, Updating
        # Other: Archived, Available, Created, Deleted, Failed, Moved, Queued, Shutdown, Unavailable, Unknown
        do
        {
            Start-Sleep -Seconds $sleepSeconds
            $codespace = (Get-GitHubCodespace @PSBoundParameters)
            Write-Log -Message "[$CodespaceName] state is $($codespace.state)" -Level Verbose
        }
        until ($codespace.state -notmatch 'Queued|ing')

        return $codespace
    }
}

filter Add-GitHubCodespaceAdditionalProperties
{
    <#
    .SYNOPSIS
        Adds type name and additional properties to ease pipelining to GitHub Repository objects.

    .PARAMETER InputObject
        The GitHub object to add additional properties to.

    .PARAMETER TypeName
        The type that should be assigned to the object.

    .INPUTS
        [PSCustomObject]

    .OUTPUTS
        GitHub.Codespace
#>
    [CmdletBinding()]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseSingularNouns", "", Justification = "Internal helper that is definitely adding more than one property.")]
    param(
        [Parameter(
            Mandatory,
            ValueFromPipeline)]
        [AllowNull()]
        [AllowEmptyCollection()]
        [PSCustomObject[]] $InputObject,

        [ValidateNotNullOrEmpty()]
        [string] $TypeName = $script:GitHubCodespaceTypeName
    )

    foreach ($item in $InputObject)
    {
        $item.PSObject.TypeNames.Insert(0, $TypeName)

        if (-not (Get-GitHubConfiguration -Name DisablePipelineSupport))
        {
            if ($item.name)
            {
                Add-Member -InputObject $item -Name 'CodespaceUrl' -Value "user/codespaces/$($item.name)" -MemberType NoteProperty -Force
                Add-Member -InputObject $item -Name 'CodespaceName' -Value $item.name -MemberType NoteProperty -Force
            }

            if ($null -ne $item.billable_owner)
            {
                $null = Add-GitHubUserAdditionalProperties -InputObject $item.billable_owner
            }

            if ($null -ne $item.owner)
            {
                $null = Add-GitHubUserAdditionalProperties -InputObject $item.owner
            }

            if ($null -ne $item.repository)
            {
                $null = Add-GitHubRepositoryAdditionalProperties -InputObject $item.repository
                Add-Member -InputObject $item -Name 'RepositoryUrl' -Value $item.repository.RepositoryUrl -MemberType NoteProperty -Force
            }
        }

        Write-Output $item
    }
}
