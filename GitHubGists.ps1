# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

@{
    GitHubGistTypeName = 'GitHub.Gist'
    GitHubGistCommitTypeName = 'GitHub.GistCommit'
    GitHubGistForkTypeName = 'GitHub.GistFork'
    GitHubGistSummaryTypeName = 'GitHub.GistSummary'
 }.GetEnumerator() | ForEach-Object {
     Set-Variable -Scope Script -Option ReadOnly -Name $_.Key -Value $_.Value
 }

filter Get-GitHubGist
{
<#
    .SYNOPSIS
        Retrieves gist information from GitHub.

    .DESCRIPTION
        Retrieves gist information from GitHub.

        The Git repo for this module can be found here: http://aka.ms/PowerShellForGitHub

    .PARAMETER Gist
        The ID of the specific gist that you wish to retrieve.

    .PARAMETER Sha
        The specific revision of the gist that you wish to retrieve.

    .PARAMETER Forks
        Gets the forks of the specified gist.

    .PARAMETER Commits
        Gets the commits of the specified gist.

    .PARAMETER UserName
        Gets public gists for the specified user.

    .PARAMETER Path
        Download the files that are part of the specified gist to this path.

    .PARAMETER Force
        If downloading files, this will overwrite any files with the same name in the provided path.

    .PARAMETER Current
        Gets the authenticated user's gists.

    .PARAMETER Starred
        Gets the authenticated user's starred gists.

    .PARAMETER Public
        Gets public gists sorted by most recently updated to least recently updated.
        The results will be limited to the first 3000.

    .PARAMETER Since
        Only gists updated at or after this time are returned.

    .PARAMETER AccessToken
        If provided, this will be used as the AccessToken for authentication with the
        REST Api.  Otherwise, will attempt to use the configured value or will run unauthenticated.

    .INPUTS
        GitHub.Gist
        GitHub.GistComment
        GitHub.GistCommit
        GitHub.GistFork
        GitHub.GistSummary

    .OUTPUTS
        GitHub.Gist
        GitHub.GistCommit
        GitHub.GistFork
        GitHub.GistSummary

    .EXAMPLE
        Get-GitHubGist -Starred

        Gets all starred gists for the current authenticated user.

    .EXAMPLE
        Get-GitHubGist -Public -Since ((Get-Date).AddDays(-2))

        Gets all public gists that have been updated within the past two days.

    .EXAMPLE
        Get-GitHubGist -Gist 6cad326836d38bd3a7ae

        Gets octocat's "hello_world.rb" gist.
#>
    [CmdletBinding(
        DefaultParameterSetName='Current',
        PositionalBinding = $false)]
    [OutputType({$script:GitHubGistTypeName})]
    [OutputType({$script:GitHubGistCommitTypeName})]
    [OutputType({$script:GitHubGistForkTypeName})]
    [OutputType({$script:GitHubGistSummaryTypeName})]
    param(
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName='Id',
            Position = 1)]
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName='Download',
            Position = 1)]
        [Alias('GistId')]
        [ValidateNotNullOrEmpty()]
        [string] $Gist,

        [Parameter(ParameterSetName='Id')]
        [Parameter(ParameterSetName='Download')]
        [ValidateNotNullOrEmpty()]
        [string] $Sha,

        [Parameter(ParameterSetName='Id')]
        [switch] $Forks,

        [Parameter(ParameterSetName='Id')]
        [switch] $Commits,

        [Parameter(
            Mandatory,
            ParameterSetName='User')]
        [ValidateNotNullOrEmpty()]
        [string] $UserName,

        [Parameter(
            Mandatory,
            ParameterSetName='Download',
            Position = 2)]
        [ValidateNotNullOrEmpty()]
        [string] $Path,

        [Parameter(ParameterSetName='Download')]
        [switch] $Force,

        [Parameter(ParameterSetName='Current')]
        [switch] $Current,

        [Parameter(ParameterSetName='Current')]
        [switch] $Starred,

        [Parameter(ParameterSetName='Public')]
        [switch] $Public,

        [Parameter(ParameterSetName='User')]
        [Parameter(ParameterSetName='Current')]
        [Parameter(ParameterSetName='Public')]
        [DateTime] $Since,

        [string] $AccessToken
    )

    Write-InvocationLog

    $telemetryProperties = @{}

    $uriFragment = [String]::Empty
    $description = [String]::Empty
    $outputType = $script:GitHubGistSummaryTypeName

    if ($PSCmdlet.ParameterSetName -in ('Id', 'Download'))
    {
        $telemetryProperties['ById'] = $true

        if ($PSBoundParameters.ContainsKey('Sha'))
        {
            if ($Forks -or $Commits)
            {
                $message = 'Cannot check for forks or commits of a specific SHA.  Do not specify SHA if you want to list out forks or commits.'
                Write-Log -Message $message -Level Error
                throw $message
            }

            $telemetryProperties['SpecifiedSha'] = $true

            $uriFragment = "gists/$Gist/$Sha"
            $description = "Getting gist $Gist with specified Sha"
            $outputType = $script:GitHubGistTypeName
        }
        elseif ($Forks)
        {
            $uriFragment = "gists/$Gist/forks"
            $description = "Getting forks of gist $Gist"
            $outputType = $script:GitHubGistForkTypeName
        }
        elseif ($Commits)
        {
            $uriFragment = "gists/$Gist/commits"
            $description = "Getting commits of gist $Gist"
            $outputType = $script:GitHubGistCommitTypeName
        }
        else
        {
            $uriFragment = "gists/$Gist"
            $description = "Getting gist $Gist"
            $outputType = $script:GitHubGistTypeName
        }
    }
    elseif ($PSCmdlet.ParameterSetName -eq 'User')
    {
        $telemetryProperties['ByUserName'] = $true

        $uriFragment = "users/$UserName/gists"
        $description = "Getting public gists for $UserName"
        $outputType = $script:GitHubGistSummaryTypeName
    }
    elseif ($PSCmdlet.ParameterSetName -eq 'Current')
    {
        $telemetryProperties['CurrentUser'] = $true
        $outputType = $script:GitHubGistSummaryTypeName

        if ((Test-GitHubAuthenticationConfigured) -or (-not [String]::IsNullOrEmpty($AccessToken)))
        {
            if ($Starred)
            {
                $uriFragment = 'gists/starred'
                $description = 'Getting starred gists for current authenticated user'
            }
            else
            {
                $uriFragment = 'gists'
                $description = 'Getting gists for current authenticated user'
            }
        }
        else
        {
            if ($Starred)
            {
                $message = 'Starred can only be specified for authenticated users.  Either call Set-GitHubAuthentication first, or provide a value for the AccessToken parameter.'
                Write-Log -Message $message -Level Error
                throw $message
            }

            $message = 'Specified -Current, but not currently authenticated.  Either call Set-GitHubAuthentication first, or provide a value for the AccessToken parameter.'
            Write-Log -Message $message -Level Error
            throw $message
        }
    }
    elseif ($PSCmdlet.ParameterSetName -eq 'Public')
    {
        $telemetryProperties['Public'] = $true
        $outputType = $script:GitHubGistSummaryTypeName

        $uriFragment = "gists/public"
        $description = 'Getting public gists'
    }

    $getParams = @()
    $sinceFormattedTime = [String]::Empty
    if ($null -ne $Since)
    {
        $sinceFormattedTime = $Since.ToUniversalTime().ToString('o')
        $getParams += "since=$sinceFormattedTime"
    }

    $params = @{
        'UriFragment' = $uriFragment + '?' +  ($getParams -join '&')
        'Description' =  $description
        'AccessToken' = $AccessToken
        'TelemetryEventName' = $MyInvocation.MyCommand.Name
        'TelemetryProperties' = $telemetryProperties
    }

    $result = (Invoke-GHRestMethodMultipleResult @params |
        Add-GitHubGistAdditionalProperties -TypeName $outputType)

    if ($PSCmdlet.ParameterSetName -eq 'Download')
    {
        Save-GitHubGist -GistObject $result -Path $Path -Force:$Force
    }
    else
    {
        if ($result.truncated -eq $true)
        {
            $message = @(
                'Response has been truncated.  The API will only return the first 3000 gist results',
                'the first 300 files within the gist, and the first 1 Mb of an individual',
                'file.  If the file has been truncated, you can call',
                '(Invoke-WebRequest -UseBasicParsing -Method Get -Uri <raw_url>).Content)',
                'where <raw_url> is the value of raw_url for the file in question.  Be aware that',
                'for files larger than 10 Mb, you''ll need to clone the gist via the URL provided',
                'by git_pull_url.')

            Write-Log -Message ($message -join ' ') -Level Warning
        }

        return $result
    }
}

