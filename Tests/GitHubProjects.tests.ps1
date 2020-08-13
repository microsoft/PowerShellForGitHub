# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

<#
.Synopsis
   Tests for GitHubProjects.ps1 module
#>

[CmdletBinding()]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '',
    Justification='Suppress false positives in Pester code blocks')]
param()

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
                $project = New-GitHubProject -UserProject -ProjectName $defaultUserProject -Description $defaultUserProjectDesc
            }

            AfterAll {
                $null = Remove-GitHubProject -Project $project.id -Confirm:$false
            }

            $results = @(Get-GitHubProject -UserName $script:ownerName | Where-Object Name -eq $defaultUserProject)
            It 'Should get project' {
                $results | Should -Not -BeNullOrEmpty
            }

            It 'Should only get a single project' {
                $results.Count | Should -Be 1
            }

            It 'Name is correct' {
                $results[0].name | Should -Be $defaultUserProject
            }

            It 'Description is correct' {
                $results[0].body | Should -Be $defaultUserProjectDesc
            }

            It 'Should have the expected type and additional properties' {
                $results[0].PSObject.TypeNames[0] | Should -Be 'GitHub.Project'
                $results[0].RepositoryUrl | Should -BeNullOrEmpty # no RepositoryUrl for user projects
                $results[0].ProjectId | Should -Be $results[0].id
            }
        }

        Context 'Get Organization projects' {
            BeforeAll {
                $project = New-GitHubProject -OrganizationName $script:organizationName -ProjectName $defaultOrgProject -Description $defaultOrgProjectDesc
            }

            AfterAll {
                $null = Remove-GitHubProject -Project $project.id -Confirm:$false
            }

            $results = @(Get-GitHubProject -OrganizationName $script:organizationName | Where-Object Name -eq $defaultOrgProject)
            It 'Should get project' {
                $results | Should -Not -BeNullOrEmpty
            }

            It 'Should only get a single project' {
                $results.Count | Should -Be 1
            }

            It 'Name is correct' {
                $results[0].name | Should -Be $defaultOrgProject
            }

            It 'Description is correct' {
                $results[0].body | Should -Be $defaultOrgProjectDesc
            }

            It 'Should have the expected type and additional properties' {
                $elements = Split-GitHubUri -Uri $results[0].html_url
                $repositoryUrl = Join-GitHubUri @elements

                $results[0].PSObject.TypeNames[0] | Should -Be 'GitHub.Project'
                $results[0].RepositoryUrl | Should -Be $repositoryUrl
                $results[0].ProjectId | Should -Be $results[0].id
            }
        }

        Context 'Get Repo projects' {
            BeforeAll {
                $project = New-GitHubProject -OwnerName $script:ownerName -RepositoryName $repo.name -ProjectName $defaultRepoProject -Description $defaultRepoProjectDesc
            }

            AfterAll {
                $null = Remove-GitHubProject -Project $project.id -Confirm:$false
            }

            $results = @(Get-GitHubProject -OwnerName $script:ownerName -RepositoryName $repo.name | Where-Object Name -eq $defaultRepoProject)
            It 'Should get project' {
                $results | Should -Not -BeNullOrEmpty
            }

            It 'Should only get a single project' {
                $results.Count | Should -Be 1
            }

            It 'Name is correct' {
                $results[0].name | Should -Be $defaultRepoProject
            }

            It 'Description is correct' {
                $results[0].body | Should -Be $defaultRepoProjectDesc
            }

            It 'Should have the expected type and additional properties' {
                $results[0].PSObject.TypeNames[0] | Should -Be 'GitHub.Project'
                $results[0].RepositoryUrl | Should -Be $repo.RepositoryUrl
                $results[0].ProjectId | Should -Be $results[0].id
                $results[0].creator.PSObject.TypeNames[0] | Should -Be 'GitHub.User'
            }
        }

        Context 'Get a closed Repo project (via pipeline)' {
            BeforeAll {
                $project = $repo | New-GitHubProject -ProjectName $defaultProjectClosed -Description $defaultProjectClosedDesc
                Set-GitHubProject -Project $project.id -State Closed
            }

            AfterAll {
                $null = Remove-GitHubProject -Project $project.id -Confirm:$false
            }

            $results = @($repo | Get-GitHubProject -State 'Closed')
            It 'Should get project' {
                $results | Should -Not -BeNullOrEmpty
            }

            It 'Should only get a single project' {
                $results.Count | Should -Be 1
            }

            It 'Name is correct' {
                $results[0].name | Should -Be $defaultProjectClosed
            }

            It 'Description is correct' {
                $results[0].body | Should -Be $defaultProjectClosedDesc
            }

            It 'State is correct' {
                $results[0].state | Should -Be "Closed"
            }

            It 'Should have the expected type and additional properties' {
                $results[0].PSObject.TypeNames[0] | Should -Be 'GitHub.Project'
                $results[0].RepositoryUrl | Should -Be $repo.RepositoryUrl
                $results[0].ProjectId | Should -Be $results[0].id
                $results[0].creator.PSObject.TypeNames[0] | Should -Be 'GitHub.User'
            }
        }

        Context 'Get a specific project (by parameter)' {
            BeforeAll {
                $project = New-GitHubProject -OwnerName $script:ownerName -RepositoryName $repo.name -ProjectName $defaultRepoProject -Description $defaultRepoProjectDesc
            }

            AfterAll {
                $null = Remove-GitHubProject -Project $project.id -Confirm:$false
            }

            $result = Get-GitHubProject -Project $project.id
            It 'Should get project' {
                $result | Should -Not -BeNullOrEmpty
            }

            It 'Name is correct' {
                $result.name | Should -Be $defaultRepoProject
            }

            It 'Description is correct' {
                $result.body | Should -Be $defaultRepoProjectDesc
            }

            It 'Should have the expected type and additional properties' {
                $result.PSObject.TypeNames[0] | Should -Be 'GitHub.Project'
                $result.RepositoryUrl | Should -Be $repo.RepositoryUrl
                $result.ProjectId | Should -Be $project.id
                $result.creator.PSObject.TypeNames[0] | Should -Be 'GitHub.User'
            }
        }

        Context 'Get a specific project (by pipeline object)' {
            BeforeAll {
                $project = $repo | New-GitHubProject -ProjectName $defaultRepoProject -Description $defaultRepoProjectDesc
            }

            AfterAll {
                $project | Remove-GitHubProject -Force
            }

            $result = $project | Get-GitHubProject
            It 'Should get the right project' {
                $result.id | Should -Be $project.id
            }

            It 'Should have the expected type and additional properties' {
                $result.PSObject.TypeNames[0] | Should -Be 'GitHub.Project'
                $result.RepositoryUrl | Should -Be $repo.RepositoryUrl
                $result.ProjectId | Should -Be $project.id
                $result.creator.PSObject.TypeNames[0] | Should -Be 'GitHub.User'
            }
        }

        Context 'Get a specific project (with ID via pipeline)' {
            BeforeAll {
                $project = $repo | New-GitHubProject -ProjectName $defaultRepoProject -Description $defaultRepoProjectDesc
            }

            AfterAll {
                $project | Remove-GitHubProject -Force
            }

            $result = $project.id | Get-GitHubProject
            It 'Should get the right project' {
                $result.id | Should -Be $project.id
            }

            It 'Should have the expected type and additional properties' {
                $result.PSObject.TypeNames[0] | Should -Be 'GitHub.Project'
                $result.RepositoryUrl | Should -Be $repo.RepositoryUrl
                $result.ProjectId | Should -Be $project.id
                $result.creator.PSObject.TypeNames[0] | Should -Be 'GitHub.User'
            }
        }
    }

    Describe 'Modify Project' {
        Context 'Modify User projects' {
            BeforeAll {
                $project = New-GitHubProject -UserProject -ProjectName $defaultUserProject -Description $defaultUserProjectDesc
            }

            AfterAll {
                $null = Remove-GitHubProject -Project $project.id -Confirm:$false
            }

            Set-GitHubProject -Project $project.id -Description $modifiedUserProjectDesc
            $result = Get-GitHubProject -Project $project.id
            It 'Should get project' {
                $result | Should -Not -BeNullOrEmpty
            }

            It 'Name is correct' {
                $result.name | Should -Be $defaultUserProject
            }

            It 'Description should be updated' {
                $result.body | Should -Be $modifiedUserProjectDesc
            }

            It 'Should have the expected type and additional properties' {
                $result.PSObject.TypeNames[0] | Should -Be 'GitHub.Project'
                $result.RepositoryUrl | Should -BeNullOrEmpty # no RepositoryUrl for user projects
                $result.ProjectId | Should -Be $result.id
                $result.creator.PSObject.TypeNames[0] | Should -Be 'GitHub.User'
            }
        }

        Context 'Modify User projects (via ID in pipeline)' {
            BeforeAll {
                $project = New-GitHubProject -UserProject -ProjectName $defaultUserProject -Description $defaultUserProjectDesc
            }

            AfterAll {
                $null = Remove-GitHubProject -Project $project.id -Confirm:$false
            }

            $project.id | Set-GitHubProject -Description $modifiedUserProjectDesc
            $result = Get-GitHubProject -Project $project.id
            It 'Should get project' {
                $result | Should -Not -BeNullOrEmpty
            }

            It 'Name is correct' {
                $result.name | Should -Be $defaultUserProject
            }

            It 'Description should be updated' {
                $result.body | Should -Be $modifiedUserProjectDesc
            }

            It 'Should have the expected type and additional properties' {
                $result.PSObject.TypeNames[0] | Should -Be 'GitHub.Project'
                $result.RepositoryUrl | Should -BeNullOrEmpty # no RepositoryUrl for user projects
                $result.ProjectId | Should -Be $result.id
                $result.creator.PSObject.TypeNames[0] | Should -Be 'GitHub.User'
            }
        }

        Context 'Modify User projects (via object in pipeline)' {
            BeforeAll {
                $project = New-GitHubProject -UserProject -ProjectName $defaultUserProject -Description $defaultUserProjectDesc
            }

            AfterAll {
                $null = Remove-GitHubProject -Project $project.id -Confirm:$false
            }

            $project | Set-GitHubProject -Description $modifiedUserProjectDesc
            $result = Get-GitHubProject -Project $project.id
            It 'Should get project' {
                $result | Should -Not -BeNullOrEmpty
            }

            It 'Name is correct' {
                $result.name | Should -Be $defaultUserProject
            }

            It 'Description should be updated' {
                $result.body | Should -Be $modifiedUserProjectDesc
            }

            It 'Should have the expected type and additional properties' {
                $result.PSObject.TypeNames[0] | Should -Be 'GitHub.Project'
                $result.RepositoryUrl | Should -BeNullOrEmpty # no RepositoryUrl for user projects
                $result.ProjectId | Should -Be $result.id
                $result.creator.PSObject.TypeNames[0] | Should -Be 'GitHub.User'
            }
        }

        Context 'Modify Organization projects' {
            BeforeAll {
                $project = New-GitHubProject -OrganizationName $script:organizationName -ProjectName $defaultOrgProject -Description $defaultOrgProjectDesc
            }

            AfterAll {
                $null = Remove-GitHubProject -Project $project.id -Confirm:$false
            }

            Set-GitHubProject -Project $project.id -Description $modifiedOrgProjectDesc -Private:$false -OrganizationPermission Admin
            $result = Get-GitHubProject -Project $project.id
            It 'Should get project' {
                $result | Should -Not -BeNullOrEmpty
            }

            It 'Name is correct' {
                $result.name | Should -Be $defaultOrgProject
            }

            It 'Description should be updated' {
                $result.body | Should -Be $modifiedOrgProjectDesc
            }

            It 'Visibility should be updated to public' {
                $result.private | Should -Be $false
            }

            It 'Organization permission should be updated to admin' {
                $result.organization_permission | Should -Be 'admin'
            }

            It 'Should have the expected type and additional properties' {
                $elements = Split-GitHubUri -Uri $result.html_url
                $repositoryUrl = Join-GitHubUri @elements

                $result.PSObject.TypeNames[0] | Should -Be 'GitHub.Project'
                $result.RepositoryUrl | Should -Be $repositoryUrl
                $result.ProjectId | Should -Be $result.id
                $result.creator.PSObject.TypeNames[0] | Should -Be 'GitHub.User'
            }
        }

        Context 'Modify Repo projects' {
            BeforeAll {
                $project = New-GitHubProject -OwnerName $script:ownerName -RepositoryName $repo.name -ProjectName $defaultRepoProject -Description $defaultRepoProjectDesc
            }

            AfterAll {
                $null = Remove-GitHubProject -Project $project.id -Confirm:$false
            }

            Set-GitHubProject -Project $project.id -Description $modifiedRepoProjectDesc
            $result = Get-GitHubProject -Project $project.id
            It 'Should get project' {
                $result | Should -Not -BeNullOrEmpty
            }

            It 'Name is correct' {
                $result.name | Should -Be $defaultRepoProject
            }

            It 'Description should be updated' {
                $result.body | Should -Be $modifiedRepoProjectDesc
            }

            It 'Should have the expected type and additional properties' {
                $result.PSObject.TypeNames[0] | Should -Be 'GitHub.Project'
                $result.RepositoryUrl | Should -Be $repo.RepositoryUrl
                $result.ProjectId | Should -Be $result.id
                $result.creator.PSObject.TypeNames[0] | Should -Be 'GitHub.User'
            }
        }
    }

    Describe 'Create Project' {
        Context 'Create User projects' {
            BeforeAll {
                $project = @{id = 0}
            }

            AfterAll {
                $null = Remove-GitHubProject -Project $project.id -Confirm:$false
                Remove-Variable project
            }

            $project.id = (New-GitHubProject -UserProject -ProjectName $defaultUserProject -Description $defaultUserProjectDesc).id
            $result = Get-GitHubProject -Project $project.id
            It 'Project exists' {
                $result | Should -Not -BeNullOrEmpty
            }

            It 'Name is correct' {
                $result.name | Should -Be $defaultUserProject
            }

            It 'Description should be updated' {
                $result.body | Should -Be $defaultUserProjectDesc
            }

            It 'Should have the expected type and additional properties' {
                $result.PSObject.TypeNames[0] | Should -Be 'GitHub.Project'
                $result.RepositoryUrl | Should -BeNullOrEmpty # no RepositoryUrl for user projects
                $result.ProjectId | Should -Be $result.id
                $result.creator.PSObject.TypeNames[0] | Should -Be 'GitHub.User'
            }
        }

        Context 'Create User project (title on pipeline)' {
            BeforeAll {
                $project = @{id = 0}
            }

            AfterAll {
                $null = Remove-GitHubProject -Project $project.id -Confirm:$false
                Remove-Variable project
            }

            $project.id = ($defaultUserProject | New-GitHubProject -UserProject -Description $defaultUserProjectDesc).id
            $result = Get-GitHubProject -Project $project.id
            It 'Project exists' {
                $result | Should -Not -BeNullOrEmpty
            }

            It 'Name is correct' {
                $result.name | Should -Be $defaultUserProject
            }

            It 'Description should be updated' {
                $result.body | Should -Be $defaultUserProjectDesc
            }

            It 'Should have the expected type and additional properties' {
                $result.PSObject.TypeNames[0] | Should -Be 'GitHub.Project'
                $result.RepositoryUrl | Should -BeNullOrEmpty # no RepositoryUrl for user projects
                $result.ProjectId | Should -Be $result.id
                $result.creator.PSObject.TypeNames[0] | Should -Be 'GitHub.User'
            }
        }

        Context 'Create Organization projects' {
            BeforeAll {
                $project = @{id = 0}
            }

            AfterAll {
                $null = Remove-GitHubProject -Project $project.id -Confirm:$false
                Remove-Variable project
            }

            $project.id = (New-GitHubProject -OrganizationName $script:organizationName -ProjectName $defaultOrgProject -Description $defaultOrgProjectDesc).id
            $result = Get-GitHubProject -Project $project.id
            It 'Project exists' {
                $result | Should -Not -BeNullOrEmpty
            }

            It 'Name is correct' {
                $result.name | Should -Be $defaultOrgProject
            }

            It 'Description should be updated' {
                $result.body | Should -Be $defaultOrgProjectDesc
            }

            It 'Should have the expected type and additional properties' {
                $elements = Split-GitHubUri -Uri $result.html_url
                $repositoryUrl = Join-GitHubUri @elements

                $result.PSObject.TypeNames[0] | Should -Be 'GitHub.Project'
                $result.RepositoryUrl | Should -Be $repositoryUrl
                $result.ProjectId | Should -Be $result.id
                $result.creator.PSObject.TypeNames[0] | Should -Be 'GitHub.User'
            }
        }

        Context 'Create Repo projects' {
            BeforeAll {
                $project = @{id = 0}
            }

            AfterAll {
                $null = Remove-GitHubProject -Project $project.id -Confirm:$false
                Remove-Variable project
            }

            $project.id = (New-GitHubProject -OwnerName $script:ownerName -RepositoryName $repo.name -ProjectName $defaultRepoProject -Description $defaultRepoProjectDesc).id
            $result = Get-GitHubProject -Project $project.id
            It 'Project Exists' {
                $result | Should -Not -BeNullOrEmpty
            }

            It 'Name is correct' {
                $result.name | Should -Be $defaultRepoProject
            }

            It 'Description should be updated' {
                $result.body | Should -Be $defaultRepoProjectDesc
            }

            It 'Should have the expected type and additional properties' {
                $result.PSObject.TypeNames[0] | Should -Be 'GitHub.Project'
                $result.RepositoryUrl | Should -Be $repo.RepositoryUrl
                $result.ProjectId | Should -Be $result.id
                $result.creator.PSObject.TypeNames[0] | Should -Be 'GitHub.User'
            }
        }

        Context 'Create Repo project (via pipeline)' {
            BeforeAll {
                $project = @{id = 0}
            }

            AfterAll {
                $null = Remove-GitHubProject -Project $project.id -Confirm:$false
                Remove-Variable project
            }

            $project.id = ($repo | New-GitHubProject -ProjectName $defaultRepoProject -Description $defaultRepoProjectDesc).id
            $result = Get-GitHubProject -Project $project.id
            It 'Project Exists' {
                $result | Should -Not -BeNullOrEmpty
            }

            It 'Name is correct' {
                $result.name | Should -Be $defaultRepoProject
            }

            It 'Description should be updated' {
                $result.body | Should -Be $defaultRepoProjectDesc
            }

            It 'Should have the expected type and additional properties' {
                $result.PSObject.TypeNames[0] | Should -Be 'GitHub.Project'
                $result.RepositoryUrl | Should -Be $repo.RepositoryUrl
                $result.ProjectId | Should -Be $result.id
                $result.creator.PSObject.TypeNames[0] | Should -Be 'GitHub.User'
            }
        }
    }

    Describe 'Remove Project' {
        Context 'Remove User projects' {
            $project = New-GitHubProject -UserProject -ProjectName $defaultUserProject -Description $defaultUserProjectDesc
            $null = Remove-GitHubProject -Project $project.id -Force
            It 'Project should be removed' {
                {Get-GitHubProject -Project $project.id} | Should -Throw
            }
        }

        Context 'Remove Organization projects' {
            $project = New-GitHubProject -OrganizationName $script:organizationName -ProjectName $defaultOrgProject -Description $defaultOrgProjectDesc
            $null = Remove-GitHubProject -Project $project.id -Force
            It 'Project should be removed' {
                {Get-GitHubProject -Project $project.id} | Should -Throw
            }
        }

        Context 'Remove Repo projects' {
            $project = New-GitHubProject -OwnerName $script:ownerName -RepositoryName $repo.name -ProjectName $defaultRepoProject -Description $defaultRepoProjectDesc
            $null = Remove-GitHubProject -Project $project.id -Confirm:$false

            # Despite using StateChangeDelaySeconds during tests, we still appear to need more time
            # for projects to be removed before testing that they were properly deleted.
            Start-Sleep -Seconds 5

            It 'Project should be removed' {
                {Get-GitHubProject -Project $project.id} | Should -Throw
            }
        }

        Context 'Remove Repo project via pipeline' {
            $project = $repo | New-GitHubProject -ProjectName $defaultRepoProject -Description $defaultRepoProjectDesc
            $project | Remove-GitHubProject -Force

            # Despite using StateChangeDelaySeconds during tests, we still appear to need more time
            # for projects to be removed before testing that they were properly deleted.
            Start-Sleep -Seconds 5

            It 'Project should be removed' {
                {$project | Get-GitHubProject} | Should -Throw
            }
        }
    }

    Remove-GitHubRepository -Uri $repo.svn_url -Confirm:$false
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
