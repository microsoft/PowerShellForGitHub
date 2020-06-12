# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

@{
    GitHubLabelTypeName = 'GitHub.Label'
 }.GetEnumerator() | ForEach-Object {
     Set-Variable -Scope Script -Option ReadOnly -Name $_.Key -Value $_.Value
 }

filter Get-GitHubLabel
{
<#
    .SYNOPSIS
        Retrieve label(s) of a given GitHub repository.

    .DESCRIPTION
        Retrieve label(s) of a given GitHub repository.

        The Git repo for this module can be found here: http://aka.ms/PowerShellForGitHub

    .PARAMETER OwnerName
        Owner of the repository.
        If not supplied here, the DefaultOwnerName configuration property value will be used.

    .PARAMETER RepositoryName
        Name of the repository.
        If not supplied here, the DefaultRepositoryName configuration property value will be used.

    .PARAMETER Uri
        Uri for the repository.
        The OwnerName and RepositoryName will be extracted from here instead of needing to provide
        them individually.

    .PARAMETER Name
        Name of the specific label to be retrieved.  If not supplied, all labels will be retrieved.
        Emoji and codes are supported.  For more information, see here: https://www.webpagefx.com/tools/emoji-cheat-sheet/

    .PARAMETER Issue
        If provided, will return all of the labels for this particular issue.

    .PARAMETER Milestone
        If provided, will return all of the labels for this particular milestone.

    .PARAMETER AccessToken
        If provided, this will be used as the AccessToken for authentication with the
        REST Api.  Otherwise, will attempt to use the configured value or will run unauthenticated.

    .PARAMETER NoStatus
        If this switch is specified, long-running commands will run on the main thread
        with no commandline status update.  When not specified, those commands run in
        the background, enabling the command prompt to provide status information.
        If not supplied here, the DefaultNoStatus configuration property value will be used.

    .OUTPUTS
        GitHub.Label

    .EXAMPLE
        Get-GitHubLabel -OwnerName Microsoft -RepositoryName PowerShellForGitHub

        Gets the information for every label from the Microsoft\PowerShellForGitHub project.

    .EXAMPLE
        Get-GitHubLabel -OwnerName Microsoft -RepositoryName PowerShellForGitHub -LabelName TestLabel

        Gets the information for the label named "TestLabel" from the Microsoft\PowerShellForGitHub
        project.
#>
    [CmdletBinding(
        SupportsShouldProcess,
        DefaultParameterSetName='Elements')]
    [OutputType({$script:GitHubLabelTypeName})]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSShouldProcess", "", Justification="Methods called within here make use of PSShouldProcess, and the switch is passed on to them inherently.")]
    param(
        [Parameter(Mandatory, ParameterSetName='Elements')]
        [Parameter(Mandatory, ParameterSetName='NameElements')]
        [Parameter(Mandatory, ParameterSetName='IssueElements')]
        [Parameter(Mandatory, ParameterSetName='MilestoneElements')]
        [string] $OwnerName,

        [Parameter(Mandatory, ParameterSetName='Elements')]
        [Parameter(Mandatory, ParameterSetName='NameElements')]
        [Parameter(Mandatory, ParameterSetName='IssueElements')]
        [Parameter(Mandatory, ParameterSetName='MilestoneElements')]
        [string] $RepositoryName,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ParameterSetName='Uri')]
        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ParameterSetName='NameUri')]
        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ParameterSetName='IssueUri')]
        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ParameterSetName='MilestoneUri')]
        [Alias('RepositoryUrl')]
        [string] $Uri,

        [Parameter(Mandatory, ParameterSetName='NameUri')]
        [Parameter(Mandatory, ParameterSetName='NameElements')]
        [Alias('LabelName')]
        [string] $Name,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ParameterSetName='IssueUri')]
        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ParameterSetName='IssueElements')]
        [Alias('IssueId')]
        [int64] $Issue,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ParameterSetName='MilestoneUri')]
        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ParameterSetName='MilestoneElements')]
        [Alias('MilestoneId')]
        [int64] $Milestone,

        [string] $AccessToken,

        [switch] $NoStatus
    )

    Write-InvocationLog

    $elements = Resolve-RepositoryElements
    $OwnerName = $elements.ownerName
    $RepositoryName = $elements.repositoryName

    $telemetryProperties = @{
        'OwnerName' = (Get-PiiSafeString -PlainText $OwnerName)
        'RepositoryName' = (Get-PiiSafeString -PlainText $RepositoryName)
    }

    $uriFragment = [String]::Empty
    $description = [String]::Empty

    if ($PSBoundParameters.ContainsKey('Issue'))
    {
        $uriFragment = "/repos/$OwnerName/$RepositoryName/issues/$Issue/labels"
        $description = "Getting labels for Issue $Issue in $RepositoryName"
    }
    elseif ($PSBoundParameters.ContainsKey('Milestone'))
    {
        $uriFragment = "/repos/$OwnerName/$RepositoryName/milestones/$Milestone/labels"
        $description = "Getting labels for Milestone $Milestone in $RepositoryName"
    }
    else
    {
        $uriFragment = "repos/$OwnerName/$RepositoryName/labels/$Name"

        if ($PSBoundParameters.ContainsKey('Name'))
        {
            $description =  "Getting label $Name for $RepositoryName"
        }
        else
        {
            $description = "Getting labels for $RepositoryName"
        }
    }

    $params = @{
        'UriFragment' = $uriFragment
        'Description' =  $description
        'AcceptHeader' = 'application/vnd.github.symmetra-preview+json'
        'AccessToken' = $AccessToken
        'TelemetryEventName' = $MyInvocation.MyCommand.Name
        'TelemetryProperties' = $telemetryProperties
        'NoStatus' = (Resolve-ParameterWithDefaultConfigurationValue -Name NoStatus -ConfigValueName DefaultNoStatus)
    }

    if (-not [String]::IsNullOrWhiteSpace($Name))
    {
        $params["Description"] =  "Getting label $Name for $RepositoryName"
    }

    return (Invoke-GHRestMethodMultipleResult @params |
        Add-GitHubLabelAdditionalProperties -TypeName $script:GitHubLabelTypeName -OwnerName $OwnerName -RepositoryName $RepositoryName)
}

