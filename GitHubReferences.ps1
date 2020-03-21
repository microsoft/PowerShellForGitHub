# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

function Get-GitHubReference
{
<#
    .SYNOPSIS
        Retrieve a reference of a given GitHub repository.

    .DESCRIPTION
        Retrieve a reference of a given GitHub repository.
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

    .PARAMETER Reference
        Name of the reference, for example: "heads/<branch name>" for branches and "tags/<tag name>" for tags.
        Gets all the references (everything in the namespace, not only heads and tags) if not provided

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
        Get-GitHubReference -OwnerName microsoft -RepositoryName PowerShellForGitHub -Reference heads/master
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

        [string] $Reference,

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

    if ($OwnerName -xor $RepositoryName)
    {
        $message = 'You must specify both Owner Name and Repository Name.'
        Write-Log -Message $message -Level Error
        throw $message
    }

    if (-not [String]::IsNullOrEmpty($RepositoryName))
    {
        $uriFragment = "repos/$OwnerName/$RepositoryName/git/matching-refs"
        $description =  "Getting all references for $RepositoryName"
        if ($PSBoundParameters.ContainsKey('Reference'))
        {
            $uriFragment = $uriFragment + "/$Reference"
            $description =  "Getting Reference $Reference for $RepositoryName"
        }
        else
        {
            # Add a slash at the end. Calling it with only matching-refs without the slash causes a 404
            $uriFragment = $uriFragment + "//"
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

    .PARAMETER Reference
        The name of the reference to be created (eg: heads/master or tags/myTag)

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
        New-GitHubReference -OwnerName microsoft -RepositoryName PowerShellForGitHub -Reference heads/master -Sha aa218f56b14c9653891f9e74264a383fa43fefbd
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
        [string] $Reference,

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

    if ($OwnerName -xor $RepositoryName)
    {
        $message = 'You must specify both Owner Name and Repository Name.'
        Write-Log -Message $message -Level Error
        throw $message
    }

    $uriFragment = "repos/$OwnerName/$RepositoryName/git/refs"
    $description =  "Creating Reference $Reference for $RepositoryName from SHA $Sha"

    $hashBody = @{
        'ref' = "refs/" + $Reference
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

    .PARAMETER Reference
        The name of the reference to be updated (eg: heads/master or tags/myTag)
    
    .PARAMETER Sha
        The updated SHA1 value to be set for this reference
    
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
        [Parameter(ParameterSetName='Elements')]
        [string] $OwnerName,

        [Parameter(ParameterSetName='Elements')]
        [string] $RepositoryName,

        [Parameter(
            Mandatory,
            ParameterSetName='Uri')]
        [string] $Uri,

        [Parameter(Mandatory)]
        [string] $Reference,

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

    if ($OwnerName -xor $RepositoryName)
    {
        $message = 'You must specify both Owner Name and Repository Name.'
        Write-Log -Message $message -Level Error
        throw $message
    }

    $uriFragment = "repos/$OwnerName/$RepositoryName/git/refs/$Reference"
    $description =  "Updating SHA for Reference $Reference in $RepositoryName to $Sha"

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

    .PARAMETER Reference
        The name of the reference to be deleted (eg: heads/master)

    .PARAMETER AccessToken
        If provided, this will be used as the AccessToken for authentication with the
        REST Api.  Otherwise, will attempt to use the configured value or will run unauthenticated.

    .PARAMETER NoStatus
        If this switch is specified, long-running commands will run on the main thread
        with no commandline status update.  When not specified, those commands run in
        the background, enabling the command prompt to provide status information.
        If not supplied here, the DefaultNoStatus configuration property value will be used.

    .EXAMPLE
        Remove-GitHubReference -OwnerName microsoft -RepositoryName PowerShellForGitHub -Reference heads/master
    #>
    [CmdletBinding(
        SupportsShouldProcess,
        DefaultParametersetName='Elements')]
    [Alias('Delete-GitHubReference')]
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
        [string] $Reference,

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

    if ($OwnerName -xor $RepositoryName)
    {
        $message = 'You must specify both Owner Name and Repository Name.'
        Write-Log -Message $message -Level Error
        throw $message
    }

    $uriFragment = "repos/$OwnerName/$RepositoryName/git/refs/$Reference"
    $description =  "Deleting Reference $Reference from repository $RepositoryName"

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