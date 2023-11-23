# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

function Get-SHA512Hash
{
<#
    .SYNOPSIS
        Gets the SHA512 hash of the requested string.

    .DESCRIPTION
        Gets the SHA512 hash of the requested string.

        The Git repo for this module can be found here: http://aka.ms/PowerShellForGitHub

    .PARAMETER PlainText
        The plain text that you want the SHA512 hash for.

    .EXAMPLE
        Get-SHA512Hash -PlainText "Hello World"

        Returns back the string "2C74FD17EDAFD80E8447B0D46741EE243B7EB74DD2149A0AB1B9246FB30382F27E853D8585719E0E67CBDA0DAA8F51671064615D645AE27ACB15BFB1447F459B"
        which represents the SHA512 hash of "Hello World"

    .OUTPUTS
        System.String - A SHA512 hash of the provided string
#>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [AllowNull()]
        [AllowEmptyString()]
        [string] $PlainText
    )

    $sha512= New-Object -TypeName System.Security.Cryptography.SHA512CryptoServiceProvider
    $utf8 = New-Object -TypeName System.Text.UTF8Encoding
    return [System.BitConverter]::ToString($sha512.ComputeHash($utf8.GetBytes($PlainText))) -replace '-', ''
}


function Write-Log
{
<#
    .SYNOPSIS
        Writes logging information to screen and log file simultaneously.

    .DESCRIPTION
        Writes logging information to screen and log file simultaneously.

        The Git repo for this module can be found here: http://aka.ms/PowerShellForGitHub

    .PARAMETER Message
        The message(s) to be logged. Each element of the array will be written to a separate line.

        This parameter supports pipelining but there are no
        performance benefits to doing so. For more information, see the .NOTES for this
        cmdlet.

    .PARAMETER Level
        The type of message to be logged.

    .PARAMETER Indent
        The number of spaces to indent the line in the log file.

    .PARAMETER Path
        The log file path.
        Defaults to $env:USERPROFILE\Documents\PowerShellForGitHub.log

    .PARAMETER Exception
        If present, the exception information will be logged after the messages provided.
        The actual string that is logged is obtained by passing this object to Out-String.

    .EXAMPLE
        Write-Log -Message "Everything worked." -Path C:\Debug.log

        Writes the message "Everything worked." to the screen as well as to a log file at "c:\Debug.log",
        with the caller's username and a date/time stamp prepended to the message.

    .EXAMPLE
        Write-Log -Message ("Everything worked.", "No cause for alarm.") -Path C:\Debug.log

        Writes the following message to the screen as well as to a log file at "c:\Debug.log",
        with the caller's username and a date/time stamp prepended to the message:

        Everything worked.
        No cause for alarm.

    .EXAMPLE
        Write-Log -Message "There may be a problem..." -Level Warning -Indent 2

        Writes the message "There may be a problem..." to the warning pipeline indented two spaces,
        as well as to the default log file with the caller's username and a date/time stamp
        prepended to the message.

    .EXAMPLE
        try { $null.Do() }
        catch { Write-Log -Message ("There was a problem.", "Here is the exception information:") -Exception $_ -Level Error }

        Logs the message:

        Write-Log : 2018-01-23 12:57:37 : dabelc : There was a problem.
        Here is the exception information:
        You cannot call a method on a null-valued expression.
        At line:1 char:7
        + try { $null.Do() } catch { Write-Log -Message ("There was a problem." ...
        +       ~~~~~~~~~~
            + CategoryInfo          : InvalidOperation: (:) [], RuntimeException
            + FullyQualifiedErrorId : InvokeMethodOnNull

    .INPUTS
        System.String

    .NOTES
        The "LogPath" configuration value indicates where the log file will be created.
        The "" determines if log entries will be made to the log file.
           If $false, log entries will ONLY go to the relevant output pipeline.

        Note that, although this function supports pipeline input to the -Message parameter,
        there is NO performance benefit to using the pipeline. This is because the pipeline
        input is simply accumulated and not acted upon until all input has been received.
        This behavior is intentional, in order for a statement like:
            "Multiple", "messages" | Write-Log -Exception $ex -Level Error
        to make sense.  In this case, the cmdlet should accumulate the messages and, at the end,
        include the exception information.
#>
    [CmdletBinding()]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidGlobalVars", "", Justification="We need to be able to access the PID for logging purposes, and it is accessed via a global variable.")]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidOverwritingBuiltInCmdlets", "", Justification="Write-Log is an internal function being incorrectly exported by PSDesiredStateConfiguration.  See PowerShell/PowerShell#7209")]
    param(
        [Parameter(ValueFromPipeline)]
        [AllowEmptyCollection()]
        [AllowEmptyString()]
        [AllowNull()]
        [string[]] $Message = @(),

        [ValidateSet('Error', 'Warning', 'Informational', 'Verbose', 'Debug')]
        [string] $Level = 'Informational',

        [ValidateRange(1, 30)]
        [Int16] $Indent = 0,

        [IO.FileInfo] $Path = (Get-GitHubConfiguration -Name LogPath),

        [System.Management.Automation.ErrorRecord] $Exception
    )

    begin
    {
        # Accumulate the list of Messages, whether by pipeline or parameter.
        $messages = @()
    }

    process
    {
        foreach ($m in $Message)
        {
            $messages += $m
        }
    }

    end
    {
        if ($null -ne $Exception)
        {
            # If we have an exception, add it after the accumulated messages.
            $messages += Out-String -InputObject $Exception
        }
        elseif ($messages.Count -eq 0)
        {
            # If no exception and no messages, we should early return.
            return
        }

        # Finalize the string to be logged.
        $finalMessage = $messages -join [Environment]::NewLine

        # Build the console and log-specific messages.
        $date = Get-Date
        $dateString = $date.ToString("yyyy-MM-dd HH:mm:ss")
        if (Get-GitHubConfiguration -Name LogTimeAsUtc)
        {
            $dateString = $date.ToUniversalTime().ToString("yyyy-MM-dd HH:mm:ssZ")
        }

        $consoleMessage = '{0}{1}' -f
            (" " * $Indent),
            $finalMessage

        if (Get-GitHubConfiguration -Name LogProcessId)
        {
            $maxPidDigits = 10 # This is an estimate (see https://stackoverflow.com/questions/17868218/what-is-the-maximum-process-id-on-windows)
            $pidColumnLength = $maxPidDigits + "[]".Length
            $logFileMessage = "{0}{1} : {2, -$pidColumnLength} : {3} : {4} : {5}" -f
                (" " * $Indent),
                $dateString,
                "[$global:PID]",
                $env:username,
                $Level.ToUpper(),
                $finalMessage
        }
        else
        {
            $logFileMessage = '{0}{1} : {2} : {3} : {4}' -f
                (" " * $Indent),
                $dateString,
                $env:username,
                $Level.ToUpper(),
                $finalMessage
        }

        # Write the message to screen/log.
        # Note that the below logic could easily be moved to a separate helper function, but a conscious
        # decision was made to leave it here. When this cmdlet is called with -Level Error, Write-Error
        # will generate a WriteErrorException with the origin being Write-Log. If this call is moved to
        # a helper function, the origin of the WriteErrorException will be the helper function, which
        # could confuse an end user.
        switch ($Level)
        {
            # Need to explicitly say SilentlyContinue here so that we continue on, given that
            # we've assigned a script-level ErrorActionPreference of "Stop" for the module.
            'Error'   { Write-Error $consoleMessage -ErrorAction SilentlyContinue }
            'Warning' { Write-Warning $consoleMessage }
            'Verbose' { Write-Verbose $consoleMessage }
            'Debug'   { Write-Debug $consoleMessage }
            'Informational'    {
                # We'd prefer to use Write-Information to enable users to redirect that pipe if
                # they want, unfortunately it's only available on v5 and above.  We'll fallback to
                # using Write-Host for earlier versions (since we still need to support v4).
                if ($PSVersionTable.PSVersion.Major -ge 5)
                {
                    Write-Information $consoleMessage -InformationAction Continue
                }
                else
                {
                    Write-InteractiveHost $consoleMessage
                }
            }
        }

        try
        {
            if (-not (Get-GitHubConfiguration -Name DisableLogging))
            {
                if ([String]::IsNullOrWhiteSpace($Path))
                {
                    Write-Warning 'Logging is currently enabled, however no path has been specified for the log file.  Use "Set-GitHubConfiguration -LogPath" to set the log path, or "Set-GitHubConfiguration -DisableLogging" to disable logging.'
                }
                else
                {
                    $logFileMessage | Out-File -FilePath $Path -Append -WhatIf:$false -Confirm:$false
                }
            }
        }
        catch
        {
            $output = @()
            $output += "Failed to add log entry to [$Path]. The error was:"
            $output += Out-String -InputObject $_

            if (Test-Path -Path $Path -PathType Leaf)
            {
                # The file exists, but likely is being held open by another process.
                # Let's do best effort here and if we can't log something, just report
                # it and move on.
                $output += "This is non-fatal, and your command will continue.  Your log file will be missing this entry:"
                $output += $consoleMessage
                Write-Warning ($output -join [Environment]::NewLine)
            }
            else
            {
                # If the file doesn't exist and couldn't be created, it likely will never
                # be valid.  In that instance, let's stop everything so that the user can
                # fix the problem, since they have indicated that they want this logging to
                # occur.
                throw ($output -join [Environment]::NewLine)
            }
        }
    }
}