filter New-GitHubLabel
{
<#
    .SYNOPSIS
        Create a new label on a given GitHub repository.

    .DESCRIPTION
        Create a new label on a given GitHub repository.

        The Git repo for this module can be found here: http://aka.ms/PowerShellForGitHub

    .PARAMETER OwnerName
        Owner of the repository.
        If not supplied here, the DefaultOwnerName configuration property value will be used.

    .PARAMETER RepositoryName
        Name of the repository.
        If not supplied here, the DefaultRepositoryName configuration property value will be used.

    .PARAMETER Uri
        Uri for the repository.
        The OwnerName and RepositoryName will be extracted from here instead of needing to provide
        them individually.

    .PARAMETER Name
        Name of the label to be created.
        Emoji and codes are supported.  For more information, see here: https://www.webpagefx.com/tools/emoji-cheat-sheet/

    .PARAMETER Color
        Color (in HEX) for the new label, without the leading # sign.

    .PARAMETER Description
        A short description of the label.

    .PARAMETER AccessToken
        If provided, this will be used as the AccessToken for authentication with the
        REST Api.  Otherwise, will attempt to use the configured value or will run unauthenticated.

    .PARAMETER NoStatus
        If this switch is specified, long-running commands will run on the main thread
        with no commandline status update.  When not specified, those commands run in
        the background, enabling the command prompt to provide status information.
        If not supplied here, the DefaultNoStatus configuration property value will be used.

    .OUTPUTS
        GitHub.Label

    .EXAMPLE
        New-GitHubLabel -OwnerName Microsoft -RepositoryName PowerShellForGitHub -Name TestLabel -Color BBBBBB

        Creates a new, grey-colored label called "TestLabel" in the PowerShellForGitHub project.
#>
    [CmdletBinding(
        SupportsShouldProcess,
        DefaultParameterSetName='Elements')]
    [OutputType({$script:GitHubLabelTypeName})]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSShouldProcess", "", Justification="Methods called within here make use of PSShouldProcess, and the switch is passed on to them inherently.")]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSReviewUnusedParameter", "", Justification="One or more parameters (like NoStatus) are only referenced by helper methods which get access to it from the stack via Get-Variable -Scope 1.")]
    param(
        [Parameter(ParameterSetName='Elements')]
        [string] $OwnerName,

        [Parameter(ParameterSetName='Elements')]
        [string] $RepositoryName,

        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName='Uri')]
        [Alias('RepositoryUrl')]
        [string] $Uri,

        [Parameter(Mandatory)]
        [Alias('LabelName')]
        [string] $Name,

        [Parameter(Mandatory)]
        [ValidateScript({if ($_ -match '^#?[ABCDEF0-9]{6}$') { $true } else { throw "Color must be provided in hex." }})]
        [Alias('LabelColor')]
        [string] $Color = "EEEEEE",

        [string] $Description,

        [string] $AccessToken,

        [switch] $NoStatus
    )

    Write-InvocationLog

    $elements = Resolve-RepositoryElements
    $OwnerName = $elements.ownerName
    $RepositoryName = $elements.repositoryName

    $telemetryProperties = @{
        'OwnerName' = (Get-PiiSafeString -PlainText $OwnerName)
        'RepositoryName' = (Get-PiiSafeString -PlainText $RepositoryName)
    }

    # Be robust to users who choose to provide a color in hex by specifying the leading # sign
    # (by just stripping it out).
    if ($Color.StartsWith('#'))
    {
        $Color = $Color.Substring(1)
    }

    $hashBody = @{
        'name' = $Name
        'color' = $Color
        'description' = $Description
    }

    $params = @{
        'UriFragment' = "repos/$OwnerName/$RepositoryName/labels"
        'Body' = (ConvertTo-Json -InputObject $hashBody)
        'Method' = 'Post'
        'Description' =  "Creating label $Name in $RepositoryName"
        'AcceptHeader' = 'application/vnd.github.symmetra-preview+json'
        'AccessToken' = $AccessToken
        'TelemetryEventName' = $MyInvocation.MyCommand.Name
        'TelemetryProperties' = $telemetryProperties
        'NoStatus' = (Resolve-ParameterWithDefaultConfigurationValue -Name NoStatus -ConfigValueName DefaultNoStatus)
    }

    return (Invoke-GHRestMethod @params |
        Add-GitHubLabelAdditionalProperties -TypeName $script:GitHubLabelTypeName -OwnerName $OwnerName -RepositoryName $RepositoryName)
}

