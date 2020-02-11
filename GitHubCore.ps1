# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

@{
    defaultAcceptHeader = 'application/vnd.github.v3+json'
    mediaTypeVersion = 'v3'
    squirrelAcceptHeader = 'application/vnd.github.squirrel-girl-preview'
    symmetraAcceptHeader = 'application/vnd.github.symmetra-preview+json'

 }.GetEnumerator() | ForEach-Object {
     Set-Variable -Scope Script -Option ReadOnly -Name $_.Key -Value $_.Value
 }

Set-Variable -Scope Script -Option ReadOnly -Name ValidBodyContainingRequestMethods -Value ('Post', 'Patch', 'Put', 'Delete')

function Invoke-GHRestMethod
{
<#
    .SYNOPSIS
        A wrapper around Invoke-WebRequest that understands the Store API.

    .DESCRIPTION
        A very heavy wrapper around Invoke-WebRequest that understands the Store API and
        how to perform its operation with and without console status updates.  It also
        understands how to parse and handle errors from the REST calls.

        The Git repo for this module can be found here: http://aka.ms/PowerShellForGitHub

    .PARAMETER UriFragment
        The unique, tail-end, of the REST URI that indicates what Store REST action will
        be peformed.  This should not start with a leading "/".

    .PARAMETER Method
        The type of REST method being peformed.  This only supports a reduced set of the
        possible REST methods (delete, get, post, put).

    .PARAMETER Description
        A friendly description of the operation being performed for logging and console
        display purposes.

    .PARAMETER Body
        This optional parameter forms the body of a PUT or POST request. It will be automatically
        encoded to UTF8 and sent as Content Type: "application/json; charset=UTF-8"

    .PARAMETER AcceptHeader
        Specify the media type in the Accept header.  Different types of commands may require
        different media types.

    .PARAMETER ExtendedResult
        If specified, the result will be a PSObject that contains the normal result, along with
        the response code and other relevant header detail content.

    .PARAMETER AccessToken
        If provided, this will be used as the AccessToken for authentication with the
        REST Api as opposed to requesting a new one.

    .PARAMETER TelemetryEventName
        If provided, the successful execution of this REST command will be logged to telemetry
        using this event name.

    .PARAMETER TelemetryProperties
        If provided, the successful execution of this REST command will be logged to telemetry
        with these additional properties.  This will be silently ignored if TelemetryEventName
        is not provided as well.

    .PARAMETER TelemetryExceptionBucket
        If provided, any exception that occurs will be logged to telemetry using this bucket.
        It's possible that users will wish to log exceptions but not success (by providing
        TelemetryEventName) if this is being executed as part of a larger scenario.  If this
        isn't provided, but TelemetryEventName *is* provided, then TelemetryEventName will be
        used as the exception bucket value in the event of an exception.  If neither is specified,
        no bucket value will be used.

    .PARAMETER NoStatus
        If this switch is specified, long-running commands will run on the main thread
        with no commandline status update.  When not specified, those commands run in
        the background, enabling the command prompt to provide status information.

    .OUTPUTS
        [PSCutomObject] - The result of the REST operation, in whatever form it comes in.

    .EXAMPLE
        Invoke-GHRestMethod -UriFragment "applications/" -Method Get -Description "Get first 10 applications"

        Gets the first 10 applications for the connected dev account.

    .EXAMPLE
        Invoke-GHRestMethod -UriFragment "applications/0ABCDEF12345/submissions/1234567890123456789/" -Method Delete -Description "Delete Submission" -NoStatus

        Deletes the specified submission, but the request happens in the foreground and there is
        no additional status shown to the user until a response is returned from the REST request.

    .NOTES
        This wraps Invoke-WebRequest as opposed to Invoke-RestMethod because we want access to the headers
        that are returned in the response (specifically 'MS-ClientRequestId') for logging purposes, and
        Invoke-RestMethod drops those headers.
