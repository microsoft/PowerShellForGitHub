# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

function Get-GitHubComment
{
<#
    .DESCRIPTION
        Get the comments for a given Github repository.

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

    .PARAMETER CommentID
        The ID of a specific comment to get. If not supplied, will return back all comments for this repository.

    .PARAMETER Issue
        Issue number to get comments for. If not supplied, will return back all comments for this repository.

    .PARAMETER Sort
        How to sort the results.

    .PARAMETER Direction
        How to list the results. Ignored without the sort parameter.

    .PARAMETER Since
        Only comments updated at or after this time are returned.

    .PARAMETER MediaType
        The format in which the API will return the body of the comment.

        raw - Return the raw markdown body. Response will include body. This is the default if you do not pass any specific media type.
        text - Return a text only representation of the markdown body. Response will include body_text.
        html - Return HTML rendered from the body's markdown. Response will include body_html.
        full - Return raw, text and HTML representations. Response will include body, body_text, and body_html.

    .PARAMETER AccessToken
        If provided, this will be used as the AccessToken for authentication with the
        REST Api.  Otherwise, will attempt to use the configured value or will run unauthenticated.

    .PARAMETER NoStatus
        If this switch is specified, long-running commands will run on the main thread
        with no commandline status update.  When not specified, those commands run in
        the background, enabling the command prompt to provide status information.
        If not supplied here, the DefaultNoStatus configuration property value will be used.

    .EXAMPLE
        Get-GitHubComment-OwnerName Powershell -RepositoryName PowerShellForGitHub

        Get the comments for the PowerShell\PowerShellForGitHub project.
#>
    [CmdletBinding(
        SupportsShouldProcess,
        DefaultParametersetName='RepositoryElements')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSShouldProcess", "", Justification="Methods called within here make use of PSShouldProcess, and the switch is passed on to them inherently.")]
    param(
        [Parameter(Mandatory, ParameterSetName='RepositoryElements')]
        [Parameter(Mandatory, ParameterSetName='IssueElements')]
        [Parameter(Mandatory, ParameterSetName='CommentElements')]
        [string] $OwnerName,

        [Parameter(Mandatory, ParameterSetName='RepositoryElements')]
        [Parameter(Mandatory, ParameterSetName='IssueElements')]
        [Parameter(Mandatory, ParameterSetName='CommentElements')]
        [string] $RepositoryName,

        [Parameter(Mandatory, ParameterSetName='RepositoryUri')]
        [Parameter(Mandatory, ParameterSetName='IssueUri')]
        [Parameter(Mandatory, ParameterSetName='CommentUri')]
        [string] $Uri,

        [Parameter(Mandatory, ParameterSetName='CommentUri')]
        [Parameter(Mandatory, ParameterSetName='CommentElements')]
        [string] $CommentID,

        [Parameter(Mandatory, ParameterSetName='IssueUri')]
        [Parameter(Mandatory, ParameterSetName='IssueElements')]
        [int] $Issue,

        [Parameter(ParameterSetName='RepositoryUri')]
        [Parameter(ParameterSetName='RepositoryElements')]
        [Parameter(ParameterSetName='IssueElements')]
        [Parameter(ParameterSetName='IssueUri')]
        [DateTime] $Since,

        [Parameter(ParameterSetName='RepositoryUri')]
        [Parameter(ParameterSetName='RepositoryElements')]
        [ValidateSet('Created', 'Updated')]
        [string] $Sort,

        [Parameter(ParameterSetName='RepositoryUri')]
        [Parameter(ParameterSetName='RepositoryElements')]
        [ValidateSet('Ascending', 'Descending')]
        [string] $Direction,

        [ValidateSet('Raw', 'Text', 'Html', 'Full')]
        [string] $MediaType ='Raw',

        [string] $AccessToken,

        [switch] $NoStatus
    )

    Write-InvocationLog

    $elements = Resolve-RepositoryElements
    $OwnerName = $elements.ownerName
    $RepositoryName = $elements.repositoryName
    $uriFragment = [String]::Empty
    $description = [String]::Empty

    $sinceFormattedTime = [String]::Empty
    if ($null -ne $Since)
    {
        $sinceFormattedTime = $Since.ToUniversalTime().ToString('o')
    }

    $telemetryProperties = @{
        'OwnerName' = (Get-PiiSafeString -PlainText $OwnerName)
        'RepositoryName' = (Get-PiiSafeString -PlainText $RepositoryName)
        'ProvidedIssue' = $PSBoundParameters.ContainsKey('Issue')
        'ProvidedComment' = $PSBoundParameters.ContainsKey('CommentID')
    }

    if ($PSBoundParameters.ContainsKey('CommentID'))
    {
        $uriFragment = "repos/$OwnerName/$RepositoryName/issues/comments/$CommentId"
        $description = "Getting comment $CommentID for $RepositoryName"
    }
    elseif ($PSBoundParameters.ContainsKey('Issue'))
    {
        $uriFragment = "repos/$OwnerName/$RepositoryName/issues/$Issue/comments`?"

        if ($PSBoundParameters.ContainsKey('Since'))
        {
            $uriFragment += "since=$sinceFormattedTime"
        }

        $description = "Getting comments for issue $Issue in $RepositoryName"
    }
    else
    {
        $getParams = @()

        if ($PSBoundParameters.ContainsKey('Sort'))
        {
            $getParams += "sort=$($Sort.ToLower())"
        }

        if ($PSBoundParameters.ContainsKey('Direction'))
        {
            $directionConverter = @{
                'Ascending' = 'asc'
                'Descending' = 'desc'
            }

            $getParams += "direction=$($directionConverter[$Direction])"
        }

        if ($PSBoundParameters.ContainsKey('Since'))
        {
            $getParams += "since=$sinceFormattedTime"
        }

        $uriFragment = "repos/$OwnerName/$RepositoryName/issues/comments`?" +  ($getParams -join '&')
        $description = "Getting comments for $RepositoryName"
    }

    $params = @{
        'UriFragment' = $uriFragment
        'Description' = $description
        'AccessToken' = $AccessToken
        'AcceptHeader' = (Get-CommentAcceptHeader -MediaType $MediaType)
        'TelemetryEventName' = $MyInvocation.MyCommand.Name
        'TelemetryProperties' = $telemetryProperties
        'NoStatus' = (Resolve-ParameterWithDefaultConfigurationValue -Name NoStatus -ConfigValueName DefaultNoStatus)
    }

    return Invoke-GHRestMethodMultipleResult @params
}

function New-GitHubComment
{
<#
    .DESCRIPTION
        Creates a new Github comment in an issue for the given repository

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

    .PARAMETER Issue
        The number for the issue that the comment will be filed under.

    .PARAMETER Body
        The contents of the comment.

    .PARAMETER MediaType
        The format in which the API will return the body of the comment.

        raw - Return the raw markdown body. Response will include body. This is the default if you do not pass any specific media type.
        text - Return a text only representation of the markdown body. Response will include body_text.
        html - Return HTML rendered from the body's markdown. Response will include body_html.
        full - Return raw, text and HTML representations. Response will include body, body_text, and body_html.

    .PARAMETER AccessToken
        If provided, this will be used as the AccessToken for authentication with the
        REST Api.  Otherwise, will attempt to use the configured value or will run unauthenticated.

    .PARAMETER NoStatus
        If this switch is specified, long-running commands will run on the main thread
        with no commandline status update.  When not specified, those commands run in
        the background, enabling the command prompt to provide status information.
        If not supplied here, the DefaultNoStatus configuration property value will be used.

    .EXAMPLE
        New-GitHubComment -OwnerName Powershell -RepositoryName PowerShellForGitHub -Issue 1 -Body "Testing this API"

        Creates a new Github comment in an issue for the PowerShell\PowerShellForGitHub project.
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

        [Parameter(Mandatory)]
        [int] $Issue,

        [Parameter(Mandatory)]
        [string] $Body,

        [ValidateSet('Raw', 'Text', 'Html', 'Full')]
        [string] $MediaType ='Raw',

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
        'Issue' =  (Get-PiiSafeString -PlainText $Issue)
    }

    $hashBody = @{
        'body' = $Body
    }

    $params = @{
        'UriFragment' = "repos/$OwnerName/$RepositoryName/issues/$Issue/comments"
        'Body' = (ConvertTo-Json -InputObject $hashBody)
        'Method' = 'Post'
        'Description' =  "Creating comment under issue $Issue for $RepositoryName"
        'AccessToken' = $AccessToken
        'AcceptHeader' = (Get-CommentAcceptHeader -MediaType $MediaType)
        'TelemetryEventName' = $MyInvocation.MyCommand.Name
        'TelemetryProperties' = $telemetryProperties
        'NoStatus' = (Resolve-ParameterWithDefaultConfigurationValue -Name NoStatus -ConfigValueName DefaultNoStatus)
    }

    return Invoke-GHRestMethod @params
}