$script:alwaysRedactParametersForLogging = @(
    'AccessToken' # Would be a security issue
)

$script:alwaysExcludeParametersForLogging = @(
)

function Write-InvocationLog
{
<#
    .SYNOPSIS
        Writes a log entry for the invoke command.

    .DESCRIPTION
        Writes a log entry for the invoke command.

        The Git repo for this module can be found here: http://aka.ms/PowerShellForGitHub

    .PARAMETER InvocationInfo
        The '$MyInvocation' object from the calling function.
        No need to explicitly provide this if you're trying to log the immediate function this is
        being called from.

    .PARAMETER RedactParameter
        An optional array of parameter names that should be logged, but their values redacted.

    .PARAMETER ExcludeParameter
        An optional array of parameter names that should simply not be logged.

    .EXAMPLE
        Write-InvocationLog -Invocation $MyInvocation

    .EXAMPLE
        Write-InvocationLog -Invocation $MyInvocation -ExcludeParameter @('Properties', 'Metrics')

    .NOTES
        The actual invocation line will not be _completely_ accurate as converted parameters will
        be in JSON format as opposed to PowerShell format.  However, it should be sufficient enough
        for debugging purposes.

        ExcludeParameter will always take precedence over RedactParameter.
#>
    [CmdletBinding()]
    param(
        [Management.Automation.InvocationInfo] $Invocation = (Get-Variable -Name MyInvocation -Scope 1 -ValueOnly),

        [string[]] $RedactParameter,

        [string[]] $ExcludeParameter
    )

    $jsonConversionDepth = 20 # Seems like it should be more than sufficient

    # Build up the invoked line, being sure to exclude and/or redact any values necessary
    $params = @()
    foreach ($param in $Invocation.BoundParameters.GetEnumerator())
    {
        if ($param.Key -in ($script:alwaysExcludeParametersForLogging + $ExcludeParameter))
        {
            continue
        }

        if ($param.Key -in ($script:alwaysRedactParametersForLogging + $RedactParameter))
        {
            $params += "-$($param.Key) <redacted>"
        }
        else
        {
            if ($param.Value -is [switch])
            {
                $params += "-$($param.Key):`$$($param.Value.ToBool().ToString().ToLower())"
            }
            else
            {
                $params += "-$($param.Key) $(ConvertTo-Json -InputObject $param.Value -Depth $jsonConversionDepth -Compress)"
            }
        }
    }

    Write-Log -Message "[$($Invocation.MyCommand.Module.Version)] Executing: $($Invocation.MyCommand) $($params -join ' ')" -Level Verbose
}