function Save-GitHubGist
{
<#
    .SYNOPSIS
        Downloads the contents of a gist to the specified file path.

    .DESCRIPTION
        Downloads the contents of a gist to the specified file path.

        The Git repo for this module can be found here: http://aka.ms/PowerShellForGitHub

    .PARAMETER GistObject
        The Gist PSCustomObject

    .PARAMETER Path
        Download the files that are part of the specified gist to this path.

    .PARAMETER Force
        If downloading files, this will overwrite any files with the same name in the provided path.

    .NOTES
        Internal-only helper
#>
    [CmdletBinding(PositionalBinding = $false)]
    param(
        [Parameter(Mandatory)]
        [PSCustomObject] $GistObject,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string] $Path,

        [switch] $Force
    )

    # First, check to see if the response is missing files.
    if ($GistObject.truncated)
    {
        $message = @(
            'Gist response has been truncated.  The API will only return information on',
            'the first 300 files within a gist. To download this entire gist,',
            'you''ll need to clone it via the URL provided by git_pull_url',
            "[$($GistObject.git_pull_url)].")

        Write-Log -Message ($message -join ' ') -Level Error
        throw $message
    }

    # Then check to see if there are files we won't be able to download
    $files = $GistObject.files | Get-Member -Type NoteProperty | Select-Object -ExpandProperty Name
    foreach ($fileName in $files)
    {
        if ($GistObject.files.$fileName.truncated -and
            ($GistObject.files.$fileName.size -gt 10mb))
        {
            $message = @(
                "At least one file ($fileName) in this gist is larger than 10mb.",
                'In order to download this gist, you''ll need to clone it via the URL',
                "provided by git_pull_url [$($GistObject.git_pull_url)].")

            Write-Log -Message ($message -join ' ') -Level Error
            throw $message
        }
    }

    # Finally, we're ready to directly save the non-truncated files,
    # and download the ones that are between 1 - 10mb.
    $originalSecurityProtocol = [Net.ServicePointManager]::SecurityProtocol
    [Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12
    try
    {
        $headers = @{}
        $AccessToken = Get-AccessToken -AccessToken $AccessToken
        if (-not [String]::IsNullOrEmpty($AccessToken))
        {
            $headers['Authorization'] = "token $AccessToken"
        }

        $Path = Resolve-UnverifiedPath -Path $Path
        $null = New-Item -Path $Path -ItemType Directory -Force
        foreach ($fileName in $files)
        {
            $filePath = Join-Path -Path $Path -ChildPath $fileName
            if ((Test-Path -Path $filePath -PathType Leaf) -and (-not $Force))
            {
                $message = "File already exists at path [$filePath].  Choose a different path or specify -Force"
                Write-Log -Message $message -Level Error
                throw $message
            }

            if ($GistObject.files.$fileName.truncated)
            {
                # Disable Progress Bar in function scope during Invoke-WebRequest
                $ProgressPreference = 'SilentlyContinue'

                $webRequestParams = @{
                    UseBasicParsing = $true
                    Method = 'Get'
                    Headers = $headers
                    Uri = $GistObject.files.$fileName.raw_url
                    OutFile = $filePath
                }

                Invoke-WebRequest @webRequestParams
            }
            else
            {
                $stream = New-Object -TypeName System.IO.StreamWriter -ArgumentList ($filePath)
                try
                {
                    $stream.Write($GistObject.files.$fileName.content)
                }
                finally
                {
                    $stream.Close()
                }
            }
        }
    }
    finally
    {
        [Net.ServicePointManager]::SecurityProtocol = $originalSecurityProtocol
    }
}

