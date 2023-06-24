# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

<#
.Synopsis
   Tests for GitHubCodespaces.ps1 module
#>

[CmdletBinding()]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '',
    Justification = 'Suppress false positives in Pester code blocks')]
param()

# This is common test code setup logic for all Pester test files
BeforeAll {
    $moduleRootPath = Split-Path -Path $PSScriptRoot -Parent
    . (Join-Path -Path $moduleRootPath -ChildPath 'Tests\Common.ps1')

    # Define Script-scoped, readonly, hidden variables.
    @{
        defaultRepositoryName = ([Guid]::NewGuid().Guid)
    }.GetEnumerator() | ForEach-Object {
        Set-Variable -Force -Scope Script -Option ReadOnly -Visibility Private -Name $_.Key -Value $_.Value
    }

    $newGitHubRepositoryParms = @{
        AutoInit = $true
        Private = $true
        RepositoryName = $defaultRepositoryName
        OrganizationName = $script:organizationName
    }
    $repo = New-GitHubRepository @newGitHubRepositoryParms
}

Describe 'GitHubCodespaces\Delete-GitHubCodespace' {

    Context 'When deleting a codespace for the authenticated user' {
        BeforeEach {
            # Suppress HTTP 202 warning for codespace creation
            # TODO: Suppression is not working as intended here.
            $WarningPreference = 'SilentlyContinue'

            $newGitHubCodespaceParms = @{
                OwnerName = $script:organizationName
                RepositoryName = $defaultRepositoryName
            }
            $codespace = New-GitHubCodespace @newGitHubCodespaceParms
            Start-Sleep -Seconds 2
        }

        It 'Should get no content using -Confirm:$false' {
            # Also asserts pipeline input
            $codespace | Remove-GitHubCodespace -Confirm:$false
            { Get-GitHubCodespace -CodespaceName $codespace.name } | Should -Throw
        }

        It 'Should get no content using -Force' {
            # Also assert CodespaceName input
            Remove-GitHubCodespace -CodespaceName $codespace.name -Force
            { Get-GitHubCodespace -CodespaceName $codespace.name } | Should -Throw
        }
    }
}

Describe 'GitHubCodespaces\Get-GitHubCodespace' {
    BeforeAll {
        # Suppress HTTP 202 warning for codespace creation
        $WarningPreference = 'SilentlyContinue'

        $newGitHubCodespaceParms = @{
            OwnerName = $script:organizationName
            RepositoryName = $defaultRepositoryName
        }
        $null = New-GitHubCodespace @newGitHubCodespaceParms
        Start-Sleep -Seconds 2
    }

    Context 'When getting codespaces for the authenticated user' {
        BeforeAll {
            $codespaces = Get-GitHubCodespace |
            Where-Object { $_.repository.name -eq $defaultRepositoryName }
        }

        It 'Should return objects of the correct type' {
            $codespaces[0].PSObject.TypeNames[0] | Should -Be 'GitHub.Codespace'
        }

        It 'Should return one or more results' {
            $codespaces.Count | Should -BeGreaterOrEqual 1
        }

        It 'Should return the correct properties' {
            foreach ($codespace in $codespaces)
            {
                $codespace.owner.login | Should -Be $script:OwnerName
                $codespace.repository.name | Should -Be $newGitHubCodespaceParms.RepositoryName
            }
        }
    }

    Context 'When getting a codespace for a specified owner and repository' {

        BeforeAll {
            $codespaces = Get-GitHubCodespace @newGitHubCodespaceParms
        }
        It 'Should return objects of the correct type' {
            $codespaces[0].PSObject.TypeNames[0] | Should -Be 'GitHub.Codespace'
        }

        It 'Should return one or more results' {
            $codespaces.Count | Should -BeGreaterOrEqual 1
        }

        It 'Should return the correct properties' {
            foreach ($codespace in $codespaces)
            {
                $codespace.owner.login | Should -Be $script:OwnerName
                $codespace.repository.name | Should -Be $newGitHubCodespaceParms.RepositoryName
            }
        }
    }

    Context 'When getting all codespaces for a specified organization' {

        BeforeAll {
            $codespaces = Get-GitHubCodespace -OrganizationName $script:organizationName
        }
        It 'Should return objects of the correct type' {
            $codespaces[0].PSObject.TypeNames[0] | Should -Be 'GitHub.Codespace'
        }

        It 'Should return one or more results' {
            $codespaces.Count | Should -BeGreaterOrEqual 1
        }
    }

    Context 'When getting a codespace for a specified organization user' {
        BeforeAll {
            $codespaces = Get-GitHubCodespace -OrganizationName $script:organizationName
            $userCodespaces = Get-GitHubCodespace -OrganizationName $script:organizationName -UserName $script:OwnerName
        }

        It 'Should have results for the organization user' {
            $userCodespaces.name | Should -BeIn $codespaces.name
        }

        It 'Should return the correct properties' {
            foreach ($codespace in $userCodespaces)
            {
                $codespace.owner.login | Should -Be $script:OwnerName
            }
        }
    }

    Context 'When getting a codespace for a specified codespace name' {
        BeforeAll {
            $codespaces = Get-GitHubCodespace
            $codespace = Get-GitHubCodespace -CodespaceName $codespaces[0].name
        }

        It 'Should return objects of the correct type' {
            $codespace.PSObject.TypeNames[0] | Should -Be 'GitHub.Codespace'
        }

        It 'Should return the correct properties' {
            $codespace.owner.login | Should -Be $script:OwnerName
        }
    }

    Context 'When specifiying the Uri parameter' {
        BeforeAll {
            $codespace = Get-GitHubCodespace -Uri $repo.RepositoryUrl
        }

        It 'Should return objects of the correct type' {
            $codespace.PSObject.TypeNames[0] | Should -Be 'GitHub.Codespace'
        }

        It 'Should return the correct properties' {
            $codespace.owner.login | Should -Be $script:OwnerName
            $codespace.repository.name | Should -Be $repo.name
        }
    }

    Context "When specifiying the Uri parameter from the pipeline" {
        BeforeAll {
            $codespace = $repo | Get-GitHubCodespace
        }

        It 'Should return objects of the correct type' {
            $codespace.PSObject.TypeNames[0] | Should -Be 'GitHub.Codespace'
        }

        It 'Should return the correct properties' {
            $codespace.repository.name | Should -Be $repo.name
        }
    }
}