function DeepCopy-Object
{
<#
    .SYNOPSIS
        Creates a deep copy of a serializable object.

    .DESCRIPTION
        Creates a deep copy of a serializable object.
        By default, PowerShell performs shallow copies (simple references)
        when assigning objects from one variable to another.  This will
        create full exact copies of the provided object so that they
        can be manipulated independently of each other, provided that the
        object being copied is serializable.

        The Git repo for this module can be found here: http://aka.ms/PowerShellForGitHub

    .PARAMETER InputObject
        The object that is to be copied.  This must be serializable or this will fail.

    .EXAMPLE
        $bar = DeepCopy-Object -InputObject $foo
        Assuming that $foo is serializable, $bar will now be an exact copy of $foo, but
        any changes that you make to one will not affect the other.

    .RETURNS
        An exact copy of the PSObject that was just deep copied.
#>
    [CmdletBinding()]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseApprovedVerbs", "", Justification="Intentional.  This isn't exported, and needed to be explicit relative to Copy-Object.")]
    param(
        [Parameter(Mandatory)]
        [PSCustomObject] $InputObject
    )

    $serialData = [System.Management.Automation.PSSerializer]::Serialize($InputObject, 64)
    return [System.Management.Automation.PSSerializer]::Deserialize($serialData)
}