filter Remove-GitHubGist
{
<#
    .SYNOPSIS
        Removes/deletes a gist from GitHub.

    .DESCRIPTION
        Removes/deletes a gist from GitHub.

        The Git repo for this module can be found here: http://aka.ms/PowerShellForGitHub

    .PARAMETER Gist
        The ID of the specific gist that you wish to retrieve.

    .PARAMETER Force
        If this switch is specified, you will not be prompted for confirmation of command execution.

    .PARAMETER AccessToken
        If provided, this will be used as the AccessToken for authentication with the
        REST Api.  Otherwise, will attempt to use the configured value or will run unauthenticated.

    .INPUTS
        GitHub.Gist
        GitHub.GistComment
        GitHub.GistCommit
        GitHub.GistFork
        GitHub.GistSummary

    .EXAMPLE
        Remove-GitHubGist -Gist 6cad326836d38bd3a7ae

        Removes octocat's "hello_world.rb" gist (assuming you have permission).

    .EXAMPLE
        Remove-GitHubGist -Gist 6cad326836d38bd3a7ae -Confirm:$false

        Removes octocat's "hello_world.rb" gist (assuming you have permission).
        Will not prompt for confirmation, as -Confirm:$false was specified.

    .EXAMPLE
        Remove-GitHubGist -Gist 6cad326836d38bd3a7ae -Force

        Removes octocat's "hello_world.rb" gist (assuming you have permission).
        Will not prompt for confirmation, as -Force was specified.
#>
    [CmdletBinding(
        SupportsShouldProcess,
        PositionalBinding = $false,
        ConfirmImpact = 'High')]
    [Alias('Delete-GitHubGist')]
    param(
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            Position = 1)]
        [Alias('GistId')]
        [ValidateNotNullOrEmpty()]
        [string] $Gist,

        [switch] $Force,

        [string] $AccessToken
    )

    Write-InvocationLog

    if ($Force -and (-not $Confirm))
    {
        $ConfirmPreference = 'None'
    }

    if (-not $PSCmdlet.ShouldProcess($Gist, "Delete gist"))
    {
        return
    }

    $telemetryProperties = @{}
    $params = @{
        'UriFragment' = "gists/$Gist"
        'Method' = 'Delete'
        'Description' =  "Removing gist $Gist"
        'AccessToken' = $AccessToken
        'TelemetryEventName' = $MyInvocation.MyCommand.Name
        'TelemetryProperties' = $telemetryProperties
    }

    return Invoke-GHRestMethod @params
}

filter Copy-GitHubGist
{
<#
    .SYNOPSIS
        Forks a gist from GitHub.

    .DESCRIPTION
        Forks a gist from GitHub.

        The Git repo for this module can be found here: http://aka.ms/PowerShellForGitHub

    .PARAMETER Gist
        The ID of the specific gist that you wish to fork.

    .PARAMETER PassThru
        Returns the newly created gist fork.  By default, this cmdlet does not generate any output.
        You can use "Set-GitHubConfiguration -DefaultPassThru" to control the default behavior
        of this switch.

    .PARAMETER AccessToken
        If provided, this will be used as the AccessToken for authentication with the
        REST Api.  Otherwise, will attempt to use the configured value or will run unauthenticated.

    .INPUTS
        GitHub.Gist
        GitHub.GistComment
        GitHub.GistCommit
        GitHub.GistFork
        GitHub.GistSummary

    .OUTPUTS
        GitHub.GistSummary

    .EXAMPLE
        Copy-GitHubGist -Gist 6cad326836d38bd3a7ae

        Forks octocat's "hello_world.rb" gist.

    .EXAMPLE
        $result = Fork-GitHubGist -Gist 6cad326836d38bd3a7ae -PassThru

        Forks octocat's "hello_world.rb" gist.  This is using the alias for the command.
        The result is the same whether you use Copy-GitHubGist or Fork-GitHubGist.
        Specifying the -PassThru switch enables you to get a reference to the newly created fork.
#>
    [CmdletBinding(
        SupportsShouldProcess,
        PositionalBinding = $false)]
    [OutputType({$script:GitHubGistSummaryTypeName})]
    [Alias('Fork-GitHubGist')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSReviewUnusedParameter", "", Justification="PassThru is accessed indirectly via Resolve-ParameterWithDefaultConfigurationValue")]
    param(
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            Position = 1)]
        [Alias('GistId')]
        [ValidateNotNullOrEmpty()]
        [string] $Gist,

        [switch] $PassThru,

        [string] $AccessToken
    )

    Write-InvocationLog

    if (-not $PSCmdlet.ShouldProcess($Gist, "Forking gist"))
    {
        return
    }

    $telemetryProperties = @{}
    $params = @{
        'UriFragment' = "gists/$Gist/forks"
        'Method' = 'Post'
        'Description' =  "Forking gist $Gist"
        'AccessToken' = $AccessToken
        'TelemetryEventName' = $MyInvocation.MyCommand.Name
        'TelemetryProperties' = $telemetryProperties
    }

    $result = (Invoke-GHRestMethod @params |
        Add-GitHubGistAdditionalProperties -TypeName $script:GitHubGistSummaryTypeName)

    if (Resolve-ParameterWithDefaultConfigurationValue -Name PassThru -ConfigValueName DefaultPassThru)
    {
        return $result
    }
}

filter Set-GitHubGistStar
{
<#
    .SYNOPSIS
        Changes the starred state of a gist on GitHub for the current authenticated user.

    .DESCRIPTION
        Changes the starred state of a gist on GitHub for the current authenticated user.

        The Git repo for this module can be found here: http://aka.ms/PowerShellForGitHub

    .PARAMETER Gist
        The ID of the specific Gist that you wish to change the starred state for.

    .PARAMETER Star
        Include this switch to star the gist.  Exclude the switch (or use -Star:$false) to
        remove the star.

    .PARAMETER AccessToken
        If provided, this will be used as the AccessToken for authentication with the
        REST Api.  Otherwise, will attempt to use the configured value or will run unauthenticated.

    .INPUTS
        GitHub.Gist
        GitHub.GistComment
        GitHub.GistCommit
        GitHub.GistFork
        GitHub.GistSummary

    .EXAMPLE
        Set-GitHubGistStar -Gist 6cad326836d38bd3a7ae -Star

        Stars octocat's "hello_world.rb" gist.

    .EXAMPLE
        Set-GitHubGistStar -Gist 6cad326836d38bd3a7ae

        Unstars octocat's "hello_world.rb" gist.

    .EXAMPLE
        Get-GitHubGist -Gist 6cad326836d38bd3a7ae | Set-GitHubGistStar -Star:$false

        Unstars octocat's "hello_world.rb" gist.

#>
    [CmdletBinding(
        SupportsShouldProcess,
        PositionalBinding = $false)]
    param(
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            Position = 1)]
        [Alias('GistId')]
        [ValidateNotNullOrEmpty()]
        [string] $Gist,

        [switch] $Star,

        [string] $AccessToken
    )

    Write-InvocationLog
    Set-TelemetryEvent -EventName $MyInvocation.MyCommand.Name

    $PSBoundParameters.Remove('Star')
    if ($Star)
    {
        return Add-GitHubGistStar @PSBoundParameters
    }
    else
    {
        return Remove-GitHubGistStar @PSBoundParameters
    }
}

