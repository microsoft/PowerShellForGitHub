# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

@{
    GitHubUserTypeName = 'GitHub.User'
    GitHubUserContextualInformationTypeName = 'GitHub.UserContextualInformation'
 }.GetEnumerator() | ForEach-Object {
     Set-Variable -Scope Script -Option ReadOnly -Name $_.Key -Value $_.Value
 }

filter Get-GitHubUser
{
<#
    .SYNOPSIS
        Retrieves information about the specified user on GitHub.

    .DESCRIPTION
        Retrieves information about the specified user on GitHub.

        The Git repo for this module can be found here: http://aka.ms/PowerShellForGitHub

    .PARAMETER UserName
        The GitHub user to retrieve information for.
        If not specified, will retrieve information on all GitHub users
        (and may take a while to complete).

    .PARAMETER Current
        If specified, gets information on the current user.

    .PARAMETER AccessToken
        If provided, this will be used as the AccessToken for authentication with the
        REST Api.  Otherwise, will attempt to use the configured value or will run unauthenticated.

    .NOTES
        The email key in the following response is the publicly visible email address from the
        user's GitHub profile page.  You only see publicly visible email addresses when
        authenticated with GitHub.

        When setting up your profile, a user can select a primary email address to be public
        which provides an email entry for this endpoint.  If the user does not set a public
        email address for email, then it will have a value of null.

    .INPUTS
        GitHub.User

    .OUTPUTS
        GitHub.User

    .EXAMPLE
        Get-GitHubUser -UserName octocat

        Gets information on just the user named 'octocat'

    .EXAMPLE
        'octocat', 'PowerShellForGitHubTeam' | Get-GitHubUser

        Gets information on the users named 'octocat' and 'PowerShellForGitHubTeam'

    .EXAMPLE
        Get-GitHubUser

        Gets information on every GitHub user.

    .EXAMPLE
        Get-GitHubUser -Current

        Gets information on the current authenticated user.
#>
    [CmdletBinding(DefaultParameterSetName = 'ListAndSearch')]
    [OutputType({$script:GitHubUserTypeName})]
    param(
        [Parameter(
            ValueFromPipeline,
            ValueFromPipelineByPropertyName,
            ParameterSetName='ListAndSearch')]
        [Alias('Name')]
        [Alias('User')]
        [string] $UserName,

        [Parameter(ParameterSetName='Current')]
        [switch] $Current,

        [string] $AccessToken
    )

    Write-InvocationLog

    $params = @{
        'AccessToken' = $AccessToken
        'TelemetryEventName' = $MyInvocation.MyCommand.Name
    }

    if ($Current)
    {
        return (Invoke-GHRestMethod -UriFragment "user" -Description "Getting current authenticated user" -Method 'Get' @params |
            Add-GitHubUserAdditionalProperties)
    }
    elseif ([String]::IsNullOrEmpty($UserName))
    {
        return (Invoke-GHRestMethodMultipleResult -UriFragment 'users' -Description 'Getting all users' @params |
            Add-GitHubUserAdditionalProperties)
    }
    else
    {
        return (Invoke-GHRestMethod -UriFragment "users/$UserName" -Description "Getting user $UserName" -Method 'Get' @params |
            Add-GitHubUserAdditionalProperties)
    }
}