function New-TemporaryDirectory
{
<#
    .SYNOPSIS
        Creates a new subdirectory within the users's temporary directory and returns the path.

    .DESCRIPTION
        Creates a new subdirectory within the users's temporary directory and returns the path.

        The Git repo for this module can be found here: http://aka.ms/PowerShellForGitHub

    .EXAMPLE
        New-TemporaryDirectory
        Creates a new directory with a GUID under $env:TEMP

    .OUTPUTS
        System.String - The path to the newly created temporary directory
#>
    [CmdletBinding(SupportsShouldProcess)]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSShouldProcess", "", Justification="Methods called within here make use of PSShouldProcess, and the switch is passed on to them inherently.")]
    param()

    $parentTempPath = [System.IO.Path]::GetTempPath()
    $tempFolderPath = [String]::Empty
    do
    {
        $guid = [System.Guid]::NewGuid()
        $tempFolderPath = Join-Path -Path $parentTempPath -ChildPath $guid
    }
    while (Test-Path -Path $tempFolderPath -PathType Container)

    Write-Log -Message "Creating temporary directory: $tempFolderPath" -Level Verbose
    New-Item -ItemType Directory -Path $tempFolderPath
}

function Write-InteractiveHost
{
<#
    .SYNOPSIS
        Forwards to Write-Host only if the host is interactive, else does nothing.

    .DESCRIPTION
        A proxy function around Write-Host that detects if the host is interactive
        before calling Write-Host. Use this instead of Write-Host to avoid failures in
        non-interactive hosts.

        The Git repo for this module can be found here: http://aka.ms/PowerShellForGitHub

    .EXAMPLE
        Write-InteractiveHost "Test"
        Write-InteractiveHost "Test" -NoNewline -f Yellow

    .NOTES
        Boilerplate is generated using these commands:
        # $Metadata = New-Object System.Management.Automation.CommandMetaData (Get-Command Write-Host)
        # [System.Management.Automation.ProxyCommand]::Create($Metadata) | Out-File temp
#>

    [CmdletBinding(
        HelpUri='http://go.microsoft.com/fwlink/?LinkID=113426',
        RemotingCapability='None')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingWriteHost", "", Justification="This provides a wrapper around Write-Host. In general, we'd like to use Write-Information, but it's not supported on PS 4.0 which we need to support.")]
    param(
        [Parameter(
            Position=0,
            ValueFromPipeline,
            ValueFromRemainingArguments)]
        [System.Object] $Object,

        [switch] $NoNewline,

        [System.Object] $Separator,

        [System.ConsoleColor] $ForegroundColor,

        [System.ConsoleColor] $BackgroundColor
    )

    begin
    {
        $hostIsInteractive = ([Environment]::UserInteractive -and
            ![Bool]([Environment]::GetCommandLineArgs() -like '-noni*') -and
            ((Get-Host).Name -ne 'Default Host'))
    }

    process
    {
        # Determine if the host is interactive
        if ($hostIsInteractive)
        {
            # Special handling for OutBuffer (generated for the proxy function)
            $outBuffer = $null
            if ($PSBoundParameters.TryGetValue('OutBuffer', [ref]$outBuffer))
            {
                $PSBoundParameters['OutBuffer'] = 1
            }

            Write-Host @PSBoundParameters
        }
    }
}

function Resolve-UnverifiedPath
{
<#
    .SYNOPSIS
        A wrapper around Resolve-Path that works for paths that exist as well
        as for paths that don't (Resolve-Path normally throws an exception if
        the path doesn't exist.)

    .DESCRIPTION
        A wrapper around Resolve-Path that works for paths that exist as well
        as for paths that don't (Resolve-Path normally throws an exception if
        the path doesn't exist.)

        The Git repo for this module can be found here: https://aka.ms/PowerShellForGitHub

    .EXAMPLE
        Resolve-UnverifiedPath -Path 'c:\windows\notepad.exe'

        Returns the string 'c:\windows\notepad.exe'.

    .EXAMPLE
        Resolve-UnverifiedPath -Path '..\notepad.exe'

        Returns the string 'c:\windows\notepad.exe', assuming that it's executed from
        within 'c:\windows\system32' or some other sub-directory.

    .EXAMPLE
        Resolve-UnverifiedPath -Path '..\foo.exe'

        Returns the string 'c:\windows\foo.exe', assuming that it's executed from
        within 'c:\windows\system32' or some other sub-directory, even though this
        file doesn't exist.

    .OUTPUTS
        [string] - The fully resolved path

#>
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline)]
        [string] $Path
    )

    process
    {
        $resolvedPath = Resolve-Path -Path $Path -ErrorVariable resolvePathError -ErrorAction SilentlyContinue

        if ($null -eq $resolvedPath)
        {
            Write-Output -InputObject ($resolvePathError[0].TargetObject)
        }
        else
        {
            Write-Output -InputObject ($resolvedPath.ProviderPath)
        }
    }
}