filter Add-GitHubGistStar
{
<#
    .SYNOPSIS
        Star a gist from GitHub.

    .DESCRIPTION
        Star a gist from GitHub.

        The Git repo for this module can be found here: http://aka.ms/PowerShellForGitHub

    .PARAMETER Gist
        The ID of the specific Gist that you wish to star.

    .PARAMETER AccessToken
        If provided, this will be used as the AccessToken for authentication with the
        REST Api.  Otherwise, will attempt to use the configured value or will run unauthenticated.

    .INPUTS
        GitHub.Gist
        GitHub.GistComment
        GitHub.GistCommit
        GitHub.GistFork
        GitHub.GistSummary

    .EXAMPLE
        Add-GitHubGistStar -Gist 6cad326836d38bd3a7ae

        Stars octocat's "hello_world.rb" gist.

    .EXAMPLE
        Star-GitHubGist -Gist 6cad326836d38bd3a7ae

        Stars octocat's "hello_world.rb" gist.  This is using the alias for the command.
        The result is the same whether you use Add-GitHubGistStar or Star-GitHubGist.
#>
    [CmdletBinding(
        SupportsShouldProcess,
        PositionalBinding = $false)]
    [Alias('Star-GitHubGist')]
    param(
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            Position = 1)]
        [Alias('GistId')]
        [ValidateNotNullOrEmpty()]
        [string] $Gist,

        [string] $AccessToken
    )

    Write-InvocationLog

    if (-not $PSCmdlet.ShouldProcess($Gist, "Starring gist"))
    {
        return
    }

    $telemetryProperties = @{}
    $params = @{
        'UriFragment' = "gists/$Gist/star"
        'Method' = 'Put'
        'Description' =  "Starring gist $Gist"
        'AccessToken' = $AccessToken
        'TelemetryEventName' = $MyInvocation.MyCommand.Name
        'TelemetryProperties' = $telemetryProperties
    }

    return Invoke-GHRestMethod @params
}

filter Remove-GitHubGistStar
{
<#
    .SYNOPSIS
        Unstar a gist from GitHub.

    .DESCRIPTION
        Unstar a gist from GitHub.

        The Git repo for this module can be found here: http://aka.ms/PowerShellForGitHub

    .PARAMETER Gist
        The ID of the specific gist that you wish to unstar.

    .PARAMETER AccessToken
        If provided, this will be used as the AccessToken for authentication with the
        REST Api.  Otherwise, will attempt to use the configured value or will run unauthenticated.

    .INPUTS
        GitHub.Gist
        GitHub.GistComment
        GitHub.GistCommit
        GitHub.GistFork
        GitHub.GistSummary

    .EXAMPLE
        Remove-GitHubGistStar -Gist 6cad326836d38bd3a7ae

        Unstars octocat's "hello_world.rb" gist.

    .EXAMPLE
        Unstar-GitHubGist -Gist 6cad326836d38bd3a7ae

        Unstars octocat's "hello_world.rb" gist.  This is using the alias for the command.
        The result is the same whether you use Remove-GitHubGistStar or Unstar-GitHubGist.
#>
    [CmdletBinding(
        SupportsShouldProcess,
        PositionalBinding = $false)]
    [Alias('Unstar-GitHubGist')]
    param(
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            Position = 1)]
        [Alias('GistId')]
        [ValidateNotNullOrEmpty()]
        [string] $Gist,

        [string] $AccessToken
    )

    Write-InvocationLog

    if (-not $PSCmdlet.ShouldProcess($Gist, "Unstarring gist"))
    {
        return
    }

    $telemetryProperties = @{}
    $params = @{
        'UriFragment' = "gists/$Gist/star"
        'Method' = 'Delete'
        'Description' =  "Unstarring gist $Gist"
        'AccessToken' = $AccessToken
        'TelemetryEventName' = $MyInvocation.MyCommand.Name
        'TelemetryProperties' = $telemetryProperties
    }

    return Invoke-GHRestMethod @params
}

filter Test-GitHubGistStar
{
<#
    .SYNOPSIS
        Checks if a gist from GitHub is starred.

    .DESCRIPTION
        Checks if a gist from GitHub is starred.
        Will return $false if it isn't starred, as well as if it couldn't be checked
        (due to permissions or non-existence).

        The Git repo for this module can be found here: http://aka.ms/PowerShellForGitHub

    .PARAMETER Gist
        The ID of the specific gist that you wish to check.

    .PARAMETER AccessToken
        If provided, this will be used as the AccessToken for authentication with the
        REST Api.  Otherwise, will attempt to use the configured value or will run unauthenticated.

    .INPUTS
        GitHub.Gist
        GitHub.GistComment
        GitHub.GistCommit
        GitHub.GistFork
        GitHub.GistSummary

    .OUTPUTS
        Boolean indicating if the gist was both found and determined to be starred.

    .EXAMPLE
        Test-GitHubGistStar -Gist 6cad326836d38bd3a7ae

        Returns $true if the gist is starred, or $false if isn't starred or couldn't be checked
        (due to permissions or non-existence).
#>
    [CmdletBinding(PositionalBinding = $false)]
    [OutputType([bool])]
    param(
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            Position = 1)]
        [Alias('GistId')]
        [ValidateNotNullOrEmpty()]
        [string] $Gist,

        [string] $AccessToken
    )

    Write-InvocationLog

    $telemetryProperties = @{}
    $params = @{
        'UriFragment' = "gists/$Gist/star"
        'Method' = 'Get'
        'Description' =  "Checking if gist $Gist is starred"
        'AccessToken' = $AccessToken
        'TelemetryEventName' = $MyInvocation.MyCommand.Name
        'TelemetryProperties' = $telemetryProperties
        'ExtendedResult' = $true
    }

    try
    {
        $response = Invoke-GHRestMethod @params
        return $response.StatusCode -eq 204
    }
    catch
    {
        return $false
    }
}

