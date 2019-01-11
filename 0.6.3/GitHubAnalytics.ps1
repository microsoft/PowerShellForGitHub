# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

function Group-GitHubIssue
{
<#
    .SYNOPSIS
        Groups the provided issues based on the specified grouping criteria.

    .DESCRIPTION
        Groups the provided issues based on the specified grouping criteria.

        Currently able to group Issues by week.

        The Git repo for this module can be found here: http://aka.ms/PowerShellForGitHub

    .PARAMETER Issue
        The Issue(s) to be grouped.

    .PARAMETER Weeks
        The number of weeks to group the Issues by.

    .PARAMETER DateType
        The date property that should be inspected when determining which week grouping the issue
        if part of.

    .OUTPUTS
        [PSCustomObject[]] Collection of issues and counts, by week, along with the total count of issues.

    .EXAMPLE
        $issues = @()
        $issues += Get-GitHubIssue -Uri 'https://github.com/powershell/xpsdesiredstateconfiguration'
        $issues += Get-GitHubIssue -Uri 'https://github.com/powershell/xactivedirectory'
        $issues | Group-GitHubIssue -Weeks 12 -DateType Closed
#>
    [CmdletBinding(
        SupportsShouldProcess,
        DefaultParametersetName='Weekly')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSShouldProcess", "", Justification="Methods called within here make use of PSShouldProcess, and the switch is passed on to them inherently.")]
    param
    (
        [Parameter(
            Mandatory,
            ValueFromPipeline)]
        [PSCustomObject[]] $Issue,

        [Parameter(
            Mandatory,
            ParameterSetName='Weekly')]
        [ValidateRange(0, 10000)]
        [int] $Weeks,

        [Parameter(ParameterSetName='Weekly')]
        [ValidateSet('Created', 'Closed')]
        [string] $DateType = 'Created'
    )

    Write-InvocationLog

    if ($PSCmdlet.ParameterSetName -eq 'Weekly')
    {
        $totalIssues = 0
        $weekDates = Get-WeekDate -Weeks $Weeks
        $endOfWeek = Get-Date

        foreach ($week in $weekDates)
        {
            $filteredIssues = @($Issue | Where-Object {
                (($DateType -eq 'Created') -and ($_.created_at -ge $week) -and ($_.created_at -le $endOfWeek)) -or
                (($DateType -eq 'Closed') -and ($_.closed_at -ge $week) -and ($_.closed_at -le $endOfWeek))
            })

            $endOfWeek = $week
            $count = $filteredIssues.Count
            $totalIssues += $count

            Write-Output -InputObject ([PSCustomObject]([ordered]@{
                'WeekStart' = $week
                'Count' = $count
                'Issues' = $filteredIssues
            }))
        }

        Write-Output -InputObject ([PSCustomObject]([ordered]@{
            'WeekStart' = 'total'
            'Count' = $totalIssues
            'Issues' = $Issue
        }))
    }
    else
    {
        Write-Output -InputObject $Issue
    }
}

function Group-GitHubPullRequest
{
<#
    .SYNOPSIS
        Groups the provided pull requests based on the specified grouping criteria.

    .DESCRIPTION
        Groups the provided pull requests based on the specified grouping criteria.

        Currently able to group Pull Requests by week.

        The Git repo for this module can be found here: http://aka.ms/PowerShellForGitHub

    .PARAMETER PullRequest
        The Pull Requests(s) to be grouped.

    .PARAMETER Weeks
        The number of weeks to group the Pull Requests by.

    .PARAMETER DateType
        The date property that should be inspected when determining which week grouping the
        pull request if part of.

    .OUTPUTS
        [PSCustomObject[]] Collection of pull requests and counts, by week, along with the
        total count of pull requests.

    .EXAMPLE
        $pullRequests = @()
        $pullRequests += Get-GitHubPullRequest -Uri 'https://github.com/powershell/xpsdesiredstateconfiguration'
        $pullRequests += Get-GitHubPullRequest -Uri 'https://github.com/powershell/xactivedirectory'
        $pullRequests | Group-GitHubPullRequest -Weeks 12 -DateType Closed
#>
    [CmdletBinding(
        SupportsShouldProcess,
        DefaultParametersetName='Weekly')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSShouldProcess", "", Justification="Methods called within here make use of PSShouldProcess, and the switch is passed on to them inherently.")]
    param
    (
        [Parameter(
            Mandatory,
            ValueFromPipeline)]
        [PSCustomObject[]] $PullRequest,

        [Parameter(
            Mandatory,
            ParameterSetName='Weekly')]
        [ValidateRange(0, 10000)]
        [int] $Weeks,

        [Parameter(ParameterSetName='Weekly')]
        [ValidateSet('Created', 'Merged')]
        [string] $DateType = 'Created'
    )

    Write-InvocationLog

    if ($PSCmdlet.ParameterSetName -eq 'Weekly')
    {
        $totalPullRequests = 0
        $weekDates = Get-WeekDate -Weeks $Weeks
        $endOfWeek = Get-Date

        foreach ($week in $weekDates)
        {
            $filteredPullRequests = @($PullRequest | Where-Object {
                (($DateType -eq 'Created') -and ($_.created_at -ge $week) -and ($_.created_at -le $endOfWeek)) -or
                (($DateType -eq 'Merged') -and ($_.merged_at -ge $week) -and ($_.merged_at -le $endOfWeek))
            })

            $endOfWeek = $week
            $count = $filteredPullRequests.Count
            $totalPullRequests += $count

            Write-Output -InputObject ([PSCustomObject]([ordered]@{
                'WeekStart' = $week
                'Count' = $count
                'PullRequests' = $filteredPullRequests
            }))
        }

        Write-Output -InputObject ([PSCustomObject]([ordered]@{
            'WeekStart' = 'total'
            'Count' = $totalPullRequests
            'PullRequests' = $PullRequest
        }))
    }
    else
    {
        Write-Output -InputObject $PullRequest
    }
}

function Get-WeekDate
{
<#
    .SYNOPSIS
        Retrieves an array of dates with starts of $Weeks previous weeks.
        Dates are sorted in reverse chronological order

    .DESCRIPTION
        Retrieves an array of dates with starts of $Weeks previous weeks.
        Dates are sorted in reverse chronological order

        The Git repo for this module can be found here: http://aka.ms/PowerShellForGitHub

    .PARAMETER Weeks
        The number of weeks prior to today that should be included in the final result.

    .OUTPUTS
        [DateTime[]] List of DateTimes representing the first day of each requested week.

    .EXAMPLE
        Get-WeekDate -Weeks 10
#>
    [CmdletBinding()]
    param(
        [ValidateRange(0, 10000)]
        [int] $Weeks = 12
    )

    $dates = @()

    $midnightToday = Get-Date -Hour 0 -Minute 0 -Second 0 -Millisecond 0
    $startOfWeek = $midnightToday.AddDays(- ($midnightToday.DayOfWeek.value__ - 1))

    $i = 0
    while ($i -lt $Weeks)
    {
        $dates += $startOfWeek
        $startOfWeek = $startOfWeek.AddDays(-7)
        $i++
    }

    return $dates
}

# SIG # Begin signature block
# MIIdkgYJKoZIhvcNAQcCoIIdgzCCHX8CAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUNNCT4cNQn/WhCOsL4uVU0wjM
# nEugghhuMIIE2jCCA8KgAwIBAgITMwAAAQxsIwULB5kezQAAAAABDDANBgkqhkiG
# 9w0BAQUFADB3MQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4G
# A1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSEw
# HwYDVQQDExhNaWNyb3NvZnQgVGltZS1TdGFtcCBQQ0EwHhcNMTgwODIzMjAyMDM0
# WhcNMTkxMTIzMjAyMDM0WjCByjELMAkGA1UEBhMCVVMxCzAJBgNVBAgTAldBMRAw
# DgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24x
# LTArBgNVBAsTJE1pY3Jvc29mdCBJcmVsYW5kIE9wZXJhdGlvbnMgTGltaXRlZDEm
# MCQGA1UECxMdVGhhbGVzIFRTUyBFU046RkM0MS00QkQ0LUQyMjAxJTAjBgNVBAMT
# HE1pY3Jvc29mdCBUaW1lLVN0YW1wIHNlcnZpY2UwggEiMA0GCSqGSIb3DQEBAQUA
# A4IBDwAwggEKAoIBAQCO1S+QNIfQl05MvK2qCZdUhp26KrBTVZ0lBY2yrlJJ+lkn
# vd50+oHQESUNwXcgaDzNDv//ILA+M+trKzggkctne7QQyWdhDReiG7ys8yARz3M9
# kX1SUKRa3QGUJgiQjwEtyCRYRZKQVkMs6khlobG+q75X5cQRnJV3mjyD21TomVIz
# RoyMv3fgVZ7VDkfM1TLGgnrcuMAqIGKzLnHHdRJ38lzQCacr59g4zPASDN5Mo9vU
# T3Y3wsr8HfNgDaqAHQI0mJtVDKY+FOPY9FQx/zyip+vyJ3GpMdrmPbIaGgaoHLXo
# 4wF97qpxok6lrypxThw7O2DLXB74xiL+9uxHkllzAgMBAAGjggEJMIIBBTAdBgNV
# HQ4EFgQUle1s3XXPM7bDhbeMFjQIDBsoKhcwHwYDVR0jBBgwFoAUIzT42VJGcArt
# QPt2+7MrsMM1sw8wVAYDVR0fBE0wSzBJoEegRYZDaHR0cDovL2NybC5taWNyb3Nv
# ZnQuY29tL3BraS9jcmwvcHJvZHVjdHMvTWljcm9zb2Z0VGltZVN0YW1wUENBLmNy
# bDBYBggrBgEFBQcBAQRMMEowSAYIKwYBBQUHMAKGPGh0dHA6Ly93d3cubWljcm9z
# b2Z0LmNvbS9wa2kvY2VydHMvTWljcm9zb2Z0VGltZVN0YW1wUENBLmNydDATBgNV
# HSUEDDAKBggrBgEFBQcDCDANBgkqhkiG9w0BAQUFAAOCAQEAWPj0bJs6vOs/3ln2
# GbbeXV893lKIG+Cpy24LYfH1J3sq7JO5l7nPM7wqWHBlQ9/nqbnoTGqOMv30bNMQ
# mFOuDuOwmua2xxcBNa/FtrGG9XJ3rUpk/oar6UpDfZFLBxZeO7ULI4jxZI+pITne
# YoPVMbkIVHEJB24feqHz9E0E5Ofc4HjfcMPUY/6Kum4OU0GDhBEazSDmAHrhuusV
# jrAKXXFZ6l8ZQ6ynD9ZKs8/uxOGkEFPm+xwgQtl4U0Nch6rg/ksVCjAQYi5MUNBa
# HHUZg8vkO9sYL2W5KjX1kdwMkSc7UqfcykIOf1UdeohJhGo30F+jFKf04pmBRs1x
# CnQB1DCCBgMwggProAMCAQICEzMAAAEEaeLbufuKDYMAAAAAAQQwDQYJKoZIhvcN
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
# MAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFM1ubWZbYmJiyb622yc5QKV5
# i0Z8MEIGCisGAQQBgjcCAQwxNDAyoBSAEgBNAGkAYwByAG8AcwBvAGYAdKEagBho
# dHRwOi8vd3d3Lm1pY3Jvc29mdC5jb20wDQYJKoZIhvcNAQEBBQAEggEANRiZ7fMp
# iIuHk+AOEUnWvnt1FT5LYEMCa6ZUZiT7UfojjlPyFA3N02skta3DXwtik3TGZO41
# UsA8Wv8CC5Dr66GaZOVTpInBlymQK5OGydz7xLm5rmLp/6A5VoduS+yTneb18gan
# JSxryZ1boktF1ALl4SUSuU7lh5vspnNr/XGG7+LvSg5OaSLiRvq/MWFBvLrXb2IG
# QWN0gGO6fCis8atTgkG5O/ViUSNMtlgV9RClNGcWgH7W0zo3gzJVQvfMThyAr7jR
# Tz/nvj0DxGttpSxxrZhMBLe1+REFZ43askvJchwEnFWoB7rgn2gqz5pF+ip1PvkO
# WQ62RjfAPgQPG6GCAigwggIkBgkqhkiG9w0BCQYxggIVMIICEQIBATCBjjB3MQsw
# CQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9u
# ZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSEwHwYDVQQDExhNaWNy
# b3NvZnQgVGltZS1TdGFtcCBQQ0ECEzMAAAEMbCMFCweZHs0AAAAAAQwwCQYFKw4D
# AhoFAKBdMBgGCSqGSIb3DQEJAzELBgkqhkiG9w0BBwEwHAYJKoZIhvcNAQkFMQ8X
# DTE5MDEwNzE3Mjk0NVowIwYJKoZIhvcNAQkEMRYEFL88oenRmxnwWt8dBu771q38
# XibaMA0GCSqGSIb3DQEBBQUABIIBACZKzm5eEGfag8rbqVD5d18JPZ3n3wGyTV8g
# LkDAX9DhKei6aRoFbZDabLaOleMkjzwUJ3/nJhpLCHLREJTIGgEtw/k7dwBRHaKa
# p+tS16lG0R2YdeXy+jyLaYSjVVXXilciUjqvcfY4IGqJ4EEglFTOVbbea5a+Pdnd
# ME1INOi+ERGmMjvFfCrODIzUi1hQfEodft7kFoHuFWTOGdsaz1HAU0vJKlj0lNLY
# OggL5o0twoaO7IeBe0NSHXWAugpf91po93vPnh3HUypFOyf81laccW3rQicdDak6
# W09kh7DQ4hPW2PpvwSBCcKA+2uN/nvk33pSZNPn5vZL63gy6TX8=
# SIG # End signature block
