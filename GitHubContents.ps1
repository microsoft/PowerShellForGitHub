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

    .PARAMETER NoStatus
        If this switch is specified, long-running commands will run on the main thread
        with no commandline status update.  When not specified, those commands run in
        the background, enabling the command prompt to provide status information.
        If not supplied here, the DefaultNoStatus configuration property value will be used.

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
    [CmdletBinding(
        SupportsShouldProcess,
        DefaultParameterSetName = 'Elements')]
    [OutputType([String])]
    [OutputType({$script:GitHubContentTypeName})]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSShouldProcess", "", Justification = "Methods called within here make use of PSShouldProcess, and the switch is passed on to them inherently.")]
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

        [string] $BranchName,

        [ValidateSet('Raw', 'Html', 'Object')]
        [string] $MediaType = 'Object',

        [switch] $ResultAsString,

        [string] $AccessToken,

        [switch] $NoStatus
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

    if ($PSBoundParameters.ContainsKey('Branch'))
    {
        $uriFragment += "?ref=$Branch"
    }

    $params = @{
        'UriFragment' = $uriFragment
        'Description' = $description
        'AcceptHeader' = (Get-MediaAcceptHeader -MediaType $MediaType)
        'AccessToken' = $AccessToken
        'TelemetryEventName' = $MyInvocation.MyCommand.Name
        'TelemetryProperties' = $telemetryProperties
        'NoStatus' = (Resolve-ParameterWithDefaultConfigurationValue -Name NoStatus -ConfigValueName DefaultNoStatus)
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

function Set-GitHubContent
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

    .PARAMETER BranchName
        The branch, or defaults to the default branch of not specified.

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

    .PARAMETER AccessToken
        If provided, this will be used as the AccessToken for authentication with the
        REST Api.  Otherwise, will attempt to use the configured value or will run unauthenticated.

    .PARAMETER NoStatus
        If this switch is specified, long-running commands will run on the main thread
        with no commandline status update.  When not specified, those commands run in
        the background, enabling the command prompt to provide status information.
        If not supplied here, the DefaultNoStatus configuration property value will be used.

    .EXAMPLE
        Set-GitHubContent  -Path README.md -OwnerName microsoft -RepositoryName PowerShellForGitHub -CommitMessage 'Adding README.md' -Content '# README' -BranchName master

        Sets the contents of the README.md file on the master branch of the PowerShellForGithub repository.
#>
    [CmdletBinding(
        SupportsShouldProcess,
        PositionalBinding = $false,
        DefaultParameterSetName = 'Elements')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '',
        Justification='One or more parameters (like NoStatus) are only referenced by helper methods which get access to it from the stack via Get-Variable -Scope 1.')]
    param(
        [Parameter(
            Mandatory,
            Position = 1)]
        [string] $Path,

        [Parameter(
            Mandatory,
            Position = 2)]
        [string] $CommitMessage,

        [Parameter(
            Mandatory,
            Position = 3)]
        [string] $Content,

        [Parameter(
            Mandatory,
            ParameterSetName='Uri')]
        [string] $Uri,

        [Parameter(
            Mandatory,
            ParameterSetName = 'Elements')]
        [string] $OwnerName,

        [Parameter(
            Mandatory,
            ParameterSetName = 'Elements')]
        [string] $RepositoryName,

        [string] $BranchName,

        [string] $CommitterName,

        [string] $CommitterEmail,

        [string] $AuthorName,

        [string] $AuthorEmail,

        [string] $AccessToken,

        [switch] $NoStatus
    )

    $elements = Resolve-RepositoryElements -DisableValidation
    $OwnerName = $elements.ownerName
    $RepositoryName = $elements.repositoryName

    $telemetryProperties = @{
        'OwnerName' = (Get-PiiSafeString -PlainText $OwnerName)
        'RepositoryName' = (Get-PiiSafeString -PlainText $RepositoryName)
    }

    $uriFragment = "/repos/$OwnerName/$RepositoryName/contents/$Path"

    $encodedContent = [Convert]::ToBase64String([System.Text.Encoding]::Unicode.GetBytes($Content))

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
            throw 'Both CommiterName and CommitterEmail need to be specified.'
        }
    }

    if ($PSBoundParameters.ContainsKey('AuthorName') -or
        $PSBoundParameters.ContainsKey('AuthorEmail'))
    {
        if (![System.String]::IsNullOrEmpty($CommitterName) -and
            ![System.String]::IsNullOrEmpty($CommitterEmail))
        {
            $hashBody['author'] = @{
                name = $AuthorName
                email = $AuthorEmail
            }
        }
        else
        {
            throw 'Both AuthorName and AuthorEmail need to be specified.'
        }
    }

    if ($PSCmdlet.ShouldProcess("$BranchName branch of $RepositoryName",
        "Set GitHub Contents on $Path"))
    {
        Write-InvocationLog

        $params = @{
            UriFragment = $uriFragment
            Description = "Writing content for $Path in the $BranchName branch of $RepositoryName"
            Body = (ConvertTo-Json -InputObject $hashBody)
            Method = 'Put'
            AccessToken = $AccessToken
            TelemetryEventName = $MyInvocation.MyCommand.Name
            TelemetryProperties = $telemetryProperties
            NoStatus = (Resolve-ParameterWithDefaultConfigurationValue -Name NoStatus `
                -ConfigValueName DefaultNoStatus)
        }

        try
        {
            return Invoke-GHRestMethod @params
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

                if ($PSBoundParameters.ContainsKey('NoStatus'))
                {
                    $getGitHubContentParms['NoStatus'] = $NoStatus
                }

                $object = Get-GitHubContent @getGitHubContentParms

                $hashBody['sha'] = $object.sha
                $params['body'] = ConvertTo-Json -InputObject $hashBody

                return Invoke-GHRestMethod @params
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
            $elements = Split-GitHubUri -Uri $item.url
            $repositoryUrl = Join-GitHubUri @elements
            Add-Member -InputObject $item -Name 'RepositoryUrl' -Value $repositoryUrl -MemberType NoteProperty -Force
        }

        Write-Output $item
    }
}