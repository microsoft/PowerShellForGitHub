@{
    GitHubContentTypeName = 'GitHub.Content'
 }.GetEnumerator() | ForEach-Object {
     Set-Variable -Scope Script -Option ReadOnly -Name $_.Key -Value $_.Value
 }

filter Get-GitHubContent
{
    <#
    .SYNOPSIS
        Retrieve the contents of a file or directory in a repository on GitHub.

    .DESCRIPTION
        Retrieve content from files on GitHub.
        The Git repo for this module can be found here: http://aka.ms/PowerShellForGitHub

    .PARAMETER OwnerName
        Owner of the repository.
        If not supplied here, the DefaultOwnerName configuration property value will be used.

    .PARAMETER RepositoryName
        Name of the repository.
        If not supplied here, the DefaultRepositoryName configuration property value will be used.

    .PARAMETER Uri
        Uri for the repository.
        The OwnerName and RepositoryName will be extracted from here instead of needing to provide
        them individually.

    .PARAMETER Path
        The file path for which to retrieve contents

    .PARAMETER BranchName
        The branch, or defaults to the default branch of not specified.

    .PARAMETER MediaType
        The format in which the API will return the body of the issue.

        Object - Return a json object representation a file or folder.
                 This is the default if you do not pass any specific media type.
        Raw    - Return the raw contents of a file.
        Html   - For markup files such as Markdown or AsciiDoc,
                 you can retrieve the rendered HTML using the Html media type.

    .PARAMETER ResultAsString
        If this switch is specified and the MediaType is either Raw or Html then the
        resulting bytes will be decoded the result will be  returned as a string instead of bytes.
        If the MediaType is Object, then an additional property on the object named
        'contentAsString' will be included and its value will be the decoded base64 result
        as a string.

    .PARAMETER AccessToken
        If provided, this will be used as the AccessToken for authentication with the
        REST Api.  Otherwise, will attempt to use the configured value or will run unauthenticated.

    .INPUTS
        GitHub.Branch
        GitHub.Content
        GitHub.Event
        GitHub.Issue
        GitHub.IssueComment
        GitHub.Label
        GitHub.Milestone
        GitHub.PullRequest
        GitHub.Project
        GitHub.ProjectCard
        GitHub.ProjectColumn
        GitHub.Reaction
        GitHub.Release
        GitHub.ReleaseAsset
        GitHub.Repository

    .OUTPUTS
        [String]
        GitHub.Content

    .EXAMPLE
        Get-GitHubContent -OwnerName microsoft -RepositoryName PowerShellForGitHub -Path README.md -MediaType Html

        Get the Html output for the README.md file

    .EXAMPLE
        Get-GitHubContent -OwnerName microsoft -RepositoryName PowerShellForGitHub -Path LICENSE

        Get the Binary file output for the LICENSE file

    .EXAMPLE
        Get-GitHubContent -OwnerName microsoft -RepositoryName PowerShellForGitHub -Path Tests

        List the files within the "Tests" path of the repository

    .EXAMPLE
        $repo = Get-GitHubRepository -OwnerName microsoft -RepositoryName PowerShellForGitHub
        $repo | Get-GitHubContent -Path Tests

        List the files within the "Tests" path of the repository

    .NOTES
        Unable to specify Path as ValueFromPipeline because a Repository object may be incorrectly
        coerced into a string used for Path, thus confusing things.
#>
    [CmdletBinding(DefaultParameterSetName = 'Elements')]
    [OutputType([String])]
    [OutputType({$script:GitHubContentTypeName})]
    param(
        [Parameter(
            Mandatory,
            ParameterSetName = 'Elements')]
        [string] $OwnerName,

        [Parameter(
            Mandatory,
            ParameterSetName = 'Elements')]
        [string] $RepositoryName,

        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName='Uri')]
        [Alias('RepositoryUrl')]
        [string] $Uri,

        [string] $Path,

        [ValidateNotNullOrEmpty()]
        [string] $BranchName,

        [ValidateSet('Raw', 'Html', 'Object')]
        [string] $MediaType = 'Object',

        [switch] $ResultAsString,

        [string] $AccessToken
    )

    Write-InvocationLog

    $elements = Resolve-RepositoryElements
    $OwnerName = $elements.ownerName
    $RepositoryName = $elements.repositoryName

    $telemetryProperties = @{
        'OwnerName' = (Get-PiiSafeString -PlainText $OwnerName)
        'RepositoryName' = (Get-PiiSafeString -PlainText $RepositoryName)
    }

    $description = [String]::Empty

    $uriFragment = "/repos/$OwnerName/$RepositoryName/contents"

    if ($PSBoundParameters.ContainsKey('Path'))
    {
        $Path = $Path.TrimStart("\", "/")
        $uriFragment += "/$Path"
        $description = "Getting content for $Path in $RepositoryName"
    }
    else
    {
        $description = "Getting all content for in $RepositoryName"
    }

    if ($PSBoundParameters.ContainsKey('BranchName'))
    {
        $uriFragment += "?ref=$BranchName"
    }

    $params = @{
        'UriFragment' = $uriFragment
        'Description' = $description
        'AcceptHeader' = (Get-MediaAcceptHeader -MediaType $MediaType)
        'AccessToken' = $AccessToken
        'TelemetryEventName' = $MyInvocation.MyCommand.Name
        'TelemetryProperties' = $telemetryProperties
    }

    $result = Invoke-GHRestMethodMultipleResult @params

    if ($ResultAsString)
    {
        if ($MediaType -eq 'Raw' -or $MediaType -eq 'Html')
        {
            # Decode bytes to string
            $result = [System.Text.Encoding]::UTF8.GetString($result)
        }
        elseif ($MediaType -eq 'Object')
        {
            # Convert from base64
            $decoded = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($result.content))
            Add-Member -InputObject $result -NotePropertyName "contentAsString" -NotePropertyValue $decoded
        }
    }

    if ($MediaType -eq 'Object')
    {
        $null = $result | Add-GitHubContentAdditionalProperties
    }

    return $result
}

