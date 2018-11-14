# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

# Singleton telemetry client. Don't directly access this though....always get it
# by calling Get-TelemetryClient to ensure that the singleton is properly initialized.
$script:GHTelemetryClient = $null

function Get-PiiSafeString
{
<#
    .SYNOPSIS
        If PII protection is enabled, returns back an SHA512-hashed value for the specified string,
        otherwise returns back the original string, untouched.

    .SYNOPSIS
        If PII protection is enabled, returns back an SHA512-hashed value for the specified string,
        otherwise returns back the original string, untouched.

        The Git repo for this module can be found here: http://aka.ms/PowerShellForGitHub

    .PARAMETER PlainText
        The plain text that contains PII that may need to be protected.

    .EXAMPLE
        Get-PiiSafeString -PlainText "Hello World"

        Returns back the string "B10A8DB164E0754105B7A99BE72E3FE5" which respresents
        the SHA512 hash of "Hello World", but only if the "DisablePiiProtection" configuration
        value is $false.  If it's $true, "Hello World" will be returned.

    .OUTPUTS
        System.String - A SHA512 hash of PlainText will be returned if the "DisablePiiProtection"
                        configuration value is $false, otherwise PlainText will be returned untouched.
#>
    [CmdletBinding()]
    [OutputType([String])]
    param(
        [Parameter(Mandatory)]
        [AllowNull()]
        [AllowEmptyString()]
        [string] $PlainText
    )

    if (Get-GitHubConfiguration -Name DisablePiiProtection)
    {
        return $PlainText
    }
    else
    {
        return (Get-SHA512Hash -PlainText $PlainText)
    }
}

function Get-ApplicationInsightsDllPath
{
<#
    .SYNOPSIS
        Makes sure that the Microsoft.ApplicationInsights.dll assembly is available
        on the machine, and returns the path to it.

    .DESCRIPTION
        Makes sure that the Microsoft.ApplicationInsights.dll assembly is available
        on the machine, and returns the path to it.

        This will first look for the assembly in the module's script directory.

        Next it will look for the assembly in the location defined by
        $SBAlternateAssemblyDir.  This value would have to be defined by the user
        prior to execution of this cmdlet.

        If not found there, it will look in a temp folder established during this
        PowerShell session.

        If still not found, it will download the nuget package
        for it to a temp folder accessible during this PowerShell session.

        The Git repo for this module can be found here: http://aka.ms/PowerShellForGitHub

    .PARAMETER NoStatus
        If this switch is specified, long-running commands will run on the main thread
        with no commandline status update.  When not specified, those commands run in
        the background, enabling the command prompt to provide status information.

    .EXAMPLE
        Get-ApplicationInsightsDllPath

        Returns back the path to the assembly as found.  If the package has to
        be downloaded via nuget, the command prompt will show a time duration
        status counter while the package is being downloaded.

    .EXAMPLE
        Get-ApplicationInsightsDllPath -NoStatus

        Returns back the path to the assembly as found.  If the package has to
        be downloaded via nuget, the command prompt will appear to hang during
        this time.

    .OUTPUTS
        System.String - The path to the Microsoft.ApplicationInsights.dll assembly.
#>
    [CmdletBinding(SupportsShouldProcess)]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSShouldProcess", "", Justification="Methods called within here make use of PSShouldProcess, and the switch is passed on to them inherently.")]
    param(
        [switch] $NoStatus
    )

    $nugetPackageName = "Microsoft.ApplicationInsights"
    $nugetPackageVersion = "2.0.1"
    $assemblyPackageTailDir = "Microsoft.ApplicationInsights.2.0.1\lib\net45"
    $assemblyName = "Microsoft.ApplicationInsights.dll"

    return Get-NugetPackageDllPath -NugetPackageName $nugetPackageName -NugetPackageVersion $nugetPackageVersion -AssemblyPackageTailDirectory $assemblyPackageTailDir -AssemblyName $assemblyName -NoStatus:$NoStatus
}

