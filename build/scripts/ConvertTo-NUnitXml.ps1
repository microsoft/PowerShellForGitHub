# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

<#
    .DESCRIPTION
        This script takes the output of PSScriptAnalyzer and converts it into an NUnit XML schema
        file which can be fed into CI test reporting.

    .PARAMETER ScriptAnalyzerResult
        The output from Invoke-PSScriptAnalzyer to be written to an NUnit XML file.

    .PARAMETER Path
        The path the xml config file should be written to.

    .PARAMETER Force
        Overwrite the file at Path if it exists.

    .EXAMPLE
        $results = Invoke-ScriptAnalyzer -Settings ./PSScriptAnalyzerSettings.psd1 -Path ./ -Recurse
        .\ConverTo-NUnitXml.ps1 -ScriptAnalyzerResult $results -Path ./PSScriptAnalyzerFailures.xml
#>
[CmdletBinding()]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingWriteHost", "", Justification = "This is the preferred way of writing output for Azure DevOps.")]
param(
    [Parameter(Mandatory)]
    [AllowNull()]
    [Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord[]] $ScriptAnalyzerResult,

    [Parameter(Mandatory)]
    [string] $Path,

    [switch] $Force
)

# Convert sucess/failure into the appropriate terms for certain NUnit attributes.
$script:SuccessTerms = @{
    $true = [PSCustomObject]@{
        'result' = 'Success'
        'success' = 'True'}

    $false = [PSCustomObject]@{
        'result' = 'Failure'
        'success' = 'False'}
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
        [Parameter(
            Position=0,
            ValueFromPipeline)]
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

function New-NUnitXml
{
<#
    .SYNOPSIS
        Creates a new, empty NUnit Xml file.

    .OUTPUTS
        XmlDocument

    .NOTES
        It's expected that the "total" and "failures" attributes on test-results will be updated
        by the caller after this object has been returned.
#>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "", Justification="This does not change any system state.")]
    param()

    $date = Get-Date
    $dateString = $date.ToString("yyyy-MM-dd")
    $timeString = $date.ToString("HH:mm:ss")

    $xml = [xml]([String]::Format('<?xml version="1.0" encoding="utf-8"?>
    <test-results language="en-us"
        xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
        xsi:noNamespaceSchemaLocation="nunit_schema_2.5.xsd"
        name="PSScriptAnalyzer"
        total="0" errors="0" failures="0" not-run="0" inconclusive="0" ignored="0" skipped="0" invalid="0"
        date="{0}" time="{1}"/>',
        $dateString, $timeString))

    return $xml
}

function Add-Environment
{
<#
    .SYNOPSIS
        Adds the environment node to the NUnit Xml document.

    .PARAMETER Parent
        The parent element that the element is being added to.
#>
    param(
        [Parameter(Mandatory)]
        [System.Xml.XmlElement] $Parent
    )

    try
    {
        $environment = $Parent.OwnerDocument.CreateElement('environment', $Parent.OwnerDocument.NamespaceURI)
        $null = $Parent.AppendChild($environment)
        $environment.SetAttribute('user', $env:USERNAME)
        $environment.SetAttribute('machine-name', $env:COMPUTERNAME)
        $environment.SetAttribute('cwd', (Get-Location))
        $environment.SetAttribute('user-domain', $env:USERDOMAIN)
        $environment.SetAttribute('nunit-version', '2.5.8.0')
        $environment.SetAttribute('platform', ([System.Environment]::OSVersion.Platform))
        $environment.SetAttribute('os-version', ([System.Environment]::OSVersion.Version.ToString()))
        $environment.SetAttribute('clr-version', $PSVersionTable.CLRVersion)

        return $environment
    }
    catch
    {
        throw
    }
}

function Add-CultureInfo
{
<#
    .SYNOPSIS
        Adds the culture-info node to the NUnit Xml document.

    .PARAMETER Parent
        The parent element that the element is being added to.
#>
    param(
        [Parameter(Mandatory)]
        [System.Xml.XmlElement] $Parent
    )

    try
    {
        $cultureInfo = $Parent.OwnerDocument.CreateElement('culture-info', $Parent.OwnerDocument.NamespaceURI)
        $null = $Parent.AppendChild($cultureInfo)
        $cultureInfo.SetAttribute('current-culture', ((Get-Culture).Name))
        $cultureInfo.SetAttribute('current-uiculture', ((Get-UICulture).Name))

        return $cultureInfo
    }
    catch
    {
        throw
    }
}

function Add-TestSuite
{
<#
    .SYNOPSIS
        Adds a test-suite node to the NUnit Xml document.

    .PARAMETER Parent
        The parent element that the element is being added to.
#>
    param(
        [Parameter(Mandatory)]
        [System.Xml.XmlElement] $Parent,

        [Parameter(Mandatory)]
        [string] $Type,

        [Parameter(Mandatory)]
        [string] $Name,

        [string] $Description,

        [switch] $Succeeded
    )

    try
    {
        $testSuite = $Parent.OwnerDocument.CreateElement('test-suite', $Parent.OwnerDocument.NamespaceURI)
        $null = $Parent.AppendChild($testSuite)
        $testSuite.SetAttribute('type', $Type)
        $testSuite.SetAttribute('name', $Name)
        if ($PSBoundParameters.ContainsKey('Description')) { $testSuite.SetAttribute('description', $Description) }
        $testSuite.SetAttribute('executed', 'True')
        $testSuite.SetAttribute('time', '0.0')
        $testSuite.SetAttribute('asserts', '0')
        $testSuite.SetAttribute('result', $script:SuccessTerms[$Succeeded.ToBool()].result)
        $testSuite.SetAttribute('success', $script:SuccessTerms[$Succeeded.ToBool()].success)

        return $testSuite
    }
    catch
    {
        throw
    }
}

function Add-Results
{
<#
    .SYNOPSIS
        Adds a results node to the NUnit Xml document.

    .PARAMETER Parent
        The parent element that the element is being added to.
#>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseSingularNouns", "", Justification="This is intended to reflect the actual name of the node being added.")]
    param(
        [Parameter(Mandatory)]
        [System.Xml.XmlElement] $Parent
    )

    try
    {
        $results = $Parent.OwnerDocument.CreateElement('results', $Parent.OwnerDocument.NamespaceURI)
        $null = $Parent.AppendChild($results)

        return $results
    }
    catch
    {
        throw
    }
}

function Add-TestCase
{
<#
    .SYNOPSIS
        Adds a test case result to an existing XMLElement results node.

    .PARAMETER Parent
        The parent element that the element is being added to.

    .PARAMETER Name
        The name of the test case.

    .PARAMETER Description
        A descrition of the test case.

    .PARAMETER ScriptAnalyzerResult
        The PSScriptAnalyzer result record which explains the specific failure.

    .OUTPUTS
        XmlElement. Returns a reference to the newly created test-case element.

    .EXAMPLE
        Add-TestCase -Parent $element -Name 'All entries for this rule succeeded' -Description 'All entries for this rule succeeded'

        Adds a successful test-case element to the parent element provided.

    .EXAMPLE
        Add-TestCase -Parent $element -ScriptAnalyzerResult $result

        Adds a failure test-case element to the parent element provided, with the relevant
        information extracted from the PSScriptAnalyzer result object.
#>
    [CmdletBinding(DefaultParameterSetName='Success')]
    param(
        [Parameter(
            Mandatory,
            ParameterSetName='Success')]
        [Parameter(
            Mandatory,
            ParameterSetName='Failure')]
        [System.Xml.XmlElement] $Parent,

        [Parameter(
            Mandatory,
            ParameterSetName='Success')]
        [string] $Name,

        [Parameter(
            Mandatory,
            ParameterSetName='Success')]
        [string] $Description,

        [Parameter(
            Mandatory,
            ParameterSetName='Failure')]
        [Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord] $ScriptAnalyzerResult
    )

    try
    {
        $testCase = $Parent.OwnerDocument.CreateElement('test-case', $Parent.OwnerDocument.NamespaceURI)
        $null = $Parent.AppendChild($testCase)

        $succeeded = ($PSCmdlet.ParameterSetName -eq 'Success')
        if (-not $succeeded)
        {
            $Name = "[$($ScriptAnalyzerResult.RuleName)] - $($ScriptAnalyzerResult.ScriptPath):$($ScriptAnalyzerResult.Line), $($ScriptAnalyzerResult.Column)"

            $rules = Get-ScriptAnalyzerRule
            $Description = ($rules | Where-Object { $_.RuleName -eq $ScriptAnalyzerResult.RuleName }).Description
        }

        $testCase.SetAttribute('name', $Name)
        $testCase.SetAttribute('description', $Description)
        $testCase.SetAttribute('time', '0.0')
        $testCase.SetAttribute('executed', 'True')
        $testCase.SetAttribute('asserts', '0')
        $testCase.SetAttribute('result', $script:SuccessTerms[$succeeded].result)
        $testCase.SetAttribute('success', $script:SuccessTerms[$succeeded].success)

        if (-not $succeeded)
        {
            $failure = $Parent.OwnerDocument.CreateElement('failure', $Parent.OwnerDocument.NamespaceURI)
            $null = $testCase.AppendChild($failure)

            $message = $Parent.OwnerDocument.CreateElement('message', $Parent.OwnerDocument.NamespaceURI)
            $null = $failure.AppendChild($message)
            $message.InnerText = $ScriptAnalyzerResult.Message

            $stackTraceElement = $Parent.OwnerDocument.CreateElement('stack-trace', $Parent.OwnerDocument.NamespaceURI)
            $null = $failure.AppendChild($stackTraceElement)

            $generatedStackTrace = @(
                "at line: $($ScriptAnalyzerResult.line) in $($ScriptAnalyzerResult.ScriptPath)",
                " $($ScriptAnalyzerResult.Extent.Text)",
                " Severity: $($ScriptAnalyzerResult.Severity)")
            $stackTraceElement.InnerText = ($generatedStackTrace -join [Environment]::NewLine)
        }

        return $testCase
    }
    catch
    {
        throw
    }

}

function ConvertTo-NUnitXml
{
<#
    .DESCRIPTION
        Takes the output of PSScriptAnalyzer and converts it into an NUnit XML schema
        object.

    .PARAMETER ScriptAnalyzerResult
        One or more PSScriptAnalyzer result records to be written to the NUnit XML file.

    .OUTPUTS
        XmlDocument
#>
    param(
        [Parameter(Mandatory)]
        [AllowNull()]
        [Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord[]] $ScriptAnalyzerResult
    )

    try
    {
        $hasFailures = ($ScriptAnalyzerResult.Count -gt 0)
        $totalTests = 0
        $totalFailures = 0

        $xml = New-NUnitXml
        $null = Add-Environment -Parent $xml.DocumentElement
        $null = Add-CultureInfo -Parent $xml.DocumentElement
        $mainTestSuite = Add-TestSuite -Parent $xml.DocumentElement -Type 'PowerShell' -Name -'PSScriptAnalyzer' -Succeeded:(-not $hasFailures)
        $mainResults = Add-Results -Parent $mainTestSuite

        $rules = Get-ScriptAnalyzerRule
        foreach ($rule in $rules)
        {
            $failures = $ScriptAnalyzerResult | Where-Object { $_.RuleName -eq $rule }

            $testSuite = Add-TestSuite -Parent $mainResults -Type 'TestFixture' -Name $rule.RuleName -Description $rule.Description -Succeeded:($failures.Count -eq 0)
            $results = Add-Results -Parent $testSuite

            if ($failures.Count -eq 0)
            {
                $name = "All files pass rule [$($rule.RuleName)]"
                $null = Add-TestCase -Parent $results -Name $name -Description $rule.Description
                $totalTests++
            }
            else
            {
                foreach ($failure in $failures)
                {
                    $null = Add-TestCase -Parent $results -ScriptAnalyzerResult $failure
                    $totalTests++
                    $totalFailures++
                }
            }
        }

        # Finally, we need to update a few attributes in the root test-results
        $xml.'test-results'.total = $totalTests.ToString()
        $xml.'test-results'.failures = $totalFailures.ToString()

        # Catch an odd edge case if somehow there was a rule that failed that wasn't in the list
        # of rules returned.
        if ($totalFailures -ne $ScriptAnalyzerResult.Count)
        {
            Write-Error "The total generated number of failures ($totalFailures) does not match the expected number of failures ($($ScriptAnalyzerResult.Count))."
        }

        return $xml
    }
    catch
    {
        throw
    }
}

# Script body

$scriptName = Split-Path -Leaf -Path $PSCommandPath
try
{
    Write-Host "$($scriptName): Trying to create NUnit XML file based off of the provided PSScriptAnalyzer results."

    $Path = Resolve-UnverifiedPath -Path $Path
    if ((Test-Path -Path $Path -PathType Leaf) -and (-not $Force))
    {
        throw "File at [$Path] already exists, but -Force was not specified.  Exiting without replacing it."
    }

    $xml = ConvertTo-NUnitXml -ScriptAnalyzerResult $ScriptAnalyzerResult
    $xml.Save($Path)

    Write-Host "$($scriptName): Successfully created the NUnit XML file"
}
catch
{
    Write-Host "$($scriptName): Failed to create the NUnit XML file."
    throw
}
