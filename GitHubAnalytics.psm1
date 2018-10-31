<#
    .SYNOPSIS PowerShell module for GitHub analytics
#>

# Import module which defines $global:gitHubApiToken with GitHub API access token. Create this file it if it doesn't exist.
$apiTokensFilePath = "$PSScriptRoot\ApiTokens.psm1"
if (Test-Path $apiTokensFilePath)
{
    Write-Host "Importing $apiTokensFilePath"
    Import-Module  -force $apiTokensFilePath
}
else
{
    Write-Warning "$apiTokensFilePath does not exist, skipping import"
    Write-Warning @'
This module should define $global:gitHubApiToken with your GitHub API access token in ApiTokens.psm1. Create this file if it doesn't exist.
You can simply rename ApiTokensTemplate.psm1 to ApiTokens.psm1 and update value of $global:gitHubApiToken, then reimport this module with -Force switch.
You can get GitHub token from https://github.com/settings/tokens
If you don't provide it, you can still use this module, but you will be limited to 60 queries per hour.
'@
}

$script:gitHubToken = $global:gitHubApiToken 
$script:gitHubApiUrl = "https://api.github.com"
$script:gitHubApiReposUrl = "https://api.github.com/repos"
$script:gitHubApiOrgsUrl = "https://api.github.com/orgs"

<#
    .SYNOPSIS Function which gets list of issues for given repository
    .PARAM
        RepositoryUrl Array of repository urls which we want to get issues from
    .PARAM 
        State Whether we want to get open, closed or all issues
    .PARAM
        CreatedOnOrAfter Filter to only get issues created on or after specific date
    .PARAM
        CreatedOnOrBefore Filter to only get issues created on or before specific date    
    .PARAM
        ClosedOnOrAfter Filter to only get issues closed on or after specific date
    .PARAM
        ClosedOnOrBefore Filter to only get issues closed on or before specific date
    .PARAM
        GitHubAccessToken GitHub API Access Token.
            Get github token from https://github.com/settings/tokens 
            If you don't provide it, you can still use this script, but you will be limited to 60 queries per hour.
    .EXAMPLE
        $issues = Get-GitHubIssueForRepository -RepositoryUrl @('https://github.com/PowerShell/xPSDesiredStateConfiguration')
    .EXAMPLE
        $issues = Get-GitHubIssueForRepository `
            -RepositoryUrl @('https://github.com/PowerShell/xPSDesiredStateConfiguration', "https://github.com/PowerShell/xWindowsUpdate" ) `
            -CreatedOnOrAfter '2015-04-20'
#>
function Get-GitHubIssueForRepository
{
    param
    (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [String[]] $RepositoryUrl,
        [ValidateSet("open", "closed", "all")]
        [String] $State = "open",
        [DateTime] $CreatedOnOrAfter,
        [DateTime] $CreatedOnOrBefore,
        [DateTime] $ClosedOnOrAfter,
        [DateTime] $ClosedOnOrBefore,
        $GitHubAccessToken = $script:gitHubToken
    )

    $resultToReturn = @()

    $index = 0
    
    foreach ($repository in $RepositoryUrl)
    {
        Write-Host "Getting issues for repository $repository" -ForegroundColor Yellow

        $repositoryName = Get-GitHubRepositoryNameFromUrl -RepositoryUrl $repository
        $repositoryOwner = Get-GitHubRepositoryOwnerFromUrl -RepositoryUrl $repository

        # Create query for issues
        $query = "$script:gitHubApiReposUrl/$repositoryOwner/$repositoryName/issues?state=$State"
            
        if (![string]::IsNullOrEmpty($GitHubAccessToken))
        {
            $query += "&access_token=$GitHubAccessToken"
        }
        
        # Obtain issues    
        do 
        {
            try
            {
                $jsonResult = Invoke-WebRequest $query
                $issues = ConvertFrom-Json -InputObject $jsonResult.content
            }    
            catch [System.Net.WebException] {
                Write-Error "Failed to execute query with exception: $($_.Exception)`nHTTP status code: $($_.Exception.Response.StatusCode)"
                return $null
            }
            catch {
                Write-Error "Failed to execute query with exception: $($_.Exception)"
                return $null
            }

            foreach ($issue in $issues)
            {
                # GitHub considers pull request to be an issue, so let's skip pull requests.
                if ($issue.pull_request -ne $null)
                {
                    continue
                }

                # Filter according to CreatedOnOrAfter
                $createdDate = Get-Date -Date $issue.created_at
                if (($CreatedOnOrAfter -ne $null) -and ($createdDate -lt $CreatedOnOrAfter))
                {
                    continue  
                }

                # Filter according to CreatedOnOrBefore
                if (($CreatedOnOrBefore -ne $null) -and ($createdDate -gt $CreatedOnOrBefore))
                {
                    continue  
                }

                if ($issue.closed_at -ne $null)
                {
                    # Filter according to ClosedOnOrAfter
                    $closedDate = Get-Date -Date $issue.closed_at
                    if (($ClosedOnOrAfter -ne $null) -and ($closedDate -lt $ClosedOnOrAfter))
                    {
                        continue  
                    }

                    # Filter according to ClosedOnOrBefore
                    if (($ClosedOnOrBefore -ne $null) -and ($closedDate -gt $ClosedOnOrBefore))
                    {
                        continue  
                    }
                }
                else
                {
                    # If issue isn't closed, but we specified filtering on closedOn, skip it
                    if (($ClosedOnOrAfter -ne $null) -or ($ClosedOnOrBefore -ne $null))
                    {
                        continue
                    }
                }
                
                Write-Verbose "$index. $($issue.html_url) ## Created: $($issue.created_at) ## Closed: $($issue.closed_at)"
                $index++

                $resultToReturn += $issue
            }
            $query = Get-NextResultPage -JsonResult $jsonResult
        } while ($query -ne $null)
    }

    return $resultToReturn
}