function Get-DiagnosticsTracingDllPath
{
<#
    .SYNOPSIS
        Makes sure that the Microsoft.Diagnostics.Tracing.EventSource.dll assembly is available
        on the machine, and returns the path to it.

    .DESCRIPTION
        Makes sure that the Microsoft.Diagnostics.Tracing.EventSource.dll assembly is available
        on the machine, and returns the path to it.

        This will first look for the assembly in the module's script directory.

        Next it will look for the assembly in the location defined by
        $SBAlternateAssemblyDir.  This value would have to be defined by the user
        prior to execution of this cmdlet.

        If not found there, it will look in a temp folder established during this
        PowerShell session.

        If still not found, it will download the nuget package
        for it to a temp folder accessible during this PowerShell session.

        The Git repo for this module can be found here: http://aka.ms/PowerShellForGitHub

    .PARAMETER NoStatus
        If this switch is specified, long-running commands will run on the main thread
        with no commandline status update.  When not specified, those commands run in
        the background, enabling the command prompt to provide status information.

    .EXAMPLE
        Get-DiagnosticsTracingDllPath

        Returns back the path to the assembly as found.  If the package has to
        be downloaded via nuget, the command prompt will show a time duration
        status counter while the package is being downloaded.

    .EXAMPLE
        Get-DiagnosticsTracingDllPath -NoStatus

        Returns back the path to the assembly as found.  If the package has to
        be downloaded via nuget, the command prompt will appear to hang during
        this time.

    .OUTPUTS
        System.String - The path to the Microsoft.ApplicationInsights.dll assembly.
#>
    [CmdletBinding(SupportsShouldProcess)]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSShouldProcess", "", Justification="Methods called within here make use of PSShouldProcess, and the switch is passed on to them inherently.")]
    param(
        [switch] $NoStatus
    )

    $nugetPackageName = "Microsoft.Diagnostics.Tracing.EventSource.Redist"
    $nugetPackageVersion = "1.1.24"
    $assemblyPackageTailDir = "Microsoft.Diagnostics.Tracing.EventSource.Redist.1.1.24\lib\net35"
    $assemblyName = "Microsoft.Diagnostics.Tracing.EventSource.dll"

    return Get-NugetPackageDllPath -NugetPackageName $nugetPackageName -NugetPackageVersion $nugetPackageVersion -AssemblyPackageTailDirectory $assemblyPackageTailDir -AssemblyName $assemblyName -NoStatus:$NoStatus
}

function Get-ThreadingTasksDllPath
{
<#
    .SYNOPSIS
        Makes sure that the Microsoft.Threading.Tasks.dll assembly is available
        on the machine, and returns the path to it.

    .DESCRIPTION
        Makes sure that the Microsoft.Threading.Tasks.dll assembly is available
        on the machine, and returns the path to it.

        This will first look for the assembly in the module's script directory.

        Next it will look for the assembly in the location defined by
        $SBAlternateAssemblyDir.  This value would have to be defined by the user
        prior to execution of this cmdlet.

        If not found there, it will look in a temp folder established during this
        PowerShell session.

        If still not found, it will download the nuget package
        for it to a temp folder accessible during this PowerShell session.

        The Git repo for this module can be found here: http://aka.ms/PowerShellForGitHub

    .PARAMETER NoStatus
        If this switch is specified, long-running commands will run on the main thread
        with no commandline status update.  When not specified, those commands run in
        the background, enabling the command prompt to provide status information.

    .EXAMPLE
        Get-ThreadingTasksDllPath

        Returns back the path to the assembly as found.  If the package has to
        be downloaded via nuget, the command prompt will show a time duration
        status counter while the package is being downloaded.

    .EXAMPLE
        Get-ThreadingTasksDllPath -NoStatus

        Returns back the path to the assembly as found.  If the package has to
        be downloaded via nuget, the command prompt will appear to hang during
        this time.

    .OUTPUTS
        System.String - The path to the Microsoft.ApplicationInsights.dll assembly.
#>
    [CmdletBinding(SupportsShouldProcess)]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSShouldProcess", "", Justification="Methods called within here make use of PSShouldProcess, and the switch is passed on to them inherently.")]
    param(
        [switch] $NoStatus
    )

    $nugetPackageName = "Microsoft.Bcl.Async"
    $nugetPackageVersion = "1.0.168.0"
    $assemblyPackageTailDir = "Microsoft.Bcl.Async.1.0.168\lib\net40"
    $assemblyName = "Microsoft.Threading.Tasks.dll"

    return Get-NugetPackageDllPath -NugetPackageName $nugetPackageName -NugetPackageVersion $nugetPackageVersion -AssemblyPackageTailDirectory $assemblyPackageTailDir -AssemblyName $assemblyName -NoStatus:$NoStatus
}

