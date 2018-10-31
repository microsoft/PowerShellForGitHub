# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

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
        RepositoryName Name of the repository
    .PARAM 
        OwnerName Owner of the repository
    .PARAM
        LabelName Name of the label to get. Function will return all labels for given repository if LabelName is not specified.
    .PARAM
        GitHubAccessToken GitHub API Access Token.
            Get github token from https://github.com/settings/tokens 
            If you don't provide it, you can still use this script, but you will be limited to 60 queries per hour.
    .EXAMPLE
        Get-GitHubLabel -RepositoryName DesiredStateConfiguration -OwnerName Powershell -LabelName TestLabel
        Get-GitHubLabel -RepositoryName DesiredStateConfiguration -OwnerName Powershell
#>
function Get-GitHubLabel
{
    param(
        [Parameter(Mandatory=$true)]
        [string]$RepositoryName,
        [Parameter(Mandatory=$true)]
        [string]$OwnerName,
        [string]$LabelName, 
        [string]$GitHubAccessToken = $script:gitHubToken
        )
        
        $resultToReturn = @()
        $index = 0
        $headers = @{"Authorization"="token $GitHubAccessToken"}
        
        if ($LabelName -eq "")
        {
            $query = "$script:gitHubApiReposUrl/{0}/{1}/labels" -f $OwnerName, $RepositoryName    
            Write-Host "Getting all labels for repository $RepositoryName"

            do 
            {
                try
                {
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
                $query = Get-NextResultPage -JsonResult $jsonResult
            } while ($query -ne $null)
        }
        else 
        {
            $query = "$script:gitHubApiReposUrl/{0}/{1}/labels/{2}" -f $OwnerName, $RepositoryName, $LabelName
            Write-Host "Getting label $LabelName for repository $RepositoryName"

            try
            {
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
        RepositoryName Name of the repository
    .PARAM 
        OwnerName Owner of the repository
    .PARAM
        LabelName Name of the label to create
    .PARAM
        LabelColor New color of the label
    .PARAM
        GitHubAccessToken GitHub API Access Token.
            Get github token from https://github.com/settings/tokens 
            If you don't provide it, you can still use this script, but you will be limited to 60 queries per hour.
    .EXAMPLE
        New-GitHubLabel -RepositoryName DesiredStateConfiguration -OwnerName PowerShell -LabelName TestLabel -LabelColor BBBBBB
#>
function New-GitHubLabel 
{
    param(
        [Parameter(Mandatory=$true)]
        [string]$RepositoryName,
        [Parameter(Mandatory=$true)]
        [string]$OwnerName,
        [Parameter(Mandatory=$true)]
        [string]$LabelName, 
        [string]$LabelColor = "EEEEEE",
        [string]$GitHubAccessToken = $script:gitHubToken
        )
        
        $headers = @{"Authorization"="token $GitHubAccessToken"}
        $hashTable = @{"name"=$LabelName; "color"=$LabelColor}
        $data = $hashTable | ConvertTo-Json
        $url = "$script:gitHubApiReposUrl/{0}/{1}/labels" -f $OwnerName, $RepositoryName
        
        Write-Host "Creating Label:" $LabelName
        $result = Invoke-WebRequest $url -Method Post -Body $data -Headers $headers
        
        if ($result.StatusCode -eq 201) 
        {
            Write-Host $LabelName "was created"
        } 
        else 
        {
            Write-Error $LabelName "was not created. Result: $result"
        }      
}

<#
    .SYNOPSIS Function to remove label from given repository
    .PARAM
        RepositoryName Name of the repository
    .PARAM 
        OwnerName Owner of the repository
    .PARAM
        LabelName Name of the label to delete
    .PARAM
        GitHubAccessToken GitHub API Access Token.
            Get github token from https://github.com/settings/tokens 
            If you don't provide it, you can still use this script, but you will be limited to 60 queries per hour.
    .EXAMPLE
        Remove-GitHubLabel -RepositoryName desiredstateconfiguration -OwnerName powershell -LabelName TestLabel
#>
function Remove-GitHubLabel 
{
    param(
        [Parameter(Mandatory=$true)]
        [string]$RepositoryName,
        [Parameter(Mandatory=$true)]
        [string]$OwnerName,
        [Parameter(Mandatory=$true)]
        [string]$LabelName,
        [string]$GitHubAccessToken = $script:gitHubToken
        )           
            
        $headers = @{"Authorization"="token $GitHubAccessToken"}
        $url = "$script:gitHubApiReposUrl/{0}/{1}/labels/{2}" -f $OwnerName, $RepositoryName, $LabelName
        
        Write-Host "Deleting Label:" $LabelName
        $result = Invoke-WebRequest $url -Method Delete -Headers $headers
        
        if ($result.StatusCode -eq 204) 
        {
            Write-Host $LabelName "was deleted"
        } 
        else 
        {
            Write-Error $LabelName "was not deleted. Result: $result"
        }
}

<#
    .SYNOPSIS Function to update label in given repository
    .PARAM
        RepositoryName Name of the repository
    .PARAM 
        OwnerName Owner of the repository
    .PARAM
        LabelName Name of the label to update
    .PARAM
        NewLabelName New name of the label
    .PARAM
        LabelColor New color of the label
    .PARAM
        GitHubAccessToken GitHub API Access Token.
            Get github token from https://github.com/settings/tokens 
            If you don't provide it, you can still use this script, but you will be limited to 60 queries per hour.
    .EXAMPLE
        Update-GitHubLabel -RepositoryName DesiredStateConfiguration -OwnerName Powershell -LabelName TestLabel -NewLabelName NewTestLabel -LabelColor BBBB00
#>
function Update-GitHubLabel
{
    param(
        [Parameter(Mandatory=$true)]
        [string]$RepositoryName,
        [Parameter(Mandatory=$true)]
        [string]$OwnerName,
        [Parameter(Mandatory=$true)]
        [string]$LabelName,
        [Parameter(Mandatory=$true)]
        [string]$NewLabelName,
        [string]$LabelColor = "EEEEEE",
        [string]$GitHubAccessToken = $script:gitHubToken
        )           
            
        $headers = @{"Authorization"="token $GitHubAccessToken"}
        $hashTable = @{"name"=$NewLabelName; "color"=$LabelColor}
        $data = $hashTable | ConvertTo-Json
        $url = "$script:gitHubApiReposUrl/{0}/{1}/labels/{2}" -f $OwnerName, $RepositoryName, $LabelName
        
        Write-Host "Updating label '$LabelName' to name '$NewLabelName' and color '$LabelColor'"
        $result = Invoke-WebRequest $url -Method Patch -Body $data -Headers $headers

        if ($result.StatusCode -eq 200) 
        {
            Write-Host $LabelName "was updated"
        } 
        else
        {
            Write-Error $LabelName "was not updated. Result: $result"
        }
}

<#
    .SYNOPSIS Function to create labels for given repository.
        It get all labels from repo, remove the ones which aren't on our approved label list, update the ones which already exist to desired color and add the ones which weren't there before.
    .PARAM
        RepositoryName Name of the repository
    .PARAM 
        OwnerName Owner of the repository
    .PARAM
        GitHubAccessToken GitHub API Access Token.
            Get github token from https://github.com/settings/tokens 
            If you don't provide it, you can still use this script, but you will be limited to 60 queries per hour.
    .EXAMPLE
        New-GitHubLabels -RepositoryName DesiredStateConfiguration -OwnerName Powershell
#>
function New-GitHubLabels
{
    param(
          [Parameter(Mandatory=$true)]
          [string]$RepositoryName,
          [Parameter(Mandatory=$true)]
          [string]$OwnerName,
          [string]$GitHubAccessToken = $script:gitHubToken
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
    $existingLabels = Get-GitHubLabel -RepositoryName $RepositoryName -OwnerName $OwnerName -GitHubAccessToken $GitHubAccessToken
    $existingLabelsNames = $existingLabels.name
    
    
    foreach ($label in $labelList)
    {
        if ($label.name -notin $existingLabelsNames)
        {
            # Create label if it doesn't exist
            New-GitHubLabel -RepositoryName $RepositoryName -OwnerName $OwnerName -LabelName $label.name -LabelColor $label.color -GitHubAccessToken $GitHubAccessToken
        }
        else 
        {
            # Update label's color if it already exists
            Update-GitHubLabel -RepositoryName $RepositoryName -OwnerName $OwnerName -LabelName $label.name -NewLabelName $label.name -LabelColor $label.color -GitHubAccessToken $GitHubAccessToken
        }
    }
    
    foreach ($label in $existingLabelsNames)
    {
        if($label -notin $labelListNames)
        {
            # Remove label if it exists but is not on desired label list
            Remove-GitHubLabel -RepositoryName $RepositoryName -OwnerName $OwnerName -LabelName $label -GitHubAccessToken $GitHubAccessToken
        }
    }
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
    if ($query -notmatch 'page=1')
    {
        
        return $query
    }
    else
    {
        return $null
    }
}