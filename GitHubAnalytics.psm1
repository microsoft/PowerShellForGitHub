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
        repositoryUrl Array of repository urls which we want to get issues from
    .PARAM 
        state Whether we want to get open, closed or all issues
    .PARAM
        createdOnOrAfter Filter to only get issues created on or after specific date
    .PARAM
        createdOnOrBefore Filter to only get issues created on or before specific date    
    .PARAM
        closedOnOrAfter Filter to only get issues closed on or after specific date
    .PARAM
        ClosedOnOrBefore Filter to only get issues closed on or before specific date
    .PARAM
        gitHubAccessToken GitHub API Access Token.
            Get github token from https://github.com/settings/tokens 
            If you don't provide it, you can still use this script, but you will be limited to 60 queries per hour.
    .EXAMPLE
        $issues = Get-GitHubIssueForRepository -repositoryUrl @('https://github.com/PowerShell/xPSDesiredStateConfiguration')
    .EXAMPLE
        $issues = Get-GitHubIssueForRepository `
            -repositoryUrl @('https://github.com/PowerShell/xPSDesiredStateConfiguration', "https://github.com/PowerShell/xWindowsUpdate" ) `
            -createdOnOrAfter '2015-04-20'
#>
function Get-GitHubIssueForRepository
{
    param
    (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [String[]] $repositoryUrl,
        [ValidateSet("open", "closed", "all")]
        [String] $state = "open",
        [DateTime] $createdOnOrAfter,
        [DateTime] $createdOnOrBefore,
        [DateTime] $closedOnOrAfter,
        [DateTime] $closedOnOrBefore,
        $gitHubAccessToken = $script:gitHubToken
    )

    $resultToReturn = @()

    $index = 0
    
    foreach ($repository in $repositoryUrl)
    {
        Write-Host "Getting issues for repository $repository" -ForegroundColor Yellow

        $repositoryName = Get-GitHubRepositoryNameFromUrl -repositoryUrl $repository
        $repositoryOwner = Get-GitHubRepositoryOwnerFromUrl -repositoryUrl $repository

        # Create query for issues
        $query = "$script:gitHubApiReposUrl/$repositoryOwner/$repositoryName/issues?state=$state"
            
        if (![string]::IsNullOrEmpty($gitHubAccessToken))
        {
            $query += "&access_token=$gitHubAccessToken"
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

                # Filter according to createdOnOrAfter
                $createdDate = Get-Date -Date $issue.created_at
                if (($createdOnOrAfter -ne $null) -and ($createdDate -lt $createdOnOrAfter))
                {
                    continue  
                }

                # Filter according to createdOnOrBefore
                if (($createdOnOrBefore -ne $null) -and ($createdDate -gt $createdOnOrBefore))
                {
                    continue  
                }

                if ($issue.closed_at -ne $null)
                {
                    # Filter according to closedOnOrAfter
                    $closedDate = Get-Date -Date $issue.closed_at
                    if (($closedOnOrAfter -ne $null) -and ($closedDate -lt $closedOnOrAfter))
                    {
                        continue  
                    }

                    # Filter according to closedOnOrBefore
                    if (($closedOnOrBefore -ne $null) -and ($closedDate -gt $closedOnOrBefore))
                    {
                        continue  
                    }
                }
                else
                {
                    # If issue isn't closed, but we specified filtering on closedOn, skip it
                    if (($closedOnOrAfter -ne $null) -or ($closedOnOrBefore -ne $null))
                    {
                        continue
                    }
                }
                
                Write-Verbose "$index. $($issue.html_url) ## Created: $($issue.created_at) ## Closed: $($issue.closed_at)"
                $index++

                $resultToReturn += $issue
            }
            $query = Get-NextResultPage -jsonResult $jsonResult
        } while ($query -ne $null)
    }

    return $resultToReturn
}

