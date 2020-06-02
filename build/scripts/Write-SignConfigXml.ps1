# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

<#
    .DESCRIPTION
        This script produces an xml file for a given PowerShell module, which is used to submit a
        batch of files to be Authenticode signed.

        The files to be signed are any PowerShell files that would be packaged by the module
        definition found inside the ModulePath.

    .PARAMETER ModulePath
        The path to the root of the module that contains the files that should be signed.
        They will be signed in-place.

    .PARAMETER OutPath
        The path the xml config file should be written to.

    .PARAMETER ModuleName
        The name of the module being signed.

    .PARAMETER Approver
        The list of usernames who have the authority to request the signing of the identified files.

    .EXAMPLE
        .\Write-SignConfigXml.ps1 -ModulePath c:\MyModule -OutPath c:\data\PoShFileSignConfig.xml -ModuleName 'PowerShellForGitHub' -Approver 'username'
#>
[CmdletBinding()]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingWriteHost", "", Justification = "This is the preferred way of writing output for Azure DevOps.")]
param(
    [Parameter(Mandatory)]
    [ValidateScript( {if (Test-Path -Path $_ -PathType Container) { $true } else { throw "$_ cannot be found." }})]
    [string] $ModulePath,

    [Parameter(Mandatory)]
    [string] $OutPath,

    [string] $ModuleName,

    [string[]] $Approver
)

function Out-SignConfigXml
{
    <#
    .DESCRIPTION
        A helper function for producing a PoShFileSignConfig.xml file that references the input paths.

        The PoShFileSignConfig.xml file is produced under $OutPath. Each file given as part of
        $Path will be translated to a <file> element in the SignConfig.xml.

        The way the config file is written, the signed files will be written in-place.

        All files will be signed as a single job.

    .PARAMETER Path
        An array of one or more paths that should be Authenticode signed.

    .PARAMETER OutPath
        The path where SignConfig.xml should be written.
        If the directory does not exist it will be created.

    .PARAMETER ModuleName
        The name of the module being signed.

    .PARAMETER ModuleVersion
        The version of the module being signed.

    .PARAMETER Approver
        The list of usernames who have the authority to request the signing of the identified module files.
#>

    [CmdletBinding()]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingWriteHost", "", Justification = "This is the preferred way of writing output for Azure DevOps.")]
    param(
        [Parameter(
            Mandatory,
            ValueFromPipeline,
            ValueFromPipelineByPropertyName)]
        [System.IO.FileInfo[]] $Path,

        [Parameter(Mandatory)]
        [System.IO.FileInfo] $OutPath,

        [string] $ModuleName,

        [string] $ModuleVersion,

        [string[]] $Approver
    )

    begin
    {
        Write-Host "$($scriptName): Generating [$OutPath]"

        $tab = " " * 4

        $header = @(
            '<?xml version="1.0" encoding="utf-8" ?>',
            '<SignConfigXML>',
            ($tab + "<job platform=`"`" configuration=`"`" dest=`"`" jobname=`"$ModuleName $ModuleVersion Signing`" approvers=`"$($Approver -join ';')`">")
        )

        $body = @()

        $footer = @(
            ($tab + '</job>'),
            '</SignConfigXML>'
        )

        # With an empty 'dest' attribute, the signed file will be written in-place
        $fileElementFormat = ($tab * 2) + '<file src="{0}" dest="" signType="AuthenticodeFormer"/>'
    }

    process
    {
        foreach ($filePath in $Path)
        {
            $body += ($fileElementFormat -f $filePath)
        }
    }

    end
    {
        # Ensure that the file and its full path, exist.
        New-Item -Path (Split-Path -Path $OutPath -Parent) -ItemType Directory -Force -ErrorAction Stop | Out-Null

        $content = ($header + $body + $footer) | Out-String
        Set-Content -Path $OutPath -Value $content -Encoding UTF8 -Force -ErrorAction Stop

        Write-Host "$($scriptName): Generated [$OutPath] with content:"
        Write-Host $content
    }
}

function Get-HashtableFromModuleManifest
{
    <#
    .DESCRIPTION
        Safely imports a module manifest file and returns it back as a hashtable of properties.

    .PARAMETER Path
        The path to the .psd1 file for the module.

    .OUTPUTS
        [HashTable] The hashtable content of the module's manifest
#>
    [CmdletBinding()]
    param(
        [Parameter(
            Mandatory,
            ValueFromPipeline,
            ValueFromPipelineByPropertyName)]
        [System.IO.FileInfo] $Path
    )

    process
    {
        try
        {
            $content = Get-Content -Path $Path -Encoding UTF8 -Raw
            $scriptBlock = [scriptblock]::Create($content)

            [string[]] $allowedCommands = @()
            [string[]] $allowedVariables = @()
            $allowEnvronmentVariables = $false
            $scriptBlock.CheckRestrictedLanguage($allowedCommands, $allowedVariables, $allowEnvronmentVariables)

            Write-Output -InputObject (& $scriptBlock)
        }
        catch
        {
            throw
        }
    }
}

function Get-FilesFromModuleManifest
{
    <#
    .DESCRIPTION
        A helper function that returns full paths to all PowerShell files referenced by
        a module's manifest (.psd1) file.

    .PARAMETER Path
        The path to the .psd1 file for the module.

    .OUTPUTS
        [FileInfo[]] A list of full paths of all PowerShell files referenced by ModuleManifestPath.
#>
    [CmdletBinding()]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingWriteHost", "", Justification = "This is the preferred way of writing output for Azure DevOps.")]
    param(
        [Parameter(
            Mandatory,
            ValueFromPipeline,
            ValueFromPipelineByPropertyName)]
        [System.IO.FileInfo] $Path
    )

    process
    {
        Write-Host "$($scriptName): Getting list of PowerShell files referenced by [$Path]."

        $manifest = Get-HashtableFromModuleManifest -Path $Path

        $files = @($Path)
        $moduleRoot = Split-Path -Path $Path -Parent
        if (-not [String]::IsNullOrEmpty($manifest['RootModule']))
        {
            $files += (Get-Item -Path (Join-Path -Path $moduleRoot -ChildPath $manifest['RootModule']))
        }

        foreach ($file in $manifest['NestedModules'])
        {
            $files += (Get-Item -Path (Join-Path -Path $moduleRoot -ChildPath $file))
        }

        Write-Output -InputObject $files
    }
}

# Script body

$scriptName = Split-Path -Leaf -Path $PSCommandPath
try
{
    $ModulePath = Resolve-Path -Path $ModulePath
    Write-Host "$($scriptName): Trying to create PowerShell signing config file for [$ModuleName] located at [$ModulePath]."

    # Find the module manifest.  We'll inspect it in order to identify what files need to be signed.
    $manifestFile = (Get-ChildItem -Path $ModulePath -Filter '*.psd1' | Select-Object -First 1)
    if ($null -eq $manifestFile)
    {
        throw "No manifest file (*.psd1) could be found at [$ModulePath]."
    }

    $moduleVersion = (Get-HashtableFromModuleManifest -Path $manifestFile.FullName).ModuleVersion
    Get-FilesFromModuleManifest -Path $manifestFile.FullName |
        Out-SignConfigXml -OutPath $OutPath -ModuleName $ModuleName -ModuleVersion $moduleVersion -Approver $Approver

    Write-Host "$($scriptName): Successfully created sign config file."
}
catch
{
    Write-Host "$($scriptName): Failed to create signing config file."
    throw
}
