# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

# The cached location of nuget.exe
$script:nugetExePath = [String]::Empty

# The directory where we'll store the assemblies that we dynamically download during this session.
$script:tempAssemblyCacheDir = [String]::Empty

function Get-NugetExe
{
<#
    .SYNOPSIS
        Downloads nuget.exe from http://nuget.org to a new local temporary directory
        and returns the path to the local copy.

    .DESCRIPTION
        Downloads nuget.exe from http://nuget.org to a new local temporary directory
        and returns the path to the local copy.

        The Git repo for this module can be found here: http://aka.ms/PowerShellForGitHub

    .EXAMPLE
        Get-NugetExe
        Creates a new directory with a GUID under $env:TEMP and then downloads
        http://nuget.org/nuget.exe to that location.

    .OUTPUTS
        System.String - The path to the newly downloaded nuget.exe
#>
    [CmdletBinding(SupportsShouldProcess)]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSShouldProcess", "", Justification="Methods called within here make use of PSShouldProcess, and the switch is passed on to them inherently.")]
    param()

    if ([String]::IsNullOrEmpty($script:nugetExePath))
    {
        $sourceNugetExe = "https://dist.nuget.org/win-x86-commandline/latest/nuget.exe"
        $script:nugetExePath = Join-Path $(New-TemporaryDirectory) "nuget.exe"

        Write-Log -Message "Downloading $sourceNugetExe to $script:nugetExePath" -Level Verbose
        Invoke-WebRequest $sourceNugetExe -OutFile $script:nugetExePath
    }

    return $script:nugetExePath
}

function Get-NugetPackage
{
<#
    .SYNOPSIS
        Downloads a nuget package to the specified directory.

    .DESCRIPTION
        Downloads a nuget package to the specified directory (or the current
        directory if no TargetPath was specified).

        The Git repo for this module can be found here: http://aka.ms/PowerShellForGitHub

    .PARAMETER PackageName
        The name of the nuget package to download

    .PARAMETER TargetPath
        The nuget package will be downloaded to this location.

    .PARAMETER Version
        If provided, this indicates the version of the package to download.
        If not specified, downloads the latest version.

    .PARAMETER NoStatus
        If this switch is specified, long-running commands will run on the main thread
        with no commandline status update.  When not specified, those commands run in
        the background, enabling the command prompt to provide status information.

    .EXAMPLE
        Get-NugetPackage "Microsoft.AzureStorage" -Version "6.0.0.0" -TargetPath "c:\foo"
        Downloads v6.0.0.0 of the Microsoft.AzureStorage nuget package to the c:\foo directory.

    .EXAMPLE
        Get-NugetPackage "Microsoft.AzureStorage" "c:\foo"
        Downloads the most recent version of the Microsoft.AzureStorage
        nuget package to the c:\foo directory.
#>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(
            Mandatory,
            ValueFromPipeline)]
        [string] $PackageName,

        [Parameter(Mandatory)]
        [ValidateScript({if (Test-Path -Path $_ -PathType Container) { $true } else { throw "$_ does not exist." }})]
        [string] $TargetPath,

        [string] $Version,

        [switch] $NoStatus
    )

    Write-Log -Message "Downloading nuget package [$PackageName] to [$TargetPath]" -Level Verbose

    $nugetPath = Get-NugetExe

    if ($NoStatus)
    {
        if ($PSCmdlet.ShouldProcess($PackageName, $nugetPath))
        {
            if (-not [System.String]::IsNullOrEmpty($Version))
            {
                & $nugetPath install $PackageName -o $TargetPath -version $Version -source nuget.org -NonInteractive | Out-Null
            }
            else
            {
                & $nugetPath install $PackageName -o $TargetPath -source nuget.org -NonInteractive | Out-Null
            }
        }
    }
    else
    {
        $jobName = "Get-NugetPackage-" + (Get-Date).ToFileTime().ToString()

        if ($PSCmdlet.ShouldProcess($jobName, "Start-Job"))
        {
            [scriptblock]$scriptBlock = {
                param($NugetPath, $PackageName, $TargetPath, $Version)

                if (-not [System.String]::IsNullOrEmpty($Version))
                {
                    & $NugetPath install $PackageName -o $TargetPath -version $Version -source nuget.org
                }
                else
                {
                    & $NugetPath install $PackageName -o $TargetPath -source nuget.org
                }
            }

            Start-Job -Name $jobName -ScriptBlock $scriptBlock -Arg @($nugetPath, $PackageName, $TargetPath, $Version) | Out-Null

            if ($PSCmdlet.ShouldProcess($jobName, "Wait-JobWithAnimation"))
            {
                Wait-JobWithAnimation -Name $jobName -Description "Retrieving nuget package: $PackageName"
            }

            if ($PSCmdlet.ShouldProcess($jobName, "Receive-Job"))
            {
                Receive-Job $jobName -AutoRemoveJob -Wait -ErrorAction SilentlyContinue -ErrorVariable remoteErrors | Out-Null
            }
        }

        if ($remoteErrors.Count -gt 0)
        {
            throw $remoteErrors[0].Exception
        }
    }
}