#>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [string] $UriFragment,

        [Parameter(Mandatory)]
        [ValidateSet('Delete', 'Get', 'Post', 'Patch', 'Put')]
        [string] $Method,

        [string] $Description,

        [string] $Body = $null,

        [string] $AcceptHeader = $script:defaultAcceptHeader,

        [switch] $ExtendedResult,

        [string] $AccessToken,

        [string] $TelemetryEventName = $null,

        [hashtable] $TelemetryProperties = @{},

        [string] $TelemetryExceptionBucket = $null,

        [switch] $NoStatus
    )

    # Normalize our Uri fragment.  It might be coming from a method implemented here, or it might
    # be coming from the Location header in a previous response.  Either way, we don't want there
    # to be a leading "/" or trailing '/'
    if ($UriFragment.StartsWith('/')) { $UriFragment = $UriFragment.Substring(1) }
    if ($UriFragment.EndsWith('/')) { $UriFragment = $UriFragment.Substring(0, $UriFragment.Length - 1) }

    if ([String]::IsNullOrEmpty($Description))
    {
        $Description = "Executing: $UriFragment"
    }

    # Telemetry-related
    $stopwatch = New-Object -TypeName System.Diagnostics.Stopwatch
    $localTelemetryProperties = @{
        'UriFragment' = $UriFragment
        'WaitForCompletion' = ($WaitForCompletion -eq $true)
    }
    $TelemetryProperties.Keys | ForEach-Object { $localTelemetryProperties[$_] = $TelemetryProperties[$_] }
    $errorBucket = $TelemetryExceptionBucket
    if ([String]::IsNullOrEmpty($errorBucket))
    {
        $errorBucket = $TelemetryEventName
    }

    # Since we have retry logic, we won't create a new stopwatch every time,
    # we'll just always continue the existing one...
    $stopwatch.Start()

    $hostName = $(Get-GitHubConfiguration -Name "ApiHostName")

    if ($hostName -eq 'github.com')
    {
        $url = "https://api.$hostName/$UriFragment"
    }
    else
    {
        $url = "https://$hostName/api/v3/$UriFragment"
    }

    # It's possible that we are directly calling the "nextLink" from a previous command which
    # provides the full URI.  If that's the case, we'll just use exactly what was provided to us.
    if ($UriFragment.StartsWith('http'))
    {
        $url = $UriFragment
    }

    $headers = @{
        'Accept' = $AcceptHeader
        'User-Agent' = 'PowerShellForGitHub'
    }

    $AccessToken = Get-AccessToken -AccessToken $AccessToken
    if (-not [String]::IsNullOrEmpty($AccessToken))
    {
        $headers['Authorization'] = "token $AccessToken"
    }

    if ($Method -in $ValidBodyContainingRequestMethods)
    {
        $headers.Add("Content-Type", "application/json; charset=UTF-8")
    }

    try
    {
        Write-Log -Message $Description -Level Verbose
        Write-Log -Message "Accessing [$Method] $url [Timeout = $(Get-GitHubConfiguration -Name WebRequestTimeoutSec))]" -Level Verbose

        $NoStatus = Resolve-ParameterWithDefaultConfigurationValue -Name NoStatus -ConfigValueName DefaultNoStatus
        if ($NoStatus)
        {
            if ($PSCmdlet.ShouldProcess($url, "Invoke-WebRequest"))
            {
                $params = @{}
                $params.Add("Uri", $url)
                $params.Add("Method", $Method)
                $params.Add("Headers", $headers)
                $params.Add("UseDefaultCredentials", $true)
                $params.Add("UseBasicParsing", $true)
                $params.Add("TimeoutSec", (Get-GitHubConfiguration -Name WebRequestTimeoutSec))

                if ($Method -in $ValidBodyContainingRequestMethods -and (-not [String]::IsNullOrEmpty($Body)))
                {
                    $bodyAsBytes = [System.Text.Encoding]::UTF8.GetBytes($Body)
                    $params.Add("Body", $bodyAsBytes)
                    Write-Log -Message "Request includes a body." -Level Verbose
                    if (Get-GitHubConfiguration -Name LogRequestBody)
                    {
                        Write-Log -Message $Body -Level Verbose
                    }
                }

                [Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12
                $result = Invoke-WebRequest @params
                if ($Method -eq 'Delete')
                {
                    Write-Log -Message "Successfully removed." -Level Verbose
                }
            }
        }
        else
        {
            $jobName = "Invoke-GHRestMethod-" + (Get-Date).ToFileTime().ToString()

            if ($PSCmdlet.ShouldProcess($jobName, "Start-Job"))
            {
                [scriptblock]$scriptBlock = {
                    param($Url, $Method, $Headers, $Body, $ValidBodyContainingRequestMethods, $TimeoutSec, $LogRequestBody, $ScriptRootPath)

                    # We need to "dot invoke" Helpers.ps1 and GitHubConfiguration.ps1 within
                    # the context of this script block since we're running in a different
                    # PowerShell process and need access to Get-HttpWebResponseContent and
                    # config values referenced within Write-Log.
                    . (Join-Path -Path $ScriptRootPath -ChildPath 'Helpers.ps1')
                    . (Join-Path -Path $ScriptRootPath -ChildPath 'GitHubConfiguration.ps1')

                    $params = @{}
                    $params.Add("Uri", $Url)
                    $params.Add("Method", $Method)
                    $params.Add("Headers", $Headers)
                    $params.Add("UseDefaultCredentials", $true)
                    $params.Add("UseBasicParsing", $true)
                    $params.Add("TimeoutSec", $TimeoutSec)

                    if ($Method -in $ValidBodyContainingRequestMethods -and (-not [String]::IsNullOrEmpty($Body)))
                    {
                        $bodyAsBytes = [System.Text.Encoding]::UTF8.GetBytes($Body)
                        $params.Add("Body", $bodyAsBytes)
                        Write-Log -Message "Request includes a body." -Level Verbose
                        if ($LogRequestBody)
                        {
                            Write-Log -Message $Body -Level Verbose
                        }
                    }

                    try
                    {
                        [Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12
                        Invoke-WebRequest @params
                    }
                    catch [System.Net.WebException]
                    {
                        # We need to access certain headers in the exception handling,
                        # but the actual *values* of the headers of a WebException don't get serialized
                        # when the RemoteException wraps it.  To work around that, we'll extract the
                        # information that we actually care about *now*, and then we'll throw our own exception
                        # that is just a JSON object with the data that we'll later extract for processing in
                        # the main catch.
                        $ex = @{}
                        $ex.Message = $_.Exception.Message
                        $ex.StatusCode = $_.Exception.Response.StatusCode
                        $ex.StatusDescription = $_.Exception.Response.StatusDescription
                        $ex.InnerMessage = $_.ErrorDetails.Message
                        try
                        {
                            $ex.RawContent = Get-HttpWebResponseContent -WebResponse $_.Exception.Response
                        }
                        catch
                        {
                            Write-Log -Message "Unable to retrieve the raw HTTP Web Response:" -Exception $_ -Level Warning
                        }

                        throw (ConvertTo-Json -InputObject $ex -Depth 20)
                    }
                }

                $null = Start-Job -Name $jobName -ScriptBlock $scriptBlock -Arg @(
                    $url,
                    $Method,
                    $headers,
                    $Body,
                    $ValidBodyContainingRequestMethods,
                    (Get-GitHubConfiguration -Name WebRequestTimeoutSec),
                    (Get-GitHubConfiguration -Name LogRequestBody),
                    $PSScriptRoot)

                if ($PSCmdlet.ShouldProcess($jobName, "Wait-JobWithAnimation"))
                {
                    Wait-JobWithAnimation -Name $jobName -Description $Description
                }

                if ($PSCmdlet.ShouldProcess($jobName, "Receive-Job"))
                {
                    $result = Receive-Job $jobName -AutoRemoveJob -Wait -ErrorAction SilentlyContinue -ErrorVariable remoteErrors
                }
            }

            if ($remoteErrors.Count -gt 0)
            {
                throw $remoteErrors[0].Exception
            }

            if ($Method -eq 'Delete')
            {
                Write-Log -Message "Successfully removed." -Level Verbose
            }
        }

        # Record the telemetry for this event.
        $stopwatch.Stop()
        if (-not [String]::IsNullOrEmpty($TelemetryEventName))
        {
            $telemetryMetrics = @{ 'Duration' = $stopwatch.Elapsed.TotalSeconds }
            Set-TelemetryEvent -EventName $TelemetryEventName -Properties $localTelemetryProperties -Metrics $telemetryMetrics
        }

        $finalResult = $result.Content
        try
        {
            $finalResult = $finalResult | ConvertFrom-Json
        }
        catch [ArgumentException]
        {
            # The content must not be JSON (which is a legitimate situation).  We'll return the raw content result instead.
            # We do this unnecessary assignment to avoid PSScriptAnalyzer's PSAvoidUsingEmptyCatchBlock.
            $finalResult = $finalResult
        }

        if (-not (Get-GitHubConfiguration -Name DisableSmarterObjects))
        {
            $finalResult = ConvertTo-SmarterObject -InputObject $finalResult
        }

        $links = $result.Headers['Link'] -split ','
        $nextLink = $null
        foreach ($link in $links)
        {
            if ($link -match '<(.*)>; rel="next"')
            {
                $nextLink = $matches[1]
            }
        }

        $resultNotReadyStatusCode = 202
        if ($result.StatusCode -eq $resultNotReadyStatusCode)
        {
            $retryDelaySeconds = Get-GitHubConfiguration -Name RetryDelaySeconds

            if ($Method -ne 'Get')
            {
                # We only want to do our retry logic for GET requests...
                # We don't want to repeat PUT/PATCH/POST/DELETE.
                Write-Log -Message "The server has indicated that the result is not yet ready (received status code of [$($result.StatusCode)])." -Level Warning
            }
            elseif ($retryDelaySeconds -le 0)
            {
                Write-Log -Message "The server has indicated that the result is not yet ready (received status code of [$($result.StatusCode)]), however the module is currently configured to not retry in this scenario (RetryDelaySeconds is set to 0).  Please try this command again later." -Level Warning
            }
            else
            {
                Write-Log -Message "The server has indicated that the result is not yet ready (received status code of [$($result.StatusCode)]).  Will retry in [$retryDelaySeconds] seconds." -Level Warning
                Start-Sleep -Seconds ($retryDelaySeconds)
                return (Invoke-GHRestMethod @PSBoundParameters)
            }
        }

        if ($ExtendedResult)
        {
            $finalResultEx = @{
                'result' = $finalResult
                'statusCode' = $result.StatusCode
                'requestId' = $result.Headers['X-GitHub-Request-Id']
                'nextLink' = $nextLink
                'link' = $result.Headers['Link']
                'lastModified' = $result.Headers['Last-Modified']
                'ifNoneMatch' = $result.Headers['If-None-Match']
                'ifModifiedSince' = $result.Headers['If-Modified-Since']
                'eTag' = $result.Headers['ETag']
                'rateLimit' = $result.Headers['X-RateLimit-Limit']
                'rateLimitRemaining' = $result.Headers['X-RateLimit-Remaining']
                'rateLimitReset' = $result.Headers['X-RateLimit-Reset']
            }

            return ([PSCustomObject] $finalResultEx)
        }
        else
        {
            return $finalResult
        }
    }
    catch
    {
        # We only know how to handle WebExceptions, which will either come in "pure" when running with -NoStatus,
        # or will come in as a RemoteException when running normally (since it's coming from the asynchronous Job).
        $ex = $null
        $message = $null
        $statusCode = $null
        $statusDescription = $null
        $requestId = $null
        $innerMessage = $null
        $rawContent = $null

        if ($_.Exception -is [System.Net.WebException])
        {
            $ex = $_.Exception
            $message = $_.Exception.Message
            $statusCode = $ex.Response.StatusCode.value__ # Note that value__ is not a typo.
            $statusDescription = $ex.Response.StatusDescription
            $innerMessage = $_.ErrorDetails.Message
            try
            {
                $rawContent = Get-HttpWebResponseContent -WebResponse $ex.Response
            }
            catch
            {
                Write-Log -Message "Unable to retrieve the raw HTTP Web Response:" -Exception $_ -Level Warning
            }

            if ($ex.Response.Headers.Count -gt 0)
            {
                $requestId = $ex.Response.Headers['X-GitHub-Request-Id']
            }
        }
        elseif (($_.Exception -is [System.Management.Automation.RemoteException]) -and
            ($_.Exception.SerializedRemoteException.PSObject.TypeNames[0] -eq 'Deserialized.System.Management.Automation.RuntimeException'))
        {
            $ex = $_.Exception
            try
            {
                $deserialized = $ex.Message | ConvertFrom-Json
                $message = $deserialized.Message
                $statusCode = $deserialized.StatusCode
                $statusDescription = $deserialized.StatusDescription
                $innerMessage = $deserialized.InnerMessage
                $requestId = $deserialized['X-GitHub-Request-Id']
                $rawContent = $deserialized.RawContent
            }
            catch [System.ArgumentException]
            {
                # Will be thrown if $ex.Message isn't JSON content
                Write-Log -Exception $_ -Level Error
                Set-TelemetryException -Exception $ex -ErrorBucket $errorBucket -Properties $localTelemetryProperties
                throw
            }
        }
        else
        {
            Write-Log -Exception $_ -Level Error
            Set-TelemetryException -Exception $_.Exception -ErrorBucket $errorBucket -Properties $localTelemetryProperties
            throw
        }

        $output = @()
        $output += $message

        if (-not [string]::IsNullOrEmpty($statusCode))
        {
            $output += "$statusCode | $($statusDescription.Trim())"
        }

        if (-not [string]::IsNullOrEmpty($innerMessage))
        {
            try
            {
                $innerMessageJson = ($innerMessage | ConvertFrom-Json)
                if ($innerMessageJson -is [String])
                {
                    $output += $innerMessageJson.Trim()
                }
                elseif (-not [String]::IsNullOrWhiteSpace($innerMessageJson.message))
                {
                    $output += "$($innerMessageJson.message.Trim()) | $($innerMessageJson.documentation_url.Trim())"
                    if ($innerMessageJson.details)
                    {
                        $output += "$($innerMessageJson.details | Format-Table | Out-String)"
                    }
                }
                else
                {
                    # In this case, it's probably not a normal message from the API
                    $output += ($innerMessageJson | Out-String)
                }
            }
            catch [System.ArgumentException]
            {
                # Will be thrown if $innerMessage isn't JSON content
                $output += $innerMessage.Trim()
            }
        }

        # It's possible that the API returned JSON content in its error response.
        if (-not [String]::IsNullOrWhiteSpace($rawContent))
        {
            $output += $rawContent
        }

        if ($statusCode -eq 404)
        {
            $output += "This typically happens when the current user isn't properly authenticated.  You may need an Access Token with additional scopes checked."
        }

        if (-not [String]::IsNullOrEmpty($requestId))
        {
            $localTelemetryProperties['RequestId'] = $requestId
            $message = 'RequestId: ' + $requestId
            $output += $message
            Write-Log -Message $message -Level Verbose
        }

        $newLineOutput = ($output -join [Environment]::NewLine)
        Write-Log -Message $newLineOutput -Level Error
        Set-TelemetryException -Exception $ex -ErrorBucket $errorBucket -Properties $localTelemetryProperties
        throw $newLineOutput
    }
}

function Invoke-GHRestMethodMultipleResult
{
<#
    .SYNOPSIS
        A special-case wrapper around Invoke-GHRestMethod that understands GET URI's
        which support the 'top' and 'max' parameters.

    .DESCRIPTION
        A special-case wrapper around Invoke-GHRestMethod that understands GET URI's
        which support the 'top' and 'max' parameters.

        The Git repo for this module can be found here: http://aka.ms/PowerShellForGitHub

    .PARAMETER UriFragment
        The unique, tail-end, of the REST URI that indicates what Store REST action will
        be peformed.  This should *not* include the 'top' and 'max' parameters.  These
        will be automatically added as needed.

    .PARAMETER Description
        A friendly description of the operation being performed for logging and console
        display purposes.

    .PARAMETER AcceptHeader
        Specify the media type in the Accept header.  Different types of commands may require
        different media types.

    .PARAMETER AccessToken
        If provided, this will be used as the AccessToken for authentication with the
        REST Api as opposed to requesting a new one.

    .PARAMETER TelemetryEventName
        If provided, the successful execution of this REST command will be logged to telemetry
        using this event name.

    .PARAMETER TelemetryProperties
        If provided, the successful execution of this REST command will be logged to telemetry
        with these additional properties.  This will be silently ignored if TelemetryEventName
        is not provided as well.

    .PARAMETER TelemetryExceptionBucket
        If provided, any exception that occurs will be logged to telemetry using this bucket.
        It's possible that users will wish to log exceptions but not success (by providing
        TelemetryEventName) if this is being executed as part of a larger scenario.  If this
        isn't provided, but TelemetryEventName *is* provided, then TelemetryEventName will be
        used as the exception bucket value in the event of an exception.  If neither is specified,
        no bucket value will be used.

    .PARAMETER SinglePage
        By default, this function will automtically call any follow-up "nextLinks" provided by
        the return value in order to retrieve the entire result set.  If this switch is provided,
        only the first "page" of results will be retrieved, and the "nextLink" links will not be
        followed.
        WARNING: This might take a while depending on how many results there are.

    .PARAMETER NoStatus
        If this switch is specified, long-running commands will run on the main thread
        with no commandline status update.  When not specified, those commands run in
        the background, enabling the command prompt to provide status information.

    .OUTPUTS
        [PSCutomObject[]] - The result of the REST operation, in whatever form it comes in.

    .EXAMPLE
        Invoke-GHRestMethodMultipleResult -UriFragment "repos/PowerShell/PowerShellForGitHub/issues?state=all" -Description "Get all issues"

        Gets the first set of issues associated with this project,
        with the console window showing progress while awaiting the response
        from the REST request.

    .EXAMPLE
        Invoke-GHRestMethodMultipleResult -UriFragment "repos/PowerShell/PowerShellForGitHub/issues?state=all" -Description "Get all issues" -NoStatus

        Gets the first set of issues associated with this project,
        but the request happens in the foreground and there is no additional status
        shown to the user until a response is returned from the REST request.
#>
    [CmdletBinding(SupportsShouldProcess)]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSShouldProcess", "", Justification="Methods called within here make use of PSShouldProcess, and the switch is passed on to them inherently.")]
    [OutputType([Object[]])]
    param(
        [Parameter(Mandatory)]
        [string] $UriFragment,

        [Parameter(Mandatory)]
        [string] $Description,

        [string] $AcceptHeader = $script:defaultAcceptHeader,

        [string] $AccessToken,

        [string] $TelemetryEventName = $null,

        [hashtable] $TelemetryProperties = @{},

        [string] $TelemetryExceptionBucket = $null,

        [switch] $SinglePage,

        [switch] $NoStatus
    )

    $AccessToken = Get-AccessToken -AccessToken $AccessToken

    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    $errorBucket = $TelemetryExceptionBucket
    if ([String]::IsNullOrEmpty($errorBucket))
    {
        $errorBucket = $TelemetryEventName
    }

    $finalResult = @()

    $currentDescription = $Description
    $nextLink = $UriFragment

    try
    {
        do
        {
            $params = @{
                'UriFragment' = $nextLink
                'Method' = 'Get'
                'Description' = $currentDescription
                'AcceptHeader' = $AcceptHeader
                'ExtendedResult' = $true
                'AccessToken' = $AccessToken
                'TelemetryProperties' = $telemetryProperties
                'TelemetryExceptionBucket' = $errorBucket
                'NoStatus' = (Resolve-ParameterWithDefaultConfigurationValue -Name NoStatus -ConfigValueName DefaultNoStatus)
            }

            $result = Invoke-GHRestMethod @params
            $finalResult += $result.result
            $nextLink = $result.nextLink
            $currentDescription = "$Description (getting additional results)"
        }
        until ($SinglePage -or ([String]::IsNullOrWhiteSpace($nextLink)))

        # Record the telemetry for this event.
        $stopwatch.Stop()
        if (-not [String]::IsNullOrEmpty($TelemetryEventName))
        {
            $telemetryMetrics = @{ 'Duration' = $stopwatch.Elapsed.TotalSeconds }
            Set-TelemetryEvent -EventName $TelemetryEventName -Properties $TelemetryProperties -Metrics $telemetryMetrics
        }

        # Ensure we're always returning our results as an array, even if there is a single result.
        return @($finalResult)
    }
    catch
    {
        throw
    }
}

