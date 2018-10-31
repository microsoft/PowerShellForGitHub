# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

function Get-GitHubPullRequest
{
<#
    .SYNOPSIS
        Retrieve the pull requests in the specified repository.

    .DESCRIPTION
        Retrieve the pull requests in the specified repository.

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

    .PARAMETER PullRequest
        The specic pull request id to return back.  If not supplied, will return back all
        pull requests for the specified Repository.

    .PARAMETER State
        The state of the pull requests that should be returned back.

    .PARAMETER Head
        Filter pulls by head user and branch name in the format of 'user:ref-name'

    .PARAMETER Base
        Base branch name to filter the pulls by.

    .PARAMETER Sort
        What to sort the results by.
        * created
        * updated
        * popularity (comment count)
        * long-running (age, filtering by pulls updated in the last month)

    .PARAMETER Direction
        The direction to be used for Sort.

    .PARAMETER AccessToken
        If provided, this will be used as the AccessToken for authentication with the
        REST Api.  Otherwise, will attempt to use the configured value or will run unauthenticated.

    .PARAMETER NoStatus
        If this switch is specified, long-running commands will run on the main thread
        with no commandline status update.  When not specified, those commands run in
        the background, enabling the command prompt to provide status information.
        If not supplied here, the DefaultNoStatus configuration property value will be used.

    .OUTPUTS
        [PSCustomObject[]] List of Pull Requests that match the specified criteria.

    .EXAMPLE
        $pullRequests = Get-GitHubPullRequest -Uri 'https://github.com/PowerShell/PowerShellForGitHub'

    .EXAMPLE
        $pullRequests = Get-GitHubPullRequest -OwnerName PowerShell -RepositoryName PowerShellForGitHub -State closed
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

        [string] $PullRequest,

        [ValidateSet('open', 'closed', 'all')]
        [string] $State = 'open',

        [string] $Head,

        [string] $Base,

        [ValidateSet('created', 'updated', 'popularity', 'long-running')]
        [string] $Sort = 'created',

        [ValidateSet('asc', 'desc')]
        [string] $Direction = 'desc',

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
        'ProvidedPullRequest' = $PSBoundParameters.ContainsKey('PullRequest')
    }

    $uriFragment = "/repos/$OwnerName/$RepositoryName/pulls"
    $description = "Getting pull requests for $RepositoryName"
    if (-not [String]::IsNullOrEmpty($PullRequest))
    {
        $uriFragment = $uriFragment + "/$PullRequest"
        $description = "Getting pull request $PullRequest for $RepositoryName"
    }

    $getParams = @(
        "state=$State",
        "sort=$Sort",
        "direction=$Direction"
    )

    if ($PSBoundParameters.ContainsKey('Head'))
    {
        $getParams += "head=$Head"
    }

    if ($PSBoundParameters.ContainsKey('Base'))
    {
        $getParams += "base=$Base"
    }

    $params = @{
        'UriFragment' = $uriFragment + '?' +  ($getParams -join '&')
        'Description' =  $description
        'AcceptHeader' = 'application/vnd.github.symmetra-preview+json'
        'AccessToken' = $AccessToken
        'TelemetryEventName' = $MyInvocation.MyCommand.Name
        'TelemetryProperties' = $telemetryProperties
        'NoStatus' = (Resolve-ParameterWithDefaultConfigurationValue -BoundParameters $PSBoundParameters -Name NoStatus -ConfigValueName DefaultNoStatus)
    }

    return Invoke-GHRestMethodMultipleResult @params
}
