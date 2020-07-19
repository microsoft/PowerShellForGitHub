# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

@{
    GitHubReferenceTypeName = 'GitHub.Reference'
 }.GetEnumerator() | ForEach-Object {
     Set-Variable -Scope Script -Option ReadOnly -Name $_.Key -Value $_.Value
 }

filter Get-GitHubReference
{
<#
    .SYNOPSIS
        Retrieve a reference from a given GitHub repository.

    .DESCRIPTION
        Retrieve a reference from a given GitHub repository.

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

    .PARAMETER TagName
        The name of the Tag to be retrieved.

    .PARAMETER BranchName
        The name of the Branch to be retrieved.

    .PARAMETER MatchPrefix
        If provided, this will return matching preferences for the given branch/tag name in case an exact match is not found

    .PARAMETER AccessToken
        If provided, this will be used as the AccessToken for authentication with the
        REST Api. Otherwise, will attempt to use the configured value or will run unauthenticated.

    .PARAMETER NoStatus
        If this switch is specified, long-running commands will run on the main thread
        with no commandline status update. When not specified, those commands run in
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
        GitHub.Reaction
        GitHub.Release
        GitHub.Repository

    .OUTPUTS
        GitHub.Reference
        Details of the git reference in the given repository

    .EXAMPLE
        Get-GitHubReference -OwnerName microsoft -RepositoryName PowerShellForGitHub -TagName powershellTagV1

    .EXAMPLE
        Get-GitHubReference -OwnerName microsoft -RepositoryName PowerShellForGitHub -BranchName master

    .EXAMPLE
        Get-GitHubReference -OwnerName microsoft -RepositoryName PowerShellForGitHub -BranchName powershell -MatchPrefix

        Get the branch 'powershell' and if it doesn't exist, get all branches beginning with 'powershell'

    .EXAMPLE
        $repo = Get-GitHubRepository -OwnerName microsoft -RepositoryName PowerShellForGitHub
        $repo | Get-GitHubReference -BranchName powershell

        Get details of the "powershell" branch in the repository

#>
    [CmdletBinding(
        SupportsShouldProcess,
        DefaultParameterSetName='Uri')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSShouldProcess", "", Justification="Methods called within here make use of PSShouldProcess, and the switch is passed on to them inherently.")]
    param(
        [Parameter(
            Mandatory,
            ParameterSetName='BranchElements')]
        [Parameter(
            Mandatory,
            ParameterSetName='TagElements')]
        [Parameter(
            Mandatory,
            ParameterSetName='Elements')]
        [string] $OwnerName,

        [Parameter(
            Mandatory,
            ParameterSetName='BranchElements')]
        [Parameter(
            Mandatory,
            ParameterSetName='TagElements')]
        [Parameter(
            Mandatory,
            ParameterSetName='Elements')]
        [string] $RepositoryName,

        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName='BranchUri')]
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName='TagUri')]
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName='Uri')]
        [Alias('RepositoryUrl')]
        [string] $Uri,

        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName='TagUri')]
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName='TagElements')]
        [string] $TagName,

        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName='BranchUri')]
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName='BranchElements')]
        [string] $BranchName,

        [Parameter(ParameterSetName='BranchUri')]
        [Parameter(ParameterSetName='BranchElements')]
        [Parameter(ParameterSetName='TagUri')]
        [Parameter(ParameterSetName='TagElements')]
        [switch] $MatchPrefix,

        [string] $AccessToken,

        [switch] $NoStatus
    )

    Write-InvocationLog

    $elements = Resolve-RepositoryElements -BoundParameters $PSBoundParameters
    $OwnerName = $elements.ownerName
    $RepositoryName = $elements.repositoryName

    $telemetryProperties = @{
        'OwnerName' = (Get-PiiSafeString -PlainText $OwnerName)
        'RepositoryName' = (Get-PiiSafeString -PlainText $RepositoryName)
    }

    $uriFragment = "repos/$OwnerName/$RepositoryName/git"
    $reference = Resolve-GitHubReference -TagName $TagName -BranchName $BranchName

    if ([String]::IsNullOrEmpty($reference))
    {
        # Add a slash at the end as Invoke-GHRestMethod removes the last trailing slash. Calling this API without the slash causes a 404
        $uriFragment = $uriFragment + "/matching-refs//"
        $description = "Getting all references for $RepositoryName"
    }
    else
    {
        if ($MatchPrefix)
        {
            $uriFragment = $uriFragment + "/matching-refs/$reference"
            $description = "Getting references matching $reference for $RepositoryName"
        }
        else
        {
            # We want to return an exact match, call the 'get single reference' API
            $uriFragment = $uriFragment + "/ref/$reference"
            $description = "Getting reference $reference for $RepositoryName"
        }
    }

    $params = @{
        'UriFragment' = $uriFragment
        'Description' = $description
        'AccessToken' = $AccessToken
        'TelemetryEventName' = $MyInvocation.MyCommand.Name
        'TelemetryProperties' = $telemetryProperties
        'NoStatus' = (Resolve-ParameterWithDefaultConfigurationValue -Name NoStatus -ConfigValueName DefaultNoStatus)
    }

    return (Invoke-GHRestMethodMultipleResult @params | Add-GitHubBranchAdditionalProperties)
}