function Split-GitHubUri
{
<#
    .SYNOPSIS
        Extracts the relevant elements of a GitHub repository Uri and returns the requested element.

    .DESCRIPTION
        Extracts the relevant elements of a GitHub repository Uri and returns the requested element.

        Currently supports retrieving the OwnerName and the RepositoryName, when avaialable.

        The Git repo for this module can be found here: http://aka.ms/PowerShellForGitHub

    .PARAMETER Uri
        The GitHub repository Uri whose components should be returned.

    .PARAMETER OwnerName
        Returns the Owner Name from the Uri if it can be identified.

    .PARAMETER RepositoryName
        Returns the Repository Name from the Uri if it can be identified.

    .OUTPUTS
        [PSCutomObject] - The OwnerName and RepositoryName elements from the provided URL

    .EXAMPLE
        Split-GitHubUri -Uri 'https://github.com/PowerShell/PowerShellForGitHub'

        PowerShellForGitHub

    .EXAMPLE
        Split-GitHubUri -Uri 'https://github.com/PowerShell/PowerShellForGitHub' -RepositoryName

        PowerShellForGitHub

    .EXAMPLE
        Split-GitHubUri -Uri 'https://github.com/PowerShell/PowerShellForGitHub' -OwnerName

        PowerShell
#>
    [CmdletBinding(DefaultParametersetName='RepositoryName')]
    param
    (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string] $Uri,

        [Parameter(ParameterSetName='OwnerName')]
        [switch] $OwnerName,

        [Parameter(ParameterSetName='RepositoryName')]
        [switch] $RepositoryName
    )

    $components = @{
        ownerName = [String]::Empty
        repositoryName = [String]::Empty
    }

    $hostName = $(Get-GitHubConfiguration -Name "ApiHostName")

    if (($Uri -match "^https?://(?:www.)?$hostName/([^/]+)/?([^/]+)?(?:/.*)?$") -or
        ($Uri -match "^https?://api.$hostName/repos/([^/]+)/?([^/]+)?(?:/.*)?$"))
    {
        $components.ownerName = $Matches[1]
        if ($Matches.Count -gt 2)
        {
            $components.repositoryName = $Matches[2]
        }
    }

    if ($OwnerName)
    {
        return $components.ownerName
    }
    elseif ($RepositoryName -or ($PSCmdlet.ParameterSetName -eq 'RepositoryName'))
    {
        return $components.repositoryName
    }
}

