# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

<#
    .SYNOPSIS
        Builds the markdown documentation for the module.

    .DESCRIPTION
        Builds the markdown documentation for the module using the PlatyPS PowerShell module.

    .PARAMETER Path
        Specifies the output path for the function markdown files.

    .PARAMETER ModulePath
        Specifies the path of the module to generate the help for.

    .PARAMETER ModuleName
        Specifies the name of the already loaded module to generate the help for.

    .PARAMETER Description
        Specifies the description for the module.

    .PARAMETER RemoveDeprecated
        Removes any files that were previously generated but were not generated during this update.
        Those files likely represent functions that were either renamed, removed or that stopped
        being exported.

    .PARAMETER Force
        Indicates that this should overwrite existing files that have the same names.

    .INPUTS
        None

    .OUTPUTS
        None

    .EXAMPLE
        Build-Wiki -Path './' -ModuleName 'PowerShellForGitHub' -RemoveDeprecated
#>
[CmdletBinding(DefaultParameterSetName='ModuleName')]
param
(
    [string] $Path = 'docs',

    [Parameter(
        Mandatory,
        ParameterSetName='ModulePath')]
    [string] $ModulePath,

    [Parameter(
        ParameterSetName='ModuleName')]
    [string] $ModuleName = 'PowerShellForGitHub',

    [string] $Description = 'PowerShellForGitHub is a PowerShell module that provides command-line interaction and automation for the [GitHub v3 API](https://developer.github.com/v3/).',

    [switch] $RemoveDeprecated,

    [switch] $Force
)

function Out-Utf8File
{
<#
    .DESCRIPTION
        Writes a file using UTF8 (no BOM) encoding.

    .PARAMETER Path
        The path to the file to write to.

    .PARAMETER Content
        The string content for the file.

    .PARAMETER Force
        Indicates that this should overwrite an existing file that has the same name.

    .INPUTS
        String

    .EXAMPLE
        Out-Utf8File -Path ./foo.txt -Content 'bar'
        Creates a 'foo.txt' in the current working directory with the content 'bar' as a UTF-8 file
        without BOM.

    .NOTES
        This is being used because the PS5 Encoding options only include utf8 with BOM, and we
        want to write without BOM.  This is fixed in PS6+, but we need to support PS4+.
#>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string] $Path,

        [Parameter(ValueFromPipeline)]
        [string] $Content,

        [switch] $Force
    )

    begin
    {
        if (Test-Path -Path $Path -PathType Leaf)
        {
            if ($Force.IsPresent)
            {
                Remove-Item -Path $Path -Force | Out-Null
            }
            else
            {
                throw "[$Path] already exists and -Force was not specified."
            }
        }

        $stream = New-Object -TypeName System.IO.StreamWriter -ArgumentList ($Path, [System.Text.Encoding]::UTF8)
    }

    process
    {

        $stream.WriteLine($Content)
    }

    end
    {
        $stream.Close();
    }
}

function Build-SideBar
{
<#
    .DESCRIPTION
        Generate the sidebar content file.

    .PARAMETER Path
        The path where the file should be written to.

    .PARAMETER ModuleRootPageFileName
        The filename for the root of the module documentation.

    .PARAMETER ModuleName
        The name of the module the documentation is for.

    .PARAMETER ModulePages
        The names of the module pages that have been generated.

    .EXAMPLE
        Build-SideBar -Path ./docs -ModuleRootPageFileName 'root.md' -ModuleName 'PowerShellForGitHub' -ModulePages @('Foo', 'Bar')
#>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseApprovedVerbs", "", Justification="It's an approved verb in PS Core, just not Windows PowerShell.  Plus, this is an internal helper.")]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string] $Path,

        [Parameter(Mandatory)]
        [string] $ModuleRootPageFileName,

        [Parameter(Mandatory)]
        [string] $ModuleName,

        [string[]] $ModulePages
    )

    $sideBarFilePath = Join-Path -Path $Path -ChildPath '_sidebar.md'

    $moduleRootPageBaseName = $ModuleRootPageFileName.Substring(0, $ModuleRootPageFileName.lastIndexOf('.'))

    $moduleContentStartMarker = '<!-- startDocs -->'
    $moduleContentEndMarker = '<!-- endDocs -->'
    $moduleContent = @()
    $moduleContent += $moduleContentStartMarker
    $moduleContent += '### Docs'
    $moduleContent += ''
    $moduleContent += "[$ModuleName]($moduleRootPageBaseName)"
    $moduleContent += ''
    $moduleContent += '#### Functions'
    $moduleContent += ''
    foreach ($modulePage in $modulePages)
    {
        $moduleContent += "- [$modulePage]($modulePage)"
    }
    $moduleContent += $moduleContentEndMarker
    $moduleContent += ''

    $content = ''
    $docsSideBarRegEx = "$moduleContentStartMarker[\r\n]+(?:[^<]+[\r\n]+)*$moduleContentEndMarker[\r\n]+"
    if (Test-Path -Path $sideBarFilePath -PathType Leaf)
    {
        $content = Get-Content -Path $sideBarFilePath -Raw -Encoding utf8
        if ($content -match $docsSideBarRegEx)
        {
            $content = $content -replace $docsSideBarRegEx,($moduleContent -join [Environment]::NewLine)
        }
        else
        {
            $content += [Environment]::NewLine
            $content += ($moduleContent -join [Environment]::NewLine)
        }
    }
    else
    {
        $newContent = @()
        $newContent += "## $ModuleName"
        $newContent += ''
        $newContent += $moduleContent
        $content = $newContent -join [Environment]::NewLine
    }

    $content | Out-Utf8File -Path $sideBarFilePath -Force
}

