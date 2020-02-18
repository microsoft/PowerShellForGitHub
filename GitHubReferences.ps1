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
        Name of the reference, for example: "heads/<branch name>" for branches and "tags/<tag name>" for tags

    .PARAMETER AccessToken
        If provided, this will be used as the AccessToken for authentication with the
        REST Api.  Otherwise, will attempt to use the configured value or will run unauthenticated.

    .PARAMETER NoStatus
        If this switch is specified, long-running commands will run on the main thread
        with no commandline status update.  When not specified, those commands run in
        the background, enabling the command prompt to provide status information.
        If not supplied here, the DefaultNoStatus configuration property value will be used.

    .EXAMPLE
        Get-GitHubReference -OwnerName Powershell -RepositoryName PowerShellForGitHub -Reference heads/master
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
    $uriFragment = "/repos/$OwnerName/$RepositoryName/git/refs/$Reference"
    $description =  "Getting Reference $Reference for $RepositoryName"

    $params = @{
        'UriFragment' = $uriFragment
        'Method' = 'Get'
        'Description' =  $description
        'AcceptHeader' = 'application/vnd.github.symmetra-preview+json'
        'AccessToken' = $AccessToken
        'TelemetryEventName' = $MyInvocation.MyCommand.Name
        'TelemetryProperties' = $telemetryProperties
        'NoStatus' = (Resolve-ParameterWithDefaultConfigurationValue -Name NoStatus -ConfigValueName DefaultNoStatus)
    }

    try
    {
        return Invoke-GHRestMethod @params
    }
    catch
    {
        Write-InteractiveHost "No reference named $Reference exists in repository $RepositoryName" -NoNewline -f Red
        Write-Log -Level Error "No reference named $Reference exists in repository $RepositoryName"
        return $null
    }

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
        The name of the fully qualified reference to be created (eg: refs/heads/master)

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

    .EXAMPLE
        -GitHubReference -OwnerName Powershell -RepositoryName PowerShellForGitHub -Reference refs/heads/master -Sha aa218f56b14c9653891f9e74264a383fa43fefbd
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

    $uriFragment = "/repos/$OwnerName/$RepositoryName/git/refs"
    $description =  "Creating Reference $Reference for $RepositoryName from SHA $Sha"

    $hashBody = @{
        'ref' = $Reference
        'sha' = $Sha
    }

    $params = @{
        'UriFragment' = $uriFragment
        'Method' = 'Post'
        'Body' = (ConvertTo-Json -InputObject $hashBody)
        'Description' =  $description
        'AcceptHeader' = 'application/vnd.github.symmetra-preview+json'
        'AccessToken' = $AccessToken
        'TelemetryEventName' = $MyInvocation.MyCommand.Name
        'TelemetryProperties' = $telemetryProperties
        'NoStatus' = (Resolve-ParameterWithDefaultConfigurationValue -Name NoStatus -ConfigValueName DefaultNoStatus)
    }

    return Invoke-GHRestMethod @params
}