function Resolve-RepositoryElements
{
<#
    .SYNOPSIS
        Determines the OwnerName and RepositoryName from the possible parameter values.

    .DESCRIPTION
        Determines the OwnerName and RepositoryName from the possible parameter values.

        The Git repo for this module can be found here: http://aka.ms/PowerShellForGitHub

    .PARAMETER BoundParameters
        The inbound parameters from the calling method.
        This is expecting values that may include 'Uri', 'OwnerName' and 'RepositoryName'
        No need to explicitly provide this if you're using the PSBoundParameters from the
        function that is calling this directly.

    .PARAMETER DisableValidation
        By default, this function ensures that it returns with all elements provided,
        otherwise an exception is thrown.  If this is specified, that validation will
        not occur, and it's possible to receive a result where one or more elements
        have no value.

    .OUTPUTS
        [PSCutomObject] - The OwnerName and RepositoryName elements to be used
#>
    [CmdletBinding(SupportsShouldProcess)]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSShouldProcess", "", Justification="Methods called within here make use of PSShouldProcess, and the switch is passed on to them inherently.")]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseSingularNouns", "", Justification="This was the most accurate name that I could come up with.  Internal only anyway.")]
    param
    (
        $BoundParameters = (Get-Variable -Name PSBoundParameters -Scope 1 -ValueOnly),

        [switch] $DisableValidation
    )

    $validate = -not $DisableValidation
    $elements = @{}

    if ($BoundParameters.ContainsKey('Uri') -and
       ($BoundParameters.ContainsKey('OwnerName') -or $BoundParameters.ContainsKey('RepositoryName')))
    {
        $message = "Cannot specify a Uri AND individual OwnerName/RepositoryName.  Please choose one or the other."
        Write-Log -Message $message -Level Error
        throw $message
    }

    if ($BoundParameters.ContainsKey('Uri'))
    {
        $elements.ownerName = Split-GitHubUri -Uri $BoundParameters.Uri -OwnerName
        if ($validate -and [String]::IsNullOrEmpty($elements.ownerName))
        {
            $message = "Provided Uri does not contain enough information: Owner Name."
            Write-Log -Message $message -Level Error
            throw $message
        }

        $elements.repositoryName = Split-GitHubUri -Uri $BoundParameters.Uri -RepositoryName
        if ($validate -and [String]::IsNullOrEmpty($elements.repositoryName))
        {
            $message = "Provided Uri does not contain enough information: Repository Name."
            Write-Log -Message $message -Level Error
            throw $message
        }
    }
    else
    {
        $elements.ownerName = Resolve-ParameterWithDefaultConfigurationValue -BoundParameters $BoundParameters -Name OwnerName -ConfigValueName DefaultOwnerName -NonEmptyStringRequired:$validate
        $elements.repositoryName = Resolve-ParameterWithDefaultConfigurationValue -BoundParameters $BoundParameters -Name RepositoryName -ConfigValueName DefaultRepositoryName -NonEmptyStringRequired:$validate
    }

    return ([PSCustomObject] $elements)
}