<#
    .SYNOPSIS Function which returns number of issues created/merged in every week in specific repositories
    .PARAM
        RepositoryUrl Array of repository urls which we want to get pull requests from
    .PARAM 
        NumberOfWeeks How many weeks we want to obtain data for
    .PARAM 
        DataType Whether we want to get information about created or merged issues in specific weeks
    .PARAM
        GitHubAccessToken GitHub API Access Token.
            Get github token from https://github.com/settings/tokens 
            If you don't provide it, you can still use this script, but you will be limited to 60 queries per hour.
    .EXAMPLE
        Get-GitHubWeeklyIssueForRepository -RepositoryUrl @('https://github.com/powershell/xpsdesiredstateconfiguration', 'https://github.com/powershell/xactivedirectory') -Datatype closed

#>
function Get-GitHubWeeklyIssueForRepository
{
    param
    (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [String[]] $RepositoryUrl,
        [int] $NumberOfWeeks = 12,
        [Parameter(Mandatory=$true)]
        [ValidateSet("created","closed")]
        [string] $DataType,
        $GitHubAccessToken = $script:gitHubToken
    )

    $weekDates = Get-WeekDate -NumberOfWeeks $NumberOfWeeks
    $endOfWeek = Get-Date
    $results = @()
    $totalIssues = 0

    foreach ($week in $weekDates)
    {
        Write-Host "Getting issues from week of $week"

        $issues = $null

        if ($DataType -eq "closed")
        {
            $issues = Get-GitHubIssueForRepository `
            -RepositoryUrl $RepositoryUrl -State 'all' -ClosedOnOrAfter $week -ClosedOnOrBefore $endOfWeek    
        }
        elseif ($DataType -eq "created")
        {
            $issues = Get-GitHubIssueForRepository `
            -RepositoryUrl $RepositoryUrl -State 'all' -CreatedOnOrAfter $week -CreatedOnOrBefore $endOfWeek
        }
        
        $endOfWeek = $week
        
        if (($issues -ne $null) -and ($issues.Count -eq $null))
        {
            $count = 1
        }
        else
        {
            $count = $issues.Count
        }
        
        $totalIssues += $count

        $results += @{"BeginningOfWeek"=$week; "Issues"=$count}
    }

    $results += @{"BeginningOfWeek"="total"; "Issues"=$totalIssues}
    return $results    
}

<#
    .SYNOPSIS Function which returns repositories with biggest number of issues meeting specified criteria
    .PARAM
        RepositoryUrl Array of repository urls which we want to get issues from
    .PARAM 
        State Whether we want to get information about open issues, closed or both
    .PARAM
        CreatedOnOrAfter Get information about issues created after specific date
    .PARAM
        ClosedOnOrAfter Get information about issues closed after specific date
    .PARAM
        GitHubAccessToken GitHub API Access Token.
            Get github token from https://github.com/settings/tokens 
            If you don't provide it, you can still use this script, but you will be limited to 60 queries per hour.
    .EXAMPLE
        Get-GitHubTopIssueRepository -RepositoryUrl @('https://github.com/powershell/xsharepoint', 'https://github.com/powershell/xCertificate', 'https://github.com/powershell/xwebadministration') -State open

