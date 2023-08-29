# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

@{
    defaultAcceptHeader = 'application/vnd.github.v3+json'
    mediaTypeVersion = 'v3'
    baptisteAcceptHeader = 'application/vnd.github.baptiste-preview+json'
    dorianAcceptHeader = 'application/vnd.github.dorian-preview+json'
    hagarAcceptHeader = 'application/vnd.github.hagar-preview+json'
    hellcatAcceptHeader = 'application/vnd.github.hellcat-preview+json'
    inertiaAcceptHeader = 'application/vnd.github.inertia-preview+json'
    londonAcceptHeader = 'application/vnd.github.london-preview+json'
    lukeCageAcceptHeader = 'application/vnd.github.luke-cage-preview+json'
    machineManAcceptHeader = 'application/vnd.github.machine-man-preview'
    mercyAcceptHeader = 'application/vnd.github.mercy-preview+json'
    mockingbirdAcceptHeader = 'application/vnd.github.mockingbird-preview'
    nebulaAcceptHeader = 'application/vnd.github.nebula-preview+json'
    repositoryAcceptHeader = 'application/vnd.github.v3.repository+json'
    sailorVAcceptHeader = 'application/vnd.github.sailor-v-preview+json'
    scarletWitchAcceptHeader = 'application/vnd.github.scarlet-witch-preview+json'
    squirrelGirlAcceptHeader = 'application/vnd.github.squirrel-girl-preview'
    starfoxAcceptHeader = 'application/vnd.github.starfox-preview+json'
    symmetraAcceptHeader = 'application/vnd.github.symmetra-preview+json'
 }.GetEnumerator() | ForEach-Object {
     Set-Variable -Scope Script -Option ReadOnly -Name $_.Key -Value $_.Value
 }

Set-Variable -Scope Script -Option ReadOnly -Name ValidBodyContainingRequestMethods -Value ('Post', 'Patch', 'Put', 'Delete')

