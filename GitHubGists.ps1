# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

@{
    GitHubGistTypeName = 'GitHub.Gist'
    GitHubGistCommitTypeName = 'GitHub.GistCommit'
    GitHubGistDetailTypeName = 'GitHub.GistDetail'
    GitHubGistForkTypeName = 'GitHub.GistFork'
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

    .PARAMETER NoStatus
        If this switch is specified, long-running commands will run on the main thread
        with no commandline status update.  When not specified, those commands run in
        the background, enabling the command prompt to provide status information.
        If not supplied here, the DefaultNoStatus configuration property value will be used.

    .INPUTS
        GitHub.Gist
        GitHub.GistComment
        GitHub.GistCommit
        GitHub.GistDetail
        GitHub.GistFork

    .OUTPUTS
        GitHub.Gist
        GitHub.GistCommit
        GitHub.GistDetail
        GitHub.GistFork

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
    [OutputType({$script:GitHubGistDetailTypeName})]
    [OutputType({$script:GitHubGistForkTypeName})]
    param(
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName='Id',
            Position = 1)]
        [Alias('GistId')]
        [ValidateNotNullOrEmpty()]
        [string] $Gist,

        [Parameter(ParameterSetName='Id')]
        [ValidateNotNullOrEmpty()]
        [string] $Sha,

        [Parameter(ParameterSetName='Id')]
        [switch] $Forks,

        [Parameter(ParameterSetName='Id')]
        [switch] $Commits,

        [Parameter(ParameterSetName='User')]
        [ValidateNotNullOrEmpty()]
        [string] $UserName,

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

        [string] $AccessToken,

        [switch] $NoStatus
    )

    Write-InvocationLog -Invocation $MyInvocation

    $telemetryProperties = @{}

    $uriFragment = [String]::Empty
    $description = [String]::Empty
    $outputType = $script:GitHubGistTypeName

    if ($PSCmdlet.ParameterSetName -eq 'Id')
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
            $outputType = $script:GitHubGistDetailTypeName
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
            $outputType = $script:GitHubGistDetailTypeName
        }
    }
    elseif ($PSCmdlet.ParameterSetName -eq 'User')
    {
        $telemetryProperties['ByUserName'] = $true

        $uriFragment = "users/$UserName/gists"
        $description = "Getting public gists for $UserName"
        $outputType = $script:GitHubGistTypeName
    }
    elseif ($PSCmdlet.ParameterSetName -eq 'Current')
    {
        $telemetryProperties['CurrentUser'] = $true
        $outputType = $script:GitHubGistTypeName

        if (Test-GitHubAuthenticationConfigured -or (-not [String]::IsNullOrEmpty($AccessToken)))
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
        $outputType = $script:GitHubGistTypeName

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
        'NoStatus' = (Resolve-ParameterWithDefaultConfigurationValue -BoundParameters $PSBoundParameters -Name NoStatus -ConfigValueName DefaultNoStatus)
    }

    $result = Invoke-GHRestMethodMultipleResult @params

    if ($result.truncated -eq $true)
    {
        $message = @"
Response has been truncated.  The API will only return the first 3000 gist results,
the first 300 files within an individual gist, and the first 1 Mb of an individual file.
If the file has been truncated, you can call (Invoke-WebRequest -UseBasicParsing -Method Get -Uri <raw_url>).Content)
where <raw_url> is the value of raw_url for the file in question.  Be aware that for files larger
than 10 Mb, you'll need to clone the gist via the URL provided by git_pull_url.
"@
        Write-Log -Message $message -Level Warning
    }

    return ($result | Add-GitHubGistAdditionalProperties -TypeName $outputType)
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

    .PARAMETER NoStatus
        If this switch is specified, long-running commands will run on the main thread
        with no commandline status update.  When not specified, those commands run in
        the background, enabling the command prompt to provide status information.
        If not supplied here, the DefaultNoStatus configuration property value will be used.

    .INPUTS
        GitHub.Gist
        GitHub.GistComment
        GitHub.GistCommit
        GitHub.GistDetail
        GitHub.GistFork

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

        [string] $AccessToken,

        [switch] $NoStatus
    )

    Write-InvocationLog -Invocation $MyInvocation

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
        'NoStatus' = (Resolve-ParameterWithDefaultConfigurationValue -BoundParameters $PSBoundParameters -Name NoStatus -ConfigValueName DefaultNoStatus)
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

    .PARAMETER AccessToken
        If provided, this will be used as the AccessToken for authentication with the
        REST Api.  Otherwise, will attempt to use the configured value or will run unauthenticated.

    .PARAMETER NoStatus
        If this switch is specified, long-running commands will run on the main thread
        with no commandline status update.  When not specified, those commands run in
        the background, enabling the command prompt to provide status information.
        If not supplied here, the DefaultNoStatus configuration property value will be used.

    .INPUTS
        GitHub.Gist
        GitHub.GistComment
        GitHub.GistCommit
        GitHub.GistDetail
        GitHub.GistFork

    .OUTPUTS
        GitHub.Gist

    .EXAMPLE
        Copy-GitHubGist -Gist 6cad326836d38bd3a7ae

        Forks octocat's "hello_world.rb" gist.

    .EXAMPLE
        Fork-GitHubGist -Gist 6cad326836d38bd3a7ae

        Forks octocat's "hello_world.rb" gist.  This is using the alias for the command.
        The result is the same whether you use Copy-GitHubGist or Fork-GitHubGist.