function Build-Footer
{
<#
    .DESCRIPTION
        Generate the footer content file.

    .PARAMETER Path
        The path where the file should be written to.

    .PARAMETER ModuleRootPageFileName
        The filename for the root of the module documentation.

    .PARAMETER ModuleName
        The name of the module the documentation is for.

    .EXAMPLE
        Build-Footer -Path ./docs -ModuleRootPageFileName 'root.md' -ModuleName 'PowerShellForGitHub'
#>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseApprovedVerbs", "", Justification="It's an approved verb in PS Core, just not Windows PowerShell.  Plus, this is an internal helper.")]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string] $Path,

        [Parameter(Mandatory)]
        [string] $ModuleRootPageFileName,

        [Parameter(Mandatory)]
        [string] $ModuleName
    )

    $footerFilePath = Join-Path -Path $Path -ChildPath '_footer.md'

    $moduleRootPageBaseName = $ModuleRootPageFileName.Substring(0, $ModuleRootPageFileName.lastIndexOf('.'))

    $moduleContentStartMarker = '<!-- startDocs -->'
    $moduleContentEndMarker = '<!-- endDocs -->'
    $moduleContent = @()
    $moduleContent += $moduleContentStartMarker
    $moduleContent += ''
    $moduleContent += "[Back to [$ModuleName]($moduleRootPageBaseName)]"
    $moduleContent += ''
    $moduleContent += $moduleContentEndMarker
    $moduleContent += ''

    $content = ''
    $docsFooterRegEx = "$moduleContentStartMarker[\r\n]+(?:[^<]+[\r\n]+)*$moduleContentEndMarker[\r\n]+"
    if (Test-Path -Path $footerFilePath -PathType Leaf)
    {
        $content = Get-Content -Path $footerFilePath -Raw -Encoding utf8
        if ($content -match $docsFooterRegEx)
        {
            $content = $content -replace $docsFooterRegEx,($moduleContent -join [Environment]::NewLine)
        }
        else
        {
            $content += [Environment]::NewLine
            $content += ($moduleContent -join [Environment]::NewLine)
        }
    }
    else
    {
        $content = ($moduleContent -join [Environment]::NewLine)
    }

    $content | Out-Utf8File -Path $footerFilePath -Force
}