filter Remove-GitHubLabel
{
<#
    .SYNOPSIS
        Deletes a label from a given GitHub repository.

    .DESCRIPTION
        Deletes a label from a given GitHub repository.

        The Git repo for this module can be found here: http://aka.ms/PowerShellForGitHub

    .PARAMETER OwnerName
        Owner of the repository.
        If not supplied here, the DefaultOwnerName configuration property value will be used.

    .PARAMETER RepositoryName
        Name of the repository.
        If not supplied here, the DefaultRepositoryName configuration property value will be used.

    .PARAMETER Uri
        Uri for the repository.
        The OwnerName and RepositoryName will be extracted from here instead of needing to provide
        them individually.

    .PARAMETER Name
        Name of the label to be deleted.
        Emoji and codes are supported.  For more information, see here: https://www.webpagefx.com/tools/emoji-cheat-sheet/

    .PARAMETER Force
        If this switch is specified, you will not be prompted for confirmation of command execution.

    .PARAMETER AccessToken
        If provided, this will be used as the AccessToken for authentication with the
        REST Api.  Otherwise, will attempt to use the configured value or will run unauthenticated.

    .PARAMETER NoStatus
        If this switch is specified, long-running commands will run on the main thread
        with no commandline status update.  When not specified, those commands run in
        the background, enabling the command prompt to provide status information.
        If not supplied here, the DefaultNoStatus configuration property value will be used.

    .EXAMPLE
        Remove-GitHubLabel -OwnerName Microsoft -RepositoryName PowerShellForGitHub -Name TestLabel

        Removes the label called "TestLabel" from the PowerShellForGitHub project.

    .EXAMPLE
        Remove-GitHubLabel -OwnerName Microsoft -RepositoryName PowerShellForGitHub -Name TestLabel -Confirm:$false

        Removes the label called "TestLabel" from the PowerShellForGitHub project. Will not prompt for confirmation, as -Confirm:$false was specified.

    .EXAMPLE
        Remove-GitHubLabel -OwnerName Microsoft -RepositoryName PowerShellForGitHub -Name TestLabel -Force

        Removes the label called "TestLabel" from the PowerShellForGitHub project. Will not prompt for confirmation, as -Force was specified.
#>
    [CmdletBinding(
        SupportsShouldProcess,
        DefaultParameterSetName='Elements',
        ConfirmImpact="High")]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSReviewUnusedParameter", "", Justification="One or more parameters (like NoStatus) are only referenced by helper methods which get access to it from the stack via Get-Variable -Scope 1.")]
    [Alias('Delete-GitHubLabel')]
    param(
        [Parameter(ParameterSetName='Elements')]
        [string] $OwnerName,

        [Parameter(ParameterSetName='Elements')]
        [string] $RepositoryName,

        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName='Uri')]
        [Alias('RepositoryUrl')]
        [string] $Uri,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [Alias('LabelName')]
        [string] $Name,

        [switch] $Force,

        [string] $AccessToken,

        [switch] $NoStatus
    )

    Write-InvocationLog

    $elements = Resolve-RepositoryElements
    $OwnerName = $elements.ownerName
    $RepositoryName = $elements.repositoryName

    $telemetryProperties = @{
        'OwnerName' = (Get-PiiSafeString -PlainText $OwnerName)
        'RepositoryName' = (Get-PiiSafeString -PlainText $RepositoryName)
    }

    if ($Force -and (-not $Confirm))
    {
        $ConfirmPreference = 'None'
    }

    if ($PSCmdlet.ShouldProcess($Name, "Remove label"))
    {
        $params = @{
            'UriFragment' = "repos/$OwnerName/$RepositoryName/labels/$Name"
            'Method' = 'Delete'
            'Description' =  "Deleting label $Name from $RepositoryName"
            'AcceptHeader' = 'application/vnd.github.symmetra-preview+json'
            'AccessToken' = $AccessToken
            'TelemetryEventName' = $MyInvocation.MyCommand.Name
            'TelemetryProperties' = $telemetryProperties
            'NoStatus' = (Resolve-ParameterWithDefaultConfigurationValue -Name NoStatus -ConfigValueName DefaultNoStatus)
        }

        return Invoke-GHRestMethod @params
    }
}