filter Set-GitHubContent
{
    <#
    .SYNOPSIS
        Sets the contents of a file or directory in a repository on GitHub.

    .DESCRIPTION
        Sets the contents of a file or directory in a repository on GitHub.

        The Git repo for this module can be found here: http://aka.ms/PowerShellForGitHub

    .PARAMETER OwnerName
        Owner of the repository.
        If not supplied here, the DefaultOwnerName configuration property value will be used.

    .PARAMETER RepositoryName
        Name of the repository.
        If not supplied here, the DefaultRepositoryName configuration property value will be used.

    .PARAMETER Uri
        Uri for the repository.
        The OwnerName and RepositoryName will be extracted from here instead of needing to provide
        them individually.

    .PARAMETER Path
        The file path for which to set contents.

    .PARAMETER CommitMessage
        The Git commit message.

    .PARAMETER Content
        The new file content.

    .PARAMETER Sha
        The SHA value of the current file if present. If this parameter is not provided, and the
        file currently exists in the specified branch of the repo, it will be read to obtain this
        value.

    .PARAMETER BranchName
        The branch, or defaults to the default branch if not specified.

    .PARAMETER CommitterName
        The name of the committer of the commit. Defaults to the name of the authenticated user if
        not specified. If specified, CommiterEmail must also be specified.

    .PARAMETER CommitterEmail
        The email of the committer of the commit. Defaults to the email of the authenticated user
        if not specified. If specified, CommitterName must also be specified.

    .PARAMETER AuthorName
        The name of the author of the commit. Defaults to the name of the authenticated user if
        not specified. If specified, AuthorEmail must also be specified.

    .PARAMETER AuthorEmail
        The email of the author of the commit. Defaults to the email of the authenticated user if
        not specified. If specified, AuthorName must also be specified.

    .PARAMETER PassThru
        Returns the updated GitHub Content.  By default, this cmdlet does not generate any output.
        You can use "Set-GitHubConfiguration -DefaultPassThru" to control the default behavior
        of this switch.

    .PARAMETER AccessToken
        If provided, this will be used as the AccessToken for authentication with the
        REST Api.  Otherwise, will attempt to use the configured value or will run unauthenticated.

     .INPUTS
        GitHub.Branch
        GitHub.Content
        GitHub.Event
        GitHub.Issue
        GitHub.IssueComment
        GitHub.Label
        GitHub.Milestone
        GitHub.PullRequest
        GitHub.Project
        GitHub.ProjectCard
        GitHub.ProjectColumn
        GitHub.Release
        GitHub.Repository

    .OUTPUTS
        GitHub.Content

    .EXAMPLE
        Set-GitHubContent -OwnerName microsoft -RepositoryName PowerShellForGitHub -Path README.md -CommitMessage 'Adding README.md' -Content '# README' -BranchName master

        Sets the contents of the README.md file on the master branch of the PowerShellForGithub repository.
#>
    [CmdletBinding(
        SupportsShouldProcess,
        PositionalBinding = $false)]
    [OutputType({$script:GitHubContentTypeName})]
    param(
        [Parameter(
            Mandatory,
            ParameterSetName = 'Elements')]
        [string] $OwnerName,

        [Parameter(
            Mandatory,
            ParameterSetName = 'Elements')]
        [string] $RepositoryName,

        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            Position = 1,
            ParameterSetName='Uri')]
        [Alias('RepositoryUrl')]
        [string] $Uri,

        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            Position = 2)]
        [string] $Path,

        [Parameter(
            Mandatory,
            Position = 3)]
        [string] $CommitMessage,

        [Parameter(
            Mandatory,
            Position = 4)]
        [string] $Content,

        [Parameter(ValueFromPipelineByPropertyName)]
        [string] $Sha,

        [Parameter(ValueFromPipelineByPropertyName)]
        [string] $BranchName,

        [string] $CommitterName,

        [string] $CommitterEmail,

        [string] $AuthorName,

        [string] $AuthorEmail,

        [switch] $PassThru,

        [string] $AccessToken
    )

    Write-InvocationLog

    $elements = Resolve-RepositoryElements -DisableValidation
    $OwnerName = $elements.ownerName
    $RepositoryName = $elements.repositoryName

    $telemetryProperties = @{
        'OwnerName' = (Get-PiiSafeString -PlainText $OwnerName)
        'RepositoryName' = (Get-PiiSafeString -PlainText $RepositoryName)
    }

    $uriFragment = "/repos/$OwnerName/$RepositoryName/contents/$Path"

    $encodedContent = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($Content))

    $hashBody = @{
        message = $CommitMessage
        content = $encodedContent
    }

    if ($PSBoundParameters.ContainsKey('BranchName'))
    {
        $hashBody['branch'] = $BranchName
    }

    if ($PSBoundParameters.ContainsKey('CommitterName') -or
        $PSBoundParameters.ContainsKey('CommitterEmail'))
    {
        if (![System.String]::IsNullOrEmpty($CommitterName) -and
            ![System.String]::IsNullOrEmpty($CommitterEmail))
        {
            $hashBody['committer'] = @{
                name = $CommitterName
                email = $CommitterEmail
            }
        }
        else
        {
            $message = 'Both CommiterName and CommitterEmail need to be specified.'
            Write-Log -Message $message -Level Error
            throw $message
        }
    }

    if ($PSBoundParameters.ContainsKey('AuthorName') -or
        $PSBoundParameters.ContainsKey('AuthorEmail'))
    {
        if (![System.String]::IsNullOrEmpty($AuthorName) -and
            ![System.String]::IsNullOrEmpty($AuthorEmail))
        {
            $hashBody['author'] = @{
                name = $AuthorName
                email = $AuthorEmail
            }
        }
        else
        {
            $message = 'Both AuthorName and AuthorEmail need to be specified.'
            Write-Log -Message $message -Level Error
            throw $message
        }
    }

    if ($PSBoundParameters.ContainsKey('Sha'))
    {
        $hashBody['sha'] = $Sha
    }

    if (-not $PSCmdlet.ShouldProcess(
        "$BranchName branch of $RepositoryName",
        "Set GitHub Contents on $Path"))
    {
        return
    }

    $params = @{
        UriFragment = $uriFragment
        Description = "Writing content for $Path in the $BranchName branch of $RepositoryName"
        Body = (ConvertTo-Json -InputObject $hashBody)
        Method = 'Put'
        AccessToken = $AccessToken
        TelemetryEventName = $MyInvocation.MyCommand.Name
        TelemetryProperties = $telemetryProperties
    }

    try
    {
        $result = (Invoke-GHRestMethod @params | Add-GitHubContentAdditionalProperties)
        if (Resolve-ParameterWithDefaultConfigurationValue -Name PassThru -ConfigValueName DefaultPassThru)
        {
            return $result
        }
    }
    catch
    {
        $overwriteShaRequired = $false

        # Temporary code to handle current differences in exception object between PS5 and PS7
        if ($PSVersionTable.PSedition -eq 'Core')
        {
            $errorMessage = ($_.ErrorDetails.Message | ConvertFrom-Json).message -replace '\n',' ' -replace '\"','"'
            if (($_.Exception -is [Microsoft.PowerShell.Commands.HttpResponseException]) -and
                ($errorMessage -eq 'Invalid request.  "sha" wasn''t supplied.'))
            {
                $overwriteShaRequired = $true
            }
            else
            {
                throw $_
            }
        }
        else
        {
            $errorMessage = $_.Exception.Message  -replace '\n',' ' -replace '\"','"'
            if ($errorMessage -like '*Invalid request.  "sha" wasn''t supplied.*')
            {
                $overwriteShaRequired = $true
            }
            else
            {
                throw $_
            }
        }

        if ($overwriteShaRequired)
        {
            # Get SHA from current file
            $getGitHubContentParms = @{
                Path = $Path
                OwnerName = $OwnerName
                RepositoryName = $RepositoryName
            }

            if ($PSBoundParameters.ContainsKey('BranchName'))
            {
                $getGitHubContentParms['BranchName'] = $BranchName
            }

            if ($PSBoundParameters.ContainsKey('AccessToken'))
            {
                $getGitHubContentParms['AccessToken'] = $AccessToken
            }

            $object = Get-GitHubContent @getGitHubContentParms

            $hashBody['sha'] = $object.sha
            $params['body'] = ConvertTo-Json -InputObject $hashBody

            $message = 'Replacing the content of an existing file requires the current SHA ' +
                'of that file.  Retrieving the SHA now.'
            Write-Log -Level Verbose -Message $message

            $result = (Invoke-GHRestMethod @params | Add-GitHubContentAdditionalProperties)
            if (Resolve-ParameterWithDefaultConfigurationValue -Name PassThru -ConfigValueName DefaultPassThru)
            {
                return $result
            }
        }
    }
}

