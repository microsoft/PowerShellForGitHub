# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

@{
    GitHubBranchTypeName = 'GitHub.Branch'
 }.GetEnumerator() | ForEach-Object {
     Set-Variable -Scope Script -Option ReadOnly -Name $_.Key -Value $_.Value
 }

filter Get-GitHubRepositoryBranch
{
<#
    .SYNOPSIS
        Retrieve branches for a given GitHub repository.

    .DESCRIPTION
        Retrieve branches for a given GitHub repository.

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
        Name of the specific branch to be retrieved.  If not supplied, all branches will be retrieved.

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

    .OUTPUTS
        GitHub.Branch
        List of branches within the given repository.

    .EXAMPLE
        Get-GitHubRepositoryBranch -OwnerName microsoft -RepositoryName PowerShellForGitHub

        Gets all branches for the specified repository.

    .EXAMPLE
        $repo = Get-GitHubRepository -OwnerName microsoft -RepositoryName PowerShellForGitHub
        $repo | Get-GitHubRepositoryBranch

        Gets all branches for the specified repository.

    .EXAMPLE
        Get-GitHubRepositoryBranch -Uri 'https://github.com/PowerShell/PowerShellForGitHub' -BranchName master

        Gets information only on the master branch for the specified repository.

    .EXAMPLE
        $repo = Get-GitHubRepository -OwnerName microsoft -RepositoryName PowerShellForGitHub
        $repo | Get-GitHubRepositoryBranch -BranchName master

        Gets information only on the master branch for the specified repository.

    .EXAMPLE
        $repo = Get-GitHubRepository -OwnerName microsoft -RepositoryName PowerShellForGitHub
        $branch = $repo | Get-GitHubRepositoryBranch -BranchName master
        $branch | Get-GitHubRepositoryBranch

        Gets information only on the master branch for the specified repository, and then does it
        again.  This tries to show some of the different types of objects you can pipe into this
        function.
#>
    [CmdletBinding(
        SupportsShouldProcess,
        DefaultParameterSetName='Elements')]
    [OutputType({$script:GitHubBranchTypeName})]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSShouldProcess", "", Justification="Methods called within here make use of PSShouldProcess, and the switch is passed on to them inherently.")]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSReviewUnusedParameter", "", Justification="One or more parameters (like NoStatus) are only referenced by helper methods which get access to it from the stack via Get-Variable -Scope 1.")]
    [Alias('Get-GitHubBranch')]
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

        [Parameter(ValueFromPipelineByPropertyName)]
        [string] $BranchName,

        [switch] $ProtectedOnly,

        [string] $AccessToken,

        [switch] $NoStatus
    )

    Write-InvocationLog

    $elements = Resolve-RepositoryElements
    $OwnerName = $elements.ownerName
    $RepositoryName = $elements.repositoryName

    $telemetryProperties = @{
        'OwnerName' = (Get-PiiSafeString -PlainText $OwnerName)
        'RepositoryName' = (Get-PiiSafeString -PlainText $RepositoryName)
    }

    $uriFragment = "repos/$OwnerName/$RepositoryName/branches"
    if (-not [String]::IsNullOrEmpty($BranchName)) { $uriFragment = $uriFragment + "/$BranchName" }

    $getParams = @()
    if ($ProtectedOnly) { $getParams += 'protected=true' }

    $params = @{
        'UriFragment' = $uriFragment + '?' + ($getParams -join '&')
        'Description' = "Getting branches for $RepositoryName"
        'AccessToken' = $AccessToken
        'TelemetryEventName' = $MyInvocation.MyCommand.Name
        'TelemetryProperties' = $telemetryProperties
        'NoStatus' = (Resolve-ParameterWithDefaultConfigurationValue -Name NoStatus -ConfigValueName DefaultNoStatus)
    }

    return (Invoke-GHRestMethodMultipleResult @params | Add-GitHubBranchAdditionalProperties)
}