function Build-HomePage
{
<#
    .DESCRIPTION
        Generate the home page file for the Wiki.

    .PARAMETER Path
        The path where the file should be written to.

    .PARAMETER ModuleRootPageFileName
        The filename for the root of the module documentation.

    .EXAMPLE
        Build-HomePage -Path ./docs -ModuleRootPageFileName 'root.md'
#>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseApprovedVerbs", "", Justification="It's an approved verb in PS Core, just not Windows PowerShell.  Plus, this is an internal helper.")]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string] $Path,

        [Parameter(Mandatory)]
        [string] $ModuleRootPageFileName
    )

    $homePageFilePath = Join-Path -Path $Path -ChildPath 'Home.md'

    $moduleRootPageBaseName = $ModuleRootPageFileName.Substring(0, $ModuleRootPageFileName.lastIndexOf('.'))

    $moduleContentStartMarker = '<!-- startDocs -->'
    $moduleContentEndMarker = '<!-- endDocs -->'
    $moduleContent = @()
    $moduleContent += $moduleContentStartMarker
    $moduleContent += ''
    $moduleContent += "[Full Module Documentation]($moduleRootPageBaseName)"
    $moduleContent += ''
    $moduleContent += $moduleContentEndMarker
    $moduleContent += ''

    $content = ''
    $docsFooterRegEx = "$moduleContentStartMarker[\r\n]+(?:[^<]+[\r\n]+)*$moduleContentEndMarker[\r\n]+"
    if (Test-Path -Path $homePageFilePath -PathType Leaf)
    {
        $content = Get-Content -Path $homePageFilePath -Raw -Encoding utf8
        if ($content -match $docsFooterRegEx)
        {
            $content = $content -replace $docsFooterRegEx,($moduleContent -join [Environment]::NewLine)
        }
        else
        {
            $content += [Environment]::NewLine
            $content += ($moduleContent -join [Environment]::NewLine)
        }
    }
    else
    {
        $content = ($moduleContent -join [Environment]::NewLine)
    }

    $content | Out-Utf8File -Path $homePageFilePath -Force
}

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 1.0

$Path = Resolve-Path -Path $Path

if ($PSVersionTable.PSVersion.Major -lt 7)
{
    Write-Warning 'It is recommended to run this with PowerShell 7+, as platyPS has a bug which doesn''t properly handle multi-line examples when run on older vesrions of PowerShell.'
}

$numSteps = 11
$currentStep = 0
$progressParams = @{
    'Activity' = 'Generating documentation for wiki'
    'Id' = 1
}

#######
$currentStep++
Write-Progress @progressParams -Status 'Ensuring PlatyPS installed' -PercentComplete (($currentStep / $numSteps) * 100)
if ($null -eq (Get-Module -Name 'PlatyPS' -ListAvailable))
{
    Write-Verbose -Message 'Installing PlatyPS Module'
    Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Scope CurrentUser -Force -Verbose:$false | Out-Null
    Install-Module PlatyPS -Scope CurrentUser -Force
}

#######
$currentStep++
Write-Progress @progressParams -Status 'Ensuring source module is loaded' -PercentComplete (($currentStep / $numSteps) * 100)
if (-not [String]::IsNullOrEmpty($ModulePath))
{
    Write-Verbose -Message "Importing [$ModulePath]"
    $module = Import-Module -Name $ModulePath -PassThru -Force -Verbose:$false
    $ModuleName = $module.Name
}

$moduleRootPageFileName = "$ModuleName.md"

# We generate the files to a _temp_ directory so that we can determine if there have been any
# files that should be _removed_ from the Wiki due to rename/removal of exports.
$tempFolder = Join-Path -Path $env:TEMP -ChildPath ([Guid]::NewGuid().Guid)
New-Item -Path $tempFolder -ItemType Directory | Out-Null
Write-Verbose -Message "Working from temp location: $tempFolder"

#######
$currentStep++
Write-Progress @progressParams -Status 'Creating the new module markdown help files' -PercentComplete (($currentStep / $numSteps) * 100)

# The ModulePage is generated to the current working directory, so we need to be temporarily located
# at the temp folder.
Push-Location -Path $tempFolder

$params = @{
    Module = $ModuleName
    OutputFolder = $tempFolder
    UseFullTypeName = $true
    AlphabeticParamsOrder = $true
    WithModulePage = $true
    ModulePagePath = $moduleRootPageFileName
    NoMetadata = $false # Otherwise was having issues with Update-MarkdownHelpModule
    FwLink = 'N/A'
    Encoding = ([System.Text.Encoding]::UTF8)
    Force = $true
}
New-MarkdownHelp @params | Out-Null

#######
$currentStep++
Write-Progress @progressParams -Status 'Updating the generated documentation' -PercentComplete (($currentStep / $numSteps) * 100)
$params = @{
    Path = $tempFolder
    RefreshModulePage = $true
    ModulePagePath = $moduleRootPageFileName
    UseFullTypeName = $true
    AlphabeticParamsOrder = $true
    Encoding = ([System.Text.Encoding]::UTF8)
}
Update-MarkdownHelpModule @params | Out-Null