function Test-AssemblyIsDesiredVersion
{
    <#
    .SYNOPSIS
        Checks if the specified file is the expected version.

    .DESCRIPTION
        Checks if the specified file is the expected version.

        Does a best effort match.  If you only specify a desired version of "6",
        any version of the file that has a "major" version of 6 will be considered
        a match, where we use the terminology of a version being:
        Major.Minor.Build.PrivateInfo.

        The Git repo for this module can be found here: http://aka.ms/PowerShellForGitHub

    .PARAMETER AssemblyPath
        The full path to the assembly file being tested.

    .PARAMETER DesiredVersion
        The desired version of the assembly.  Specify the version as specifically as
        necessary.

    .EXAMPLE
        Test-AssemblyIsDesiredVersion "c:\Microsoft.WindowsAzure.Storage.dll" "6"

        Returns back $true if "c:\Microsoft.WindowsAzure.Storage.dll" has a major version
        of 6, regardless of its Minor, Build or PrivateInfo numbers.

    .OUTPUTS
        Boolean - $true if the assembly at the specified path exists and meets the specified
        version criteria, $false otherwise.
#>
    param(
        [Parameter(Mandatory)]
        [ValidateScript( { if (Test-Path -PathType Leaf -Path $_) { $true }  else { throw "'$_' cannot be found." } })]
        [string] $AssemblyPath,

        [Parameter(Mandatory)]
        [ValidateScript( { if ($_ -match '^\d+(\.\d+){0,3}$') { $true } else { throw "'$_' not a valid version format." } })]
        [string] $DesiredVersion
    )

    $splitTargetVer = $DesiredVersion.Split('.')

    $file = Get-Item -Path $AssemblyPath -ErrorVariable ev
    if (($null -ne $ev) -and ($ev.Count -gt 0))
    {
        Write-Log "Problem accessing [$Path]: $($ev[0].Exception.Message)" -Level Warning
        return $false
    }

    $versionInfo = $file.VersionInfo
    $splitSourceVer = @(
        $versionInfo.ProductMajorPart,
        $versionInfo.ProductMinorPart,
        $versionInfo.ProductBuildPart,
        $versionInfo.ProductPrivatePart
    )

    # The cmdlet contract states that we only care about matching
    # as much of the version number as the user has supplied.
    for ($i = 0; $i -lt $splitTargetVer.Count; $i++)
    {
        if ($splitSourceVer[$i] -ne $splitTargetVer[$i])
        {
            return $false
        }
    }

    return $true
}

