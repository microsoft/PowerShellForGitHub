# PowerShellForGitHub

PowerShell wrapper for GitHub API.

This repository currently contains two modules:
* GitHubAnalytics.psm1 - for querying issues, pull requests, collaborators, contributors, and organizations
* GitHubLabels.psm1 - for operations on GitHub labels

Please scroll down to the "Examples" section for details on what operations are supported.

## Installation
You can get latest release of the PowerShellForGitHub on the [PowerShell Gallery](https://www.powershellgallery.com/packages/PowerShellForGitHub)
```PowerShell
Install-Module -Name PowerShellForGitHub
```

## Usage
1) Rename ApiTokensTemplate.psm1 to ApiTokens.psm1 and update value of $global:gitHubApiToken with GitHub token for your account
  * You can obtain it from https://github.com/settings/tokens. 
  * If you don't provide GitHub token, you can still use this module, but you will be limited to 60 queries per hour. 
  * You will need to edit this file from an elevated context. 
 
2) Import module you want to use and call it's function, e.g.

 ```powershell
Import-Module .\GitHubAnalytics.psm1
$issues = Get-GitHubIssuesForRepository -repositoryUrl @('https://github.com/PowerShell/DscResources')
```

## Running tests
1) Install [Pester](http://www.powershellgallery.com/packages/Pester/3.4.0) 

```powershell
Install-Module -Name Pester 
```

2) Start test pass

Go to the Tests folder and run:
```powershell
Invoke-Pester
```

Make sure ApiTokens.psm1 exists and contains $global:gitHubApiToken with your GitHub key.
Please keep in mind some tests may fail on your machine, as they test private items (e.g. secret teams) which your key won't have access to.

## Contributing

Contributions are welcome, please open issue on what functionality you would like to see added/contribute or simply send a pull request.

## Examples

### GitHubAnalytics

#### Querying issues

```powershell
$issues = Get-GitHubIssuesForRepository `
-repositoryUrl @('https://github.com/PowerShell/xPSDesiredStateConfiguration')
```

```powershell
$issues = Get-GitHubWeeklyIssuesForRepository `
-repositoryUrl @('https://github.com/powershell/xpsdesiredstateconfiguration',`
'https://github.com/powershell/xactivedirectory') -datatype closed
```

```powershell
$issues = Get-GitHubTopIssuesRepository `
-repositoryUrl @('https://github.com/powershell/xsharepoint',`
'https://github.com/powershell/xCertificate', 'https://github.com/powershell/xwebadministration') -state open
```

#### Querying pull requests

```powershell
$pullRequests = Get-GitHubPullRequestsForRepository `
-repositoryUrl @('https://github.com/PowerShell/xPSDesiredStateConfiguration')
```

```powershell
$pullRequests = Get-GitHubWeeklyPullRequestsForRepository `
-repositoryUrl @('https://github.com/powershell/xpsdesiredstateconfiguration',`
'https://github.com/powershell/xwebadministration') -datatype merged
```

```powershell
$pullRequests = Get-GitHubTopPullRequestsRepository `
-repositoryUrl @('https://github.com/powershell/xsharepoint', 'https://github.com/powershell/xwebadministration')`
-state closed -mergedOnOrAfter 2015-04-20
```

#### Querying collaborators

```powershell
$collaborators = Get-GitHubRepositoryCollaborators`
-repositoryUrl @('https://github.com/PowerShell/DscResources')
```

#### Querying contributors

```powershell
$contributors = Get-GitHubRepositoryContributors`
-repositoryUrl @('https://github.com/PowerShell/DscResources', 'https://github.com/PowerShell/xWebAdministration')
```

```powershell
$contributors = Get-GitHubRepositoryContributors`
-repositoryUrl @('https://github.com/PowerShell/DscResources','https://github.com/PowerShell/xWebAdministration')

$uniqueContributors = Get-GitHubRepositoryUniqueContributors -contributors $contributors
```

#### Quering teams / organization membership

```powershell
$organizationMembers = Get-GitHubOrganizationMembers -organizationName 'OrganizationName'
$teamMembers = Get-GitHubTeamMembers -organizationName 'OrganizationName' -teamName 'TeamName'
```

### GitHubLabels

#### Getting labels for given repository
```powershell
$labels = Get-GitHubLabel -repositoryName DesiredStateConfiguration -ownerName Powershell
```

#### Adding new label to the repository
```powershell
New-GitHubLabel -repositoryName DesiredStateConfiguration -ownerName PowerShell -labelName TestLabel -labelColor BBBBBB
```

#### Removing specific label from the repository
```powershell
Remove-GitHubLabel -repositoryName desiredstateconfiguration -ownerName powershell -labelName TestLabel
```

#### Updating specific label with new name and color
```powershell
Update-GitHubLabel -repositoryName DesiredStateConfiguration -ownerName Powershell -labelName TestLabel -newLabelName NewTestLabel -labelColor BBBB00
```
