---
name: Bug or problem report
about: If you have a general question or request for help.
labels: triage needed, bug
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


#### Steps to reproduce the issue
```powershell
   # Include your repro steps here
```

#### Verbose logs showing the problem
<!--
    If the problem is consistent, you can grab this from the console by re-running your
    command and adding "-Verbose" to the end.  If it's not consistent, you can grab the
    previous logs from your log file: (Get-GitHubConfiguration -Name LogPath)
-->


#### Suggested solution to the issue
<!--
    It's totally ok if you don't have one.  This section is here for those users who
    have decided to dive into the code to see what might be going on.
-->


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