filter New-GitHubReference
{
    <#
    .SYNOPSIS
        Create a reference in a given GitHub repository.

    .DESCRIPTION
        Create a reference in a given GitHub repository.

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

    .PARAMETER TagName
        The name of the Tag to be created.

    .PARAMETER BranchName
        The name of the Branch to be created.

    .PARAMETER Sha
        The SHA1 value for the reference to be created

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
        GitHub.Reaction
        GitHub.Release
        GitHub.Repository

    .OUTPUTS
        GitHub.Reference
        Details of the git reference created. Throws an Exception if the reference already exists

    .EXAMPLE
        New-GitHubReference -OwnerName microsoft -RepositoryName PowerShellForGitHub -TagName powershellTagV1 -Sha aa218f56b14c9653891f9e74264a383fa43fefbd

    .EXAMPLE
        New-GitHubReference  -Uri https://github.com/You/YourRepo -BranchName master -Sha aa218f56b14c9653891f9e74264a383fa43fefbd

    .EXAMPLE
        $repo = Get-GitHubRepository -OwnerName microsoft -RepositoryName PowerShellForGitHub
        $repo | New-GitHubReference -BranchName powershell -Sha aa218f56b14c9653891f9e74264a383fa43fefbd

        Create a new branch named "powershell" in the given repository
    #>
    [CmdletBinding(SupportsShouldProcess)]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSShouldProcess", "", Justification="Methods called within here make use of PSShouldProcess, and the switch is passed on to them inherently.")]
    param(
        [Parameter(
            Mandatory,
            ParameterSetName='BranchElements')]
        [Parameter(
            Mandatory,
            ParameterSetName='TagElements')]
        [string] $OwnerName,

        [Parameter(
            Mandatory,
            ParameterSetName='BranchElements')]
        [Parameter(
            Mandatory,
            ParameterSetName='TagElements')]
        [string] $RepositoryName,

        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName='BranchUri')]
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName='TagUri')]
        [Alias('RepositoryUrl')]
        [string] $Uri,

        [Parameter(
            Mandatory,
            ParameterSetName='TagUri')]
        [Parameter(
            Mandatory,
            ParameterSetName='TagElements')]
        [string] $TagName,

        [Parameter(
            Mandatory,
            ParameterSetName='BranchUri')]
        [Parameter(
            Mandatory,
            ParameterSetName='BranchElements')]
        [string] $BranchName,

        [Parameter(Mandatory)]
        [string] $Sha,

        [string] $AccessToken,

        [switch] $NoStatus
    )

    Write-InvocationLog

    $elements = Resolve-RepositoryElements -BoundParameters $PSBoundParameters
    $OwnerName = $elements.ownerName
    $RepositoryName = $elements.repositoryName

    $telemetryProperties = @{
        'OwnerName' = (Get-PiiSafeString -PlainText $OwnerName)
        'RepositoryName' = (Get-PiiSafeString -PlainText $RepositoryName)
    }

    $reference = Resolve-GitHubReference -TagName $TagName -BranchName $BranchName

    $uriFragment = "repos/$OwnerName/$RepositoryName/git/refs"
    $description = "Creating Reference $reference for $RepositoryName from SHA $Sha"

    $hashBody = @{
        'ref' = "refs/" + $reference
        'sha' = $Sha
    }

    $params = @{
        'UriFragment' = $uriFragment
        'Method' = 'Post'
        'Body' = (ConvertTo-Json -InputObject $hashBody)
        'Description' = $description
        'AccessToken' = $AccessToken
        'TelemetryEventName' = $MyInvocation.MyCommand.Name
        'TelemetryProperties' = $telemetryProperties
        'NoStatus' = (Resolve-ParameterWithDefaultConfigurationValue -Name NoStatus -ConfigValueName DefaultNoStatus)
    }

    return (Invoke-GHRestMethod @params | Add-GitHubBranchAdditionalProperties)
}

