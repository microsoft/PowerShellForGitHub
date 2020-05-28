# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

function Get-GitHubReaction
{
<#
    .SYNOPSIS
        Retrieve reations of a given GitHub issue.

    .DESCRIPTION
        Retrieve reactions of a given GitHub issue.

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
        The issue number.

    .PARAMETER ReactionType
        The type of reaction you want to retrieve. This is aslo called the 'content' in the GitHub API.
        Valid options are based off: https://developer.github.com/v3/reactions/#reaction-types

    .PARAMETER AccessToken
        If provided, this will be used as the AccessToken for authentication with the
        REST Api.  Otherwise, will attempt to use the configured value or will run unauthenticated.

    .PARAMETER NoStatus
        If this switch is specified, long-running commands will run on the main thread
        with no commandline status update.  When not specified, those commands run in
        the background, enabling the command prompt to provide status information.
        If not supplied here, the DefaultNoStatus configuration property value will be used.

    .EXAMPLE
        Get-GitHubReaction -OwnerName Microsoft -RepositoryName PowerShellForGitHub -Issue 157

        Gets the reactions for issue 157 from the Microsoft\PowerShellForGitHub project.

    .EXAMPLE
        Get-GitHubReaction -OwnerName Microsoft -RepositoryName PowerShellForGitHub -Issue 157 -ReactionType eyes

        Gets the 'eyes' reactions for issue 157 from the Microsoft\PowerShellForGitHub project.

    .EXAMPLE
        Get-GitHubIssue -OwnerName Microsoft -RepositoryName PowerShellForGitHub -Issue 157 | Get-GitHubReaction

        Gets a GitHub issue and pipe it into Get-GitHubReaction to get all the reactions for that issue.

    .NOTES
        Currently, this only supports reacting to issues. Issue comments, commit comments and PR comments will come later.

    .NOTES
        The alias parameters 'number' and 'repository_url' are so that this cmdlet composes with `Get-GitHubIssue`.
#>
    [CmdletBinding(
        SupportsShouldProcess,
        DefaultParameterSetName='Elements')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSShouldProcess", "", Justification="Methods called within here make use of PSShouldProcess, and the switch is passed on to them inherently.")]
    param(
        [Parameter(Mandatory, ParameterSetName='Elements')]
        [string] $OwnerName,

        [Parameter(Mandatory, ParameterSetName='Elements')]
        [string] $RepositoryName,

        [Parameter(Mandatory, ParameterSetName='Uri', ValueFromPipelineByPropertyName)]
        [Alias("repository_url")]
        [string] $Uri,

        [Parameter(Mandatory, ParameterSetName='Elements')]
        [Parameter(Mandatory, ParameterSetName='Uri', ValueFromPipelineByPropertyName)]
        [Alias("number")]
        [int64] $Issue,

        [ValidateSet('+1', '-1', 'laugh', 'confused', 'heart', 'hooray', 'rocket', 'eyes')]
        [string] $ReactionType,

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

    $uriFragment = "/repos/$OwnerName/$RepositoryName/issues/$Issue/reactions"
    if ($PSBoundParameters.ContainsKey('ReactionType')) {
        $uriFragment += "?content=" + [Uri]::EscapeDataString($ReactionType)
    }

    $description = "Getting reactions for Issue $Issue in $RepositoryName"

    $params = @{
        'UriFragment' = $uriFragment
        'Description' =  $description
        'AcceptHeader' = 'application/vnd.github.squirrel-girl-preview+json'
        'AccessToken' = $AccessToken
        'TelemetryEventName' = $MyInvocation.MyCommand.Name
        'TelemetryProperties' = $telemetryProperties
        'NoStatus' = (Resolve-ParameterWithDefaultConfigurationValue -Name NoStatus -ConfigValueName DefaultNoStatus)
    }

    $result = Invoke-GHRestMethodMultipleResult @params

    # Add metadata to reactions so that they compose with Remove-GitHubReaction
    if ($result) {
        $result | Add-Member -NotePropertyMembers @{
            OwnerName = $OwnerName
            RepositoryName = $RepositoryName
            Issue = $Issue
        }

        return $result
    }
}

function Set-GitHubReaction
{
<#
    .SYNOPSIS
        Sets a reation of a given GitHub issue.

    .DESCRIPTION
        Sets a reaction of a given GitHub issue.

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
        The issue number.

    .PARAMETER ReactionType
        The type of reaction you want to set. This is aslo called the 'content' in the GitHub API.
        Valid options are based off: https://developer.github.com/v3/reactions/#reaction-types

    .PARAMETER AccessToken
        If provided, this will be used as the AccessToken for authentication with the
        REST Api.  Otherwise, will attempt to use the configured value or will run unauthenticated.

    .PARAMETER NoStatus
        If this switch is specified, long-running commands will run on the main thread
        with no commandline status update.  When not specified, those commands run in
        the background, enabling the command prompt to provide status information.
        If not supplied here, the DefaultNoStatus configuration property value will be used.

    .EXAMPLE
        Set-GitHubReaction -OwnerName PowerShell -RepositoryName PowerShell -Issue 12626 -ReactionType rocket

        Sets the 'rocket' reaction for issue 12626 of the PowerShell\PowerShell project.

    .NOTES
        Currently, this only supports reacting to issues. Issue comments, commit comments and PR comments will come later.

    .NOTES
        The alias parameters 'number' and 'repository_url' are so that this cmdlet composes with `Get-GitHubIssue`.
#>
    [CmdletBinding(
        SupportsShouldProcess,
        DefaultParameterSetName='Elements')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSShouldProcess", "", Justification="Methods called within here make use of PSShouldProcess, and the switch is passed on to them inherently.")]
    param(
        [Parameter(Mandatory, ParameterSetName='Elements')]
        [string] $OwnerName,

        [Parameter(Mandatory, ParameterSetName='Elements')]
        [string] $RepositoryName,

        [Parameter(Mandatory, ParameterSetName='Uri', ValueFromPipelineByPropertyName)]
        [Alias("repository_url")]
        [string] $Uri,

        [Parameter(Mandatory, ParameterSetName='Elements')]
        [Parameter(Mandatory, ParameterSetName='Uri', ValueFromPipelineByPropertyName)]
        [Alias("number")]
        [int64] $Issue,

        [ValidateSet('+1', '-1', 'laugh', 'confused', 'heart', 'hooray', 'rocket', 'eyes')]
        [Parameter(Mandatory, ParameterSetName='Elements')]
        [Parameter(Mandatory, ParameterSetName='Uri')]
        [string] $ReactionType,

        [switch] $PassThru,

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

    $uriFragment = "/repos/$OwnerName/$RepositoryName/issues/$Issue/reactions"
    $description = "Setting reaction $ReactionType for Issue $Issue in $RepositoryName"

    $params = @{
        'UriFragment' = $uriFragment
        'Description' =  $description
        'Method' = 'Post'
        'Body' = @{ content = $ReactionType } | ConvertTo-Json
        'AcceptHeader' = 'application/vnd.github.squirrel-girl-preview+json'
        'AccessToken' = $AccessToken
        'TelemetryEventName' = $MyInvocation.MyCommand.Name
        'TelemetryProperties' = $telemetryProperties
        'NoStatus' = (Resolve-ParameterWithDefaultConfigurationValue -Name NoStatus -ConfigValueName DefaultNoStatus)
    }

    $result = Invoke-GHRestMethod @params
    if ($PSBoundParameters.ContainsKey('PassThru')) {
        return $result
    }
}

function Remove-GitHubReaction
{
<#
    .SYNOPSIS
        Removes a reation on a given GitHub issue.

    .DESCRIPTION
        Removes a reation on a given GitHub issue.

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
        The issue number.

    .PARAMETER ReactionId
        The Id of the reaction. You can get this from using Get-GitHubReaction.

    .PARAMETER AccessToken
        If provided, this will be used as the AccessToken for authentication with the
        REST Api.  Otherwise, will attempt to use the configured value or will run unauthenticated.

    .PARAMETER NoStatus
        If this switch is specified, long-running commands will run on the main thread
        with no commandline status update.  When not specified, those commands run in
        the background, enabling the command prompt to provide status information.
        If not supplied here, the DefaultNoStatus configuration property value will be used.

    .EXAMPLE
        Remove-GitHubReaction -OwnerName PowerShell -RepositoryName PowerShell -Issue 12626 -ReactionId 1234

        Remove a reaction by Id on Issue 12626 from the PowerShell\PowerShell project.

    .EXAMPLE
        Get-GitHubReaction -OwnerName PowerShell -RepositoryName PowerShell -Issue 12626 -ReactionType rocket | Remove-GitHubReaction

        Gets a reaction using Get-GitHubReaction and pipes it into Remove-GitHubReaction.

    .NOTES
        Currently, this only supports reacting to issues. Issue comments, commit comments and PR comments will come later.
#>
    [CmdletBinding(
        SupportsShouldProcess,
        DefaultParameterSetName='Elements')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSShouldProcess", "", Justification="Methods called within here make use of PSShouldProcess, and the switch is passed on to them inherently.")]
    param(
        [Parameter(Mandatory, ParameterSetName='Elements', ValueFromPipelineByPropertyName)]
        [string] $OwnerName,

        [Parameter(Mandatory, ParameterSetName='Elements', ValueFromPipelineByPropertyName)]
        [string] $RepositoryName,

        [Parameter(Mandatory, ParameterSetName='Uri')]
        [string] $Uri,

        [Parameter(Mandatory, ParameterSetName='Elements', ValueFromPipelineByPropertyName)]
        [Parameter(Mandatory, ParameterSetName='Uri', ValueFromPipelineByPropertyName)]
        [int64] $Issue,

        [Parameter(Mandatory, ParameterSetName='Elements', ValueFromPipelineByPropertyName, ValueFromPipeline)]
        [Parameter(Mandatory, ParameterSetName='Uri', ValueFromPipelineByPropertyName, ValueFromPipeline)]
        [Alias('Id')]
        [int64] $ReactionId,

        [switch] $PassThru,

        [string] $AccessToken,

        [switch] $NoStatus
    )

    process {
        Write-InvocationLog

        $elements = Resolve-RepositoryElements
        $OwnerName = $elements.ownerName
        $RepositoryName = $elements.repositoryName

        $telemetryProperties = @{
            'OwnerName' = (Get-PiiSafeString -PlainText $OwnerName)
            'RepositoryName' = (Get-PiiSafeString -PlainText $RepositoryName)
        }

        $uriFragment = "/repos/$OwnerName/$RepositoryName/issues/$Issue/reactions/$ReactionId"
        $description = "Removing reaction $ReactionId for Issue $Issue in $RepositoryName"

        $params = @{
            'UriFragment' = $uriFragment
            'Description' =  $description
            'Method' = 'Delete'
            'AcceptHeader' = 'application/vnd.github.squirrel-girl-preview+json'
            'AccessToken' = $AccessToken
            'TelemetryEventName' = $MyInvocation.MyCommand.Name
            'TelemetryProperties' = $telemetryProperties
            'NoStatus' = (Resolve-ParameterWithDefaultConfigurationValue -Name NoStatus -ConfigValueName DefaultNoStatus)
        }

        return Invoke-GHRestMethod @params
    }
}
