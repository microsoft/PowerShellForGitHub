function Get-GitHubContents
{
<#
    .SYNOPSIS
        Retrieve content from files on GitHub.
    .DESCRIPTION
        Retrieve content from files on GitHub.
        The Git repo for this module can be found here: http://aka.ms/PowerShellForGitHub
    .PARAMETER OwnerName
        Owner of the repository.
        If not supplied here, the DefaultOwnerName configuration property value will be used.
    .PARAMETER RepositoryName
        Name of the repository.
        If not supplied here, the DefaultRepositoryName configuration property value will be used.    
    .PARAMETER Path
        The file path for which to retrieve contents
    .PARAMETER MediaType
        The format in which the API will return the body of the issue.
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
#>
    [CmdletBinding(
        SupportsShouldProcess,
        DefaultParametersetName='Elements')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSShouldProcess", "", Justification="Methods called within here make use of PSShouldProcess, and the switch is passed on to them inherently.")]
    param(
        [Parameter(Mandatory, ParameterSetName='Elements')]
        [string] $OwnerName,

        [Parameter(Mandatory, ParameterSetName='Elements')]
        [string] $RepositoryName,

        [string] $Path,

        [ValidateSet('Raw', 'Text', 'Html', 'Full')]
        [string] $MediaType ='Raw',

        [string] $AccessToken,

        [switch] $NoStatus
    )

    Write-InvocationLog

    $elements = Resolve-RepositoryElements -DisableValidation
    $OwnerName = $elements.ownerName
    $RepositoryName = $elements.repositoryName

    $telemetryProperties = @{
        'OwnerName' = (Get-PiiSafeString -PlainText $OwnerName)
        'RepositoryName' = (Get-PiiSafeString -PlainText $RepositoryName)
        'Path' = $PSBoundParameters.ContainsKey('Path')
    }

    $uriFragment = [String]::Empty
    $description = [String]::Empty    

    $uriFragment = "/repos/$OwnerName/$RepositoryName/contents"    

    if ($PSBoundParameters.ContainsKey('Path'))
    {
        $uriFragment += "/$Path"
        $description = "Getting content for $Path in $RepositoryName"
    }
    else 
    {
        $description = "Getting all content for in $RepositoryName"
    }

    $params = @{
        'UriFragment' = $uriFragment
        'Description' =  $description
        'AcceptHeader' = (Get-MediaAcceptHeader -MediaType $MediaType -AcceptHeader $symmetraAcceptHeader)
        'AccessToken' = $AccessToken
        'TelemetryEventName' = $MyInvocation.MyCommand.Name
        'TelemetryProperties' = $telemetryProperties
        'NoStatus' = (Resolve-ParameterWithDefaultConfigurationValue -Name NoStatus -ConfigValueName DefaultNoStatus)
    }

    $result = Invoke-GHRestMethodMultipleResult @params

    return $result
}