function Get-TelemetryClient
{
<#
    .SYNOPSIS
        Returns back the singleton instance of the Application Insights TelemetryClient for
        this module.

    .DESCRIPTION
        Returns back the singleton instance of the Application Insights TelemetryClient for
        this module.

        If the singleton hasn't been initialized yet, this will ensure all dependenty assemblies
        are available on the machine, create the client and initialize its properties.

        This will first look for the dependent assemblies in the module's script directory.

        Next it will look for the assemblies in the location defined by
        $SBAlternateAssemblyDir.  This value would have to be defined by the user
        prior to execution of this cmdlet.

        If not found there, it will look in a temp folder established during this
        PowerShell session.

        If still not found, it will download the nuget package
        for it to a temp folder accessible during this PowerShell session.

        The Git repo for this module can be found here: http://aka.ms/PowerShellForGitHub

    .PARAMETER NoStatus
        If this switch is specified, long-running commands will run on the main thread
        with no commandline status update.  When not specified, those commands run in
        the background, enabling the command prompt to provide status information.

    .EXAMPLE
        Get-TelemetryClient

        Returns back the singleton instance to the TelemetryClient for the module.
        If any nuget packages have to be downloaded in order to load the TelemetryClient, the
        command prompt will show a time duration status counter during the download process.

    .EXAMPLE
        Get-TelemetryClient -NoStatus

        Returns back the singleton instance to the TelemetryClient for the module.
        If any nuget packages have to be downloaded in order to load the TelemetryClient, the
        command prompt will appear to hang during this time.

    .OUTPUTS
        Microsoft.ApplicationInsights.TelemetryClient
#>
    [CmdletBinding(SupportsShouldProcess)]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSShouldProcess", "", Justification="Methods called within here make use of PSShouldProcess, and the switch is passed on to them inherently.")]
    param(
        [switch] $NoStatus
    )

    if ($null -eq $script:GHTelemetryClient)
    {
        if (-not (Get-GitHubConfiguration -Name SuppressTelemetryReminder))
        {
            Write-Log -Message 'Telemetry is currently enabled.  It can be disabled by calling "Set-GitHubConfiguration -DisableTelemetry". Refer to USAGE.md#telemetry for more information. Stop seeing this message in the future by calling "Set-GitHubConfiguration -SuppressTelemetryReminder".'
        }

        Write-Log -Message "Initializing telemetry client." -Level Verbose

        $dlls = @(
                    (Get-ThreadingTasksDllPath -NoStatus:$NoStatus),
                    (Get-DiagnosticsTracingDllPath -NoStatus:$NoStatus),
                    (Get-ApplicationInsightsDllPath -NoStatus:$NoStatus)
        )

        foreach ($dll in $dlls)
        {
            $bytes = [System.IO.File]::ReadAllBytes($dll)
            [System.Reflection.Assembly]::Load($bytes) | Out-Null
        }

        $username = Get-PiiSafeString -PlainText $env:USERNAME

        $script:GHTelemetryClient = New-Object Microsoft.ApplicationInsights.TelemetryClient
        $script:GHTelemetryClient.InstrumentationKey = (Get-GitHubConfiguration -Name ApplicationInsightsKey)
        $script:GHTelemetryClient.Context.User.Id = $username
        $script:GHTelemetryClient.Context.Session.Id = [System.GUID]::NewGuid().ToString()
        $script:GHTelemetryClient.Context.Properties['Username'] = $username
        $script:GHTelemetryClient.Context.Properties['DayOfWeek'] = (Get-Date).DayOfWeek
        $script:GHTelemetryClient.Context.Component.Version = $MyInvocation.MyCommand.Module.Version.ToString()
    }

    return $script:GHTelemetryClient
}

