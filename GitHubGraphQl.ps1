function Invoke-GHGraphQl
{
    <#
    .SYNOPSIS
        A wrapper around Invoke-WebRequest that understands the GitHub GraphQL API.

    .DESCRIPTION
        A very heavy wrapper around Invoke-WebRequest that understands the GitHub QraphQL API.
        It also understands how to parse and handle errors from the GraphQL calls.

        The Git repo for this module can be found here: http://aka.ms/PowerShellForGitHub

    .PARAMETER Description
        A friendly description of the operation being performed for logging.

    .PARAMETER Body
        This parameter forms the body of the request. It will be automatically
        encoded to UTF8 and sent as Content Type: "application/json; charset=UTF-8"

    .PARAMETER AccessToken
        If provided, this will be used as the AccessToken for authentication with the
        GraphQL Api as opposed to requesting a new one.

    .PARAMETER TelemetryEventName
        If provided, the successful execution of this GraphQL command will be logged to telemetry
        using this event name.

    .PARAMETER TelemetryProperties
        If provided, the successful execution of this GraphQL command will be logged to telemetry
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
        PSCustomObject

    .EXAMPLE
        Invoke-GHGraphQl

    .NOTES
        This wraps Invoke-WebRequest as opposed to Invoke-RestMethod because we want access
        to the headers that are returned in the response, and Invoke-RestMethod drops those headers.
#>
    [CmdletBinding()]
    [OutputType([System.Management.Automation.ErrorRecord])]
    param(
        [string] $Description,

        [Parameter(Mandatory)]
        [string] $Body,

        [string] $AccessToken,

        [string] $TelemetryEventName = $null,

        [hashtable] $TelemetryProperties = @{},

        [string] $TelemetryExceptionBucket = $null
    )

    Invoke-UpdateCheck

    # Telemetry-related
    $stopwatch = New-Object -TypeName System.Diagnostics.Stopwatch
    $localTelemetryProperties = @{}
    $TelemetryProperties.Keys | ForEach-Object { $localTelemetryProperties[$_] = $TelemetryProperties[$_] }
    $errorBucket = $TelemetryExceptionBucket
    if ([String]::IsNullOrEmpty($errorBucket))
    {
        $errorBucket = $TelemetryEventName
    }

    $stopwatch.Start()

    $hostName = $(Get-GitHubConfiguration -Name 'ApiHostName')

    if ($hostName -eq 'github.com')
    {
        $url = "https://api.$hostName/graphql"
    }
    else
    {
        $url = "https://$hostName/api/v3/graphql"
    }

    $headers = @{
        'User-Agent' = 'PowerShellForGitHub'
    }

    $AccessToken = Get-AccessToken -AccessToken $AccessToken
    if (-not [String]::IsNullOrEmpty($AccessToken))
    {
        $headers['Authorization'] = "token $AccessToken"
    }

    $timeOut = Get-GitHubConfiguration -Name WebRequestTimeoutSec
    $method = 'Post'

    Write-Log -Message $Description -Level Debug
    Write-Log -Message "Accessing [$method] $url [Timeout = $timeOut]" -Level Debug

    if (Get-GitHubConfiguration -Name LogRequestBody)
    {
        Write-Log -Message $Body -Level Debug
    }

    $bodyAsBytes = [System.Text.Encoding]::UTF8.GetBytes($Body)

    # Disable Progress Bar in function scope during Invoke-WebRequest
    $ProgressPreference = 'SilentlyContinue'

    # Save Current Security Protocol
    $originalSecurityProtocol = [Net.ServicePointManager]::SecurityProtocol

    # Enforce TLS v1.2 Security Protocol
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

    $invokeWebRequestParms = @{
        Uri = $url
        Method = $method
        Headers = $headers
        Body = $bodyAsBytes
        UseDefaultCredentials = $true
        UseBasicParsing = $true
        TimeoutSec = $timeOut
        Verbose = $false
    }

    try
    {
        $result = Invoke-WebRequest @invokeWebRequestParms
    }
    catch
    {
        $ex = $_.Exception

        <#
            PowerShell 5 Invoke-WebRequest returns a 'System.Net.WebException' object on error.
            PowerShell 6+ Invoke-WebRequest returns a 'Microsoft.PowerShell.Commands.HttpResponseException' or
            a 'System.Net.Http.HttpRequestException' object on error.
        #>

        if ($ex.PSTypeNames[0] -eq 'System.Net.Http.HttpRequestException')
        {
            Write-Debug -Message "Processing PowerShell Core 'System.Net.Http.HttpRequestException'"

            $newErrorRecordParms = @{
                ErrorMessage = $ex.Message
                ErrorId = $_.FullyQualifiedErrorId
                ErrorCategory = $_.CategoryInfo.Category
                TargetObject = $_.TargetObject
            }
            $errorRecord = New-ErrorRecord @newErrorRecordParms

            Write-Log -Exception $errorRecord -Level Error
            Set-TelemetryException -Exception $ex -ErrorBucket $errorBucket -Properties $localTelemetryProperties

            $PSCmdlet.ThrowTerminatingError($errorRecord)
        }
        elseif ($ex.PSTypeNames[0] -eq 'Microsoft.PowerShell.Commands.HttpResponseException' -or
            $ex.PSTypeNames[0] -eq 'System.Net.WebException')
        {
            Write-Debug -Message "Processing '$($ex.PSTypeNames[0])'"

            $errorMessage = @()
            $errorMessage += $ex.Message

            $errorDetailsMessage = $_.ErrorDetails.Message

            if (-not [string]::IsNullOrEmpty($errorDetailsMessage))
            {
                Write-Debug -Message "Processing Error Details message '$errorDetailsMessage'"

                try
                {
                    Write-Debug  -Message 'Checking Error Details message for JSON content'

                    $errorDetailsMessageJson = $errorDetailsMessage | ConvertFrom-Json
                }
                catch [System.ArgumentException]
                {
                    # Will be thrown if $errorDetailsMessage isn't JSON content
                    Write-Debug -Message 'No Error Details Message JSON content Found'

                    $errorDetailsMessageJson = $false
                }

                if ($errorDetailsMessageJson)
                {
                    Write-Debug -Message 'Adding Error Details Message JSON content to output'
                    Write-Debug -Message "Error Details Message: $($errorDetailsMessageJson.message)"
                    Write-Debug -Message "Error Details Documentation URL: $($errorDetailsMessageJson.documentation_url)"

                    $errorMessage += ($errorDetailsMessageJson.message.Trim() +
                        ' | ' + $errorDetailsMessageJson.documentation_url.Trim())

                    if ($errorDetailsMessageJson.details)
                    {
                        $errorMessage += $errorDetailsMessageJson.details | Format-Table | Out-String
                    }
                }
                else
                {
                    # In this case, it's probably not a normal message from the API
                    Write-Debug -Message 'Adding Error Details Message String to output'

                    $errorMessage += $_.ErrorDetails.Message | Out-String
                }
            }

            if (-not [System.String]::IsNullOrEmpty($ex.Response))
            {
                Write-Debug -Message "Processing '$($ex.Response.PSTypeNames[0])' Object"

                <#
                    PowerShell 5.x returns a 'System.Net.HttpWebResponse' exception response object and
                    PowerShell 6+ returns a 'System.Net.Http.HttpResponseMessage' exception response object.
                #>

                $requestId = ''

                if ($ex.Response.PSTypeNames[0] -eq 'System.Net.HttpWebResponse')
                {
                    if (($ex.Response.Headers.Count -gt 0) -and
                        (-not [System.String]::IsNullOrEmpty($ex.Response.Headers['X-GitHub-Request-Id'])))
                    {
                        $requestId = $ex.Response.Headers['X-GitHub-Request-Id']
                    }
                }
                elseif ($ex.Response.PSTypeNames[0] -eq 'System.Net.Http.HttpResponseMessage')
                {
                    $requestId = ($ex.Response.Headers | Where-Object -Property Key -eq 'X-GitHub-Request-Id').Value
                }

                if (-not [System.String]::IsNullOrEmpty($requestId))
                {
                    Write-Debug -Message "GitHub RequestID '$requestId' in response header"

                    $localTelemetryProperties['RequestId'] = $requestId
                    $requestIdMessage += "RequestId: $requestId"
                    $errorMessage += $requestIdMessage

                    Write-Log -Message $requestIdMessage -Level Debug
                }
            }

            $newErrorRecordParms = @{
                ErrorMessage = $errorMessage -join [Environment]::NewLine
                ErrorId = $_.FullyQualifiedErrorId
                ErrorCategory = $_.CategoryInfo.Category
                TargetObject = $Body
            }
            $errorRecord = New-ErrorRecord @newErrorRecordParms

            Write-Log -Exception $errorRecord -Level Error
            Set-TelemetryException -Exception $ex -ErrorBucket $errorBucket -Properties $localTelemetryProperties

            $PSCmdlet.ThrowTerminatingError($errorRecord)
        }
        else
        {
            Write-Debug -Message "Processing Other Exception '$($ex.PSTypeNames[0])'"

            $newErrorRecordParms = @{
                ErrorMessage = $ex.Message
                ErrorId = $_.FullyQualifiedErrorId
                ErrorCategory = $_.CategoryInfo.Category
                TargetObject = $body
            }
            $errorRecord = New-ErrorRecord @newErrorRecordParms

            Write-Log -Exception $errorRecord -Level Error
            Set-TelemetryException -Exception $ex -ErrorBucket $errorBucket -Properties $localTelemetryProperties

            $PSCmdlet.ThrowTerminatingError($errorRecord)
        }
    }
    finally
    {
        # Restore original security protocol
        [Net.ServicePointManager]::SecurityProtocol = $originalSecurityProtocol
    }

    # Record the telemetry for this event.
    $stopwatch.Stop()
    if (-not [String]::IsNullOrEmpty($TelemetryEventName))
    {
        $telemetryMetrics = @{ 'Duration' = $stopwatch.Elapsed.TotalSeconds }
        Set-TelemetryEvent -EventName $TelemetryEventName -Properties $localTelemetryProperties -Metrics $telemetryMetrics -Verbose:$false
    }

    Write-Debug -Message "GraphQl result: '$($result.Content)'"

    $graphQlResult = $result.Content | ConvertFrom-Json

    if ($graphQlResult.errors)
    {
        Write-Debug -Message "GraphQl Error: $($graphQLResult.errors | Out-String)"

        if (-not [System.String]::IsNullOrEmpty($graphQlResult.errors[0].type))
        {
            $errorId = $graphQlResult.errors[0].type
            switch ($errorId)
            {
                'NOT_FOUND'
                {
                    Write-Debug -Message "GraphQl Error Type: $errorId"

                    $errorCategory = [System.Management.Automation.ErrorCategory]::ObjectNotFound
                }

                Default
                {
                    Write-Debug -Message "GraphQL Unknown Error Type: $errorId"

                    $errorCategory = [System.Management.Automation.ErrorCategory]::InvalidOperation
                }
            }
        }
        else
        {
            Write-Debug -Message "GraphQl Unspecified Error"

            $errorId = 'UnspecifiedError'
            $errorCategory = [System.Management.Automation.ErrorCategory]::NotSpecified
        }

        $errorMessage = @()
        $errorMessage += "GraphQl Error: $($graphQlResult.errors[0].message)"

        if ($result.Headers.Count -gt 0 -and
            -not [System.String]::IsNullOrEmpty($result.Headers['X-GitHub-Request-Id']))
        {
            $requestId = $result.Headers['X-GitHub-Request-Id']

            $requestIdMessage += "RequestId: $requestId"
            $errorMessage += $requestIdMessage

            Write-Log -Message $requestIdMessage -Level Debug
        }

        $newErrorRecordParms = @{
            ErrorMessage = $errorMessage -join [Environment]::NewLine
            ErrorId = $errorId
            ErrorCategory = $errorCategory
            TargetObject = $Body
        }
        $errorRecord = New-ErrorRecord @newErrorRecordParms

        Write-Log -Exception $errrorRecord -Level Error

        $PSCmdlet.ThrowTerminatingError($errorRecord)
    }
    else
    {
        return $graphQlResult
    }
}
