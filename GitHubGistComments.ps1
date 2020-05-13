# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

function Get-GitHubGistComment
{
<#
    .SYNOPSIS
        Retrieves comments for a specific gist from GitHub.

    .DESCRIPTION
        Retrieves comments for a specific gist from GitHub.

        The Git repo for this module can be found here: http://aka.ms/PowerShellForGitHub

    .PARAMETER Id
        The ID of the specific gist that you wish to retrieve the comments for.

    .PARAMETER CommentId
        The ID of the specific comment on the gist that you wish to retrieve.

    .PARAMETER MediaType
        The format in which the API will return the body of the comment.

        Raw - Return the raw markdown body. Response will include body. This is the default if you do not pass any specific media type.
        Text - Return a text only representation of the markdown body. Response will include body_text.
        Html - Return HTML rendered from the body's markdown. Response will include body_html.
        Full - Return raw, text and HTML representations. Response will include body, body_text, and body_html.

    .PARAMETER AccessToken
        If provided, this will be used as the AccessToken for authentication with the
        REST Api.  Otherwise, will attempt to use the configured value or will run unauthenticated.

    .PARAMETER NoStatus
        If this switch is specified, long-running commands will run on the main thread
        with no commandline status update.  When not specified, those commands run in
        the background, enabling the command prompt to provide status information.
        If not supplied here, the DefaultNoStatus configuration property value will be used.

    .EXAMPLE
        Get-GitHubGistComment -Id 6cad326836d38bd3a7ae

        Gets all comments on octocat's "hello_world.rb" gist.

    .EXAMPLE
        Get-GitHubGistComment -Id 6cad326836d38bd3a7ae -CommentId 1507813

        Gets comment 1507813 from octocat's "hello_world.rb" gist.
#>
    [CmdletBinding(SupportsShouldProcess)]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSShouldProcess", "", Justification="Methods called within here make use of PSShouldProcess, and the switch is passed on to them inherently.")]
    param(
        [Parameter(Mandatory)]
        [Alias('GistId')]
        [string] $Id,

        [string] $CommentId,

        [ValidateSet('Raw', 'Text', 'Html', 'Full')]
        [string] $MediaType = 'Raw',

        [string] $AccessToken,

        [switch] $NoStatus
    )

    Write-InvocationLog -Invocation $MyInvocation

    $telemetryProperties = @{}

    $uriFragment = [String]::Empty
    $description = [String]::Empty

    if ([String]::IsNullOrWhiteSpace($CommentId))
    {
        $uriFragment = "gists/$Id/comments"
        $description = "Getting comments for gist $Id"
    }
    else
    {
        $telemetryProperties['SpecifiedCommentId'] = $true

        $uriFragment = "gists/$Id/comments/$CommentId"
        $description = "Getting comment $CommentId for gist $Id"
    }

    $params = @{
        'UriFragment' = $uriFragment
        'Description' =  $description
        'AccessToken' = $AccessToken
        'AcceptHeader' = (Get-MediaAcceptHeader -MediaType $MediaType -AsJson)
        'TelemetryEventName' = $MyInvocation.MyCommand.Name
        'TelemetryProperties' = $telemetryProperties
        'NoStatus' = (Resolve-ParameterWithDefaultConfigurationValue -BoundParameters $PSBoundParameters -Name NoStatus -ConfigValueName DefaultNoStatus)
    }

    $result = Invoke-GHRestMethodMultipleResult @params

    return $result
}

function Remove-GitHubGistComment
{
<#
    .SYNOPSIS
        Removes/deletes a comment from a gist on GitHub.

    .DESCRIPTION
        Removes/deletes a comment from a gist on GitHub.

        The Git repo for this module can be found here: http://aka.ms/PowerShellForGitHub

    .PARAMETER Id
        The ID of the specific gist that you wish to remove the comment from.

    .PARAMETER CommentId
        The ID of the comment to remove from the gist.

    .PARAMETER AccessToken
        If provided, this will be used as the AccessToken for authentication with the
        REST Api.  Otherwise, will attempt to use the configured value or will run unauthenticated.

    .PARAMETER NoStatus
        If this switch is specified, long-running commands will run on the main thread
        with no commandline status update.  When not specified, those commands run in
        the background, enabling the command prompt to provide status information.
        If not supplied here, the DefaultNoStatus configuration property value will be used.

    .EXAMPLE
        Remove-GitHubGist -Id 6cad326836d38bd3a7ae

        Removes octocat's "hello_world.rb" gist (assuming you have permission).

    .EXAMPLE
        Remove-GitHubGist -Id 6cad326836d38bd3a7ae -Confirm:$false

        Removes octocat's "hello_world.rb" gist (assuming you have permission).
        Will not prompt for confirmation, as -Confirm:$false was specified.
#>
    [CmdletBinding(
        SupportsShouldProcess,
        ConfirmImpact="High")]
    [Alias('Delete-GitHubGist')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSShouldProcess", "", Justification="Methods called within here make use of PSShouldProcess, and the switch is passed on to them inherently.")]
    param(
        [Parameter(Mandatory)]
        [Alias('GistId')]
        [ValidateNotNullOrEmpty()]
        [string] $Id,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string] $CommentId,

        [string] $AccessToken,

        [switch] $NoStatus
    )

    Write-InvocationLog -Invocation $MyInvocation

    if ($PSCmdlet.ShouldProcess($CommentId, "Delete comment from gist $Id"))
    {
        $telemetryProperties = @{}
        $params = @{
            'UriFragment' = "gists/$Id/comments/$CommentId"
            'Method' = 'Delete'
            'Description' =  "Removing comment $CommentId from gist $Id"
            'AccessToken' = $AccessToken
            'TelemetryEventName' = $MyInvocation.MyCommand.Name
            'TelemetryProperties' = $telemetryProperties
            'NoStatus' = (Resolve-ParameterWithDefaultConfigurationValue -BoundParameters $PSBoundParameters -Name NoStatus -ConfigValueName DefaultNoStatus)
        }

        return Invoke-GHRestMethod @params
    }
}