function Get-NugetPackageDllPath
{
<#
    .SYNOPSIS
        Makes sure that the specified assembly from a nuget package is available
        on the machine, and returns the path to it.

    .DESCRIPTION
        Makes sure that the specified assembly from a nuget package is available
        on the machine, and returns the path to it.

        This will first look for the assembly in the module's script directory.

        Next it will look for the assembly in the location defined by the configuration
        property AssemblyPath.

        If not found there, it will look in a temp folder established during this
        PowerShell session.

        If still not found, it will download the nuget package
        for it to a temp folder accessible during this PowerShell session.

        The Git repo for this module can be found here: http://aka.ms/PowerShellForGitHub

    .PARAMETER NugetPackageName
        The name of the nuget package to download

    .PARAMETER NugetPackageVersion
        Indicates the version of the package to download.

    .PARAMETER AssemblyPackageTailDirectory
        The sub-path within the nuget package download location where the assembly should be found.

    .PARAMETER AssemblyName
        The name of the actual assembly that the user is looking for.

    .PARAMETER NoStatus
        If this switch is specified, long-running commands will run on the main thread
        with no commandline status update.  When not specified, those commands run in
        the background, enabling the command prompt to provide status information.

    .EXAMPLE
        Get-NugetPackageDllPath "WindowsAzure.Storage" "6.0.0" "WindowsAzure.Storage.6.0.0\lib\net40\" "Microsoft.WindowsAzure.Storage.dll"

        Returns back the path to "Microsoft.WindowsAzure.Storage.dll", which is part of the
        "WindowsAzure.Storage" nuget package.  If the package has to be downloaded via nuget,
        the command prompt will show a time duration status counter while the package is being
        downloaded.

    .EXAMPLE
        Get-NugetPackageDllPath "WindowsAzure.Storage" "6.0.0" "WindowsAzure.Storage.6.0.0\lib\net40\" "Microsoft.WindowsAzure.Storage.dll" -NoStatus

        Returns back the path to "Microsoft.WindowsAzure.Storage.dll", which is part of the
        "WindowsAzure.Storage" nuget package.  If the package has to be downloaded via nuget,
        the command prompt will appear to hang during this time.

    .OUTPUTS
        System.String - The full path to $AssemblyName.
#>
    [CmdletBinding(SupportsShouldProcess)]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSShouldProcess", "", Justification="Methods called within here make use of PSShouldProcess, and the switch is passed on to them inherently.")]
    param(
        [Parameter(Mandatory)]
        [string] $NugetPackageName,

        [Parameter(Mandatory)]
        [string] $NugetPackageVersion,

        [Parameter(Mandatory)]
        [string] $AssemblyPackageTailDirectory,

        [Parameter(Mandatory)]
        [string] $AssemblyName,

        [switch] $NoStatus
    )

    Write-Log -Message "Looking for $AssemblyName" -Level Verbose

    # First we'll check to see if the user has cached the assembly into the module's script directory
    $moduleAssembly = Join-Path -Path $PSScriptRoot -ChildPath $AssemblyName
    if (Test-Path -Path $moduleAssembly -PathType Leaf -ErrorAction Ignore)
    {
        if (Test-AssemblyIsDesiredVersion -AssemblyPath $moduleAssembly -DesiredVersion $NugetPackageVersion)
        {
            Write-Log -Message "Found $AssemblyName in module directory ($PSScriptRoot)." -Level Verbose
            return $moduleAssembly
        }
        else
        {
            Write-Log -Message "Found $AssemblyName in module directory ($PSScriptRoot), but its version number [$moduleAssembly] didn't match required [$NugetPackageVersion]." -Level Verbose
        }
    }

    # Next, we'll check to see if the user has defined an alternate path to get the assembly from
    $alternateAssemblyPath = Get-GitHubConfiguration -Name AssemblyPath
    if (-not [System.String]::IsNullOrEmpty($alternateAssemblyPath))
    {
        $assemblyPath = Join-Path -Path $alternateAssemblyPath -ChildPath $AssemblyName
        if (Test-Path -Path $assemblyPath -PathType Leaf -ErrorAction Ignore)
        {
            if (Test-AssemblyIsDesiredVersion -AssemblyPath $assemblyPath -DesiredVersion $NugetPackageVersion)
            {
                Write-Log -Message "Found $AssemblyName in alternate directory ($alternateAssemblyPath)." -Level Verbose
                return $assemblyPath
            }
            else
            {
                Write-Log -Message "Found $AssemblyName in alternate directory ($alternateAssemblyPath), but its version number [$moduleAssembly] didn't match required [$NugetPackageVersion]." -Level Verbose
            }
        }
    }

    # Then we'll check to see if we've previously cached the assembly in a temp folder during this PowerShell session
    if ([System.String]::IsNullOrEmpty($script:tempAssemblyCacheDir))
    {
        $script:tempAssemblyCacheDir = New-TemporaryDirectory
    }
    else
    {
        $cachedAssemblyPath = Join-Path -Path $(Join-Path $script:tempAssemblyCacheDir $AssemblyPackageTailDirectory) $AssemblyName
        if (Test-Path -Path $cachedAssemblyPath -PathType Leaf -ErrorAction Ignore)
        {
            if (Test-AssemblyIsDesiredVersion -AssemblyPath $cachedAssemblyPath -DesiredVersion $NugetPackageVersion)
            {
                Write-Log -Message "Found $AssemblyName in temp directory ($script:tempAssemblyCacheDir)." -Level Verbose
                return $cachedAssemblyPath
            }
            else
            {
                Write-Log -Message "Found $AssemblyName in temp directory ($script:tempAssemblyCacheDir), but its version number [$moduleAssembly] didn't match required [$NugetPackageVersion]." -Level Verbose
            }
        }
    }

    # Still not found, so we'll go ahead and download the package via nuget.
    Write-Log -Message "$AssemblyName is needed and wasn't found.  Acquiring it via nuget..." -Level Verbose
    Get-NugetPackage -PackageName $NugetPackageName -Version $NugetPackageVersion -TargetPath $script:tempAssemblyCacheDir -NoStatus:$NoStatus

    $cachedAssemblyPath = Join-Path -Path $(Join-Path -Path $script:tempAssemblyCacheDir -ChildPath $AssemblyPackageTailDirectory) -ChildPath $AssemblyName
    if (Test-Path -Path $cachedAssemblyPath -PathType Leaf -ErrorAction Ignore)
    {
        Write-Log -Message @(
            "To avoid this download delay in the future, copy the following file:",
            "  [$cachedAssemblyPath]",
            "either to:",
            "  [$PSScriptRoot]",
            "or to:",
            "  a directory of your choosing, and store that directory as 'AssemblyPath' with 'Set-GitHubConfiguration'")

        return $cachedAssemblyPath
    }

    $message = "Unable to acquire a reference to $AssemblyName."
    Write-Log -Message $message -Level Error
    throw $message
}