function Set-GitHubComment
{
<#
    .DESCRIPTION
        Set an existing comment in an issue for the given repository

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

    .PARAMETER CommentID
        The comment ID of the comment to edit.

    .PARAMETER Body
        The new contents of the comment.

    .PARAMETER MediaType
        The format in which the API will return the body of the comment.

        raw - Return the raw markdown body. Response will include body. This is the default if you do not pass any specific media type.
        text - Return a text only representation of the markdown body. Response will include body_text.
        html - Return HTML rendered from the body's markdown. Response will include body_html.
        full - Return raw, text and HTML representations. Response will include body, body_text, and body_html.

    .PARAMETER AccessToken
        If provided, this will be used as the AccessToken for authentication with the
        REST Api.  Otherwise, will attempt to use the configured value or will run unauthenticated.

    .PARAMETER NoStatus
        If this switch is specified, long-running commands will run on the main thread
        with no commandline status update.  When not specified, those commands run in
        the background, enabling the command prompt to provide status information.
        If not supplied here, the DefaultNoStatus configuration property value will be used.

    .EXAMPLE
        Set-GitHubComment -OwnerName Powershell -RepositoryName PowerShellForGitHub -CommentID 1 -Body "Testing this API"

        Update an existing comment in an issue for the PowerShell\PowerShellForGitHub project.
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

        [Parameter(Mandatory)]
        [string] $CommentID,

        [Parameter(Mandatory)]
        [string] $Body,

        [ValidateSet('Raw', 'Text', 'Html', 'Full')]
        [string] $MediaType ='Raw',

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
        'CommentID' =  (Get-PiiSafeString -PlainText $CommentID)
    }

    $hashBody = @{
        'body' = $Body
    }

    $params = @{
        'UriFragment' = "repos/$OwnerName/$RepositoryName/issues/comments/$CommentID"
        'Body' = (ConvertTo-Json -InputObject $hashBody)
        'Method' = 'Patch'
        'Description' =  "Update comment $CommentID for $RepositoryName"
        'AccessToken' = $AccessToken
        'AcceptHeader' = (Get-CommentAcceptHeader -MediaType $MediaType)
        'TelemetryEventName' = $MyInvocation.MyCommand.Name
        'TelemetryProperties' = $telemetryProperties
        'NoStatus' = (Resolve-ParameterWithDefaultConfigurationValue -Name NoStatus -ConfigValueName DefaultNoStatus)
    }

    return Invoke-GHRestMethod @params
}

