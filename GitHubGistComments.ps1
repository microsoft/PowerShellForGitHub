# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

@{
    GitHubGistCommentTypeName = 'GitHub.GistComment'
 }.GetEnumerator() | ForEach-Object {
     Set-Variable -Scope Script -Option ReadOnly -Name $_.Key -Value $_.Value
 }

filter Get-GitHubGistComment
{
<#
    .SYNOPSIS
        Retrieves comments for a specific gist from GitHub.

    .DESCRIPTION
        Retrieves comments for a specific gist from GitHub.

        The Git repo for this module can be found here: http://aka.ms/PowerShellForGitHub

    .PARAMETER GistId
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

    .INPUTS
        GitHub.GistComment

    .OUTPUTS
        GitHub.GistComment

    .EXAMPLE
        Get-GitHubGistComment -GistId 6cad326836d38bd3a7ae

        Gets all comments on octocat's "hello_world.rb" gist.

    .EXAMPLE
        Get-GitHubGistComment -GistId 6cad326836d38bd3a7ae -CommentId 1507813

        Gets comment 1507813 from octocat's "hello_world.rb" gist.
#>
    [CmdletBinding(PositionalBinding = $false)]
    [OutputType({$script:GitHubGistCommentTypeName})]
    param(
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            Position = 1)]
        [string] $GistId,

        [Parameter(ValueFromPipelineByPropertyName)]
        [Alias('GistCommentId')]
        [ValidateNotNullOrEmpty()]
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
        $uriFragment = "gists/$GistId/comments"
        $description = "Getting comments for gist $GistId"
    }
    else
    {
        $telemetryProperties['SpecifiedCommentId'] = $true

        $uriFragment = "gists/$GistId/comments/$CommentId"
        $description = "Getting comment $CommentId for gist $GistId"
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

    return (Invoke-GHRestMethodMultipleResult @params |
        Add-GitHubGistCommentAdditionalProperties -GistId $GistId)
}

filter Remove-GitHubGistComment
{
<#
    .SYNOPSIS
        Removes/deletes a comment from a gist on GitHub.

    .DESCRIPTION
        Removes/deletes a comment from a gist on GitHub.

        The Git repo for this module can be found here: http://aka.ms/PowerShellForGitHub

    .PARAMETER GistId
        The ID of the specific gist that you wish to remove the comment from.

    .PARAMETER CommentId
        The ID of the comment to remove from the gist.

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
        GitHub.GistComment

    .EXAMPLE
        Remove-GitHubGist -GistId 6cad326836d38bd3a7ae -CommentId 12324567

        Removes the specified comment from octocat's "hello_world.rb" gist
        (assuming you have permission).

    .EXAMPLE
        Remove-GitHubGist -GistId 6cad326836d38bd3a7ae -CommentId 12324567 -Confirm:$false

        Removes the specified comment from octocat's "hello_world.rb" gist
        (assuming you have permission).
        Will not prompt for confirmation, as -Confirm:$false was specified.

    .EXAMPLE
        Remove-GitHubGist -GistId 6cad326836d38bd3a7ae -CommentId 12324567 -Force

        Removes the specified comment from octocat's "hello_world.rb" gist
        (assuming you have permission).
        Will not prompt for confirmation, as -Force was specified.
#>
    [CmdletBinding(
        SupportsShouldProcess,
        PositionalBinding = $false,
        ConfirmImpact="High")]
    [Alias('Delete-GitHubGist')]
    param(
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            Position = 1)]
        [ValidateNotNullOrEmpty()]
        [string] $GistId,

        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            Position = 2)]
        [Alias('GistCommentId')]
        [ValidateNotNullOrEmpty()]
        [string] $CommentId,

        [switch] $Force,

        [string] $AccessToken,

        [switch] $NoStatus
    )

    Write-InvocationLog -Invocation $MyInvocation

    if ($Force -and (-not $Confirm))
    {
        $ConfirmPreference = 'None'
    }

    if (-not $PSCmdlet.ShouldProcess($CommentId, "Delete comment from gist $GistId"))
    {
        return
    }

    $telemetryProperties = @{}
    $params = @{
        'UriFragment' = "gists/$GistId/comments/$CommentId"
        'Method' = 'Delete'
        'Description' =  "Removing comment $CommentId from gist $GistId"
        'AccessToken' = $AccessToken
        'TelemetryEventName' = $MyInvocation.MyCommand.Name
        'TelemetryProperties' = $telemetryProperties
        'NoStatus' = (Resolve-ParameterWithDefaultConfigurationValue -BoundParameters $PSBoundParameters -Name NoStatus -ConfigValueName DefaultNoStatus)
    }

    return Invoke-GHRestMethod @params
}