function New-GitHubRepositoryBranch
{
    <#
    .SYNOPSIS
        Creates a new branch for a given GitHub repository.

    .DESCRIPTION
        Creates a new branch for a given GitHub repository.

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
        Name of the branch to be created.

    .PARAMETER OriginBranchName
        The name of the origin branch to create the new branch from.

    .PARAMETER AccessToken
        If provided, this will be used as the AccessToken for authentication with the
        REST Api.  Otherwise, will attempt to use the configured value or will run unauthenticated.

    .PARAMETER NoStatus
        If this switch is specified, long-running commands will run on the main thread
        with no commandline status update.  When not specified, those commands run in
        the background, enabling the command prompt to provide status information.
        If not supplied here, the DefaultNoStatus configuration property value will be used.

    .INPUTS
        None

    .OUTPUTS
        PSCustomObject

    .EXAMPLE
        New-GitHubRepositoryBranch -Name New-Branch1 -OwnerName Microsoft -RepositoryName PowerShellForGitHub

        Creates a new branch in the specified repository from the master branch.

    .EXAMPLE
        New-GitHubRepositoryBranch -Name New-Branch2 -Uri 'https://github.com/PowerShell/PowerShellForGitHub' -OriginBranchName 'New-Branch1'

        Creates a new branch in the specified repository from the specified origin branch.
#>
    [CmdletBinding(
        SupportsShouldProcess,
        DefaultParameterSetName = 'Elements',
        PositionalBinding = $false
    )]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSShouldProcess", "",
        Justification = "Methods called within here make use of PSShouldProcess, and the switch is
        passed on to them inherently.")]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSReviewUnusedParameter", "",
        Justification = "One or more parameters (like NoStatus) are only referenced by helper
        methods which get access to it from the stack via Get-Variable -Scope 1.")]
    [Alias('New-GitHubBranch')]
    param(
        [Parameter(
            Mandatory,
            Position = 1)]
        [string] $Name,

        [Parameter(
            Mandatory,
            Position = 2,
            ParameterSetName = 'Uri')]
        [string] $Uri,

        [Parameter(ParameterSetName = 'Elements')]
        [string] $OwnerName,

        [Parameter(ParameterSetName = 'Elements')]
        [string] $RepositoryName,

        [string] $OriginBranchName = 'master',

        [string] $AccessToken,

        [switch] $NoStatus
    )

    Write-InvocationLog

    $elements = Resolve-RepositoryElements
    $OwnerName = $elements.ownerName
    $RepositoryName = $elements.repositoryName

    $telemetryProperties = @{
        'OwnerName' = (Get-PiiSafeString -PlainText $OwnerName)
        'RepositoryName' = (Get-PiiSafeString -PlainText $RepositoryName)
    }

    try
    {
        $getGitHubRepositoryBranchParms = @{
            OwnerName = $OwnerName
            RepositoryName = $RepositoryName
            Name = $OriginBranchName
            Whatif = $false
            Confirm = $false
        }
        if ($PSBoundParameters.ContainsKey('AccessToken'))
        {
            $getGitHubRepositoryBranchParms['AccessToken'] = $AccessToken
        }
        if ($PSBoundParameters.ContainsKey('NoStatus'))
        {
            $getGitHubRepositoryBranchParms['NoStatus'] = $NoStatus
        }
        $originBranch = Get-GitHubRepositoryBranch  @getGitHubRepositoryBranchParms
    }
    catch
    {
        # Temporary code to handle current differences in exception object between PS5 and PS7
        $throwObject = $_

        if ($PSVersionTable.PSedition -eq 'Core')
        {
            if ($_.Exception -is [Microsoft.PowerShell.Commands.HttpResponseException] -and
            ($_.ErrorDetails.Message | ConvertFrom-Json).message -eq 'Branch not found')
            {
                $throwObject = "Origin branch $OriginBranchName not found"
            }
        }
        else
        {
            if ($_.Exception.Message -like '*Not Found*')
            {
                $throwObject = "Origin branch $OriginBranchName not found"
            }
        }

        throw $throwObject
    }

    $uriFragment = "repos/$OwnerName/$RepositoryName/git/refs"

    $hashBody = @{
        ref = "refs/heads/$Name"
        sha = $originBranch.commit.sha
    }

    $params = @{
        'UriFragment' = $uriFragment
        'Body' = (ConvertTo-Json -InputObject $hashBody)
        'Method' = 'Post'
        'Description' = "Creating branch $Name for $RepositoryName"
        'AccessToken' = $AccessToken
        'TelemetryEventName' = $MyInvocation.MyCommand.Name
        'TelemetryProperties' = $telemetryProperties
        'NoStatus' = (Resolve-ParameterWithDefaultConfigurationValue -Name NoStatus -ConfigValueName DefaultNoStatus)
    }

    return Invoke-GHRestMethod @params
}