# The list of property names across all of GitHub API v3 that are known to store dates as strings.
$script:datePropertyNames = @(
    'closed_at',
    'committed_at',
    'completed_at',
    'created_at',
    'date',
    'due_on',
    'last_edited_at',
    'last_read_at',
    'merged_at',
    'published_at',
    'pushed_at',
    'starred_at',
    'started_at',
    'submitted_at',
    'timestamp',
    'updated_at'
)

filter ConvertTo-SmarterObject
{
<#
    .SYNOPSIS
        Updates the properties of the input object to be object themselves when the conversion
        is possible.

    .DESCRIPTION
        Updates the properties of the input object to be object themselves when the conversion
        is possible.

        At present, this only attempts to convert properties known to store dates as strings
        into storing them as DateTime objects instead.

    .PARAMETER InputObject
        The object to update
#>
    [CmdletBinding()]
    param(
        [Parameter(
            Mandatory,
            ValueFromPipeline,
            ValueFromPipelineByPropertyName)]
        [AllowNull()]
        [object] $InputObject
    )

    if ($null -eq $InputObject)
    {
        return $null
    }

    if ($InputObject -is [System.Collections.IList])
    {
        $InputObject |
            ConvertTo-SmarterObject |
            Write-Output
    }
    elseif ($InputObject -is [PSCustomObject])
    {
        $clone = DeepCopy-Object -InputObject $InputObject
        $properties = $clone.PSObject.Properties | Where-Object { $null -ne $_.Value }
        foreach ($property in $properties)
        {
            # Convert known date properties from dates to real DateTime objects
            if (($property.Name -in $script:datePropertyNames) -and
                ($property.Value -is [String]) -and
                (-not [String]::IsNullOrWhiteSpace($property.Value)))
            {
                try
                {
                    $property.Value = Get-Date -Date $property.Value
                }
                catch
                {
                    Write-Log -Message "Unable to convert $($property.Name) value of $($property.Value) to a [DateTime] object.  Leaving as-is." -Level Verbose
                }
            }

            if ($property.Value -is [System.Collections.IList])
            {
                $property.Value = @(ConvertTo-SmarterObject -InputObject $property.Value)
            }
            elseif ($property.Value -is [PSCustomObject])
            {
                $property.Value = ConvertTo-SmarterObject -InputObject $property.Value
            }
        }

        Write-Output -InputObject $clone
    }
    else
    {
        Write-Output -InputObject $InputObject
    }
}