#>
function Get-GitHubTopIssueRepository
{
    param
    (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [String[]] $RepositoryUrl,
        [ValidateSet("open", "closed", "all")]
        [String] $State = "open",
        [DateTime] $CreatedOnOrAfter,
        [DateTime] $ClosedOnOrAfter,
        $GitHubAccessToken = $script:gitHubToken
    )
    
    if (($State -eq "open") -and ($ClosedOnOrAfter -ne $null))
    {
        Throw "ClosedOnOrAfter cannot be specified if State is open"
    }

    $repositoryIssues = @{}

    foreach ($repository in $RepositoryUrl)
    {
        if (($ClosedOnOrAfter -ne $null) -and ($CreatedOnOrAfter -ne $null))
        {
            $issues = Get-GitHubIssueForRepository `
            -RepositoryUrl $repository `
            -State $State -ClosedOnOrAfter $ClosedOnOrAfter -CreatedOnOrAfter $CreatedOnOrAfter
        }
        elseif (($ClosedOnOrAfter -ne $null) -and ($CreatedOnOrAfter -eq $null))
        {
            $issues = Get-GitHubIssueForRepository `
            -RepositoryUrl $repository `
            -State $State -ClosedOnOrAfter $ClosedOnOrAfter
        }
        elseif (($ClosedOnOrAfter -eq $null) -and ($CreatedOnOrAfter -ne $null))
        {
            $issues = Get-GitHubIssueForRepository `
            -RepositoryUrl $repository `
            -State $State -CreatedOnOrAfter $CreatedOnOrAfter
        }
        elseif (($ClosedOnOrAfter -eq $null) -and ($CreatedOnOrAfter -eq $null))
        {
            $issues = Get-GitHubIssueForRepository `
            -RepositoryUrl $repository `
            -State $State
        }

        if (($issues -ne $null) -and ($issues.Count -eq $null))
        {
            $count = 1
        }
        else
        {
            $count = $issues.Count
        }

        $repositoryName = Get-GitHubRepositoryNameFromUrl -RepositoryUrl $repository
        $repositoryIssues.Add($repositoryName, $count)
    }

    $repositoryIssues = $repositoryIssues.GetEnumerator() | Sort-Object Value -Descending

    return $repositoryIssues
}

<#
    .SYNOPSIS Function which gets list of pull requests for given repository
    .PARAM
        RepositoryUrl Array of repository urls which we want to get pull requests from
    .PARAM 
        State Whether we want to get open, closed or all pull requests
    .PARAM
        CreatedOnOrAfter Filter to only get pull requests created on or after specific date
    .PARAM
        CreatedOnOrBefore Filter to only get pull requests created on or before specific date    
    .PARAM
        MergedOnOrAfter Filter to only get issues merged on or after specific date
    .PARAM
        MergedOnOrBefore Filter to only get issues merged on or before specific date
    .PARAM
        GitHubAccessToken GitHub API Access Token.
            Get github token from https://github.com/settings/tokens 
            If you don't provide it, you can still use this script, but you will be limited to 60 queries per hour.
    .EXAMPLE
        $pullRequests = Get-GitHubPullRequestForRepository -RepositoryUrl @('https://github.com/PowerShell/xPSDesiredStateConfiguration')
    .EXAMPLE
        $pullRequests = Get-GitHubPullRequestForRepository `
            -RepositoryUrl @('https://github.com/PowerShell/xPSDesiredStateConfiguration', 'https://github.com/PowerShell/xWebAdministration') `
            -State closed -MergedOnOrAfter 2015-02-13 -MergedOnOrBefore 2015-06-17

