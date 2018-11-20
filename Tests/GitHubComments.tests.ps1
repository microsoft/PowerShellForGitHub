# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

<#
.Synopsis
   Tests for GitHubComments.ps1 module
#>

[String] $root = Split-Path -Parent (Split-Path -Parent $Script:MyInvocation.MyCommand.Path)
. (Join-Path -Path $root -ChildPath 'Tests\Config\Settings.ps1')
Import-Module -Name $root -Force

function Initialize-AppVeyor
{
<#
    .SYNOPSIS
        Configures the tests to run with the authentication information stored in AppVeyor
        (if that information exists in the environment).

    .DESCRIPTION
        Configures the tests to run with the authentication information stored in AppVeyor
        (if that information exists in the environment).

        The Git repo for this module can be found here: http://aka.ms/PowerShellForGitHub

    .NOTES
        Internal-only helper method.

        The only reason this exists is so that we can leverage CodeAnalysis.SuppressMessageAttribute,
        which can only be applied to functions.

        We call this immediately after the declaration so that AppVeyor initialization can heppen
        (if applicable).

#>
    [CmdletBinding()]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingConvertToSecureStringWithPlainText", "", Justification="Needed to configure with the stored, encrypted string value in AppVeyor.")]
    param()

    if ($env:AppVeyor)
    {
        $secureString = $env:avAccessToken | ConvertTo-SecureString -AsPlainText -Force
        $cred = New-Object System.Management.Automation.PSCredential "<username is ignored>", $secureString
        Set-GitHubAuthentication -Credential $cred

        $script:ownerName = $env:avOwnerName
        $script:organizationName = $env:avOrganizationName

        $message = @(
            'This run is executed in the AppVeyor environment.',
            'The GitHub Api Token won''t be decrypted in PR runs causing some tests to fail.',
            '403 errors possible due to GitHub hourly limit for unauthenticated queries.',
            'Use Set-GitHubAuthentication manually. modify the values in Tests\Config\Settings.ps1,',
            'and run tests on your machine first.')
        Write-Warning -Message ($message -join [Environment]::NewLine)
    }
}

Initialize-AppVeyor

$script:accessTokenConfigured = Test-GitHubAuthenticationConfigured
if (-not $script:accessTokenConfigured)
{
    $message = @(
        'GitHub API Token not defined, some of the tests will be skipped.',
        '403 errors possible due to GitHub hourly limit for unauthenticated queries.')
    Write-Warning -Message ($message -join [Environment]::NewLine)
}

# Backup the user's configuration before we begin, and ensure we're at a pure state before running
# the tests.  We'll restore it at the end.
$configFile = New-TemporaryFile
Backup-GitHubConfiguration -Path $configFile
Reset-GitHubConfiguration

# Define Script-scoped, readonly, hidden variables.

@{
    defaultIssueTitle = "Test Title"
    defaultCommentBody = "Test Body"
}.GetEnumerator() | ForEach-Object {
    Set-Variable -Force -Scope Script -Option ReadOnly -Visibility Private -Name $_.Key -Value $_.Value
}

Describe 'Creating a new comment' {
    $repo = New-GitHubRepository -RepositoryName ([Guid]::NewGuid().Guid) -AutoInit

    $issue = New-GitHubIssue -Uri $repo.svn_url -Title $defaultIssueTitle

    Context 'For creating a new comment' {
        $newComment = New-GitHubComment -Uri $repo.svn_url -IssueNumber $issue.id -Body $defaultCommentBody
        $existingComment = Get-GitHubComment -Uri $repo.svn_url -CommentID $newComment.id

        It "Should have the expected body text" {
            $existingComment.body | Should be $defaultCommentBody
        }
    }

    Context 'For getting comments from an issue'
    {
        $existingComments = @(Get-GitHubIssueComment -Uri $repo.svn_url -IssueNumber $issue.id)

        It 'Should have the expected number of comments' {
            $existingComments.Count | Should be 1
        }

        It 'Should have the expected body text on the first comment' {
            $existingComments[0].body | Should be $defaultCommentBody
        }
    }

    Context 'For getting comments from a repository'
    {
        $existingComments = @(Get-GitHubRepositoryComment -Uri $repo.svn_url)

        It 'Should have the expected number of comments' {
            $existingComments.Count | Should be 1
        }

        It 'Should have the expected body text on the first comment' {
            $existingComments[0].body | Should be $defaultCommentBody
        }
    }

    Remove-GitHubRepository -Uri $repo.svn_url
}

# Restore the user's configuration to its pre-test state
Restore-GitHubConfiguration -Path $configFile