filter New-GitHubGist
{
<#
    .SYNOPSIS
        Creates a new gist on GitHub.

    .DESCRIPTION
        Creates a new gist on GitHub.

        The Git repo for this module can be found here: http://aka.ms/PowerShellForGitHub

    .PARAMETER File
        An array of filepaths that should be part of this gist.
        Use this when you have multiple files that should be part of a gist, or when you simply
        want to reference an existing file on disk.

    .PARAMETER FileName
        The name of the file that Content should be stored in within the newly created gist.

    .PARAMETER Content
        The content of a single file that should be part of the gist.

    .PARAMETER Description
        A descriptive name for this gist.

    .PARAMETER Public
        When specified, the gist will be public and available for anyone to see.

    .PARAMETER AccessToken
        If provided, this will be used as the AccessToken for authentication with the
        REST Api.  Otherwise, will attempt to use the configured value or will run unauthenticated.

    .INPUTS
        String - Filename(s) of file(s) that should be the content of the gist.

    .OUTPUTS
        GitHub.GitDetail

    .EXAMPLE
        New-GitHubGist -FileName 'sample.txt' -Content 'Body of my file.' -Description 'This is my gist!' -Public

        Creates a new public gist with a single file named 'sample.txt' that has the body of "Body of my file."

    .EXAMPLE
        New-GitHubGist -File 'c:\files\foo.txt' -Description 'This is my gist!'

        Creates a new private gist with a single file named 'foo.txt'.  Will populate it with the
        content of the file at c:\files\foo.txt.

    .EXAMPLE
        New-GitHubGist -File ('c:\files\foo.txt', 'c:\other\bar.txt', 'c:\octocat.ps1') -Description 'This is my gist!'

        Creates a new private gist with a three files named 'foo.txt', 'bar.txt' and 'octocat.ps1'.
        Each will be populated with the content from the file on disk at the specified location.
#>
    [CmdletBinding(
        SupportsShouldProcess,
        DefaultParameterSetName='FileRef',
        PositionalBinding = $false)]
    [OutputType({$script:GitHubGistTypeName})]
    param(
        [Parameter(
            Mandatory,
            ValueFromPipeline,
            ParameterSetName='FileRef',
            Position = 1)]
        [ValidateNotNullOrEmpty()]
        [string[]] $File,

        [Parameter(
            Mandatory,
            ParameterSetName='Content',
            Position = 1)]
        [ValidateNotNullOrEmpty()]
        [string] $FileName,

        [Parameter(
            Mandatory,
            ParameterSetName='Content',
            Position = 2)]
        [ValidateNotNullOrEmpty()]
        [string] $Content,

        [string] $Description,

        [switch] $Public,

        [string] $AccessToken
    )

    begin
    {
        $files = @{}
    }

    process
    {
        foreach ($path in $File)
        {
            $path = Resolve-UnverifiedPath -Path $path
            if (-not (Test-Path -Path $path -PathType Leaf))
            {
                $message = "Specified file [$path] could not be found or was inaccessible."
                Write-Log -Message $message -Level Error
                throw $message
            }

            $content = [System.IO.File]::ReadAllText($path)
            $fileName = (Get-Item -Path $path).Name

            if ($files.ContainsKey($fileName))
            {
                $message = "You have specified more than one file with the same name [$fileName].  gists don't have a concept of directory structures, so please ensure each file has a unique name."
                Write-Log -Message $message -Level Error
                throw $message
            }

            $files[$fileName] = @{ 'content' = $Content }
        }
    }

    end
    {
        Write-InvocationLog

        $telemetryProperties = @{}

        if ($PSCmdlet.ParameterSetName -eq 'Content')
        {
            $files[$FileName] = @{ 'content' = $Content }
        }

        if (($files.Keys.StartsWith('gistfile') | Where-Object { $_ -eq $true }).Count -gt 0)
        {
            $message = "Don't name your files starting with 'gistfile'. This is the format of the automatic naming scheme that Gist uses internally."
            Write-Log -Message $message -Level Error
            throw $message
        }

        $hashBody = @{
            'description' = $Description
            'public' = $Public.ToBool()
            'files' = $files
        }

        if (-not $PSCmdlet.ShouldProcess('Create new gist'))
        {
            return
        }

        $params = @{
            'UriFragment' = "gists"
            'Body' = (ConvertTo-Json -InputObject $hashBody)
            'Method' = 'Post'
            'Description' =  "Creating a new gist"
            'AccessToken' = $AccessToken
            'TelemetryEventName' = $MyInvocation.MyCommand.Name
            'TelemetryProperties' = $telemetryProperties
        }

        return (Invoke-GHRestMethod @params |
            Add-GitHubGistAdditionalProperties -TypeName $script:GitHubGistTypeName)
    }
}