Describe 'GitHubCodespaces\New-GitHubCodespace' {

    Context -Name 'When creating a repository for the authenticated user' {

        Context -Name 'When creating a codespace with default settings with RepositoryId' {
            BeforeAll {
                $newGitHubCodespaceParms = @{
                    RepositoryId = $repo.Id
                }
                $codespace = New-GitHubCodespace @newGitHubCodespaceParms
                Start-Sleep -Seconds 2
            }

            It 'Should return an object of the correct type' {
                $codespace | Should -BeOfType PSCustomObject
            }

            It 'Should return the correct properties' {
                $codespace.display_name | Should -Not -BeNullOrEmpty
                $codespace.repository.name | Should -Be $repo.name
                $codespace.idle_timeout_minutes | Should -Be 30
                $codespace.owner.UserName | Should -Be $script:OwnerName
                $codespace.template | Should -BeNullOrEmpty
            }

            AfterAll {
                if ($codespace)
                {
                    Remove-GitHubCodespace -CodespaceName $codespace.name -Confirm:$false
                }
            }
        }

        Context -Name 'When creating a codespace with default settings with Ref' {
            BeforeAll {
                $repoWithPR = Get-GitHubRepository -OrganizationName 'super-fake-not-real-org' |
                    Where-Object { $_ | Get-GitHubPullRequest } |
                    Select-Object -First 1
                $pullRequest = $repoWithPR | Get-GitHubPullRequest | Select-Object -First 1
                $newGitHubCodespaceParms = @{
                    Ref = $pullRequest.head.ref
                    RepositoryId = $repoWithPR.Id
                }
                $codespace = New-GitHubCodespace @newGitHubCodespaceParms
                Start-Sleep -Seconds 2
            }

            It 'Should return an object of the correct type' {
                $codespace | Should -BeOfType PSCustomObject
            }

            It 'Should return the correct properties' {
                $codespace.display_name | Should -Not -BeNullOrEmpty
                $codespace.git_status.ref | Should -Be $pullRequest.head.ref
                $codespace.repository.name | Should -Be $repoWithPR.name
                $codespace.idle_timeout_minutes | Should -Be 30
                $codespace.owner.UserName | Should -Be $script:OwnerName
                $codespace.template | Should -BeNullOrEmpty
            }

            AfterAll {
                if ($codespace)
                {
                    Remove-GitHubCodespace -CodespaceName $codespace.name -Confirm:$false
                }
            }
        }

        Context -Name 'When creating a codespace with default settings from a PullRequest' {
            BeforeAll {
                  $repoWithPR = Get-GitHubRepository -OrganizationName 'super-fake-not-real-org' |
                      Where-Object { $_ | Get-GitHubPullRequest } |
                      Select-Object -First 1
                $pullRequest = $repoWithPR | Get-GitHubPullRequest | Select-Object -First 1
                $newGitHubCodespaceParms = @{
                    PullRequest = $pullRequest.number
                    RepositoryId = $repoWithPR.Id
                }
                $codespace = New-GitHubCodespace @newGitHubCodespaceParms
                Start-Sleep -Seconds 2
            }

            It 'Should return an object of the correct type' {
                $codespace | Should -BeOfType PSCustomObject
            }

            It 'Should return the correct properties' {
                $codespace.display_name | Should -Not -BeNullOrEmpty
                $codespace.repository.name | Should -Be $repoWithPR.name
                $codespace.idle_timeout_minutes | Should -Be 30
                $codespace.owner.UserName | Should -Be $script:OwnerName
                $codespace.pulls_url | Should -Be $pullRequest.url
                $codespace.template | Should -BeNullOrEmpty
            }

            AfterAll {
                if ($codespace)
                {
                    Remove-GitHubCodespace -CodespaceName $codespace.name -Confirm:$false
                }
            }
        }

        Context -Name 'When creating a codespace with all possible settings' {
            BeforeAll {
                $newGitHubCodespaceParms = @{
                    # ClientIp = 'TODO ???? - should be instead of rather than in addition to Geo, perhaps add some param validation to the function'
                    # DevContainerPath = 'Will add to test in the future when Get-GitHubDevContainer is implemented and the test repo includes one'
                    DisplayName = 'PowerShellForGitHub pester test'
                    Geo = 'UsWest'
                    Machine = 'basicLinux32gb'
                    NoMultipleRepoPermissions = $true # Not sure how to assert this, but this proves it accepts the switch without error
                    RetentionPeriod = 10
                    Timeout = 5
                    # WorkingDirectory = 'TODO ???? - not sure how to handle this'
                }
                $codespace = $repo | New-GitHubCodespace @newGitHubCodespaceParms
            }

            It 'Should return an object of the correct type' {
                $codespace | Should -BeOfType PSCustomObject
            }

            It 'Should return the correct properties' {
                # $codespace.devcontainer_path | Should -Be
                $codespace.display_name | Should -Be $newGitHubCodespaceParms.DisplayName
                $codespace.idle_timeout_minutes | Should -Be 5
                $codespace.geo | Should -Be $newGitHubCodespaceParms.Geo
                $codespace.machine.name | Should -Be $newGitHubCodespaceParms.Machine
                $codespace.owner.UserName | Should -Be $script:OwnerName
                $codespace.repository.name | Should -Be $repo.name
                $codespace.retention_period_minutes | Should -Be 10
                $codespace.template | Should -BeNullOrEmpty
            }

            AfterAll {
                if ($codespace)
                {
                    Remove-GitHubCodespace -CodespaceName $codespace.name -Confirm:$false
                }
            }
        }

        Context -Name 'When creating a codespace with default settings with Repository Elements' {
            BeforeAll {
                $newGitHubCodespaceParms = @{
                    RepositoryName = $repo.name
                    OwnerName = $script:organizationName
                }
                $codespace = New-GitHubCodespace @newGitHubCodespaceParms
            }

            It 'Should return an object of the correct type' {
                $codespace | Should -BeOfType PSCustomObject
            }

            It 'Should return the correct properties' {
                $codespace.display_name | Should -Not -BeNullOrEmpty
                $codespace.repository.name | Should -Be $repo.name
                $codespace.idle_timeout_minutes | Should -Be 30
                $codespace.owner.UserName | Should -Be $script:OwnerName
                $codespace.template | Should -BeNullOrEmpty
            }

            AfterAll {
                if ($codespace)
                {
                    Remove-GitHubCodespace -CodespaceName $codespace.name -Confirm:$false
                }
            }
        }
    }
}

