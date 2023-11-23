# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

@{
    GUID = '9e8dfd44-f782-445a-883c-70614f71519c'
    Author = 'Microsoft Corporation'
    CompanyName = 'Microsoft Corporation'
    Copyright = 'Copyright (C) Microsoft Corporation.  All rights reserved.'

    ModuleVersion = '0.17.0'
    Description = 'PowerShell wrapper for GitHub API'

    # Script module or binary module file associated with this manifest.
    RootModule = 'PowerShellForGitHub.psm1'

    # Format files (.ps1xml) to be loaded when importing this module
    FormatsToProcess = @(
        'Formatters/GitHubBranches.Format.ps1xml',
        'Formatters/GitHubCodespaces.Format.ps1xml',
        'Formatters/GitHubDeployments.Format.ps1xml',
        'Formatters/GitHubGistComments.Format.ps1xml',
        'Formatters/GitHubGists.Format.ps1xml',
        'Formatters/GitHubReleases.Format.ps1xml'
        'Formatters/GitHubRepositories.Format.ps1xml'
        'Formatters/GitHubTeams.Format.ps1xml'
    )

    # Modules to import as nested modules of the module specified in RootModule/ModuleToProcess
    NestedModules = @(
        # Ideally this list would be kept completely alphabetical, but other scripts (like
        # GitHubConfiguration.ps1) depend on some of the code in Helpers being around at load time.
        'Helpers.ps1',
        'GitHubConfiguration.ps1',

        'GitHubAnalytics.ps1',
        'GitHubAssignees.ps1',
        'GitHubBranches.ps1',
        'GitHubCodespaces.ps1',
        'GitHubCore.ps1',
        'GitHubContents.ps1',
        'GitHubEvents.ps1',
        'GitHubGistComments.ps1',
        'GitHubGists.ps1',
        'GitHubGraphQl.ps1',
        'GitHubIssueComments.ps1',
        'GitHubIssues.ps1',
        'GitHubLabels.ps1',
        'GitHubMilestones.ps1',
        'GitHubMiscellaneous.ps1',
        'GitHubOrganizations.ps1',
        'GitHubProjects.ps1',
        'GitHubProjectCards.ps1',
        'GitHubProjectColumns.ps1',
        'GitHubPullRequests.ps1',
        'GitHubReactions.ps1',
        'GitHubReleases.ps1',
        'GitHubRepositories.ps1',
        'GitHubRepositoryForks.ps1',
        'GitHubRepositoryTraffic.ps1',
        'GitHubTeams.ps1',
        'GitHubUsers.ps1',
        'GitHubDeployments.ps1',
        'Telemetry.ps1',
        'UpdateCheck.ps1')

    # Minimum version of the Windows PowerShell engine required by this module
    PowerShellVersion = '4.0'

    # Functions to export from this module
    FunctionsToExport = @(
        'Add-GitHubAssignee',
        'Add-GitHubIssueLabel',
        'Add-GitHubGistStar',
        'Backup-GitHubConfiguration',
        'Clear-GitHubAuthentication',
        'ConvertFrom-GitHubMarkdown',
        'Copy-GitHubGist',
        'Disable-GitHubRepositorySecurityFix',
        'Disable-GitHubRepositoryVulnerabilityAlert',
        'Enable-GitHubRepositorySecurityFix',
        'Enable-GitHubRepositoryVulnerabilityAlert',
        'Get-GitHubAssignee',
        'Get-GitHubCloneTraffic',
        'Get-GitHubCodeOfConduct',
        'Get-GitHubCodespace',
        'Get-GitHubConfiguration',
        'Get-GitHubContent',
        'Get-GitHubDeploymentEnvironment',
        'Get-GitHubEmoji',
        'Get-GitHubEvent',
        'Get-GitHubGist',
        'Get-GitHubGistComment',
        'Get-GitHubGitIgnore',
        'Get-GitHubIssue',
        'Get-GitHubIssueComment',
        'Get-GitHubIssueTimeline',
        'Get-GitHubLabel',
        'Get-GitHubLicense',
        'Get-GitHubMilestone',
        'Get-GitHubOrganizationMember',
        'Get-GitHubPathTraffic',
        'Get-GitHubProject',
        'Get-GitHubProjectCard',
        'Get-GitHubProjectColumn',
        'Get-GitHubPullRequest',
        'Get-GitHubRateLimit',
        'Get-GitHubReaction',
        'Get-GitHubReferrerTraffic',
        'Get-GitHubRelease',
        'Get-GitHubReleaseAsset',
        'Get-GitHubRepository',
        'Get-GitHubRepositoryActionsPermission',
        'Get-GitHubRepositoryBranch',
        'Get-GitHubRepositoryBranchPatternProtectionRule',
        'Get-GitHubRepositoryBranchProtectionRule',
        'Get-GitHubRepositoryCollaborator',
        'Get-GitHubRepositoryContributor',
        'Get-GitHubRepositoryFork',
        'Get-GitHubRepositoryLanguage',
        'Get-GitHubRepositoryTag',
        'Get-GitHubRepositoryTeamPermission',
        'Get-GitHubRepositoryTopic',
        'Get-GitHubRepositoryUniqueContributor',
        'Get-GitHubTeam',
        'Get-GitHubTeamMember',
        'Get-GitHubUser',
        'Get-GitHubUserContextualInformation',
        'Get-GitHubViewTraffic',
        'Group-GitHubIssue',
        'Group-GitHubPullRequest',
        'Initialize-GitHubLabel',
        'Invoke-GHGraphQl',
        'Invoke-GHRestMethod',
        'Invoke-GHRestMethodMultipleResult',
        'Join-GitHubUri',
        'Lock-GitHubIssue',
        'Move-GitHubProjectCard',
        'Move-GitHubProjectColumn',
        'Move-GitHubRepositoryOwnership',
        'New-GitHubCodespace',
        'New-GitHubDeploymentEnvironment',
        'New-GitHubGist',
        'New-GitHubGistComment',
        'New-GitHubIssue',
        'New-GitHubIssueComment',
        'New-GitHubLabel',
        'New-GitHubMilestone',
        'New-GitHubProject',
        'New-GitHubProjectCard',
        'New-GitHubProjectColumn',
        'New-GitHubPullRequest',
        'New-GitHubRelease',
        'New-GitHubReleaseAsset',
        'New-GitHubRepository',
        'New-GitHubRepositoryFromTemplate',
        'New-GitHubRepositoryBranch',
        'New-GitHubRepositoryBranchPatternProtectionRule',
        'New-GitHubRepositoryBranchProtectionRule',
        'New-GitHubRepositoryFork',
        'New-GitHubTeam',
        'Remove-GitHubAssignee',
        'Remove-GitHubCodespace',
        'Remove-GitHubComment',
        'Remove-GitHubDeploymentEnvironment'
        'Remove-GitHubGist',
        'Remove-GitHubGistComment',
        'Remove-GitHubGistFile',
        'Remove-GitHubGistStar',
        'Remove-GitHubIssueComment',
        'Remove-GitHubIssueLabel',
        'Remove-GitHubLabel',
        'Remove-GitHubMilestone',
        'Remove-GitHubProject',
        'Remove-GitHubProjectCard',
        'Remove-GitHubProjectColumn',
        'Remove-GitHubReaction',
        'Remove-GitHubRelease',
        'Remove-GitHubReleaseAsset',
        'Remove-GitHubRepository',
        'Remove-GitHubRepositoryBranch'
        'Remove-GitHubRepositoryBranchPatternProtectionRule',
        'Remove-GitHubRepositoryBranchProtectionRule',
        'Remove-GitHubRepositoryTeamPermission',
        'Remove-GitHubTeam',
        'Rename-GitHubGistFile',
        'Rename-GitHubRepository',
        'Rename-GitHubTeam',
        'Reset-GitHubConfiguration',
        'Restore-GitHubConfiguration',
        'Set-GitHubAuthentication',
        'Set-GitHubConfiguration',
        'Set-GitHubContent',
        'Set-GitHubGist',
        'Set-GitHubGistComment',
        'Set-GitHubGistFile',
        'Set-GitHubGistStar',
        'Set-GitHubIssue',
        'Set-GitHubIssueComment',
        'Set-GitHubIssueLabel',
        'Set-GitHubLabel',
        'Set-GitHubMilestone',
        'Set-GitHubProfile',
        'Set-GitHubProject',
        'Set-GitHubProjectCard',
        'Set-GitHubProjectColumn',
        'Set-GitHubReaction',
        'Set-GitHubRelease',
        'Set-GitHubReleaseAsset',
        'Set-GitHubRepository',
        'Set-GitHubRepositoryActionsPermission',
        'Set-GitHubRepositoryTeamPermission',
        'Set-GitHubRepositoryTopic',
        'Set-GitHubTeam',
        'Split-GitHubUri',
        'Start-GitHubCodespace',
        'Stop-GitHubCodespace',
        'Test-GitHubAssignee',
        'Test-GitHubAuthenticationConfigured',
        'Test-GitHubGistStar',
        'Test-GitHubOrganizationMember',
        'Test-GitHubRepositoryVulnerabilityAlert',
        'Unlock-GitHubIssue'
    )

    AliasesToExport = @(
        'Add-GitHubGistFile',
        'Delete-GitHubAsset',
        'Delete-GitHubBranch',
        'Delete-GitHubComment',
        'Delete-GitHubDeploymentEnvironment',
        'Delete-GitHubGist',
        'Delete-GitHubGistComment',
        'Delete-GitHubGistFile',
        'Delete-GitHubIssueComment',
        'Delete-GitHubLabel',
        'Delete-GitHubMilestone',
        'Delete-GitHubProject',
        'Delete-GitHubProjectCard',
        'Delete-GitHubProjectColumn'
        'Delete-GitHubReaction',
        'Delete-GitHubRelease',
        'Delete-GitHubReleaseAsset',
        'Delete-GitHubRepository',
        'Delete-GitHubRepositoryBranch',
        'Delete-GitHubRepositoryBranchPatternProtectionRule',
        'Delete-GitHubRepositoryBranchProtectionRule',
        'Delete-GitHubRepositoryTeamPermission',
        'Delete-GitHubTeam',
        'Fork-GitHubGist',
        'Get-GitHubAsset',
        'Get-GitHubBranch',
        'Get-GitHubComment',
        'New-GitHubAsset',
        'New-GitHubAssignee',
        'New-GitHubBranch',
        'New-GitHubComment',
        'Remove-GitHubAsset',
        'Remove-GitHubBranch'
        'Remove-GitHubComment',
        'Set-GitHubAsset',
        'Set-GitHubComment',
        'Set-GitHubDeploymentEnvironment',
        'Star-GitHubGist',
        'Transfer-GitHubRepositoryOwnership'
        'Unstar-GitHubGist'
        'Update-GitHubIssue',
        'Update-GitHubLabel',
        'Update-GitHubCurrentUser',
        'Update-GitHubRepository'
    )

    # Cmdlets to export from this module
    # CmdletsToExport = '*'

    # Variables to export from this module
    # VariablesToExport = '*'

    # Private data to pass to the module specified in RootModule/ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
    PrivateData = @{

        PSData = @{

            # Tags applied to this module. These help with module discovery in online galleries.
            Tags = @('GitHub', 'API', 'PowerShell')

            # A URL to the license for this module.
            LicenseUri = 'https://aka.ms/PowerShellForGitHub_License'

            # A URL to the main website for this project.
            ProjectUri = 'https://aka.ms/PowerShellForGitHub'

            # A URL to an icon representing this module.
            # IconUri = ''

            # ReleaseNotes of this module
            ReleaseNotes = 'https://github.com/microsoft/PowerShellForGitHub/blob/master/CHANGELOG.md'
        }
    }

    # Default prefix for commands exported from this module. Override the default prefix using Import-Module -Prefix.
    # DefaultCommandPrefix = 'GH'

    # Modules that must be imported into the global environment prior to importing this module
    # RequiredModules = @()

    # Assemblies that must be loaded prior to importing this module
    # RequiredAssemblies = @()

    # Script files (.ps1) that are run in the caller's environment prior to importing this module.
    # ScriptsToProcess = @()

    # List of all modules packaged with this module
    # ModuleList = @()

    # List of all files packaged with this module
    # FileList = @()

    # HelpInfo URI of this module
    # HelpInfoURI = ''
}
