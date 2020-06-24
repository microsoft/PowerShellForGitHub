# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

@{
    GitHubReactionTypeName = 'GitHub.Reaction'
 }.GetEnumerator() | ForEach-Object {
     Set-Variable -Scope Script -Option ReadOnly -Name $_.Key -Value $_.Value
 }

filter Get-GitHubReaction
{
<#
    .SYNOPSIS
        Retrieve reactions of a given GitHub issue.

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

    .PARAMETER IssueNumber
        The issue *OR* pull request number. This parameter has an alias called
        `PullRequestNumber` so that the experience feels natural but in this case,
        PRs are handled the same as issues.

    .PARAMETER ReactionType
        The type of reaction you want to retrieve. This is also called the 'content' in the GitHub API.
        Valid options are based off: https://developer.github.com/v3/reactions/#reaction-types

    .PARAMETER AccessToken
        If provided, this will be used as the AccessToken for authentication with the
        REST Api.  Otherwise, will attempt to use the configured value or will run unauthenticated.

    .PARAMETER NoStatus
        If this switch is specified, long-running commands will run on the main thread
        with no commandline status update.  When not specified, those commands run in
        the background, enabling the command prompt to provide status information.
        If not supplied here, the DefaultNoStatus configuration property value will be used.

    .INPUTS
        GitHub.Issue
        GitHub.PullRequest
        GitHub.Reaction

    .OUTPUTS
        GitHub.Reaction

    .EXAMPLE
        Get-GitHubReaction -OwnerName Microsoft -RepositoryName PowerShellForGitHub -IssueNumber 157

        Gets the reactions for issue 157 from the Microsoft\PowerShellForGitHub project.

    .EXAMPLE
        Get-GitHubReaction -OwnerName Microsoft -RepositoryName PowerShellForGitHub -IssueNumber 157 -ReactionType eyes

        Gets the 'eyes' reactions for issue 157 from the Microsoft\PowerShellForGitHub project.

    .EXAMPLE
        Get-GitHubIssue -OwnerName Microsoft -RepositoryName PowerShellForGitHub -IssueNumber 157 | Get-GitHubReaction

        Gets a GitHub issue and pipe it into Get-GitHubReaction to get all the reactions for that issue.

    .EXAMPLE
        Get-GitHubPullRequest -Uri https://github.com/microsoft/PowerShellForGitHub -PullRequest 193 | Get-GitHubReaction

        Gets a GitHub pull request and pipes it into Get-GitHubReaction to get all the reactions for that pull request.

    .NOTES
        Currently, this only supports reacting to issues and pull requests. Issue comments, commit comments and PR comments will come later.
#>
    [CmdletBinding(
        SupportsShouldProcess,
        DefaultParameterSetName='Elements')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSShouldProcess", "", Justification="Methods called within here make use of PSShouldProcess, and the switch is passed on to them inherently.")]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSReviewUnusedParameter", "", Justification="One or more parameters (like NoStatus) are only referenced by helper methods which get access to it from the stack via Get-Variable -Scope 1.")]
    param(
        [Parameter(
            Mandatory,
            ParameterSetName='Elements')]
        [string] $OwnerName,

        [Parameter(
            Mandatory,
            ParameterSetName='Elements')]
        [string] $RepositoryName,

        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName='Uri')]
        [Alias('RepositoryUrl')]
        [string] $Uri,

        [Parameter(Mandatory, ParameterSetName='Elements', ValueFromPipelineByPropertyName)]
        [Parameter(Mandatory, ParameterSetName='Uri', ValueFromPipelineByPropertyName)]
        [Alias('Issue')]
        [Alias('PullRequestNumber')]
        [int64] $IssueNumber,

        [ValidateSet('+1', '-1', 'Laugh', 'Confused', 'Heart', 'Hooray', 'Rocket', 'Eyes')]
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

    $uriFragment = "/repos/$OwnerName/$RepositoryName/issues/$IssueNumber/reactions"
    if ($PSBoundParameters.ContainsKey('ReactionType'))
    {
        $uriFragment += "?content=" + [Uri]::EscapeDataString($ReactionType.ToLower())
    }

    $description = "Getting reactions for Issue $IssueNumber in $RepositoryName"

    $params = @{
        'UriFragment' = $uriFragment
        'Description' =  $description
        'AcceptHeader' = $script:squirrelGirlAcceptHeader
        'AccessToken' = $AccessToken
        'TelemetryEventName' = $MyInvocation.MyCommand.Name
        'TelemetryProperties' = $telemetryProperties
        'NoStatus' = (Resolve-ParameterWithDefaultConfigurationValue -Name NoStatus -ConfigValueName DefaultNoStatus)
    }

    $result = Invoke-GHRestMethodMultipleResult @params
    return ($result |
        Add-GitHubReactionAdditionalProperties -OwnerName $OwnerName -RepositoryName $RepositoryName -IssueNumber $IssueNumber)
}