Describe 'GitHubCodespaces\Start-GitHubCodespace' {
    BeforeAll {
        # Suppress HTTP 202 warning for codespace creation
        $WarningPreference = 'SilentlyContinue'

        $newGitHubCodespaceParms = @{
            OwnerName = $script:organizationName
            RepositoryName = $defaultRepositoryName
        }
        $null = New-GitHubCodespace @newGitHubCodespaceParms
        Start-Sleep -Seconds 2
    }

    Context 'When starting a codespace for the authenticated user' {
        BeforeAll {
            $codespace = Get-GitHubCodespace @newGitHubCodespaceParms
        }

        It 'Should not throw' {
            # Also asserts pipeline input
            { $codespace | Start-GitHubCodespace } | Should -Not -Throw
        }

        It 'Should become Available' {
            # Also asserts Wait and PassThru
            $result = $codespace | Start-GitHubCodespace -Wait -PassThru
            $result.State | Should -Be 'Available'
        }
    }
}

Describe 'GitHubCodespaces\Stop-GitHubCodespace' {
    BeforeAll {
        # Suppress HTTP 202 warning for codespace creation
        $WarningPreference = 'SilentlyContinue'

        $newGitHubCodespaceParms = @{
            OwnerName = $script:organizationName
            RepositoryName = $defaultRepositoryName
        }
        $null = New-GitHubCodespace @newGitHubCodespaceParms
        Start-Sleep -Seconds 2
    }

    Context 'When stopping a codespace for the authenticated user' {
        BeforeAll {
            $codespace = Get-GitHubCodespace @newGitHubCodespaceParms
        }

        It 'Should not throw' {
            # Also asserts pipeline input
            { $codespace | Stop-GitHubCodespace } | Should -Not -Throw
        }

        It 'Should become Shutdown' {
            # Also asserts Wait and PassThru
            $result = $codespace | Stop-GitHubCodespace -Wait -PassThru
            $result.State | Should -Be 'Shutdown'
        }
    }
}

AfterAll {
    if (Get-Variable -Name repo -ErrorAction SilentlyContinue)
    {
        # Should delete any corresponding codespaces along with it
        $repo | Remove-GitHubRepository -Confirm:$false
    }

    if (Test-Path -Path $script:originalConfigFile -PathType Leaf)
    {
        # Restore the user's configuration to its pre-test state
        Restore-GitHubConfiguration -Path $script:originalConfigFile
        $script:originalConfigFile = $null
    }
}