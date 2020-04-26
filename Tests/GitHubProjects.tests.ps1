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
                $null = New-GitHubProject -UserProject -Name $defaultUserProject -Description $defaultUserProjectDesc
            }
            AfterAll {
                $null = Remove-GitHubProject -UserName $script:ownerName -Name $defaultUserProject
            }

            $results = Get-GitHubProject -UserName $script:ownerName -Name $defaultUserProject
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
                $null = New-GitHubProject -OrganizationName $script:organizationName -Name $defaultOrgProject -Description $defaultOrgProjectDesc
            }
            AfterAll {
                $null = Remove-GitHubProject -OrganizationName $script:organizationName -Name $defaultOrgProject
            }

            $results = Get-GitHubProject -OrganizationName $script:organizationName -Name $defaultOrgProject
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
                $null = New-GitHubProject -OwnerName $script:ownerName -RepositoryName $repo.name -Name $defaultRepoProject -Description $defaultRepoProjectDesc
            }
            AfterAll {
                $null = Remove-GitHubProject -OwnerName $script:ownerName -RepositoryName $repo.name -Name $defaultRepoProject
            }

            $results = Get-GitHubProject -OwnerName $script:ownerName -RepositoryName $repo.name -Name $defaultRepoProject
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
                $null = New-GitHubProject -OwnerName $script:ownerName -RepositoryName $repo.name -Name $defaultProjectClosed -Description $defaultProjectClosedDesc
                $null = Set-GitHubProject -OwnerName $script:ownerName -RepositoryName $repo.name -Name $defaultProjectClosed -State Closed
            }
            AfterAll {
                $null = Remove-GitHubProject -OwnerName $script:ownerName -RepositoryName $repo.name -Name $defaultProjectClosed
            }

            $results = Get-GitHubProject -OwnerName $script:ownerName -RepositoryName $repo.name -State 'Closed' -Name $defaultProjectClosed
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
                $null = New-GitHubProject -UserProject -Name $defaultUserProject -Description $defaultUserProjectDesc
            }
            AfterAll {
                $null = Remove-GitHubProject -UserName $script:ownerName -Name $defaultUserProject
            }

            $null = Set-GitHubProject -UserName $script:ownerName -Name $defaultUserProject -Description $modifiedUserProjectDesc
            $results = Get-GitHubProject -UserName $script:ownerName -Name $defaultUserProject
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
                $null = New-GitHubProject -OrganizationName $script:organizationName -Name $defaultOrgProject -Description $defaultOrgProjectDesc
            }
            AfterAll {
                $null = Remove-GitHubProject -OrganizationName $script:organizationName -Name $defaultOrgProject
            }

            $null = Set-GitHubProject -OrganizationName $script:organizationName -Name $defaultOrgProject -Description $modifiedOrgProjectDesc -Private $false -OrganizationPermission Admin
            $results = Get-GitHubProject -OrganizationName $script:organizationName -Name $defaultOrgProject
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
                $null = New-GitHubProject -OwnerName $script:ownerName -RepositoryName $repo.name -Name $defaultRepoProject -Description $defaultRepoProjectDesc
            }
            AfterAll {
                $null = Remove-GitHubProject -OwnerName $script:ownerName -RepositoryName $repo.name -Name $defaultRepoProject
            }

            $null = Set-GitHubProject -OwnerName $script:ownerName -RepositoryName $repo.name -Name $defaultRepoProject -Description $modifiedRepoProjectDesc
            $results = Get-GitHubProject -OwnerName $script:ownerName -RepositoryName $repo.name -Name $defaultRepoProject
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

        Context 'Modify project using uri' {
            BeforeAll {
                $null = New-GitHubProject -OwnerName $script:ownerName -RepositoryName $repo.name -Name $defaultRepoProject -Description $defaultRepoProjectDesc
            }
            AfterAll {
                $null = Remove-GitHubProject -OwnerName $script:ownerName -RepositoryName $repo.name -Name $defaultRepoProject
            }

            $null = Set-GitHubProject -Uri ('https://github.com/{0}/{1}' -f $script:ownerName, $repo.name) -Name $defaultRepoProject -Description $modifiedRepoProjectDesc
            $results = Get-GitHubProject -OwnerName $script:ownerName -RepositoryName $repo.name -Name $defaultRepoProject
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
            AfterAll {
                $null = Remove-GitHubProject -UserName $script:ownerName -Name $defaultUserProject
            }

            $null = New-GitHubProject -UserProject -Name $defaultUserProject -Description $defaultUserProjectDesc
            $results = Get-GitHubProject -UserName $script:ownerName -Name $defaultUserProject
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
            AfterAll {
                $null = Remove-GitHubProject -OrganizationName $script:organizationName -Name $defaultOrgProject
            }

            $null = New-GitHubProject -OrganizationName $script:organizationName -Name $defaultOrgProject -Description $defaultOrgProjectDesc
            $results = Get-GitHubProject -OrganizationName $script:organizationName -Name $defaultOrgProject
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
            AfterAll {
                $null = Remove-GitHubProject -OwnerName $script:ownerName -RepositoryName $repo.name -Name $defaultRepoProject
            }

            $null = New-GitHubProject -OwnerName $script:ownerName -RepositoryName $repo.name -Name $defaultRepoProject -Description $defaultRepoProjectDesc
            $results = Get-GitHubProject -OwnerName $script:ownerName -RepositoryName $repo.name -Name $defaultRepoProject
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
                $null = New-GitHubProject -UserProject -Name $defaultUserProject -Description $defaultUserProjectDesc
            }

            $null = Remove-GitHubProject -UserName $script:ownerName -Name $defaultUserProject
            $results = Get-GitHubProject -UserName $script:ownerName -Name $defaultUserProject
            It 'Project should be removed' {
                $results | Should BeNullOrEmpty
            }
        }

        Context 'Remove Organization projects' {
            BeforeAll {
                $null = New-GitHubProject -OrganizationName $script:organizationName -Name $defaultOrgProject -Description $defaultOrgProjectDesc
            }

            $null = Remove-GitHubProject -OrganizationName $script:organizationName -Name $defaultOrgProject
            $results = Get-GitHubProject -OrganizationName $script:organizationName -Name $defaultOrgProject
            It 'Project should be removed' {
                $results | Should BeNullOrEmpty
            }
        }

        Context 'Remove Repo projects' {
            BeforeAll {
                $null = New-GitHubProject -OwnerName $script:ownerName -RepositoryName $repo.name -Name $defaultRepoProject -Description $defaultRepoProjectDesc
            }

            $null = Remove-GitHubProject -OwnerName $script:ownerName -RepositoryName $repo.name -Name $defaultRepoProject
            $results = Get-GitHubProject -OwnerName $script:ownerName -RepositoryName $repo.name -Name $defaultRepoProject
            It 'Project should be removed' {
                $results | Should  BeNullOrEmpty
            }
        }

        Context 'Remove project by id' {
            BeforeAll {
                $repoProject = New-GitHubProject -OwnerName $script:ownerName -RepositoryName $repo.name -Name $defaultRepoProject -Description $defaultRepoProjectDesc
            }

            $null = Remove-GitHubProject -Project $repoProject.id

            try
            {
                $results = Get-GitHubProject -Project $repoProject.id
            }
            catch {
                $null
            }

            It 'Project should be removed' {
                $results | Should  BeNullOrEmpty
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
