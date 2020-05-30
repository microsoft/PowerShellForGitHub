# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

function Get-GitHubReference
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

    .PARAMETER Tag
        The name of the Tag to be retrieved.

    .PARAMETER Branch
        The name of the Branch to be retrieved.

    .PARAMETER All
        If provided, will retrieve both branches and tags for the given repository

    .PARAMETER MatchPrefix
        If provided, this will return matching preferences for the given branch/tag name in case an exact match is not found

    .PARAMETER AccessToken
        If provided, this will be used as the AccessToken for authentication with the
        REST Api. Otherwise, will attempt to use the configured value or will run unauthenticated.

    .PARAMETER NoStatus
        If this switch is specified, long-running commands will run on the main thread
        with no commandline status update.  When not specified, those commands run in
        the background, enabling the command prompt to provide status information.
        If not supplied here, the DefaultNoStatus configuration property value will be used.

    .OUTPUTS
        [PSCustomObject]
        Details of the git reference in the given repository

    .EXAMPLE
        Get-GitHubReference -OwnerName microsoft -RepositoryName PowerShellForGitHub -Tag powershellTagV1

    .EXAMPLE
        Get-GitHubReference -OwnerName microsoft -RepositoryName PowerShellForGitHub -Branch master

    .EXAMPLE
        Get-GitHubReference -OwnerName microsoft -RepositoryName PowerShellForGitHub -Branch master -MatchPrefix

    .EXAMPLE
        Get-GitHubReference -OwnerName microsoft -RepositoryName -All