#>
function Get-GitHubPullRequestForRepository
{
    param 
    (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [String[]] $RepositoryUrl,
        [ValidateSet("open", "closed", "all")]
        [String] $State = "open",
        [DateTime] $CreatedOnOrAfter,
        [DateTime] $CreatedOnOrBefore,
        [DateTime] $MergedOnOrAfter,
        [DateTime] $MergedOnOrBefore,
        $GitHubAccessToken = $script:gitHubToken
    )

    $resultToReturn = @()

    $index = 0
    
    foreach ($repository in $RepositoryUrl)
    {
        Write-Host "Getting pull requests for repository $repository" -ForegroundColor Yellow

        $repositoryName = Get-GitHubRepositoryNameFromUrl -RepositoryUrl $repository
        $repositoryOwner = Get-GitHubRepositoryOwnerFromUrl -RepositoryUrl $repository

        # Create query for pull requests
        $query = "$script:gitHubApiReposUrl/$repositoryOwner/$repositoryName/pulls?state=$State"
            
        if (![string]::IsNullOrEmpty($GitHubAccessToken))
        {
            $query += "&access_token=$GitHubAccessToken"
        }
        
        # Obtain pull requests
        do 
        {
            try
            {
                $jsonResult = Invoke-WebRequest $query
                $pullRequests = ConvertFrom-Json -InputObject $jsonResult.content
            }    
            catch [System.Net.WebException] {
                Write-Error "Failed to execute query with exception: $($_.Exception)`nHTTP status code: $($_.Exception.Response.StatusCode)"
                return $null
            }
            catch {
                Write-Error "Failed to execute query with exception: $($_.Exception)"
                return $null
            }

            foreach ($pullRequest in $pullRequests)
            {
                # Filter according to CreatedOnOrAfter
                $createdDate = Get-Date -Date $pullRequest.created_at
                if (($CreatedOnOrAfter -ne $null) -and ($createdDate -lt $CreatedOnOrAfter))
                {
                    continue  
                }

                # Filter according to CreatedOnOrBefore
                if (($CreatedOnOrBefore -ne $null) -and ($createdDate -gt $CreatedOnOrBefore))
                {
                    continue  
                }

                if ($pullRequest.merged_at -ne $null)
                {
                    # Filter according to MergedOnOrAfter
                    $mergedDate = Get-Date -Date $pullRequest.merged_at
                    if (($MergedOnOrAfter -ne $null) -and ($mergedDate -lt $MergedOnOrAfter))
                    {
                        continue
                    }

                    # Filter according to MergedOnOrBefore
                    if (($MergedOnOrBefore -ne $null) -and ($mergedDate -gt $MergedOnOrBefore))
                    {
                        continue  
                    }
                }
                else
                {
                    # If issue isn't merged, but we specified filtering on mergedOn, skip it
                    if (($MergedOnOrAfter -ne $null) -or ($MergedOnOrBefore -ne $null))
                    {
                        continue
                    }
                }
                
                Write-Verbose "$index. $($pullRequest.html_url) ## Created: $($pullRequest.created_at) ## Merged: $($pullRequest.merged_at)"
                $index++

                $resultToReturn += $pullRequest
            }
            $query = Get-NextResultPage -JsonResult $jsonResult
        } while ($query -ne $null) 
    }

    return $resultToReturn
}

<#
    .SYNOPSIS Function which returns number of pull requests created/merged in every week in specific repositories
    .PARAM
        RepositoryUrl Array of repository urls which we want to get pull requests from
    .PARAM 
        NumberOfWeeks How many weeks we want to obtain data for
    .PARAM 
        DataType Whether we want to get information about created or merged pull requests in specific weeks
    .PARAM
        GitHubAccessToken GitHub API Access Token.
            Get github token from https://github.com/settings/tokens 
            If you don't provide it, you can still use this script, but you will be limited to 60 queries per hour.
    .EXAMPLE
        Get-GitHubWeeklyPullRequestForRepository -RepositoryUrl @('https://github.com/powershell/xpsdesiredstateconfiguration', 'https://github.com/powershell/xwebadministration') -Datatype merged

#>
function Get-GitHubWeeklyPullRequestForRepository
{
    param
    (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [String[]] $RepositoryUrl,
        [int] $NumberOfWeeks = 12,
        [Parameter(Mandatory=$true)]
        [ValidateSet("created","merged")]
        [string] $DataType,
        $GitHubAccessToken = $script:gitHubToken
    )
    
    $weekDates = Get-WeekDate -NumberOfWeeks $NumberOfWeeks
    $endOfWeek = Get-Date
    $results = @()
    $totalPullRequests = 0

    foreach ($week in $weekDates)
    {
        Write-Host "Getting Pull Requests from week of $week"

        $pullRequests = $null

        if ($DataType -eq "merged")
        {
            $pullRequests = Get-GitHubPullRequestForRepository `
            -RepositoryUrl $RepositoryUrl `
            -State 'all' -MergedOnOrAfter $week -MergedOnOrBefore $endOfWeek
        }
        elseif ($DataType -eq "created")
        {
            $pullRequests = Get-GitHubPullRequestForRepository `
            -RepositoryUrl $RepositoryUrl `
            -State 'all' -CreatedOnOrAfter $week -CreatedOnOrBefore $endOfWeek
        }
        
        
        $endOfWeek = $week
        

        if (($pullRequests -ne $null) -and ($pullRequests.Count -eq $null))
        {
            $count = 1
        }
        else
        {
            $count = $pullRequests.Count
        }
        $totalPullRequests += $count

        $results += @{"BeginningOfWeek"=$week; "PullRequests"=$count}
    }

    $results += @{"BeginningOfWeek"="total"; "PullRequests"=$totalPullRequests}
    return $results    
}

<#
    .SYNOPSIS Function which returns repositories with biggest number of pull requests meeting specified criteria
    .PARAM
        RepositoryUrl Array of repository urls which we want to get pull requests from
    .PARAM 
        State Whether we want to get information about open pull requests, closed or both
    .PARAM
        CreatedOnOrAfter Get information about pull requests created after specific date
    .PARAM
        MergedOnOrAfter Get information about pull requests merged after specific date
    .PARAM
        GitHubAccessToken GitHub API Access Token.
            Get github token from https://github.com/settings/tokens 
            If you don't provide it, you can still use this script, but you will be limited to 60 queries per hour.
    .EXAMPLE
        Get-GitHubTopPullRequestRepository -RepositoryUrl @('https://github.com/powershell/xsharepoint', 'https://github.com/powershell/xwebadministration') -State closed -MergedOnOrAfter 2015-04-20