function Set-TelemetryEvent
{
<#
    .SYNOPSIS
        Posts a new telemetry event for this module to the configured Applications Insights instance.

    .DESCRIPTION
        Posts a new telemetry event for this module to the configured Applications Insights instance.

        The Git repo for this module can be found here: http://aka.ms/PowerShellForGitHub

    .PARAMETER EventName
        The name of the event that has occurred.

    .PARAMETER Properties
        A collection of name/value pairs (string/string) that should be associated with this event.

    .PARAMETER Metrics
        A collection of name/value pair metrics (string/double) that should be associated with
        this event.

    .PARAMETER NoStatus
        If this switch is specified, long-running commands will run on the main thread
        with no commandline status update.  When not specified, those commands run in
        the background, enabling the command prompt to provide status information.

    .EXAMPLE
        Set-TelemetryEvent "zFooTest1"

        Posts a "zFooTest1" event with the default set of properties and metrics.  If the telemetry
        client needs to be created to accomplish this, and the required assemblies are not available
        on the local machine, the download status will be presented at the command prompt.

    .EXAMPLE
        Set-TelemetryEvent "zFooTest1" @{"Prop1" = "Value1"}

        Posts a "zFooTest1" event with the default set of properties and metrics along with an
        additional property named "Prop1" with a value of "Value1".  If the telemetry client
        needs to be created to accomplish this, and the required assemblies are not available
        on the local machine, the download status will be presented at the command prompt.

    .EXAMPLE
        Set-TelemetryEvent "zFooTest1" -NoStatus

        Posts a "zFooTest1" event with the default set of properties and metrics.  If the telemetry
        client needs to be created to accomplish this, and the required assemblies are not available
        on the local machine, the command prompt will appear to hang while they are downloaded.

    .NOTES
        Because of the short-running nature of this module, we always "flush" the events as soon
        as they have been posted to ensure that they make it to Application Insights.
#>
    [CmdletBinding(SupportsShouldProcess)]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSShouldProcess", "", Justification="Methods called within here make use of PSShouldProcess, and the switch is passed on to them inherently.")]
    param(
        [Parameter(Mandatory)]
        [string] $EventName,

        [hashtable] $Properties = @{},

        [hashtable] $Metrics = @{},

        [switch] $NoStatus
    )

    if (Get-GitHubConfiguration -Name DisableTelemetry)
    {
        Write-Log -Message "Telemetry has been disabled via configuration. Skipping reporting event [$EventName]." -Level Verbose
        return
    }

    Write-InvocationLog -Invocation $MyInvocation -ExcludeParameter @('Properties', 'Metrics')

    try
    {
        $telemetryClient = Get-TelemetryClient -NoStatus:$NoStatus

        $propertiesDictionary = New-Object 'System.Collections.Generic.Dictionary[string, string]'
        $propertiesDictionary['DayOfWeek'] = (Get-Date).DayOfWeek
        $Properties.Keys | ForEach-Object { $propertiesDictionary[$_] = $Properties[$_] }

        $metricsDictionary = New-Object 'System.Collections.Generic.Dictionary[string, double]'
        $Metrics.Keys | ForEach-Object { $metricsDictionary[$_] = $Metrics[$_] }

        $telemetryClient.TrackEvent($EventName, $propertiesDictionary, $metricsDictionary);

        # Flushing should increase the chance of success in uploading telemetry logs
        Flush-TelemetryClient -NoStatus:$NoStatus
    }
    catch
    {
        # Telemetry should be best-effort.  Failures while trying to handle telemetry should not
        # cause exceptions in the app itself.
        Write-Log -Message "Set-TelemetryEvent failed:" -Exception $_ -Level Error
    }
}

