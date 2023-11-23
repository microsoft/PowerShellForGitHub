# PowerShellForGitHub PowerShell Module
# Changelog

## [0.17.0](https://github.com/PowerShell/PowerShellForGitHub/tree/0.17.0) - (2021/11/20)

### Features

+ Add support for `Invoke-GHGraphQl` which then allowed support for
  `Get-GitHubRepositoryBranchPatternProtectionRule`, `New-GitHubRepositoryBranchPatternProtectionRule`,
  and `Remove-GitHubRepositoryBranchPatternProtectionRule`
  [[pr]](https://github.com/PowerShell/PowerShellForGitHub/pull/313) | [[cl]](https://github.com/microsoft/PowerShellForGitHub/commit/f7efc4a03640cf292b0e6a256d6713a6f15145b2)

+ Updated `Invoke-GHRestMethod` (and `Invoke-GHRestMethodMultipleResult`) to support versioned API's
  with the new (optional) `ApiVersion` parameter
  [[pr]](https://github.com/PowerShell/PowerShellForGitHub/pull/379) | [[cl]](https://github.com/microsoft/PowerShellForGitHub/commit/938896738c7a8c8b6d3b7b798c761798e4fce651)

+ Added the `HasDiscussions` switch to `New-GitHubRepository` and `Set-GitHubRepository` to allow
  the control of whether discussions are supported in a repository
  [[pr]](https://github.com/PowerShell/PowerShellForGitHub/pull/382) | [[cl]](https://github.com/microsoft/PowerShellForGitHub/commit/3ccee43287e053a4ad9f9729a943e75ad12ce904)

+ Added the `AllowAutoMerge` switch to `New-GitHubRepository` and `Set-GitHubRepository` (which is
  currently only supported on public repositories).
  [[pr]](https://github.com/PowerShell/PowerShellForGitHub/pull/383) | [[cl]](https://github.com/microsoft/PowerShellForGitHub/commit/b976e9515cd42d521bd3f4d7ab6fb2b870cd98ed)

+ Added the `AllowUpdateBranch` switch to `New-GitHubRepository` and `Set-GitHubRepository`, which
  specifies whether to always allow a pull request head branch that is behind its base branch
  to be updated even if it is not required to be up-to-date before merging.
  [[pr]](https://github.com/PowerShell/PowerShellForGitHub/pull/387) | [[cl]](https://github.com/microsoft/PowerShellForGitHub/commit/9baf54e44cee7fb79dee74ae54306b1edbe6e7d0)

+ Added the `WebCommitSignoffRequired` switch to `Set-GitHubRepository`, which
  specifies whether to require contributors to sign off on web-based commits.
  [[pr]](https://github.com/PowerShell/PowerShellForGitHub/pull/389) | [[cl]](https://github.com/microsoft/PowerShellForGitHub/commit/516be0b4cafafb334bca5951c057af0885e6976f)

+ Added the `SecretScanning` parameter to `Set-GitHubRepository`, which
  specifies whether to enable or disable secret scanning for the repository.
  [[pr]](https://github.com/PowerShell/PowerShellForGitHub/pull/391) | [[cl]](https://github.com/microsoft/PowerShellForGitHub/commit/43d5392642cce2ec3d45fbbb1066f7b2efc3b8c4)

+ Added support for Deployment environments with `New-GitHubDeploymentEnvironment`,
  `Get-GitHubDeploymentEnvironment`, `Set-GitHubDeploymentEnvironment` and
  `Remove-GitHubDeploymentEnvironment`
  [[pr]](https://github.com/PowerShell/PowerShellForGitHub/pull/395) | [[cl]](https://github.com/microsoft/PowerShellForGitHub/commit/dd844e5e4a2224e092c8d247f889f6ebabda1767)

+ Added the ability to control how the title and message of a commit are handled during a merge
  and a squash merge with the new `SquashMergeCommitTitle`, `SquashMergeCommitMessage`,
  `MergeCommitTitle`, and `MergeCommitMessage` parameters on `New-GitHubRepository` and
  `Set-GitHubRepository`
  [[pr]](https://github.com/PowerShell/PowerShellForGitHub/pull/385) | [[cl]](https://github.com/microsoft/PowerShellForGitHub/commit/6f94a9b0a37ee466c2fb457299c78de1bd371f95)

+ Added base support for GitHub Codespaces with `Get-GitHubCodespace`, `New-GitHubCodespace`,
  `Remove-GitHubCodespace`, `Start-GitHubCodespace` and `Stop-GitHubCodespace`
  [[pr]](https://github.com/PowerShell/PowerShellForGitHub/pull/407) | [[cl]](https://github.com/microsoft/PowerShellForGitHub/commit/9ec863b14277a524aa8f2931b742bb3dfed10d5a)

### Fixes

+ Fixed a documentation error with `DefaultRepositoryName` in `Set-GitHubConfiguration`
  [[pr]](https://github.com/PowerShell/PowerShellForGitHub/pull/341) | [[cl]](https://github.com/microsoft/PowerShellForGitHub/commit/8b46226ba5347155470c2d789ef2356e4aef118a)

+ Fixed a bug that caused Telemetry to stop working when a PowerShell session was open for longer
  than a day
  [[pr]](https://github.com/PowerShell/PowerShellForGitHub/pull/355) | [[cl]](https://github.com/microsoft/PowerShellForGitHub/commit/4b48946d81924a8508be2b16c28d9842da7d5b37)

+ Improved the error message displayed when an API returns with a 404 error code
  [[pr]](https://github.com/PowerShell/PowerShellForGitHub/pull/363) | [[cl]](https://github.com/microsoft/PowerShellForGitHub/commit/1466f1656b85e256917bc3057ba6dd6d1579a652)

+ Was not properly forwarding the `AccessToken` to sub-commands for
  `Get-GitHubRepositoryTeamPermission`, `Set-GitHubRepositoryTeamPermission`, and
  `Remove-GitHubRepositoryTeamPermission`
  [[pr]](https://github.com/PowerShell/PowerShellForGitHub/pull/362) | [[cl]](https://github.com/microsoft/PowerShellForGitHub/commit/4d7667bcaf66523bf3b0194d847d8bfc3c6325f1)

+ Fixed the logic that determined the simplified explanation of Team permissions exposed by a
  repository object
  [[pr]](https://github.com/PowerShell/PowerShellForGitHub/pull/361) | [[cl]](https://github.com/microsoft/PowerShellForGitHub/commit/d8ee50a7ad0fa1b12e3b5d7745aeed348a340708)

+ Fixed support for PowerShell 7.4+ which removed support for `BinaryFormatter`.
  [[pr]](https://github.com/PowerShell/PowerShellForGitHub/pull/415) | [[cl]](https://github.com/microsoft/PowerShellForGitHub/commit/356350b22f47acf55e72380442c630e6c9591fbc)

### Authors

+ [**@HowardWolosky**](https://github.com/HowardWolosky)
+ [**@X-Guardian**](https://github.com/X-Guardian)
+ [**@matt9ucci**](https://github.com/matt9ucci)
+ [**@variableresistor**](https://github.com/variableresistor)
+ [**@vercellone**](https://github.com/vercellone)
+ [**@andyleejordan**](https://github.com/andyleejordan)

------

## [0.16.1](https://github.com/PowerShell/PowerShellForGitHub/tree/0.16.1) - (2021/05/26)

### Features

+ `Invoke-GHRestMethodMultipleResult` now allows callers to specify `AdditionalHeader`, just like
  `Invoke-GHRestMethod`.
  [[pr]](https://github.com/PowerShell/PowerShellForGitHub/pull/319) | [[cl]](https://github.com/microsoft/PowerShellForGitHub/commit/a2329d67302c55c42bae7fab2c78e63e1abdb656)

### Fixes

- Fixes encoding issues when calling `Set-GitHubContent`
  [[pr]](https://github.com/PowerShell/PowerShellForGitHub/pull/328) | [[cl]](https://github.com/microsoft/PowerShellForGitHub/commit/1200b5b36aa94d96906802ddc04f8604ab83d83c)

### Authors

   * [**@HowardWolosky**](https://github.com/HowardWolosky)
   * [**@jing8956**](https://github.com/jing8956)

------

## [0.16.0](https://github.com/PowerShell/PowerShellForGitHub/tree/0.16.0) - (2021/01/06)

### Features

+ Added the ability to retrieve and modify team permissions on a repository with
  `Get-GitHubRepositoryTeamPermission`, `Set-GitHubRepositoryTeamPermission` and
  `Remove-GitHubRepositoryTeamPermission`
  [[pr]](https://github.com/PowerShell/PowerShellForGitHub/pull/300) | [[cl]](https://github.com/microsoft/PowerShellForGitHub/commit/22e3d7bdf6c3b33fdead74dac831e0bb43beb2c4)

+ Added the ability to retrieve and modify the GitHub Actions permissions policy for repositories
  with `Get-GitHubRepositoryActionsPermission` and `Set-GitHubRepositoryActionsPermission`
  [[pr]](https://github.com/PowerShell/PowerShellForGitHub/pull/301) | [[cl]](https://github.com/microsoft/PowerShellForGitHub/commit/d4997057f8b1234ea1aabeb4fb6742148d3afaaf)

### Fixes

- Added missing `.SYNOPSIS` to a number of functions throughout the module.
  [[pr]](https://github.com/PowerShell/PowerShellForGitHub/pull/293) | [[cl]](https://github.com/microsoft/PowerShellForGitHub/commit/ab536c772a7656f92166d13f5df9ef7bf6627a3f)

- Fixed an error in `Set-GitHubContent` which caused it to ignore requested changes to
  `AuthorName`/`AuthorEmail`.
  [[pr]](https://github.com/PowerShell/PowerShellForGitHub/pull/295) | [[cl]](https://github.com/microsoft/PowerShellForGitHub/commit/ec7950c02c1e52af2a6edc30331982d172f6e7ff)

- Fixed `Get-GitHubEvent`, which was erroring out when its result contained any labels.  (The labels
  were being post-processed incorrectly when adding support for pipelining).
  [[pr]](https://github.com/PowerShell/PowerShellForGitHub/pull/306) | [[cl]](https://github.com/microsoft/PowerShellForGitHub/commit/8fd42010209edaf10936751b8eb190655a2bdb38)

### Authors

   * [**@HowardWolosky**](https://github.com/HowardWolosky)
   * [**@X-Guardian**](https://github.com/X-Guardian)
   * [**@johnlokerse**](https://github.com/johnlokerse)
   * [**@joseartrivera**](https://github.com/joseartrivera)

------

## [0.15.1](https://github.com/PowerShell/PowerShellForGitHub/tree/0.15.1) - (2020/09/09)

### Fixes

- Fixed the default `LogPath` when no user profile is available (like in the situation of running
  within the context of an Azure Function App).  The alternate default log path in this scenario
  will now be the `LocalApplicationDataFolder`.
  [[pr]](https://github.com/PowerShell/PowerShellForGitHub/pull/283) | [[cl]](https://github.com/microsoft/PowerShellForGitHub/commit/e9a6810b3c1a3c6b2ec798bc06f4fa50be154e87)

### Authors

   * [**@HowardWolosky**](https://github.com/HowardWolosky)

------

## [0.15.0](https://github.com/PowerShell/PowerShellForGitHub/tree/0.15.0) - (2020/08/16)

### Overview:

This is a significant update that has a number of breaking changes amongst its payload that
existing users need to be made aware of.

### Highlights:

+ Complete pipeline support has been added to the module.  You can now pipe the output of almost
  any command as input to almost any command.  Every command output now has a specific `GitHub.*`
  type that is queryable as well.

+ Major performance increase.  It turns out that showing animated status would make an operation
  take 3 seconds that would otherwise take 1/4 second due to performance issues with ProgressBar.
  We no longer show status except for commands that 10+ pages of results which we must query for,
  and that minimum can be changed with a new configuration property: `multiRequestProgressThreshold`
  (set it to `0` to never see any progress).

+ Lots of new functionality added:
  + Full support for gists: `Get-GitHubGist`, `Remove-GitHubGist`,
    `Copy-GitHubGist` (aka `Fork-GitHubGist`), `Add-GitHubGistStar`, `Remove-GitHubGistStar`,
    `Set-GitHubGistStar`, `Test-GitHubGistStar`, `New-GitHubGist`, `Set-GitHubGist`,
    `Rename-GitHubGistFile`, `Remove-GitHubGistFile`, `Set-GitHubGistFile` (aka`Add-GitHubGistFile`),
    `Get-GitHubGistComment`, `Set-GitHubGistComment`, `New-GitHubGistComment`,
    `Remove-GitHubGistComment`

  + Full support for Releases:
    `New-GitHubRelease`, `Set-GitHubRelease`, `Remove-GitHubRelease`, `Get-GitHubReleaseAsset`,
    `New-GitHubReleaseAsset`, `Set-GitHubReleaseAsset`, `Remove-GitHubReleaseAsset`

  + Improved support for Teams:
    `New-GitHubTeam`, `Set-GitHubTeam`, `Remove-GitHubTeam`, `Rename-GitHubTeam`

  + Dependabot support: `Test-GitHubRepositoryVulnerabilityAlert`,
    `Enable-GitHubRepositoryVulnerabilityAlert`, `Disable-GitHubRepositoryVulnerabilityAlert`,
    `Enable-GitHubRepositorySecurityFix`, `Disable-GitHubRepositorySecurityFix`

  + New Repository-related commands:
    `New-GitHubRepositoryFromTemplate`, `Set-GitHubContent`, `New-GitHubRepositoryBranch`,
    `Remove-GitHubRepositoryBranch`, `Get-GitHubRepositoryBranchProtectionRule`,
    `New-GitHubRepositoryBranchProtectionRule`, `Remove-GitHubRepositoryBranchProtectionRule`

  + New Reaction support added for issues and pull requests:
    `Get-GitHubReaction`, `Set-GitHubReaction`, `Remove-GitHubReaction`

+ Default formatters have been added for many (but not yet all) of the types introduced by this
  module.  Formatter support will be increased over the coming releases.

+ No longer has any external dependencies.  Previously had to download .NET
  assemblies in order to send telemetry, which made the initial commands
  take up much more time than needed.  With no eternal dependencies involved
  anymore, telemetry is lightning-fast with negligible impact to normal
  command execution.

### Breaking Changes

#### Stardized naming (and verb usage) throughout the module

* A number of commands have been renamed to follow the pattern that we're standardizing on:
  `Get` / `Set` / `New` / `Remove`
  (but we will continue to alias `Remove-*` as `Delete-*`).
  * That resulted in the following command renames:
    * `Get-GitHubComment` -> `Get-GitHubIssueComment` `[Alias('Get-GitHubComment)]`
    * `New-GitHubAssignee` -> `Add-GitHubAssignee` `[Alias('New-GitHubAssignee')]`
    * `New-GitHubComment` -> `New-GitHubIssueComment` `[Alias('New-GitHubComment)]`
    * `Remove-GitHubComment` -> `Remove-GitHubIssueComment` `[Alias('Remove-GitHubComment)]`
    * `Set-GitHubLabel` -> `Initialize-GitHubLabel` _[breaking behavior due to the `Update-GitHubLabel` change below]_`
    * `Update-GitHubCurrentUser` -> `Set-GitHubProfile` `[Alias('Update-GitHubCurrentUser')]`
    * `Update-GitHubIssue` -> `Set-GitHubIssue`  `[Alias('Update-GitHubIssue')]`
    * `Update-GitHubLabel` -> `Set-GitHubLabel`  `[Alias('Update-GitHubLabel')]`
      _[breaking behavior since `Set-GitHubLabel` used to do something else]_
    * `Update-GitHubRepository` -> `Set-GitHubRepository`  `[Alias('Update-GitHubRepository')]`

* The following parameter renames occurred as well:
  * `Add-GitHubIssueLabel`: `Name` -> `Label`
  * `Get-GitHubCodeOfConduct`: `Name` -> `Key`
  * `Get-GitHubProjectCard`: `ArchivedState` -> `State` (although we kept an alias for `ArchivedState`)
  * `Get-GitHubLabel`: `Name` -> `Label`, `Milestone` -> `MilestoneNumber`
  * `Get-GitHubLicense`: `Name` -> `Key`
  * `Get-GitHubRelease`: `ReleaseId` -> `Release` (although we kept an alias for `ReleaseId`)
  * `Get-GitHubRepositoryBranch`: `Name` -> `BranchName`
  * `Get-GitHubUser`: `User` -> `UserName` (although we kept an alias for `User`)
  * `Get-GitHubUserContextualInformation`: There is no longer `SubjectId` and `Subject`.
     Instead you either specify `OrganizationId`, `RepositoryId`, `IssueId` or `PullRequestId`.
  * `Move-GitHubProjectCard`: `ColumnId` -> `Column` (although we kept an alias for `ColumnId`)
  * `New-GitHubLabel`: `Name` -> `Label`
  * `New-GitHubProject`: `Name` -> `ProjectName` (although we kept an alias for `Name`)
  * `New-GitHubProjectCard`: There is no longer `ContentId` and `ContentType`.
     Instead you either specify `IssueId` or `PullRequestId`.
  * `New-GitHubProjectColumn`: `Name` -> `ColumnName` (although we kept an alias for `Name`)
  * `Remove-GitHubIssueLabel`: `Name` -> `Label`
  * `Remove-GitHubLabel`: `Name` -> `Label`
  * `Rename-GitHubRepository`: `html_url` alias for `Uri` has been removed
  * `Set-GitHubIssueLabel`: `Name` -> `Label`
  * `Set-GitHubLabel` (formerly `Update-GitHubLabel`): `Name` -> `Label`
  * `Set-GitHubProjectColumn`: `Name` -> `ColumnName` (although we kept an alias for `Name`)
  * `Set-GitHubRepositoryTopic`: `Name` -> `Topic` (although we kept an alias for `Name`)

#### Other breaking changes

* All `Remove-*` functions (and some `Rename-*`/`Set-*` functions) now prompt for confirmation before
  performing the requested action.  This can be silently bypassed by passing-in `-Confirm:$false`
  or `-Force`.
  * Affected commands that existed in previous releases:
    * `Remove-GitHubAssignee`
    * `Remove-GitHubIssueComment` (formerly named `Remove-GitHubComment`)
    * `Remove-GitHubIssueLabel`
    * `Remove-GitHubLabel`
    * `Remove-GitHubMilestone`
    * `Remove-GitHubProject`
    * `Remove-GitHubProjectCard`
    * `Remove-GitHubProjectColumn`
    * `Remove-GitHubRepository`
    * `Rename-GitHubRepository`
    * `Set-GitHubLabel` (formerly named `Update-GitHubLabel`)
    * `Set-GitHubRepository` (only affected when being used to rename the repository)

* Some parameters have had their type updated:
  * `Comment`: `[string]` -> `[int64]`
  * `Issue`/`IssueNumber`: `[string]`/`[int]` -> `[int64]`
  * `Milestone`/`MilestoneNumber`: `[string]` -> `[int64]`
  * `PullRequest`/`PullRequestNumber`: `[string]`/`[int]` -> `[int64]`
  * `Release`/`ReleaseId`: `[string]` -> `[int64]`

* `WhatIf` support changes:
  * Only GitHub state-changing commands now support `-WhatIf` (which means `Get-GitHub*` and
    `Test-GitHub*` no longer support `-WhatIf`).
  * All other `-WhatIf`-supporting commands will only have a single `-WhatIf` output.

* The `NoStatus` parameter has been removed from all functions due to the change in status behavior
  as descried above.  The `DefaultNoStatus` configuration value has also been removed for the same
  reason.

* All state-changing functions are now silent by default (no resulting output).  If you want them
  to return the result, you can pass in `-PassThru`, which is a PowerShell standard design pattern.
  To truly get back to previous module behavior, you can set the new configuration property:
  `DefaultPassThru`.

* `Get-GitHubTeam` and `Get-GitHubTeamMember` no longer support the `TeamId` parameter, as that
  functionality has been deprecated by GitHub.  You can use `TeamSlug` instead.

### Features

+ Complete pipeline support has been added to the module.  You can now pipe the output of almost
  any command as input to almost any command.  Every command output now has a specific `GitHub.*`
  type that is queryable as well.
  [[pr]](https://github.com/PowerShell/PowerShellForGitHub/pull/242) | [[cl]](https://github.com/microsoft/PowerShellForGitHub/commit/17f6122d7812ee4001ce4bdf630429e711e45f7b)

+ All removal functions (and some rename functions) now prompt for confirmation.  This can be silently
  disabled with `-Confirm:$false`.  A later change will add support for using `-Force` as well.
  [[pr]](https://github.com/PowerShell/PowerShellForGitHub/pull/174) | [[cl]](https://github.com/microsoft/PowerShellForGitHub/commit/a6a27aa0aa1129d97bb6e5188707ff3ef6d53549)

+ All commands that require confirmation now accept `-Force` in addition to `-Confirm:$false`.
  [[pr]](https://github.com/PowerShell/PowerShellForGitHub/pull/226) | [[cl]](https://github.com/microsoft/PowerShellForGitHub/commit/3c642d2e686725f7b17ad096c1f04d7d3777f733)

+ Telemetry no longer has any external dependencies.  We used to have to download .NET assemblies
  in order to send telemetry, and the downloading of those binaries took up time.  Telemetry
  reporting has now been completely implemented within PowerShell, removing all external dependencies.
  [[pr]](https://github.com/PowerShell/PowerShellForGitHub/pull/186) | [[cl]](https://github.com/microsoft/PowerShellForGitHub/commit/ae8467f74a8bae1b97ca808a3b6eec727d15fc7e)

+ Added additional options to `Update-GitHubRepository` (later renamed to `Set-GitHubRepository`):
  `DeleteBranchOnMerge` and `IsTemplate`
  [[pr]](https://github.com/PowerShell/PowerShellForGitHub/pull/192) | [[cl]](https://github.com/microsoft/PowerShellForGitHub/commit/ef246cd5b2a8a1d5646be8f1467e304cf27aabd4)

+ Added Dependabot service functions: `Test-GitHubRepositoryVulnerabilityAlert`,
  `Enable-GitHubRepositoryVulnerabilityAlert`, `Disable-GitHubRepositoryVulnerabilityAlert`,
  `Enable-GitHubRepositorySecurityFix`, `Disable-GitHubRepositorySecurityFix`
  [[pr]](https://github.com/PowerShell/PowerShellForGitHub/pull/235) | [[cl]](https://github.com/microsoft/PowerShellForGitHub/commit/b70c7d433721bcbe82e6272e32979cf2e5c5e1d8)

+ Added `New-GitHubRepositoryFromTemplate` which can create a new GitHub repository from a specified
  template repository.
  [[pr]](https://github.com/PowerShell/PowerShellForGitHub/pull/221) | [[cl]](https://github.com/microsoft/PowerShellForGitHub/commit/d96541ee5e16a3b9e11a52994a26540b203fb22c)

+ Added `Set-GitHubContent` and added a `BranchName` parameter to `Get-GitHubContent`.
  [[pr]](https://github.com/PowerShell/PowerShellForGitHub/pull/241) | [[cl]](https://github.com/microsoft/PowerShellForGitHub/commit/a1f5e935165b2c606f81089524e89da9bb8b851d)

+ Added default "views" for all types exposed in GitHubRepositories.ps1: `GitHub.Repository`,
  `GitHub.RepositoryTopic`, `GitHub.RepositoryContributor`, `GitHub.RepositoryContributorStatistics`,
  `GitHub.RepositoryCollaborator`, `GitHub.RepositoryTag`
  [[pr]](https://github.com/PowerShell/PowerShellForGitHub/pull/205) | [[cl]](https://github.com/microsoft/PowerShellForGitHub/commit/41de3adb29ed583f775ce30e52c3d6ed8ade35ff)

+ Standardized verb usage and parameter naming throughout the module.  This is great for long-term
  maintainability of the module, but it does introduced breaking changes from 0.14.0.  The breaking
  changes are covered more completely, above.
  [[pr]](https://github.com/PowerShell/PowerShellForGitHub/pull/228) | [[cl]](https://github.com/microsoft/PowerShellForGitHub/commit/e57a9563ef68f3a897c2b523e5ea0cbf23011d4c)

+ Overhauled how status works for the module.  No longer shows an animation while invoking a web
  request.  This has the side effect of simplifying the code and significantly speeding-up the
  module.  This deprecates `NoStatus` and `DefaultNoStatus`.  This adds
  `MultiRequestProgressThreshold` to control how many pages of results are needed before a command
  will show status of completion across the full number of pages being retrieved.  This defaults to
  10.
  [[pr]](https://github.com/PowerShell/PowerShellForGitHub/pull/253) | [[cl]](https://github.com/microsoft/PowerShellForGitHub/commit/2740026e64f2246d3b10bd3ccca197ea4ca3c9d8)

+ Added `New-GitHubRepositoryBranch` and `Remove-GitHubRepositoryBranch`
  [[pr]](https://github.com/PowerShell/PowerShellForGitHub/pull/256) | [[cl]](https://github.com/microsoft/PowerShellForGitHub/commit/d76f54b08ea7c3f3355ec188827fadc0035d0595)

+ Updated `New-GitHubRepositoryBranch` to better support pipeline input, and added `Sha` as an
  optional parameter to allow for arbitrary commit branch creation.  Also added `Sha` as a top-level
  property to a `GitHub.Branch` object.
  [[pr]](https://github.com/PowerShell/PowerShellForGitHub/pull/277) | [[cl]](https://github.com/microsoft/PowerShellForGitHub/commit/3e79c2592ce0f062c52d95f2de2c87cbff40e8ea)

+ Added GitHub Reactions support for Issues and Pull Requests: `Get-GitHubReaction`,
  `Set-GitHubReaction`, `Remove-GitHubReaction`
  [[pr]](https://github.com/PowerShell/PowerShellForGitHub/pull/193) | [[cl]](https://github.com/microsoft/PowerShellForGitHub/commit/8e55f5af03aa0ae2d402e52b7cd50ca43ded03a7)

+ Added complete support for the GitHub Releases API surface: `New-GitHubRelease`,
  `Set-GitHubRelease`, `Remove-GitHubRelease`, `Get-GitHubReleaseAsset`, `New-GitHubReleaseAsset`,
  `Set-GitHubReleaseAsset`, `Remove-GitHubReleaseAsset`
  [[pr]](https://github.com/PowerShell/PowerShellForGitHub/pull/177) | [[cl]](https://github.com/microsoft/PowerShellForGitHub/commit/356af2f5b69fa8cd60bc77670d250cde796ac1d6)

+ Added complete support for the GitHub gists API surface: `Get-GitHubGist`, `Remove-GitHubGist`,
  `Copy-GitHubGist` (aka `Fork-GitHubGist`), `Add-GitHubGistStar`, `Remove-GitHubGistStar`,
  `Set-GitHubGistStar`, `Test-GitHubGistStar`, `New-GitHubGist`, `Set-GitHubGist`,
  `Rename-GitHubGistFile`, `Remove-GitHubGistFile`, `Set-GitHubGistFile` (aka`Add-GitHubGistFile`),
  `Get-GitHubGistComment`, `Set-GitHubGistComment`, `New-GitHubGistComment`,
  `Remove-GitHubGistComment`
  [[pr]](https://github.com/PowerShell/PowerShellForGitHub/pull/172) | [[cl]](https://github.com/microsoft/PowerShellForGitHub/commit/92c4aa8b3a0142752e68a50af73ac276db0c1ff6)

+ Added branch protection rule commands: `Get-GitHubRepositoryBranchProtectionRule`,
  `New-GitHubRepositoryBranchProtectionRule`, `Remove-GitHubRepositoryBranchProtectionRule`
  [[pr]](https://github.com/PowerShell/PowerShellForGitHub/pull/255) | [[cl]](https://github.com/microsoft/PowerShellForGitHub/commit/981b85c2d49172df531bee641c9554a425181625)

+ Standardized and improved the `WhatIf` support throughout the entire module.
  [[pr]](https://github.com/PowerShell/PowerShellForGitHub/pull/254) | [[cl]](https://github.com/microsoft/PowerShellForGitHub/commit/2f16de1f46611a89cd833429f6227c83b5563e84)

+ Added additional support for Teams: `New-GitHubTeam`, `Set-GitHubTeam`, `Remove-GitHubTeam`, and
  adds `TeamName` as an additional way to call into `Get-GitHubTeam`.
  [[pr]](https://github.com/PowerShell/PowerShellForGitHub/pull/257) | [[cl]](https://github.com/microsoft/PowerShellForGitHub/commit/6a51601ec841a52e1fa95cf0e2e0a6fd1100269a)

+ Minor improvements to the new Teams commands to better support pipeline input and to provide
  alternative calling patterns (which can specify a team's `slug` or parent team's `TeamId` in order
  to minimize additional queries that would have to be done internally to complete your request).
  Added `Rename-GitHubTeam` as well.
  This _also_ removes `TeamId` as a way to call `Get-GitHubTeam` or `Get-GitHubTeamMember`, as
  those API's have been deprecated by GitHub.  You can now speficy a `TeamSlug` instead.
  [[pr]](https://github.com/PowerShell/PowerShellForGitHub/pull/275) | [[cl]](https://github.com/microsoft/PowerShellForGitHub/commit/9ef3c2b5670fc7b640a47a33d0aa725c63319839)

* All state-changing functions are now silent by default (no resulting output).  If you want them
  to return the result, you can pass in `-PassThru`, which is a PowerShell standard design pattern.
  To truly get back to previous module behavior, you can set the new configuration property:
  `DefaultPassThru`.
  [[pr]](https://github.com/PowerShell/PowerShellForGitHub/pull/276) | [[cl]](https://github.com/microsoft/PowerShellForGitHub/commit/9600fc21120e17241e60606c5de3459d973026bb)

### Fixes

- Module update check needs to be able to handle when the module in use is newer than the published
  version (since publication to PowerShellGallery happens a few hours after the version is updated
  in GitHub).
  [[pr]](https://github.com/PowerShell/PowerShellForGitHub/pull/204) | [[cl]](https://github.com/microsoft/PowerShellForGitHub/commit/efdcbfa4a086bd4606ec2c32ef67db8553711781)

- Simplified `-WhatIf` handling within `Invoke-GHRestMethod` to only have a single `ShouldProcess`
  statement.  This was the first attempt at simplifying how `-WhatIf` should work.  There was a
  successive change that took things further (see below).
  [[pr]](https://github.com/PowerShell/PowerShellForGitHub/pull/213) | [[cl]](https://github.com/microsoft/PowerShellForGitHub/commit/ad15657551d137c5db063b64f15c2760f74ac5af)

- Fixed exception that occurred when calling `Set-GitHubRepositoryTopic` with `-Clear`.
  [[pr]](https://github.com/PowerShell/PowerShellForGitHub/pull/216) | [[cl]](https://github.com/microsoft/PowerShellForGitHub/commit/d1bd976d70cc975dfd247f9ad2bace58a465c7da)

- Disabled the progress bar for `Invoke-WebRequest` which greatly improves its performance in
  PowerShell 5.1.
  [[pr]](https://github.com/PowerShell/PowerShellForGitHub/pull/229) | [[cl]](https://github.com/microsoft/PowerShellForGitHub/commit/6e794cbcaf5782bb9ba1cdbaeaa567f81435484e)

- Significantly increased the performance of `Get-GitHubContent` with some internal changes.
  [[pr]](https://github.com/PowerShell/PowerShellForGitHub/pull/232) | [[cl]](https://github.com/microsoft/PowerShellForGitHub/commit/78187766f0b8b4d2bece25b945edc6b5aa43bbb4)

- Removed positional binding support on `Set-GitHubConfiguration` to solve a common misconfiguration
  problem introduced by accidentally setting the wrong configuration value state.
  [[pr]](https://github.com/PowerShell/PowerShellForGitHub/pull/234) | [[cl]](https://github.com/microsoft/PowerShellForGitHub/commit/08ff284644c70f9f1d9bc5d65f62dc41cafef0ac)

- The module will now restore the previous state of `[Net.ServicePointManager]::SecurityProtocol `
  after performing its operation.
  [[pr]](https://github.com/PowerShell/PowerShellForGitHub/pull/240) | [[cl]](https://github.com/microsoft/PowerShellForGitHub/commit/618398eedd4571a42e000a4ce4527b56244f7720)

- Some commands were not properly validating the `OwnerName`/`RepositoryName` input due to a
  misconfiguration.  That has now been fixed.
  [[pr]](https://github.com/PowerShell/PowerShellForGitHub/pull/243) | [[cl]](https://github.com/microsoft/PowerShellForGitHub/commit/2385b5cf5d959a7581bf968f15f346d9a0ff816b)

- Added a `ValidateSet` to the `Affiiliation` parameter in `Get-GitHubRepository` to limit input to
  the set of permitted options. Comment-based help was updated for `Get-GitHubRepositoryCollaborator`
  and `Move-GitHubRepositoryOwnership`.  Removed an unreachable codepath in `Get-GitHubRepository`.
  [[pr]](https://github.com/PowerShell/PowerShellForGitHub/pull/233) | [[cl]](https://github.com/microsoft/PowerShellForGitHub/commit/eedfaa3740ac5330128fea27038f213c8abf1d4b)

- Fixes to module version update checking: Fixed regression introduced by the
  [pipeline work](https://github.com/PowerShell/PowerShellForGitHub/pull/242), and suppressed
  its usage of the progress bar to speed it up further.
  [[pr]](https://github.com/PowerShell/PowerShellForGitHub/pull/252) | [[cl]](https://github.com/microsoft/PowerShellForGitHub/commit/d32bd11d971c8b5c4a56b6ff6f997aca61fba2ca)

- Fixed pipeline support for the newly added
  [`New-GitHubRepositoryFromTemplate`](https://github.com/PowerShell/PowerShellForGitHub/pull/221).
  [[pr]](https://github.com/PowerShell/PowerShellForGitHub/pull/259) | [[cl]](https://github.com/microsoft/PowerShellForGitHub/commit/f31d79133df1310fac1f14643eea4cdb4972a26a)

- Fixed how numerical configuration values are handled to accommodate behavior differences in
  PowerShell 5 and PowerShell 7 Core.
  [[pr]](https://github.com/PowerShell/PowerShellForGitHub/pull/262) | [[cl]](https://github.com/microsoft/PowerShellForGitHub/commit/683187a94f05b7c69bc6ca3459ce615936f5a0d2)

- Fixed pipeline input handling for the newly added Dependabot functions.
  [[pr]](https://github.com/PowerShell/PowerShellForGitHub/pull/272) | [[cl]](https://github.com/microsoft/PowerShellForGitHub/commit/4ded2faf8127a502fc7f21d7e60167e1230061af)

- Removed `NoStatus` completely from the module to complete the transitional work done for how
  status is handled in the module.
  [[pr]](https://github.com/PowerShell/PowerShellForGitHub/pull/274) | [[cl]](https://github.com/microsoft/PowerShellForGitHub/commit/db111559f9844e9a30b666ec069a5dc462643c63)

### Authors

   * [**@HowardWolosky**](https://github.com/HowardWolosky)
   * [**@X-Guardian**](https://github.com/X-Guardian)
   * [**@themilfan**](https://github.com/themilfan)
   * [**@TylerLeonhardt**](https://github.com/TylerLeonhardt)

------

## [0.14.0](https://github.com/PowerShell/PowerShellForGitHub/tree/0.14.0) - (2020/05/30)

### Features

+ The module will now asynchronously check for updates up to once per day.  This can be disabled
  if desired with the `Set-GitHubConfiguration -DisableUpdateCheck`.
  [[pr]](https://github.com/PowerShell/PowerShellForGitHub/pull/185) | [[cl]](https://github.com/microsoft/PowerShellForGitHub/commit/a9f48a8aec796195664c3d86eb11755a1394d34e)
+ It turns out that `Group-GitHubPullRequest` which was written back in `0.2.0` was never actually
  exported.  Now it is.
  [[pr]](https://github.com/PowerShell/PowerShellForGitHub/pull/180) | [[cl]](https://github.com/microsoft/PowerShellForGitHub/commit/b7e1ea1cb912493e110b9854b0ec7700462254a0)

### Fixes

- Fixes the behavior of `Get-GitHubRepository`.  It actually had a number of issues:
  [[pr]](https://github.com/PowerShell/PowerShellForGitHub/pull/179) | [[cl]](https://github.com/microsoft/PowerShellForGitHub/commit/c4c1ec344a357489d248b9cf1bc2837484d4915f)
  - `-GetAllPublicRepositories` didn't acutally work.  Now it does, along with the newly
     added `Since` parameters.
  - Fixed the ParameterSet handling for all parameters to make sure that users can only specify
    the correct combination of parameters.
- Fixes multi-result behavior across all versions of PowerShell.  You can now reliably capture
  the result of an API call like this: `@(Get-GitHubRepository ...)` and be assured that you'll
  get an array result with the proper count of items.  As a result, this fixes all remaining failing
  UT's on PowerShell 7.
  [[pr]](https://github.com/PowerShell/PowerShellForGitHub/pull/199) | [[cl]](https://github.com/microsoft/PowerShellForGitHub/commit/bcd0a5616e1395ca480bc7f3b64776eada2a6670)
- Fixed an erroneous exception that occurred when calling `New-GitHubRepository` when specifying
  a `TeamId`.
  [[pr]](https://github.com/PowerShell/PowerShellForGitHub/pull/196) | [[cl]](https://github.com/microsoft/PowerShellForGitHub/commit/587e2042621091c79cc06be2aa9cc6ea836561f4)
- The module is now PSScriptAnalyzer clean (again).  This also fixed pipeline handling in
  `Group-GitHubPullRequest`, `Group-GitHubIssue` and `ConvertFrom-GitHubMarkdown`.
  [[pr]](https://github.com/PowerShell/PowerShellForGitHub/pull/180) | [[cl]](https://github.com/microsoft/PowerShellForGitHub/commit/b7e1ea1cb912493e110b9854b0ec7700462254a0)
- Fixed some documentation which referenced that private repos were only available to paid GitHub
  plans.
  [[pr]](https://github.com/PowerShell/PowerShellForGitHub/pull/191) | [[cl]](https://github.com/microsoft/PowerShellForGitHub/commit/3c70b8d2702a4a7b5674bb72decacb385f1a47a8)
- Fixed a bug preventing quering for a specifically named branch with `Get-GitHubRepositoryBranch`.
  [[pr]](https://github.com/PowerShell/PowerShellForGitHub/pull/188) | [[cl]](https://github.com/microsoft/PowerShellForGitHub/commit/5807d00ed0a3acd293057d8a9c06a9d68b6030db)
- Correctly fixed the hash that catches whether or not a developer has updated the settings file used
  when running this module's unit tests.  It involved updating the hash and then also ensuring we
  always check the file out with consistent line endings.
  [[pr]](https://github.com/PowerShell/PowerShellForGitHub/pull/181) | [[cl]](https://github.com/microsoft/PowerShellForGitHub/commit/93689d69eedc50f084982a6fba21183857507dbb) &&
  [[pr]](https://github.com/PowerShell/PowerShellForGitHub/pull/183) | [[cl]](https://github.com/microsoft/PowerShellForGitHub/commit/b4439f4a6b12f89d755851b313eff0e9ea0b3ab5)
- Documentation updates around configuring unattended authentication.
  [[pr]](https://github.com/PowerShell/PowerShellForGitHub/pull/173) | [[cl]](https://github.com/microsoft/PowerShellForGitHub/commit/3440909f5f1264865ccfca85ce2364af3ce85425)

### Authors

   * [**@HowardWolosky**](https://github.com/HowardWolosky)

------

## [0.13.1](https://github.com/PowerShell/PowerShellForGitHub/tree/0.13.1) - (2020/05/12)

### Fixes

- Ensure progress bar for Wait-JobWithAnimation gets marked as Completed
  [[pr]](https://github.com/PowerShell/PowerShellForGitHub/pull/169) | [[cl]](https://github.com/microsoft/PowerShellForGitHub/commit/bb2ad45f61f4e55ba763d5eb402c80de5991bb6b)

### Authors

   * [**@HowardWolosky**](https://github.com/HowardWolosky)

------

## [0.13.0](https://github.com/PowerShell/PowerShellForGitHub/tree/0.13.0) - (2020/05/12)

### Improvement:

- Migrate REST API progress status to use Write-Progress
  [[pr]](https://github.com/PowerShell/PowerShellForGitHub/pull/167) | [[cl]](https://github.com/microsoft/PowerShellForGitHub/commit/992f67871cd659dac20833487b326bdad7b85bd8)

### Authors

   * [**@HowardWolosky**](https://github.com/HowardWolosky)

------

## [0.12.0](https://github.com/PowerShell/PowerShellForGitHub/tree/0.12.0) - (2020/05/12)

### Features

+ Added core support for Projects
  [[pr]](https://github.com/PowerShell/PowerShellForGitHub/pull/160) | [[cl]](https://github.com/microsoft/PowerShellForGitHub/commit/1cdaac1a5af873589458bd0b40b3651187ec7e19)
+ Added suport for Project Columns
  [[pr]](https://github.com/PowerShell/PowerShellForGitHub/pull/162) | [[cl]](https://github.com/microsoft/PowerShellForGitHub/commit/85170ce517dc4941518d51d788843a87612e25e0)
+ Added suport for Project Cards
  [[pr]](https://github.com/PowerShell/PowerShellForGitHub/pull/163) | [[cl]](https://github.com/microsoft/PowerShellForGitHub/commit/3a87f2bd50a811f554d6cfaf085fede7aede6c76)
+ Added sample usage documentation for the new Project API's
  [[pr]](https://github.com/PowerShell/PowerShellForGitHub/pull/164) | [[cl]](https://github.com/microsoft/PowerShellForGitHub/commit/1556b8b39cd61735aad14be0fb237c14e763f696)

### Fixes

- Minor spelling fixes in documentation throughout module
  [[pr]](https://github.com/PowerShell/PowerShellForGitHub/pull/165) | [[cl]](https://github.com/microsoft/PowerShellForGitHub/commit/6735ba57a5a43b61a37ef09d4021296dcd417dba)
- Fixed confirmation message for `Rename-GitHubRepository`
  [[pr]](https://github.com/PowerShell/PowerShellForGitHub/pull/161) | [[cl]](https://github.com/PowerShell/PowerHellForGitHub/commit/3fab72464e38cb573408add7e99d5a6bb0db2ea1)

### Authors

   * [**@jpomfret**](https://github.com/jpomfret)
   * [**@HowardWolosky**](https://github.com/HowardWolosky)

------

## [0.11.0](https://github.com/PowerShell/PowerShellForGitHub/tree/0.11.0) - (2020/04/03)

### Features

+ Added `Get-GitHubContents`
  [[pr]](https://github.com/PowerShell/PowerShellForGitHub/pull/146) | [[cl]](https://github.com/PowerShell/PowerHellForGitHub/commit/9a45908dc65b3e8dd0227083fab281099cf07b1b)

### Authors

[**@Shazwazza**](https://github.com/Shazwazza)

------

## [0.10.0](https://github.com/PowerShell/PowerShellForGitHub/tree/0.10.0) - (2020/03/02)

### Features

+ Added `Rename-GitHubRepository`
  [[pr]](https://github.com/PowerShell/PowerShellForGitHub/pull/145) | [[cl]](https://github.com/PowerShell/PowerHellForGitHub/commit/536b762425d51a181166c2c47ad2b00014911d1d)

Author: [**@mtboren**](https://github.com/mtboren)

------

## [0.9.2](https://github.com/PowerShell/PowerShellForGitHub/tree/0.9.2) - (2019/11/11)

### Fixes

- Reduces the warning noise seen during execution of the unit tests.
  [[pr]](https://github.com/PowerShell/PowerShellForGitHub/pull/130) | [[cl]](https://github.com/PowerShell/PowerHellForGitHub/commit/89f69f1132505f04e6b2ac38b6f5a93aef6ac947)

### Authors

[**@smaglio81**](https://github.com/smaglio81)

------

## [0.9.1](https://github.com/PowerShell/PowerShellForGitHub/tree/0.9.1) - (2019/09/24)

### Fixes

- Ensure Milestone `due_on` always gets set to the desired date.
  (Attempts to work around odd GitHub behavior which uses PST/PDT's midnight to determine the date instead of UTC.)
  [[pr]](https://github.com/PowerShell/PowerShellForGitHub/pull/133) | [[cl]](https://github.com/PowerShell/PowerHellForGitHub/commit/013452b5cd8a7d7655cb32031d5ebdb580af16d9)
- Fix `Update-GitHubRepository` to work correctly
  - The REST endpoint had a typo in it
    [[pr]](https://github.com/PowerShell/PowerShellForGitHub/pull/137) | [[cl]](https://github.com/PowerShell/PowerHellForGitHub/commit/27920b1abefd3d33082cbf930e8965af36f86a6a)
  - The `Archived` switch's value was being incorrectly inverted
    [[pr]](https://github.com/PowerShell/PowerShellForGitHub/pull/135) | [[cl]](https://github.com/PowerShell/PowerHellForGitHub/commit/9bdb37c053f98f108d346050622b609d8488fd45)

### Authors

[**@HowardWolosky**](https://github.com/HowardWolosky)

------

## [0.9.0](https://github.com/PowerShell/PowerShellForGitHub/tree/0.9.0) - (2019/09/19)

### Features

+ Added `Get-GitHubRelease`
  [[pr]](https://github.com/PowerShell/PowerShellForGitHub/pull/125) | [[cl]](https://github.com/PowerShell/PowerHellForGitHub/commit/7ea773c715525273dddd451d2a05f429e7fe69e1)
+ Added `New-GitHubPullRequest`
  [[pr]](https://github.com/PowerShell/PowerShellForGitHub/pull/111) | [[cl]](https://github.com/PowerShell/PowerHellForGitHub/commit/788465faec1b6d6331537aa87c2d94039682e373)

### Fixes
- Updates the GitHub Enterprise support to use the `http(s)://[hostname]/api/v3` syntax
  instead of the non-standard `http(s)://api.[hostname]/` syntax.
  [[pr]](https://github.com/PowerShell/PowerShellForGitHub/pull/118) | [[cl]](https://github.com/PowerShell/PowerHellForGitHub/commit/f7b956da4ae169ec6ec1bb6582ce742372677f5c)
- Minor Comment Based Help (CBH) update for Get-GitHubRepository
  [[pr]](https://github.com/PowerShell/PowerShellForGitHub/pull/120) | [[cl]](https://github.com/PowerShell/PowerHellForGitHub/commit/220333a71214fb88a33093b5e907d431dcfdb4c8)

### Authors

   * [**@smaglio81**](https://github.com/smaglio81)
   * [**@rjmholt**](https://github.com/rjmholt)
   * [**@v2kiran**](https://github.com/v2kiran)
   * [**@PrzemyslawKlys**](https://github.com/PrzemyslawKlys)

------

## [0.8.0](https://github.com/PowerShell/PowerShellForGitHub/tree/0.8.0) - (2019/04/12)

### Features

+ Added support for GitHub Enterprise users by adding a new `ApiHostName` configuration value.
  ([more info](https://github.com/Microsoft/PowerShellForGitHub/blob/master/README.md#github-enterprise))
  [[pr]](https://github.com/PowerShell/PowerShellForGitHub/pull/101) | [[cl]](https://github.com/PowerShell/PowerHellForGitHub/commit/d5acd0f73d97f6692914976ce9366456a59cbf70)

### Fixes

- Renamed `ConvertFrom-Markdown` to `ConvertFrom-GitHubMarkdown` to avoid a conflict with
  PSCore's new `ConvertFrom-Markdown` command.
  [[pr]](https://github.com/PowerShell/PowerShellForGitHub/pull/100) | [[cl]](https://github.com/PowerShell/PowerHellForGitHub/commit/088f95b5a1340c7ce570e6e68a41967fd5760c46)

### Authors

   * [**@Cellivar**](https://github.com/Cellivar)
   * [**@HowardWolosky**](https://github.com/HowardWolosky)

------

## [0.7.0](https://github.com/PowerShell/PowerShellForGitHub/tree/0.7.0) - (2019/03/15)

### Features

+ Added `Test-GitHubOrganizationMember` to test if a user is in an organization.
  [[pr]](https://github.com/PowerShell/PowerShellForGitHub/pull/90) | [[cl]](https://github.com/PowerShell/PowerHellForGitHub/commit/c60bb29ac02e7ab9fcd2e29db865b63876cb0125)
+ Updated `Get-GitHubTeamMember` to optionally work directly with a TeamId.
  [[pr]](https://github.com/PowerShell/PowerShellForGitHub/pull/90) | [[cl]](https://github.com/PowerShell/PowerHellForGitHub/commit/c60bb29ac02e7ab9fcd2e29db865b63876cb0125)

### Fixes

- Modified all [int] parameters to be [int64] to avoid out of bounds issues with large ID's.
  [[pr]](https://github.com/PowerShell/PowerShellForGitHub/pull/94) | [[cl]](https://github.com/PowerShell/PowerHellForGitHub/commit/a22739e7f535faf4c5f486694bd213782437e82a)
- `Split-GitHubUri` updated to work with the `https://api.github.com/*` uri's included in some of
  the REST responses.
  [[pr]](https://github.com/PowerShell/PowerShellForGitHub/pull/88) | [[cl]](https://github.com/PowerShell/PowerHellForGitHub/commit/592167de9b3f07635c49365e291082fd3f712586)

### Authors

[**@HowardWolosky**](https://github.com/HowardWolosky)

------

## [0.6.4](https://github.com/PowerShell/PowerShellForGitHub/tree/0.6.4) - (2019/01/16)

### Fixes

- Updated the `*-GitHubIssue` functions to support specifying the `MediaType` that should be used
  for the returned result.
  [[pr]](https://github.com/PowerShell/PowerShellForGitHub/pull/83) | [[cl]](https://github.com/PowerShell/PowerHellForGitHub/commit/e3b6c53017abd36fc70253e1a49c31046c885ad1)

### Authors

[**@joseartrivera**](https://github.com/joseartrivera)

------

## [0.6.3](https://github.com/PowerShell/PowerShellForGitHub/tree/0.6.3) - (2019/01/07)

### Fixes

- Updated all parameter sets to use `CamelCase` for the permitted options, and stopped
  any use of abbreviation, to be more consistent with the rest of PowerShell.
  [[pr]](https://github.com/PowerShell/PowerShellForGitHub/pull/81) | [[cl]](https://github.com/PowerShell/PowerHellForGitHub/commit/185441078efeb0e6693eafeb023785388a1a5a69)

### Authors

[**@HowardWolosky**](https://github.com/HowardWolosky)

------

## [0.6.2](https://github.com/PowerShell/PowerShellForGitHub/tree/0.6.2) - (2018/12/13)

### Fixes

- Fixes a bug preventing Labels from being correctly added at the time of new Issue creation or
  modified when updating an issue.
  {[[pr]](https://github.com/PowerShell/PowerShellForGitHub/pull/76) | [[cl]](https://github.com/PowerShell/PowerShellForGitHub/commit/3b6e84cbafaf044e2154a06612b1c43a873cd002) and
  [[pr]](https://github.com/PowerShell/PowerShellForGitHub/pull/78) | [[cl]](https://github.com/PowerShell/PowerShellForGitHub/commit/577f07bd219e9b5c03d481e562fd7f2fc3586474)}

### Authors

   * [**@lazywinadmin**](https://github.com/lazywinadmin)
   * [**@HowardWolosky**](https://github.com/HowardWolosky)

------

## [0.6.1](https://github.com/PowerShell/PowerShellForGitHub/tree/0.6.1) - (2018/12/13)

### Fixes

- Fixes a bug with checking Issues.  When trying to list all issues, it tried to speficially look
  for Issue 0.
  [[pr]](https://github.com/PowerShell/PowerShellForGitHub/pull/73) | [[cl]](https://github.com/PowerShell/PowerShellForGitHub/commit/bf6764080ce1291cfe2530a39ffd292f38b37440)

### Authors

   * [**@joseartrivera**](https://github.com/joseartrivera)

------

## [0.6.0](https://github.com/PowerShell/PowerShellForGitHub/tree/0.6.0) - (2018/12/13)

### Features

+ Completes all support for GitHub Issue API's:
  + Added support for the [Issue Event](https://developer.github.com/v3/issues/events/) API's.
    [[pr]](https://github.com/PowerShell/PowerShellForGitHub/pull/64) | [[cl]](https://github.com/PowerShell/PowerShellForGitHub/commit/06e25243086954013b50c1fa7e3eb11bc34a9501)
  + Added support for the [Issue Milestone](https://developer.github.com/v3/issues/milestones/) API's.
    [[pr]](https://github.com/PowerShell/PowerShellForGitHub/pull/62) | [[cl]](https://github.com/PowerShell/PowerShellForGitHub/commit/2bd244768d0bed85943e5e8375bb3f5bebdc763b)
  + Added support for the [Issue Label](https://developer.github.com/v3/issues/labels/) API's.
    [[pr]](https://github.com/PowerShell/PowerShellForGitHub/pull/59) | [[cl]](https://github.com/PowerShell/PowerShellForGitHub/commit/6c7355424828d5ada457bdbe2182c8fdf6845641)
+ Added new `LogRequestBody` configuration option to help with development, allowing you to see the
  exact body of the REST request being sent before it is sent over the wire.
  [[pr]](https://github.com/PowerShell/PowerShellForGitHub/pull/60) | [[cl]](https://github.com/PowerShell/PowerShellForGitHub/commit/98aec29d61bf013a153705079703ae027cc25c9f)

### Authors

   * [**@HowardWolosky**](https://github.com/HowardWolosky)
   * [**@joseartrivera**](https://github.com/joseartrivera)
   * [**@etgottli**](https://github.com/etgottli)

------

## [0.5.0](https://github.com/PowerShell/PowerShellForGitHub/tree/0.5.0) - (2018/11/30)

### Features

+ Added support for the [Issue Comment](https://developer.github.com/v3/issues/comments/) API's.
  [[pr]](https://github.com/PowerShell/PowerShellForGitHub/pull/53) | [[cl]](https://github.com/PowerShell/PowerShellForGitHub/commit/28b314bd7c0a810848e1acb3df43a1d83291be7b)
+ Added support for the [Issue Assignee](https://developer.github.com/v3/issues/assignees/) API's.
  [[pr]](https://github.com/PowerShell/PowerShellForGitHub/pull/54) | [[cl]](https://github.com/PowerShell/PowerShellForGitHub/commit/680696a833b3cc753e961fc8c723b0be9b39ecc2)

### Fixes

- Fixed bug that caused single or empty arrays returned within objects to be flattened
  (instead of remaining as arrays)
  [[pr]](https://github.com/PowerShell/PowerShellForGitHub/pull/56) | [[cl]](https://github.com/PowerShell/PowerShellForGitHub/commit/6cf344fb38485275f94b1e85c1a5f932e1b519c3)

### Authors

   * [**@HowardWolosky**](https://github.com/HowardWolosky)
   * [**@joseartrivera**](https://github.com/joseartrivera)

------

## [0.4.0](https://github.com/PowerShell/PowerShellForGitHub/tree/0.4.0) - (2018/11/16)

### Features

+ Added support for the [Repository Traffic API's](https://developer.github.com/v3/repos/traffic/).
  [[pr]](https://github.com/PowerShell/PowerShellForGitHub/pull/49) | [[cl]](https://github.com/PowerShell/PowerHellForGitHub/commit/8d2e76f9059f0939b892d08386fe43f0e2722bb0)

### Fixes

- Made NuGet dll retrieval more robust by preventing potential file access problems from being
  written to the error stream.
  [[pr]](https://github.com/PowerShell/PowerShellForGitHub/pull/48) | [[cl]](https://github.com/PowerShell/PowerHellForGitHub/commit/b614f4a0fbcb570ef462fea64f776ca85480de86)
- Prevented the possibility of Access Tokens from being written into the log file in plain text
  if explicitly passed-in
  [[pr]](https://github.com/PowerShell/PowerShellForGitHub/pull/50) | [[cl]](https://github.com/PowerShell/PowerHellForGitHub/commit/c6835f4cb1ef0e78e23a8195949eb9ad2555fd4a)

### Authors

   * [**@HowardWolosky**](https://github.com/HowardWolosky)
   * [**@joseartrivera**](https://github.com/joseartrivera)

------

## [0.3.1](https://github.com/PowerShell/PowerShellForGitHub/tree/0.3.1) - (2018/11/13)

### Fixes

- Minor static analysis issues fixed.
- Corrected name of the test file for `GitHubRepositoryForks`
- Ensured the `getParams` are used during execution of `Get-GitHubRepositoryFork`

More Info: [[pr]](https://github.com/PowerShell/PowerShellForGitHub/pull/42) | [[cl]](https://github.com/PowerShell/PowerHellForGitHub/commit/5703295d497f20fe8eec91d6ed47d126cc518592)

Author: [**@HowardWolosky**](https://github.com/HowardWolosky)

------

## [0.3.0](https://github.com/PowerShell/PowerShellForGitHub/tree/0.3.0) - (2018/11/13)

### Features

+ Added support for querying forks and creating new ones.

### Fixes

- Will only perform a retry when receiving a `202` response on a `GET` request.  Previously, it would
  retry regardless of the method of the request.

More Info: [[pr]](https://github.com/PowerShell/PowerShellForGitHub/pull/41) | [[cl]](https://github.com/PowerShell/PowerHellForGitHub/commit/1076239d7639497984a6e0b04df1e69019c4ec28)

### Authors

[**@HowardWolosky**](https://github.com/HowardWolosky)

------

## [0.2.0](https://github.com/PowerShell/PowerShellForGitHub/tree/0.2.0) - (2018/11/13)

### Features

+ Significant restructing and refactoring of entire module to make future expansion easier.
+ Significant documentation updates ([CHANGELOG](./CHANGELOG.md), [CONTRIBUTING.md](./CONTRIBUTING.md),
  [GOVERNANCE.md](./GOVERNANCE.md), [README.md](./README.md), [USAGE.md](./USAGE.md))
+ Added `Set-GitHubAuthentication` (and related methods) for securely caching the Access Token
+ Added `Set-GitHubConfiguration` (and related methods) to enable short and long-term configuration
  of the module.
+ Added ability to asynchronously see status update of REST requests.
+ Added logging and telemetry to the module (each can be disabled if desired).
+ Tests now auto-configure themselves across whatever account information is supplied in
  [Tests/Config/Settings.ps1](./Tests/Config/Settings.ps1)
+ Added support for a number of additional GitHub API's:
  + All [Miscellaneous API's](https://developer.github.com/v3/misc/)
  + Ability to fully query, update, remove, lock, and unlock Issues.
  + Enhanced pull request querying support
  + Ability tofully query, create, and remove Repositories, as well as transfer ownership,
    get tags, get/set topic and current used programming languages.
  + Enhanced user query support as well as being able update information for the current user.

### Fixes

- Made parameter ordering consistent across all functions (OwnerName is now first, then RepositoryName)
- Normalized all parameters to use SentenceCase
- All functions that can take a Uri or OwnerName/RepositoryName now support both options.
- Made all parameter names consistent across functions:
  - `GitHubAccessToken` -> `AccessToken`
  - `RepositoryUrl` -> `Uri`
  - `Organization` -> `OrganizationName`
  - `Repository` -> `RepositoryName`
  - `Owner` -> `OwnerName`
- Normalized usage of Verbose, Info and Error streams

### Functionality Modified from 0.1.0:

* `New-GitHubLabels` was renamed to `Set-GitHubLabel` and can now optionally take in the labels
  to apply to the Repository.
* `Get-GitHubIssueForRepository` has been removed and replaced with `Get-GitHubIssue`.
  The key difference between these two is that it no longer accepts multiple repositories as single
  input, and filtering on creation/closed date can be done after the fact piping the results into
  `Where-Object` now that the returned objects from `Get-GitHubIssue` have actual `[DateTime]` values
  for the date properties.  For an updated example of doing this, refer to [example usage](USAGE.md#querying-issues).
* `Get-GitHubWeeklyIssueForRepository` has been removed and functionally replaced by `Group-GitHubIssue`.
  For an updated example of using it, refer to [example usage](USAGE.md#querying-issues)
* `Get-GitHubTopIssueRepository` has been removed.  We have [updated examples](USAGE.md#querying-issues)
  for how to accomplish the same scenario.
* `Get-GitHubPullRequestForRepository` has been removed and replaced with `Get-GitHubPullRequest`.
  The key difference between these two is that it no longer accepts multiple repositories as single
  input, and filtering on creation/merged date can be done after the fact piping the results into
  `Where-Object` now that the returned objects from `Get-GitHubPullRequest` have actual `[DateTime]` values
  for the date properties.  For an updated example of doing this, refer to [example usage](USAGE.md#querying-pull-requests).
* `Get-GitHubWeeklyPullRequestForRepository` has been removed and functionally replaced by `Group-GitHubPullRequest`.
  For an updated example of using it, refer to [example usage](USAGE.md#querying-pull-requests)
* `Get-GitHubTopPullRequestRepository` has been removed.  We have [updated examples](USAGE.md#querying-pull-requests)
  for how to accomplish the same scenario.
* `Get-GitHubRepositoryNameFromUrl` and `GitHubRepositoryOwnerFromUrl` have been removed and
  functionally replaced by `Split-GitHubUri`
* `Get-GitHubRepositoryUniqueContributor` has been removed.  We have an
  [updated example](USAGE.md#querying-contributors) for how to accomplish the same scenario.
* `GitHubOrganizationRepository` has been removed.  You can now retrieve repositories for an
  organization via `Get-GitHubRepository -OrganizationName <name>`.
* `Get-GitHubAuthenticatedUser` has been replaced with `Get-GitHubUser -Current`.

More Info: [[pr]](https://github.com/PowerShell/PowerShellForGitHub/pull/39) | [[cl]](https://github.com/PowerShell/PowerHellForGitHub/commit/eb33688e5b8d688d28e8582b76b526da3c4428be)

### Authors

[**@HowardWolosky**](https://github.com/HowardWolosky)

------

## [0.1.0](https://github.com/PowerShell/PowerShellForGitHub/tree/0.1.0) - (2016/11/29)

### Features

+ Initial public release

More Info: [[cl]](https://github.com/PowerShell/PowerShellForGitHub/commit/6a3b400019d6a97ccc2f08a951fd4b2d09282eb5)

### Authors

[**@KarolKaczmarek**](https://github.com/KarolKaczmarek)