filter Set-GitHubReaction
{
<#
    .SYNOPSIS
        Sets a reaction of a given GitHub issue.

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

    .PARAMETER IssueNumber
        The issue *OR* pull request number. This parameter has an alias called
        `PullRequestNumber` so that the experience feels natural but in this case,
        PRs are handled the same as issues.

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

    .INPUTS
        GitHub.Issue
        GitHub.PullRequest
        GitHub.Reaction

    .OUTPUTS
        GitHub.Reaction

    .EXAMPLE
        Set-GitHubReaction -OwnerName PowerShell -RepositoryName PowerShell -IssueNumber 12626 -ReactionType rocket

        Sets the 'rocket' reaction for issue 12626 of the PowerShell\PowerShell project.

    .EXAMPLE
        Get-GitHubPullRequest -Uri https://github.com/microsoft/PowerShellForGitHub -PullRequest 193 | Set-GitHubReaction -ReactionType Heart

        Gets a GitHub pull request and pipes it into Set-GitHubReaction to set the 'heart' reaction for that pull request.

    .NOTES
        Currently, this only supports reacting to issues and pull requests. Issue comments, commit comments and PR comments will come later.
#>
    [CmdletBinding(
        SupportsShouldProcess,
        DefaultParameterSetName='Elements')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSShouldProcess", "", Justification="Methods called within here make use of PSShouldProcess, and the switch is passed on to them inherently.")]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSReviewUnusedParameter", "", Justification="One or more parameters (like NoStatus) are only referenced by helper methods which get access to it from the stack via Get-Variable -Scope 1.")]
    param(
        [Parameter(
            Mandatory,
            ParameterSetName='Elements')]
        [string] $OwnerName,

        [Parameter(
            Mandatory,
            ParameterSetName='Elements')]
        [string] $RepositoryName,

        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName='Uri')]
        [Alias('RepositoryUrl')]
        [string] $Uri,

        [Parameter(Mandatory, ParameterSetName='Elements', ValueFromPipelineByPropertyName)]
        [Parameter(Mandatory, ParameterSetName='Uri', ValueFromPipelineByPropertyName)]
        [Alias('Issue')]
        [Alias('PullRequest')]
        [Alias('PullRequestNumber')]
        [int64] $IssueNumber,

        [ValidateSet('+1', '-1', 'Laugh', 'Confused', 'Heart', 'Hooray', 'Rocket', 'Eyes')]
        [Parameter(Mandatory)]
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

    $uriFragment = "/repos/$OwnerName/$RepositoryName/issues/$IssueNumber/reactions"
    $description = "Setting reaction $ReactionType for Issue $IssueNumber in $RepositoryName"

    $params = @{
        'UriFragment' = $uriFragment
        'Description' =  $description
        'Method' = 'Post'
        'Body' = @{ content = $ReactionType.ToLower() } | ConvertTo-Json
        'AcceptHeader' = $script:squirrelGirlAcceptHeader
        'AccessToken' = $AccessToken
        'TelemetryEventName' = $MyInvocation.MyCommand.Name
        'TelemetryProperties' = $telemetryProperties
        'NoStatus' = (Resolve-ParameterWithDefaultConfigurationValue -Name NoStatus -ConfigValueName DefaultNoStatus)
    }

    $result = Invoke-GHRestMethod @params
    return ($result |
        Add-GitHubReactionAdditionalProperties -OwnerName $OwnerName -RepositoryName $RepositoryName -IssueNumber $IssueNumber)
}