filter Update-GitHubLabel
{
<#
    .SYNOPSIS
        Updates an existing label on a given GitHub repository.

    .DESCRIPTION
        Updates an existing label on a given GitHub repository.

        The Git repo for this module can be found here: http://aka.ms/PowerShellForGitHub

    .PARAMETER OwnerName
        Owner of the repository.
        If not supplied here, the DefaultOwnerName configuration property value will be used.

    .PARAMETER RepositoryName
        Name of the repository.
        If not supplied here, the DefaultRepositoryName configuration property value will be used.

    .PARAMETER Uri
        Uri for the repository.
        The OwnerName and RepositoryName will be extracted from here instead of needing to provide
        them individually.

    .PARAMETER Name
        Current name of the label to be updated.
        Emoji and codes are supported.  For more information, see here: https://www.webpagefx.com/tools/emoji-cheat-sheet/

    .PARAMETER NewName
        New name for the label being updated.
        Emoji and codes are supported.  For more information, see here: https://www.webpagefx.com/tools/emoji-cheat-sheet/

    .PARAMETER Color
        Color (in HEX) for the new label, without the leading # sign.

    .PARAMETER Description
        A short description of the label.

    .PARAMETER AccessToken
        If provided, this will be used as the AccessToken for authentication with the
        REST Api.  Otherwise, will attempt to use the configured value or will run unauthenticated.

    .PARAMETER NoStatus
        If this switch is specified, long-running commands will run on the main thread
        with no commandline status update.  When not specified, those commands run in
        the background, enabling the command prompt to provide status information.
        If not supplied here, the DefaultNoStatus configuration property value will be used.

    .OUTPUTS
        GitHub.Label

    .EXAMPLE
        Update-GitHubLabel -OwnerName Microsoft -RepositoryName PowerShellForGitHub -Name TestLabel -NewName NewTestLabel -LabelColor BBBB00

        Updates the existing label called TestLabel in the PowerShellForGitHub project to be called
        'NewTestLabel' and be colored yellow.
#>
    [CmdletBinding(
        SupportsShouldProcess,
        DefaultParameterSetName='Elements')]
    [OutputType({$script:GitHubLabelTypeName})]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSShouldProcess", "", Justification="Methods called within here make use of PSShouldProcess, and the switch is passed on to them inherently.")]
    param(
        [Parameter(ParameterSetName='Elements')]
        [string] $OwnerName,

        [Parameter(ParameterSetName='Elements')]
        [string] $RepositoryName,

        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName='Uri')]
        [Alias('RepositoryUrl')]
        [string] $Uri,

        [Parameter(Mandatory)]
        [Alias('LabelName')]
        [string] $Name,

        [Parameter(Mandatory)]
        [Alias('NewLabelName')]
        [string] $NewName,

        [Parameter(Mandatory)]
        [Alias('LabelColor')]
        [ValidateScript({if ($_ -match '^#?[ABCDEF0-9]{6}$') { $true } else { throw "Color must be provided in hex." }})]
        [string] $Color = "EEEEEE",

        [string] $Description,

        [string] $AccessToken,

        [switch] $NoStatus
    )

    Write-InvocationLog

    $elements = Resolve-RepositoryElements
    $OwnerName = $elements.ownerName
    $RepositoryName = $elements.repositoryName

    $telemetryProperties = @{
        'OwnerName' = (Get-PiiSafeString -PlainText $OwnerName)
        'RepositoryName' = (Get-PiiSafeString -PlainText $RepositoryName)
    }

    $hashBody = @{}
    if ($PSBoundParameters.ContainsKey('NewName')) { $hashBody['name'] = $NewName }
    if ($PSBoundParameters.ContainsKey('Color')) { $hashBody['color'] = $Color }
    if ($PSBoundParameters.ContainsKey('Description')) { $hashBody['description'] = $Description }

    $params = @{
        'UriFragment' = "repos/$OwnerName/$RepositoryName/labels/$Name"
        'Body' = (ConvertTo-Json -InputObject $hashBody)
        'Method' = 'Patch'
        'Description' =  "Updating label $Name"
        'AcceptHeader' = 'application/vnd.github.symmetra-preview+json'
        'AccessToken' = $AccessToken
        'TelemetryEventName' = $MyInvocation.MyCommand.Name
        'TelemetryProperties' = $telemetryProperties
        'NoStatus' = (Resolve-ParameterWithDefaultConfigurationValue -Name NoStatus -ConfigValueName DefaultNoStatus)
    }

    return (Invoke-GHRestMethod @params |
        Add-GitHubLabelAdditionalProperties -TypeName $script:GitHubLabelTypeName -OwnerName $OwnerName -RepositoryName $RepositoryName)
}