function Remove-GitHubComment
{
<#
    .DESCRIPTION
        Deletes a Github comment for the given repository

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

    .PARAMETER CommentID
        The id of the comment to delete.

    .PARAMETER AccessToken
        If provided, this will be used as the AccessToken for authentication with the
        REST Api.  Otherwise, will attempt to use the configured value or will run unauthenticated.

    .PARAMETER NoStatus
        If this switch is specified, long-running commands will run on the main thread
        with no commandline status update.  When not specified, those commands run in
        the background, enabling the command prompt to provide status information.
        If not supplied here, the DefaultNoStatus configuration property value will be used.

    .EXAMPLE
        Remove-GitHubComment -OwnerName Powershell -RepositoryName PowerShellForGitHub -CommentID 1

        Deletes a Github comment from the PowerShell\PowerShellForGitHub project.
#>
    [CmdletBinding(
        SupportsShouldProcess,
        DefaultParametersetName='Elements')]
    [Alias('Delete-GitHubComment')]
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
        [string] $CommentID,

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
        'CommentID' =  (Get-PiiSafeString -PlainText $CommentID)
    }

    $params = @{
        'UriFragment' = "repos/$OwnerName/$RepositoryName/issues/comments/$CommentID"
        'Method' = 'Delete'
        'Description' =  "Removing comment $CommentID for $RepositoryName"
        'AccessToken' = $AccessToken
        'TelemetryEventName' = $MyInvocation.MyCommand.Name
        'TelemetryProperties' = $telemetryProperties
        'NoStatus' = (Resolve-ParameterWithDefaultConfigurationValue -Name NoStatus -ConfigValueName DefaultNoStatus)
    }

    return Invoke-GHRestMethod @params
}

function Get-CommentAcceptHeader
{
<#
    .DESCRIPTION
        Returns a formatted AcceptHeader based on the requested MediaType

        The Git repo for this module can be found here: http://aka.ms/PowerShellForGitHub

    .PARAMETER MediaType
        The format in which the API will return the body of the comment.

        raw - Return the raw markdown body. Response will include body. This is the default if you do not pass any specific media type.
        text - Return a text only representation of the markdown body. Response will include body_text.
        html - Return HTML rendered from the body's markdown. Response will include body_html.
        full - Return raw, text and HTML representations. Response will include body, body_text, and body_html.

    .EXAMPLE
        Get-CommentAcceptHeader -MediaType Raw

        Returns a formatted AcceptHeader for v3 of the response object
#>
    [CmdletBinding()]
    param(
        [ValidateSet('Raw', 'Text', 'Html', 'Full')]
        [string] $MediaType ='Raw'
    )

    $acceptHeaders = @(
        'application/vnd.github.squirrel-girl-preview',
        "application/vnd.github.$mediaTypeVersion.$($MediaType.ToLower())+json")

    return ($acceptHeaders -join ',')
}