filter Remove-GitHubReaction
{
<#
    .SYNOPSIS
        Removes a reaction on a given GitHub issue.

    .DESCRIPTION
        Removes a reaction on a given GitHub issue.

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

    .PARAMETER IssueNumber
        The issue *OR* pull request number. This parameter has an alias called
        `PullRequestNumber` so that the experience feels natural but in this case,
        PRs are handled the same as issues.

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

    .INPUTS
        GitHub.Issue
        GitHub.PullRequests
        GitHub.Reaction

    .OUTPUTS
        None

    .EXAMPLE
        Remove-GitHubReaction -OwnerName PowerShell -RepositoryName PowerShell -IssueNumber 12626 -ReactionId 1234

        Remove a reaction by Id on Issue 12626 from the PowerShell\PowerShell project interactively.

    .EXAMPLE
        Remove-GitHubReaction -OwnerName PowerShell -RepositoryName PowerShell -IssueNumber 12626 -ReactionId 1234 -Confirm:$false

        Remove a reaction by Id on Issue 12626 from the PowerShell\PowerShell project non-interactively.

    .EXAMPLE
        Get-GitHubReaction -OwnerName PowerShell -RepositoryName PowerShell -IssueNumber 12626 -ReactionType rocket | Remove-GitHubReaction -Confirm:$false

        Gets a reaction using Get-GitHubReaction and pipes it into Remove-GitHubReaction.

    .NOTES
        Currently, this only supports reacting to issues and pull requests. Issue comments, commit comments and PR comments will come later.
#>
    [CmdletBinding(
        SupportsShouldProcess,
        DefaultParameterSetName='Elements',
        ConfirmImpact='High')]
    [Alias('Delete-GitHubReaction')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSReviewUnusedParameter", "", Justification="One or more parameters (like NoStatus) are only referenced by helper methods which get access to it from the stack via Get-Variable -Scope 1.")]
    param(
        [Parameter(
            Mandatory,
            ParameterSetName='Elements')]
        [string] $OwnerName,

        [Parameter(
            Mandatory,
            ParameterSetName='Elements')]
        [string] $RepositoryName,

        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName='Uri')]
        [Alias('RepositoryUrl')]
        [string] $Uri,

        [Parameter(Mandatory, ParameterSetName='Elements', ValueFromPipelineByPropertyName)]
        [Parameter(Mandatory, ParameterSetName='Uri', ValueFromPipelineByPropertyName)]
        [Alias('Issue')]
        [Alias('PullRequest')]
        [Alias('PullRequestNumber')]
        [int64] $IssueNumber,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ValueFromPipeline)]
        [int64] $ReactionId,

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

    $uriFragment = "/repos/$OwnerName/$RepositoryName/issues/$IssueNumber/reactions/$ReactionId"
    $description = "Removing reaction $ReactionId for Issue $IssueNumber in $RepositoryName"

    if ($PSCmdlet.ShouldProcess($ReactionId, "Removing reaction for Issue $IssueNumber in $RepositoryName"))
    {
        $params = @{
            'UriFragment' = $uriFragment
            'Description' =  $description
            'Method' = 'Delete'
            'AcceptHeader' = $script:squirrelGirlAcceptHeader
            'AccessToken' = $AccessToken
            'TelemetryEventName' = $MyInvocation.MyCommand.Name
            'TelemetryProperties' = $telemetryProperties
            'NoStatus' = (Resolve-ParameterWithDefaultConfigurationValue -Name NoStatus -ConfigValueName DefaultNoStatus)
        }

        return Invoke-GHRestMethod @params
    }
}

filter Add-GitHubReactionAdditionalProperties
{
<#
    .SYNOPSIS
        Adds type name and additional properties to ease pipelining to GitHub Reaction objects.
    .PARAMETER InputObject
        The GitHub object to add additional properties to.
    .PARAMETER TypeName
        The type that should be assigned to the object.
    .INPUTS
        [PSCustomObject]
    .OUTPUTS
        GitHub.Reaction
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

        [Parameter(Mandatory)]
        [string] $OwnerName,

        [Parameter(Mandatory)]
        [string] $RepositoryName,

        [Parameter(Mandatory)]
        [string] $IssueNumber,

        [ValidateNotNullOrEmpty()]
        [string] $TypeName = $script:GitHubReactionTypeName
    )

    if ($null -eq $InputObject) {
        return
    }

    foreach ($item in $InputObject)
    {
        $item.PSObject.TypeNames.Insert(0, $TypeName)

        if (-not (Get-GitHubConfiguration -Name DisablePipelineSupport))
        {
            $repositoryUrl = Join-GitHubUri -OwnerName $OwnerName -RepositoryName $RepositoryName
            Add-Member -InputObject $item -Name 'RepositoryUrl' -Value $repositoryUrl -MemberType NoteProperty -Force
            Add-Member -InputObject $item -Name 'ReactionId' -Value $item.id -MemberType NoteProperty -Force
            Add-Member -InputObject $item -Name 'IssueNumber' -Value $IssueNumber -MemberType NoteProperty -Force

            @('assignee', 'assignees', 'user') |
                ForEach-Object {
                    if ($null -ne $item.$_)
                    {
                        $null = Add-GitHubUserAdditionalProperties -InputObject $item.$_
                    }
                }
        }

        Write-Output $item
    }
}