# SIG # Begin signature block
# MIIdkgYJKoZIhvcNAQcCoIIdgzCCHX8CAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUxmQ/i4isjYAlN+/k//zOOXes
# RpegghhuMIIE2jCCA8KgAwIBAgITMwAAAQdjpRkqESfl2QAAAAABBzANBgkqhkiG
# 9w0BAQUFADB3MQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4G
# A1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSEw
# HwYDVQQDExhNaWNyb3NvZnQgVGltZS1TdGFtcCBQQ0EwHhcNMTgwODIzMjAyMDI2
# WhcNMTkxMTIzMjAyMDI2WjCByjELMAkGA1UEBhMCVVMxCzAJBgNVBAgTAldBMRAw
# DgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24x
# LTArBgNVBAsTJE1pY3Jvc29mdCBJcmVsYW5kIE9wZXJhdGlvbnMgTGltaXRlZDEm
# MCQGA1UECxMdVGhhbGVzIFRTUyBFU046QUI0MS00QjI3LUYwMjYxJTAjBgNVBAMT
# HE1pY3Jvc29mdCBUaW1lLVN0YW1wIHNlcnZpY2UwggEiMA0GCSqGSIb3DQEBAQUA
# A4IBDwAwggEKAoIBAQCx4jFPYPLORcJ9TE+rvtOh7IQ4/db/zAzVBmzhKIcvrg0l
# fI61buwA3740F66FFMqxZgMedFov74GNlZ/7y6eIiy1pVdQown+yA+EnB8lEVvKE
# H0J1xReHlQAJr11l/zzjHux30VkA/BBOLfe9uZ+CLAP8F1Wt/aZAkTuxC4rdYSJt
# WGcTyiSyR50fPLtEZqyihPi7g/dJB7R4BCCL/pO7trsI/AA98LSHcOydoGmO852f
# KgtAEV0NbZyVphn+c/5H3qPHcifpB/D47n43wUXkjgrqLlgqdm1Op8fuTNlrHoRV
# 1NBfB8v/zK7RrYP4oVEztN29akvlxUzl062e/oGLAgMBAAGjggEJMIIBBTAdBgNV
# HQ4EFgQUj3Lnp1uB5EjhiEY9QThjCuJYBoowHwYDVR0jBBgwFoAUIzT42VJGcArt
# QPt2+7MrsMM1sw8wVAYDVR0fBE0wSzBJoEegRYZDaHR0cDovL2NybC5taWNyb3Nv
# ZnQuY29tL3BraS9jcmwvcHJvZHVjdHMvTWljcm9zb2Z0VGltZVN0YW1wUENBLmNy
# bDBYBggrBgEFBQcBAQRMMEowSAYIKwYBBQUHMAKGPGh0dHA6Ly93d3cubWljcm9z
# b2Z0LmNvbS9wa2kvY2VydHMvTWljcm9zb2Z0VGltZVN0YW1wUENBLmNydDATBgNV
# HSUEDDAKBggrBgEFBQcDCDANBgkqhkiG9w0BAQUFAAOCAQEAVTCQ9vD8tkOVyPlU
# Na4Y3EfCkpzjliJMKA0uaRy2igxvK4KWoIUTMi4l+fgiVU6ugnn9/meg+COBw2M6
# XmX/+2j57RQgYXcTK5McXlszt3tzvSp2age1sOKPNtfzdxzUgDl1Sh4a8KZf82nJ
# 5mbWe41sVDIHSCSUftMZG+3a8w98HIp7J/upmmpD+K4n/uaYB+UmIWVusJkD9Afv
# IrJAjXWCIYxbIjKnzOMy5JMCoZYGY5npi7u99/Ku/WvsJWtjRC2UxZvMSA5B2YEv
# xvFpKv9qCzbmv/C9fbyhEFO2aLoKpwx97B7PxC50Y9dVtPg6TRWOEeGEopv24YLw
# sBIGlDCCBgMwggProAMCAQICEzMAAAEEaeLbufuKDYMAAAAAAQQwDQYJKoZIhvcN
# AQELBQAwfjELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNV
# BAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEoMCYG
# A1UEAxMfTWljcm9zb2Z0IENvZGUgU2lnbmluZyBQQ0EgMjAxMTAeFw0xODA3MTIy
# MDA4NDlaFw0xOTA3MjYyMDA4NDlaMHQxCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpX
# YXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3NvZnQg
# Q29ycG9yYXRpb24xHjAcBgNVBAMTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjCCASIw
# DQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBAJvFlfKX9v8jamydc1lzOJvTtOOE
# rY24PiXnoLggWkqRcDjYFKi9msD9DWse7OH8/wQ84mFgrlVqYZL71wB9nuppNtb9
# V3kZl/6EkfbHVa2mrgKK7bGRR1bNSodmRacwGxrtrHtrBdIzgnO+xm8czNToGgUV
# AC6Rl7ZLyGFnIovnExJowhcUryZatu5Vc3z1RLMhJwYA67U2+fwmiq0/f0QUw3q7
# I8iL3r4WisEhogIB2X+YkuIxU4+HsZAkmxf6FU3KAWwQbFICopNfYgNBJIxwp3As
# jUsv1zNZXP1d4D/X5IQXu30+edOCQ2JUQMibXs9wFDtgPGk/nzfn+BaSM4sCAwEA
# AaOCAYIwggF+MB8GA1UdJQQYMBYGCisGAQQBgjdMCAEGCCsGAQUFBwMDMB0GA1Ud
# DgQWBBS6F+MlaPS71Xsjpri2fOemgqtXrjBUBgNVHREETTBLpEkwRzEtMCsGA1UE
# CxMkTWljcm9zb2Z0IElyZWxhbmQgT3BlcmF0aW9ucyBMaW1pdGVkMRYwFAYDVQQF
# Ew0yMzAwMTIrNDM3OTY2MB8GA1UdIwQYMBaAFEhuZOVQBdOCqhc3NyK1bajKdQKV
# MFQGA1UdHwRNMEswSaBHoEWGQ2h0dHA6Ly93d3cubWljcm9zb2Z0LmNvbS9wa2lv
# cHMvY3JsL01pY0NvZFNpZ1BDQTIwMTFfMjAxMS0wNy0wOC5jcmwwYQYIKwYBBQUH
# AQEEVTBTMFEGCCsGAQUFBzAChkVodHRwOi8vd3d3Lm1pY3Jvc29mdC5jb20vcGtp
# b3BzL2NlcnRzL01pY0NvZFNpZ1BDQTIwMTFfMjAxMS0wNy0wOC5jcnQwDAYDVR0T
# AQH/BAIwADANBgkqhkiG9w0BAQsFAAOCAgEAKcWCCzmZIAzoJFuJOzhQkoOV25Hy
# O9Kk8NqBW3OOZ0gatsmKB3labM7D/GaYF7K716YWtQNWhXsqfS9ABk6eaddpFBWO
# Y/vMgPXbEZxQ7ksCcUxrBwX+Z1PxGbZubizyj9RFKeE2CLIceIEnloeZQhh3lNzG
# vJ2k21amNtBDSF9ABH5n6YjYAMfrMv/eCndgA3P+nqHHHfPAsy1hh8jxN4Xc/G08
# SxNKEna1UEpN513zTyHkmBKBgf7pXKj8FIzRAp9l+3Z1t2JTx33ax7pC4m57Jkoj
# gjLYjXUeEW+Lf3oG1aofGKVwE+fuaJ0HvAbpiQOWDGriIaslA9i3ARHhxCKWKTF8
# w1VO0BznRcZmAIoVIcTFAXAd4mgBOQ8iIcmoc39w2Cz09WnlSWw5paKpyns51fl3
# bzBzg5bAo4uu5X/dY03aFct7+R3ljsQ6qkr0LUVmn/JeuEkXOePfHUmJYYu6M69e
# Quoa1PVRU/GlXZKbh2e4dqsGVeGu1YOvOf8gMYtc5vq1B8+GJ8dBAiM5bVlOLsB4
# rzpJY2zieOAjdtQrqGcAPGVSWDDSeOl47e27KX2iHzjl7FnHk5lF+QCIykR6R9Ym
# R83UCcK1epAMPRYWfreU20ZSAEoeuT1pyVFlatU/EcQtN5dfksINMQya1ll38FBI
# h4l2k9jzfUqwItgwggYHMIID76ADAgECAgphFmg0AAAAAAAcMA0GCSqGSIb3DQEB
# BQUAMF8xEzARBgoJkiaJk/IsZAEZFgNjb20xGTAXBgoJkiaJk/IsZAEZFgltaWNy
# b3NvZnQxLTArBgNVBAMTJE1pY3Jvc29mdCBSb290IENlcnRpZmljYXRlIEF1dGhv
# cml0eTAeFw0wNzA0MDMxMjUzMDlaFw0yMTA0MDMxMzAzMDlaMHcxCzAJBgNVBAYT
# AlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYD
# VQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xITAfBgNVBAMTGE1pY3Jvc29mdCBU
# aW1lLVN0YW1wIFBDQTCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBAJ+h
# bLHf20iSKnxrLhnhveLjxZlRI1Ctzt0YTiQP7tGn0UytdDAgEesH1VSVFUmUG0KS
# rphcMCbaAGvoe73siQcP9w4EmPCJzB/LMySHnfL0Zxws/HvniB3q506jocEjU8qN
# +kXPCdBer9CwQgSi+aZsk2fXKNxGU7CG0OUoRi4nrIZPVVIM5AMs+2qQkDBuh/NZ
# MJ36ftaXs+ghl3740hPzCLdTbVK0RZCfSABKR2YRJylmqJfk0waBSqL5hKcRRxQJ
# gp+E7VV4/gGaHVAIhQAQMEbtt94jRrvELVSfrx54QTF3zJvfO4OToWECtR0Nsfz3
# m7IBziJLVP/5BcPCIAsCAwEAAaOCAaswggGnMA8GA1UdEwEB/wQFMAMBAf8wHQYD
# VR0OBBYEFCM0+NlSRnAK7UD7dvuzK7DDNbMPMAsGA1UdDwQEAwIBhjAQBgkrBgEE
# AYI3FQEEAwIBADCBmAYDVR0jBIGQMIGNgBQOrIJgQFYnl+UlE/wq4QpTlVnkpKFj
# pGEwXzETMBEGCgmSJomT8ixkARkWA2NvbTEZMBcGCgmSJomT8ixkARkWCW1pY3Jv
# c29mdDEtMCsGA1UEAxMkTWljcm9zb2Z0IFJvb3QgQ2VydGlmaWNhdGUgQXV0aG9y
# aXR5ghB5rRahSqClrUxzWPQHEy5lMFAGA1UdHwRJMEcwRaBDoEGGP2h0dHA6Ly9j
# cmwubWljcm9zb2Z0LmNvbS9wa2kvY3JsL3Byb2R1Y3RzL21pY3Jvc29mdHJvb3Rj
# ZXJ0LmNybDBUBggrBgEFBQcBAQRIMEYwRAYIKwYBBQUHMAKGOGh0dHA6Ly93d3cu
# bWljcm9zb2Z0LmNvbS9wa2kvY2VydHMvTWljcm9zb2Z0Um9vdENlcnQuY3J0MBMG
# A1UdJQQMMAoGCCsGAQUFBwMIMA0GCSqGSIb3DQEBBQUAA4ICAQAQl4rDXANENt3p
# tK132855UU0BsS50cVttDBOrzr57j7gu1BKijG1iuFcCy04gE1CZ3XpA4le7r1ia
# HOEdAYasu3jyi9DsOwHu4r6PCgXIjUji8FMV3U+rkuTnjWrVgMHmlPIGL4UD6ZEq
# JCJw+/b85HiZLg33B+JwvBhOnY5rCnKVuKE5nGctxVEO6mJcPxaYiyA/4gcaMvnM
# MUp2MT0rcgvI6nA9/4UKE9/CCmGO8Ne4F+tOi3/FNSteo7/rvH0LQnvUU3Ih7jDK
# u3hlXFsBFwoUDtLaFJj1PLlmWLMtL+f5hYbMUVbonXCUbKw5TNT2eb+qGHpiKe+i
# myk0BncaYsk9Hm0fgvALxyy7z0Oz5fnsfbXjpKh0NbhOxXEjEiZ2CzxSjHFaRkMU
# vLOzsE1nyJ9C/4B5IYCeFTBm6EISXhrIniIh0EPpK+m79EjMLNTYMoBMJipIJF9a
# 6lbvpt6Znco6b72BJ3QGEe52Ib+bgsEnVLaxaj2JoXZhtG6hE6a/qkfwEm/9ijJs
# sv7fUciMI8lmvZ0dhxJkAj0tr1mPuOQh5bWwymO0eFQF1EEuUKyUsKV4q7OglnUa
# 2ZKHE3UiLzKoCG6gW4wlv6DvhMoh1useT8ma7kng9wFlb4kLfchpyOZu6qeXzjEp
# /w7FW1zYTRuh2Povnj8uVRZryROj/TCCB3owggVioAMCAQICCmEOkNIAAAAAAAMw
# DQYJKoZIhvcNAQELBQAwgYgxCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5n
# dG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9y
# YXRpb24xMjAwBgNVBAMTKU1pY3Jvc29mdCBSb290IENlcnRpZmljYXRlIEF1dGhv
# cml0eSAyMDExMB4XDTExMDcwODIwNTkwOVoXDTI2MDcwODIxMDkwOVowfjELMAkG
# A1UEBhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQx
# HjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEoMCYGA1UEAxMfTWljcm9z
# b2Z0IENvZGUgU2lnbmluZyBQQ0EgMjAxMTCCAiIwDQYJKoZIhvcNAQEBBQADggIP
# ADCCAgoCggIBAKvw+nIQHC6t2G6qghBNNLrytlghn0IbKmvpWlCquAY4GgRJun/D
# DB7dN2vGEtgL8DjCmQawyDnVARQxQtOJDXlkh36UYCRsr55JnOloXtLfm1OyCizD
# r9mpK656Ca/XllnKYBoF6WZ26DJSJhIv56sIUM+zRLdd2MQuA3WraPPLbfM6XKEW
# 9Ea64DhkrG5kNXimoGMPLdNAk/jj3gcN1Vx5pUkp5w2+oBN3vpQ97/vjK1oQH01W
# KKJ6cuASOrdJXtjt7UORg9l7snuGG9k+sYxd6IlPhBryoS9Z5JA7La4zWMW3Pv4y
# 07MDPbGyr5I4ftKdgCz1TlaRITUlwzluZH9TupwPrRkjhMv0ugOGjfdf8NBSv4yU
# h7zAIXQlXxgotswnKDglmDlKNs98sZKuHCOnqWbsYR9q4ShJnV+I4iVd0yFLPlLE
# tVc/JAPw0XpbL9Uj43BdD1FGd7P4AOG8rAKCX9vAFbO9G9RVS+c5oQ/pI0m8GLhE
# fEXkwcNyeuBy5yTfv0aZxe/CHFfbg43sTUkwp6uO3+xbn6/83bBm4sGXgXvt1u1L
# 50kppxMopqd9Z4DmimJ4X7IvhNdXnFy/dygo8e1twyiPLI9AN0/B4YVEicQJTMXU
# pUMvdJX3bvh4IFgsE11glZo+TzOE2rCIF96eTvSWsLxGoGyY0uDWiIwLAgMBAAGj
# ggHtMIIB6TAQBgkrBgEEAYI3FQEEAwIBADAdBgNVHQ4EFgQUSG5k5VAF04KqFzc3
# IrVtqMp1ApUwGQYJKwYBBAGCNxQCBAweCgBTAHUAYgBDAEEwCwYDVR0PBAQDAgGG
# MA8GA1UdEwEB/wQFMAMBAf8wHwYDVR0jBBgwFoAUci06AjGQQ7kUBU7h6qfHMdEj
# iTQwWgYDVR0fBFMwUTBPoE2gS4ZJaHR0cDovL2NybC5taWNyb3NvZnQuY29tL3Br
# aS9jcmwvcHJvZHVjdHMvTWljUm9vQ2VyQXV0MjAxMV8yMDExXzAzXzIyLmNybDBe
# BggrBgEFBQcBAQRSMFAwTgYIKwYBBQUHMAKGQmh0dHA6Ly93d3cubWljcm9zb2Z0
# LmNvbS9wa2kvY2VydHMvTWljUm9vQ2VyQXV0MjAxMV8yMDExXzAzXzIyLmNydDCB
# nwYDVR0gBIGXMIGUMIGRBgkrBgEEAYI3LgMwgYMwPwYIKwYBBQUHAgEWM2h0dHA6
# Ly93d3cubWljcm9zb2Z0LmNvbS9wa2lvcHMvZG9jcy9wcmltYXJ5Y3BzLmh0bTBA
# BggrBgEFBQcCAjA0HjIgHQBMAGUAZwBhAGwAXwBwAG8AbABpAGMAeQBfAHMAdABh
# AHQAZQBtAGUAbgB0AC4gHTANBgkqhkiG9w0BAQsFAAOCAgEAZ/KGpZjgVHkaLtPY
# dGcimwuWEeFjkplCln3SeQyQwWVfLiw++MNy0W2D/r4/6ArKO79HqaPzadtjvyI1
# pZddZYSQfYtGUFXYDJJ80hpLHPM8QotS0LD9a+M+By4pm+Y9G6XUtR13lDni6WTJ
# RD14eiPzE32mkHSDjfTLJgJGKsKKELukqQUMm+1o+mgulaAqPyprWEljHwlpblqY
# luSD9MCP80Yr3vw70L01724lruWvJ+3Q3fMOr5kol5hNDj0L8giJ1h/DMhji8MUt
# zluetEk5CsYKwsatruWy2dsViFFFWDgycScaf7H0J/jeLDogaZiyWYlobm+nt3TD
# QAUGpgEqKD6CPxNNZgvAs0314Y9/HG8VfUWnduVAKmWjw11SYobDHWM2l4bf2vP4
# 8hahmifhzaWX0O5dY0HjWwechz4GdwbRBrF1HxS+YWG18NzGGwS+30HHDiju3mUv
# 7Jf2oVyW2ADWoUa9WfOXpQlLSBCZgB/QACnFsZulP0V3HjXG0qKin3p6IvpIlR+r
# +0cjgPWe+L9rt0uX4ut1eBrs6jeZeRhL/9azI2h15q/6/IvrC4DqaTuv/DDtBEyO
# 3991bWORPdGdVk5Pv4BXIqF4ETIheu9BCrE/+6jMpF3BoYibV3FWTkhFwELJm3Zb
# CoBIa/15n8G9bW1qyVJzEw16UM0xggSOMIIEigIBATCBlTB+MQswCQYDVQQGEwJV
# UzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UE
# ChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSgwJgYDVQQDEx9NaWNyb3NvZnQgQ29k
# ZSBTaWduaW5nIFBDQSAyMDExAhMzAAABBGni27n7ig2DAAAAAAEEMAkGBSsOAwIa
# BQCggaIwGQYJKoZIhvcNAQkDMQwGCisGAQQBgjcCAQQwHAYKKwYBBAGCNwIBCzEO
# MAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFGDaDxtKLIbBc/yfNg16Ep4a
# ZwF7MEIGCisGAQQBgjcCAQwxNDAyoBSAEgBNAGkAYwByAG8AcwBvAGYAdKEagBho
# dHRwOi8vd3d3Lm1pY3Jvc29mdC5jb20wDQYJKoZIhvcNAQEBBQAEggEAhwoKm/LH
# id4GYUxvFOM6LeWWdJ+61n4+3ueI1n38eaVBnhSYLiehkCzTQjGlRZE/lvu1wM7A
# cAcFLDOL2DYKIpZsmlrXeWFN9FO2jkOoJU97FYeg1Irqhhxsz7ypP+pBTLNqifGR
# DegExnbgnateksHcgjawUvI8Xge2CHY0DuNpHXXq8YFr9NgZgZWEUBqkrSPHxlTG
# E3LzF6+kgY9UlKw80CGd7yuA1gMTWu4VrFi2tunp3GTrpLmd4NFDmbz5vm9ENcgk
# yYzjrQGUyagYAyrsWzwy7180cvlvGtXANQpRQbOXHcOATYJNFqrs4G94e66lvNWC
# PmHsqGwZdubBuaGCAigwggIkBgkqhkiG9w0BCQYxggIVMIICEQIBATCBjjB3MQsw
# CQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9u
# ZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSEwHwYDVQQDExhNaWNy
# b3NvZnQgVGltZS1TdGFtcCBQQ0ECEzMAAAEHY6UZKhEn5dkAAAAAAQcwCQYFKw4D
# AhoFAKBdMBgGCSqGSIb3DQEJAzELBgkqhkiG9w0BBwEwHAYJKoZIhvcNAQkFMQ8X
# DTE5MDEwNzE3Mjk0NFowIwYJKoZIhvcNAQkEMRYEFIiz1MlM23HUgXBhbEyvvr7x
# lP6CMA0GCSqGSIb3DQEBBQUABIIBAC38tuscM1hIdcQouwGvBUIgCM08ZtHtXm0m
# 0AskmWi9VooU+CcWcsteeoq4UjecfbVeO0ew4UgGC0TfEMqfDFzHjBhpNhPCtrsC
# g2fdl7eSS3agCilg4SHT736VRVEm2V530Qdx5QZmojAMAvzfUAmz0rmcOnWq2d5i
# iM62SmmeYkyGGNfK92ZQMULptwaJ6MEYxJt0XS3o51CePyLmdZkHg9t2pham9oPp
# 1ggbXs+Jre5PwMZCNRYkF1cMqK7jtBuKPz7TEklFbTidZqVYJjT/kbKkjn67a/as
# cQedY3mwH64VAhjoeHgxTfGwyMzkyo2ILp0BBBrUZmzawrvgKXo=
# SIG # End signature block
