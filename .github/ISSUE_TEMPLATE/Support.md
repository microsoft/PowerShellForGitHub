---
name: Support request or question
about: If you have a general question or request for help.
labels: triage needed, support
assignees: ''
---

<!--
    Your feedback and support is greatly appreciated, thanks so much for contributing!

    Please provide information regarding your issue under each header below.
    If appropriate, your response to a header can be "N/A".

    You may remove this and all other comment block, but please keep the
    headers (the lines starting with '####').
-->
#### A description of your problem or question


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
    This section may not make sense at all for your question/problem.  If not, just write N/A.
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
