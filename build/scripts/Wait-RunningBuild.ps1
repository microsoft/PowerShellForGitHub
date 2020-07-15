# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

<#
    .DESCRIPTION
        This script will enforce the concept of a queue for a build pipeline to ensure that
        builds do not actively run concurrently.

    .PARAMETER PersonalAccessToken
        A token that has Build READ permission.

    .PARAMETER OrganizationName
        The name of the organization that this project is a part of.

    .PARAMETER ProjectName
        The name of the project that this build pipeline can be found in.

    .PARAMETER BuildDefinitionId
        The ID for the build definition that we are enforcing a queue on.

    .PARAMETER BuildId
        The ID for this build.

    .PARAMETER NumSecondsSleepBetweenPolling
        The number of seconds to sleep before polling attempt to check build pipeline status again.

    .PARAMETER MaxRetriesBeforeStarting
        The number of successive retries that will be attempted to query for build pipeline status
        before just allowing the build to start.

    .EXAMPLE
        $params = @{
            PersonalAccessToken = $env:buildReadAccessToken
            OrganizationName = 'ms'
            ProjectName = 'PowerShellForGitHub'
            BuildDefinitionId = $(System.DefinitionId)
            BuildId = $(Build.BuildId)
        }
        ./Wait-RunningBuilds.ps1 @params
#>
[CmdletBinding()]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingWriteHost", "", Justification = "This is the preferred way of writing output for Azure DevOps.")]
param(
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string] $PersonalAccessToken,

    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string] $OrganizationName,

    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string] $ProjectName,

    [Parameter(Mandatory)]
    [int64] $BuildDefinitionId,

    [Parameter(Mandatory)]
    [int64] $BuildId,

    [int] $NumSecondsSleepBetweenPolling = 30,

    [int] $MaxRetriesBeforeStarting = 3
)

Write-Host '[Wait-RunningBuilds] - Starting'

$elapsedTimeFormat = '{0:hh\:mm\:ss}'
$stopwatch = New-Object -TypeName System.Diagnostics.Stopwatch
$stopwatch.Start()

$url = "https://dev.azure.com/$OrganizationName/$ProjectName/_apis/build/builds?api-version=5.1&definitions=$BuildDefinitionId"
$headers = @{
    'Authorization' = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":$PersonalAccessToken"))
}

$remainingRetries = $MaxRetriesBeforeStarting
do
{
    try
    {
        $params = @{
            Uri = $url
            Method = 'Get'
            ContentType = 'application/json'
            Headers = $headers
            UseBasicParsing = $true
        }

        $builds = Invoke-RestMethod @params

        $remainingRetries = $MaxRetriesBeforeStarting # successfully got a result.  Reset remaining retries

        $thisBuild = $builds.value | Where-Object { $_.id -eq $BuildId }
        $runningBuilds = @($builds.value | Where-Object { $_.status -eq 'inProgress' })
        $currentRunningBuild = $runningBuilds | Sort-Object -Property 'Id' | Select-Object -First 1

        if ($null -eq $currentRunningBuild)
        {
            Write-Host 'Failed to identify the currently running build.  To prevent an indefinite wait, allowing this build to start.'
            break
        }
        elseif ($BuildId -ne $currentRunningBuild.id)
        {
            $buildsAheadInQueue = @($runningBuilds | Where-Object { $_.id -lt $BuildId })

            # We want to display how long the current build has been running for _actively_,
            # so we need to take into account if it had been queued while the previous build was
            # running and thus subtract that extra time.
            $currentRunningBuildStartTime = Get-Date -Date $currentRunningBuild.startTime
            $lastCompletedBuild = $builds.value |
                Where-Object { $_.status -ne 'inProgress' } |
                Select-Object -First 1
            if ($null -ne $lastCompletedBuild)
            {
                $lastCompletedBuildTime = Get-Date -Date $lastCompletedBuild.finishTime
                if ($lastCompletedBuildTime -gt $currentRunningBuildStartTime)
                {
                    $waitedDuration = $lastCompletedBuildTime - $currentRunningBuildStartTime
                    $currentRunningBuildStartTime.AddMilliseconds($waitedDuration.TotalMilliseconds)
                }
            }

            $currentRunningBuildElapsedTime = New-TimeSpan -Start $currentRunningBuildStartTime -End (Get-Date)
            $currentRunningBuildElapsedTimeFormatted = $elapsedTimeFormat -f $currentRunningBuildElapsedTime

            $timeWaited = New-TimeSpan -Start $thisBuild.startTime -End (Get-Date)
            $timeWaitedFormatted = $elapsedTimeFormat -f $timeWaited

            $message = @(
                "* Time: $(Get-Date -Format 'o')",
                "  This build: $($thisBuild.id) ($($thisBuild.buildNumber)) [Waiting for $timeWaitedFormatted]",
                "  Builds ahead in queue: $($buildsAheadInQueue.buildNumber -join ', ')",
                "  Total queued builds: $($runningBuilds.Count - 1)",
                "  Currently running build: $($currentRunningBuild.id) ($($currentRunningBuild.buildNumber)) [Running for $currentRunningBuildElapsedTimeFormatted]",
                "  Waiting $NumSecondsSleepBetweenPolling seconds before polling build status for this pipeline again...",
                '--------------------------')
            Write-Host ($message -join [Environment]::NewLine)
        }
        else
        {
            break
        }
    }
    catch
    {
        $remainingRetries--
        if ($remainingRetries -lt 0)
        {
            Write-Host 'Still unable to retrieve build status for this pipeline.  Exhausted retries.  To prevent an indefinite wait, allowing this build to start.'
            break
        }
        else
        {
            Write-Host "Failed to get build status for this pipeline. Will try again in $NumSecondsSleepBetweenPolling seconds.  $remainingRetries retries remaining."
        }
    }

    Start-Sleep -Seconds $NumSecondsSleepBetweenPolling
}
while ($true)

$stopwatch.Stop()
$timeWaitedFormatted = $elapsedTimeFormat -f $stopwatch.Elapsed
Write-Host "Waiting completed after $timeWaitedFormatted.  Starting this build."

Write-Host '[Wait-RunningBuilds] - Exiting'