filter Get-GitHubUserContextualInformation
{
<#
    .SYNOPSIS
        Retrieves contextual information about the specified user on GitHub.

    .DESCRIPTION
        Retrieves contextual information about the specified user on GitHub.

        The Git repo for this module can be found here: http://aka.ms/PowerShellForGitHub

    .PARAMETER User
        The GitHub user to retrieve information for.

    .PARAMETER OrganizationId
        The ID of an Organization.  When provided, this returns back the context for the user
        in relation to this Organization.

    .PARAMETER RepositoryId
        The ID for a Repository.  When provided, this returns back the context for the user
        in relation to this Repository.

    .PARAMETER IssueId
        The ID for a Issue.  When provided, this returns back the context for the user
        in relation to this Issue.
        NOTE: This is the *id* of the issue and not the issue *number*.

    .PARAMETER PullRequestId
        The ID for a PullRequest.  When provided, this returns back the context for the user
        in relation to this Pull Request.
        NOTE: This is the *id* of the pull request and not the pull request *number*.

    .PARAMETER AccessToken
        If provided, this will be used as the AccessToken for authentication with the
        REST Api.  Otherwise, will attempt to use the configured value or will run unauthenticated.

    .INPUTS
        GitHub.Issue
        GitHub.Organization
        GitHub.PullRequest
        GitHub.Repository
        GitHub.User

    .OUTPUTS
        GitHub.UserContextualInformation

    .EXAMPLE
        Get-GitHubUserContextualInformation -User octocat

    .EXAMPLE
        Get-GitHubUserContextualInformation -User octocat -RepositoryId 1300192

    .EXAMPLE
        $repo = Get-GitHubRepository -OwnerName microsoft -RepositoryName 'PowerShellForGitHub'
        $repo | Get-GitHubUserContextualInformation -User octocat

    .EXAMPLE
        Get-GitHubIssue -OwnerName microsoft -RepositoryName PowerShellForGitHub -Issue 70 |
            Get-GitHubUserContextualInformation -User octocat
#>
    [CmdletBinding(DefaultParameterSetName = 'NoContext')]
    [OutputType({$script:GitHubUserContextualInformationTypeName})]
    param(
        [Parameter(
            Mandatory,
            ValueFromPipeline,
            ValueFromPipelineByPropertyName)]
        [Alias('Name')]
        [Alias('User')]
        [string] $UserName,

        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName='Organization')]
        [int64] $OrganizationId,

        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName='Repository')]
        [int64] $RepositoryId,

        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName='Issue')]
        [int64] $IssueId,

        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName='PullRequest')]
        [int64] $PullRequestId,

        [string] $AccessToken
    )

    Write-InvocationLog

    $getParams = @()

    $contextType = [String]::Empty
    $contextId = 0
    if ($PSCmdlet.ParameterSetName -ne 'NoContext')
    {
        if ($PSCmdlet.ParameterSetName -eq 'Organization')
        {
            $getParams += 'subject_type=organization'
            $getParams += "subject_id=$OrganizationId"

            $contextType = 'OrganizationId'
            $contextId = $OrganizationId
        }
        elseif ($PSCmdlet.ParameterSetName -eq 'Repository')
        {
            $getParams += 'subject_type=repository'
            $getParams += "subject_id=$RepositoryId"

            $contextType = 'RepositoryId'
            $contextId = $RepositoryId
        }
        elseif ($PSCmdlet.ParameterSetName -eq 'Issue')
        {
            $getParams += 'subject_type=issue'
            $getParams += "subject_id=$IssueId"

            $contextType = 'IssueId'
            $contextId = $IssueId
        }
        elseif ($PSCmdlet.ParameterSetName -eq 'PullRequest')
        {
            $getParams += 'subject_type=pull_request'
            $getParams += "subject_id=$PullRequestId"

            $contextType = 'PullRequestId'
            $contextId = $PullRequestId
        }
    }

    $params = @{
        'UriFragment' = "users/$UserName/hovercard`?" + ($getParams -join '&')
        'Method' = 'Get'
        'Description' = "Getting hovercard information for $UserName"
        'AcceptHeader' = $script:hagarAcceptHeader
        'AccessToken' = $AccessToken
        'TelemetryEventName' = $MyInvocation.MyCommand.Name
    }

    $result = Invoke-GHRestMethod @params
    foreach ($item in $result.contexts)
    {
        $item.PSObject.TypeNames.Insert(0, $script:GitHubUserContextualInformationTypeName)

        if (-not (Get-GitHubConfiguration -Name DisablePipelineSupport))
        {
            Add-Member -InputObject $item -Name 'UserName' -Value $UserName -MemberType NoteProperty -Force
            if ($PSCmdlet.ParameterSetName -ne 'NoContext')
            {
                Add-Member -InputObject $item -Name $contextType -Value $contextId -MemberType NoteProperty -Force
            }
        }
    }

    return $result
}