filter Set-GitHubLabel
{
<#
    .SYNOPSIS
        Sets the entire set of Labels on the given GitHub repository to match the provided list
        of Labels.

    .DESCRIPTION
        Sets the entire set of Labels on the given GitHub repository to match the provided list
        of Labels.

        Will update the color/description for any Labels already in the repository that match the
        name of a Label in the provided list.  All other existing Labels will be removed, and then
        new Labels will be created to match the others in the Label list.

        The Git repo for this module can be found here: http://aka.ms/PowerShellForGitHub

    .PARAMETER OwnerName
        Owner of the repository.
        If not supplied here, the DefaultOwnerName configuration property value will be used.

    .PARAMETER RepositoryName
        Name of the repository.
        If not supplied here, the DefaultRepositoryName configuration property value will be used.

    .PARAMETER Uri
        Uri for the repository.
        The OwnerName and RepositoryName will be extracted from here instead of needing to provide
        them individually.

    .PARAMETER Label
        The array of Labels (name, color, description) that the repository should be aligning to.
        A default list of labels will be used if no Labels are provided.

    .PARAMETER AccessToken
        If provided, this will be used as the AccessToken for authentication with the
        REST Api.  Otherwise, will attempt to use the configured value or will run unauthenticated.

    .PARAMETER NoStatus
        If this switch is specified, long-running commands will run on the main thread
        with no commandline status update.  When not specified, those commands run in
        the background, enabling the command prompt to provide status information.
        If not supplied here, the DefaultNoStatus configuration property value will be used.

    .NOTES
        This method does not rename any existing labels, as it doesn't have any context regarding
        which Label the new name is for.  Therefore, it is possible that by running this function
        on a repository with Issues that have already been assigned Labels, you may experience data
        loss as a minor correction to you (maybe fixing a typo) will result in the old Label being
        removed (and thus unassigned from existing Issues) and then the new one created.

    .EXAMPLE
        Set-GitHubLabel -OwnerName Microsoft -RepositoryName PowerShellForGitHub -Label @(@{'name' = 'TestLabel'; 'color' = 'EEEEEE'}, @{'name' = 'critical'; 'color' = 'FF000000'; 'description' = 'Needs immediate attention'})

        Removes any labels not in this Label array, ensure the current assigned color and descriptions
        match what's in the array for the labels that do already exist, and then creates new labels
        for any remaining ones in the Label list.
#>
    [CmdletBinding(
        SupportsShouldProcess,
        DefaultParameterSetName='Elements')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSShouldProcess", "", Justification="Methods called within here make use of PSShouldProcess, and the switch is passed on to them inherently.")]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSReviewUnusedParameter", "", Justification="One or more parameters (like NoStatus) are only referenced by helper methods which get access to it from the stack via Get-Variable -Scope 1.")]
    param(
        [Parameter(ParameterSetName='Elements')]
        [string] $OwnerName,

        [Parameter(ParameterSetName='Elements')]
        [string] $RepositoryName,

        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName='Uri')]
        [Alias('RepositoryUrl')]
        [string] $Uri,

        [object[]] $Label,

        [string] $AccessToken,

        [switch] $NoStatus
    )

    if (($null -eq $Label) -or ($Label.Count -eq 0))
    {
        $Label = $script:defaultGitHubLabels
    }

    $elements = Resolve-RepositoryElements
    $OwnerName = $elements.ownerName
    $RepositoryName = $elements.repositoryName

    $NoStatus = Resolve-ParameterWithDefaultConfigurationValue -Name NoStatus -ConfigValueName DefaultNoStatus

    $commonParams = @{
        'OwnerName' = $OwnerName
        'RepositoryName' = $RepositoryName
        'AccessToken' = $AccessToken
        'NoStatus' = $NoStatus
    }

    $labelNames = $Label.name
    $existingLabels = Get-GitHubLabel @commonParams
    $existingLabelNames = $existingLabels.name

    foreach ($labelToConfigure in $Label)
    {
        if ($labelToConfigure.name -notin $existingLabelNames)
        {
            # Create label if it doesn't exist
            $null = New-GitHubLabel -Name $labelToConfigure.name -Color $labelToConfigure.color @commonParams
        }
        else
        {
            # Update label's color if it already exists
            $null = Update-GitHubLabel -Name $labelToConfigure.name -NewName $labelToConfigure.name -Color $labelToConfigure.color @commonParams
        }
    }

    foreach ($labelName in $existingLabelNames)
    {
        if ($labelName -notin $labelNames)
        {
            # Remove label if it exists but is not in desired label list
            $null = Remove-GitHubLabel -Name $labelName @commonParams -Confirm:$false
        }
    }
}