filter Set-GitHubGist
{
<#
    .SYNOPSIS
        Updates a gist on GitHub.

    .DESCRIPTION
        Updates a gist on GitHub.

        The Git repo for this module can be found here: http://aka.ms/PowerShellForGitHub

    .PARAMETER Gist
        The ID for the gist to update.

    .PARAMETER Update
        A hashtable of files to update in the gist.
        The key should be the name of the file in the gist as it exists right now.
        The value should be another hashtable with the following optional key/value pairs:
            fileName - Specify a new name here if you want to rename the file.
            filePath - Specify a path to a file on disk if you wish to update the contents of the
                       file in the gist with the contents of the specified file.
                       Should not be specified if you use 'content' (below)
            content  - Directly specify the raw content that the file in the gist should be updated with.
                       Should not be used if you use 'filePath' (above).

    .PARAMETER Delete
        A list of filenames that should be removed from this gist.

    .PARAMETER Description
        New description for this gist.

    .PARAMETER Force
        If this switch is specified, you will not be prompted for confirmation of command execution.

    .PARAMETER PassThru
        Returns the updated gist.  By default, this cmdlet does not generate any output.
        You can use "Set-GitHubConfiguration -DefaultPassThru" to control the default behavior
        of this switch.

    .PARAMETER AccessToken
        If provided, this will be used as the AccessToken for authentication with the
        REST Api.  Otherwise, will attempt to use the configured value or will run unauthenticated.

    .INPUTS
        GitHub.Gist
        GitHub.GistComment
        GitHub.GistCommit
        GitHub.GistFork
        GitHub.GistSummary

    .OUTPUTS
        GitHub.GistDetail

    .EXAMPLE
        Set-GitHubGist -Gist 6cad326836d38bd3a7ae -Description 'This is my newer description'

        Updates the description for the specified gist.

    .EXAMPLE
        Set-GitHubGist -Gist 6cad326836d38bd3a7ae -Delete 'hello_world.rb' -Force

        Deletes the 'hello_world.rb' file from the specified gist without prompting for confirmation.

    .EXAMPLE
        Set-GitHubGist -Gist 6cad326836d38bd3a7ae -Delete 'hello_world.rb' -Description 'This is my newer description'

        Deletes the 'hello_world.rb' file from the specified gist and updates the description.

    .EXAMPLE
        Set-GitHubGist -Gist 6cad326836d38bd3a7ae -Update @{'hello_world.rb' = @{ 'fileName' = 'hello_universe.rb' }}

        Renames the 'hello_world.rb' file in the specified gist to be 'hello_universe.rb'.

    .EXAMPLE
        Set-GitHubGist -Gist 6cad326836d38bd3a7ae -Update @{'hello_world.rb' = @{ 'fileName' = 'hello_universe.rb' }}

        Renames the 'hello_world.rb' file in the specified gist to be 'hello_universe.rb'.
#>
    [CmdletBinding(
        SupportsShouldProcess,
        DefaultParameterSetName='Content',
        PositionalBinding = $false)]
    [OutputType({$script:GitHubGistTypeName})]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSReviewUnusedParameter", "", Justification="PassThru is accessed indirectly via Resolve-ParameterWithDefaultConfigurationValue")]
    param(
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            Position = 1)]
        [Alias('GistId')]
        [ValidateNotNullOrEmpty()]
        [string] $Gist,

        [hashtable] $Update,

        [string[]] $Delete,

        [string] $Description,

        [switch] $Force,

        [switch] $PassThru,

        [string] $AccessToken
    )

    Write-InvocationLog

    $telemetryProperties = @{}

    $files = @{}

    $shouldProcessMessage = 'Update gist'

    # Mark the files that should be deleted.
    if ($Delete.Count -gt 0)
    {
        $ConfirmPreference = 'Low'
        $shouldProcessMessage = 'Update gist (and remove files)'

        foreach ($toDelete in $Delete)
        {
            $files[$toDelete] = $null
        }
    }

    # Then figure out which ones need content updates and/or file renames
    if ($null -ne $Update)
    {
        foreach ($toUpdate in $Update.GetEnumerator())
        {
            $currentFileName = $toUpdate.Key

            $providedContent = $toUpdate.Value.Content
            $providedFileName = $toUpdate.Value.FileName
            $providedFilePath = $toUpdate.Value.FilePath

            if (-not [String]::IsNullOrWhiteSpace($providedContent))
            {
                $files[$currentFileName] = @{ 'content' = $providedContent }
            }

            if (-not [String]::IsNullOrWhiteSpace($providedFilePath))
            {
                if (-not [String]::IsNullOrWhiteSpace($providedContent))
                {
                    $message = "When updating a file [$currentFileName], you cannot provide both a path to a file [$providedFilePath] and the raw content."
                    Write-Log -Message $message -Level Error
                    throw $message
                }

                $providedFilePath = Resolve-Path -Path $providedFilePath
                if (-not (Test-Path -Path $providedFilePath -PathType Leaf))
                {
                    $message = "Specified file [$providedFilePath] could not be found or was inaccessible."
                    Write-Log -Message $message -Level Error
                    throw $message
                }

                $newContent = [System.IO.File]::ReadAllText($providedFilePath)
                $files[$currentFileName] = @{ 'content' = $newContent }
            }

            # The user has chosen to rename the file.
            if (-not [String]::IsNullOrWhiteSpace($providedFileName))
            {
                $files[$currentFileName] = @{ 'filename' = $providedFileName }
            }
        }
    }

    $hashBody = @{}
    if (-not [String]::IsNullOrWhiteSpace($Description)) { $hashBody['description'] = $Description }
    if ($files.Keys.count -gt 0) { $hashBody['files'] = $files }

    if ($Force -and (-not $Confirm))
    {
        $ConfirmPreference = 'None'
    }

    if (-not $PSCmdlet.ShouldProcess($Gist, $shouldProcessMessage))
    {
        return
    }

    $ConfirmPreference = 'None'
    $params = @{
        'UriFragment' = "gists/$Gist"
        'Body' = (ConvertTo-Json -InputObject $hashBody)
        'Method' = 'Patch'
        'Description' =  "Updating gist $Gist"
        'AccessToken' = $AccessToken
        'TelemetryEventName' = $MyInvocation.MyCommand.Name
        'TelemetryProperties' = $telemetryProperties
    }

    try
    {
        $result = (Invoke-GHRestMethod @params |
            Add-GitHubGistAdditionalProperties -TypeName $script:GitHubGistTypeName)

        if (Resolve-ParameterWithDefaultConfigurationValue -Name PassThru -ConfigValueName DefaultPassThru)
        {
            return $result
        }
    }
    catch
    {
        if ($_.Exception.Message -like '*(422)*')
        {
            $message = 'This error can happen if you try to delete a file that doesn''t exist.  Be aware that casing matters.  ''A.txt'' is not the same as ''a.txt''.'
            Write-Log -Message $message -Level Warning
        }

        throw
    }
}

function Set-GitHubGistFile
{
<#
    .SYNOPSIS
        Updates content of file(s) in an existing gist on GitHub,
        or adds them if they aren't already part of the gist.

    .DESCRIPTION
        Updates content of file(s) in an existing gist on GitHub,
        or adds them if they aren't already part of the gist.

        This is a helper function built on top of Set-GitHubGist.

        The Git repo for this module can be found here: http://aka.ms/PowerShellForGitHub

    .PARAMETER Gist
        The ID for the gist to update.

    .PARAMETER File
        An array of filepaths that should be part of this gist.
        Use this when you have multiple files that should be part of a gist, or when you simply
        want to reference an existing file on disk.

    .PARAMETER FileName
        The name of the file that Content should be stored in within the newly created gist.

    .PARAMETER Content
        The content of a single file that should be part of the gist.

    .PARAMETER PassThru
        Returns the updated gist.  By default, this cmdlet does not generate any output.
        You can use "Set-GitHubConfiguration -DefaultPassThru" to control the default behavior
        of this switch.

    .PARAMETER AccessToken
        If provided, this will be used as the AccessToken for authentication with the
        REST Api.  Otherwise, will attempt to use the configured value or will run unauthenticated.

    .INPUTS
        GitHub.Gist
        GitHub.GistComment
        GitHub.GistCommit
        GitHub.GistFork
        GitHub.GistSummary

    .OUTPUTS
        GitHub.Gist

    .EXAMPLE
        Set-GitHubGistFile -Gist 1234567 -Content 'Body of my file.' -FileName 'sample.txt'

        Adds a file named 'sample.txt' that has the body of "Body of my file." to the existing
        specified gist, or updates the contents of 'sample.txt' in the gist if is already there.

    .EXAMPLE
        Set-GitHubGistFile -Gist 1234567 -File 'c:\files\foo.txt'

        Adds the file 'foo.txt' to the existing specified gist, or updates its content if it
        is already there.

    .EXAMPLE
        Set-GitHubGistFile -Gist 1234567 -File ('c:\files\foo.txt', 'c:\other\bar.txt', 'c:\octocat.ps1')

        Adds all three files to the existing specified gist, or updates the contents of the files
        in the gist if they are already there.
#>
    [CmdletBinding(
        SupportsShouldProcess,
        DefaultParameterSetName='Content',
        PositionalBinding = $false)]
    [OutputType({$script:GitHubGistTypeName})]
    [Alias('Add-GitHubGistFile')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSShouldProcess", "", Justification="This is a helper method for Set-GitHubGist which will handle ShouldProcess.")]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSReviewUnusedParameter", "", Justification="PassThru is accessed indirectly via Resolve-ParameterWithDefaultConfigurationValue")]
    param(
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            Position = 1)]
        [Alias('GistId')]
        [ValidateNotNullOrEmpty()]
        [string] $Gist,

        [Parameter(
            Mandatory,
            ValueFromPipeline,
            ParameterSetName='FileRef',
            Position = 2)]
        [ValidateNotNullOrEmpty()]
        [string[]] $File,

        [Parameter(
            Mandatory,
            ParameterSetName='Content',
            Position = 2)]
        [ValidateNotNullOrEmpty()]
        [string] $FileName,

        [Parameter(
            Mandatory,
            ParameterSetName='Content',
            Position = 3)]
        [ValidateNotNullOrEmpty()]
        [string] $Content,

        [switch] $PassThru,

        [string] $AccessToken
    )

    begin
    {
        $files = @{}
    }

    process
    {
        foreach ($path in $File)
        {
            $path = Resolve-UnverifiedPath -Path $path
            if (-not (Test-Path -Path $path -PathType Leaf))
            {
                $message = "Specified file [$path] could not be found or was inaccessible."
                Write-Log -Message $message -Level Error
                throw $message
            }

            $fileName = (Get-Item -Path $path).Name
            $files[$fileName] = @{ 'filePath' = $path }
        }
    }

    end
    {
        Write-InvocationLog
        Set-TelemetryEvent -EventName $MyInvocation.MyCommand.Name

        if ($PSCmdlet.ParameterSetName -eq 'Content')
        {
            $files[$FileName] = @{ 'content' = $Content }
        }

        $params = @{
            'Gist' = $Gist
            'Update' = $files
            'PassThru' = (Resolve-ParameterWithDefaultConfigurationValue -Name PassThru -ConfigValueName DefaultPassThru)
            'AccessToken' = $AccessToken
        }

        return (Set-GitHubGist @params)
    }
}

