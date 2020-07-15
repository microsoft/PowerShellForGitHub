# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

# We'll cache our job name and result so that we don't check more than once per day.
$script:UpdateCheckJobName = $null
$script:HasLatestVersion = $null

function Invoke-UpdateCheck
{
<#
    .SYNOPSIS
        Checks PowerShellGallery to see if a newer version of this module has been published.

    .DESCRIPTION
        Checks PowerShellGallery to see if a newer version of this module has been published.

        The check will only run once per day.

        Runs asynchronously, so the user won't see any message until after they run their first
        API request after the module has been imported.

        Will always assume true in the event of an incomplete or failed check.

        Reports the result to the user via a Warning message (if a newer version is available)
        or a Verbose message (if they're running the latest version or the version check failed).

        The Git repo for this module can be found here: http://aka.ms/PowerShellForGitHub

    .PARAMETER Force
        For debugging purposes, using this switch will allow the check to occur more than the limit
        of once per day.  This _will not_ bypass the DisableUpdateCheck configuration value however.

    .EXAMPLE
        Invoke-UpdateCheck

    .NOTES
        Internal-only helper method.
#>
    [cmdletbinding()]
    param([switch] $Force)

    if (Get-GitHubConfiguration -Name DisableUpdateCheck)
    {
        return
    }

    $moduleName = $MyInvocation.MyCommand.Module.Name
    $moduleVersion = $MyInvocation.MyCommand.Module.Version

    $jobNameToday = "Invoke-UpdateCheck-" + (Get-Date -format 'yyyyMMdd')

    if ($Force)
    {
        if ($null -ne $script:UpdateCheckJobName)
        {
            # We're going to clear out the existing job and try running it again.
            $null = Receive-Job -Name $script:UpdateCheckJobName -AutoRemoveJob -Wait -ErrorAction SilentlyContinue -ErrorVariable errorInfo
        }

        $script:UpdateCheckJobName = $null
        $script:HasLatestVersion = $null
    }

    # We only check once per day
    if ($jobNameToday -eq $script:UpdateCheckJobName)
    {
        # Have we retrieved the status yet?  $null means we haven't.
        if ($null -ne $script:HasLatestVersion)
        {
            # We've already completed the check for today.  No further action required.
            return
        }

        $state = (Get-Job -Name $script:UpdateCheckJobName).state
        if ($state -eq 'Failed')
        {
            # We'll just assume we're up-to-date if we failed to check today.
            $message = '[$moduleName] update check failed for today (web request failed).  Assuming up-to-date.'
            Write-Log -Message $message -Level Verbose
            $script:HasLatestVersion = $true

            # Clear out the job info (even though we don't need the result)
            $null = Receive-Job -Name $script:UpdateCheckJobName -AutoRemoveJob -Wait -ErrorAction SilentlyContinue -ErrorVariable errorInfo
            return
        }
        elseif ($state -eq 'Completed')
        {
            $result = Receive-Job -Name $script:UpdateCheckJobName -AutoRemoveJob -Wait
            try
            {
                # Occasionally the API puts two nearly identical XML responses in the body (each on a separate line).
                # We'll try to avoid an unnecessary failure by always using the first line of the response.
                $xml = [xml]($result.Content.Split([Environment]::NewLine) | Select-Object -First 1)
                $latestVersion = $xml.feed.entry.properties.version |
                    ForEach-Object {[System.Version]$_} |
                    Sort-Object -Descending |
                    Select-Object -First 1

                $script:HasLatestVersion = $latestVersion -eq $moduleVersion
                if ($script:HasLatestVersion)
                {
                    $message = "[$moduleName] update check complete.  Running latest version: $latestVersion"
                    Write-Log -Message $message -Level Verbose
                }
                elseif ($moduleVersion -gt $latestVersion)
                {
                    $message = "[$moduleName] update check complete.  This version ($moduleVersion) is newer than the latest published version ($latestVersion)."
                    Write-Log -Message $message -Level Verbose
                }
                else
                {
                    $message = "A newer version of $moduleName is available ($latestVersion).  Your current version is $moduleVersion.  Run 'Update-Module $moduleName' to get up-to-date."
                    Write-Log -Message $message -Level Warning
                }
            }
            catch
            {
                # This could happen if the server returned back an invalid (non-XML) response for the request
                # for some reason.
                $message = "[$moduleName] update check failed for today (invalid XML response).  Assuming up-to-date."
                Write-Log -Message $message -Level Verbose
                $script:HasLatestVersion = $true
            }

            return
        }
        else
        {
            # It's still running.  Nothing further for us to do right now.  We'll check back
            # again next time.
            return
        }
    }
    else
    {
        # We either haven't checked yet, or it's a new day so we should check again.
        $script:UpdateCheckJobName = $jobNameToday
        $script:HasLatestVersion = $null
    }

    [scriptblock]$scriptBlock = {
        param($ModuleName)

        $params = @{}
        $params.Add('Uri', "https://www.powershellgallery.com/api/v2/FindPackagesById()?id='$ModuleName'")
        $params.Add('Method', 'Get')
        $params.Add('UseDefaultCredentials', $true)
        $params.Add('UseBasicParsing', $true)

        try
        {
            # Disable Progress Bar in function scope during Invoke-WebRequest
            $ProgressPreference = 'SilentlyContinue'

            Invoke-WebRequest @params
        }
        catch
        {
            # We will silently ignore any errors that occurred, but we need to make sure that
            # we are explicitly catching and throwing them so that our reported state is Failed.
            throw
        }
    }

    $null = Start-Job -Name $script:UpdateCheckJobName -ScriptBlock $scriptBlock -Arg @($moduleName)

    # We're letting this run asynchronously so that users can immediately start using the module.
    # We'll check back in on the result of this the next time they run any command.
}

# We will explicitly run this as soon as the module has been loaded,
# and then it will be called again during every major function call in the module
# so that the result can be reported.
Invoke-UpdateCheck