filter Add-GitHubIssueLabel
{
<#
    .DESCRIPTION
        Adds a label to an issue in the given GitHub repository.

        The Git repo for this module can be found here: http://aka.ms/PowerShellForGitHub

    .PARAMETER OwnerName
        Owner of the repository.
        If not supplied here, the DefaultOwnerName configuration property value will be used.

    .PARAMETER RepositoryName
        Name of the repository.
        If not supplied here, the DefaultRepositoryName configuration property value will be used.

    .PARAMETER Uri
        Uri for the repository.
        The OwnerName and RepositoryName will be extracted from here instead of needing to provide
        them individually.

    .PARAMETER Issue
        Issue number to add the label to.

    .PARAMETER Name
        Array of label names to add to the issue

    .PARAMETER AccessToken
        If provided, this will be used as the AccessToken for authentication with the
        REST Api.  Otherwise, will attempt to use the configured value or will run unauthenticated.

    .PARAMETER NoStatus
        If this switch is specified, long-running commands will run on the main thread
        with no commandline status update.  When not specified, those commands run in
        the background, enabling the command prompt to provide status information.
        If not supplied here, the DefaultNoStatus configuration property value will be used.

    .OUTPUTS
        GitHub.Label

    .EXAMPLE
        Add-GitHubIssueLabel -OwnerName Microsoft -RepositoryName PowerShellForGitHub -Issue 1 -Name $labels

        Adds labels to an issue in the PowerShellForGitHub project.
#>
    [CmdletBinding(
        SupportsShouldProcess,
        DefaultParameterSetName='Elements')]
    [OutputType({$script:GitHubLabelTypeName})]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSShouldProcess", "", Justification="Methods called within here make use of PSShouldProcess, and the switch is passed on to them inherently.")]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSReviewUnusedParameter", "", Justification="One or more parameters (like NoStatus) are only referenced by helper methods which get access to it from the stack via Get-Variable -Scope 1.")]
    param(
        [Parameter(Mandatory, ParameterSetName='Elements')]
        [string] $OwnerName,

        [Parameter(Mandatory, ParameterSetName='Elements')]
        [string] $RepositoryName,

        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName='Uri')]
        [Alias('RepositoryUrl')]
        [string] $Uri,

        [Parameter(Mandatory)]
        [int64] $Issue,

        [Parameter(Mandatory)]
        [Alias('LabelName')]
        [string[]] $Name,

        [string] $AccessToken,

        [switch] $NoStatus
    )

    Write-InvocationLog

    $elements = Resolve-RepositoryElements
    $OwnerName = $elements.ownerName
    $RepositoryName = $elements.repositoryName

    $telemetryProperties = @{
        'OwnerName' = (Get-PiiSafeString -PlainText $OwnerName)
        'RepositoryName' = (Get-PiiSafeString -PlainText $RepositoryName)
        'LabelCount' = $Name.Count
    }

    $hashBody = @{
        'labels' = $Name
    }

    $params = @{
        'UriFragment' = "repos/$OwnerName/$RepositoryName/issues/$Issue/labels"
        'Body' = (ConvertTo-Json -InputObject $hashBody)
        'Method' = 'Post'
        'Description' =  "Adding labels to issue $Issue in $RepositoryName"
        'AcceptHeader' = 'application/vnd.github.symmetra-preview+json'
        'AccessToken' = $AccessToken
        'TelemetryEventName' = $MyInvocation.MyCommand.Name
        'TelemetryProperties' = $telemetryProperties
        'NoStatus' = (Resolve-ParameterWithDefaultConfigurationValue -Name NoStatus -ConfigValueName DefaultNoStatus)
    }

    return (Invoke-GHRestMethod @params |
        Add-GitHubLabelAdditionalProperties -TypeName $script:GitHubLabelTypeName -OwnerName $OwnerName -RepositoryName $RepositoryName)
}

