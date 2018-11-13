# PowerShellForGitHub PowerShell Module
## Usage

#### Table of Contents
*   [Logging](#logging)
*   [Telemetry](#telemetry)
*   [Examples](#examples)
    *   [Analytics](#analytics)
        *   [Querying Issues](#querying-issues)
        *   [Querying Pull Requests](#querying-pull-requests)
        *   [Querying Collaborators](#querying-collaborators)
        *   [Querying Contributors](#querying-contributors)
        *   [Quering Team and Organization Membership](#querying-team-and-organization-membership)
    *   [Labels](#labels)
        *   [Getting Labels for a Repository](#getting-labels-for-a-repository)
        *   [Adding a New Label to a Repository](#adding-a-new-label-to-a-repository)
        *   [Removing a Label From a Repository](#removing-a-label-from-a-repository)
        *   [Updating a Label With a New Name and Color](#updating-a-label-with-a-new-name-and-color)
        *   [Bulk Updating Labels in a Repository](#bulk-updating-labels-in-a-repository)
    *   [Users](#users)
        *   [Getting the current authenticated user](#getting-the-current-authenticated-user)
        *   [Updating the current authenticated user](#updating-the-current-authenticated-user)
        *   [Getting any user](#getting-any-user)
        *   [Getting all users](#getting-all-users)

----------

## Logging

All commands will log to the console, as well as to a log file, by default.
The logging is affected by configuration properties (which can be checked with
`Get-GitHubConfiguration` and changed with `Set-GitHubConfiguration`).

 **`LogPath`** [string] The logfile. Defaults to
   `$env:USERPROFILE\Documents\PowerShellForGitHub.log`

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

    Get-Content -Path <logPath> -Encoding UTF8 | Where { $_ -like '*[[]PID[]]*' }

----------

## Telemetry

In order to track usage, gauge performance and identify areas for improvement, telemetry is
employed during execution of commands within this module (via Application Insights).  For more
information, refer to the [Privacy Policy](README.md#privacy-policy).

> You may notice some needed assemblies for communicating with Application Insights being
> downloaded on first run of a command within each PowerShell session.  The
> [automatic dependency downloads](#automatic-dependency-downloads) section of the setup
> documentation describes how you can avoid having to always re-download the telemetry assemblies
> in the future.

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

## Examples

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
$issues | Group-GitHubIssue -Weeks 12 -DateType 'created'
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
# Getting all of the pull requests from the PowerShell\PowerShellForGitHub repository
$issues = Get-GitHubIssue -OwnerName PowerShell -RepositoryName 'PowerShellForGitHub'
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
$pullRequests | Group-GitHubPullRequest -Weeks 12 -DateType 'merged'
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

#### Quering Team and Organization Membership

```powershell
$organizationMembers = Get-GitHubOrganizationMembers -OrganizationName 'OrganizationName'
$teamMembers = Get-GitHubTeamMembers -OrganizationName 'OrganizationName' -TeamName 'TeamName'
```

----------

### Labels

#### Getting Labels for a Repository
```powershell
$labels = Get-GitHubLabel -OwnerName Powershell -RepositoryName DesiredStateConfiguration
```

#### Adding a New Label to a Repository
```powershell
New-GitHubLabel -OwnerName Powershell -RepositoryName DesiredStateConfiguration -Name TestLabel -Color BBBBBB
```

#### Removing a Label From a Repository
```powershell
Remove-GitHubLabel -OwnerName Powershell -RepositoryName desiredstateconfiguration -Name TestLabel
```

#### Updating a Label With a New Name and Color
```powershell
Update-GitHubLabel -OwnerName Powershell -RepositoryName DesiredStateConfiguration -Name TestLabel -NewName NewTestLabel -Color BBBB00
```

#### Bulk Updating Labels in a Repository
```powershell
$labels = @( @{ 'name' = 'Label1'; 'color' = 'BBBB00'; 'description' = 'My label description' }, @{ 'name' = 'Label2'; 'color' = 'FF00000' })
Set-GitHubLabel -OwnerName Powershell -RepositoryName DesiredStateConfiguration -Label $labels
```

----------

### Users

#### Getting the current authenticated user
```powershell
Get-GitHubUser -Current
```

#### Updating the current authenticated user
```powershell
Update-GitHubCurrentUser -Location 'Seattle, WA' -Hireable:$false
```

#### Getting any user
```powershell
Get-GitHubUser -Name octocat
```

#### Getting all users
```powershell
Get-GitHubUser
```
> Warning: This will take a while.  It's getting _every_ GitHub user.