#>
    [CmdletBinding(
        SupportsShouldProcess,
        PositionalBinding = $false)]
    [OutputType({$script:GitHubGistTypeName})]
    [Alias('Fork-GitHubGist')]
    param(
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            Position = 1)]
        [Alias('GistId')]
        [ValidateNotNullOrEmpty()]
        [string] $Gist,

        [string] $AccessToken,

        [switch] $NoStatus
    )

    Write-InvocationLog -Invocation $MyInvocation

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
        'NoStatus' = (Resolve-ParameterWithDefaultConfigurationValue -BoundParameters $PSBoundParameters -Name NoStatus -ConfigValueName DefaultNoStatus)
    }

    return (Invoke-GHRestMethod @params | Add-GitHubGistAdditionalProperties)
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

    .PARAMETER NoStatus
        If this switch is specified, long-running commands will run on the main thread
        with no commandline status update.  When not specified, those commands run in
        the background, enabling the command prompt to provide status information.
        If not supplied here, the DefaultNoStatus configuration property value will be used.

    .INPUTS
        GitHub.Gist
        GitHub.GistComment
        GitHub.GistCommit
        GitHub.GistDetail
        GitHub.GistFork

    .EXAMPLE
        Add-GitHubGistStar -Gist 6cad326836d38bd3a7ae

        STars octocat's "hello_world.rb" gist.

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

        [string] $AccessToken,

        [switch] $NoStatus
    )

    Write-InvocationLog -Invocation $MyInvocation

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
        'NoStatus' = (Resolve-ParameterWithDefaultConfigurationValue -BoundParameters $PSBoundParameters -Name NoStatus -ConfigValueName DefaultNoStatus)
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

    .PARAMETER NoStatus
        If this switch is specified, long-running commands will run on the main thread
        with no commandline status update.  When not specified, those commands run in
        the background, enabling the command prompt to provide status information.
        If not supplied here, the DefaultNoStatus configuration property value will be used.

    .INPUTS
        GitHub.Gist
        GitHub.GistComment
        GitHub.GistCommit
        GitHub.GistDetail
        GitHub.GistFork

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

        [string] $AccessToken,

        [switch] $NoStatus
    )

    Write-InvocationLog -Invocation $MyInvocation

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
        'NoStatus' = (Resolve-ParameterWithDefaultConfigurationValue -BoundParameters $PSBoundParameters -Name NoStatus -ConfigValueName DefaultNoStatus)
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

    .PARAMETER NoStatus
        If this switch is specified, long-running commands will run on the main thread
        with no commandline status update.  When not specified, those commands run in
        the background, enabling the command prompt to provide status information.
        If not supplied here, the DefaultNoStatus configuration property value will be used.

    .INPUTS
        GitHub.Gist
        GitHub.GistComment
        GitHub.GistCommit
        GitHub.GistDetail
        GitHub.GistFork

    .OUTPUTS
        Boolean indicating if the gist was both found and determined to be starred.

    .EXAMPLE
        Test-GitHubGistStar -Gist 6cad326836d38bd3a7ae

        Returns $true if the gist is starred, or $false if isn't starred or couldn't be checked
        (due to permissions or non-existence).

    .NOTES
        For some reason, this does not currently seem to be working correctly
        (even though it matches the spec: https://developer.github.com/v3/gists/#check-if-a-gist-is-starred).
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

        [string] $AccessToken,

        [switch] $NoStatus
    )

    Write-InvocationLog -Invocation $MyInvocation

    $telemetryProperties = @{}
    $params = @{
        'UriFragment' = "gists/$Gist/star"
        'Method' = 'Get'
        'Description' =  "Checking if gist $Gist is starred"
        'AccessToken' = $AccessToken
        'TelemetryEventName' = $MyInvocation.MyCommand.Name
        'TelemetryProperties' = $telemetryProperties
        'ExtendedResult' = $true
        'NoStatus' = (Resolve-ParameterWithDefaultConfigurationValue -BoundParameters $PSBoundParameters -Name NoStatus -ConfigValueName DefaultNoStatus)
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

    .PARAMETER Content
        The content of a single file that should be part of the gist.

    .PARAMETER FileName
        The name of the file that Content should be stored in within the newly created gist.

    .PARAMETER Description
        A descriptive name for this gist.

    .PARAMETER Public
        When specified, the gist will be public and available for anyone to see.

    .PARAMETER AccessToken
        If provided, this will be used as the AccessToken for authentication with the
        REST Api.  Otherwise, will attempt to use the configured value or will run unauthenticated.

    .PARAMETER NoStatus
        If this switch is specified, long-running commands will run on the main thread
        with no commandline status update.  When not specified, those commands run in
        the background, enabling the command prompt to provide status information.
        If not supplied here, the DefaultNoStatus configuration property value will be used.

    .INPUTS
        String - Filename(s) of file(s) that should be the content of the gist.

    .OUTPUTS
        GitHub.GitDetail

    .EXAMPLE
        New-GitHubGist -Content 'Body of my file.' -FileName 'sample.txt' -Description 'This is my gist!' -Public

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
    [OutputType({$script:GitHubGistDetailTypeName})]
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
        [string] $Content,

        [Parameter(
            Mandatory,
            ParameterSetName='Content',
            Position = 2)]
        [ValidateNotNullOrEmpty()]
        [string] $FileName,

        [string] $Description,

        [switch] $Public,

        [string] $AccessToken,

        [switch] $NoStatus
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
            if (-not (Test-Path -Path $path))
            {
                $message = "Specified file [$path] could not be found or was inaccessible."
                Write-Log -Message $message -Level Error
                throw $message
            }

            $content = Get-Content -Path $path -Raw -Encoding UTF8
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
        Write-InvocationLog -Invocation $MyInvocation

        $telemetryProperties = @{}

        if ($PSCmdlet.ParameterSetName -eq 'Content')
        {
            $files[$FileName] = @{ 'content' = $Content }
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
            'NoStatus' = (Resolve-ParameterWithDefaultConfigurationValue -BoundParameters $PSBoundParameters -Name NoStatus -ConfigValueName DefaultNoStatus)
        }

        return (Invoke-GHRestMethod @params |
            Add-GitHubGistAdditionalProperties -TypeName $script:GitHubGistDetailTypeName)
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

    .PARAMETER AccessToken
        If provided, this will be used as the AccessToken for authentication with the
        REST Api.  Otherwise, will attempt to use the configured value or will run unauthenticated.

    .PARAMETER NoStatus
        If this switch is specified, long-running commands will run on the main thread
        with no commandline status update.  When not specified, those commands run in
        the background, enabling the command prompt to provide status information.
        If not supplied here, the DefaultNoStatus configuration property value will be used.

    .INPUTS
        GitHub.Gist
        GitHub.GistComment
        GitHub.GistCommit
        GitHub.GistDetail
        GitHub.GistFork

    .OUTPUTS
        GitHub.GistDetail

    .EXAMPLE
        Set-GitHubGist -Gist 6cad326836d38bd3a7ae -Description 'This is my newer description'

        Updates the description for the specified gist.

    .EXAMPLE
        Set-GitHubGist -Gist 6cad326836d38bd3a7ae -Delete 'hello_world.rb'

        Deletes the 'hello_world.rb' file from the specified gist.

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
    [OutputType({$script:GitHubGistDetailTypeName})]
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

        [string] $AccessToken,

        [switch] $NoStatus
    )

    Write-InvocationLog -Invocation $MyInvocation

    $telemetryProperties = @{}

    $files = @{}

    # Mark the files that should be deleted.
    foreach ($toDelete in $Delete)
    {
        $files[$toDelete] = $null
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
                    $message = "When updating a file [$currentFileName], you cannot provide both a path to a file [$providedPath] and the raw content."
                    Write-Log -Message $message -Level Error
                    throw $message
                }

                $providedPath = Resolve-Path -Path $providedPath
                if (-not (Test-Path -Path $providedPath))
                {
                    $message = "Specified file [$providedPath] could not be found or was inaccessible."
                    Write-Log -Message $message -Level Error
                    throw $message
                }

                $newContent = Get-Content -Path $providedFilePath -Raw -Encoding UTF8
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

    if (-not $PSCmdlet.ShouldProcess($Gist, 'Update gist'))
    {
        return
    }

    $params = @{
        'UriFragment' = "gists/$Gist"
        'Body' = (ConvertTo-Json -InputObject $hashBody)
        'Method' = 'Patch'
        'Description' =  "Updating gist $Gist"
        'AccessToken' = $AccessToken
        'TelemetryEventName' = $MyInvocation.MyCommand.Name
        'TelemetryProperties' = $telemetryProperties
        'NoStatus' = (Resolve-ParameterWithDefaultConfigurationValue -BoundParameters $PSBoundParameters -Name NoStatus -ConfigValueName DefaultNoStatus)
    }

    try
    {
        return (Invoke-GHRestMethod @params |
            Add-GitHubGistAdditionalProperties -TypeName $script:GitHubGistDetailTypeName)
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
        GitHub.GistDetail
        GitHub.GistFork
#>
    [CmdletBinding()]
    [OutputType({$script:GitHubGistTypeName})]
    [OutputType({$script:GitHubGistDetailTypeName})]
    [OutputType({$script:GitHubGistFormTypeName})]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseSingularNouns", "", Justification="Internal helper that is definitely adding more than one property.")]
    param(
        [Parameter(
            Mandatory,
            ValueFromPipeline)]
        [AllowNull()]
        [AllowEmptyCollection()]
        [PSCustomObject[]] $InputObject,

        [ValidateNotNullOrEmpty()]
        [string] $TypeName = $script:GitHubGistTypeName
    )

    if ($TypeName -eq $script:GitHubGistCommitTypeName)
    {
        return Add-GitHubGistCommitAdditionalProperties -InputObject $InputObject
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

            foreach ($fork in $item.forks)
            {
                Add-Member -InputObject $fork -Name 'GistId' -Value $fork.id -MemberType NoteProperty -Force
                $null = Add-GitHubUserAdditionalProperties -InputObject $fork.user
            }

            foreach ($entry in $item.history)
            {
                $null = Add-GitHubGistCommitAdditionalProperties -InputObject $entry
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
            if ($item.uri -match "^https?://(?:www\.|api\.|)$hostName/gists/([^/]+)/(.+)$")
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