# The ModulePage is generated to the current working directory.  Now that we're done generating,
# let's go back to our original location
Pop-Location

#######
$currentStep++
Write-Progress @progressParams -Status "Cleaning up content in $moduleRootPageFileName" -PercentComplete (($currentStep / $numSteps) * 100)
$moduleRootPageFilePath = Join-Path -Path $tempFolder -ChildPath $moduleRootPageFileName
$moduleRootPageContent = Get-Content -Path $moduleRootPageFilePath -Raw -Encoding utf8
$moduleRootPageContent = $moduleRootPageContent.Replace('.md)', ')')

$descriptionMarker = '{{ Fill in the Description }}'
$moduleRootPageContent = $moduleRootPageContent.Replace($descriptionMarker, $Description)
$moduleRootPageContent | Out-Utf8File -Path $moduleRootPageFilePath -Force | Out-Null

#######
$currentStep++
Write-Progress @progressParams -Status "Removing metadata from generated files" -PercentComplete (($currentStep / $numSteps) * 100)
$modulePages = @()
$generatedFiles = Get-ChildItem -Path $tempFolder -Filter '*.md'
$metadataRegEx = '^---[\r\n]+(?:[^-].+[\r\n]+){1,10}---[\r\n]{1,4}'
$generatedMarker = '<!-- Generated -->' + [Environment]::NewLine
foreach ($file in $generatedFiles)
{
    $fileContent = Get-Content -Path $file.FullName -Raw -Encoding utf8
    if ($fileContent -match $metadataRegEx)
    {
        $fileContent = $fileContent -replace $metadataRegEx,$generatedMarker
        $fileContent | Out-Utf8File -Path $file.FullName -Force

        if ($file.Name -ne $moduleRootPageFileName)
        {
            $modulePages += $file.BaseName
        }
    }
}

#######
$currentStep++
Write-Progress @progressParams -Status "Updating sidebar" -PercentComplete (($currentStep / $numSteps) * 100)
Build-SideBar -Path $Path -ModuleRootPageFileName $moduleRootPageFileName -ModuleName $ModuleName -ModulePages $modulePages

#######
$currentStep++
Write-Progress @progressParams -Status "Updating footer" -PercentComplete (($currentStep / $numSteps) * 100)
Build-Footer -Path $Path -ModuleRootPageFileName $moduleRootPageFileName -ModuleName $ModuleName

#######
$currentStep++
Write-Progress @progressParams -Status "Updating home page" -PercentComplete (($currentStep / $numSteps) * 100)
Build-HomePage -Path $Path -ModuleRootPageFileName $moduleRootPageFileName

#######
$currentStep++
Write-Progress @progressParams -Status "Detecting deprecated pages" -PercentComplete (($currentStep / $numSteps) * 100)
$deprecatedFiles = @()
$currentFiles = Get-ChildItem -Path $Path -Filter '*.md'
foreach ($file in $currentFiles)
{
    $content = Get-Content -Path $file -Raw -Encoding utf8
    if (($content -match $generatedMarker) -and
        ($file.BaseName -notin $modulePages) -and
        ($file.Name -notin ($moduleRootPageFileName, 'Home.md')))
    {
        $deprecatedFiles += $file
    }
}

if ($deprecatedFiles.Length -gt 0)
{
    if ($RemoveDeprecated.IsPresent)
    {
        Write-Verbose "The following files have been deprecated and will be removed:"
    }
    else
    {
        Write-Verbose "The following files have been deprecated.  They can be removed automatically by specifying the -RemoveDeprecated switch."
    }

    foreach ($file in $deprecatedFiles)
    {
        Write-Verbose "* $($file.Name)"
        if ($RemoveDeprecated.IsPresent)
        {
            Remove-Item -Path $file.FullName -Force
        }
    }
}

#######
$currentStep++
Write-Progress @progressParams -Status "Moving generated content to final destination" -PercentComplete (($currentStep / $numSteps) * 100)
$files = Get-ChildItem -Path $tempFolder
foreach ($file in $files)
{
    Move-Item -Path $file.FullName -Destination $Path -Force:$Force.IsPresent
}

Remove-Item -Path $tempFolder -Recurse -Force

#######
Write-Progress @progressParams -Completed