filter Set-GithubReference
{
    <#
    .SYNOPSIS
        Update a reference in a given GitHub repository.

    .DESCRIPTION
        Update a reference in a given GitHub repository.

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

    .PARAMETER TagName
        The name of the tag to be updated to the given SHA.

    .PARAMETER BranchName
        The name of the branch to be updated to the given SHA.

    .PARAMETER Sha
        The updated SHA1 value to be set for this reference.

    .PARAMETER Force
        If not set, the update will only occur if it is a fast-forward update.
        Not specifying this (or setting it to $false) will make sure you're not overwriting work.

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
        Github.Reference
        GitHub.Repository

    .OUTPUTS
        GitHub.Reference

    .EXAMPLE
        Set-GithubReference -OwnerName microsoft -RepositoryName PowerShellForGitHub -BranchName myBranch -Sha aa218f56b14c9653891f9e74264a383fa43fefbd

    .EXAMPLE
        Set-GithubReference -Uri https://github.com/You/YourRepo -TagName myTag -Sha aa218f56b14c9653891f9e74264a383fa43fefbd

    .EXAMPLE
        Set-GithubReference -Uri https://github.com/You/YourRepo -TagName myTag -Sha aa218f56b14c9653891f9e74264a383fa43fefbd -Force

        Force an update even if it is not a fast-forward update

    .EXAMPLE
        $repo = Get-GitHubRepository -OwnerName microsoft -RepositoryName PowerShellForGitHub
        $ref = $repo | Get-GitHubReference -BranchName powershell
        $ref | Set-GithubReference -Sha aa218f56b14c9653891f9e74264a383fa43fefbd

        Get the "powershell" branch from the given repo and update its SHA
    #>
    [CmdletBinding(
        SupportsShouldProcess,
        DefaultParametersetName='Uri')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSShouldProcess", "", Justification="Methods called within here make use of PSShouldProcess, and the switch is passed on to them inherently.")]
    param(
        [Parameter(
            Mandatory,
            ParameterSetName='BranchElements')]
        [Parameter(
            Mandatory,
            ParameterSetName='TagElements')]
        [string] $OwnerName,

        [Parameter(
            Mandatory,
            ParameterSetName='BranchElements')]
        [Parameter(
            Mandatory,
            ParameterSetName='TagElements')]
        [string] $RepositoryName,

        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName='BranchUri')]
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName='TagUri')]
        [Alias('RepositoryUrl')]
        [string] $Uri,

        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName='TagUri')]
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName='TagElements')]
        [string] $TagName,

        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName='BranchUri')]
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName='BranchElements')]
        [string] $BranchName,

        [Parameter(Mandatory)]
        [string] $Sha,

        [switch] $Force,

        [string] $AccessToken,

        [switch] $NoStatus
    )

    Write-InvocationLog

    $elements = Resolve-RepositoryElements -BoundParameters $PSBoundParameters
    $OwnerName = $elements.ownerName
    $RepositoryName = $elements.repositoryName

    $telemetryProperties = @{
        'OwnerName' = (Get-PiiSafeString -PlainText $OwnerName)
        'RepositoryName' = (Get-PiiSafeString -PlainText $RepositoryName)
    }

    $reference = Resolve-GitHubReference -TagName $TagName -BranchName $BranchName

    $uriFragment = "repos/$OwnerName/$RepositoryName/git/refs/$reference"
    $description = "Updating SHA for Reference $reference in $RepositoryName to $Sha"

    $hashBody = @{
        'force' = $Force.IsPresent
        'sha' = $Sha
    }

    $params = @{
        'UriFragment' = $uriFragment
        'Method' = 'Patch'
        'Body' = (ConvertTo-Json -InputObject $hashBody)
        'Description' = $description
        'AccessToken' = $AccessToken
        'TelemetryEventName' = $MyInvocation.MyCommand.Name
        'TelemetryProperties' = $telemetryProperties
        'NoStatus' = (Resolve-ParameterWithDefaultConfigurationValue -Name NoStatus -ConfigValueName DefaultNoStatus)
    }

    return (Invoke-GHRestMethod @params | Add-GitHubBranchAdditionalProperties)
}

