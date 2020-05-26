# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

<#
.Synopsis
   Tests for GitHubProjects.ps1 module
#>

# This is common test code setup logic for all Pester test files
$moduleRootPath = Split-Path -Path $PSScriptRoot -Parent
. (Join-Path -Path $moduleRootPath -ChildPath 'Tests\Common.ps1')

try
{
    # Define Script-scoped, readOnly, hidden variables.
    @{
        defaultUserProject = "TestProject_$([Guid]::NewGuid().Guid)"
        defaultUserProjectDesc = "This is my desc for user project"
        modifiedUserProjectDesc = "Desc has been modified"

        defaultRepoProject = "TestRepoProject_$([Guid]::NewGuid().Guid)"
        defaultRepoProjectDesc = "This is my desc for repo project"
        modifiedRepoProjectDesc = "Desc has been modified"

        defaultOrgProject = "TestOrgProject_$([Guid]::NewGuid().Guid)"
        defaultOrgProjectDesc = "This is my desc for org project"
        modifiedOrgProjectDesc = "Desc has been modified"

        defaultProjectClosed = "TestClosedProject"
        defaultProjectClosedDesc = "I'm a closed project"
    }.GetEnumerator() | ForEach-Object {
        Set-Variable -Force -Scope Script -Option ReadOnly -Visibility Private -Name $_.Key -Value $_.Value
    }

    $repo = New-GitHubRepository -RepositoryName ([Guid]::NewGuid().Guid) -AutoInit

    Describe 'Getting Project' {
        Context 'Get User projects' {
            BeforeAll {
                $project = New-GitHubProject -UserProject -Name $defaultUserProject -Description $defaultUserProjectDesc

                # Avoid PSScriptAnalyzer PSUseDeclaredVarsMoreThanAssignments
                $project = $project
            }

            AfterAll {
                $null = Remove-GitHubProject -Project $project.id -Confirm:$false
            }

            $results = Get-GitHubProject -UserName $script:ownerName | Where-Object Name -eq $defaultUserProject
            It 'Should get project' {
                $results | Should Not BeNullOrEmpty
            }

            It 'Name is correct' {
                $results.name | Should be $defaultUserProject
            }

            It 'Description is correct' {
                $results.body | Should be $defaultUserProjectDesc
            }
        }

        Context 'Get Organization projects' {
            BeforeAll {
                $project = New-GitHubProject -OrganizationName $script:organizationName -Name $defaultOrgProject -Description $defaultOrgProjectDesc

                # Avoid PSScriptAnalyzer PSUseDeclaredVarsMoreThanAssignments
                $project = $project
            }

            AfterAll {
                $null = Remove-GitHubProject -Project $project.id -Confirm:$false
            }

            $results = Get-GitHubProject -OrganizationName $script:organizationName | Where-Object Name -eq $defaultOrgProject
            It 'Should get project' {
                $results | Should Not BeNullOrEmpty
            }

            It 'Name is correct' {
                $results.name | Should be $defaultOrgProject
            }

            It 'Description is correct' {
                $results.body | Should be $defaultOrgProjectDesc
            }
        }

        Context 'Get Repo projects' {
            BeforeAll {
                $project = New-GitHubProject -OwnerName $script:ownerName -RepositoryName $repo.name -Name $defaultRepoProject -Description $defaultRepoProjectDesc

                # Avoid PSScriptAnalyzer PSUseDeclaredVarsMoreThanAssignments
                $project = $project
            }

            AfterAll {
                $null = Remove-GitHubProject -Project $project.id -Confirm:$false
            }

            $results = Get-GitHubProject -OwnerName $script:ownerName -RepositoryName $repo.name | Where-Object Name -eq $defaultRepoProject
            It 'Should get project' {
                $results | Should Not BeNullOrEmpty
            }

            It 'Name is correct' {
                $results.name | Should be $defaultRepoProject
            }

            It 'Description is correct' {
                $results.body | Should be $defaultRepoProjectDesc
            }
        }

        Context 'Get a closed Repo project' {
            BeforeAll {
                $project = New-GitHubProject -OwnerName $script:ownerName -RepositoryName $repo.name -Name $defaultProjectClosed -Description $defaultProjectClosedDesc
                $null = Set-GitHubProject -Project $project.id -State Closed

                # Avoid PSScriptAnalyzer PSUseDeclaredVarsMoreThanAssignments
                $project = $project
            }

            AfterAll {
                $null = Remove-GitHubProject -Project $project.id -Confirm:$false
            }

            $results = Get-GitHubProject -OwnerName $script:ownerName -RepositoryName $repo.name -State 'Closed' | Where-Object Name -eq $defaultProjectClosed
            It 'Should get project' {
                $results | Should Not BeNullOrEmpty
            }

            It 'Name is correct' {
                $results.name | Should be $defaultProjectClosed
            }

            It 'Description is correct' {
                $results.body | Should be $defaultProjectClosedDesc
            }

            It 'State is correct' {
                $results.state | Should be "Closed"
            }
        }
    }

    Describe 'Modify Project' {
        Context 'Modify User projects' {
            BeforeAll {
                $project = New-GitHubProject -UserProject -Name $defaultUserProject -Description $defaultUserProjectDesc

                # Avoid PSScriptAnalyzer PSUseDeclaredVarsMoreThanAssignments
                $project = $project
            }

            AfterAll {
                $null = Remove-GitHubProject -Project $project.id -Confirm:$false
            }

            $null = Set-GitHubProject -Project $project.id -Description $modifiedUserProjectDesc
            $results = Get-GitHubProject -Project $project.id
            It 'Should get project' {
                $results | Should Not BeNullOrEmpty
            }

            It 'Name is correct' {
                $results.name | Should be $defaultUserProject
            }

            It 'Description should be updated' {
                $results.body | Should be $modifiedUserProjectDesc
            }
        }

        Context 'Modify Organization projects' {
            BeforeAll {
                $project = New-GitHubProject -OrganizationName $script:organizationName -Name $defaultOrgProject -Description $defaultOrgProjectDesc

                # Avoid PSScriptAnalyzer PSUseDeclaredVarsMoreThanAssignments
                $project = $project
            }

            AfterAll {
                $null = Remove-GitHubProject -Project $project.id -Confirm:$false
            }

            $null = Set-GitHubProject -Project $project.id -Description $modifiedOrgProjectDesc -Private:$false -OrganizationPermission Admin
            $results = Get-GitHubProject -Project $project.id
            It 'Should get project' {
                $results | Should Not BeNullOrEmpty
            }

            It 'Name is correct' {
                $results.name | Should be $defaultOrgProject
            }

            It 'Description should be updated' {
                $results.body | Should be $modifiedOrgProjectDesc
            }

            It 'Visibility should be updated to public' {
                $results.private | Should be $false
            }

            It 'Organization permission should be updated to admin' {
                $results.organization_permission | Should be 'admin'
            }

        }

        Context 'Modify Repo projects' {
            BeforeAll {
                $project = New-GitHubProject -OwnerName $script:ownerName -RepositoryName $repo.name -Name $defaultRepoProject -Description $defaultRepoProjectDesc

                # Avoid PSScriptAnalyzer PSUseDeclaredVarsMoreThanAssignments
                $project = $project
            }

            AfterAll {
                $null = Remove-GitHubProject -Project $project.id -Confirm:$false
            }

            $null = Set-GitHubProject -Project $project.id -Description $modifiedRepoProjectDesc
            $results = Get-GitHubProject -Project $project.id
            It 'Should get project' {
                $results | Should Not BeNullOrEmpty
            }

            It 'Name is correct' {
                $results.name | Should be $defaultRepoProject
            }

            It 'Description should be updated' {
                $results.body | Should be $modifiedRepoProjectDesc
            }
        }
    }

    Describe 'Create Project' {
        Context 'Create User projects' {
            BeforeAll {
                $project = @{id = 0}

                # Avoid PSScriptAnalyzer PSUseDeclaredVarsMoreThanAssignments
                $project = $project
            }

            AfterAll {
                $null = Remove-GitHubProject -Project $project.id -Confirm:$false
                Remove-Variable project
            }

            $project.id = (New-GitHubProject -UserProject -Name $defaultUserProject -Description $defaultUserProjectDesc).id
            $results = Get-GitHubProject -Project $project.id
            It 'Project exists' {
                $results | Should Not BeNullOrEmpty
            }

            It 'Name is correct' {
                $results.name | Should be $defaultUserProject
            }

            It 'Description should be updated' {
                $results.body | Should be $defaultUserProjectDesc
            }
        }

        Context 'Create Organization projects' {
            BeforeAll {
                $project = @{id = 0}

                # Avoid PSScriptAnalyzer PSUseDeclaredVarsMoreThanAssignments
                $project = $project
            }

            AfterAll {
                $null = Remove-GitHubProject -Project $project.id -Confirm:$false
                Remove-Variable project
            }

            $project.id = (New-GitHubProject -OrganizationName $script:organizationName -Name $defaultOrgProject -Description $defaultOrgProjectDesc).id
            $results = Get-GitHubProject -Project $project.id
            It 'Project exists' {
                $results | Should Not BeNullOrEmpty
            }

            It 'Name is correct' {
                $results.name | Should be $defaultOrgProject
            }

            It 'Description should be updated' {
                $results.body | Should be $defaultOrgProjectDesc
            }
        }

        Context 'Create Repo projects' {
            BeforeAll {
                $project = @{id = 0}

                # Avoid PSScriptAnalyzer PSUseDeclaredVarsMoreThanAssignments
                $project = $project
            }

            AfterAll {
                $null = Remove-GitHubProject -Project $project.id -Confirm:$false
                Remove-Variable project
            }

            $project.id = (New-GitHubProject -OwnerName $script:ownerName -RepositoryName $repo.name -Name $defaultRepoProject -Description $defaultRepoProjectDesc).id
            $results = Get-GitHubProject -Project $project.id
            It 'Project Exists' {
                $results | Should Not BeNullOrEmpty
            }

            It 'Name is correct' {
                $results.name | Should be $defaultRepoProject
            }

            It 'Description should be updated' {
                $results.body | Should be $defaultRepoProjectDesc
            }
        }
    }

    Describe 'Remove Project' {
        Context 'Remove User projects' {
            BeforeAll {
                $project = New-GitHubProject -UserProject -Name $defaultUserProject -Description $defaultUserProjectDesc

                # Avoid PSScriptAnalyzer PSUseDeclaredVarsMoreThanAssignments
                $project = $project
            }

            $null = Remove-GitHubProject -Project $project.id -Confirm:$false
            It 'Project should be removed' {
                {Get-GitHubProject -Project $project.id} | Should Throw
            }
        }

        Context 'Remove Organization projects' {
            BeforeAll {
                $project = New-GitHubProject -OrganizationName $script:organizationName -Name $defaultOrgProject -Description $defaultOrgProjectDesc

                # Avoid PSScriptAnalyzer PSUseDeclaredVarsMoreThanAssignments
                $project = $project
            }

            $null = Remove-GitHubProject -Project $project.id -Confirm:$false
            It 'Project should be removed' {
                {Get-GitHubProject -Project $project.id} | Should Throw
            }
        }

        Context 'Remove Repo projects' {
            BeforeAll {
                $project = New-GitHubProject -OwnerName $script:ownerName -RepositoryName $repo.name -Name $defaultRepoProject -Description $defaultRepoProjectDesc

                # Avoid PSScriptAnalyzer PSUseDeclaredVarsMoreThanAssignments
                $project = $project
            }

            $null = Remove-GitHubProject -Project $project.id -Confirm:$false
            It 'Project should be removed' {
                {Get-GitHubProject -Project $project.id} | Should Throw
            }
        }
    }

    Remove-GitHubRepository -Uri $repo.svn_url
}
finally
{
    if (Test-Path -Path $script:originalConfigFile -PathType Leaf)
    {
        # Restore the user's configuration to its pre-test state
        Restore-GitHubConfiguration -Path $script:originalConfigFile
        $script:originalConfigFile = $null
    }
}
