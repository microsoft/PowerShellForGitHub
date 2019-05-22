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
        $pullRequests = Get-GitHubPullRequest -OwnerName Microsoft -RepositoryName PowerShellForGitHub -State Closed
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

        [ValidateSet('Open', 'Closed', 'All')]
        [string] $State = 'Open',

        [string] $Head,

        [string] $Base,

        [ValidateSet('Created', 'Updated', 'Popularity', 'LongRunning')]
        [string] $Sort = 'Created',

        [ValidateSet('Ascending', 'Descending')]
        [string] $Direction = 'Descending',

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
        'ProvidedPullRequest' = $PSBoundParameters.ContainsKey('PullRequest')
    }

    $uriFragment = "/repos/$OwnerName/$RepositoryName/pulls"
    $description = "Getting pull requests for $RepositoryName"
    if (-not [String]::IsNullOrEmpty($PullRequest))
    {
        $uriFragment = $uriFragment + "/$PullRequest"
        $description = "Getting pull request $PullRequest for $RepositoryName"
    }

    $sortConverter = @{
        'Created' = 'created'
        'Updated' = 'updated'
        'Popularity' = 'popularity'
        'LongRunning' = 'long-running'
    }

    $directionConverter = @{
        'Ascending' = 'asc'
        'Descending' = 'desc'
    }

    $getParams = @(
        "state=$($State.ToLower())",
        "sort=$($sortConverter[$Sort])",
        "direction=$($directionConverter[$Direction])"
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
        'NoStatus' = (Resolve-ParameterWithDefaultConfigurationValue -Name NoStatus -ConfigValueName DefaultNoStatus)
    }

    return Invoke-GHRestMethodMultipleResult @params
}

function New-GitHubPullRequest
{ 
    <#
    .SYNOPSIS
        Create a new pull request in the specified repository.
    
    .DESCRIPTION
        Opens a new pull request from the given branch into the given branch in the specified repository.

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
    
    .PARAMETER Title
        The title of the pull request to be created.
    
    .PARAMETER Head
        The name of the head branch (the branch containing the changes to be merged).

        May also include the name of the owner fork, in the form "${fork}:${branch}".
    
    .PARAMETER Base
        The name of the target branch of the pull request
        (where the changes in the head will be merged to).

    .PARAMETER HeadOwner
        The name of fork that the change is coming from.
        
        Used as the prefix of $Head parameter in the form "${HeadOwner}:${Head}".

        If unspecified, the unprefixed branch name is used,
        creating a pull request from the $OwnerName fork of the repository.
    
    .PARAMETER Body
        The text description of the pull request.
    
    .PARAMETER MaintainerCanModify
        If set, allows repository maintainers to commit changes to the
        head branch of this pull request.
    
    .PARAMETER Draft
        If set, opens the pull request as a draft.
    
    .PARAMETER AccessToken
        If provided, this will be used as the AccessToken for authentication with the
        REST Api.  Otherwise, will attempt to use the configured value or will run unauthenticated.
    
    .PARAMETER NoStatus
        If this switch is specified, long-running commands will run on the main thread
        with no commandline status update.  When not specified, those commands run in
        the background, enabling the command prompt to provide status information.
        If not supplied here, the DefaultNoStatus configuration property value will be used.

    .OUTPUTS
        [PSCustomObject] An object describing the created pull request.
    
    .EXAMPLE
        $prParams = @{
            OwnerName = 'Microsoft'
            Repository = 'PowerShellForGitHub'
            Title = 'Add simple file to root'
            Head = 'octocat:simple-file'
            Base = 'master'
            Body = "Adds a simple text file to the repository root.`n`nThis is an automated PR!"
            MaintainerCanModify = $true
        }
        $pr = New-GitHubPullRequest @prParams

    .EXAMPLE
        New-GitHubPullRequest -Uri 'https://github.com/PowerShell/PSScriptAnalyzer' -Title 'Add test' -Head simple-test -HeadOwner octocat -Base development -Draft -MaintainerCanModify
    #>
    
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSShouldProcess", "", Justification="Methods called within here make use of PSShouldProcess, and the switch is passed on to them inherently.")]
    [CmdletBinding(SupportsShouldProcess, DefaultParameterSetName='Elements')]
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
        [string] $Title,

        [Parameter(Mandatory)]
        [string] $Head,

        [Parameter(Mandatory)]
        [string] $Base,

        [string] $HeadOwner,

        [string] $Body,

        [switch] $MaintainerCanModify,

        [switch] $Draft,

        [string] $AccessToken,

        [switch] $NoStatus
    )

    Write-InvocationLog

    if ($HeadOwner)
    {
        if ($Head.Contains(':'))
        {
            $message = "`$Head ('$Head') was specified with an owner prefix, but `$HeadOwner ('$HeadOwner') was also specified." +
                " Either specify `$Head in '<owner>:<branch>' format, or set `$Head = '<branch>' and `$HeadOwner = '<owner>'."

            Write-Log -Message $message -Level Error
            throw $message
        }

        # $Head does not contain ':' - add the owner fork prefix
        $Head = "${HeadOwner}:${Head}"
    }

    $elements = Resolve-RepositoryElements
    $OwnerName = $elements.ownerName
    $RepositoryName = $elements.respositoryName

    $telemetryProperties = @{
        'OwnerName' = (Get-PiiSafeString -PlainText $OwnerName)
        'RepositoryName' = (Get-PiiSafeString -PlainText $RepositoryName)
    }

    $uriFragment = "/repos/$OwnerName/$RepositoryName/pulls"
    $description = "Creating pull request $Title for $RepositoryName"

    $postBody = @{
        'title' = $Title
        'head' = $Head
        'base' = $Base
    }

    if ($Body)
    {
        $postBody['body'] = $Body
    }

    if ($MaintainerCanModify)
    {
        $postBody['maintainer_can_modify'] = $true
    }

    if ($Draft)
    {
        $postBody['draft'] = $true
        $acceptHeader = 'application/vnd.github.shadow-cat-preview+json'
    }

    $restParams = @{
        'UriFragment' = $uriFragment
        'Method' = 'Post'
        'Description' = $description
        'Body' = ConvertTo-Json -InputObject $postBody -Compress
        'AccessToken' = $AccessToken
        'TelemetryEventName' = $MyInvocation.MyCommand.Name
        'TelemetryProperties' = $telemetryProperties
        'NoStatus' = (Resolve-ParameterWithDefaultConfigurationValue -Name NoStatus -ConfigValueName DefaultNoStatus)
    }

    if ($acceptHeader)
    {
        $restParams['AcceptHeader'] = $acceptHeader
    }

    return Invoke-GHRestMethod @restParams
}
