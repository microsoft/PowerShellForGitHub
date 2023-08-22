# PowerShellForGitHub PowerShell Module
## Usage

#### Table of Contents
*   [Full Module Documentation](#full-module-documentation)
*   [Logging](#logging)
*   [Telemetry](#telemetry)
*   [Common PowerShell API Patterns](#common-powershell-api-patterns)
    *   [Confirmation Required for Major Actions](#confirmation-required-for-major-actions)
    *   [WhatIf Supported for All State Changing Commands](#whatif-supported-for-all-state-changing-commands)
    *   [State Changing Commands are Silent by Default](#state-changing-commands-are-silent-by-default)
*   [Examples](#examples)
    *   [Overview](#overview)
        *   [Embracing the pipeline](#embracing-the-pipeline)
        *   [Pipeline Example](#pipeline-example)
    *   [Analytics](#analytics)
        *   [Querying Issues](#querying-issues)
        *   [Querying Pull Requests](#querying-pull-requests)
        *   [Querying Collaborators](#querying-collaborators)
        *   [Querying Contributors](#querying-contributors)
        *   [Querying Team and Organization Membership](#querying-team-and-organization-membership)
    *   [Labels](#labels)
        *   [Getting Labels for a Repository](#getting-labels-for-a-repository)
        *   [Getting Labels for an issue](#getting-labels-for-an-issue)
        *   [Getting Labels for a milestone](#getting-labels-for-a-milestone)
        *   [Adding a New Label to a Repository](#adding-a-new-label-to-a-repository)
        *   [Removing a Label From a Repository](#removing-a-label-from-a-repository)
        *   [Adding Labels to an Issue](#adding-labels-to-an-issue)
        *   [Removing a Label From an Issue](#removing-a-label-from-an-issue)
        *   [Updating a Label With a New Name and Color](#updating-a-label-with-a-new-name-and-color)
        *   [Bulk Updating Labels in a Repository](#bulk-updating-labels-in-a-repository)
    *   [Users](#users)
        *   [Getting the current authenticated user](#getting-the-current-authenticated-user)
        *   [Updating the current authenticated user](#updating-the-current-authenticated-user)
        *   [Getting any user](#getting-any-user)
        *   [Getting all users](#getting-all-users)
    *   [Teams](#teams)
        *   [Getting teams in an Organization](#Getting-teams-in-an-Organization)
        *   [Getting teams assigned to a repository](#Getting-teams-assigned-to-a-repository)
        *   [Getting a team by team name](#Getting-a-team-by-team-name)
        *   [Getting a team by team id](#Getting-a-team-by-team-id)
        *   [Creating a team](#Creating-a-team)
        *   [Creating a child team](#Creating-a-child-team)
        *   [Updating a team](#Updating-a-team)
        *   [Removing a team](#Removing-a-team)
    *   [Repositories](#repositories])
        *   [Create a repository](#Create-a-repository)
        *   [Create a repository in an organization](#Create-a-repository-in-an-organization)
        *   [Create a repository in an organization and grant access to a team](#Create-a-repository-in-an-organization-and-grant-access-to-a-team)
        *   [Create a repository from a template repository](#Create-a-repository-from-a-template-repository)
        *   [Get repository vulnerability alert status](#get-repository-vulnerability-alert-status)
        *   [Enable repository vulnerability alerts](#enable-repository-vulnerability-alerts)
        *   [Disable repository vulnerability alerts](#disable-repository-vulnerability-alerts)
        *   [Enable repository automatic security fixes](#enable-repository-automatic-security-fixes)
        *   [Disable repository automatic security fixes](#disable-repository-automatic-security-fixes)
        *   [Get repository GitHub Actions permissions](#get-repository-github-actions-permissions)
        *   [Set repository GitHub Actions permissions](#set-repository-github-actions-permissions)
        *   [Get a repository team permission](#get-a-repository-team-permission)
        *   [Set a repository team permission](#set-a-repository-team-permission)
        *   [Remove a repository team permission](#remove-a-repository-team-permission)
    *   [Branches](#branches)
        *   [Adding a new Branch to a Repository](#adding-a-new-branch-to-a-repository)
        *   [Removing a Branch from a Repository](#removing-a-branch-from-a-repository)
        *   [Getting a repository branch protection rule](#getting-a-repository-branch-protection-rule)
        *   [Creating a repository branch protection rule](#creating-a-repository-branch-protection-rule)
        *   [Removing a repository branch protection rule](#removing-a-repository-branch-protection-rule)
        *   [Getting a repository branch pattern protection rule](#getting-a-repository-branch-pattern-protection-rule)
        *   [Creating a repository branch pattern protection rule](#creating-a-repository-branch-pattern-protection-rule)
        *   [Removing a repository branch pattern protection rule](#removing-a-repository-branch-pattern-protection-rule)
    *   [Forks](#forks)
        *   [Get all the forks for a repository](#get-all-the-forks-for-a-repository)
        *   [Create a new fork](#create-a-new-fork)
    *   [Content](#content)
        *   [Get html output for a file](#get-html-output-for-a-file)
        *   [Get raw output for a file](#get-raw-output-for-a-file)
        *   [Get a list of files](#get-a-list-of-files)
        *   [Write a file to a branch of a repository](#write-a-file-to-a-branch-of-a-repository)
    *   [Traffic](#traffic)
        *   [Get the referrer traffic for a repository](#get-the-referrer-traffic-for-a-repository)
        *   [Get the popular content for a repository](#get-the-popular-content-for-a-repository)
        *   [Get the number of views for a repository](#get-the-number-of-views-for-a-repository)
        *   [Get the number of clones for a repository](#get-the-number-of-clones-for-a-repository)
    *   [Assignees](#assignees)
        *   [Get assignees](#get-assignees)
        *   [Check assignee permission](#check-assignee-permission)
        *   [Add assignee to an issue](#add-assignee-to-an-issue)
        *   [Remove assignee from an issue](#remove-assignee-from-an-issue)
    *   [Comments](#comments)
        *   [Get comments from an Issue](#get-comments-from-an-issue)
        *   [Get Issue comments from a repository](#get-issue-comments-from-a-repository)
        *   [Get a single Issue comment](#get-a-single-issue-comment)
        *   [Adding a new comment to an Issue](#adding-a-new-comment-to-an-issue)
        *   [Editing an existing Issue comment](#editing-an-existing-issue-comment)
        *   [Removing an Issue comment](#removing-an-issue-comment)
    *   [Milestones](#milestones)
        *   [Get milestones from a repository](#get-milestones-from-a-repository)
        *   [Get a single milestone](#get-a-single-milestone)
        *   [Adding a new milestone](#adding-a-new-milestone)
        *   [Editing an existing milestone](#editing-an-existing-milestone)
        *   [Removing a milestone](#removing-a-milestone)
    *   [Events](#Events)
        *   [Get events from a repository](#get-events-from-a-repository)
        *   [Get events from an issue](#get-events-from-an-issue)
        *   [Get a single event](#get-a-single-event])
    *   [Projects](#Projects)
        *   [Get projects for a repository](#get-projects-for-a-repository)
        *   [Get projects for a user](#get-projects-for-a-user)
        *   [Create a project](#create-a-project)
        *   [Add a column to a project](#add-a-column-to-a-project)
        *   [Add a card to a column](#add-a-card-to-a-column)
        *   [Add an existing issue as a card to a column](#add-an-existing-issue-as-a-card-to-a-column)
        *   [Move a card to be after a certain card in the same column](Move-a-card-to-be-after-a-certain-card-in-the-same-column)
        *   [Move a card to the bottom of another column](Move-a-card-to-the-bottom-of-another-column)
    *   [Releases](#Releases)
        *   [Get releases for a repository](#get-releases-for-a-repository)
        *   [Get an individual release for a repository](#get-an-individual-release-for-a-repository)
        *   [Create a new release](#create-a-new-release)
        *   [Update a release](#update-a-release)
        *   [Remove a release](#remove-a-release)
        *   [List assets for a release](#list-assets-for-a-release)
        *   [Download a release asset](#download-a-release-asset)
        *   [Create a release asset](#create-a-release-asset)
        *   [Update a release asset](#update-a-release-asset)
        *   [Remove a release asset](#remove-a-release-asset)
    *   [Gists](#gists)
        *   [Getting gists](#getting-gists)
        *   [Download a gist](#download-a-gist)
        *   [Fork a gist](#fork-a-gist)
        *   [Creating a gist](#creating-a-gist)
        *   [Removing a gist](#removing-a-gist)
        *   [Updating a gist](#updating-a-gist)
        *   [Starring a gist](#starring-a-gist)
        *   [Getting gist comments](#getting-gist-comments)
        *   [Adding a gist comment](#adding-a-gist-comment)
        *   [Changing a gist comment](#changing-a-gist-comment)
        *   [Removing a gist comment](#removing-a-gist-comment)
    *   [Deployments Environments](#deployment-environments)
        * [Adding a new environment](#adding-a-new-environment)
        * [Getting details of an environment](#getting-details-of-an-environment)
        * [Updating an environment](#updating-an-environment)
        * [Removing an environment](#removing-an-environment)
    *   [Advanced](#advanced)
        *   [Migrating blog comments to GitHub issues](#migrating-blog-comments-to-github-issues)
        aces
    *   [Codespaces](#codespaces)
        *   [Getting codespaces](#getting-codespaces)
        *   [Creating a codespace](#creating-a-codespace)
        *   [Removing a codespace](#removing-a-codespace)
        *   [Starting a codespace](#starting-a-codespace)
        *   [Stopping a codespace](#stopping-a-codespace)
    *   [Codespaces](#codespaces-organizations)
        *   [Getting codespaces](#getting-organization-codespaces)
        *   [Removing a codespace](#removing-an-organization-codespace)
        *   [Stopping a codespace](#stopping-an-organization-codespace)

----------

## Full Module Documentation

All commands for the module have "Comment-Based Help" available at your fingertips.
You can access that help at any time by running:

```powershell
Get-Help -Full <commandName>
```

In addition to accessing it from the commandline, all of that help documentation is also available
online on our [wiki](https://github.com/microsoft/PowerShellForGitHub/wiki).

----------

## Logging

All commands will log to the console, as well as to a log file, by default.
The logging is affected by configuration properties (which can be checked with
`Get-GitHubConfiguration` and changed with `Set-GitHubConfiguration`).

 **`LogPath`** [string] The logfile. Defaults to
   `([System.Environment]::GetFolderPath('MyDocuments'))\PowerShellForGitHub.log`.  Will default to
   `([System.Environment]::GetFolderPath('LocalApplicationData'))\PowerShellForGitHub.log` when
   there is no user profile (like in an Azure environment).

 **`DisableLogging`** [bool] Defaults to `$false`.

 **`LogTimeAsUtc`** [bool] Defaults to `$false`. If `$false`, times are logged in local time.
    When `$true`, times are logged using UTC (and those timestamps will end with a Z per the
    [W3C standard](http://www.w3.org/TR/NOTE-datetime))

 **`LogProcessId`** [bool] Defaults to `$false`. If `$true`, the
    Process ID (`$global:PID`) of the current PowerShell process will be added
    to every log entry.  This can be helpful if you have situations where
    multiple instances of this module run concurrently and you want to
    more easily isolate the log entries for one process.  An alternative
    solution would be to use `Set-GitHubConfiguration -LogPath <path> -SessionOnly` to specify a
    different log file for each PowerShell process. An easy way to view the filtered
    entries for a session is (replacing `PID` with the PID that you are interested in):

```powershell
Get-Content -Path <logPath> -Encoding UTF8 | Where { $_ -like '*[[]PID[]]*' }
```

----------

## Telemetry

In order to track usage, gauge performance and identify areas for improvement, telemetry is
employed during execution of commands within this module (via Application Insights).  For more
information, refer to the [Privacy Policy](README.md#privacy-policy).

We recommend that you always leave the telemetry feature enabled, but a situation may arise where
it must be disabled for some reason.  In this scenario, you can disable telemetry by calling:

```powershell
Set-GitHubConfiguration -DisableTelemetry -SessionOnly
```

The effect of that value will last for the duration of your session (until you close your
console window).  To make that change permanent, remove `-SessionOnly` from that call.

The following type of information is collected:
 * Every major command executed (to gauge usefulness of the various commands)
 * Types of parameters used with the command
 * Error codes / information

The following information is also collected, but the reported information is only reported
in the form of an SHA512 Hash (to protect PII (personal identifiable information)):
 * Username
 * OwnerName
 * RepositoryName
 * OrganizationName

The hashing of the above items can be disabled (meaning that the plaint-text data will be reported
instead of the _hash_ of the data) by setting

```powershell
Set-GitHubConfiguration -DisablePiiProtection -SessionOnly
```

Similar to `DisableTelemetry`, the effect of this value will only last for the duration of
your session (until you close your console window), unless you call it without `-SessionOnly`.

The first time telemetry is tracked in a new PowerShell session, a reminder message will be displayed
to the user.  To suppress this reminder in the future, call:

```powershell
Set-GitHubConfiguration -SuppressTelemetryReminder
```

Finally, the Application Insights Key that the telemetry is reported to is exposed as

```powershell
Get-GitHubConfiguration -Name ApplicationInsightsKey
```
It is requested that you do not change this value, otherwise the telemetry will not be reported to
us for analysis.  We expose it here for complete transparency.

----------

## Common PowerShell API Patterns

This module adopts many of the standard PowerShell API design patterns.  We want to call attention
to those patterns here so that you can identify how you can most efficiently use the module.

### Confirmation Required for Major Actions

All commands that result in removing/deleting an object, as well as some commands that rename
objects (like renaming a repository) require user confirmation before the comamnd will be processed.
You can avoid that user confirmation by passing in either `-Confirm:$false` or `-Force`.

### WhatIf Supported for All State Changing Commands

Any command that _isn't_ `Get-GitHub*` supports the `-WhatIf` switch.  You can safely call that
command by passing in the `-WhatIf` switch and know that the request will not actually be sent
to GitHub.  This can be useful when paired with the `-Verbose` switch if you are examining what
is happening behind the scenes.

### State Changing Commands are Silent by Default

By default, state changing commands like `Set-*`, `Rename-*`, etc... will not produce any output
unless you specify the `-PassThru` switch.  You can change that default behavior by calling

```powershell
Set-GitHubConfiguration -DefaultPassThru:$true
```

----------

## Examples

### Overview

#### Embracing the Pipeline

One of the major benefits of PowerShell is its pipeline -- allowing you to "pipe" a saved value or
the output of a previous command directly into the next command.  There is absolutely no requirement
to make use of it in order to use the module, but you will find that the module becomes increasingly
easier to use and more powerful if you do.

Some of the examples that you find below will show how you might be able to use it to your advantage.

#### Pipeline Example

Most commands require you to pass in either a `Uri` for the repository or its elements (the
`OwnerName` and `RepositoryName`).  If you keep around the repo that you're interacting with in
a local var (like `$repo`), then you can pipe that into any command to avoid having to specify that
information.  Further, piping in a more specific object (like an `Issue`) allows you to avoid even
specifying the relevant Issue number.

Without the pipeline, an interaction log might look like this:

```powershell
# Find all of the issues that have the label "repro steps needed" and add a new comment to those
# issues asking for an update.
$issues = @(Get-GitHubIssue -OwnerName microsoft -RepositoryName PowerShellForGitHub -Label 'repro steps needed')
foreach ($issue in $issues)
{
    $params = @{
        'OwnerName' = 'microsoft'
        'RepositoryName' = 'PowerShellForGitHub'
        'Issue' = $issue.number
        'Body' = 'Any update on those repro steps?'
    }

    New-GitHubIssueComment @params
}

```

With the pipeline, a similar interaction log might look like this:

```powershell
# Find all of the issues that have the label "repro steps needed" and add a new comment to those
# issues asking for an update.
Get-GitHubRepository -OwnerName microsoft -RepositoryName PowerShellForGitHub |
    Get-GitHubIssue -Label 'repro steps needed' |
    New-GitHubIssueComment -Body 'Any update on those repro steps?'
```

We encourage you to explore how embracing the pipeline may simplify your code and interaction
with GitHub using this module!

### Analytics

#### Querying Issues

```powershell
# Getting all of the issues from the PowerShell\xPSDesiredStateConfiguration repository
$issues = Get-GitHubIssue -OwnerName PowerShell -RepositoryName 'xPSDesiredStateConfiguration'
```

```powershell
# An example of accomplishing what Get-GitHubIssueForRepository (from v0.1.0) used to do.
# Get all of the issues from multiple repos, but only return back the ones that were created within
# past two weeks.
$repos = @('https://github.com/powershell/xpsdesiredstateconfiguration', 'https://github.com/powershell/xactivedirectory')
$issues = @()
$repos | ForEach-Object { $issues += Get-GitHubIssue -Uri $_ }
$issues | Where-Object { $_.created_at -gt (Get-Date).AddDays(-14) }
```

```powershell
# An example of accomplishing what Get-GitHubWeeklyIssueForRepository (from v0.1.0) used to do.
# Get all of the issues from multiple repos, and group them by the week in which they were created.
$repos = @('https://github.com/powershell/xpsdesiredstateconfiguration', 'https://github.com/powershell/xactivedirectory')
$issues = @()
$repos | ForEach-Object { $issues += Get-GitHubIssue -Uri $_ }
$issues | Group-GitHubIssue -Weeks 12 -DateType Created
```

```powershell
# An example of accomplishing what Get-GitHubTopIssueRepository (from v0.1.0) used to do.
# Get all of the issues from multiple repos, and sort the repos by the number issues that they have.
$repos = @('https://github.com/powershell/xpsdesiredstateconfiguration', 'https://github.com/powershell/xactivedirectory')
$issueCounts = @()
$issueSearchParams = @{
    'State' = 'open'
}
$repos | ForEach-Object { $issueCounts += ([PSCustomObject]@{ 'Uri' = $_; 'Count' = (Get-GitHubIssue -Uri $_ @issueSearchParams).Count }) }
$issueCounts | Sort-Object -Property Count -Descending
```

#### Querying Pull Requests

```powershell
# Getting all of the pull requests from the microsoft\PowerShellForGitHub repository
$issues = Get-GitHubIssue -OwnerName microsoft -RepositoryName 'PowerShellForGitHub'
```

```powershell
# An example of accomplishing what Get-GitHubPullRequestForRepository (from v0.1.0) used to do.
# Get all of the pull requests from multiple repos, but only return back the ones that were created
# within the past two weeks.
$repos = @('https://github.com/powershell/xpsdesiredstateconfiguration', 'https://github.com/powershell/xactivedirectory')
$pullRequests = @()
$repos | ForEach-Object { $pullRequests += Get-GitHubPullRequest -Uri $_ }
$pullRequests | Where-Object { $_.created_at -gt (Get-Date).AddDays(-14) }
```

```powershell
# An example of accomplishing what Get-GitHubWeeklyPullRequestForRepository (from v0.1.0) used to do.
# Get all of the pull requests from multiple repos, and group them by the week in which they were merged.
$repos = @('https://github.com/powershell/xpsdesiredstateconfiguration', 'https://github.com/powershell/xactivedirectory')
$pullRequests = @()
$repos | ForEach-Object { $pullRequests += Get-GitHubPullRequest -Uri $_ }
$pullRequests | Group-GitHubPullRequest -Weeks 12 -DateType Merged
```

```powershell
# An example of accomplishing what Get-GitHubTopPullRequestRepository (from v0.1.0) used to do.
# Get all of the pull requests from multiple repos, and sort the repos by the number
# of closed pull requests that they have had within the past two weeks.
$repos = @('https://github.com/powershell/xpsdesiredstateconfiguration', 'https://github.com/powershell/xactivedirectory')
$pullRequestCounts = @()
$pullRequestSearchParams = @{
    'State' = 'closed'
}
$repos |
    ForEach-Object {
        $pullRequestCounts += ([PSCustomObject]@{
            'Uri' = $_;
            'Count' = (
                (Get-GitHubPullRequest -Uri $_ @pullRequestSearchParams) |
                    Where-Object { $_.completed_at -gt (Get-Date).AddDays(-14) }
            ).Count
        }) }

$pullRequestCounts | Sort-Object -Property Count -Descending
```

#### Querying Collaborators

```powershell
$collaborators = Get-GitHubRepositoryCollaborators`
    -Uri @('https://github.com/PowerShell/DscResources')
```

#### Querying Contributors

```powershell
# Getting all of the contributors for a single repository
$contributors = Get-GitHubRepositoryContributor -OwnerName 'PowerShell' -RepositoryName 'PowerShellForGitHub' }
```

```powershell
# An example of accomplishing what Get-GitHubRepositoryContributors (from v0.1.0) used to do.
# Getting all of the contributors for a set of repositories
$repos = @('https://github.com/PowerShell/DscResources', 'https://github.com/PowerShell/xWebAdministration')
$contributors = @()
$repos | ForEach-Object { $contributors += Get-GitHubRepositoryContributor -Uri $_ }
```

```powershell
# An example of accomplishing what Get-GitHubRepositoryUniqueContributor (from v0.1.0) used to do.
# Getting the unique set of contributors from the previous results of Get-GitHubRepositoryContributor
Get-GitHubRepositoryContributor -OwnerName 'PowerShell' -RepositoryName 'PowerShellForGitHub' } |
    Select-Object -ExpandProperty author |
    Select-Object -ExpandProperty login -Unique
    Sort-Object
```

#### Querying Team and Organization Membership

```powershell
$organizationMembers = Get-GitHubOrganizationMember -OrganizationName 'OrganizationName'
$teamMembers = Get-GitHubTeamMember -OrganizationName 'OrganizationName' -TeamName 'TeamName'
```

----------

### Labels

#### Getting Labels for a Repository
```powershell
$labels = Get-GitHubLabel -OwnerName PowerShell -RepositoryName DesiredStateConfiguration
```

#### Getting Labels for an Issue
```powershell
$labels = Get-GitHubLabel -OwnerName PowerShell -RepositoryName DesiredStateConfiguration -Issue 1
```

#### Getting Labels for a Milestone
```powershell
$labels = Get-GitHubLabel -OwnerName PowerShell -RepositoryName DesiredStateConfiguration -Milestone 1
```

#### Adding a New Label to a Repository
```powershell
New-GitHubLabel -OwnerName PowerShell -RepositoryName DesiredStateConfiguration -Name TestLabel -Color BBBBBB
```

#### Removing a Label From a Repository
```powershell
Remove-GitHubLabel -OwnerName PowerShell -RepositoryName DesiredStateConfiguration -Name TestLabel
```

#### Adding Labels to an Issue
```powershell
$labelNames = @('bug', 'discussion')
Add-GitHubIssueLabel -OwnerName $script:ownerName -RepositoryName $repositoryName -Issue 1 -LabelName $labelNames
```

#### Removing a Label From an Issue
```powershell
Remove-GitHubIssueLabel -OwnerName microsoft -RepositoryName DesiredStateConfiguration -Name TestLabel -Issue 1
```

#### Updating a Label With a New Name and Color
```powershell
Set-GitHubLabel -OwnerName microsoft -RepositoryName DesiredStateConfiguration -Name TestLabel -NewName NewTestLabel -Color BBBB00
```

#### Bulk Updating Labels in a Repository
This replaces the entire set of labels in a repository to only contain the labels in the provided array.
Any labels already in the repository that are not in this array will be removed upon execution.

```powershell
$labels = @( @{ 'name' = 'Label1'; 'color' = 'BBBB00'; 'description' = 'My label description' }, @{ 'name' = 'Label2'; 'color' = 'FF00000' })
Initialize-GitHubLabel -OwnerName PowerShell -RepositoryName DesiredStateConfiguration -Label $labels
```

----------

### Users

#### Getting the current authenticated user
```powershell
Get-GitHubUser -Current
```

#### Updating the current authenticated user's profile
```powershell
Set-GitHubProfile -Location 'Seattle, WA' -Hireable:$false
```

#### Getting any user
```powershell
Get-GitHubUser -UserName octocat
```

#### Getting all users
```powershell
Get-GitHubUser
```
> Warning: This will take a while.  It's getting _every_ GitHub user.

----------
### Repositories

#### Adding a new Branch to a Repository

```powershell
New-GitHubRepositoryBranch -OwnerName microsoft -RepositoryName PowerShellForGitHub -Name develop
```

#### Removing a Branch from a Repository

```powershell
Remove-GitHubRepositoryBranch -OwnerName microsoft -RepositoryName PowerShellForGitHub -Name develop
```

----------

### Teams

#### Getting teams in an Organization

```powershell
Get-GitHubTeam -OrganizationName microsoft
```

#### Getting teams assigned to a repository

```powershell
Get-GitHubTeam -OwnerName microsoft -RepositoryName PowerShellForGitHub
```

#### Getting a team by team name

```powershell
Get-GitHubTeam -OrganizationName microsoft -TeamName MyTeam
```

#### Getting a team by team id

```powershell
Get-GitHubTeam -OrganizationName microsoft -TeamId 378661
```

#### Creating a team

```powershell
New-GitHubTeam -OrganizationName microsoft -TeamName MyTeam -Description 'Team Description'
```

#### Creating a child team

```powershell
New-GitHubTeam -OrganizationName microsoft -TeamName MyChildTeam -Description 'Team Description' -ParentTeamName MyTeam
```

#### Updating a team

```powershell
Update-GitHubTeam -OrganizationName microsoft -TeamName MyChildTeam -Description 'Team Description' -ParentTeamName MyTeam
```

#### Removing a team

```powershell
Remove-GitHubTeam -OrganizationName microsoft -TeamName MyTeam
```

----------

### Repositories

#### Create a repository

```powershell
New-GitHubRepository -RepositoryName TestRepo
```

#### Create a repository in an organization

```powershell
New-GitHubRepository -RepositoryName TestRepo -OrganizationName MyOrg
```

#### Create a repository in an organization and grant access to a team

```powershell
$myTeam = Get-GitHubTeam -OrganizationName MyOrg | Where-Object -Property name -eq MyTeam
New-GitHubRepository -RepositoryName TestRepo -OrganizationName MyOrg -TeamId $myTeam.id
```

#### Create a repository from a template repository

```powershell
New-GitHubRepositoryFromTemplate -OwnerName MyOrg -RepositoryName TemplateRepoName -TargetRepositoryName MyNewRepo -TargetOwnerName MyUserName
```

#### Get repository vulnerability alert status

```powershell
Test-GitHubRepositoryVulnerabilityAlert -OwnerName microsoft -RepositoryName PowerShellForGitHub
```

#### Enable repository vulnerability alerts

```powershell
Enable-GitHubRepositoryVulnerabilityAlert -OwnerName microsoft -RepositoryName PowerShellForGitHub
```

#### Disable repository vulnerability alert

```powershell
Disable-GitHubRepositoryVulnerabilityAlert -OwnerName microsoft -RepositoryName PowerShellForGitHub
```

#### Enable repository automatic security fixes

```powershell
Enable-GitHubRepositorySecurityFix -OwnerName microsoft -RepositoryName PowerShellForGitHub
```

#### Disable repository automatic security fixes

```powershell
Disable-GitHubRepositorySecurityFix -OwnerName microsoft -RepositoryName PowerShellForGitHub
```

#### Get repository GitHub Actions permissions

```powershell
Get-GitHubRepositoryActionsPermission -OwnerName microsoft -RepositoryName PowerShellForGitHub
```

#### Set repository GitHub Actions permissions

```powershell
Set-GitHubRepositoryActionsPermission -OwnerName microsoft -RepositoryName PowerShellForGitHub -AllowedActions All
```

#### Get a repository team permission

```powershell
Get-GitHubRepositoryTeamPermission -OwnerName microsoft -RepositoryName PowerShellForGitHub -TeamName Admins
```

#### Set a repository team permission

```powershell
Set-GitHubRepositoryTeamPermission -OwnerName microsoft -RepositoryName PowerShellForGitHub -TeamName Admins -Permission Admin
```

#### Remove a repository team permission

```powershell
Remove-GitHubRepositoryTeamPermission -OwnerName microsoft -RepositoryName PowerShellForGitHub -TeamName Admins
```

----------

### Branches

#### Getting a repository branch protection rule

```powershell
Get-GitHubRepositoryBranchProtectionRule -OwnerName microsoft -RepositoryName PowerShellForGitHub -BranchName master
```

#### Creating a repository branch protection rule

```powershell
New-GitHubRepositoryBranchProtectionRule -OwnerName microsoft -RepositoryName PowerShellForGitHub -BranchName master -RequiredApprovingReviewCount 1
```

#### Removing a repository branch protection rule

```powershell
Remove-GitHubRepositoryBranchProtectionRule -OwnerName microsoft -RepositoryName PowerShellForGitHub -BranchName master
```

#### Getting a repository branch pattern protection rule

```powershell
Get-GitHubRepositoryBranchPatternProtectionRule -OwnerName microsoft -RepositoryName PowerShellForGitHub -BranchPatternName 'Release/**/*'
```

#### Creating a repository branch pattern protection rule

```powershell
New-GitHubRepositoryBranchPatternProtectionRule -OwnerName microsoft -RepositoryName PowerShellForGitHub -BranchPatternName 'Release/**/*' -RequiredApprovingReviewCount 1 -DismissStaleReviews -RequireStrictStatusChecks -StatusCheck 'CICheck'
```

#### Removing a repository branch pattern protection rule

```powershell
Remove-GitHubRepositoryBranchPatternProtectionRule -OwnerName microsoft -RepositoryName PowerShellForGitHub -BranchPatternName 'Release/**/*'
```

----------

### Forks

#### Get all the forks for a repository
```powershell
Get-GitHubRepositoryFork -OwnerName microsoft -RepositoryName PowerShellForGitHub
```

#### Create a new fork
```powershell
New-GitHubRepositoryFork -OwnerName microsoft -RepositoryName PowerShellForGitHub
```

----------

### Content

#### Get html output for a file

```powershell
Get-GitHubContent -OwnerName microsoft -RepositoryName PowerShellForGitHub -Path README.md -MediaType Html
```

#### Get raw output for a file

```powershell
Get-GitHubContent -OwnerName microsoft -RepositoryName PowerShellForGitHub -Path LICENSE
```

#### Get a list of files

```powershell
Get-GitHubContent -OwnerName microsoft -RepositoryName PowerShellForGitHub -Path Tests
```

#### Write a file to a branch of a repository

```powershell
Set-GitHubContent -OwnerName microsoft -RepositoryName PowerShellForGitHub -Path README.md -CommitMessage 'Adding README.md' -Content '# README' -BranchName master
```

----------

### Traffic

#### Get the referrer traffic for a repository
```powershell
Get-GitHubReferrerTraffic -OwnerName microsoft -RepositoryName PowerShellForGitHub
```

#### Get the popular content for a repository
```powershell
Get-GitHubPathTraffic -OwnerName microsoft -RepositoryName PowerShellForGitHub
```

#### Get the number of views for a repository
```powershell
Get-GitHubViewTraffic -OwnerName microsoft -RepositoryName PowerShellForGitHub -Per Week
```

#### Get the number of clones for a repository
```powershell
Get-GitHubCloneTraffic -OwnerName microsoft -RepositoryName PowerShellForGitHub -Per Day
```

----------

### Assignees

#### Get assignees
```powershell
Get-GitHubAssignee -OwnerName microsoft -RepositoryName PowerShellForGitHub
```

#### Check assignee permission
```powershell
$HasPermission = Test-GitHubAssignee -OwnerName microsoft -RepositoryName PowerShellForGitHub -Assignee "LoginID123"
```

#### Add assignee to an issue
```powershell
Add-GitHubAssignee -OwnerName microsoft -RepositoryName PowerShellForGitHub -Assignees $assignees -Issue 1
```

#### Remove assignee from an issue
```powershell
Remove-GitHubAssignee -OwnerName microsoft -RepositoryName PowerShellForGitHub -Assignees $assignees -Issue 1
```

----------

### Comments

#### Get comments from an Issue
```powershell
Get-GitHubIssueComment -OwnerName microsoft -RepositoryName PowerShellForGitHub -Issue 1
```

#### Get Issue comments from a repository
```powershell
Get-GitHubRepositoryComment -OwnerName microsoft -RepositoryName PowerShellForGitHub -Sort Created -Direction Ascending -Since '2011-04-14T16:00:49Z'
```

#### Get a single Issue comment
```powershell
Get-GitHubIssueComment -OwnerName microsoft -RepositoryName PowerShellForGitHub -CommentID 1
```

#### Adding a new comment to an Issue
```powershell
New-GitHubIssueComment -OwnerName microsoft -RepositoryName PowerShellForGitHub -Issue 1 -Body "Testing this API"
```

#### Editing an existing Issue comment
```powershell
Set-GitHubIssueComment -OwnerName microsoft -RepositoryName PowerShellForGitHub -CommentID 1 -Body "Testing this API"
```

#### Removing an Issue comment
```powershell
Remove-GitHubIssueComment -OwnerName microsoft -RepositoryName PowerShellForGitHub -CommentID 1
```

----------

### Milestones

#### Get milestones from a repository
```powershell
Get-GitHubMilestone -OwnerName microsoft -RepositoryName PowerShellForGitHub -Sort DueOn -Direction Ascending -DueOn '2011-04-14T16:00:49Z'
```

#### Get a single milestone
```powershell
Get-GitHubMilestone -OwnerName microsoft -RepositoryName PowerShellForGitHub -Milestone 1
```

#### Assign an existing issue to a new milestone
```powershell
New-GitHubMilestone -OwnerName microsoft -RepositoryName PowerShellForGitHub -Title "Testing this API"
Set-GitHubIssue -OwnerName microsoft -RepositoryName PowerShellForGitHub -Issue 2 -Milestone 1
```

#### Editing an existing milestone
```powershell
Set-GitHubMilestone -OwnerName microsoft -RepositoryName PowerShellForGitHub -Milestone 1 -Title "Testing this API edited"
```

#### Removing a milestone
```powershell
Remove-GitHubMilestone -OwnerName microsoft -RepositoryName PowerShellForGitHub -Milestone 1
```

----------

### Events

#### Get events from a repository
```powershell
Get-GitHubEvent -OwnerName microsoft -RepositoryName PowerShellForGitHub
```

#### Get events from an issue
```powershell
Get-GitHubEvent -OwnerName microsoft -RepositoryName PowerShellForGitHub -Issue 1
```

#### Get a single event
```powershell
Get-GitHubEvent -OwnerName microsoft -RepositoryName PowerShellForGitHub -EventID 1
```

----------

### Projects

#### Get projects for a repository
```powershell
Get-GitHubProject -OwnerName microsoft -RepositoryName PowerShellForGitHub
```

#### Get projects for a user
```powershell
Get-GitHubProject -UserName octocat
```

#### Create a project
```powershell
New-GitHubProject -OwnerName octocat -RepositoryName PowerShellForGitHub -ProjectName TestProject
```

#### Add a column to a project
```powershell
New-GitHubProjectColumn -Project 1 -ColumnName 'To Do'
```

#### Add a card to a column
```powershell
New-GitHubProjectCard -Column 2 -Note 'Fix this bug'
```

#### Add an existing issue as a card to a column
```powershell
New-GitHubProjectCard -Column 2 -ContentId 3 -ContentType Issue
```

#### Move a card to be after a certain card in the same column
```powershell
Move-GitHubProjectCard -Card 4 -After 5
```

#### Move a card to the bottom of another column
```powershell
Move-GitHubProjectCard -Card 4 -ColumnId 6 -Bottom
```

----------

### Releases

#### Get releases for a repository
```powershell
Get-GitHubRelease -OwnerName PowerShell -RepositoryName PowerShell
```

or with pipelining...

```powershell
Get-GitHubRepository -OwnerName PowerShell -RepositoryName PowerShell |
    Get-GitHubRelease
```

#### Get an individual release for a repository
```powershell
Get-GitHubRelease -OwnerName PowerShell -RepositoryName PowerShell |
    Select-Object -First 1 |
    Get-GitHubRelease
```

#### Create a new release
```powershell
New-GitHubRelease -OwnerName PowerShell -RepositoryName PowerShell -Tag 11.0
```

or with pipelining...

```powershell
Get-GitHubRepository -OwnerName PowerShell -RepositoryName PowerShell |
    New-GitHubRelease -Tag 11.0
```

#### Update a release
```powershell
Set-GitHubRelease -OwnerName PowerShell -RepositoryName PowerShell -Release 123456 -Body 'Updated body'
```

or with pipelining...

```powershell
$repo | Set-GitHubRelease -Release 123456 -Body 'Updated body'

# or

$release | Set-GitHubRelease -Body 'Updated body'
```

#### Remove a release
```powershell
Remove-GitHubRelease -OwnerName PowerShell -RepositoryName PowerShell -Release 123456 -Force
```

or with pipelining...

```powershell
$repo | Remove-GitHubRelease -Release 123456 -Force

# or

$release | Remove-GitHubRelease -Force
```

#### List assets for a release
```powershell
Get-GitHubReleaseAsset -OwnerName PowerShell -RepositoryName PowerShell -Release 123456
```

or with pipelining...

```powershell
$repo | Get-GitHubReleaseAsset -Release 123456

# or

$release | Get-GitHubReleaseAsset
```

#### Download a release asset
```powershell
Get-GitHubReleaseAsset -OwnerName PowerShell -RepositoryName PowerShell -Asset 123456 -Path 'c:\downloads\asset'
```

or with pipelining...

```powershell
# Downloads the first asset of the latest release from PowerShell\PowerShell to the file located
# at c:\downloads\asset
Get-GitHubRelease -OwnerName PowerShell -RepositoryName PowerShell -Latest |
    Get-GitHubReleaseAsset |
    Select-Object -First 1 |
    Get-GitHubReleaseAsset -Path 'c:\downloads\asset'
```

#### Create a release asset
```powershell
New-GitHubReleaseAsset -OwnerName PowerShell -RepositoryName PowerShell -Release 123456 -Path 'c:\foo.zip'
```

or with pipelining...

```powershell
$release | New-GitHubReleaseAsset -Path 'c:\foo.zip'

# or

@('c:\foo.zip', 'c:\bar.txt') |
    New-GitHubReleaseAsset -OwnerName PowerShell -RepositoryName PowerShell -Release 123456
```

#### Update a release asset
```powershell
Set-GitHubReleaseAsset -OwnerName PowerShell -RepositoryName PowerShell -Asset 123456 -Name 'newFileName.zip'
```

or with pipelining...

```powershell
$asset | Set-GitHubReleaseAsset -Name 'newFileName.zip'
```

#### Remove a release asset
```powershell
Remove-GitHubReleaseAsset -OwnerName PowerShell -RepositoryName PowerShell -Asset 123456 -Force
```

or with pipelining...

```powershell
$asset | Remove-GitHubReleaseAsset -Force
```

----------

### Gists

#### Getting gists
```powershell
# There are many options here:

# 1. Getting all gists for the current authenticated user:
Get-GitHubGist

# 1b. Getting all gists for the current authenticated user that were updated in the past 6 days.
Get-GitHubGist -Since ((Get-Date).AddDays(-6))

# 2. Get all starred gists for the current authenticated user
Get-GitHubGist -Starred

# 3. Get all public gists for a specific user
Get-GitHubGist -UserName 'octocat'

# 4. Get all public gists (well, the first 3000):
Get-GitHubGist -Public

# 5. Get a specific gist
Get-GitHubGist -Gist '6cad326836d38bd3a7ae'

# 5a. List all commits for a specific gist
Get-GitHubGist -Gist '6cad326836d38bd3a7ae' -Commits

# 5b. Get a gist at a specific commit (Sha)
Get-GitHubGist -Gist '6cad326836d38bd3a7ae' -Sha 'de5b9b59d1f28206e8d646c7c8025e9809d0ed73'

# 5c. Get all of the forks for a gist
Get-GitHubGist -Gist '6cad326836d38bd3a7ae' -Forks
```

#### Download a gist
```powershell
Get-GitHubGist -Gist '6cad326836d38bd3a7ae' -Path 'c:\users\octocat\downloads\gist\'
```

#### Fork a gist
```powershell
Fork-GitHubGist -Gist '6cad326836d38bd3a7ae'
```

#### Creating a gist
```powershell
# You can create a gist by specifying a single file's content in-line...
New-GitHubGist -FileName 'foo.txt' -Content 'foo content'

# or by providing one or more files that should be part of the gist
New-GitHubGist -File @('c:\files\foo.txt', 'c:\files\bar.txt')
@('c:\files\foo.txt', 'c:\files\bar.txt') | New-GitHubGist
```

#### Removing a gist
```powershell
Remove-GitHubGist -Gist '6cad326836d38bd3a7ae'
```

#### Updating a gist
```powershell
$gist = New-GitHubGist -FileName 'foo.txt' -Content 'content'

# The main method to use is Set-GitHubGist, however it is quite complicated.
$params = @{
    Description = 'new description' # modifies the description of the gist
    Update = @{
        'foo.txt' = @{
            fileName = 'alpha.txt' # Will rename foo.txt -> alpha.txt
            content = 'updated content' # and will also update its content
        }
        'bar.txt' = @{
            filePath = 'c:\files\bar.txt' # Will upload the content of bar.txt to the gist.
        }
    }
    Delete = @('bar.txt')
    Force = $true # avoid confirmation prompting due to the deletion
}

Set-GitHubGist -Gist $gist.id @params

# Therefore, you can use simpler helper methods to accomplish atomic tasks
Set-GistHubGistFile -Gist $gist.id -FileName 'foo.txt' -Content 'updated content'

# This will update the text in the existing file 'foo.txt' and add the file 'bar.txt'
$gist | Set-GitHubGistFile -File ('c:\files\foo.txt', 'c:\files\bar.txt')

Rename-GistHubGistFile -Gist $gist.id -FileName 'foo.txt' -NewName 'bar.txt'

$gist | Remove-GitHubGistFile -FileName 'bar.txt' -Force

```

#### Starring a gist
```powershell
$gistId = '6cad326836d38bd3a7ae'

# All of these options will star the same gist
Star-GitHubGist -Gist $gistId
Add-GitHubGistStar -Gist $gistId
Set-GitHubGistStar -Gist $gistId -Star
Get-GitHubGist -Gist $gistId | Star-GitHubGist

# All of these options will unstar the same gist
Unstar-GitHubGist -Gist $gistId
Remove-GitHubGistStar -Gist $gistId
Set-GitHubGistStar -Gist $gistId
Set-GitHubGistStar -Gist $gistId -Star:$false
Get-GitHubGist -Gist $gistId | Unstar-GitHubGist

# All of these options will tell you if you have starred a gist
Test-GitHubGistStar -Gist $gistId
Get-GitHubGist -Gist $gistId | Test-GitHubGistStar
```

#### Getting gist comments
```powershell
$gistId = '6cad326836d38bd3a7ae'
$commentId = 1507813

# You can get all comments for a gist with any of these options:
Get-GitHubGistComment -Gist $gistId
Get-GitHubGist -Gist $gistId | Get-GitHubGistComment

# You can retrieve an individual comment like this:
Get-GitHubGistComment -Gist $gistId -Comment $commentId
```

#### Adding a gist comment
```powershell
$gistId = '6cad326836d38bd3a7ae'

New-GitHubGistComment -Gist $gistId -Body 'Hello World'

# or with the pipeline
Get-GitHubGist -Gist $gistId | New-GitHubGistComment -Body 'Hello World'
```

#### Changing a gist comment
```powershell
$gistId = '6cad326836d38bd3a7ae'
$commentId = 1507813

Set-GitHubGistComment -Gist $gistId -Comment $commentId -Body 'Updated comment'

# or with the pipeline
Get-GitHubGist -Gist $gistId -Comment $commentId | Set-GitHubGistComment -Body 'Updated comment'
```

#### Removing a gist comment
```powershell
$gistId = '6cad326836d38bd3a7ae'
$commentId = 1507813

# If you don't specify -Force, it will prompt for confirmation before it will delete the comment

Remove-GitHubGistComment -Gist $gistId -Comment $commentId -Force

# or with the pipeline
Get-GitHubGist -Gist $gistId -Comment $commentId | Remove-GitHubGistComment -Force
```

----------

### Deployment Environments

#### Adding a new environment
```powershell
New-GitHubDeploymentEnvironment -OwnerName microsoft -RepositoryName TestRepo -Environment Test
```

#### Getting details of an environment
```powershell
Get-GitHubDeploymentEnvironment -OwnerName microsoft -RepositoryName TestRepo -Environment Test
```

#### Updating an environment
```powershell
Set-GitHubDeploymentEnvironment -OwnerName microsoft -RepositoryName TestRepo -Environment Test -DeploymentBranchPolicy ProtectedBranches
```

#### Removing an environment
```powershell
Remove-GitHubDeploymentEnvironment -OwnerName microsoft -RepositoryName TestRepo -Environment Test
```

----------

### Advanced

#### Migrating blog comments to GitHub issues
@LazyWinAdmin used this module to migrate his blog comments from Disqus to GitHub Issues. [See blog post](https://lazywinadmin.com/2019/04/moving_blog_comments.html) for full details.

```powershell
# Get your repo
$repo = Get-GitHubRepository -OwnerName <yourName> -RepositoryName RepoName

# Create an issue
$issue = $repo | New-GitHubIssue -Title $IssueTitle -Body $body -Label 'blog comments'

# Create Comment
$issue | New-GitHubIssueComment -Body $CommentBody

# Close issue
$issue | Set-GitHubIssue -State Closed
```

----------

### Codespaces

#### Getting codespaces
```powershell
# Get all codespaces for the current authenticated user
Get-GitHubCodespace

# Get all codespaces for the current authenticated user in a repository
Get-GitHubCodespace -OwnerName microsoft -RepositoryName TestRepo

# Get a codespace by name
Get-GitHubCodespace -CodespaceName 'microsoft-symmetrical-chainsaw-7q4vp6v7q3pwqq'
```

#### Create a codespace
```powershell
# Create a codespace in the specified repository by id
New-GitHubCodespace -RepositoryId 582779513

# Create a codespace in the specified repository by name
New-GitHubCodespace -OwnerName microsoft -RepositoryName TestRepo

# Create a codespace in the specified repository by id from a pull request
New-GitHubCodespace -RepositoryId 582779513 -PullRequest 508

# Create a codespace in the specified repository by name from a pull request
New-GitHubCodespace -OwnerName microsoft -RepositoryName TestRepo -PullRequest 42

# Create a codespace in repository from pipeline
$repo = Get-GitHubRepository -OwnerName microsoft -RepositoryName TestRepo
$repo | New-GitHubCodespace

# Create a codespace in repository from pipeline with options
$newGitHubCodespaceParms = @{
    DisplayName = 'PowerShellForGitHub usage'
    Geo = 'UsWest'
    Machine = 'basicLinux32gb'
    NoMultipleRepoPermissions = $true
    IdleRetentionPeriodMinutes = 10
    TimeoutMinutes = 5
}
$codespace = $repo | New-GitHubCodespace @newGitHubCodespaceParms
```

#### Removing a codespace
```powershell
$codespaceName = 'microsoft-symmetrical-chainsaw-7q4vp6v7q3pwqq'

# Remove a codespace for the current authenticated user
Remove-GitHubCodespace -CodespaceName $codespaceName
```

#### Starting a codespace
```powershell
$codespaceName = 'microsoft-symmetrical-chainsaw-7q4vp6v7q3pwqq'

# Starting a codespace (asynchronous)
Start-GithubCodespace -CodespaceName $codespaceName

# Starting a codespace (wait for Available)
Start-GithubCodespace -CodespaceName $codespaceName -Wait
```

#### Stopping a codespace
```powershell
$codespaceName = 'microsoft-symmetrical-chainsaw-7q4vp6v7q3pwqq'

# Stopping a codespace (asynchronous)
Stop-GithubCodespace -CodespaceName $codespaceName

# Stopping a codespace (wait for Shutdown)
Stop-GithubCodespace -CodespaceName $codespaceName -Wait
```

----------

### Codespaces organizations

#### Getting organization Codespaces
```powershell

# Get all codespaces for an Organization
Get-GitHubCodespace -OrganizationName microsoft

# Get all codespaces for a specific organization user
Get-GitHubCodespace -OrganizationName microsoft -UserName octocat
```

#### Removing an organization Codespace
```powershell
$codespaceName = 'microsoft-symmetrical-chainsaw-7q4vp6v7q3pwqq'

# Remove a codespace for an organization user
Remove-GitHubCodespace -OrganizationName microsoft -UserName octocat -CodespaceName $codespaceName
```

#### Stopping an organization Codespace
```powershell
$codespaceName = 'microsoft-symmetrical-chainsaw-7q4vp6v7q3pwqq'

# Stopping a codespace (wait for Shutdown)
Stop-GithubCodespace -OrganizationName microsoft -UserName octocat -CodespaceName $codespaceName -Wait
```