#>
function Get-GitHubTopPullRequestRepository
{
    param
    (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [String[]] $RepositoryUrl,
        [ValidateSet("open", "closed", "all")]
        [String] $State = "open",
        [DateTime] $CreatedOnOrAfter,
        [DateTime] $MergedOnOrAfter,
        $GitHubAccessToken = $script:gitHubToken
    )
    
    if (($State -eq "open") -and ($MergedOnOrAfter -ne $null))
    {
        Throw "MergedOnOrAfter cannot be specified if State is open"
    }

    $repositoryPullRequests = @{}

    foreach ($repository in $RepositoryUrl)
    {
        if (($MergedOnOrAfter -ne $null) -and ($CreatedOnOrAfter -ne $null))
        {
            $pullRequests = Get-GitHubPullRequestForRepository `
            -RepositoryUrl $repository `
            -State $State -MergedOnOrAfter $MergedOnOrAfter -CreatedOnOrAfter $CreatedOnOrAfter
        }
        elseif (($MergedOnOrAfter -ne $null) -and ($CreatedOnOrAfter -eq $null))
        {
            $pullRequests = Get-GitHubPullRequestForRepository `
            -RepositoryUrl $repository `
            -State $State -MergedOnOrAfter $MergedOnOrAfter
        }
        elseif (($MergedOnOrAfter -eq $null) -and ($CreatedOnOrAfter -ne $null))
        {
            $pullRequests = Get-GitHubPullRequestForRepository `
            -RepositoryUrl $repository `
            -State $State -CreatedOnOrAfter $CreatedOnOrAfter
        }
        elseif (($MergedOnOrAfter -eq $null) -and ($CreatedOnOrAfter -eq $null))
        {
            $pullRequests = Get-GitHubPullRequestForRepository `
            -RepositoryUrl $repository `
            -State $State
        }

        if (($pullRequests -ne $null) -and ($pullRequests.Count -eq $null))
        {
            $count = 1
        }
        else
        {
            $count = $pullRequests.Count
        }

        $repositoryName = Get-GitHubRepositoryNameFromUrl -RepositoryUrl $repository
        $repositoryPullRequests.Add($repositoryName, $count)
    }

    $repositoryPullRequests = $repositoryPullRequests.GetEnumerator() | Sort-Object Value -Descending

    return $repositoryPullRequests
}

<#
    .SYNOPSIS Obtain repository collaborators

    .EXAMPLE $collaborators = Get-GitHubRepositoryCollaborator -RepositoryUrl @('https://github.com/PowerShell/DscResources')
#>
function Get-GitHubRepositoryCollaborator
{
    param 
    (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [String[]] $RepositoryUrl,
        $GitHubAccessToken = $script:gitHubToken
    )

    $resultToReturn = @()
    
    foreach ($repository in $RepositoryUrl)
    {
        $index = 0
        Write-Host "Getting repository collaborators for repository $repository" -ForegroundColor Yellow

        $repositoryName = Get-GitHubRepositoryNameFromUrl -RepositoryUrl $repository
        $repositoryOwner = Get-GitHubRepositoryOwnerFromUrl -RepositoryUrl $repository

        $query = "$script:gitHubApiReposUrl/$repositoryOwner/$repositoryName/collaborators"
            
        if (![string]::IsNullOrEmpty($GitHubAccessToken))
        {
            $query += "?access_token=$GitHubAccessToken"
        }
        
        # Obtain all collaborators
        do 
        {
            try
            {
                $jsonResult = Invoke-WebRequest $query
                $collaborators = ConvertFrom-Json -InputObject $jsonResult.content
            }    
            catch [System.Net.WebException] {
                Write-Error "Failed to execute query with exception: $($_.Exception)`nHTTP status code: $($_.Exception.Response.StatusCode)"
                return $null
            }
            catch {
                Write-Error "Failed to execute query with exception: $($_.Exception)"
                return $null
            }

            foreach ($collaborator in $collaborators)
            {          
                Write-Verbose "$index. $($collaborator.login)"
                $index++
                $resultToReturn += $collaborator
            }
            $query = Get-NextResultPage -JsonResult $jsonResult
        } while ($query -ne $null)
    }
    return $resultToReturn
}

<#
    .SYNOPSIS Obtain repository contributors

    .EXAMPLE $contributors = Get-GitHubRepositoryContributor -RepositoryUrl @('https://github.com/PowerShell/DscResources', 'https://github.com/PowerShell/xWebAdministration')