function Remove-GitHubGistFile
{
<#
    .SYNOPSIS
        Removes one or more files from an existing gist on GitHub.

    .DESCRIPTION
        Removes one or more files from an existing gist on GitHub.

        This is a helper function built on top of Set-GitHubGist.

        The Git repo for this module can be found here: http://aka.ms/PowerShellForGitHub

    .PARAMETER Gist
        The ID for the gist to update.

    .PARAMETER FileName
        An array of filenames (no paths, just names) to remove from the gist.

    .PARAMETER Force
        If this switch is specified, you will not be prompted for confirmation of command execution.

    .PARAMETER PassThru
        Returns the updated gist.  By default, this cmdlet does not generate any output.
        You can use "Set-GitHubConfiguration -DefaultPassThru" to control the default behavior
        of this switch.

    .PARAMETER AccessToken
        If provided, this will be used as the AccessToken for authentication with the
        REST Api.  Otherwise, will attempt to use the configured value or will run unauthenticated.

    .INPUTS
        GitHub.Gist
        GitHub.GistComment
        GitHub.GistCommit
        GitHub.GistFork
        GitHub.GistSummary

    .OUTPUTS
        GitHub.Gist

    .EXAMPLE
        Remove-GitHubGistFile -Gist 1234567 -FileName ('foo.txt')

        Removes the file 'foo.txt' from the specified gist.

    .EXAMPLE
        Remove-GitHubGistFile -Gist 1234567 -FileName ('foo.txt') -Force

        Removes the file 'foo.txt' from the specified gist without prompting for confirmation.

    .EXAMPLE
        @('foo.txt', 'bar.txt') | Remove-GitHubGistFile -Gist 1234567

        Removes the files 'foo.txt' and 'bar.txt' from the specified gist.
#>
    [CmdletBinding(
        SupportsShouldProcess,
        PositionalBinding = $false)]
    [OutputType({$script:GitHubGistTypeName})]
    [Alias('Delete-GitHubGistFile')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSShouldProcess", "", Justification="This is a helper method for Set-GitHubGist which will handle ShouldProcess.")]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSReviewUnusedParameter", "", Justification="PassThru is accessed indirectly via Resolve-ParameterWithDefaultConfigurationValue")]
    param(
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            Position = 1)]
        [Alias('GistId')]
        [ValidateNotNullOrEmpty()]
        [string] $Gist,

        [Parameter(
            Mandatory,
            ValueFromPipeline,
            Position = 2)]
        [ValidateNotNullOrEmpty()]
        [string[]] $FileName,

        [switch] $Force,

        [switch] $PassThru,

        [string] $AccessToken
    )

    begin
    {
        $files = @()
    }

    process
    {
        foreach ($name in $FileName)
        {
            $files += $name
        }
    }

    end
    {
        Write-InvocationLog
        Set-TelemetryEvent -EventName $MyInvocation.MyCommand.Name

        $params = @{
            'Gist' = $Gist
            'Delete' = $files
            'Force' = $Force
            'Confirm' = ($Confirm -eq $true)
            'PassThru' = (Resolve-ParameterWithDefaultConfigurationValue -Name PassThru -ConfigValueName DefaultPassThru)
            'AccessToken' = $AccessToken
        }

        return (Set-GitHubGist @params)
    }
}

filter Rename-GitHubGistFile
{
<#
    .SYNOPSIS
        Renames a file in a gist on GitHub.

    .DESCRIPTION
        Renames a file in a gist on GitHub.

        This is a helper function built on top of Set-GitHubGist.

        The Git repo for this module can be found here: http://aka.ms/PowerShellForGitHub

    .PARAMETER Gist
        The ID for the gist to update.

    .PARAMETER FileName
        The current file in the gist to be renamed.

    .PARAMETER NewName
        The new name of the file for the gist.

    .PARAMETER PassThru
        Returns the updated gist.  By default, this cmdlet does not generate any output.
        You can use "Set-GitHubConfiguration -DefaultPassThru" to control the default behavior
        of this switch.

    .PARAMETER AccessToken
        If provided, this will be used as the AccessToken for authentication with the
        REST Api.  Otherwise, will attempt to use the configured value or will run unauthenticated.

    .INPUTS
        GitHub.Gist
        GitHub.GistComment
        GitHub.GistCommit
        GitHub.GistFork
        GitHub.GistSummary

    .OUTPUTS
        GitHub.Gist

    .EXAMPLE
        Rename-GitHubGistFile -Gist 1234567 -FileName 'foo.txt' -NewName 'bar.txt'

        Renames the file 'foo.txt' to 'bar.txt' in the specified gist.
#>
    [CmdletBinding(
        SupportsShouldProcess,
        PositionalBinding = $false)]
    [OutputType({$script:GitHubGistTypeName})]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSShouldProcess", "", Justification="This is a helper method for Set-GitHubGist which will handle ShouldProcess.")]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSReviewUnusedParameter", "", Justification="PassThru is accessed indirectly via Resolve-ParameterWithDefaultConfigurationValue")]
    param(
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            Position = 1)]
        [Alias('GistId')]
        [ValidateNotNullOrEmpty()]
        [string] $Gist,

        [Parameter(
            Mandatory,
            Position = 2)]
        [ValidateNotNullOrEmpty()]
        [string] $FileName,

        [Parameter(
            Mandatory,
            Position = 3)]
        [ValidateNotNullOrEmpty()]
        [string] $NewName,

        [switch] $PassThru,

        [string] $AccessToken
    )

    Write-InvocationLog
    Set-TelemetryEvent -EventName $MyInvocation.MyCommand.Name

    $params = @{
        'Gist' = $Gist
        'Update' = @{$FileName = @{ 'fileName' = $NewName }}
        'PassThru' = (Resolve-ParameterWithDefaultConfigurationValue -Name PassThru -ConfigValueName DefaultPassThru)
        'AccessToken' = $AccessToken
    }

    return (Set-GitHubGist @params)
}

