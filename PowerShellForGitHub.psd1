# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

@{
    GUID = '9e8dfd44-f782-445a-883c-70614f71519c'
    Author = 'Microsoft Corporation'
    CompanyName = 'Microsoft Corporation'
    Copyright = 'Copyright (C) Microsoft Corporation.  All rights reserved.'

    ModuleVersion = '0.9.1'
    Description = 'PowerShell wrapper for GitHub API'

    # Script module or binary module file associated with this manifest.
    RootModule = 'PowerShellForGitHub.psm1'

    # Modules to import as nested modules of the module specified in RootModule/ModuleToProcess
    NestedModules = @(
        # Ideally this list would be kept completely alphabetical, but other scripts (like
        # GitHubConfiguration.ps1) depend on some of the code in Helpers being around at load time.
        'Helpers.ps1',
        'GitHubConfiguration.ps1',

        'GitHubAnalytics.ps1',
        'GitHubAssignees.ps1',
        'GitHubBranches.ps1',
        'GitHubCore.ps1',
        'GitHubComments.ps1',
        'GitHubEvents.ps1',
        'GitHubIssues.ps1',
        'GitHubLabels.ps1',
        'GitHubMilestones.ps1',
        'GitHubMiscellaneous.ps1',
        'GitHubOrganizations.ps1',
        'GitHubPullRequests.ps1',
        'GitHubReleases.ps1',
        'GitHubRepositories.ps1',
        'GitHubRepositoryForks.ps1',
        'GitHubRepositoryTraffic.ps1',
        'GitHubTeams.ps1',
        'GitHubUsers.ps1',
        'NugetTools.ps1',
        'Telemetry.ps1')

    # Minimum version of the Windows PowerShell engine required by this module
    PowerShellVersion = '4.0'

    # Functions to export from this module
    FunctionsToExport = @(
        'Add-GitHubIssueLabel',
        'Backup-GitHubConfiguration',
        'Clear-GitHubAuthentication',
        'ConvertFrom-GitHubMarkdown',
        'Get-GitHubAssignee',
        'Get-GitHubCloneTraffic',
        'Get-GitHubCodeOfConduct',
        'Get-GitHubComment',
        'Get-GitHubConfiguration',
        'Get-GitHubEmoji',
        'Get-GitHubEvent',
        'Get-GitHubGitIgnore',
        'Get-GitHubIssue',
        'Get-GitHubIssueTimeline',
        'Get-GitHubLabel',
        'Get-GitHubLicense',
        'Get-GitHubMilestone',
        'Get-GitHubOrganizationMember',
        'Get-GitHubPathTraffic',
        'Get-GitHubPullRequest',
        'Get-GitHubRateLimit',
        'Get-GitHubReferrerTraffic',
        'Get-GitHubRelease',
        'Get-GitHubRepository',
        'Get-GitHubRepositoryBranch',
        'Get-GitHubRepositoryCollaborator',
        'Get-GitHubRepositoryContributor',
        'Get-GitHubRepositoryFork',
        'Get-GitHubRepositoryLanguage',
        'Get-GitHubRepositoryTag',
        'Get-GitHubRepositoryTopic',
        'Get-GitHubRepositoryUniqueContributor',
        'Get-GitHubTeam',
        'Get-GitHubTeamMember',
        'Get-GitHubUser',
        'Get-GitHubUserContextualInformation',
        'Get-GitHubViewTraffic',
        'Group-GitHubIssue',
        'Invoke-GHRestMethod',
        'Invoke-GHRestMethodMultipleResult',
        'Lock-GitHubIssue',
        'Move-GitHubRepositoryOwnership',
        'New-GithubAssignee',
        'New-GitHubComment',
        'New-GitHubIssue',
        'New-GitHubLabel',
        'New-GitHubMilestone',
        'New-GitHubPullRequest',
        'New-GitHubRepository',
        'New-GitHubRepositoryFork',
        'Remove-GithubAssignee',
        'Remove-GitHubComment',
        'Remove-GitHubIssueLabel',
        'Remove-GitHubLabel',
        'Remove-GitHubMilestone',
        'Remove-GitHubRepository',
        'Reset-GitHubConfiguration',
        'Restore-GitHubConfiguration',
        'Set-GitHubAuthentication',
        'Set-GitHubComment',
        'Set-GitHubConfiguration',
        'Set-GitHubIssueLabel',
        'Set-GitHubLabel',
        'Set-GitHubMilestone',
        'Set-GitHubRepositoryTopic',
        'Split-GitHubUri',
        'Test-GitHubAssignee',
        'Test-GitHubAuthenticationConfigured',
        'Test-GitHubOrganizationMember',
        'Unlock-GitHubIssue',
        'Update-GitHubCurrentUser',
        'Update-GitHubIssue',
        'Update-GitHubLabel',
        'Update-GitHubRepository'
    )

    AliasesToExport = @(
        'Delete-GitHubComment',
        'Delete-GitHubLabel',
        'Delete-GitHubMilestone',
        'Delete-GitHubRepository',
        'Get-GitHubBranch',
        'Transfer-GitHubRepositoryOwnership'
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
            # ReleaseNotes = ''
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