filter Set-GitHubIssueLabel
{
<#
    .DESCRIPTION
        Replaces labels on an issue in the given GitHub repository.

        The Git repo for this module can be found here: http://aka.ms/PowerShellForGitHub

    .PARAMETER OwnerName
        Owner of the repository.
        If not supplied here, the DefaultOwnerName configuration property value will be used.

    .PARAMETER RepositoryName
        Name of the repository.
        If not supplied here, the DefaultRepositoryName configuration property value will be used.

    .PARAMETER Uri
        Uri for the repository.
        The OwnerName and RepositoryName will be extracted from here instead of needing to provide
        them individually.

    .PARAMETER Issue
        Issue number to replace the labels.

    .PARAMETER LabelName
        Array of label names that will be set on the issue.

    .PARAMETER AccessToken
        If provided, this will be used as the AccessToken for authentication with the
        REST Api.  Otherwise, will attempt to use the configured value or will run unauthenticated.

    .PARAMETER NoStatus
        If this switch is specified, long-running commands will run on the main thread
        with no commandline status update.  When not specified, those commands run in
        the background, enabling the command prompt to provide status information.
        If not supplied here, the DefaultNoStatus configuration property value will be used.

    .OUTPUTS
        GitHub.Label

    .EXAMPLE
        Set-GitHubIssueLabel -OwnerName Microsoft -RepositoryName PowerShellForGitHub -Issue 1 -LabelName $labels

        Replaces labels on an issue in the PowerShellForGitHub project.
#>
    [CmdletBinding(
        SupportsShouldProcess,
        DefaultParameterSetName='Elements')]
    [OutputType({$script:GitHubLabelTypeName})]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSShouldProcess", "", Justification="Methods called within here make use of PSShouldProcess, and the switch is passed on to them inherently.")]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSReviewUnusedParameter", "", Justification="One or more parameters (like NoStatus) are only referenced by helper methods which get access to it from the stack via Get-Variable -Scope 1.")]
    param(
        [Parameter(ParameterSetName='Elements')]
        [string] $OwnerName,

        [Parameter(ParameterSetName='Elements')]
        [string] $RepositoryName,

        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName='Uri')]
        [Alias('RepositoryUrl')]
        [string] $Uri,

        [Parameter(Mandatory)]
        [int64] $Issue,

        [Parameter(Mandatory)]
        [Alias('LabelName')]
        [string[]] $Name,

        [string] $AccessToken,

        [switch] $NoStatus
    )

    Write-InvocationLog

    $elements = Resolve-RepositoryElements
    $OwnerName = $elements.ownerName
    $RepositoryName = $elements.repositoryName

    $telemetryProperties = @{
        'OwnerName' = (Get-PiiSafeString -PlainText $OwnerName)
        'RepositoryName' = (Get-PiiSafeString -PlainText $RepositoryName)
        'LabelCount' = $Name.Count
    }

    $hashBody = @{
        'labels' = $Name
    }

    $params = @{
        'UriFragment' = "repos/$OwnerName/$RepositoryName/issues/$Issue/labels"
        'Body' = (ConvertTo-Json -InputObject $hashBody)
        'Method' = 'Put'
        'Description' =  "Replacing labels to issue $Issue in $RepositoryName"
        'AcceptHeader' = 'application/vnd.github.symmetra-preview+json'
        'AccessToken' = $AccessToken
        'TelemetryEventName' = $MyInvocation.MyCommand.Name
        'TelemetryProperties' = $telemetryProperties
        'NoStatus' = (Resolve-ParameterWithDefaultConfigurationValue -Name NoStatus -ConfigValueName DefaultNoStatus)
    }

    return (Invoke-GHRestMethod @params |
        Add-GitHubLabelAdditionalProperties -TypeName $script:GitHubLabelTypeName -OwnerName $OwnerName -RepositoryName $RepositoryName)
}

filter Remove-GitHubIssueLabel
{
<#
    .DESCRIPTION
        Deletes a label from an issue in the given GitHub repository.

        The Git repo for this module can be found here: http://aka.ms/PowerShellForGitHub

    .PARAMETER OwnerName
        Owner of the repository.
        If not supplied here, the DefaultOwnerName configuration property value will be used.

    .PARAMETER RepositoryName
        Name of the repository.
        If not supplied here, the DefaultRepositoryName configuration property value will be used.

    .PARAMETER Uri
        Uri for the repository.
        The OwnerName and RepositoryName will be extracted from here instead of needing to provide
        them individually.

    .PARAMETER Issue
        Issue number to remove the label from.

    .PARAMETER Name
        Name of the label to be deleted. If not provided, will delete all labels on the issue.
        Emoji and codes are supported.  For more information, see here: https://www.webpagefx.com/tools/emoji-cheat-sheet/

    .PARAMETER Force
        If this switch is specified, you will not be prompted for confirmation of command execution.

    .PARAMETER AccessToken
        If provided, this will be used as the AccessToken for authentication with the
        REST Api.  Otherwise, will attempt to use the configured value or will run unauthenticated.

    .PARAMETER NoStatus
        If this switch is specified, long-running commands will run on the main thread
        with no commandline status update.  When not specified, those commands run in
        the background, enabling the command prompt to provide status information.
        If not supplied here, the DefaultNoStatus configuration property value will be used.

    .EXAMPLE
        Remove-GitHubIssueLabel -OwnerName Microsoft -RepositoryName PowerShellForGitHub -Name TestLabel -Issue 1

        Removes the label called "TestLabel" from issue 1 in the PowerShellForGitHub project.

    .EXAMPLE
        Remove-GitHubIssueLabel -OwnerName Microsoft -RepositoryName PowerShellForGitHub -Name TestLabel -Issue 1 -Confirm:$false

        Removes the label called "TestLabel" from issue 1 in the PowerShellForGitHub project. Will not prompt for confirmation, as -Confirm:$false was specified.

    .EXAMPLE
        Remove-GitHubIssueLabel -OwnerName Microsoft -RepositoryName PowerShellForGitHub -Name TestLabel -Issue 1 -Force

        Removes the label called "TestLabel" from issue 1 in the PowerShellForGitHub project. Will not prompt for confirmation, as -Force was specified.
#>
    [CmdletBinding(
        SupportsShouldProcess,
        DefaultParameterSetName='Elements',
        ConfirmImpact="High")]
    [Alias('Delete-GitHubLabel')]
    param(
        [Parameter(
            Mandatory,
            ParameterSetName='Elements')]
        [string] $OwnerName,

        [Parameter(
            Mandatory,
            ParameterSetName='Elements')]
        [string] $RepositoryName,

        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName='Uri')]
        [Alias('RepositoryUrl')]
        [string] $Uri,

        [Parameter(Mandatory)]
        [int64] $Issue,

        [ValidateNotNullOrEmpty()]
        [Alias('LabelName')]
        [string] $Name,

        [switch] $Force,

        [string] $AccessToken,

        [switch] $NoStatus
    )

    Write-InvocationLog

    $elements = Resolve-RepositoryElements
    $OwnerName = $elements.ownerName
    $RepositoryName = $elements.repositoryName

    $telemetryProperties = @{
        'OwnerName' = (Get-PiiSafeString -PlainText $OwnerName)
        'RepositoryName' = (Get-PiiSafeString -PlainText $RepositoryName)
    }

    $description = [String]::Empty

    if ($PSBoundParameters.ContainsKey('Name'))
    {
        $description = "Deleting label $Name from issue $Issue in $RepositoryName"
    }
    else
    {
        $description = "Deleting all labels from issue $Issue in $RepositoryName"
    }

    if ($Force -and (-not $Confirm))
    {
        $ConfirmPreference = 'None'
    }

    if ($PSCmdlet.ShouldProcess($Name, "Remove label"))
    {
        $params = @{
            'UriFragment' = "/repos/$OwnerName/$RepositoryName/issues/$Issue/labels/$Name"
            'Method' = 'Delete'
            'Description' =  $description
            'AcceptHeader' = 'application/vnd.github.symmetra-preview+json'
            'AccessToken' = $AccessToken
            'TelemetryEventName' = $MyInvocation.MyCommand.Name
            'TelemetryProperties' = $telemetryProperties
            'NoStatus' = (Resolve-ParameterWithDefaultConfigurationValue -Name NoStatus -ConfigValueName DefaultNoStatus)
        }

        return Invoke-GHRestMethod @params
    }
}