#>
function Get-GitHubRepositoryContributor
{
    param 
    (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [String[]] $RepositoryUrl,
        $GitHubAccessToken = $script:gitHubToken
    )

    $resultToReturn = @()
    
    foreach ($repository in $RepositoryUrl)
    {
        $index = 0
        Write-Host "Getting repository contributors for repository $repository" -ForegroundColor Yellow

        $repositoryName = Get-GitHubRepositoryNameFromUrl -RepositoryUrl $repository
        $repositoryOwner = Get-GitHubRepositoryOwnerFromUrl -RepositoryUrl $repository

        $query = "$script:gitHubApiReposUrl/$repositoryOwner/$repositoryName/stats/contributors"
            
        if (![string]::IsNullOrEmpty($GitHubAccessToken))
        {
            $query += "?access_token=$GitHubAccessToken"
        }
        
        # Obtain all contributors    
        do 
        {
            try
            {
                $jsonResult = Invoke-WebRequest $query
                $contributors = ConvertFrom-Json -InputObject $jsonResult.content
            }    
            catch [System.Net.WebException] {
                Write-Error "Failed to execute query with exception: $($_.Exception)`nHTTP status code: $($_.Exception.Response.StatusCode)"
                return $null
            }
            catch {
                Write-Error "Failed to execute query with exception: $($_.Exception)"
                return $null
            }

            foreach ($contributor in $contributors)
            {          
                Write-Verbose "$index. $($contributor.author.login). Commits: $($contributor.total)"
                $index++
                $resultToReturn += $contributor
            }
            $query = Get-NextResultPage -JsonResult $jsonResult
        } while ($query -ne $null)


    }

    return $resultToReturn
}

<#
    .SYNOPSIS Obtain organization members list
    .PARAM 
        OrganizationName name of the organization
    .PARAM
        GitHubAccessToken GitHub API Access Token.
            Get github token from https://github.com/settings/tokens 
            If you don't provide it, you can still use this script, but you will be limited to 60 queries per hour.

    .EXAMPLE $members = Get-GitHubOrganizationMember -OrganizationName PowerShell
#>
function Get-GitHubOrganizationMember
{
    param 
    (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [String] $OrganizationName,
        $GitHubAccessToken = $script:gitHubToken
    )
    $resultToReturn = @()
    $index = 0

    $query = "$script:gitHubApiOrgsUrl/$OrganizationName/members"

    if (![string]::IsNullOrEmpty($GitHubAccessToken))
    {
        $query += "?access_token=$GitHubAccessToken"
    }

    do 
    {
        try
        {
            $jsonResult = Invoke-WebRequest $query
            $members = ConvertFrom-Json -InputObject $jsonResult.content
        }    
        catch [System.Net.WebException] {
            Write-Error "Failed to execute query with exception: $($_.Exception)`nHTTP status code: $($_.Exception.Response.StatusCode)"
            return $null
        }
        catch {
            Write-Error "Failed to execute query with exception: $($_.Exception)"
            return $null
        }

        foreach ($member in $members)
        {          
            Write-Verbose "$index. $(($member).login)"
            $index++
            $resultToReturn += $member
        }
        $query = Get-NextResultPage -JsonResult $jsonResult
    } while ($query -ne $null)

    return $resultToReturn
}

<#
    .SYNOPSIS Obtain organization teams list
    .PARAM 
        OrganizationName name of the organization
    .PARAM
        GitHubAccessToken GitHub API Access Token.
            Get github token from https://github.com/settings/tokens 
            If you don't provide it, you can still use this script, but you will be limited to 60 queries per hour.
    .EXAMPLE Get-GitHubTeam -OrganizationName PowerShell
#>
function Get-GitHubTeam
{
    param 
    (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [Alias('OrganizationName')]
        [String] $OrganizationName,
        $GitHubAccessToken = $script:gitHubToken
    )
    $resultToReturn = @()
    $index = 0

    $query = "$script:gitHubApiUrl/orgs/$OrganizationName/teams"
        
    if (![string]::IsNullOrEmpty($GitHubAccessToken))
    {
        $query += "?access_token=$GitHubAccessToken"
    }

    do 
    {
        try
        {
            $jsonResult = Invoke-WebRequest $query
            $teams = ConvertFrom-Json -InputObject $jsonResult.content
        }    
        catch [System.Net.WebException] {
            Write-Error "Failed to execute query with exception: $($_.Exception)`nHTTP status code: $($_.Exception.Response.StatusCode)"
            return $null
        }
        catch {
            Write-Error "Failed to execute query with exception: $($_.Exception)"
            return $null
        }

        foreach ($team in $teams)
        {          
            Write-Verbose "$index. $(($team).name)"
            $index++
            $resultToReturn += $team
        }
        $query = Get-NextResultPage -JsonResult $jsonResult
    } while ($query -ne $null)

    return $resultToReturn
}