#>
    [CmdletBinding(
        SupportsShouldProcess,
        DefaultParameterSetName='Elements')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSShouldProcess", "", Justification="Methods called within here make use of PSShouldProcess, and the switch is passed on to them inherently.")]
    param(
        [Parameter(Mandatory, ParameterSetName='BranchElements')]
        [Parameter(Mandatory, ParameterSetName='TagElements')]
        [Parameter(Mandatory, ParameterSetName='Elements')]
        [string] $OwnerName,

        [Parameter(Mandatory, ParameterSetName='BranchElements')]
        [Parameter(Mandatory, ParameterSetName='TagElements')]
        [Parameter(Mandatory, ParameterSetName='Elements')]
        [string] $RepositoryName,

        [Parameter(Mandatory, ParameterSetName='BranchUri')]
        [Parameter(Mandatory, ParameterSetName='TagUri')]
        [Parameter(Mandatory, ParameterSetName='Uri')]
        [string] $Uri,

        [Parameter(ParameterSetName='TagUri')]
        [Parameter(ParameterSetName='TagElements')]
        [string] $Tag,

        [Parameter(ParameterSetName='BranchUri')]
        [Parameter(ParameterSetName='BranchElements')]
        [string] $Branch,

        [Parameter(ParameterSetName='Elements')]
        [Parameter(ParameterSetName='Uri')]
        [switch] $All,

        [Parameter(ParameterSetName='BranchUri')]
        [Parameter(ParameterSetName='BranchElements')]
        [Parameter(ParameterSetName='TagUri')]
        [Parameter(ParameterSetName='TagElements')]
        [switch] $MatchPrefix,

        [string] $AccessToken,

        [switch] $NoStatus
    )

    Write-InvocationLog -Invocation $MyInvocation

    $elements = Resolve-RepositoryElements -BoundParameters $PSBoundParameters -DisableValidation
    $OwnerName = $elements.ownerName
    $RepositoryName = $elements.repositoryName

    $telemetryProperties = @{
        'OwnerName' = (Get-PiiSafeString -PlainText $OwnerName)
        'RepositoryName' = (Get-PiiSafeString -PlainText $RepositoryName)
        'ProvidedReference' = $PSBoundParameters.ContainsKey('Reference')
    }

    $uriFragment = "repos/$OwnerName/$RepositoryName/git"

    if ($All) {
        # Add a slash at the end as Invoke-GHRestMethod removes the last trailing slash. Calling this API without the slash causes a 404
        $uriFragment = $uriFragment + "/matching-refs//"
        $description =  "Getting all references for $RepositoryName"
    }
    else {
        $reference = Resolve-Reference $Tag $Branch

        if ($MatchPrefix) {
            $uriFragment = $uriFragment +  "/matching-refs/$reference"
            $description =  "Getting references matching $reference for $RepositoryName"
        }
        else
        {
            # We want to return an exact match, call the 'get single reference' API
            $uriFragment = $uriFragment + "/ref/$reference"
            $description =  "Getting reference $reference for $RepositoryName"
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

    Write-Host $uriFragment
    return Invoke-GHRestMethodMultipleResult @params
}

function New-GitHubReference
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

    .PARAMETER Tag
        The name of the Tag to be created.

    .PARAMETER Branch
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

    .OUTPUTS
        [PSCustomObject]
        Details of the git reference created. Throws an Exception if the reference already exists

    .EXAMPLE
        New-GitHubReference -OwnerName microsoft -RepositoryName PowerShellForGitHub -Tag powershellTagV1 -Sha aa218f56b14c9653891f9e74264a383fa43fefbd

    .EXAMPLE
        New-GitHubReference -OwnerName microsoft -RepositoryName PowerShellForGitHub -Branch master -Sha aa218f56b14c9653891f9e74264a383fa43fefbd
    #>
    [CmdletBinding(SupportsShouldProcess)]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSShouldProcess", "", Justification="Methods called within here make use of PSShouldProcess, and the switch is passed on to them inherently.")]
    param(
        [Parameter(Mandatory, ParameterSetName='BranchElements')]
        [Parameter(Mandatory, ParameterSetName='TagElements')]
        [string] $OwnerName,

        [Parameter(Mandatory, ParameterSetName='BranchElements')]
        [Parameter(Mandatory, ParameterSetName='TagElements')]
        [string] $RepositoryName,

        [Parameter(Mandatory, ParameterSetName='BranchUri')]
        [Parameter(Mandatory, ParameterSetName='TagUri')]
        [string] $Uri,

        [Parameter(Mandatory, ParameterSetName='TagUri')]
        [Parameter(Mandatory, ParameterSetName='TagElements')]
        [string] $Tag,

        [Parameter(Mandatory, ParameterSetName='BranchUri')]
        [Parameter(Mandatory, ParameterSetName='BranchElements')]
        [string] $Branch,

        [Parameter(Mandatory)]
        [string] $Sha,

        [string] $AccessToken,

        [switch] $NoStatus
    )

    Write-InvocationLog -Invocation $MyInvocation

    $elements = Resolve-RepositoryElements -BoundParameters $PSBoundParameters -DisableValidation
    $OwnerName = $elements.ownerName
    $RepositoryName = $elements.repositoryName

    $telemetryProperties = @{
        'OwnerName' = (Get-PiiSafeString -PlainText $OwnerName)
        'RepositoryName' = (Get-PiiSafeString -PlainText $RepositoryName)
    }

    $reference = Resolve-Reference $Tag $Branch

    $uriFragment = "repos/$OwnerName/$RepositoryName/git/refs"
    $description =  "Creating Reference $reference for $RepositoryName from SHA $Sha"

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

    return Invoke-GHRestMethod @params
}

function Update-GitHubReference
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

    .PARAMETER Tag
        The name of the tag to be updated to the given SHA.

    .PARAMETER Branch
        The name of the branch to be updated to the given SHA.

    .PARAMETER Sha
        The updated SHA1 value to be set for this reference.

    .PARAMETER Force
        Indicates whether to force the update. If not set it will ensure that the update is a fast-forward update.

    .PARAMETER AccessToken
        If provided, this will be used as the AccessToken for authentication with the
        REST Api.  Otherwise, will attempt to use the configured value or will run unauthenticated.

    .PARAMETER NoStatus
        If this switch is specified, long-running commands will run on the main thread
        with no commandline status update.  When not specified, those commands run in
        the background, enabling the command prompt to provide status information.
        If not supplied here, the DefaultNoStatus configuration property value will be used.

    .EXAMPLE
        Update-GitHubReference -OwnerName microsoft -RepositoryName PowerShellForGitHub -Reference heads/master -Sha aa218f56b14c9653891f9e74264a383fa43fefbd
    #>
    [CmdletBinding(
        SupportsShouldProcess,
        DefaultParametersetName='Elements')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSShouldProcess", "", Justification="Methods called within here make use of PSShouldProcess, and the switch is passed on to them inherently.")]
    param(
        [Parameter(Mandatory, ParameterSetName='BranchElements')]
        [Parameter(Mandatory, ParameterSetName='TagElements')]
        [string] $OwnerName,

        [Parameter(Mandatory, ParameterSetName='BranchElements')]
        [Parameter(Mandatory, ParameterSetName='TagElements')]
        [string] $RepositoryName,

        [Parameter(Mandatory, ParameterSetName='BranchUri')]
        [Parameter(Mandatory, ParameterSetName='TagUri')]
        [string] $Uri,

        [Parameter(Mandatory, ParameterSetName='TagUri')]
        [Parameter(Mandatory, ParameterSetName='TagElements')]
        [string] $Tag,

        [Parameter(Mandatory, ParameterSetName='BranchUri')]
        [Parameter(Mandatory, ParameterSetName='BranchElements')]
        [string] $Branch,

        [Parameter(Mandatory)]
        [string] $Sha,

        [switch] $Force,

        [string] $AccessToken,

        [switch] $NoStatus
    )

    Write-InvocationLog -Invocation $MyInvocation

    $elements = Resolve-RepositoryElements -BoundParameters $PSBoundParameters -DisableValidation
    $OwnerName = $elements.ownerName
    $RepositoryName = $elements.repositoryName

    $telemetryProperties = @{
        'OwnerName' = (Get-PiiSafeString -PlainText $OwnerName)
        'RepositoryName' = (Get-PiiSafeString -PlainText $RepositoryName)
    }

    $reference = Resolve-Reference $Tag $Branch

    $uriFragment = "repos/$OwnerName/$RepositoryName/git/refs/$reference"
    $description =  "Updating SHA for Reference $reference in $RepositoryName to $Sha"

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

    return Invoke-GHRestMethod @params
}

function Remove-GitHubReference
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

    .PARAMETER Tag
        The name of the tag to be deleted.

    .PARAMETER Branch
        The name of the branch to be deleted.

    .PARAMETER AccessToken
        If provided, this will be used as the AccessToken for authentication with the
        REST Api.  Otherwise, will attempt to use the configured value or will run unauthenticated.

    .PARAMETER NoStatus
        If this switch is specified, long-running commands will run on the main thread
        with no commandline status update.  When not specified, those commands run in
        the background, enabling the command prompt to provide status information.
        If not supplied here, the DefaultNoStatus configuration property value will be used.

    .EXAMPLE
        Remove-GitHubReference -OwnerName microsoft -RepositoryName PowerShellForGitHub -Tag powershellTagV1

    .EXAMPLE
        Remove-GitHubReference -OwnerName microsoft -RepositoryName PowerShellForGitHub -Branch master

    .EXAMPLE
        Remove-GitHubReference -OwnerName microsoft -RepositoryName PowerShellForGitHub -Branch milestone1 -Confirm:$false
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact="High")]
    [Alias('Delete-GitHubReference')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSShouldProcess", "", Justification="Methods called within here make use of PSShouldProcess, and the switch is passed on to them inherently.")]
    param(
        [Parameter(Mandatory, ParameterSetName='BranchElements')]
        [Parameter(Mandatory, ParameterSetName='TagElements')]
        [string] $OwnerName,

        [Parameter(Mandatory, ParameterSetName='BranchElements')]
        [Parameter(Mandatory, ParameterSetName='TagElements')]
        [string] $RepositoryName,

        [Parameter(Mandatory, ParameterSetName='BranchUri')]
        [Parameter(Mandatory, ParameterSetName='TagUri')]
        [string] $Uri,

        [Parameter(Mandatory, ParameterSetName='TagUri')]
        [Parameter(Mandatory, ParameterSetName='TagElements')]
        [string] $Tag,

        [Parameter(Mandatory, ParameterSetName='BranchUri')]
        [Parameter(Mandatory, ParameterSetName='BranchElements')]
        [string] $Branch,

        [string] $AccessToken,

        [switch] $NoStatus
    )

    $repositoryInfoForDisplayMessage = if ($PSCmdlet.ParameterSetName -eq "Uri") { $Uri } else { $OwnerName, $RepositoryName -join "/" }
    $reference = Resolve-Reference $Tag $Branch
    if ($PSCmdlet.ShouldProcess($repositoryInfoForDisplayMessage, "Remove reference: $reference"))
    {
        Write-InvocationLog -Invocation $MyInvocation

        $elements = Resolve-RepositoryElements -BoundParameters $PSBoundParameters -DisableValidation
        $OwnerName = $elements.ownerName
        $RepositoryName = $elements.repositoryName

        $telemetryProperties = @{
            'OwnerName' = (Get-PiiSafeString -PlainText $OwnerName)
            'RepositoryName' = (Get-PiiSafeString -PlainText $RepositoryName)
        }

        $uriFragment = "repos/$OwnerName/$RepositoryName/git/refs/$reference"
        $description =  "Deleting Reference $reference from repository $RepositoryName"

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

function Resolve-Reference($Tag, $Branch)
{
    if (-not [String]::IsNullOrEmpty($Tag))
    {
        return "tags/$Tag"
    }
    elseif (-not [String]::IsNullOrEmpty($Branch))
    {
        return "heads/$Branch"
    }
    else
    {
        return [string]::Empty
    }
}