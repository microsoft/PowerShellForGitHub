# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

function Get-GitHubUser
{
<#
    .SYNOPSIS
        Retrieves information about the specified user on GitHub.

    .DESCRIPTION
        Retrieves information about the specified user on GitHub.

        The Git repo for this module can be found here: http://aka.ms/PowerShellForGitHub

    .PARAMETER User
        The GitHub user to retrieve information for.
        If not specified, will retrieve information on all GitHub users (and may take a while to complete).

    .PARAMETER Current
        If specified, gets information on the current user.

    .PARAMETER AccessToken
        If provided, this will be used as the AccessToken for authentication with the
        REST Api.  Otherwise, will attempt to use the configured value or will run unauthenticated.

    .PARAMETER NoStatus
        If this switch is specified, long-running commands will run on the main thread
        with no commandline status update.  When not specified, those commands run in
        the background, enabling the command prompt to provide status information.
        If not supplied here, the DefaultNoStatus configuration property value will be used.

    .NOTES
        The email key in the following response is the publicly visible email address from the
        user's GitHub profile page.  You only see publicly visible email addresses when
        authenticated with GitHub.

        When setting up your profile, a user can select a primary email address to be public
        which provides an email entry for this endpoint.  If the user does not set a public
        email address for email, then it will have a value of null.

    .EXAMPLE
        Get-GitHubUser -User octocat

        Gets information on just the user named 'octocat'

    .EXAMPLE
        Get-GitHubUser

        Gets information on every GitHub user.

    .EXAMPLE
        Get-GitHubUser -Current

        Gets information on the current authenticated user.
#>
    [CmdletBinding(
        SupportsShouldProcess,
        DefaultParameterSetName='ListAndSearch')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSShouldProcess", "", Justification="Methods called within here make use of PSShouldProcess, and the switch is passed on to them inherently.")]
    param(
        [Parameter(ParameterSetName='ListAndSearch')]
        [string] $User,

        [Parameter(ParameterSetName='Current')]
        [switch] $Current,

        [string] $AccessToken,

        [switch] $NoStatus
    )

    Write-InvocationLog

    $params = @{
        'AccessToken' = $AccessToken
        'TelemetryEventName' = $MyInvocation.MyCommand.Name
        'NoStatus' = (Resolve-ParameterWithDefaultConfigurationValue -Name NoStatus -ConfigValueName DefaultNoStatus)
    }

    if ($Current)
    {
        return Invoke-GHRestMethod -UriFragment "user" -Description "Getting current authenticated user" -Method 'Get' @params
    }
    elseif ([String]::IsNullOrEmpty($User))
    {
        return Invoke-GHRestMethodMultipleResult -UriFragment 'users' -Description 'Getting all users' @params
    }
    else
    {
        return Invoke-GHRestMethod -UriFragment "users/$User" -Description "Getting user $User" -Method 'Get' @params
    }
}

function Get-GitHubUserContextualInformation
{
<#
    .SYNOPSIS
        Retrieves contextual information about the specified user on GitHub.

    .DESCRIPTION
        Retrieves contextual information about the specified user on GitHub.

        The Git repo for this module can be found here: http://aka.ms/PowerShellForGitHub

    .PARAMETER User
        The GitHub user to retrieve information for.

    .PARAMETER Subject
        Identifies which additional information to receive about the user's hovercard.

    .PARAMETER SubjectId
        The ID for the Subject.  Required when Subject has been specified.

    .PARAMETER AccessToken
        If provided, this will be used as the AccessToken for authentication with the
        REST Api.  Otherwise, will attempt to use the configured value or will run unauthenticated.

    .PARAMETER NoStatus
        If this switch is specified, long-running commands will run on the main thread
        with no commandline status update.  When not specified, those commands run in
        the background, enabling the command prompt to provide status information.
        If not supplied here, the DefaultNoStatus configuration property value will be used.

    .EXAMPLE
        Get-GitHubUserContextualInformation -User octocat

    .EXAMPLE
        Get-GitHubUserContextualInformation -User octocat -Subject Repository -SubjectId 1300192
#>
    [CmdletBinding(SupportsShouldProcess)]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSShouldProcess", "", Justification="Methods called within here make use of PSShouldProcess, and the switch is passed on to them inherently.")]
    param(
        [Parameter(Mandatory)]
        [string] $User,

        [ValidateSet('Organization', 'Repository', 'Issue', 'PullRequest')]
        [string] $Subject,

        [string] $SubjectId,

        [string] $AccessToken,

        [switch] $NoStatus
    )

    Write-InvocationLog

    $getParams = @()

    # Intentionally not using -xor here because we need to know if we're setting the GET parameters as well.
    if ((-not [String]::IsNullOrEmpty($Subject)) -or (-not [String]::IsNullOrEmpty($SubjectId)))
    {
        if ([String]::IsNullOrEmpty($Subject) -or [String]::IsNullOrEmpty($SubjectId))
        {
            $message = 'If either Subject or SubjectId has been provided, then BOTH must be provided.'
            Write-Log -Message $message -Level Error
            throw $message
        }

        $subjectConverter = @{
            'Organization' = 'organization'
            'Repository' = 'repository'
            'Issue' = 'issue'
            'PullRequest' = 'pull_request'
        }

        $getParams += "subject_type=$($subjectConverter[$Subject])"
        $getParams += "subject_id=$SubjectId"
    }

    $params = @{
        'UriFragment' = "users/$User/hovercard`?" + ($getParams -join '&')
        'Method' = 'Get'
        'Description' =  "Getting hovercard information for $User"
        'AcceptHeader' = 'application/vnd.github.hagar-preview+json'
        'AccessToken' = $AccessToken
        'TelemetryEventName' = $MyInvocation.MyCommand.Name
        'NoStatus' = (Resolve-ParameterWithDefaultConfigurationValue -Name NoStatus -ConfigValueName DefaultNoStatus)
    }

    Invoke-GHRestMethod @params
}

function Update-GitHubCurrentUser
{
<#
    .SYNOPSIS
        Updates information about the current authenticated user on GitHub.

    .DESCRIPTION
        Updates information about the current authenticated user on GitHub.

        The Git repo for this module can be found here: http://aka.ms/PowerShellForGitHub

    .PARAMETER Name
        The new name of the user.

    .PARAMETER Email
        The publicly visible email address of the user.

    .PARAMETER Blog
        The new blog URL of the user.

    .PARAMETER Company
        The new company of the user.

    .PARAMETER Location
        The new location of the user.

    .PARAMETER Bio
        The new short biography of the user.

    .PARAMETER Hireable
        Specify to indicate a change in hireable availability for the current authenticated user's
        GitHub profile.  To change to "not hireable", specify -Hireable:$false

    .PARAMETER AccessToken
        If provided, this will be used as the AccessToken for authentication with the
        REST Api.  Otherwise, will attempt to use the configured value or will run unauthenticated.

    .PARAMETER NoStatus
        If this switch is specified, long-running commands will run on the main thread
        with no commandline status update.  When not specified, those commands run in
        the background, enabling the command prompt to provide status information.
        If not supplied here, the DefaultNoStatus configuration property value will be used.

    .EXAMPLE
        Update-GitHubCurrentUser -Location 'Seattle, WA' -Hireable:$false

        Updates the current user to indicate that their location is "Seattle, WA" and that they
        are not currently hireable.
#>
    [CmdletBinding(SupportsShouldProcess)]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSShouldProcess", "", Justification="Methods called within here make use of PSShouldProcess, and the switch is passed on to them inherently.")]
    param(
        [string] $Name,

        [string] $Email,

        [string] $Blog,

        [string] $Company,

        [string] $Location,

        [string] $Bio,

        [switch] $Hireable,

        [string] $AccessToken,

        [switch] $NoStatus
    )

    Write-InvocationLog

    $hashBody = @{}
    if ($PSBoundParameters.ContainsKey('Name')) { $hashBody['name'] = $Name }
    if ($PSBoundParameters.ContainsKey('Email')) { $hashBody['email'] = $Email }
    if ($PSBoundParameters.ContainsKey('Blog')) { $hashBody['blog'] = $Blog }
    if ($PSBoundParameters.ContainsKey('Company')) { $hashBody['company'] = $Company }
    if ($PSBoundParameters.ContainsKey('Location')) { $hashBody['location'] = $Location }
    if ($PSBoundParameters.ContainsKey('Bio')) { $hashBody['bio'] = $Bio }
    if ($PSBoundParameters.ContainsKey('Hireable')) { $hashBody['hireable'] = $Hireable.ToBool() }

    $params = @{
        'UriFragment' = 'user'
        'Method' = 'Patch'
        'Body' = (ConvertTo-Json -InputObject $hashBody)
        'Description' =  "Updating current authenticated user"
        'AccessToken' = $AccessToken
        'TelemetryEventName' = $MyInvocation.MyCommand.Name
        'NoStatus' = (Resolve-ParameterWithDefaultConfigurationValue -Name NoStatus -ConfigValueName DefaultNoStatus)
    }

    return Invoke-GHRestMethod @params
}