function Set-GitHubProfile
{
<#
    .SYNOPSIS
        Updates profile information for the current authenticated user on GitHub.

    .DESCRIPTION
        Updates profile information for the current authenticated user on GitHub.

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

    .PARAMETER PassThru
        Returns the updated User Profile.  By default, this cmdlet does not generate any output.
        You can use "Set-GitHubConfiguration -DefaultPassThru" to control the default behavior
        of this switch.

    .PARAMETER AccessToken
        If provided, this will be used as the AccessToken for authentication with the
        REST Api.  Otherwise, will attempt to use the configured value or will run unauthenticated.

    .OUTPUTS
        GitHub.User

    .EXAMPLE
        Set-GitHubProfile -Location 'Seattle, WA' -Hireable:$false

        Updates the current user to indicate that their location is "Seattle, WA" and that they
        are not currently hireable.
#>
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType({$script:GitHubUserTypeName})]
    [Alias('Update-GitHubCurrentUser')] # Non-standard usage of the Update verb, but done to avoid a breaking change post 0.14.0
    param(
        [string] $Name,

        [string] $Email,

        [string] $Blog,

        [string] $Company,

        [string] $Location,

        [string] $Bio,

        [switch] $Hireable,

        [switch] $PassThru,

        [string] $AccessToken
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

    if (-not $PSCmdlet.ShouldProcess('Update Current GitHub User'))
    {
        return
    }

    $params = @{
        'UriFragment' = 'user'
        'Method' = 'Patch'
        'Body' = (ConvertTo-Json -InputObject $hashBody)
        'Description' = "Updating current authenticated user"
        'AccessToken' = $AccessToken
        'TelemetryEventName' = $MyInvocation.MyCommand.Name
    }

    $result = (Invoke-GHRestMethod @params | Add-GitHubUserAdditionalProperties)
    if (Resolve-ParameterWithDefaultConfigurationValue -Name PassThru -ConfigValueName DefaultPassThru)
    {
        return $result
    }
}

filter Add-GitHubUserAdditionalProperties
{
<#
    .SYNOPSIS
        Adds type name and additional properties to ease pipelining to GitHub User objects.

    .PARAMETER InputObject
        The GitHub object to add additional properties to.

    .PARAMETER TypeName
        The type that should be assigned to the object.

    .PARAMETER Name
        The name of the user.  This information might be obtainable from InputObject, so this
        is optional based on what InputObject contains.

    .PARAMETER Id
        The ID of the user.  This information might be obtainable from InputObject, so this
        is optional based on what InputObject contains.

    .INPUTS
        [PSCustomObject]

    .OUTPUTS
        GitHub.User
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
        [string] $TypeName = $script:GitHubUserTypeName,

        [string] $Name,

        [int64] $Id
    )

    foreach ($item in $InputObject)
    {
        $item.PSObject.TypeNames.Insert(0, $TypeName)

        if (-not (Get-GitHubConfiguration -Name DisablePipelineSupport))
        {
            $userName = $item.login
            if ([String]::IsNullOrEmpty($userName) -and $PSBoundParameters.ContainsKey('Name'))
            {
                $userName = $Name
            }

            if (-not [String]::IsNullOrEmpty($userName))
            {
                Add-Member -InputObject $item -Name 'UserName' -Value $userName -MemberType NoteProperty -Force
            }

            $userId = $item.id
            if (($userId -eq 0) -and $PSBoundParameters.ContainsKey('Id'))
            {
                $userId = $Id
            }

            if ($userId -ne 0)
            {
                Add-Member -InputObject $item -Name 'UserId' -Value $userId -MemberType NoteProperty -Force
            }
        }

        Write-Output $item
    }
}