function Remove-GitHubRepositoryBranch
{
    <#
    .SYNOPSIS
        Removes a branch from a given GitHub repository.

    .DESCRIPTION
        Removes a branch from a given GitHub repository.

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
        Name of the branch to be removed.

    .PARAMETER Force
        If this switch is specified, you will not be prompted for confirmation of command execution.

    .PARAMETER AccessToken
        If provided, this will be used as the AccessToken for authentication with the
        REST Api.  Otherwise, will attempt to use the configured value or will run unauthenticated.

    .PARAMETER NoStatus
        If this switch is specified, long-running commands will run on the main thread
        with no commandline status update.  When not specified, those commands run in
        the background, enabling the command prompt to provide status information.
        If not supplied here, the DefaultNoStatus configuration property value will be used.

    .INPUTS
        None

    .OUTPUTS
        None

    .EXAMPLE
        Remove-GitHubRepositoryBranch  -Name TestBranch -OwnerName Microsoft -RepositoryName PowerShellForGitHub

        Removes the specified branch from the specified repository.
#>
    [CmdletBinding(
        SupportsShouldProcess,
        DefaultParameterSetName = 'Elements',
        PositionalBinding = $false,
        ConfirmImpact="High")]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSShouldProcess", "",
        Justification = "Methods called within here make use of PSShouldProcess, and the switch is
        passed on to them inherently.")]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSReviewUnusedParameter", "",
        Justification = "One or more parameters (like NoStatus) are only referenced by helper
        methods which get access to it from the stack via Get-Variable -Scope 1.")]
    [Alias('Remove-GitHubBranch')]
    [Alias('Delete-GitHubRepositoryBranch')]
    [Alias('Delete-GitHubBranch')]
    param(
        [Parameter(
            Mandatory,
            Position = 1)]
        [string] $Name,

        [Parameter(
            Mandatory,
            Position = 2,
            ParameterSetName = 'Uri')]
        [string] $Uri,

        [Parameter(ParameterSetName = 'Elements')]
        [string] $OwnerName,

        [Parameter(ParameterSetName = 'Elements')]
        [string] $RepositoryName,

        [switch] $Force,

        [string] $AccessToken,

        [switch] $NoStatus
    )

    $elements = Resolve-RepositoryElements
    $OwnerName = $elements.ownerName
    $RepositoryName = $elements.repositoryName

    $telemetryProperties = @{
        'OwnerName' = (Get-PiiSafeString -PlainText $OwnerName)
        'RepositoryName' = (Get-PiiSafeString -PlainText $RepositoryName)
    }

    $uriFragment = "repos/$OwnerName/$RepositoryName/git/refs/heads/$Name"

    if ($Force -and -not $Confirm)
    {
        $ConfirmPreference = 'None'
    }

    if ($PSCmdlet.ShouldProcess($Name, "Remove Repository Branch"))
    {
        Write-InvocationLog

        $params = @{
            'UriFragment' = $uriFragment
            'Method' = 'Delete'
            'Description' = "Deleting branch $Name from $RepositoryName"
            'AccessToken' = $AccessToken
            'TelemetryEventName' = $MyInvocation.MyCommand.Name
            'TelemetryProperties' = $telemetryProperties
            'NoStatus' = (Resolve-ParameterWithDefaultConfigurationValue `
                -Name NoStatus -ConfigValueName DefaultNoStatus)
        }

        Invoke-GHRestMethod @params | Out-Null
    }
}

filter Add-GitHubBranchAdditionalProperties
{
<#
    .SYNOPSIS
        Adds type name and additional properties to ease pipelining to GitHub Branch objects.

    .PARAMETER InputObject
        The GitHub object to add additional properties to.

    .PARAMETER TypeName
        The type that should be assigned to the object.

    .INPUTS
        [PSCustomObject]

    .OUTPUTS
        GitHub.Branch
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
        [string] $TypeName = $script:GitHubBranchTypeName
    )

    foreach ($item in $InputObject)
    {
        $item.PSObject.TypeNames.Insert(0, $TypeName)

        if (-not (Get-GitHubConfiguration -Name DisablePipelineSupport))
        {
            $elements = Split-GitHubUri -Uri $item.commit.url
            $repositoryUrl = Join-GitHubUri @elements
            Add-Member -InputObject $item -Name 'RepositoryUrl' -Value $repositoryUrl -MemberType NoteProperty -Force

            Add-Member -InputObject $item -Name 'BranchName' -Value $item.name -MemberType NoteProperty -Force
        }

        Write-Output $item
    }
}