filter Add-GitHubGistAdditionalProperties
{
<#
    .SYNOPSIS
        Adds type name and additional properties to ease pipelining to GitHub Gist objects.

    .PARAMETER InputObject
        The GitHub object to add additional properties to.

    .PARAMETER TypeName
        The type that should be assigned to the object.

    .INPUTS
        [PSCustomObject]

    .OUTPUTS
        GitHub.Gist
        GitHub.GistCommit
        GitHub.GistFork
        GitHub.GistSummary
#>
    [CmdletBinding()]
    [OutputType({$script:GitHubGistTypeName})]
    [OutputType({$script:GitHubGistFormTypeName})]
    [OutputType({$script:GitHubGistSummaryTypeName})]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseSingularNouns", "", Justification="Internal helper that is definitely adding more than one property.")]
    param(
        [Parameter(
            Mandatory,
            ValueFromPipeline)]
        [AllowNull()]
        [AllowEmptyCollection()]
        [PSCustomObject[]] $InputObject,

        [ValidateNotNullOrEmpty()]
        [string] $TypeName = $script:GitHubGistSummaryTypeName
    )

    if ($TypeName -eq $script:GitHubGistCommitTypeName)
    {
        return Add-GitHubGistCommitAdditionalProperties -InputObject $InputObject
    }
    elseif ($TypeName -eq $script:GitHubGistForkTypeName)
    {
        return Add-GitHubGistForkAdditionalProperties -InputObject $InputObject
    }

    foreach ($item in $InputObject)
    {
        $item.PSObject.TypeNames.Insert(0, $TypeName)

        if (-not (Get-GitHubConfiguration -Name DisablePipelineSupport))
        {
            Add-Member -InputObject $item -Name 'GistId' -Value $item.id -MemberType NoteProperty -Force

            @('user', 'owner') |
                ForEach-Object {
                    if ($null -ne $item.$_)
                    {
                        $null = Add-GitHubUserAdditionalProperties -InputObject $item.$_
                    }
                }

            if ($null -ne $item.forks)
            {
                $item.forks = Add-GitHubGistForkAdditionalProperties -InputObject $item.forks
            }

            if ($null -ne $item.history)
            {
                $item.history = Add-GitHubGistCommitAdditionalProperties -InputObject $item.history
            }
        }

        Write-Output $item
    }
}

filter Add-GitHubGistCommitAdditionalProperties
{
<#
    .SYNOPSIS
        Adds type name and additional properties to ease pipelining to GitHub GistCommit objects.

    .PARAMETER InputObject
        The GitHub object to add additional properties to.

    .PARAMETER TypeName
        The type that should be assigned to the object.

    .INPUTS
        [PSCustomObject]

    .OUTPUTS
        GitHub.GistCommit
#>
    [CmdletBinding()]
    [OutputType({$script:GitHubGistCommitTypeName})]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseSingularNouns", "", Justification="Internal helper that is definitely adding more than one property.")]
    param(
        [Parameter(
            Mandatory,
            ValueFromPipeline)]
        [AllowNull()]
        [AllowEmptyCollection()]
        [PSCustomObject[]] $InputObject,

        [ValidateNotNullOrEmpty()]
        [string] $TypeName = $script:GitHubGistCommitTypeName
    )

    foreach ($item in $InputObject)
    {
        $item.PSObject.TypeNames.Insert(0, $TypeName)

        if (-not (Get-GitHubConfiguration -Name DisablePipelineSupport))
        {
            $hostName = $(Get-GitHubConfiguration -Name 'ApiHostName')
            if ($item.url -match "^https?://(?:www\.|api\.|)$hostName/gists/([^/]+)/(.+)$")
            {
                $id = $Matches[1]
                $sha = $Matches[2]

                if ($sha -ne $item.version)
                {
                    $message = "The gist commit url no longer follows the expected pattern.  Please contact the PowerShellForGitHubTeam: $item.uri"
                    Write-Log -Message $message -Level Warning
                }
            }

            Add-Member -InputObject $item -Name 'GistId' -Value $id -MemberType NoteProperty -Force
            Add-Member -InputObject $item -Name 'Sha' -Value $item.version -MemberType NoteProperty -Force

            $null = Add-GitHubUserAdditionalProperties -InputObject $item.user
        }

        Write-Output $item
    }
}

filter Add-GitHubGistForkAdditionalProperties
{
<#
    .SYNOPSIS
        Adds type name and additional properties to ease pipelining to GitHub Gist Fork objects.

    .PARAMETER InputObject
        The GitHub object to add additional properties to.

    .PARAMETER TypeName
        The type that should be assigned to the object.

    .INPUTS
        [PSCustomObject]

    .OUTPUTS
        GitHub.GistFork
#>
    [CmdletBinding()]
    [OutputType({$script:GitHubGistForkTypeName})]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseSingularNouns", "", Justification="Internal helper that is definitely adding more than one property.")]
    param(
        [Parameter(
            Mandatory,
            ValueFromPipeline)]
        [AllowNull()]
        [AllowEmptyCollection()]
        [PSCustomObject[]] $InputObject,

        [ValidateNotNullOrEmpty()]
        [string] $TypeName = $script:GitHubGistForkTypeName
    )

    foreach ($item in $InputObject)
    {
        $item.PSObject.TypeNames.Insert(0, $TypeName)

        if (-not (Get-GitHubConfiguration -Name DisablePipelineSupport))
        {
            Add-Member -InputObject $item -Name 'GistId' -Value $item.id -MemberType NoteProperty -Force

            # See here for why we need to work with both 'user' _and_ 'owner':
            # https://github.community/t/gist-api-v3-documentation-incorrect-for-forks/122545
            @('user', 'owner') |
            ForEach-Object {
                if ($null -ne $item.$_)
                {
                    $null = Add-GitHubUserAdditionalProperties -InputObject $item.$_
                }
            }
        }

        Write-Output $item
    }
}