<#
    .SYNOPSIS Obtain organization team members list
    .PARAM 
        OrganizationName name of the organization
    .PARAM 
        TeamName name of the team in the organization
    .PARAM
        GitHubAccessToken GitHub API Access Token.
            Get github token from https://github.com/settings/tokens 
            If you don't provide it, you can still use this script, but you will be limited to 60 queries per hour.

    .EXAMPLE $members = Get-GitHubTeamMember -Organization PowerShell -TeamName Everybody
#>
function Get-GitHubTeamMember
{
    param 
    (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [String] $OrganizationName,
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [String] $TeamName,
        $GitHubAccessToken = $script:gitHubToken
    )
    $resultToReturn = @()
    $index = 0

    $teams = Get-GitHubTeam -OrganizationName $OrganizationName
    $team = $teams | ? {$_.name -eq $TeamName}
    if ($team) {
        Write-Host "Found team $TeamName with id $($team.id)"
    } else {
        Write-Host "Cannot find team $TeamName"
        return
    }

    $query = "$script:gitHubApiUrl/teams/$($team.id)/members"
        
    if (![string]::IsNullOrEmpty($GitHubAccessToken))
    {
        $query += "?access_token=$GitHubAccessToken"
    }

    do 
    {
        try
        {
            $jsonResult = Invoke-WebRequest $query
            $members = ConvertFrom-Json -InputObject $jsonResult.content
        }    
        catch [System.Net.WebException] {
            Write-Error "Failed to execute query with exception: $($_.Exception)`nHTTP status code: $($_.Exception.Response.StatusCode)"
            return $null
        }
        catch {
            Write-Error "Failed to execute query with exception: $($_.Exception)"
            return $null
        }

        foreach ($member in $members)
        {          
            Write-Verbose "$index. $($member.login)"
            $index++
            $resultToReturn += $member
        }
        $query = Get-NextResultPage -JsonResult $jsonResult
    } while ($query -ne $null)

    return $resultToReturn
}

<#
    .SYNOPSIS Function which gets list of repositories for a given organization
    .PARAM
        OrganizationName The name of the organization
    .PARAM
        GitHubAccessToken GitHub API Access Token.
            Get github token from https://github.com/settings/tokens 
            If you don't provide it, you can still use this script, but you will be limited to 60 queries per hour.
    .EXAMPLE
        $repositories = Get-GitHubOrganizationRepository -OrganizationName 'PowerShell'
#>
function Get-GitHubOrganizationRepository
{
    param
    (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [Alias('Organization')]
        [String] $OrganizationName,
        $GitHubAccessToken = $script:gitHubToken
    )

    $resultToReturn = @()

    $query = "$script:gitHubApiUrl/orgs/$OrganizationName/repos?"
            
    if (![string]::IsNullOrEmpty($GitHubAccessToken))
    {
        $query += "&access_token=$GitHubAccessToken"
    }    

    do
    {
        try
        {
            $jsonResult = Invoke-WebRequest $query
            $repositories = (ConvertFrom-Json -InputObject $jsonResult.content)
        }    
        catch [System.Net.WebException] {
            Write-Error "Failed to execute query with exception: $($_.Exception)`nHTTP status code: $($_.Exception.Response.StatusCode)"
            return $null
        }
        catch {
            Write-Error "Failed to execute query with exception: $($_.Exception)"
            return $null
        }

        foreach($repository in $repositories)
        {
            $resultToReturn += $repository
        }
        $query = Get-NextResultPage -JsonResult $jsonResult
    } while ($query -ne $null)

    return $resultToReturn
}

<#
    .SYNOPSIS Function which gets a list of branches for a given repository
    .PARAM
        OwnerName The name of the repository owner
    .PARAM
        Repository The name of the repository
    .PARAM
        GitHubAccessToken GitHub API Access Token.
            Get github token from https://github.com/settings/tokens 
            If you don't provide it, you can still use this script, but you will be limited to 60 queries per hour.
    .EXAMPLE
        $branches = Get-GitHubRepositoryBranch -Owner PowerShell -Repository PowerShellForGitHub
#>
function Get-GitHubRepositoryBranch
{
    param
    (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [Alias('Owner')]
        [String] $OwnerName,
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [String] $Repository,
        $GitHubAccessToken = $script:gitHubToken
    )

    $resultToReturn = @()

    $query = "$script:gitHubApiUrl/repos/$OwnerName/$Repository/branches?"

    if (![string]::IsNullOrEmpty($GitHubAccessToken))
    {
        $query += "&access_token=$GitHubAccessToken"
    }    

    do
    {
        try
        {
            $jsonResult = Invoke-WebRequest $query
            $branches = (ConvertFrom-Json -InputObject $jsonResult.content)
        }    
        catch [System.Net.WebException] {
            Write-Error "Failed to execute query with exception: $($_.Exception)`nHTTP status code: $($_.Exception.Response.StatusCode)"
            return $null
        }
        catch {
            Write-Error "Failed to execute query with exception: $($_.Exception)"
            return $null
        }

        foreach($branch in $branches)
        {
            $resultToReturn += $branch
        }
        $query = Get-NextResultPage -JsonResult $jsonResult
    } while ($query -ne $null)

    return $resultToReturn
}