filter Remove-GitHubReference
{
    <#
    .SYNOPSIS
        Delete a reference in a given GitHub repository.

    .DESCRIPTION
        Delete a reference in a given GitHub repository.

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

    .PARAMETER TagName
        The name of the tag to be deleted.

    .PARAMETER BranchName
        The name of the branch to be deleted.

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
        Github.Reference
        GitHub.Repository

    .OUTPUTS
        None

    .EXAMPLE
        Remove-GitHubReference -OwnerName microsoft -RepositoryName PowerShellForGitHub -TagName powershellTagV1

    .EXAMPLE
        Remove-GitHubReference -Uri https://github.com/You/YourRepo -BranchName master

    .EXAMPLE
        Remove-GitHubReference -OwnerName microsoft -RepositoryName PowerShellForGitHub -TagName milestone1 -Confirm:$false
        Remove the tag milestone1 without prompting for confirmation

    .EXAMPLE
        Remove-GitHubReference -OwnerName microsoft -RepositoryName PowerShellForGitHub -TagName milestone1 -Force
        Remove the tag milestone1 without prompting for confirmation

    .EXAMPLE
        $repo = Get-GitHubRepository -OwnerName microsoft -RepositoryName PowerShellForGitHub
        $ref = $repo | Get-GitHubReference -TagName powershellV1
        $ref | Remove-GithubReference

        Get a reference to the "powershellV1" tag using Get-GithubReference on the repository. Pass it to this method in order to remove it
    #>
    [CmdletBinding(
        SupportsShouldProcess,
        ConfirmImpact="High")]
    [Alias('Delete-GitHubReference')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSShouldProcess", "", Justification="Methods called within here make use of PSShouldProcess, and the switch is passed on to them inherently.")]
    param(
        [Parameter(
            Mandatory,
            ParameterSetName='BranchElements')]
        [Parameter(
            Mandatory,
            ParameterSetName='TagElements')]
        [string] $OwnerName,

        [Parameter(
            Mandatory,
            ParameterSetName='BranchElements')]
        [Parameter(
            Mandatory,
            ParameterSetName='TagElements')]
        [string] $RepositoryName,

        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName='BranchUri')]
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName='TagUri')]
        [Alias('RepositoryUrl')]
        [string] $Uri,

        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName='TagUri')]
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName='TagElements')]
        [string] $TagName,

        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName='BranchUri')]
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName='BranchElements')]
        [string] $BranchName,

        [string] $AccessToken,

        [switch] $NoStatus
    )

    $repositoryInfoForDisplayMessage = if ($PSCmdlet.ParameterSetName -eq "Uri") { $Uri } else { $OwnerName, $RepositoryName -join "/" }
    $reference = Resolve-GitHubReference -TagName $TagName -BranchName $BranchName
    if ($Force -and (-not $Confirm))
    {
        $ConfirmPreference = 'None'
    }
    if ($PSCmdlet.ShouldProcess($repositoryInfoForDisplayMessage, "Remove reference: $reference"))
    {
        Write-InvocationLog

        $elements = Resolve-RepositoryElements -BoundParameters $PSBoundParameters
        $OwnerName = $elements.ownerName
        $RepositoryName = $elements.repositoryName

        $telemetryProperties = @{
            'OwnerName' = (Get-PiiSafeString -PlainText $OwnerName)
            'RepositoryName' = (Get-PiiSafeString -PlainText $RepositoryName)
        }

        $uriFragment = "repos/$OwnerName/$RepositoryName/git/refs/$reference"
        $description = "Deleting Reference $reference from repository $RepositoryName"

        $params = @{
            'UriFragment' = $uriFragment
            'Method' = 'Delete'
            'Body' = (ConvertTo-Json -InputObject $hashBody)
            'Description' = $description
            'AccessToken' = $AccessToken
            'TelemetryEventName' = $MyInvocation.MyCommand.Name
            'TelemetryProperties' = $telemetryProperties
            'NoStatus' = (Resolve-ParameterWithDefaultConfigurationValue -Name NoStatus -ConfigValueName DefaultNoStatus)
        }

        return Invoke-GHRestMethod @params
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
        GitHub.Reference
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
        [string] $TypeName = $script:GitHubReferenceTypeName
    )

    foreach ($item in $InputObject)
    {
        $item.PSObject.TypeNames.Insert(0, $TypeName)

        if (-not (Get-GitHubConfiguration -Name DisablePipelineSupport))
        {
            if ($null -ne $item.url)
            {
                $elements = Split-GitHubUri -Uri $item.url
            }
            else
            {
                $elements = Split-GitHubUri -Uri $item.commit.url
            }
            $repositoryUrl = Join-GitHubUri @elements

            Add-Member -InputObject $item -Name 'RepositoryUrl' -Value $repositoryUrl -MemberType NoteProperty -Force

            if ($item.ref.StartsWith('refs/heads/'))
            {
                $branchName = $item.ref -replace ('refs/heads/', '')
                Add-Member -InputObject $item -Name 'BranchName' -Value $branchName -MemberType NoteProperty -Force
            }
            if ($item.ref.StartsWith('refs/tags'))
            {
                $tagName = $item.ref -replace ('refs/tags/', '')
                Add-Member -InputObject $item -Name 'TagName' -Value $tagName -MemberType NoteProperty -Force
            }
        }

        Write-Output $item
    }
}

filter Resolve-GitHubReference
{
    <#
    .SYNOPSIS
        Get the given tag or branch in the form of a Github reference

    .DESCRIPTION
        Get the given tag or branch in the form of a Github reference i.e. tags/<TAG> for a tag and heads/<BRANCH> for a branch

        The Git repo for this module can be found here: http://aka.ms/PowerShellForGitHub

    .PARAMETER TagName
        The tag for which we need the reference string

    .PARAMETER BranchName
        The branch for which we need the reference string

    .EXAMPLE
        Resolve-GitHubReference -TagName powershellTag

    .EXAMPLE
        Resolve-GitHubReference -BranchName powershellBranch
    #>
    param(
        [string] $TagName,
        [string] $BranchName
    )

    if (-not [String]::IsNullOrEmpty($TagName))
    {
        return "tags/$TagName"
    }
    elseif (-not [String]::IsNullOrEmpty($BranchName))
    {
        return "heads/$BranchName"
    }
    return [String]::Empty
}