<#
    .SYNOPSIS Function which returns number of issues created/merged in every week in specific repositories
    .PARAM
        repositoryUrl Array of repository urls which we want to get pull requests from
    .PARAM 
        numberOfWeeks How many weeks we want to obtain data for
    .PARAM 
        dataType Whether we want to get information about created or merged issues in specific weeks
    .PARAM
        gitHubAccessToken GitHub API Access Token.
            Get github token from https://github.com/settings/tokens 
            If you don't provide it, you can still use this script, but you will be limited to 60 queries per hour.
    .EXAMPLE
        Get-GitHubWeeklyIssueForRepository -repositoryUrl @('https://github.com/powershell/xpsdesiredstateconfiguration', 'https://github.com/powershell/xactivedirectory') -datatype closed

#>
function Get-GitHubWeeklyIssueForRepository
{
    param
    (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [String[]] $repositoryUrl,
        [int] $numberOfWeeks = 12,
        [Parameter(Mandatory=$true)]
        [ValidateSet("created","closed")]
        [string] $dataType,
        $gitHubAccessToken = $script:gitHubToken
    )

    $weekDates = Get-WeekDate -numberOfWeeks $numberOfWeeks
    $endOfWeek = Get-Date
    $results = @()
    $totalIssues = 0

    foreach ($week in $weekDates)
    {
        Write-Host "Getting issues from week of $week"

        $issues = $null

        if ($dataType -eq "closed")
        {
            $issues = Get-GitHubIssueForRepository `
            -repositoryUrl $repositoryUrl -state 'all' -closedOnOrAfter $week -closedOnOrBefore $endOfWeek    
        }
        elseif ($dataType -eq "created")
        {
            $issues = Get-GitHubIssueForRepository `
            -repositoryUrl $repositoryUrl -state 'all' -createdOnOrAfter $week -createdOnOrBefore $endOfWeek
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
        repositoryUrl Array of repository urls which we want to get issues from
    .PARAM 
        state Whether we want to get information about open issues, closed or both
    .PARAM
        createdOnOrAfter Get information about issues created after specific date
    .PARAM
        closedOnOrAfter Get information about issues closed after specific date
    .PARAM
        gitHubAccessToken GitHub API Access Token.
            Get github token from https://github.com/settings/tokens 
            If you don't provide it, you can still use this script, but you will be limited to 60 queries per hour.
    .EXAMPLE
        Get-GitHubTopIssueRepository -repositoryUrl @('https://github.com/powershell/xsharepoint', 'https://github.com/powershell/xCertificate', 'https://github.com/powershell/xwebadministration') -state open

#>
function Get-GitHubTopIssueRepository
{
    param
    (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [String[]] $repositoryUrl,
        [ValidateSet("open", "closed", "all")]
        [String] $state = "open",
        [DateTime] $createdOnOrAfter,
        [DateTime] $closedOnOrAfter,
        $gitHubAccessToken = $script:gitHubToken
    )
    
    if (($state -eq "open") -and ($closedOnOrAfter -ne $null))
    {
        Throw "closedOnOrAfter cannot be specified if state is open"
    }

    $repositoryIssues = @{}

    foreach ($repository in $repositoryUrl)
    {
        if (($closedOnOrAfter -ne $null) -and ($createdOnOrAfter -ne $null))
        {
            $issues = Get-GitHubIssueForRepository `
            -repositoryUrl $repository `
            -state $state -closedOnOrAfter $closedOnOrAfter -createdOnOrAfter $createdOnOrAfter
        }
        elseif (($closedOnOrAfter -ne $null) -and ($createdOnOrAfter -eq $null))
        {
            $issues = Get-GitHubIssueForRepository `
            -repositoryUrl $repository `
            -state $state -closedOnOrAfter $closedOnOrAfter
        }
        elseif (($closedOnOrAfter -eq $null) -and ($createdOnOrAfter -ne $null))
        {
            $issues = Get-GitHubIssueForRepository `
            -repositoryUrl $repository `
            -state $state -createdOnOrAfter $createdOnOrAfter
        }
        elseif (($closedOnOrAfter -eq $null) -and ($createdOnOrAfter -eq $null))
        {
            $issues = Get-GitHubIssueForRepository `
            -repositoryUrl $repository `
            -state $state
        }

        if (($issues -ne $null) -and ($issues.Count -eq $null))
        {
            $count = 1
        }
        else
        {
            $count = $issues.Count
        }

        $repositoryName = Get-GitHubRepositoryNameFromUrl -repositoryUrl $repository
        $repositoryIssues.Add($repositoryName, $count)
    }

    $repositoryIssues = $repositoryIssues.GetEnumerator() | Sort-Object Value -Descending

    return $repositoryIssues
}

<#
    .SYNOPSIS Function which gets list of pull requests for given repository
    .PARAM
        repositoryUrl Array of repository urls which we want to get pull requests from
    .PARAM 
        state Whether we want to get open, closed or all pull requests
    .PARAM
        createdOnOrAfter Filter to only get pull requests created on or after specific date
    .PARAM
        createdOnOrBefore Filter to only get pull requests created on or before specific date    
    .PARAM
        mergedOnOrAfter Filter to only get issues merged on or after specific date
    .PARAM
        mergedOnOrBefore Filter to only get issues merged on or before specific date
    .PARAM
        gitHubAccessToken GitHub API Access Token.
            Get github token from https://github.com/settings/tokens 
            If you don't provide it, you can still use this script, but you will be limited to 60 queries per hour.
    .EXAMPLE
        $pullRequests = Get-GitHubPullRequestForRepository -repositoryUrl @('https://github.com/PowerShell/xPSDesiredStateConfiguration')
    .EXAMPLE
        $pullRequests = Get-GitHubPullRequestForRepository `
            -repositoryUrl @('https://github.com/PowerShell/xPSDesiredStateConfiguration', 'https://github.com/PowerShell/xWebAdministration') `
            -state closed -mergedOnOrAfter 2015-02-13 -mergedOnOrBefore 2015-06-17

#>
function Get-GitHubPullRequestForRepository
{
    param 
    (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [String[]] $repositoryUrl,
        [ValidateSet("open", "closed", "all")]
        [String] $state = "open",
        [DateTime] $createdOnOrAfter,
        [DateTime] $createdOnOrBefore,
        [DateTime] $mergedOnOrAfter,
        [DateTime] $mergedOnOrBefore,
        $gitHubAccessToken = $script:gitHubToken
    )

    $resultToReturn = @()

    $index = 0
    
    foreach ($repository in $repositoryUrl)
    {
        Write-Host "Getting pull requests for repository $repository" -ForegroundColor Yellow

        $repositoryName = Get-GitHubRepositoryNameFromUrl -repositoryUrl $repository
        $repositoryOwner = Get-GitHubRepositoryOwnerFromUrl -repositoryUrl $repository

        # Create query for pull requests
        $query = "$script:gitHubApiReposUrl/$repositoryOwner/$repositoryName/pulls?state=$state"
            
        if (![string]::IsNullOrEmpty($gitHubAccessToken))
        {
            $query += "&access_token=$gitHubAccessToken"
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
                # Filter according to createdOnOrAfter
                $createdDate = Get-Date -Date $pullRequest.created_at
                if (($createdOnOrAfter -ne $null) -and ($createdDate -lt $createdOnOrAfter))
                {
                    continue  
                }

                # Filter according to createdOnOrBefore
                if (($createdOnOrBefore -ne $null) -and ($createdDate -gt $createdOnOrBefore))
                {
                    continue  
                }

                if ($pullRequest.merged_at -ne $null)
                {
                    # Filter according to mergedOnOrAfter
                    $mergedDate = Get-Date -Date $pullRequest.merged_at
                    if (($mergedOnOrAfter -ne $null) -and ($mergedDate -lt $mergedOnOrAfter))
                    {
                        continue
                    }

                    # Filter according to mergedOnOrBefore
                    if (($mergedOnOrBefore -ne $null) -and ($mergedDate -gt $mergedOnOrBefore))
                    {
                        continue  
                    }
                }
                else
                {
                    # If issue isn't merged, but we specified filtering on mergedOn, skip it
                    if (($mergedOnOrAfter -ne $null) -or ($mergedOnOrBefore -ne $null))
                    {
                        continue
                    }
                }
                
                Write-Verbose "$index. $($pullRequest.html_url) ## Created: $($pullRequest.created_at) ## Merged: $($pullRequest.merged_at)"
                $index++

                $resultToReturn += $pullRequest
            }
            $query = Get-NextResultPage -jsonResult $jsonResult
        } while ($query -ne $null) 
    }

    return $resultToReturn
}

<#
    .SYNOPSIS Function which returns number of pull requests created/merged in every week in specific repositories
    .PARAM
        repositoryUrl Array of repository urls which we want to get pull requests from
    .PARAM 
        numberOfWeeks How many weeks we want to obtain data for
    .PARAM 
        dataType Whether we want to get information about created or merged pull requests in specific weeks
    .PARAM
        gitHubAccessToken GitHub API Access Token.
            Get github token from https://github.com/settings/tokens 
            If you don't provide it, you can still use this script, but you will be limited to 60 queries per hour.
    .EXAMPLE
        Get-GitHubWeeklyPullRequestForRepository -repositoryUrl @('https://github.com/powershell/xpsdesiredstateconfiguration', 'https://github.com/powershell/xwebadministration') -datatype merged

#>
function Get-GitHubWeeklyPullRequestForRepository
{
    param
    (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [String[]] $repositoryUrl,
        [int] $numberOfWeeks = 12,
        [Parameter(Mandatory=$true)]
        [ValidateSet("created","merged")]
        [string] $dataType,
        $gitHubAccessToken = $script:gitHubToken
    )
    
    $weekDates = Get-WeekDate -numberOfWeeks $numberOfWeeks
    $endOfWeek = Get-Date
    $results = @()
    $totalPullRequests = 0

    foreach ($week in $weekDates)
    {
        Write-Host "Getting Pull Requests from week of $week"

        $pullRequests = $null

        if ($dataType -eq "merged")
        {
            $pullRequests = Get-GitHubPullRequestForRepository `
            -repositoryUrl $repositoryUrl `
            -state 'all' -mergedOnOrAfter $week -mergedOnOrBefore $endOfWeek
        }
        elseif ($dataType -eq "created")
        {
            $pullRequests = Get-GitHubPullRequestForRepository `
            -repositoryUrl $repositoryUrl `
            -state 'all' -createdOnOrAfter $week -createdOnOrBefore $endOfWeek
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
        repositoryUrl Array of repository urls which we want to get pull requests from
    .PARAM 
        state Whether we want to get information about open pull requests, closed or both
    .PARAM
        createdOnOrAfter Get information about pull requests created after specific date
    .PARAM
        mergedOnOrAfter Get information about pull requests merged after specific date
    .PARAM
        gitHubAccessToken GitHub API Access Token.
            Get github token from https://github.com/settings/tokens 
            If you don't provide it, you can still use this script, but you will be limited to 60 queries per hour.
    .EXAMPLE
        Get-GitHubTopPullRequestRepository -repositoryUrl @('https://github.com/powershell/xsharepoint', 'https://github.com/powershell/xwebadministration') -state closed -mergedOnOrAfter 2015-04-20

#>
function Get-GitHubTopPullRequestRepository
{
    param
    (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [String[]] $repositoryUrl,
        [ValidateSet("open", "closed", "all")]
        [String] $state = "open",
        [DateTime] $createdOnOrAfter,
        [DateTime] $mergedOnOrAfter,
        $gitHubAccessToken = $script:gitHubToken
    )
    
    if (($state -eq "open") -and ($mergedOnOrAfter -ne $null))
    {
        Throw "mergedOnOrAfter cannot be specified if state is open"
    }

    $repositoryPullRequests = @{}

    foreach ($repository in $repositoryUrl)
    {
        if (($mergedOnOrAfter -ne $null) -and ($createdOnOrAfter -ne $null))
        {
            $pullRequests = Get-GitHubPullRequestForRepository `
            -repositoryUrl $repository `
            -state $state -mergedOnOrAfter $mergedOnOrAfter -createdOnOrAfter $createdOnOrAfter
        }
        elseif (($mergedOnOrAfter -ne $null) -and ($createdOnOrAfter -eq $null))
        {
            $pullRequests = Get-GitHubPullRequestForRepository `
            -repositoryUrl $repository `
            -state $state -mergedOnOrAfter $mergedOnOrAfter
        }
        elseif (($mergedOnOrAfter -eq $null) -and ($createdOnOrAfter -ne $null))
        {
            $pullRequests = Get-GitHubPullRequestForRepository `
            -repositoryUrl $repository `
            -state $state -createdOnOrAfter $createdOnOrAfter
        }
        elseif (($mergedOnOrAfter -eq $null) -and ($createdOnOrAfter -eq $null))
        {
            $pullRequests = Get-GitHubPullRequestForRepository `
            -repositoryUrl $repository `
            -state $state
        }

        if (($pullRequests -ne $null) -and ($pullRequests.Count -eq $null))
        {
            $count = 1
        }
        else
        {
            $count = $pullRequests.Count
        }

        $repositoryName = Get-GitHubRepositoryNameFromUrl -repositoryUrl $repository
        $repositoryPullRequests.Add($repositoryName, $count)
    }

    $repositoryPullRequests = $repositoryPullRequests.GetEnumerator() | Sort-Object Value -Descending

    return $repositoryPullRequests
}

<#
    .SYNOPSIS Obtain repository collaborators

    .EXAMPLE $collaborators = Get-GitHubRepositoryCollaborator -repositoryUrl @('https://github.com/PowerShell/DscResources')
#>
function Get-GitHubRepositoryCollaborator
{
    param 
    (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [String[]] $repositoryUrl,
        $gitHubAccessToken = $script:gitHubToken
    )

    $resultToReturn = @()
    
    foreach ($repository in $repositoryUrl)
    {
        $index = 0
        Write-Host "Getting repository collaborators for repository $repository" -ForegroundColor Yellow

        $repositoryName = Get-GitHubRepositoryNameFromUrl -repositoryUrl $repository
        $repositoryOwner = Get-GitHubRepositoryOwnerFromUrl -repositoryUrl $repository

        $query = "$script:gitHubApiReposUrl/$repositoryOwner/$repositoryName/collaborators"
            
        if (![string]::IsNullOrEmpty($gitHubAccessToken))
        {
            $query += "?access_token=$gitHubAccessToken"
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
            $query = Get-NextResultPage -jsonResult $jsonResult
        } while ($query -ne $null)
    }
    return $resultToReturn
}

<#
    .SYNOPSIS Obtain repository contributors

    .EXAMPLE $contributors = Get-GitHubRepositoryContributor -repositoryUrl @('https://github.com/PowerShell/DscResources', 'https://github.com/PowerShell/xWebAdministration')
#>
function Get-GitHubRepositoryContributor
{
    param 
    (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [String[]] $repositoryUrl,
        $gitHubAccessToken = $script:gitHubToken
    )

    $resultToReturn = @()
    
    foreach ($repository in $repositoryUrl)
    {
        $index = 0
        Write-Host "Getting repository contributors for repository $repository" -ForegroundColor Yellow

        $repositoryName = Get-GitHubRepositoryNameFromUrl -repositoryUrl $repository
        $repositoryOwner = Get-GitHubRepositoryOwnerFromUrl -repositoryUrl $repository

        $query = "$script:gitHubApiReposUrl/$repositoryOwner/$repositoryName/stats/contributors"
            
        if (![string]::IsNullOrEmpty($gitHubAccessToken))
        {
            $query += "?access_token=$gitHubAccessToken"
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
            $query = Get-NextResultPage -jsonResult $jsonResult
        } while ($query -ne $null)


    }

    return $resultToReturn
}

<#
    .SYNOPSIS Obtain organization members list
    .PARAM 
        organizationName name of the organization
    .PARAM
        gitHubAccessToken GitHub API Access Token.
            Get github token from https://github.com/settings/tokens 
            If you don't provide it, you can still use this script, but you will be limited to 60 queries per hour.

    .EXAMPLE $members = Get-GitHubOrganizationMember -organizationName PowerShell
#>
function Get-GitHubOrganizationMember
{
    param 
    (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [String] $organizationName,
        $gitHubAccessToken = $script:gitHubToken
    )
    $resultToReturn = @()
    $index = 0

    $query = "$script:gitHubApiOrgsUrl/$organizationName/members"

    if (![string]::IsNullOrEmpty($gitHubAccessToken))
    {
        $query += "?access_token=$gitHubAccessToken"
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
        $query = Get-NextResultPage -jsonResult $jsonResult
    } while ($query -ne $null)

    return $resultToReturn
}

<#
    .SYNOPSIS Obtain organization teams list
    .PARAM 
        organizationName name of the organization
    .PARAM
        gitHubAccessToken GitHub API Access Token.
            Get github token from https://github.com/settings/tokens 
            If you don't provide it, you can still use this script, but you will be limited to 60 queries per hour.
    .EXAMPLE Get-GitHubTeam -organizationName PowerShell
#>
function Get-GitHubTeam
{
    param 
    (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [String] $organizationName,
        $gitHubAccessToken = $script:gitHubToken
    )
    $resultToReturn = @()
    $index = 0

    $query = "$script:gitHubApiUrl/orgs/$organizationName/teams"
        
    if (![string]::IsNullOrEmpty($gitHubAccessToken))
    {
        $query += "?access_token=$gitHubAccessToken"
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
        $query = Get-NextResultPage -jsonResult $jsonResult
    } while ($query -ne $null)

    return $resultToReturn
}

<#
    .SYNOPSIS Obtain organization team members list
    .PARAM 
        organizationName name of the organization
    .PARAM 
        teamName name of the team in the organization
    .PARAM
        gitHubAccessToken GitHub API Access Token.
            Get github token from https://github.com/settings/tokens 
            If you don't provide it, you can still use this script, but you will be limited to 60 queries per hour.

    .EXAMPLE $members = Get-GitHubTeamMember -organizationName PowerShell -teamName Everybody
#>
function Get-GitHubTeamMember
{
    param 
    (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [String] $organizationName,
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [String] $teamName,
        $gitHubAccessToken = $script:gitHubToken
    )
    $resultToReturn = @()
    $index = 0

    $teams = Get-GitHubTeam -organizationName $organizationName
    $team = $teams | ? {$_.name -eq $teamName}
    if ($team) {
        Write-Host "Found team $teamName with id $($team.id)"
    } else {
        Write-Host "Cannot find team $teamName"
        return
    }

    $query = "$script:gitHubApiUrl/teams/$($team.id)/members"
        
    if (![string]::IsNullOrEmpty($gitHubAccessToken))
    {
        $query += "?access_token=$gitHubAccessToken"
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
        $query = Get-NextResultPage -jsonResult $jsonResult
    } while ($query -ne $null)

    return $resultToReturn
}

<#
    .SYNOPSIS Function which gets list of repositories for a given organization
    .PARAM
        organization The name of the organization
    .PARAM
        gitHubAccessToken GitHub API Access Token.
            Get github token from https://github.com/settings/tokens 
            If you don't provide it, you can still use this script, but you will be limited to 60 queries per hour.
    .EXAMPLE
        $repositories = Get-GitHubOrganizationRepository -organization 'PowerShell'
#>
function Get-GitHubOrganizationRepository
{
    param
    (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [String] $organization,
        $gitHubAccessToken = $script:gitHubToken
    )

    $resultToReturn = @()

    $query = "$script:gitHubApiUrl/orgs/$organization/repos?"
            
    if (![string]::IsNullOrEmpty($gitHubAccessToken))
    {
        $query += "&access_token=$gitHubAccessToken"
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
        $query = Get-NextResultPage -jsonResult $jsonResult
    } while ($query -ne $null)

    return $resultToReturn
}

<#
    .SYNOPSIS Function which gets a list of branches for a given repository
    .PARAM
        owner The name of the repository owner
    .PARAM
        repository The name of the repository
    .PARAM
        gitHubAccessToken GitHub API Access Token.
            Get github token from https://github.com/settings/tokens 
            If you don't provide it, you can still use this script, but you will be limited to 60 queries per hour.
    .EXAMPLE
        $branches = Get-GitHubRepositoryBranch -owner PowerShell -repository PowerShellForGitHub
#>
function Get-GitHubRepositoryBranch
{
    param
    (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [String] $owner,
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [String] $repository,
        $gitHubAccessToken = $script:gitHubToken
    )

    $resultToReturn = @()

    $query = "$script:gitHubApiUrl/repos/$owner/$repository/branches?"

    if (![string]::IsNullOrEmpty($gitHubAccessToken))
    {
        $query += "&access_token=$gitHubAccessToken"
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
        $query = Get-NextResultPage -jsonResult $jsonResult
    } while ($query -ne $null)

    return $resultToReturn
}

<#
    .SYNOPSIS Function to get next page with results from query to GitHub API

    .PARAM
        jsonResult Result from the query to GitHub API
#>
function Get-NextResultPage
{
    param
    (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        $jsonResult
    )
    
    if($jsonResult.Headers.Link -eq $null)
    {
        return $null
    }

    $nextLinkString = $jsonResult.Headers.Link.Split(',').Where{ $_ -match 'rel="next"' }
    if( $nextLinkString.Count -eq 0){
        return $null
    }
    
    # Get url query for the next page
    $query = $nextLinkString.Split(';')[0].replace('<','').replace('>','')
    if ($query -notmatch '&page=1>')
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
        gitHubAccessToken GitHub API Access Token.
            Get github token from https://github.com/settings/tokens 
            If you don't provide it, you can still use this script, but you will be limited to 60 queries per hour.
    .EXAMPLE
        $user = Get-GitHubAuthenticatedUser
#>
function Get-GitHubAuthenticatedUser
{
    param
    (
        $gitHubAccessToken = $script:gitHubToken
    )

    $resultToReturn = @()

    $query = "$script:gitHubApiUrl/user?"
            
    if (![string]::IsNullOrEmpty($gitHubAccessToken))
    {
        $query += "&access_token=$gitHubAccessToken"
    }
        
    $jsonResult = Invoke-WebRequest $query
    $user = ConvertFrom-Json -InputObject $jsonResult.content

    return $user
}

<#
    .SYNOPSIS Returns array of unique contributors which were contributing to given set of repositories. Accepts output of Get-GitHubRepositoryContributor

    .EXAMPLE $contributors = Get-GitHubRepositoryContributor -repositoryUrl @('https://github.com/PowerShell/DscResources', 'https://github.com/PowerShell/xWebAdministration')
             $uniqueContributors = Get-GitHubRepositoryUniqueContributor -contributors $contributors
#>
function Get-GitHubRepositoryUniqueContributor
{
    param
    (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [object[]] $contributors
    )

    $uniqueContributors = @()
    
    Write-Host "Getting unique repository contributors" -ForegroundColor Yellow

    foreach ($contributor in $contributors)
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

    .EXAMPLE Get-GitHubRepositoryNameFromUrl -repositoryUrl "https://github.com/PowerShell/xRobocopy"
#>
function Get-GitHubRepositoryNameFromUrl
{
    param
    (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        $repositoryUrl
    )

    $repositoryName = Split-Path $repositoryUrl -Leaf
    return $repositoryName
}

<#
    .SYNOPSIS Obtain repository owner from it's url

    .EXAMPLE Get-GitHubRepositoryOwnerFromUrl -repositoryUrl "https://github.com/PowerShell/xRobocopy"
#>
function Get-GitHubRepositoryOwnerFromUrl
{
    param
    (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        $repositoryUrl
    )

    $repositoryOwner = Split-Path $repositoryUrl -Parent
    $repositoryOwner = Split-Path $repositoryOwner -Leaf
    return $repositoryOwner
}

<#
    .SYNOPSIS Returns array with dates with starts of $numberOfWeeks previous weeks.
        Dates are sorted in reverse chronological order

    .EXAMPLE Get-WeekDate -numberOfWeeks 10
#>
function Get-WeekDate
{
    param
    (
        [int] $numberOfWeeks = 12
    ) 

    $beginningsOfWeeks = @()

    $today = Get-Date
    $midnightToday = Get-Date -Hour 0 -Minute 0 -Second 0 -Millisecond 0
    $startOfWeek = $midnightToday.AddDays(- ($midnightToday.DayOfWeek.value__ - 1))

    if ($numberOfWeeks -ge 1)
    {
        $beginningsOfWeeks += $startOfWeek
    }

    for ($week = 2; $week -le $numberOfWeeks; $week++)
    {
        # Get date of previous Monday
        $startOfWeek = $startOfWeek.AddDays(-7)
        $beginningsOfWeeks += $startOfWeek
    }

    return $beginningsOfWeeks
}