function Set-TelemetryException
{
<#
    .SYNOPSIS
        Posts a new telemetry event to the configured Application Insights instance indicating
        that an exception occurred in this this module.

    .DESCRIPTION
        Posts a new telemetry event to the configured Application Insights instance indicating
        that an exception occurred in this this module.

        The Git repo for this module can be found here: http://aka.ms/PowerShellForGitHub

    .PARAMETER Exception
        The exception that just occurred.

    .PARAMETER ErrorBucket
        A property to be added to the Exception being logged to make it easier to filter to
        exceptions resulting from similar scenarios.

    .PARAMETER Properties
        Additional properties that the caller may wish to be associated with this exception.

    .PARAMETER NoFlush
        It's not recommended to use this unless the exception is coming from Flush-TelemetryClient.
        By default, every time a new exception is logged, the telemetry client will be flushed
        to ensure that the event is published to the Application Insights.  Use of this switch
        prevents that automatic flushing (helpful in the scenario where the exception occurred
        when trying to do the actual Flush).

    .PARAMETER NoStatus
        If this switch is specified, long-running commands will run on the main thread
        with no commandline status update.  When not specified, those commands run in
        the background, enabling the command prompt to provide status information.

    .EXAMPLE
        Set-TelemetryException $_

        Used within the context of a catch statement, this will post the exception that just
        occurred, along with a default set of properties.  If the telemetry client needs to be
        created to accomplish this, and the required assemblies are not available on the local
        machine, the download status will be presented at the command prompt.

    .EXAMPLE
        Set-TelemetryException $_ -NoStatus

        Used within the context of a catch statement, this will post the exception that just
        occurred, along with a default set of properties.  If the telemetry client needs to be
        created to accomplish this, and the required assemblies are not available on the local
        machine, the command prompt will appear to hang while they are downloaded.

    .NOTES
        Because of the short-running nature of this module, we always "flush" the events as soon
        as they have been posted to ensure that they make it to Application Insights.
#>
    [CmdletBinding(SupportsShouldProcess)]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSShouldProcess", "", Justification="Methods called within here make use of PSShouldProcess, and the switch is passed on to them inherently.")]
    param(
        [Parameter(Mandatory)]
        [System.Exception] $Exception,

        [string] $ErrorBucket,

        [hashtable] $Properties = @{},

        [switch] $NoFlush,

        [switch] $NoStatus
    )

    if (Get-GitHubConfiguration -Name DisableTelemetry)
    {
        Write-Log -Message "Telemetry has been disabled via configuration. Skipping reporting exception." -Level Verbose
        return
    }

    Write-InvocationLog -Invocation $MyInvocation -ExcludeParameter @('Exception', 'Properties', 'NoFlush')

    try
    {
        $telemetryClient = Get-TelemetryClient -NoStatus:$NoStatus

        $propertiesDictionary = New-Object 'System.Collections.Generic.Dictionary[string,string]'
        $propertiesDictionary['Message'] = $Exception.Message
        $propertiesDictionary['HResult'] = "0x{0}" -f [Convert]::ToString($Exception.HResult, 16)
        $Properties.Keys | ForEach-Object { $propertiesDictionary[$_] = $Properties[$_] }

        if (-not [String]::IsNullOrWhiteSpace($ErrorBucket))
        {
            $propertiesDictionary['ErrorBucket'] = $ErrorBucket
        }

        $telemetryClient.TrackException($Exception, $propertiesDictionary);

        # Flushing should increase the chance of success in uploading telemetry logs
        if (-not $NoFlush)
        {
            Flush-TelemetryClient -NoStatus:$NoStatus
        }
    }
    catch
    {
        # Telemetry should be best-effort.  Failures while trying to handle telemetry should not
        # cause exceptions in the app itself.
        Write-Log -Message "Set-TelemetryException failed:" -Exception $_ -Level Error
    }
}

function Flush-TelemetryClient
{
<#
    .SYNOPSIS
        Flushes the buffer of stored telemetry events to the configured Applications Insights instance.

    .DESCRIPTION
        Flushes the buffer of stored telemetry events to the configured Applications Insights instance.

        The Git repo for this module can be found here: http://aka.ms/PowerShellForGitHub

    .PARAMETER NoStatus
        If this switch is specified, long-running commands will run on the main thread
        with no commandline status update.  When not specified, those commands run in
        the background, enabling the command prompt to provide status information.

    .EXAMPLE
        Flush-TelemetryClient

        Attempts to push all buffered telemetry events for this telemetry client immediately to
        Application Insights.  If the telemetry client needs to be created to accomplish this,
        and the required assemblies are not available on the local machine, the download status
        will be presented at the command prompt.

    .EXAMPLE
        Flush-TelemetryClient -NoStatus

        Attempts to push all buffered telemetry events for this telemetry client immediately to
        Application Insights.  If the telemetry client needs to be created to accomplish this,
        and the required assemblies are not available on the local machine, the command prompt
        will appear to hang while they are downloaded.
#>
    [CmdletBinding(SupportsShouldProcess)]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseApprovedVerbs", "", Justification="Internal-only helper method.  Matches the internal method that is called.")]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSShouldProcess", "", Justification="Methods called within here make use of PSShouldProcess, and the switch is passed on to them inherently.")]
    param(
        [switch] $NoStatus
    )

    Write-InvocationLog -Invocation $MyInvocation

    if (Get-GitHubConfiguration -Name DisableTelemetry)
    {
        Write-Log -Message "Telemetry has been disabled via configuration. Skipping flushing of the telemetry client." -Level Verbose
        return
    }

    $telemetryClient = Get-TelemetryClient -NoStatus:$NoStatus

    try
    {
        $telemetryClient.Flush()
    }
    catch [System.Net.WebException]
    {
        Write-Log -Message "Encountered exception while trying to flush telemetry events:" -Exception $_ -Level Warning

        Set-TelemetryException -Exception ($_.Exception) -ErrorBucket "TelemetryFlush" -NoFlush -NoStatus:$NoStatus
    }
    catch
    {
        # Any other scenario is one that we want to identify and fix so that we don't miss telemetry
        Write-Log -Level Warning -Exception $_ -Message @(
            "Encountered a problem while trying to record telemetry events.",
            "This is non-fatal, but it would be helpful if you could report this problem",
            "to the PowerShellForGitHub team for further investigation:")
    }
}