function Ensure-Directory
{
<#
    .SYNOPSIS
        A utility function for ensuring a given directory exists.

    .DESCRIPTION
        A utility function for ensuring a given directory exists.

        If the directory does not already exist, it will be created.

    .PARAMETER Path
        A full or relative path to the directory that should exist when the function exits.

    .NOTES
        Uses the Resolve-UnverifiedPath function to resolve relative paths.
#>
    [CmdletBinding()]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseApprovedVerbs", "", Justification = "Unable to find a standard verb that satisfies describing the purpose of this internal helper method.")]
    param(
        [Parameter(Mandatory)]
        [string] $Path
    )

    try
    {
        $Path = Resolve-UnverifiedPath -Path $Path

        if (-not (Test-Path -PathType Container -Path $Path))
        {
            Write-Log -Message "Creating directory: [$Path]" -Level Verbose
            New-Item -ItemType Directory -Path $Path | Out-Null
        }
    }
    catch
    {
        Write-Log -Message "Could not ensure directory: [$Path]" -Level Error

        throw
    }
}

function Get-HttpWebResponseContent
{
<#
    .SYNOPSIS
        Returns the content that may be contained within an HttpWebResponse object.

    .DESCRIPTION
        Returns the content that may be contained within an HttpWebResponse object.

        This would commonly be used when trying to get the potential content
        returned within a failing WebResponse.  Normally, when you call
        Invoke-WebRequest, it returns back a BasicHtmlWebResponseObject which
        directly contains a Content property, however if the web request fails,
        you get a WebException which contains a simpler WebResponse, which
        requires a bit more effort in order to access the raw response content.

    .PARAMETER WebResponse
        An HttpWebResponse object, typically the Response property on a WebException.

    .OUTPUTS
        System.String - The raw content that was included in a WebResponse; $null otherwise.
#>
    [CmdletBinding()]
    [OutputType([String])]
    param(
        [System.Net.HttpWebResponse] $WebResponse
    )

    $streamReader = $null

    try
    {
        $content = $null

        if (($null -ne $WebResponse) -and ($WebResponse.ContentLength -gt 0))
        {
            $stream = $WebResponse.GetResponseStream()
            $encoding = [System.Text.Encoding]::UTF8
            if (-not [String]::IsNullOrWhiteSpace($WebResponse.ContentEncoding))
            {
                $encoding = [System.Text.Encoding]::GetEncoding($WebResponse.ContentEncoding)
            }

            $streamReader = New-Object -TypeName System.IO.StreamReader -ArgumentList ($stream, $encoding)
            $content = $streamReader.ReadToEnd()
        }

        return $content
    }
    finally
    {
        if ($null -ne $streamReader)
        {
            $streamReader.Close()
        }
    }
}

function New-ErrorRecord
{
<#
    .SYNOPSIS
        Returns an ErrorRecord object for use by $PSCmdlet.ThrowTerminatingError

    .DESCRIPTION
        Returns an ErrorRecord object for use by $PSCmdlet.ThrowTerminatingError

    .PARAMETER ErrorMessage
        The message that describes the error

    .PARAMETER ErrorId
        The Id to be used to construct the FullyQualifiedErrorId property of the error record.

    .PARAMETER ErrorCategory
        This is the ErrorCategory which best describes the error.

    .PARAMETER TargetObject
        This is the object against which the cmdlet was operating when the error occurred. This is optional.

    .OUTPUTS
        System.Management.Automation.ErrorRecord

    .NOTES
        ErrorRecord Class - https://docs.microsoft.com/en-us/dotnet/api/system.management.automation.errorrecord
        Exception Class - https://docs.microsoft.com/en-us/dotnet/api/system.exception
        Cmdlet.ThrowTerminationError - https://docs.microsoft.com/en-us/dotnet/api/system.management.automation.cmdlet.throwterminatingerror
#>
    [CmdletBinding()]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '',
        Justification = 'This function is non state changing.')]
    [OutputType([System.Management.Automation.ErrorRecord])]
    param(
        [Parameter(Mandatory)]
        [System.String] $ErrorMessage,

        [System.String] $ErrorId,

        [Parameter(Mandatory)]
        [System.Management.Automation.ErrorCategory] $ErrorCategory,

        [System.Management.Automation.PSObject] $TargetObject
    )

    $exception = New-Object -TypeName System.Exception -ArgumentList $ErrorMessage
    $errorRecordArgumentList = $exception, $ErrorId, $ErrorCategory, $TargetObject
    $errorRecord = New-Object -TypeName System.Management.Automation.ErrorRecord -ArgumentList $errorRecordArgumentList

    return $errorRecord
}
