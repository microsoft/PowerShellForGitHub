---
name: Documentation issue
about: If you found a problem with documentation in the module or in this repo.
labels: triage needed, documentation
assignees: ''
---

<!--
    Your feedback and support is greatly appreciated, thanks so much for contributing!

    Please provide information regarding your issue under each header below.
    If appropriate, your response to a header can be "N/A".

    You may remove this and all other comment block, but please keep the
    headers (the lines starting with '####').
-->
#### Issue Details
<!--
    If the issue is with a command, be sure to specify the command name.
    If the issue is with a markdown file in the repo, be sure to specify the markdown file name.
-->

#### Suggested solution to the issue


#### Requested Assignment
<!--
    Some people just want to report a bug and let someone else fix it.
    Other people want to not only submit the bug report, but fix it as well.
    Both scenarios are completely ok. We would just like to know which way you feel.
    Please replace this comment with one of the following options:

    - If possible, I would like to fix this.
    - I'm just reporting this problem, but don't want to fix it.
-->


#### Operating System
<!--
    Please provide as much as possible about your system.
    If this works on your device, please replace this whole comment with the output of this command:

        Get-ComputerInfo -Property @(
            'OsName',
            'OsOperatingSystemSKU',
            'OSArchitecture',
            'WindowsVersion',
            'WindowsBuildLabEx',
            'OsLanguage',
            'OsMuiLanguages')

    Otherwise, please replace this whole comment with the output of this command:

        [ordered]@{
            'OSVersion' = ([System.Environment]::OSversion).VersionString
            'Is 64-bit' =  [System.Environment]::Is64BitOperatingSystem
            'Current culture' = (Get-Culture).Name
            'Current UI culture' = (Get-UICulture).Name
        }
-->


#### PowerShell Version
<!--
    Please replace this whole comment with the output of this command:

        $PSVersionTable
-->


#### Module Version
<!--
    Please replace this whole comment with the output of this command:

        @(
            "Running: $((Get-Module -Name PowerShellForGitHub) | Select-Object -ExpandProperty Version)",
            "Installed: $((Get-Module -Name PowerShellForGitHub -ListAvailable) | Select-Object -ExpandProperty Version)"
        ) -join [Environment]::NewLine
-->