filter New-GitHubGistComment
{
<#
    .SYNOPSIS
        Creates a new comment on the specified gist from GitHub.

    .DESCRIPTION
        Creates a new comment on the specified gist from GitHub.

        The Git repo for this module can be found here: http://aka.ms/PowerShellForGitHub

    .PARAMETER GistId
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

    .INPUTS
        GitHub.GistComment

    .OUTPUTS
        GitHub.GistComment

    .EXAMPLE
        New-GitHubGistComment -GistId 6cad326836d38bd3a7ae -Comment 'Hello World'

        Adds a new comment of "Hello World" to octocat's "hello_world.rb" gist.
#>
    [CmdletBinding(
        SupportsShouldProcess,
        PositionalBinding = $false)]
    [OutputType({$script:GitHubGistCommentTypeName})]
    param(
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            Position = 1)]
        [ValidateNotNullOrEmpty()]
        [string] $GistId,

        [Parameter(
            Mandatory,
            Position = 2)]
        [ValidateNotNullOrEmpty()]
        [string] $Comment,

        [string] $AccessToken,

        [switch] $NoStatus
    )

    Write-InvocationLog -Invocation $MyInvocation

    $hashBody = @{
        'body' = $Comment
    }

    if (-not $PSCmdlet.ShouldProcess($GistId, "Create new comment for gist"))
    {
        return
    }

    $telemetryProperties = @{}
    $params = @{
        'UriFragment' = "gists/$GistId/comments"
        'Body' = (ConvertTo-Json -InputObject $hashBody)
        'Method' = 'Post'
        'Description' =  "Creating new comment on gist $GistId"
        'AccessToken' = $AccessToken
        'TelemetryEventName' = $MyInvocation.MyCommand.Name
        'TelemetryProperties' = $telemetryProperties
        'NoStatus' = (Resolve-ParameterWithDefaultConfigurationValue -BoundParameters $PSBoundParameters -Name NoStatus -ConfigValueName DefaultNoStatus)
    }

    return (Invoke-GHRestMethod @params | Add-GitHubGistCommentAdditionalProperties -GistId $GistId)
}

filter Set-GitHubGistComment
{
    <#
    .SYNOPSIS
        Edits a comment on the specified gist from GitHub.

    .DESCRIPTION
        Edits a comment on the specified gist from GitHub.

        The Git repo for this module can be found here: http://aka.ms/PowerShellForGitHub

    .PARAMETER GistId
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

    .INPUTS
        GitHub.GistComment

    .OUTPUTS
        GitHub.GistComment

    .EXAMPLE
        New-GitHubGistComment -Id 6cad326836d38bd3a7ae -Comment 'Hello World'

        Adds a new comment of "Hello World" to octocat's "hello_world.rb" gist.
#>
    [CmdletBinding(
        SupportsShouldProcess,
        PositionalBinding = $false)]
    [OutputType({$script:GitHubGistCommentTypeName})]
    param(
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            Position = 1)]
        [ValidateNotNullOrEmpty()]
        [string] $GistId,

        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            Position = 2)]
        [Alias('GistCommentId')]
        [ValidateNotNullOrEmpty()]
        [string] $CommentId,

        [Parameter(
            Mandatory,
            Position = 3)]
        [ValidateNotNullOrEmpty()]
        [string] $Comment,

        [string] $AccessToken,

        [switch] $NoStatus
    )

    Write-InvocationLog -Invocation $MyInvocation

    $hashBody = @{
        'body' = $Comment
    }

    if (-not $PSCmdlet.ShouldProcess($CommentId, "Update gist comment on gist $GistId"))
    {
        return
    }

    $telemetryProperties = @{}
    $params = @{
        'UriFragment' = "gists/$GistId/comments/$CommentId"
        'Body' = (ConvertTo-Json -InputObject $hashBody)
        'Method' = 'Patch'
        'Description' = "Creating new comment on gist $GistId"
        'AccessToken' = $AccessToken
        'TelemetryEventName' = $MyInvocation.MyCommand.Name
        'TelemetryProperties' = $telemetryProperties
        'NoStatus' = (Resolve-ParameterWithDefaultConfigurationValue -BoundParameters $PSBoundParameters -Name NoStatus -ConfigValueName DefaultNoStatus)
    }

    return (Invoke-GHRestMethod @params | Add-GitHubGistCommentAdditionalProperties -GistId $GistId)
}

filter Add-GitHubGistCommentAdditionalProperties
{
<#
    .SYNOPSIS
        Adds type name and additional properties to ease pipelining to GitHub Gist Comment objects.

    .PARAMETER InputObject
        The GitHub object to add additional properties to.

    .PARAMETER TypeName
        The type that should be assigned to the object.

    .PARAMETER GistId
        The ID of the gist that the comment is for.

    .INPUTS
        [PSCustomObject]

    .OUTPUTS
        GitHub.GistComment
#>
    [CmdletBinding()]
    [OutputType({$script:GitHubGisCommentTypeName})]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseSingularNouns", "", Justification="Internal helper that is definitely adding more than one property.")]
    param(
        [Parameter(
            Mandatory,
            ValueFromPipeline)]
        [AllowNull()]
        [AllowEmptyCollection()]
        [PSCustomObject[]] $InputObject,

        [ValidateNotNullOrEmpty()]
        [string] $TypeName = $script:GitHubGistCommentTypeName,

        [ValidateNotNullOrEmpty()]
        [string] $GistId
    )

    foreach ($item in $InputObject)
    {
        $item.PSObject.TypeNames.Insert(0, $TypeName)

        if (-not (Get-GitHubConfiguration -Name DisablePipelineSupport))
        {
            Add-Member -InputObject $item -Name 'GistCommentId' -Value $item.id -MemberType NoteProperty -Force

            if ($PSBoundParameters.ContainsKey('GistId'))
            {
                Add-Member -InputObject $item -Name 'GistId' -Value $GistId -MemberType NoteProperty -Force
            }

            if ($null -ne $item.user)
            {
                $null = Add-GitHubUserAdditionalProperties -InputObject $item.user
            }
        }

        Write-Output $item
    }
}
