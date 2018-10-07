<#
    .SYNOPSIS PowerShell module for GitHub labels
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

<#
    .SYNOPSIS Function to get single or all labels of given repository
    .PARAM
        repositoryName Name of the repository
    .PARAM 
        ownerName Owner of the repository
    .PARAM
        labelName Name of the label to get. Function will return all labels for given repository if labelName is not specified.
    .PARAM
        gitHubAccessToken GitHub API Access Token.
            Get github token from https://github.com/settings/tokens 
            If you don't provide it, you can still use this script, but you will be limited to 60 queries per hour.
    .EXAMPLE
        Get-GitHubLabel -repositoryName DesiredStateConfiguration -ownerName Powershell -labelName TestLabel
        Get-GitHubLabel -repositoryName DesiredStateConfiguration -ownerName Powershell
#>
function Get-GitHubLabel
{
    param(
        [Parameter(Mandatory=$true)]
        [string]$repositoryName,
        [Parameter(Mandatory=$true)]
        [string]$ownerName,
        [string]$labelName, 
        [string]$gitHubAccessToken = $script:gitHubToken
        )
        
        $resultToReturn = @()
        $index = 0
        $headers = @{"Authorization"="token $gitHubAccessToken"}
        
        if ($labelName -eq "")
        {
            $query = "$script:gitHubApiReposUrl/{0}/{1}/labels" -f $ownerName, $repositoryName    
            Write-Host "Getting all labels for repository $repositoryName"

            do 
            {
                try
                {
                    # Force TLS 1.2    
                    [Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12
                    $jsonResult = Invoke-WebRequest $query -Method Get -Headers $headers
                    $labels = ConvertFrom-Json -InputObject $jsonResult.content
                }    
                catch [System.Net.WebException] {
                    Write-Error "Failed to execute query with exception: $($_.Exception)`nHTTP status code: $($_.Exception.Response.StatusCode)"
                    return $null
                }
                catch {
                    Write-Error "Failed to execute query with exception: $($_.Exception)"
                    return $null
                }

                foreach ($label in $labels)
                {          
                    Write-Verbose "$index. $($label.name)"
                    $index++
                    $resultToReturn += $label
                }
                $query = Get-NextResultPage -jsonResult $jsonResult
            } while ($query -ne $null)
        }
        else 
        {
            $query = "$script:gitHubApiReposUrl/{0}/{1}/labels/{2}" -f $ownerName, $repositoryName, $labelName
            Write-Host "Getting label $labelName for repository $repositoryName"

            try
            {
                # Force TLS 1.2    
                [Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12
                $jsonResult = Invoke-WebRequest $query -Method Get -Headers $headers
                $label = ConvertFrom-Json -InputObject $jsonResult.content
            }    
            catch [System.Net.WebException] {
                Write-Error "Failed to execute query with exception: $($_.Exception)`nHTTP status code: $($_.Exception.Response.StatusCode)"
                return $null
            }
            catch {
                Write-Error "Failed to execute query with exception: $($_.Exception)"
                return $null
            }
  
            Write-Verbose "$index. $($label.name)"
            $resultToReturn = $label
        }
        
        return $resultToReturn
}

<#
    .SYNOPSIS Function to create label in given repository
    .PARAM
        repositoryName Name of the repository
    .PARAM 
        ownerName Owner of the repository
    .PARAM
        labelName Name of the label to create
    .PARAM
        gitHubAccessToken GitHub API Access Token.
            Get github token from https://github.com/settings/tokens 
            If you don't provide it, you can still use this script, but you will be limited to 60 queries per hour.
    .EXAMPLE
        New-GitHubLabel -repositoryName DesiredStateConfiguration -ownerName PowerShell -labelName TestLabel -labelColor BBBBBB
#>
function New-GitHubLabel 
{
    param(
        [Parameter(Mandatory=$true)]
        [string]$repositoryName,
        [Parameter(Mandatory=$true)]
        [string]$ownerName,
        [Parameter(Mandatory=$true)]
        [string]$labelName, 
        [string]$labelColor = "EEEEEE",
        [string]$gitHubAccessToken = $script:gitHubToken
        )
        
        $headers = @{"Authorization"="token $gitHubAccessToken"}
        $hashTable = @{"name"=$labelName; "color"=$labelColor}
        $data = $hashTable | ConvertTo-Json
        $url = "$script:gitHubApiReposUrl/{0}/{1}/labels" -f $ownerName, $repositoryName
        
        Write-Host "Creating Label:" $labelName

        # Force TLS 1.2    
        [Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12
        $result = Invoke-WebRequest $url -Method Post -Body $data -Headers $headers
        
        if ($result.StatusCode -eq 201) 
        {
            Write-Host $labelName "was created"
        } 
        else 
        {
            Write-Error $labelName "was not created. Result: $result"
        }      
}

<#
    .SYNOPSIS Function to remove label from given repository
    .PARAM
        repositoryName Name of the repository
    .PARAM 
        ownerName Owner of the repository
    .PARAM
        labelName Name of the label to delete
    .PARAM
        gitHubAccessToken GitHub API Access Token.
            Get github token from https://github.com/settings/tokens 
            If you don't provide it, you can still use this script, but you will be limited to 60 queries per hour.
    .EXAMPLE
        Remove-GitHubLabel -repositoryName desiredstateconfiguration -ownerName powershell -labelName TestLabel
#>
function Remove-GitHubLabel 
{
    param(
        [Parameter(Mandatory=$true)]
        [string]$repositoryName,
        [Parameter(Mandatory=$true)]
        [string]$ownerName,
        [Parameter(Mandatory=$true)]
        [string]$labelName,
        [string]$gitHubAccessToken = $script:gitHubToken
        )           
            
        $headers = @{"Authorization"="token $gitHubAccessToken"}
        $url = "$script:gitHubApiReposUrl/{0}/{1}/labels/{2}" -f $ownerName, $repositoryName, $labelName
        
        Write-Host "Deleting Label:" $labelName

        # Force TLS 1.2    
        [Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12
        $result = Invoke-WebRequest $url -Method Delete -Headers $headers
        
        if ($result.StatusCode -eq 204) 
        {
            Write-Host $labelName "was deleted"
        } 
        else 
        {
            Write-Error $labelName "was not deleted. Result: $result"
        }
}

<#
    .SYNOPSIS Function to update label in given repository
    .PARAM
        repositoryName Name of the repository
    .PARAM 
        ownerName Owner of the repository
    .PARAM
        labelName Name of the label to update
    .PARAM
        newLabelName New name of the label
    .PARAM
        labelColor New color of the label
    .PARAM
        gitHubAccessToken GitHub API Access Token.
            Get github token from https://github.com/settings/tokens 
            If you don't provide it, you can still use this script, but you will be limited to 60 queries per hour.
    .EXAMPLE
        Update-GitHubLabel -repositoryName DesiredStateConfiguration -ownerName Powershell -labelName TestLabel -newLabelName NewTestLabel -labelColor BBBB00
#>
function Update-GitHubLabel
{
    param(
        [Parameter(Mandatory=$true)]
        [string]$repositoryName,
        [Parameter(Mandatory=$true)]
        [string]$ownerName,
        [Parameter(Mandatory=$true)]
        [string]$labelName,
        [Parameter(Mandatory=$true)]
        [string]$newLabelName,
        [string]$labelColor = "EEEEEE",
        [string]$gitHubAccessToken = $script:gitHubToken
        )           
            
        $headers = @{"Authorization"="token $gitHubAccessToken"}
        $hashTable = @{"name"=$newLabelName; "color"=$labelColor}
        $data = $hashTable | ConvertTo-Json
        $url = "$script:gitHubApiReposUrl/{0}/{1}/labels/{2}" -f $ownerName, $repositoryName, $labelName
        
        Write-Host "Updating label '$labelName' to name '$newLabelName' and color '$labelColor'"

        # Force TLS 1.2    
        [Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12
        $result = Invoke-WebRequest $url -Method Patch -Body $data -Headers $headers

        if ($result.StatusCode -eq 200) 
        {
            Write-Host $labelName "was updated"
        } 
        else
        {
            Write-Error $labelName "was not updated. Result: $result"
        }
}

<#
    .SYNOPSIS Function to create labels for given repository.
        It get all labels from repo, remove the ones which aren't on our approved label list, update the ones which already exist to desired color and add the ones which weren't there before.
    .PARAM
        repositoryName Name of the repository
    .PARAM 
        ownerName Owner of the repository
    .PARAM
        gitHubAccessToken GitHub API Access Token.
            Get github token from https://github.com/settings/tokens 
            If you don't provide it, you can still use this script, but you will be limited to 60 queries per hour.
    .EXAMPLE
        New-GitHubLabels -repositoryName DesiredStateConfiguration -ownerName Powershell
#>
function New-GitHubLabels
{
    param(
          [Parameter(Mandatory=$true)]
          [string]$repositoryName,
          [Parameter(Mandatory=$true)]
          [string]$ownerName,
          [string]$gitHubAccessToken = $script:gitHubToken
          )

$labelJson = @"
[
    {
        "name":  "pri:lowest",
        "color":  "4285F4"
    },
    {
        "name":  "pri:low",
        "color":  "4285F4"
    },
    {
        "name":  "pri:medium",
        "color":  "4285F4"
    },
    {
        "name":  "pri:high",
        "color":  "4285F4"
    },
    {
        "name":  "pri:highest",
        "color":  "4285F4"
    },
    {
        "name":  "bug",
        "color":  "fc2929"
    },
    {
        "name":  "duplicate",
        "color":  "cccccc"
    },
    {
        "name":  "enhancement",
        "color":  "121459"
    },
    {
        "name":  "up for grabs",
        "color":  "159818"
    },
    {
        "name":  "question",
        "color":  "cc317c"
    },
    {
        "name":  "discussion",
        "color":  "fe9a3d"
    },
    {
        "name":  "wontfix",
        "color":  "dcb39c"
    },
    {
        "name":  "in progress",
        "color":  "f0d218"
    },
    {
        "name":  "ready",
        "color":  "145912"
    }
]

"@

    $labelList = $labelJson | ConvertFrom-Json
    $labelListNames = $labelList.name
    $existingLabels = Get-GitHubLabel -repositoryName $repositoryName -ownerName $ownerName -gitHubAccessToken $gitHubAccessToken
    $existingLabelsNames = $existingLabels.name
    
    
    foreach ($label in $labelList)
    {
        if ($label.name -notin $existingLabelsNames)
        {
            # Create label if it doesn't exist
            New-GitHubLabel -repositoryName $repositoryName -ownerName $ownerName -labelName $label.name -labelColor $label.color -gitHubAccessToken $gitHubAccessToken
        }
        else 
        {
            # Update label's color if it already exists
            Update-GitHubLabel -repositoryName $repositoryName -ownerName $ownerName -labelName $label.name -newLabelName $label.name -labelColor $label.color -gitHubAccessToken $gitHubAccessToken
        }
    }
    
    foreach ($label in $existingLabelsNames)
    {
        if($label -notin $labelListNames)
        {
            # Remove label if it exists but is not on desired label list
            Remove-GitHubLabel -repositoryName $repositoryName -ownerName $ownerName -labelName $label -gitHubAccessToken $gitHubAccessToken
        }
    }
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

    $nextLinkString = $jsonResult.Headers.Link.Split(',')[0]
    
    # Get url query for the next page
    $query = $nextLinkString.Split(';')[0].replace('<','').replace('>','')
    if ($query -notmatch 'page=1')
    {
        
        return $query
    }
    else
    {
        return $null
    }
}