function Invoke-GHRestMethod
{
<#
    .SYNOPSIS
        A wrapper around Invoke-WebRequest that understands the GitHub API.

    .DESCRIPTION
        A very heavy wrapper around Invoke-WebRequest that understands the GitHub API and
        how to perform its operation with and without console status updates.  It also
        understands how to parse and handle errors from the REST calls.

        The Git repo for this module can be found here: http://aka.ms/PowerShellForGitHub

    .PARAMETER UriFragment
        The unique, tail-end, of the REST URI that indicates what GitHub REST action will
        be performed.  This should not start with a leading "/".

    .PARAMETER Method
        The type of REST method being performed.  This only supports a reduced set of the
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

    .PARAMETER InFile
        Gets the content of the web request from the specified file.  Only valid for POST requests.

    .PARAMETER ContentType
        Specifies the value for the MIME Content-Type header of the request.  This will usually
        be configured correctly automatically.  You should only specify this under advanced
        situations (like if the extension of InFile is of a type unknown to this module).

    .PARAMETER AdditionalHeader
        Allows the caller to specify any number of additional headers that should be added to
        the request.

    .PARAMETER ExtendedResult
        If specified, the result will be a PSObject that contains the normal result, along with
        the response code and other relevant header detail content.

    .PARAMETER Save
        If specified, this will save the result to a temporary file and return the FileInfo of that
        temporary file.

    .PARAMETER ApiVersion
         Indicates the version of this API that should be used. Format is: 'yyyy-MM-dd'.

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

    .OUTPUTS
        [PSCustomObject] - The result of the REST operation, in whatever form it comes in.
        [FileInfo] - The temporary file created for the downloaded file if -Save was specified.

    .EXAMPLE
        Invoke-GHRestMethod -UriFragment "users/octocat" -Method Get -Description "Get information on the octocat user"

        Gets the user information for Octocat.

    .EXAMPLE
        Invoke-GHRestMethod -UriFragment "user" -Method Get -Description "Get current user"

        Gets information about the current authenticated user.

    .NOTES
        This wraps Invoke-WebRequest as opposed to Invoke-RestMethod because we want access
        to the headers that are returned in the response, and Invoke-RestMethod drops those headers.
#>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string] $UriFragment,

        [Parameter(Mandatory)]
        [ValidateSet('Delete', 'Get', 'Post', 'Patch', 'Put')]
        [string] $Method,

        [string] $Description,

        [string] $Body = $null,

        [string] $AcceptHeader = $script:defaultAcceptHeader,

        [ValidateNotNullOrEmpty()]
        [string] $InFile,

        [string] $ContentType = $script:defaultJsonBodyContentType,

        [HashTable] $AdditionalHeader = @{},

        [switch] $ExtendedResult,

        [switch] $Save,

        [ValidatePattern('^\d{4}-\d{2}-\d{2}$')]
        [string] $ApiVersion = "2022-11-28",

        [string] $AccessToken,

        [string] $TelemetryEventName = $null,

        [hashtable] $TelemetryProperties = @{},

        [string] $TelemetryExceptionBucket = $null
    )

    Invoke-UpdateCheck

    # Minor error checking around $InFile
    if ($PSBoundParameters.ContainsKey('InFile') -and ($Method -ne 'Post'))
    {
        $message = '-InFile may only be specified with Post requests.'
        Write-Log -Message $message -Level Error
        throw $message
    }

    if ($PSBoundParameters.ContainsKey('InFile') -and (-not [String]::IsNullOrWhiteSpace($Body)))
    {
        $message = 'Cannot specify BOTH InFile and Body'
        Write-Log -Message $message -Level Error
        throw $message
    }

    if ($PSBoundParameters.ContainsKey('InFile'))
    {
        $InFile = Resolve-UnverifiedPath -Path $InFile
        if (-not (Test-Path -Path $InFile -PathType Leaf))
        {
            $message = "Specified file [$InFile] does not exist or is inaccessible."
            Write-Log -Message $message -Level Error
            throw $message
        }
    }

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
    $localTelemetryProperties = @{}
    $TelemetryProperties.Keys | ForEach-Object { $localTelemetryProperties[$_] = $TelemetryProperties[$_] }
    $errorBucket = $TelemetryExceptionBucket
    if ([String]::IsNullOrEmpty($errorBucket))
    {
        $errorBucket = $TelemetryEventName
    }

    # Handling retries for 202
    $numRetriesAttempted = 0
    $maxiumRetriesPermitted = Get-GitHubConfiguration -Name 'MaximumRetriesWhenResultNotReady'

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
        'X-GitHub-Api-Version' = $ApiVersion
    }

    # Add any additional headers
    foreach ($header in $AdditionalHeader.Keys.GetEnumerator())
    {
        $headers.Add($header, $AdditionalHeader.$header)
    }

    $AccessToken = Get-AccessToken -AccessToken $AccessToken
    if (-not [String]::IsNullOrEmpty($AccessToken))
    {
        $headers['Authorization'] = "token $AccessToken"
    }

    if ($Method -in $ValidBodyContainingRequestMethods)
    {
        if ($PSBoundParameters.ContainsKey('InFile') -and [String]::IsNullOrWhiteSpace($ContentType))
        {
            $file = Get-Item -Path $InFile
            $localTelemetryProperties['FileExtension'] = $file.Extension

            if ($script:extensionToContentType.ContainsKey($file.Extension))
            {
                $ContentType = $script:extensionToContentType[$file.Extension]
            }
            else
            {
                $localTelemetryProperties['UnknownExtension'] = $file.Extension
                $ContentType = $script:defaultInFileContentType
            }
        }

        $headers.Add("Content-Type", $ContentType)
    }

    $originalSecurityProtocol = [Net.ServicePointManager]::SecurityProtocol

    # When $Save is in use, we need to remember what file we're saving the result to.
    $outFile = [String]::Empty
    if ($Save)
    {
        $outFile = New-TemporaryFile
    }

    try
    {
        while ($true) # infinite loop for handling the 202 retry, but we'll either exit via a return, or throw an exception if retry limit exceeded.
        {
            Write-Log -Message $Description -Level Verbose
            Write-Log -Message "Accessing [$Method] $url [Timeout = $(Get-GitHubConfiguration -Name WebRequestTimeoutSec))]" -Level Verbose

            $result = $null
            $params = @{}
            $params.Add("Uri", $url)
            $params.Add("Method", $Method)
            $params.Add("Headers", $headers)
            $params.Add("UseDefaultCredentials", $true)
            $params.Add("UseBasicParsing", $true)
            $params.Add("TimeoutSec", (Get-GitHubConfiguration -Name WebRequestTimeoutSec))
            if ($PSBoundParameters.ContainsKey('InFile')) { $params.Add('InFile', $InFile) }
            if (-not [String]::IsNullOrWhiteSpace($outFile)) { $params.Add('OutFile', $outFile) }

            if (($Method -in $ValidBodyContainingRequestMethods) -and (-not [String]::IsNullOrEmpty($Body)))
            {
                $bodyAsBytes = [System.Text.Encoding]::UTF8.GetBytes($Body)
                $params.Add("Body", $bodyAsBytes)
                Write-Log -Message "Request includes a body." -Level Verbose
                if (Get-GitHubConfiguration -Name LogRequestBody)
                {
                    Write-Log -Message $Body -Level Verbose
                }
            }

            # Disable Progress Bar in function scope during Invoke-WebRequest
            $ProgressPreference = 'SilentlyContinue'

            [Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12

            $result = Invoke-WebRequest @params

            if ($Method -eq 'Delete')
            {
                Write-Log -Message "Successfully removed." -Level Verbose
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
                if ($Save)
                {
                    $finalResult = Get-Item -Path $outFile
                }
                else
                {
                    $finalResult = $finalResult | ConvertFrom-Json
                }
            }
            catch [InvalidOperationException]
            {
                # In some cases, the returned data might have two different keys of the same characters
                # but different casing (this can happen with gists with two files named 'a.txt' and 'A.txt').
                # PowerShell 6 introduced the -AsHashtable switch to work around this issue, but this
                # module wants to be compatible down to PowerShell 4, so we're unable to use that feature.
                Write-Log -Message 'The returned object likely contains keys that differ only in casing.  Unable to convert to an object.  Returning the raw JSON as a fallback.' -Level Warning
                $finalResult = $finalResult
            }
            catch [ArgumentException]
            {
                # The content must not be JSON (which is a legitimate situation).
                # We'll return the raw content result instead.
                # We do this unnecessary assignment to avoid PSScriptAnalyzer's PSAvoidUsingEmptyCatchBlock.
                $finalResult = $finalResult
            }

            if ((-not $Save) -and (-not (Get-GitHubConfiguration -Name DisableSmarterObjects)))
            {
                # In the case of getting raw content from the repo, we'll end up with a large object/byte
                # array which isn't convertible to a smarter object, but by _trying_ we'll end up wasting
                # a lot of time.  Let's optimize here by not bothering to send in something that we
                # know is definitely not convertible ([int32] on PS5, [long] on PS7).
                if (($finalResult -isnot [Object[]]) -or
                    (($finalResult.Count -gt 0) -and
                    ($finalResult[0] -isnot [int]) -and
                    ($finalResult[0] -isnot [long])))
                {
                    $finalResult = ConvertTo-SmarterObject -InputObject $finalResult
                }
            }

            if ($result.Headers.Count -gt 0)
            {
                $links = $result.Headers['Link'] -split ','
                $nextLink = $null
                $nextPageNumber = 1
                $numPages = 1
                $since = 0
                foreach ($link in $links)
                {
                    if ($link -match '<(.*page=(\d+)[^\d]*)>; rel="next"')
                    {
                        $nextLink = $Matches[1]
                        $nextPageNumber = [int]$Matches[2]
                    }
                    elseif ($link -match '<(.*since=(\d+)[^\d]*)>; rel="next"')
                    {
                        # Special case scenario for the users endpoint.
                        $nextLink = $Matches[1]
                        $since = [int]$Matches[2]
                        $numPages = 0 # Signifies an unknown number of pages.
                    }
                    elseif ($link -match '<.*page=(\d+)[^\d]+rel="last"')
                    {
                        $numPages = [int]$Matches[1]
                    }
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
                elseif ($numRetriesAttempted -lt $maxiumRetriesPermitted)
                {
                    $numRetriesAttempted++
                    $localTelemetryProperties['RetryAttempt'] = $numRetriesAttempted
                    Write-Log -Message "The server has indicated that the result is not yet ready (received status code of [$($result.StatusCode)]).  Will retry in [$retryDelaySeconds] seconds. $($maxiumRetriesPermitted - $numRetriesAttempted) retries remaining." -Level Warning
                    Start-Sleep -Seconds ($retryDelaySeconds)
                    continue # loop back and try this again
                }
                else
                {
                    $message = "Request still not ready after $numRetriesAttempted retries.  Retry limit has been reached as per configuration value 'MaximumRetriesWhenResultNotReady'"
                    Write-Log -Message $message -Level Error
                    throw $message
                }
            }

            # Allow for a delay after a command that may result in a state change in order to
            # increase the reliability of the UT's which attempt multiple successive state change
            # on the same object.
            $stateChangeDelaySeconds = $(Get-GitHubConfiguration -Name 'StateChangeDelaySeconds')
            $stateChangeMethods = @('Delete', 'Post', 'Patch', 'Put')
            if (($stateChangeDelaySeconds -gt 0) -and ($Method -in $stateChangeMethods))
            {
                Start-Sleep -Seconds $stateChangeDelaySeconds
            }

            if ($ExtendedResult)
            {
                $finalResultEx = @{
                    'result' = $finalResult
                    'statusCode' = $result.StatusCode
                    'requestId' = $result.Headers['X-GitHub-Request-Id']
                    'nextLink' = $nextLink
                    'nextPageNumber' = $nextPageNumber
                    'numPages' = $numPages
                    'since' = $since
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
    }
    catch
    {
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
            $explanation = @('This error will usually happen for one of the following reasons:',
                '(1) The item you are requesting truly doesn''t exist (so make sure you don''t have',
                'a typo) or ',
                '(2) The item _does_ exist, but you don''t currently have permission to access it. ',
                'If you think the item does exist and that you _should_ have access to it, then make',
                'sure that you are properly authenticated with Set-GitHubAuthentication and that',
                'your access token has the appropriate scopes checked.')
            $output += ($explanation -join ' ')
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
    finally
    {
        [Net.ServicePointManager]::SecurityProtocol = $originalSecurityProtocol
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
        The unique, tail-end, of the REST URI that indicates what GitHub REST action will
        be performed.  This should *not* include the 'top' and 'max' parameters.  These
        will be automatically added as needed.

    .PARAMETER Description
        A friendly description of the operation being performed for logging and console
        display purposes.

    .PARAMETER AcceptHeader
        Specify the media type in the Accept header.  Different types of commands may require
        different media types.

    .PARAMETER AdditionalHeader
        Allows the caller to specify any number of additional headers that should be added to
        all of the requests made.

    .PARAMETER ApiVersion
         Indicates the version of this API that should be used. Format is: 'yyyy-MM-dd'.

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
        By default, this function will automatically call any follow-up "nextLinks" provided by
        the return value in order to retrieve the entire result set.  If this switch is provided,
        only the first "page" of results will be retrieved, and the "nextLink" links will not be
        followed.
        WARNING: This might take a while depending on how many results there are.

    .OUTPUTS
        [PSCustomObject[]] - The result of the REST operation, in whatever form it comes in.

    .EXAMPLE
        Invoke-GHRestMethodMultipleResult -UriFragment "repos/PowerShell/PowerShellForGitHub/issues?state=all" -Description "Get all issues"

        Gets the first set of issues associated with this project,
        with the console window showing progress while awaiting the response
        from the REST request.
#>
    [CmdletBinding()]
    [OutputType([Object[]])]
    param(
        [Parameter(Mandatory)]
        [string] $UriFragment,

        [Parameter(Mandatory)]
        [string] $Description,

        [string] $AcceptHeader = $script:defaultAcceptHeader,

        [hashtable] $AdditionalHeader = @{},

        [ValidatePattern('^\d{4}-\d{2}-\d{2}$')]
        [string] $ApiVersion = "2022-11-28",

        [string] $AccessToken,

        [string] $TelemetryEventName = $null,

        [hashtable] $TelemetryProperties = @{},

        [string] $TelemetryExceptionBucket = $null,

        [switch] $SinglePage
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

    $multiRequestProgressThreshold = Get-GitHubConfiguration -Name 'MultiRequestProgressThreshold'
    $iteration = 0
    $progressId = $null
    try
    {
        do
        {
            $iteration++
            $params = @{
                'UriFragment' = $nextLink
                'Method' = 'Get'
                'Description' = $currentDescription
                'AcceptHeader' = $AcceptHeader
                'AdditionalHeader' = $AdditionalHeader
                'ExtendedResult' = $true
                'ApiVersion' = $ApiVersion
                'AccessToken' = $AccessToken
                'TelemetryProperties' = $telemetryProperties
                'TelemetryExceptionBucket' = $errorBucket
            }

            $result = Invoke-GHRestMethod @params
            if ($null -ne $result.result)
            {
                $finalResult += $result.result
            }

            $nextLink = $result.nextLink
            $status = [String]::Empty
            $percentComplete = 0
            if ($result.numPages -eq 0)
            {
                # numPages == 0 is a special case for when the total number of pages is simply unknown.
                # This can happen with getting all GitHub users.
                $status = "Getting additional results [page $iteration of (unknown)]"
                $percentComplete = 10 # No idea what percentage to use in this scenario
            }
            else
            {
                $status = "Getting additional results [page $($result.nextPageNumber)/$($result.numPages)])"
                $percentComplete = (($result.nextPageNumber / $result.numPages) * 100)
            }

            $currentDescription = "$Description ($status)"
            if (($multiRequestProgressThreshold -gt 0) -and
                (($result.numPages -ge $multiRequestProgressThreshold) -or ($result.numPages -eq 0)))
            {
                $progressId = 1
                $progressParams = @{
                    'Activity' = $Description
                    'Status' = $status
                    'PercentComplete' = $percentComplete
                    'Id' = $progressId
                }

                Write-Progress @progressParams
            }
        }
        until ($SinglePage -or ([String]::IsNullOrWhiteSpace($nextLink)))

        # Record the telemetry for this event.
        $stopwatch.Stop()
        if (-not [String]::IsNullOrEmpty($TelemetryEventName))
        {
            $telemetryMetrics = @{ 'Duration' = $stopwatch.Elapsed.TotalSeconds }
            Set-TelemetryEvent -EventName $TelemetryEventName -Properties $TelemetryProperties -Metrics $telemetryMetrics
        }

        return $finalResult
    }
    catch
    {
        throw
    }
    finally
    {
        # Ensure that we complete the progress bar once the command is done, regardless of outcome.
        if ($null -ne $progressId)
        {
            Write-Progress -Activity $Description -Id $progressId -Completed
        }
    }
}

filter Split-GitHubUri
{
<#
    .SYNOPSIS
        Extracts the relevant elements of a GitHub repository Uri and returns the requested element.

    .DESCRIPTION
        Extracts the relevant elements of a GitHub repository Uri and returns the requested element.

        Currently supports retrieving the OwnerName and the RepositoryName, when available.

        The Git repo for this module can be found here: http://aka.ms/PowerShellForGitHub

    .PARAMETER Uri
        The GitHub repository Uri whose components should be returned.

    .PARAMETER OwnerName
        Returns the Owner Name from the Uri if it can be identified.

    .PARAMETER RepositoryName
        Returns the Repository Name from the Uri if it can be identified.

    .INPUTS
        [String]

    .OUTPUTS
        [PSCustomObject] - The OwnerName and RepositoryName elements from the provided URL

    .EXAMPLE
        Split-GitHubUri -Uri 'https://github.com/microsoft/PowerShellForGitHub'

        PowerShellForGitHub

    .EXAMPLE
        Split-GitHubUri -Uri 'https://github.com/microsoft/PowerShellForGitHub' -RepositoryName

        PowerShellForGitHub

    .EXAMPLE
        Split-GitHubUri -Uri 'https://github.com/microsoft/PowerShellForGitHub' -OwnerName

        microsoft

    .EXAMPLE
        Split-GitHubUri -Uri 'https://github.com/microsoft/PowerShellForGitHub'

        @{'ownerName' = 'microsoft'; 'repositoryName' = 'PowerShellForGitHub'}
#>
    [CmdletBinding(DefaultParameterSetName='RepositoryName')]
    [OutputType([Hashtable])]
    param
    (
        [Parameter(
            Mandatory,
            ValueFromPipeline)]
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
    elseif ($RepositoryName)
    {
        return $components.repositoryName
    }
    else
    {
        return $components
    }
}

function Join-GitHubUri
{
<#
    .SYNOPSIS
        Combines the provided repository elements into a repository URL.

    .DESCRIPTION
        Combines the provided repository elements into a repository URL.

        The Git repo for this module can be found here: http://aka.ms/PowerShellForGitHub

    .PARAMETER OwnerName
        Owner of the repository.

    .PARAMETER RepositoryName
        Name of the repository.

    .OUTPUTS
        [String] - The repository URL.
#>
    [CmdletBinding()]
    [OutputType([String])]
    param
    (
        [Parameter(Mandatory)]
        [string] $OwnerName,

        [Parameter(Mandatory)]
        [string] $RepositoryName
    )


    $hostName = (Get-GitHubConfiguration -Name 'ApiHostName')
    return "https://$hostName/$OwnerName/$RepositoryName"
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
        [PSCustomObject] - The OwnerName and RepositoryName elements to be used
#>
    [CmdletBinding()]
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
    'last_used_at',
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

    .INPUTS
        [object]

    .OUTPUTS
        [object]
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

    if (($InputObject -is [int]) -or ($InputObject -is [long]))
    {
        # In some instances, an int/long was being seen as a [PSCustomObject].
        # This attempts to short-circuit extra work we would have done had that happened.
        Write-Output -InputObject $InputObject
    }
    elseif ($InputObject -is [System.Collections.IList])
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
                    $message = "Unable to convert $($property.Name) value of $($property.Value) to a [DateTime] object.  Leaving as-is."
                    Write-Log -Message $message -Level Verbose
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
    .SYNOPSIS
        Returns a formatted AcceptHeader based on the requested MediaType.

    .DESCRIPTION
        Returns a formatted AcceptHeader based on the requested MediaType.

        The Git repo for this module can be found here: http://aka.ms/PowerShellForGitHub

    .PARAMETER MediaType
        The format in which the API will return the body of the comment or issue.

        Raw  - Return the raw markdown body.
               Response will include body.
               This is the default if you do not pass any specific media type.
        Text - Return a text only representation of the markdown body.
               Response will include body_text.
        Html - Return HTML rendered from the body's markdown.
               Response will include body_html.
        Full - Return raw, text and HTML representations.
               Response will include body, body_text, and body_html.
        Object - Return a json object representation a file or folder.

    .PARAMETER AsJson
        If this switch is specified as +json value is appended to the MediaType header.

    .PARAMETER AcceptHeader
        The accept header that should be included with the MediaType accept header.

    .OUTPUTS
        [String]

    .EXAMPLE
        Get-MediaAcceptHeader -MediaType Raw

        Returns a formatted AcceptHeader for v3 of the response object
#>
    [CmdletBinding()]
    [OutputType([String])]
    param(
        [ValidateSet('Raw', 'Text', 'Html', 'Full', 'Object')]
        [string] $MediaType = 'Raw',

        [switch] $AsJson,

        [string] $AcceptHeader
    )

    $resultHeaders = "application/vnd.github.$mediaTypeVersion.$($MediaType.ToLower())"
    if ($AsJson)
    {
        $resultHeaders = $resultHeaders + "+json"
    }

    if (-not [String]::IsNullOrEmpty($AcceptHeader))
    {
        $resultHeaders = "$AcceptHeader,$resultHeaders"
    }

    return $resultHeaders
}

@{
    defaultJsonBodyContentType = 'application/json; charset=UTF-8'
    defaultInFileContentType = 'text/plain'

    # Compiled mostly from https://developer.mozilla.org/en-US/docs/Web/HTTP/Basics_of_HTTP/MIME_types/Common_types
    extensionToContentType = @{
        '.3gp'    = 'video/3gpp' # 3GPP audio/video container
        '.3g2'    = 'video/3gpp2' # 3GPP2 audio/video container
        '.7z'     = 'application/x-7z-compressed' # 7-zip archive
        '.aac'    = 'audio/aac' # AAC audio
        '.abw'    = 'application/x-abiword' # AbiWord document
        '.arc'    = 'application/x-freearc' # Archive document (multiple files embedded)
        '.avi'    = 'video/x-msvideo' # AVI: Audio Video Interleave
        '.azw'    = 'application/vnd.amazon.ebook' # Amazon Kindle eBook format
        '.bin'    = 'application/octet-stream' # Any kind of binary data
        '.bmp'    = 'image/bmp' # Windows OS/2 Bitmap Graphics
        '.bz'     = 'application/x-bzip' # BZip archive
        '.bz2'    = 'application/x-bzip2' # BZip2 archive
        '.csh'    = 'application/x-csh' # C-Shell script
        '.css'    = 'text/css' # Cascading Style Sheets (CSS)
        '.csv'    = 'text/csv' # Comma-separated values (CSV)
        '.deb'    = 'application/octet-stream' # Standard Uix archive format
        '.doc'    = 'application/msword' # Microsoft Word
        '.docx'   = 'application/vnd.openxmlformats-officedocument.wordprocessingml.document' # Microsoft Word (OpenXML)
        '.eot'    = 'application/vnd.ms-fontobject' # MS Embedded OpenType fonts
        '.epub'   = 'application/epub+zip' # Electronic publication (EPUB)
        '.exe'    = 'application/vnd.microsoft.portable-executable' # Microsoft application executable
        '.gz'     = 'application/x-gzip' # GZip Compressed Archive
        '.gif'    = 'image/gif' # Graphics Interchange Format (GIF)
        '.htm'    = 'text/html' # HyperText Markup Language (HTML)
        '.html'   = 'text/html' # HyperText Markup Language (HTML)
        '.ico'    = 'image/vnd.microsoft.icon' # Icon format
        '.ics'    = 'text/calendar' # iCalendar format
        '.ini'    = 'text/plain' # Text-based configuration file
        '.jar'    = 'application/java-archive' # Java Archive (JAR)
        '.jpeg'   = 'image/jpeg' # JPEG images
        '.jpg'    = 'image/jpeg' # JPEG images
        '.js'     = 'text/javascript' # JavaScript
        '.json'   = 'application/json' # JSON format
        '.jsonld' = 'application/ld+json' # JSON-LD format
        '.mid'    = 'audio/midi' # Musical Instrument Digital Interface (MIDI)
        '.midi'   = 'audio/midi' # Musical Instrument Digital Interface (MIDI)
        '.mjs'    = 'text/javascript' # JavaScript module
        '.mp3'    = 'audio/mpeg' # MP3 audio
        '.mp4'    = 'video/mp4' # MP3 video
        '.mov'    = 'video/quicktime' # Quicktime video
        '.mpeg'   = 'video/mpeg' # MPEG Video
        '.mpg'    = 'video/mpeg' # MPEG Video
        '.mpkg'   = 'application/vnd.apple.installer+xml' # Apple Installer Package
        '.msi'    = 'application/octet-stream' # Windows Installer package
        '.msix'   = 'application/octet-stream' # Windows Installer package
        '.mkv'    = 'video/x-matroska' # Matroska Multimedia Container
        '.odp'    = 'application/vnd.oasis.opendocument.presentation' # OpenDocument presentation document
        '.ods'    = 'application/vnd.oasis.opendocument.spreadsheet' # OpenDocument spreadsheet document
        '.odt'    = 'application/vnd.oasis.opendocument.text' # OpenDocument text document
        '.oga'    = 'audio/ogg' # OGG audio
        '.ogg'    = 'application/ogg' # OGG audio or video
        '.ogv'    = 'video/ogg' # OGG video
        '.ogx'    = 'application/ogg' # OGG
        '.opus'   = 'audio/opus' # Opus audio
        '.otf'    = 'font/otf' # OpenType font
        '.png'    = 'image/png' # Portable Network Graphics
        '.pdf'    = 'application/pdf' # Adobe Portable Document Format (PDF)
        '.php'    = 'application/x-httpd-php' # Hypertext Preprocessor (Personal Home Page)
        '.pkg'    = 'application/octet-stream' # mac OS X installer file
        '.ps1'    = 'text/plain' # PowerShell script file
        '.psd1'   = 'text/plain' # PowerShell module definition file
        '.psm1'   = 'text/plain' # PowerShell module file
        '.ppt'    = 'application/vnd.ms-powerpoint' # Microsoft PowerPoint
        '.pptx'   = 'application/vnd.openxmlformats-officedocument.presentationml.presentation' # Microsoft PowerPoint (OpenXML)
        '.rar'    = 'application/vnd.rar' # RAR archive
        '.rtf'    = 'application/rtf' # Rich Text Format (RTF)
        '.rpm'    = 'application/octet-stream' # Red Hat Linux package format
        '.sh'     = 'application/x-sh' # Bourne shell script
        '.svg'    = 'image/svg+xml' # Scalable Vector Graphics (SVG)
        '.swf'    = 'application/x-shockwave-flash' # Small web format (SWF) or Adobe Flash document
        '.tar'    = 'application/x-tar' # Tape Archive (TAR)
        '.tif'    = 'image/tiff' # Tagged Image File Format (TIFF)
        '.tiff'   = 'image/tiff' # Tagged Image File Format (TIFF)
        '.ts'     = 'video/mp2t' # MPEG transport stream
        '.ttf'    = 'font/ttf' # TrueType Font
        '.txt'    = 'text/plain' # Text (generally ASCII or ISO 8859-n)
        '.vsd'    = 'application/vnd.visio' # Microsoft Visio
        '.vsix'   = 'application/zip' # Visual Studio application package archive
        '.wav'    = 'audio/wav' # Waveform Audio Format
        '.weba'   = 'audio/webm' # WEBM audio
        '.webm'   = 'video/webm' # WEBM video
        '.webp'   = 'image/webp' # WEBP image
        '.woff'   = 'font/woff' # Web Open Font Format (WOFF)
        '.woff2'  = 'font/woff2' # Web Open Font Format (WOFF)
        '.xhtml'  = 'application/xhtml+xml' # XHTML
        '.xls'    = 'application/vnd.ms-excel' # Microsoft Excel
        '.xlsx'   = 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet' # Microsoft Excel (OpenXML)
        '.xml'    = 'application/xml' # XML
        '.xul'    = 'application/vnd.mozilla.xul+xml' # XUL
        '.zip'    = 'application/zip' # ZIP archive
    }
 }.GetEnumerator() | ForEach-Object {
     Set-Variable -Scope Script -Option ReadOnly -Name $_.Key -Value $_.Value
 }