filter Add-GitHubLabelAdditionalProperties
{
<#
    .SYNOPSIS
        Adds type name and additional properties to ease pipelining to GitHub Label objects.

    .PARAMETER InputObject
        The GitHub object to add additional properties to.

    .PARAMETER TypeName
        The type that should be assigned to the object.

    .PARAMETER OwnerName
        Owner of the repository.  This information might be obtainable from InputObject, so this
        is optional based on what InputObject contains.

    .PARAMETER RepositoryName
        Name of the repository.  This information might be obtainable from InputObject, so this
        is optional based on what InputObject contains.
#>
    [CmdletBinding()]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseSingularNouns", "", Justification="Internal helper that is definitely adding more than one property.")]
    param(
        [Parameter(
            Mandatory,
            ValueFromPipeline)]
        [AllowNull()]
        [AllowEmptyCollection()]
        [PSCustomObject[]] $InputObject,

        [ValidateNotNullOrEmpty()]
        [string] $TypeName = $script:GitHubLabelTypeName,

        [string] $OwnerName,

        [string] $RepositoryName
    )

    foreach ($item in $InputObject)
    {
        $item.PSObject.TypeNames.Insert(0, $TypeName)

        if (-not (Get-GitHubConfiguration -Name DisablePipelineSupport))
        {
            if ($PSBoundParameters.ContainsKey('OwnerName') -and
                $PSBoundParameters.ContainsKey('RepositoryName'))
            {
                $repositoryUrl = (Join-GitHubUri -OwnerName $OwnerName -RepositoryName $RepositoryName)
                Add-Member -InputObject $item -Name 'RepositoryUrl' -Value $repositoryUrl -MemberType NoteProperty -Force
            }

            if ($null -ne $item.id)
            {
                Add-Member -InputObject $item -Name 'LabelId' -Value $item.id -MemberType NoteProperty -Force
            }

            Add-Member -InputObject $item -Name 'LabelName' -Value $item.name -MemberType NoteProperty -Force
        }

        Write-Output $item
    }
}

# A set of labels that a project might want to initially populate their repository with
# Used by Set-GitHubLabel when no Label list is provided by the user.
# This list exists to support v0.1.0 users.
$script:defaultGitHubLabels = @(
    @{
        'name' = 'pri:lowest'
        'color' = '4285F4'
    },
    @{
        'name' = 'pri:low'
        'color' = '4285F4'
    },
    @{
        'name' = 'pri:medium'
        'color' = '4285F4'
    },
    @{
        'name' = 'pri:high'
        'color' = '4285F4'
    },
    @{
        'name' = 'pri:highest'
        'color' = '4285F4'
    },
    @{
        'name' = 'bug'
        'color' = 'fc2929'
    },
    @{
        'name' = 'duplicate'
        'color' = 'cccccc'
    },
    @{
        'name' = 'enhancement'
        'color' = '121459'
    },
    @{
        'name' = 'up for grabs'
        'color' = '159818'
    },
    @{
        'name' = 'question'
        'color' = 'cc317c'
    },
    @{
        'name' = 'discussion'
        'color' = 'fe9a3d'
    },
    @{
        'name' = 'wontfix'
        'color' = 'dcb39c'
    },
    @{
        'name' = 'in progress'
        'color' = 'f0d218'
    },
    @{
        'name' = 'ready'
        'color' = '145912'
    }
)
