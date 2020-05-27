# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

function Get-GitHubRepositoryPublicKey {
<#
    .SYNOPSIS
        Gets the public key for a given repository, which is needed to encrypt secrets.

    .DESCRIPTION
        Gets the public key for a given repository, which is needed to encrypt secrets before creating or updating.
        Anyone with read access to the repository can use this cmdlet.
        If the repository is private you must use an access token with the repo scope.
        GitHub Apps must have the secrets repository permission to use this cmdlet.

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

    .PARAMETER AccessToken
        If provided, this will be used as the AccessToken for authentication with the
        REST Api.  Otherwise, will attempt to use the configured value or will run unauthenticated.

    .PARAMETER NoStatus
        If this switch is specified, long-running commands will run on the main thread
        with no commandline status update.  When not specified, those commands run in
        the background, enabling the command prompt to provide status information.
        If not supplied here, the DefaultNoStatus configuration property value will be used.

    .EXAMPLE
        Get-GitHubRepositoryPublicKey -OwnerName Microsoft -RepositoryName PowerShellForGitHub

    .EXAMPLE
        Get-GitHubRepositoryPublicKey -Uri 'https://github.com/Microsoft/PowerShellForGitHub'
#>
    [CmdletBinding(
        SupportsShouldProcess,
        DefaultParameterSetName='Elements')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSShouldProcess", "", Justification="Methods called within here make use of PSShouldProcess, and the switch is passed on to them inherently.")]
    param(
        [Parameter(ParameterSetName='Elements')]
        [string] $OwnerName,

        [Parameter(ParameterSetName='Elements')]
        [string] $RepositoryName,

        [Parameter(Mandatory, ParameterSetName='Uri')]
        [string] $Uri,

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

    $params = @{
        'UriFragment' = "/repos/$OwnerName/$RepositoryName/actions/secrets/public-key"
        'Description' =  "Getting public key for $RepositoryName."
        'AcceptHeader' = 'application/vnd.github.symmetra-preview+json'
        'AccessToken' = $AccessToken
        'TelemetryEventName' = $MyInvocation.MyCommand.Name
        'TelemetryProperties' = $telemetryProperties
        'NoStatus' = (Resolve-ParameterWithDefaultConfigurationValue -Name NoStatus -ConfigValueName DefaultNoStatus)
    }

    return Invoke-GHRestMethodMultipleResult @params
}

function Get-GitHubSecretInfo {
<#
    .SYNOPSIS
        Lists all secrets or gets a particular secret available in a repository without revealing their encrypted values.

    .DESCRIPTION
        Lists all secrets or gets a particular secret available in a repository without revealing their encrypted values.
        You must authenticate using an access token with the repo scope to use this cmdlet.
        GitHub Apps must have the secrets repository permission to use this cmdlet.

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

    .PARAMETER Name
        Name of the secret.
        If not provided, it will retrieve all secrets in a repository.

    .PARAMETER AccessToken
        If provided, this will be used as the AccessToken for authentication with the
        REST Api.  Otherwise, will attempt to use the configured value or will run unauthenticated.

    .PARAMETER NoStatus
        If this switch is specified, long-running commands will run on the main thread
        with no commandline status update.  When not specified, those commands run in
        the background, enabling the command prompt to provide status information.
        If not supplied here, the DefaultNoStatus configuration property value will be used.

    .EXAMPLE
        Get-GitHubSecretInfo -OwnerName Microsoft -RepositoryName PowerShellForGitHub

    .EXAMPLE
        Get-GitHubSecretInfo -Uri 'https://github.com/Microsoft/PowerShellForGitHub'

    .EXAMPLE
        Get-GitHubSecretInfo -OwnerName Microsoft -RepositoryName PowerShellForGitHub -SecretName MySecret
#>
    [CmdletBinding(
        SupportsShouldProcess,
        DefaultParameterSetName='Elements')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSShouldProcess", "", Justification="Methods called within here make use of PSShouldProcess, and the switch is passed on to them inherently.")]
    param(
        [Parameter(ParameterSetName='Elements')]
        [string] $OwnerName,

        [Parameter(ParameterSetName='Elements')]
        [string] $RepositoryName,

        [Parameter(Mandatory, ParameterSetName='Uri')]
        [string] $Uri,

        [string] $SecretName,

        [string] $AccessToken,

        [switch] $NoStatus
    )

    if ([WildcardPattern]::ContainsWildcardCharacters($SecretName))
    {
        throw "The Name parameter cannot contain wild card characters."
    }

    Write-InvocationLog

    $elements = Resolve-RepositoryElements
    $OwnerName = $elements.ownerName
    $RepositoryName = $elements.repositoryName

    $telemetryProperties = @{
        'OwnerName' = (Get-PiiSafeString -PlainText $OwnerName)
        'RepositoryName' = (Get-PiiSafeString -PlainText $RepositoryName)
    }

    if ($PSBoundParameters.ContainsKey('SecretName'))
    {
        $description =  "Getting secret info of $SecretName for $RepositoryName"
        $uriFragment = "/repos/$OwnerName/$RepositoryName/actions/secrets/$SecretName"
    }
    else
    {
        $description = "Getting secret infos for $RepositoryName"
        $uriFragment = "/repos/$OwnerName/$RepositoryName/actions/secrets"
    }

    $params = @{
        'UriFragment' = $uriFragment
        'Description' =  $description
        'AcceptHeader' = 'application/vnd.github.symmetra-preview+json'
        'AccessToken' = $AccessToken
        'TelemetryEventName' = $MyInvocation.MyCommand.Name
        'TelemetryProperties' = $telemetryProperties
        'NoStatus' = (Resolve-ParameterWithDefaultConfigurationValue -Name NoStatus -ConfigValueName DefaultNoStatus)
    }

    try {
        $result = Invoke-GHRestMethodMultipleResult @params
    } catch {
        $message = $_.ErrorDetails.Message
        if ($message -notmatch 'Not Found') {
            throw $_
        }
    }

    if($PSBoundParameters.ContainsKey('SecretName')) {
        $result
    } else {
        $result.secrets
    }
}

function Set-GitHubSecret {
<#
    .SYNOPSIS
        Creates or updates a repository secret with a value.

    .DESCRIPTION
        Creates or updates a repository secret with a value. The value is encrypted using PSSodium which
        is simple wrapper around Sodium.Core.

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

    .PARAMETER Name
        Name of the secret.
        If not provided, it will retrieve all secrets in a repository.

    .PARAMETER Value
        Value for the secret.
        If not provided, it will retrieve all secrets in a repository.

    .PARAMETER AccessToken
        If provided, this will be used as the AccessToken for authentication with the
        REST Api.  Otherwise, will attempt to use the configured value or will run unauthenticated.

    .PARAMETER NoStatus
        If this switch is specified, long-running commands will run on the main thread
        with no commandline status update.  When not specified, those commands run in
        the background, enabling the command prompt to provide status information.
        If not supplied here, the DefaultNoStatus configuration property value will be used.

    .EXAMPLE
        Set-GitHubSecret -OwnerName Microsoft -RepositoryName PowerShellForGitHub -SecretName MySecret -SecretValue 'my text'

    .EXAMPLE
        Set-GitHubSecret -Uri 'https://github.com/Microsoft/PowerShellForGitHub' -SecretName MySecret -SecretValue 'my text'
#>
    [CmdletBinding(
        SupportsShouldProcess,
        DefaultParameterSetName='Elements')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSShouldProcess", "", Justification="Methods called within here make use of PSShouldProcess, and the switch is passed on to them inherently.")]
    param(
        [Parameter(ParameterSetName='Elements')]
        [string] $OwnerName,

        [Parameter(ParameterSetName='Elements')]
        [string] $RepositoryName,

        [Parameter(Mandatory, ParameterSetName='Uri')]
        [string] $Uri,

        [Parameter(Mandatory, ParameterSetName='Uri')]
        [Parameter(Mandatory, ParameterSetName='Elements')]
        [string] $SecretName,

        [Parameter(Mandatory, ParameterSetName='Uri')]
        [Parameter(Mandatory, ParameterSetName='Elements')]
        [SecureString] $SecretValue,

        [string] $AccessToken,

        [switch] $NoStatus
    )

    Write-InvocationLog

    $elements = Resolve-RepositoryElements
    $OwnerName = $elements.ownerName
    $RepositoryName = $elements.repositoryName

    $publicKeyInfo = Get-GitHubRepositoryPublicKey -OwnerName $OwnerName -RepositoryName $RepositoryName -NoStatus

    $hashBody = @{
        encrypted_value = ConvertTo-SodiumEncryptedString -Text $SecretValue -PublicKey $publicKeyInfo.key
        key_id = $publicKeyInfo.key_id
    }

    $telemetryProperties = @{
        'OwnerName' = (Get-PiiSafeString -PlainText $OwnerName)
        'RepositoryName' = (Get-PiiSafeString -PlainText $RepositoryName)
    }

    $description =  "Setting secret of $SecretName for $RepositoryName"
    $uriFragment = "/repos/$OwnerName/$RepositoryName/actions/secrets/$SecretName"

    $params = @{
        'UriFragment' = $uriFragment
        'Description' =  $description
        'Body' = (ConvertTo-Json -InputObject $hashBody)
        'Method' = 'Put'
        'AcceptHeader' = 'application/vnd.github.symmetra-preview+json'
        'AccessToken' = $AccessToken
        'TelemetryEventName' = $MyInvocation.MyCommand.Name
        'TelemetryProperties' = $telemetryProperties
        'NoStatus' = (Resolve-ParameterWithDefaultConfigurationValue -Name NoStatus -ConfigValueName DefaultNoStatus)
    }

    Invoke-GHRestMethod @params
}

function New-GitHubSecret {
<#
    .SYNOPSIS
        Creates a repository secret with a value. Throws if the secret already exists.

    .DESCRIPTION
        Creates a repository secret with a value. Throws if the secret already exists.
        The value is encrypted using PSSodium which is simple wrapper around Sodium.Core.

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

    .PARAMETER Name
        Name of the secret.
        If not provided, it will retrieve all secrets in a repository.

    .PARAMETER Value
        Value for the secret.
        If not provided, it will retrieve all secrets in a repository.

    .PARAMETER AccessToken
        If provided, this will be used as the AccessToken for authentication with the
        REST Api.  Otherwise, will attempt to use the configured value or will run unauthenticated.

    .PARAMETER NoStatus
        If this switch is specified, long-running commands will run on the main thread
        with no commandline status update.  When not specified, those commands run in
        the background, enabling the command prompt to provide status information.
        If not supplied here, the DefaultNoStatus configuration property value will be used.

    .EXAMPLE
        New-GitHubSecret -OwnerName Microsoft -RepositoryName PowerShellForGitHub -SecretName MySecret -SecretValue 'my text'

    .EXAMPLE
        New-GitHubSecret -Uri 'https://github.com/Microsoft/PowerShellForGitHub' -SecretName MySecret -SecretValue 'my text'
#>
    [CmdletBinding(
        SupportsShouldProcess,
        DefaultParameterSetName='Elements')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSShouldProcess", "", Justification="Methods called within here make use of PSShouldProcess, and the switch is passed on to them inherently.")]
    param(
        [Parameter(ParameterSetName='Elements')]
        [string] $OwnerName,

        [Parameter(ParameterSetName='Elements')]
        [string] $RepositoryName,

        [Parameter(Mandatory, ParameterSetName='Uri')]
        [string] $Uri,

        [Parameter(Mandatory, ParameterSetName='Uri')]
        [Parameter(Mandatory, ParameterSetName='Elements')]
        [string] $SecretName,

        [Parameter(Mandatory, ParameterSetName='Uri')]
        [Parameter(Mandatory, ParameterSetName='Elements')]
        [SecureString] $SecretValue,

        [string] $AccessToken,

        [switch] $NoStatus
    )

    Write-InvocationLog

    $elements = Resolve-RepositoryElements
    $OwnerName = $elements.ownerName
    $RepositoryName = $elements.repositoryName

    if(Get-GitHubSecretInfo -OwnerName $OwnerName -RepositoryName $RepositoryName -SecretName $SecretName -ErrorAction Ignore) {
        throw "Secret already exists."
    }

    Set-GitHubSecret @PSBoundParameters
}

function Remove-GitHubSecret {
<#
    .SYNOPSIS
        Removes a repository secret with a value.

    .DESCRIPTION
        Removes a repository secret with a value. The value is encrypted using PSSodium which
        is simple wrapper around Sodium.Core.

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

    .PARAMETER Name
        Name of the secret.
        If not provided, it will retrieve all secrets in a repository.

    .PARAMETER AccessToken
        If provided, this will be used as the AccessToken for authentication with the
        REST Api.  Otherwise, will attempt to use the configured value or will run unauthenticated.

    .PARAMETER NoStatus
        If this switch is specified, long-running commands will run on the main thread
        with no commandline status update.  When not specified, those commands run in
        the background, enabling the command prompt to provide status information.
        If not supplied here, the DefaultNoStatus configuration property value will be used.

    .EXAMPLE
        Set-GitHubSecret -OwnerName Microsoft -RepositoryName PowerShellForGitHub -SecretName MySecret -SecretValue 'my text'

    .EXAMPLE
        Set-GitHubSecret -Uri 'https://github.com/Microsoft/PowerShellForGitHub' -SecretName MySecret -SecretValue 'my text'
#>
    [CmdletBinding(
        SupportsShouldProcess,
        DefaultParameterSetName='Elements')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSShouldProcess", "", Justification="Methods called within here make use of PSShouldProcess, and the switch is passed on to them inherently.")]
    param(
        [Parameter(ParameterSetName='Elements')]
        [string] $OwnerName,

        [Parameter(ParameterSetName='Elements')]
        [string] $RepositoryName,

        [Parameter(Mandatory, ParameterSetName='Uri')]
        [string] $Uri,

        [Parameter(Mandatory, ParameterSetName='Uri')]
        [Parameter(Mandatory, ParameterSetName='Elements')]
        [string] $SecretName,

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

    $description =  "Setting secret of $SecretName for $RepositoryName"
    $uriFragment = "/repos/$OwnerName/$RepositoryName/actions/secrets/$SecretName"

    $params = @{
        'UriFragment' = $uriFragment
        'Description' =  $description
        'Method' = 'Delete'
        'AcceptHeader' = 'application/vnd.github.symmetra-preview+json'
        'AccessToken' = $AccessToken
        'TelemetryEventName' = $MyInvocation.MyCommand.Name
        'TelemetryProperties' = $telemetryProperties
        'NoStatus' = (Resolve-ParameterWithDefaultConfigurationValue -Name NoStatus -ConfigValueName DefaultNoStatus)
    }

    Invoke-GHRestMethod @params
}
