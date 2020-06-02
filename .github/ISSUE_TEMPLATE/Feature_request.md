---
name: Feature request or suggestion
about: If you have an idea for a feature that this module is missing.
labels: triage needed, enhancement
assignees: ''
---

<!--
    Your feedback and support is greatly appreciated, thanks so much for contributing!

    Please provide information regarding your issue under each header below.
    If appropriate, your response to a header can be "N/A".

    You may remove this and all other comment block, but please keep the
    headers (the lines starting with '####').
-->
#### Feature Idea Summary
<!--
    A high-level summary of your idea.
    If you think you need to dive into more technical details,
    you can continue that discussion in the next section.
-->

#### Feature Idea Additional Details


#### Requested Assignment
<!--
    Some people just want to report a feature idea and let someone else implement it.
    Other people want to not only submit the feature idea, but implement it as well.
    Both scenarios are completely ok. We would just like to know which way you feel.
    Please replace this comment with one of the following options:

    - If possible, I would like to implement this.
    - I'm just suggesting this idea, but don't want to implement it.
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
