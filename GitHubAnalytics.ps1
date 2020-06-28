# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

function Group-GitHubIssue
{
<#
    .SYNOPSIS
        Groups the provided issues based on the specified grouping criteria.

    .DESCRIPTION
        Groups the provided issues based on the specified grouping criteria.

        Currently able to group Issues by week.

        The Git repo for this module can be found here: http://aka.ms/PowerShellForGitHub

    .PARAMETER Issue
        The Issue(s) to be grouped.

    .PARAMETER Weeks
        The number of weeks to group the Issues by.

    .PARAMETER DateType
        The date property that should be inspected when determining which week grouping the issue
        if part of.

    .INPUTS
        GitHub.Issue

    .OUTPUTS
        [PSCustomObject[]]
        Collection of issues and counts, by week, along with the total count of issues.

    .EXAMPLE
        $issues = @()
        $issues += Get-GitHubIssue -Uri 'https://github.com/powershell/xpsdesiredstateconfiguration'
        $issues += Get-GitHubIssue -Uri 'https://github.com/powershell/xactivedirectory'
        $issues | Group-GitHubIssue -Weeks 12 -DateType Closed
#>
    [CmdletBinding(DefaultParameterSetName = 'Weekly')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSReviewUnusedParameter", "", Justification="DateType due to PowerShell/PSScriptAnalyzer#1472")]
    param
    (
        [Parameter(
            Mandatory,
            ValueFromPipeline)]
        [PSCustomObject[]] $Issue,

        [Parameter(
            Mandatory,
            ParameterSetName='Weekly')]
        [ValidateRange(0, 10000)]
        [int] $Weeks,

        [Parameter(ParameterSetName='Weekly')]
        [ValidateSet('Created', 'Closed')]
        [string] $DateType = 'Created'
    )

    begin
    {
        Write-InvocationLog

        if ($PSCmdlet.ParameterSetName -eq 'Weekly')
        {
            $weekDates = Get-WeekDate -Weeks $Weeks

            $result = [ordered]@{}
            foreach ($week in $weekDates)
            {
                $result[$week] = ([PSCustomObject]([ordered]@{
                    'WeekStart' = $week
                    'Count' = 0
                    'Issues' = @()
                }))
            }

            $result['total'] = ([PSCustomObject]([ordered]@{
                'WeekStart' = 'total'
                'Count' = 0
                'Issues' = @()
            }))
        }
    }

    process
    {
        if ($PSCmdlet.ParameterSetName -eq 'Weekly')
        {
            $endOfWeek = Get-Date
            foreach ($week in $weekDates)
            {
                $filteredIssues = @($Issue | Where-Object {
                    (($DateType -eq 'Created') -and
                     ($_.created_at -ge $week) -and
                     ($_.created_at -le $endOfWeek)) -or
                    (($DateType -eq 'Closed') -and
                     ($_.closed_at -ge $week) -and
                     ($_.closed_at -le $endOfWeek))
                })

                $endOfWeek = $week

                $result[$week].Issues += $filteredIssues
                $result[$week].Count += ($filteredIssues.Count)

                $result['total'].Issues += $filteredIssues
                $result['total'].Count += ($filteredIssues.Count)
            }
        }
        else
        {
            Write-Output -InputObject $Issue
        }
    }

    end
    {
        if ($PSCmdlet.ParameterSetName -eq 'Weekly')
        {
            foreach ($entry in $result.Values.GetEnumerator())
            {
                Write-Output -InputObject $entry
            }
        }
    }
}

function Group-GitHubPullRequest
{
<#
    .SYNOPSIS
        Groups the provided pull requests based on the specified grouping criteria.

    .DESCRIPTION
        Groups the provided pull requests based on the specified grouping criteria.

        Currently able to group Pull Requests by week.

        The Git repo for this module can be found here: http://aka.ms/PowerShellForGitHub

    .PARAMETER PullRequest
        The Pull Requests(s) to be grouped.

    .PARAMETER Weeks
        The number of weeks to group the Pull Requests by.

    .PARAMETER DateType
        The date property that should be inspected when determining which week grouping the
        pull request if part of.

    .INPUTS
        GitHub.PullRequest

    .OUTPUTS
        [PSCustomObject[]] Collection of pull requests and counts, by week, along with the
        total count of pull requests.

    .EXAMPLE
        $pullRequests = @()
        $pullRequests += Get-GitHubPullRequest -Uri 'https://github.com/powershell/xpsdesiredstateconfiguration'
        $pullRequests += Get-GitHubPullRequest -Uri 'https://github.com/powershell/xactivedirectory'
        $pullRequests | Group-GitHubPullRequest -Weeks 12 -DateType Closed
#>
    [CmdletBinding(DefaultParameterSetName='Weekly')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSReviewUnusedParameter", "", Justification="DateType due to PowerShell/PSScriptAnalyzer#1472")]
    param
    (
        [Parameter(
            Mandatory,
            ValueFromPipeline)]
        [PSCustomObject[]] $PullRequest,

        [Parameter(
            Mandatory,
            ParameterSetName='Weekly')]
        [ValidateRange(0, 10000)]
        [int] $Weeks,

        [Parameter(ParameterSetName='Weekly')]
        [ValidateSet('Created', 'Merged')]
        [string] $DateType = 'Created'
    )

    begin
    {
        Write-InvocationLog

        if ($PSCmdlet.ParameterSetName -eq 'Weekly')
        {
            $weekDates = Get-WeekDate -Weeks $Weeks

            $result = [ordered]@{}
            foreach ($week in $weekDates)
            {
                $result[$week] = ([PSCustomObject]([ordered]@{
                    'WeekStart' = $week
                    'Count' = 0
                    'PullRequests' = @()
                }))
            }

            $result['total'] = ([PSCustomObject]([ordered]@{
                'WeekStart' = 'total'
                'Count' = 0
                'PullRequests' = @()
            }))
        }
    }

    process
    {
        if ($PSCmdlet.ParameterSetName -eq 'Weekly')
        {
            $endOfWeek = Get-Date
            foreach ($week in $weekDates)
            {
                $filteredPullRequests = @($PullRequest | Where-Object {
                    (($DateType -eq 'Created') -and
                     ($_.created_at -ge $week) -and
                     ($_.created_at -le $endOfWeek)) -or
                    (($DateType -eq 'Merged') -and
                     ($_.merged_at -ge $week) -and
                     ($_.merged_at -le $endOfWeek))
                })

                $endOfWeek = $week

                $result[$week].PullRequests += $filteredPullRequests
                $result[$week].Count += ($filteredPullRequests.Count)

                $result['total'].PullRequests += $filteredPullRequests
                $result['total'].Count += ($filteredPullRequests.Count)
            }
        }
        else
        {
            Write-Output -InputObject $PullRequest
        }
    }

    end
    {
        if ($PSCmdlet.ParameterSetName -eq 'Weekly')
        {
            foreach ($entry in $result.Values.GetEnumerator())
            {
                Write-Output -InputObject $entry
            }
        }
    }
}

function Get-WeekDate
{
<#
    .SYNOPSIS
        Retrieves an array of dates with starts of $Weeks previous weeks.
        Dates are sorted in reverse chronological order

    .DESCRIPTION
        Retrieves an array of dates with starts of $Weeks previous weeks.
        Dates are sorted in reverse chronological order

        The Git repo for this module can be found here: http://aka.ms/PowerShellForGitHub

    .PARAMETER Weeks
        The number of weeks prior to today that should be included in the final result.

    .OUTPUTS
        [DateTime[]] List of DateTimes representing the first day of each requested week.

    .EXAMPLE
        Get-WeekDate -Weeks 10
#>
    [CmdletBinding()]
    [OutputType([DateTime[]])]
    param(
        [ValidateRange(0, 10000)]
        [int] $Weeks = 12
    )

    $dates = @()

    $midnightToday = Get-Date -Hour 0 -Minute 0 -Second 0 -Millisecond 0
    $startOfWeek = $midnightToday.AddDays(- ($midnightToday.DayOfWeek.value__ - 1))

    $i = 0
    while ($i -lt $Weeks)
    {
        $dates += $startOfWeek
        $startOfWeek = $startOfWeek.AddDays(-7)
        $i++
    }

    return $dates
}
