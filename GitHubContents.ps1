filter Get-GitHubContent
{
    <#
    .SYNOPSIS
        Retrieve the contents of a file or directory in a repository on GitHub.

    .DESCRIPTION
        Retrieve content from files on GitHub.
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

    .PARAMETER Path
        The file path for which to retrieve contents

    .PARAMETER MediaType
        The format in which the API will return the body of the issue.
        Object - Return a json object representation a file or folder. This is the default if you do not pass any specific media type.
        Raw - Return the raw contents of a file.
        Html - For markup files such as Markdown or AsciiDoc, you can retrieve the rendered HTML using the Html media type.

    .PARAMETER ResultAsString
        If this switch is specified and the MediaType is either Raw or Html then the resulting bytes will be decoded the result will be
        returned as a string instead of bytes. If the MediaType is Object, then an additional property on the object is returned 'contentAsString'
        which will be the decoded base64 result as a string.

    .PARAMETER AccessToken
        If provided, this will be used as the AccessToken for authentication with the
        REST Api.  Otherwise, will attempt to use the configured value or will run unauthenticated.

    .PARAMETER NoStatus
        If this switch is specified, long-running commands will run on the main thread
        with no commandline status update.  When not specified, those commands run in
        the background, enabling the command prompt to provide status information.
        If not supplied here, the DefaultNoStatus configuration property value will be used.

    .EXAMPLE
        Get-GitHubContent -OwnerName microsoft -RepositoryName PowerShellForGitHub -Path README.md -MediaType Html

        Get the Html output for the README.md file

    .EXAMPLE
        Get-GitHubContent -OwnerName microsoft -RepositoryName PowerShellForGitHub -Path LICENSE

        Get the Binary file output for the LICENSE file

    .EXAMPLE
        Get-GitHubContent -OwnerName microsoft -RepositoryName PowerShellForGitHub -Path Tests

        List the files within the "Tests" path of the repository
#>
    [CmdletBinding(
        SupportsShouldProcess,
        DefaultParameterSetName = 'Elements')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSShouldProcess", "", Justification = "Methods called within here make use of PSShouldProcess, and the switch is passed on to them inherently.")]
    param(
        [Parameter(Mandatory, ParameterSetName = 'Elements')]
        [string] $OwnerName,

        [Parameter(Mandatory, ParameterSetName = 'Elements')]
        [string] $RepositoryName,

        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName='Uri')]
        [Alias('RepositoryUrl')]
        [string] $Uri,

        [Parameter(ValueFromPipeline)]
        [string] $Path,

        [ValidateSet('Raw', 'Html', 'Object')]
        [string] $MediaType = 'Object',

        [switch] $ResultAsString,

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
    }

    $description = [String]::Empty

    $uriFragment = "/repos/$OwnerName/$RepositoryName/contents"

    if ($PSBoundParameters.ContainsKey('Path'))
    {
        $Path = $Path.TrimStart("\", "/")
        $uriFragment += "/$Path"
        $description = "Getting content for $Path in $RepositoryName"
    }
    else
    {
        $description = "Getting all content for in $RepositoryName"
    }

    $params = @{
        'UriFragment' = $uriFragment
        'Description' = $description
        'AcceptHeader' = (Get-MediaAcceptHeader -MediaType $MediaType)
        'AccessToken' = $AccessToken
        'TelemetryEventName' = $MyInvocation.MyCommand.Name
        'TelemetryProperties' = $telemetryProperties
        'NoStatus' = (Resolve-ParameterWithDefaultConfigurationValue -Name NoStatus -ConfigValueName DefaultNoStatus)
    }

    $result = Invoke-GHRestMethodMultipleResult @params

    if ($ResultAsString)
    {
        if ($MediaType -eq 'Raw' -or $MediaType -eq 'Html')
        {
            # Decode bytes to string
            $result = [System.Text.Encoding]::UTF8.GetString($result)
        }
        elseif ($MediaType -eq 'Object')
        {
            # Convert from base64
            $decoded = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($result.content))
            Add-Member -InputObject $result -NotePropertyName "contentAsString" -NotePropertyValue $decoded
        }
    }

    return $result
}