<#
    .SYNOPSIS Function to get next page with results from query to GitHub API

    .PARAM
        JsonResult Result from the query to GitHub API
#>
function Get-NextResultPage
{
    param
    (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        $JsonResult
    )
    
    if($JsonResult.Headers.Link -eq $null)
    {
        return $null
    }

    $nextLinkString = $JsonResult.Headers.Link.Split(',')[0]
    
    # Get url query for the next page
    $query = $nextLinkString.Split(';')[0].replace('<','').replace('>','')
    if ($query -notmatch '&page=1')
    {
        return $query
    }
    else
    {
        return $null
    }
}

<#
    .SYNOPSIS Function which gets the authenticated user

    .PARAM
        GitHubAccessToken GitHub API Access Token.
            Get github token from https://github.com/settings/tokens 
            If you don't provide it, you can still use this script, but you will be limited to 60 queries per hour.
    .EXAMPLE
        $user = Get-GitHubAuthenticatedUser
#>
function Get-GitHubAuthenticatedUser
{
    param
    (
        $GitHubAccessToken = $script:gitHubToken
    )

    $resultToReturn = @()

    $query = "$script:gitHubApiUrl/user?"
            
    if (![string]::IsNullOrEmpty($GitHubAccessToken))
    {
        $query += "&access_token=$GitHubAccessToken"
    }
        
    $jsonResult = Invoke-WebRequest $query
    $user = ConvertFrom-Json -InputObject $jsonResult.content

    return $user
}

<#
    .SYNOPSIS Returns array of unique contributors which were contributing to given set of repositories. Accepts output of Get-GitHubRepositoryContributor

    .EXAMPLE $Contributors = Get-GitHubRepositoryContributor -RepositoryUrl @('https://github.com/PowerShell/DscResources', 'https://github.com/PowerShell/xWebAdministration')
             $uniqueContributors = Get-GitHubRepositoryUniqueContributor -Contributors $contributors
#>
function Get-GitHubRepositoryUniqueContributor
{
    param
    (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [object[]] $Contributors
    )

    $uniqueContributors = @()
    
    Write-Host "Getting unique repository contributors" -ForegroundColor Yellow

    foreach ($contributor in $Contributors)
    {
        if (-not $uniqueContributors.Contains($contributor.author.login))
        {
            $uniqueContributors += $contributor.author.login
        }
    }

    return $uniqueContributors
}

<#
    .SYNOPSIS Obtain repository name from it's url

    .EXAMPLE Get-GitHubRepositoryNameFromUrl -RepositoryUrl "https://github.com/PowerShell/xRobocopy"
#>
function Get-GitHubRepositoryNameFromUrl
{
    param
    (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        $RepositoryUrl
    )

    $repositoryName = Split-Path $RepositoryUrl -Leaf
    return $repositoryName
}

<#
    .SYNOPSIS Obtain repository owner from it's url

    .EXAMPLE Get-GitHubRepositoryOwnerFromUrl -RepositoryUrl "https://github.com/PowerShell/xRobocopy"
#>
function Get-GitHubRepositoryOwnerFromUrl
{
    param
    (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        $RepositoryUrl
    )

    $repositoryOwner = Split-Path $RepositoryUrl -Parent
    $repositoryOwner = Split-Path $repositoryOwner -Leaf
    return $repositoryOwner
}

<#
    .SYNOPSIS Returns array with dates with starts of $NumberOfWeeks previous weeks.
        Dates are sorted in reverse chronological order

    .EXAMPLE Get-WeekDate -NumberOfWeeks 10
#>
function Get-WeekDate
{
    param
    (
        [int] $NumberOfWeeks = 12
    ) 

    $beginningsOfWeeks = @()

    $today = Get-Date
    $midnightToday = Get-Date -Hour 0 -Minute 0 -Second 0 -Millisecond 0
    $startOfWeek = $midnightToday.AddDays(- ($midnightToday.DayOfWeek.value__ - 1))

    if ($NumberOfWeeks -ge 1)
    {
        $beginningsOfWeeks += $startOfWeek
    }

    for ($week = 2; $week -le $NumberOfWeeks; $week++)
    {
        # Get date of previous Monday
        $startOfWeek = $startOfWeek.AddDays(-7)
        $beginningsOfWeeks += $startOfWeek
    }

    return $beginningsOfWeeks
}