function New-GitHubGistComment
{
<#
    .SYNOPSIS
        Creates a new comment on the specified gist from GitHub.

    .DESCRIPTION
        Creates a new comment on the specified gist from GitHub.

        The Git repo for this module can be found here: http://aka.ms/PowerShellForGitHub

    .PARAMETER Id
        The ID of the specific gist that you wish to add the comment to.

    .PARAMETER Comment
        The text of the comment that you wish to leave on the gist.

    .PARAMETER AccessToken
        If provided, this will be used as the AccessToken for authentication with the
        REST Api.  Otherwise, will attempt to use the configured value or will run unauthenticated.

    .PARAMETER NoStatus
        If this switch is specified, long-running commands will run on the main thread
        with no commandline status update.  When not specified, those commands run in
        the background, enabling the command prompt to provide status information.
        If not supplied here, the DefaultNoStatus configuration property value will be used.

    .EXAMPLE
        New-GitHubGistComment -Id 6cad326836d38bd3a7ae -Comment 'Hello World'

        Adds a new comment of "Hello World" to octocat's "hello_world.rb" gist.
#>
    [CmdletBinding(SupportsShouldProcess)]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSShouldProcess", "", Justification="Methods called within here make use of PSShouldProcess, and the switch is passed on to them inherently.")]
    param(
        [Parameter(Mandatory)]
        [Alias('GistId')]
        [ValidateNotNullOrEmpty()]
        [string] $Id,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string] $Comment,

        [string] $AccessToken,

        [switch] $NoStatus
    )

    Write-InvocationLog -Invocation $MyInvocation

    $hashBody = @{
        'body' = $Comment
    }

    $telemetryProperties = @{}
    $params = @{
        'UriFragment' = "gists/$Id/comments"
        'Body' = (ConvertTo-Json -InputObject $hashBody)
        'Method' = 'Post'
        'Description' =  "Creating new comment on gist $Id"
        'AccessToken' = $AccessToken
        'TelemetryEventName' = $MyInvocation.MyCommand.Name
        'TelemetryProperties' = $telemetryProperties
        'NoStatus' = (Resolve-ParameterWithDefaultConfigurationValue -BoundParameters $PSBoundParameters -Name NoStatus -ConfigValueName DefaultNoStatus)
    }

    return Invoke-GHRestMethod @params
}

function Set-GitHubGistComment
{
    <#
    .SYNOPSIS
        Edits a comment on the specified gist from GitHub.

    .DESCRIPTION
        Edits a comment on the specified gist from GitHub.

        The Git repo for this module can be found here: http://aka.ms/PowerShellForGitHub

    .PARAMETER Id
        The ID of the gist that the comment is on.

    .PARAMETER CommentId
        The ID of the comment that you wish to edit.

    .PARAMETER Comment
        The new text of the comment that you wish to leave on the gist.

    .PARAMETER AccessToken
        If provided, this will be used as the AccessToken for authentication with the
        REST Api.  Otherwise, will attempt to use the configured value or will run unauthenticated.

    .PARAMETER NoStatus
        If this switch is specified, long-running commands will run on the main thread
        with no commandline status update.  When not specified, those commands run in
        the background, enabling the command prompt to provide status information.
        If not supplied here, the DefaultNoStatus configuration property value will be used.

    .EXAMPLE
        New-GitHubGistComment -Id 6cad326836d38bd3a7ae -Comment 'Hello World'

        Adds a new comment of "Hello World" to octocat's "hello_world.rb" gist.
#>
    [CmdletBinding(SupportsShouldProcess)]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSShouldProcess", "", Justification = "Methods called within here make use of PSShouldProcess, and the switch is passed on to them inherently.")]
    param(
        [Parameter(Mandatory)]
        [Alias('GistId')]
        [ValidateNotNullOrEmpty()]
        [string] $Id,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string] $CommentId,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string] $Comment,

        [string] $AccessToken,

        [switch] $NoStatus
    )

    Write-InvocationLog -Invocation $MyInvocation

    $hashBody = @{
        'body' = $Comment
    }

    $telemetryProperties = @{}
    $params = @{
        'UriFragment' = "gists/$Id/comments/$CommentId"
        'Body' = (ConvertTo-Json -InputObject $hashBody)
        'Method' = 'Patch'
        'Description' = "Creating new comment on gist $Id"
        'AccessToken' = $AccessToken
        'TelemetryEventName' = $MyInvocation.MyCommand.Name
        'TelemetryProperties' = $telemetryProperties
        'NoStatus' = (Resolve-ParameterWithDefaultConfigurationValue -BoundParameters $PSBoundParameters -Name NoStatus -ConfigValueName DefaultNoStatus)
    }

    return Invoke-GHRestMethod @params
}