function Get-MediaAcceptHeader
{
<#
    .DESCRIPTION
        Returns a formatted AcceptHeader based on the requested MediaType

        The Git repo for this module can be found here: http://aka.ms/PowerShellForGitHub

    .PARAMETER MediaType
        The format in which the API will return the body of the comment or issue.

        Raw - Return the raw markdown body. Response will include body. This is the default if you do not pass any specific media type.
        Text - Return a text only representation of the markdown body. Response will include body_text.
        Html - Return HTML rendered from the body's markdown. Response will include body_html.
        Full - Return raw, text and HTML representations. Response will include body, body_text, and body_html.
        Object - Return a json object representation a file or folder.

    .PARAMETER AsJson
        If this switch is specified as +json value is appended to the MediaType header.

    .PARAMETER AcceptHeader
        The accept header that should be included with the MediaType accept header.

    .EXAMPLE
        Get-MediaAcceptHeader -MediaType Raw

        Returns a formatted AcceptHeader for v3 of the response object
#>
    [CmdletBinding()]
    param(
        [ValidateSet('Raw', 'Text', 'Html', 'Full', 'Object')]
        [string] $MediaType = 'Raw',

        [switch] $AsJson,

        [string] $AcceptHeader
    )

    $resultHeaders = "application/vnd.github.$mediaTypeVersion.$($MediaType.ToLower())"
    if ($AsJson -eq $true)
    {
        $resultHeaders = $resultHeaders + "+json"
    }

    if ($AcceptHeader)
    {
        $resultHeaders = "$AcceptHeader,$resultHeaders"
    }

    return $resultHeaders
}