filter Add-GitHubContentAdditionalProperties
{
<#
    .SYNOPSIS
        Adds type name and additional properties to ease pipelining to GitHub Content objects.

    .PARAMETER InputObject
        The GitHub object to add additional properties to.

    .PARAMETER TypeName
        The type that should be assigned to the object.

    .INPUTS
        [PSCustomObject]

    .OUTPUTS
        GitHub.Content
#>
    [CmdletBinding()]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseSingularNouns", "", Justification="Internal helper that is definitely adding more than one property.")]
    param(
        [Parameter(
            Mandatory,
            ValueFromPipeline)]
        [AllowNull()]
        [AllowEmptyCollection()]
        [PSCustomObject[]] $InputObject,

        [ValidateNotNullOrEmpty()]
        [string] $TypeName = $script:GitHubContentTypeName
    )

    foreach ($item in $InputObject)
    {
        $item.PSObject.TypeNames.Insert(0, $TypeName)

        if (-not (Get-GitHubConfiguration -Name DisablePipelineSupport))
        {
            if ($item.html_url)
            {
                $uri = $item.html_url
            }
            else
            {
                $uri = $item.content.html_url
            }

            $elements = Split-GitHubUri -Uri $uri
            $repositoryUrl = Join-GitHubUri @elements

            Add-Member -InputObject $item -Name 'RepositoryUrl' -Value $repositoryUrl -MemberType NoteProperty -Force

            $hostName = $(Get-GitHubConfiguration -Name 'ApiHostName')

            if ($uri -match "^https?://(?:www\.|api\.|)$hostName/(?:[^/]+)/(?:[^/]+)/(?:blob|tree)/([^/]+)/([^#]*)?$")
            {
                $branchName = $Matches[1]
                $path = $Matches[2]
            }
            else
            {
                $branchName = [String]::Empty
                $path = [String]::Empty
            }

            Add-Member -InputObject $item -Name 'BranchName' -Value $branchName -MemberType NoteProperty -Force
            Add-Member -InputObject $item -Name 'Path' -Value $path -MemberType NoteProperty -Force
        }

        Write-Output $item
    }
}
