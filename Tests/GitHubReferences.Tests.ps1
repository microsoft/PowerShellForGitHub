# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

<#
.Synopsis
   Tests for GitHubReferences.ps1 module
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
    # Script-scoped, hidden, readonly variables.
    @{
        repoGuid = [Guid]::NewGuid().Guid
        masterBranchName = "master"
        branchName = [Guid]::NewGuid().ToString()
        tagName = [Guid]::NewGuid().ToString()
    }.GetEnumerator() | ForEach-Object {
        Set-Variable -Force -Scope Script -Option ReadOnly -Visibility Private -Name $_.Key -Value $_.Value
    }

    Describe 'Create a new branch in repository' {
        BeforeAll {
            # AutoInit will create a readme with the GUID of the repo name
            $repo = New-GitHubRepository -RepositoryName ($repoGuid) -AutoInit
            $existingref = Get-GitHubReference -OwnerName $script:ownerName -RepositoryName $repo.name -BranchName $masterBranchName
            $sha = $existingref.object.sha
        }

        AfterAll {
            Remove-GitHubRepository -Uri $repo.svn_url -Confirm:$false
        }

        Context 'On creating a new branch in a repository from a valid SHA' {
            $branch = [Guid]::NewGuid().ToString()
            $reference = New-GitHubReference -OwnerName $script:ownerName -RepositoryName $repo.name -BranchName $branch -Sha $sha

            It 'Should successfully create the new branch and have expected additional properties' {
                $reference.PSObject.TypeNames[0] | Should -Be 'GitHub.Reference'
                $reference.RepositoryUrl | Should -Be $repo.RepositoryUrl
                $reference.BranchName | Should -Be $branch
            }

            It 'Should throw an Exception when trying to create it again' {
                { New-GitHubReference -OwnerName $script:ownerName -RepositoryName $repo.name -BranchName $branch -Sha $sha } |
                    Should -Throw
            }
        }

        Context 'On creating a new branch in a repository (specified by Uri) from a valid SHA' {
            $branch = [Guid]::NewGuid().ToString()

            $reference = New-GitHubReference -Uri $repo.svn_url -BranchName $branch -Sha $sha

            It 'Should successfully create the new branch and have expected additional properties' {
                $reference.PSObject.TypeNames[0] | Should -Be 'GitHub.Reference'
                $reference.RepositoryUrl | Should -Be $repo.RepositoryUrl
                $reference.BranchName | Should -Be $branch
            }

            It 'Should throw an exception when trying to create it again' {
                { New-GitHubReference -Uri $repo.svn_url -BranchName $branch -Sha $sha }  | Should -Throw
            }
        }

        Context 'On creating a new branch in a repository with the repo on the pipeline' {
            $branch = [Guid]::NewGuid().ToString()

            $reference = $repo | New-GitHubReference -BranchName $branch -Sha $sha

            It 'Should successfully create the new branch and have expected additional properties' {
                $reference.PSObject.TypeNames[0] | Should -Be 'GitHub.Reference'
                $reference.RepositoryUrl | Should -Be $repo.RepositoryUrl
                $reference.BranchName | Should -Be $branch
            }

            It 'Should throw an exception when trying to create it again' {
                { $repo | New-GitHubReference -BranchName $branch -Sha $sha }  | Should -Throw
            }
        }
    }

    Describe 'Create a new tag in a repository' {
        BeforeAll {
            # AutoInit will create a readme with the GUID of the repo name
            $repo = New-GitHubRepository -RepositoryName ($repoGuid) -AutoInit
            $existingref = Get-GitHubReference -OwnerName $script:ownerName -RepositoryName $repo.name -BranchName $masterBranchName
            $sha = $existingref.object.sha
        }

        AfterAll {
            Remove-GitHubRepository -Uri $repo.svn_url -Confirm:$false
        }

        Context 'On creating a new tag in a repository referring to a given SHA' {
            $tag = [Guid]::NewGuid().ToString()
            $reference = New-GitHubReference -OwnerName $script:ownerName -RepositoryName $repo.name -TagName $tag -Sha $sha

            It 'Should successfully create the new tag and have expected additional properties' {
                $reference.PSObject.TypeNames[0] | Should -Be 'GitHub.Reference'
                $reference.RepositoryUrl | Should -Be $repo.RepositoryUrl
                $reference.TagName | Should -Be $tag
            }

            It 'Should throw an Exception when trying to create it again' {
                { New-GitHubReference -OwnerName $script:ownerName -RepositoryName $repo.name -TagName $tag -Sha $sha } | Should -Throw
            }
        }

        Context 'On creating a new tag in a repository (specified by Uri) from a given SHA' {
            $tag = [Guid]::NewGuid().ToString()

            $reference = New-GitHubReference -Uri $repo.svn_url -TagName $tag -Sha $sha

            It 'Should successfully create the new tag and have expected additional properties' {
                $reference.PSObject.TypeNames[0] | Should -Be 'GitHub.Reference'
                $reference.RepositoryUrl | Should -Be $repo.RepositoryUrl
                $reference.TagName | Should -Be $tag
            }

            It 'Should throw an exception when trying to create it again' {
                { New-GitHubReference -Uri $repo.svn_url -TagName $tag -Sha $sha }  | Should -Throw
            }
        }

        Context 'On creating a new tag in a repository with the repo on the pipeline' {
            $tag = [Guid]::NewGuid().ToString()

            $reference = $repo | New-GitHubReference -TagName $tag -Sha $sha

            It 'Should successfully create the new tag and have expected additional properties' {
                $reference.PSObject.TypeNames[0] | Should -Be 'GitHub.Reference'
                $reference.RepositoryUrl | Should -Be $repo.RepositoryUrl
                $reference.TagName | Should -Be $tag
            }

            It 'Should throw an exception when trying to create it again' {
                { $repo | New-GitHubReference -TagName $tag -Sha $sha }  | Should -Throw
            }
        }
    }

    Describe 'Getting branch(es) from repository' {
        BeforeAll {
            # AutoInit will create a readme with the GUID of the repo name
            $repo = New-GitHubRepository -RepositoryName ($repoGuid) -AutoInit
            $existingref = Get-GitHubReference -OwnerName $script:ownerName -RepositoryName $repo.name -BranchName $masterBranchName
            $sha = $existingref.object.sha
            $randomBranchName = [Guid]::NewGuid()
        }

        AfterAll {
            Remove-GitHubRepository -Uri $repo.svn_url -Confirm:$false
        }

        Context 'On getting an existing branch from a repository' {
            $reference = Get-GitHubReference -OwnerName $script:ownerName -RepositoryName $repo.name -BranchName $masterBranchName

            It 'Should return details for that branch and have expected additional properties' {
                $reference.PSObject.TypeNames[0] | Should -Be 'GitHub.Reference'
                $reference.RepositoryUrl | Should -Be $repo.RepositoryUrl
                $reference.BranchName | Should -Be $masterBranchName
            }
        }

        Context 'On getting an non-existent branch from a repository' {
            It 'Should throw an exception' {
                { Get-GitHubReference -OwnerName $script:ownerName -RepositoryName $repo.name -BranchName $randomBranchName } |
                    Should -Throw
            }
        }

        Context 'On getting an existing branch using Uri from a repository' {
            $reference = Get-GitHubReference -Uri $repo.svn_url -BranchName $masterBranchName

            It 'Should return details for that branch and have expected additional properties' {
                $reference.PSObject.TypeNames[0] | Should -Be 'GitHub.Reference'
                $reference.RepositoryUrl | Should -Be $repo.RepositoryUrl
                $reference.BranchName | Should -Be $masterBranchName
            }
        }

        Context 'On getting an invalid branch using Uri from a repository' {
            It 'Should throw an exception' {
                { Get-GitHubReference -Uri $repo.svn_url -BranchName $randomBranchName } |
                    Should -Throw
            }
        }

        Context 'On getting an existing branch with the repo on the pipeline' {
            $reference = $repo | Get-GitHubReference -BranchName $masterBranchName

            It 'Should return details for that branch and have expected additional properties' {
                $reference.PSObject.TypeNames[0] | Should -Be 'GitHub.Reference'
                $reference.RepositoryUrl | Should -Be $repo.RepositoryUrl
                $reference.BranchName | Should -Be $masterBranchName
            }
        }

        Context 'On getting an invalid branch with the repo on the pipeline' {
            It 'Should throw an exception' {
                { $repo | Get-GitHubReference -BranchName $randomBranchName } |
                    Should -Throw
            }
        }

        Context 'On getting branches by prefix from a repository' {
            $branch1 = "elements_A"
            $branch2 = "elements_B"
            New-GitHubReference -OwnerName $script:ownerName -RepositoryName $repo.name -BranchName $branch1 -Sha $sha
            New-GitHubReference -OwnerName $script:ownerName -RepositoryName $repo.name -BranchName $branch2 -Sha $sha

            $references = Get-GitHubReference -OwnerName $script:ownerName -RepositoryName $repo.name -BranchName "elements" -MatchPrefix

            It 'Should return all branches matching the prefix when an exact match is not found' {
                $expected = @($branch1, $branch2)
                $references.BranchName | Sort-Object | Should -Be $expected
                $references[0].PSObject.TypeNames[0] | Should -Be 'GitHub.Reference'
                $references[1].PSObject.TypeNames[0] | Should -Be 'GitHub.Reference'
                $references[0].RepositoryUrl | Should -Be $repo.RepositoryUrl
                $references[1].RepositoryUrl | Should -Be $repo.RepositoryUrl
            }
        }

        Context 'On getting branches by prefix using Uri from a repository' {
            $branch1 = "uri_A"
            $branch2 = "uri_B"
            New-GitHubReference -Uri $repo.svn_url -BranchName $branch1 -Sha $sha
            New-GitHubReference -Uri $repo.svn_url -BranchName $branch2 -Sha $sha

            $references = Get-GitHubReference -Uri $repo.svn_url -BranchName "uri" -MatchPrefix

            It 'Should return all branches matching the prefix when an exact match is not found' {
                $expected = @($branch1, $branch2)
                $references.BranchName | Sort-Object | Should -Be $expected
                $references[0].PSObject.TypeNames[0] | Should -Be 'GitHub.Reference'
                $references[1].PSObject.TypeNames[0] | Should -Be 'GitHub.Reference'
                $references[0].RepositoryUrl | Should -Be $repo.RepositoryUrl
                $references[1].RepositoryUrl | Should -Be $repo.RepositoryUrl
            }
        }

        Context 'On getting branches by prefix with the repo on the pipeline' {
            $branch1 = "pipeline_A"
            $branch2 = "pipeline_B"
            $repo | New-GitHubReference -BranchName $branch1 -Sha $sha
            $repo | New-GitHubReference -BranchName $branch2 -Sha $sha

            $references = $repo | Get-GitHubReference -BranchName "pipeline" -MatchPrefix

            It 'Should return all branches matching the prefix when an exact match is not found' {
                $expected = @($branch1, $branch2)
                $references.BranchName | Sort-Object | Should -Be $expected
                $references[0].PSObject.TypeNames[0] | Should -Be 'GitHub.Reference'
                $references[1].PSObject.TypeNames[0] | Should -Be 'GitHub.Reference'
                $references[0].RepositoryUrl | Should -Be $repo.RepositoryUrl
                $references[1].RepositoryUrl | Should -Be $repo.RepositoryUrl
            }
        }
    }

    Describe 'Getting tag(s) from repository' {
        BeforeAll {
            # AutoInit will create a readme with the GUID of the repo name
            $repo = New-GitHubRepository -RepositoryName ($repoGuid) -AutoInit
            $existingref = Get-GitHubReference -OwnerName $script:ownerName -RepositoryName $repo.name -BranchName $masterBranchName
            $sha = $existingref.object.sha
            $randomTagName = [Guid]::NewGuid()
            New-GitHubReference -Uri $repo.svn_url -TagName $tagName -Sha $sha
        }

        AfterAll {
            Remove-GitHubRepository -Uri $repo.svn_url -Confirm:$false
        }

        Context 'On getting an existing tag from a repository' {
            $reference = Get-GitHubReference -OwnerName $script:ownerName -RepositoryName $repo.name -TagName $tagName

            It 'Should return details for that tag and have expected additional properties' {
                $reference.PSObject.TypeNames[0] | Should -Be 'GitHub.Reference'
                $reference.RepositoryUrl | Should -Be $repo.RepositoryUrl
                $reference.TagName | Should -Be $tagName
            }
        }

        Context 'On getting an non-existent tag from a repository' {
            It 'Should throw an exception' {
                { Get-GitHubReference -OwnerName $script:ownerName -RepositoryName $repo.name -TagName $randomTagName } |
                    Should -Throw
            }
        }

        Context 'On getting an existing tag using Uri from a repository' {
            $reference = Get-GitHubReference -Uri $repo.svn_url -TagName $tagName

            It 'Should return details for that tag and have expected additional properties' {
                $reference.PSObject.TypeNames[0] | Should -Be 'GitHub.Reference'
                $reference.RepositoryUrl | Should -Be $repo.RepositoryUrl
                $reference.TagName | Should -Be $tagName
            }
        }

        Context 'On getting an invalid tag using Uri from a repository' {
            It 'Should throw an exception' {
                { Get-GitHubReference -Uri $repo.svn_url -TagName $randomTagName } |
                    Should -Throw
            }
        }

        Context 'On getting an existing tag with the repo on the pipeline' {
            $reference = $repo | Get-GitHubReference -TagName $tagName

            It 'Should return details for that tag and have expected additional properties' {
                $reference.PSObject.TypeNames[0] | Should -Be 'GitHub.Reference'
                $reference.RepositoryUrl | Should -Be $repo.RepositoryUrl
                $reference.TagName | Should -Be $tagName
            }
        }

        Context 'On getting an invalid tag using Uri from a repository' {
            It 'Should throw an exception' {
                { $repo | Get-GitHubReference -TagName $randomTagName } |
                    Should -Throw
            }
        }

        Context 'On getting tags by prefix from a repository' {
            $tag1 = "elements_A"
            $tag2 = "elements_B"
            New-GitHubReference -OwnerName $script:ownerName -RepositoryName $repo.name -TagName $tag1 -Sha $sha
            New-GitHubReference -OwnerName $script:ownerName -RepositoryName $repo.name -TagName $tag2 -Sha $sha

            $references = Get-GitHubReference -OwnerName $script:ownerName -RepositoryName $repo.name -TagName "elements" -MatchPrefix

            It 'Should return all branches matching the prefix when an exact match is not found' {
                $expected = @($tag1, $tag2)
                $references.TagName | Sort-Object | Should -Be $expected
                $references[0].PSObject.TypeNames[0] | Should -Be 'GitHub.Reference'
                $references[1].PSObject.TypeNames[0] | Should -Be 'GitHub.Reference'
                $references[0].RepositoryUrl | Should -Be $repo.RepositoryUrl
                $references[1].RepositoryUrl | Should -Be $repo.RepositoryUrl
            }
        }

        Context 'On getting tags by prefix from a repository specified By Uri' {
            $tag1 = "uri_A"
            $tag2 = "uri_B"
            New-GitHubReference -Uri $repo.svn_url -TagName $tag1 -Sha $sha
            New-GitHubReference -Uri $repo.svn_url -TagName $tag2 -Sha $sha

            $references = Get-GitHubReference -Uri $repo.svn_url -TagName "uri" -MatchPrefix

            It 'Should return all branches matching the prefix when an exact match is not found' {
                $expected = @($tag1, $tag2)
                $references.TagName | Sort-Object | Should -Be $expected
                $references[0].PSObject.TypeNames[0] | Should -Be 'GitHub.Reference'
                $references[1].PSObject.TypeNames[0] | Should -Be 'GitHub.Reference'
                $references[0].RepositoryUrl | Should -Be $repo.RepositoryUrl
                $references[1].RepositoryUrl | Should -Be $repo.RepositoryUrl
            }
        }

        Context 'On getting tags by prefix with the repo on the pipeline' {
            $tag1 = "pipeline_A"
            $tag2 = "pipeline_B"
            $repo | New-GitHubReference -TagName $tag1 -Sha $sha
            $repo | New-GitHubReference -TagName $tag2 -Sha $sha

            $references = Get-GitHubReference -Uri $repo.svn_url -TagName "pipeline" -MatchPrefix

            It 'Should return all branches matching the prefix when an exact match is not found' {
                $expected = @($tag1, $tag2)
                $references.TagName | Sort-Object | Should -Be $expected
                $references[0].PSObject.TypeNames[0] | Should -Be 'GitHub.Reference'
                $references[1].PSObject.TypeNames[0] | Should -Be 'GitHub.Reference'
                $references[0].RepositoryUrl | Should -Be $repo.RepositoryUrl
                $references[1].RepositoryUrl | Should -Be $repo.RepositoryUrl
            }
        }
    }
    Describe 'Getting all references from repository' {
        BeforeAll {
            # AutoInit will create a readme with the GUID of the repo name
            $repo = New-GitHubRepository -RepositoryName ($repoGuid) -AutoInit
            $existingref = Get-GitHubReference -OwnerName $script:ownerName -RepositoryName $repo.name -BranchName $masterBranchName
            $sha = $existingref.object.sha
            New-GitHubReference -OwnerName $script:ownerName -RepositoryName $repo.name -TagName $tagName -Sha $sha
        }

        AfterAll {
            # Remove-GitHubRepository -Uri $repo.svn_url -Confirm:$false
        }

        Context 'On getting all references from a repository' {
            $references = Get-GitHubReference -OwnerName $script:ownerName -RepositoryName $repo.name
            It 'Should return all branches matching the prefix when an exact match is not found' {
                $references.Count | Should -Be 2
                $references.TagName.Contains($tagName) | Should -Be True
                $references.BranchName.Contains($masterBranchName) | Should -Be True
                $references[0].PSObject.TypeNames[0] | Should -Be 'GitHub.Reference'
                $references[1].PSObject.TypeNames[0] | Should -Be 'GitHub.Reference'
                $references[0].RepositoryUrl | Should -Be $repo.RepositoryUrl
                $references[1].RepositoryUrl | Should -Be $repo.RepositoryUrl
            }
        }

        Context 'On getting all references using Uri from a repository' {
            $references = Get-GitHubReference -Uri $repo.svn_url

            It 'Should return all branches matching the prefix when an exact match is not found' {
                $references.Count | Should -Be 2
                $references.TagName.Contains($tagName) | Should -Be True
                $references.BranchName.Contains($masterBranchName) | Should -Be True
                $references[0].PSObject.TypeNames[0] | Should -Be 'GitHub.Reference'
                $references[1].PSObject.TypeNames[0] | Should -Be 'GitHub.Reference'
                $references[0].RepositoryUrl | Should -Be $repo.RepositoryUrl
                $references[1].RepositoryUrl | Should -Be $repo.RepositoryUrl
            }
        }

        Context 'On getting all references with repo on pipeline' {
            $references = $repo | Get-GitHubReference

            It 'Should return all branches matching the prefix when an exact match is not found' {
                $references.Count | Should -Be 2
                $references.TagName.Contains($tagName) | Should -Be True
                $references.BranchName.Contains($masterBranchName) | Should -Be True
                $references[0].PSObject.TypeNames[0] | Should -Be 'GitHub.Reference'
                $references[1].PSObject.TypeNames[0] | Should -Be 'GitHub.Reference'
                $references[0].RepositoryUrl | Should -Be $repo.RepositoryUrl
                $references[1].RepositoryUrl | Should -Be $repo.RepositoryUrl
            }
        }
    }

    Describe 'Delete a branch from a repository' {
        BeforeAll {
            # AutoInit will create a readme with the GUID of the repo name
            $repo = New-GitHubRepository -RepositoryName ($repoGuid) -AutoInit
        }

        AfterAll {
            Remove-GitHubRepository -Uri $repo.svn_url -Confirm:$false
        }

        Context 'On deleting a branch in a repository' {
            $existingref = Get-GitHubReference -OwnerName $script:ownerName -RepositoryName $repo.name -BranchName "master"
            $sha = $existingref.object.sha
            New-GitHubReference -OwnerName $script:ownerName -RepositoryName $repo.name -BranchName $branchName -Sha $sha
            Remove-GitHubReference -OwnerName $script:ownerName -RepositoryName $repo.name -BranchName $branchName -Confirm:$false

            It 'Should throw an exception when trying to get the deleted branch' {
                { Get-GitHubReference -OwnerName $script:ownerName -RepositoryName $repo.name -BranchName $branchName } |
                    Should -Throw
            }

            It 'Should throw an exception when the same branch is deleted again' {
                { Remove-GitHubReference -OwnerName $script:ownerName -RepositoryName $repo.name -BranchName $branchName -Confirm:$false} |
                    Should -Throw
            }
        }

        Context 'On deleting an invalid branch from a repository' {
            It 'Should throw an exception' {
                { Remove-GitHubReference -OwnerName $script:ownerName -RepositoryName $repo.name -BranchName $([Guid]::NewGuid()) -Confirm:$false} |
                    Should -Throw
            }
        }

        Context 'On deleting a branch in a repository specified by Uri' {
            $existingref = Get-GitHubReference -Uri $repo.svn_url -BranchName "master"
            $sha = $existingref.object.sha
            New-GitHubReference -OwnerName $script:ownerName -RepositoryName $repo.name -BranchName $branchName -Sha $sha
            Remove-GitHubReference -OwnerName $script:ownerName -RepositoryName $repo.name -BranchName $branchName -Confirm:$false

            It 'Should throw an exception when trying to get the deleted branch' {
                { Get-GitHubReference -OwnerName $script:ownerName -RepositoryName $repo.name -BranchName $branchName} |
                    Should -Throw
            }

            It 'Should throw an exception when the same branch is deleted again' {
                { Remove-GitHubReference -OwnerName $script:ownerName -RepositoryName $repo.name -BranchName $branchName -Confirm:$false} |
                    Should -Throw
            }
        }

        Context 'On deleting a branch in a repository with the repo on pipeline' {
            $existingref = Get-GitHubReference -Uri $repo.svn_url -BranchName "master"
            $sha = $existingref.object.sha
            New-GitHubReference -OwnerName $script:ownerName -RepositoryName $repo.name -BranchName $branchName -Sha $sha
            $repo | Remove-GitHubReference -BranchName $branchName -Confirm:$false

            It 'Should throw an exception when trying to get the deleted branch' {
                { Get-GitHubReference -OwnerName $script:ownerName -RepositoryName $repo.name -BranchName $branchName} |
                    Should -Throw
            }

            It 'Should throw an exception when the same branch is deleted again' {
                { Remove-GitHubReference -OwnerName $script:ownerName -RepositoryName $repo.name -BranchName $branchName -Confirm:$false} |
                    Should -Throw
            }
        }

        Context 'On deleting a branch in a repository with the branch reference on pipeline' {
            $existingref = Get-GitHubReference -Uri $repo.svn_url -BranchName "master"
            $sha = $existingref.object.sha
            $branchRef = New-GitHubReference -OwnerName $script:ownerName -RepositoryName $repo.name -BranchName $branchName -Sha $sha
            $branchRef | Remove-GitHubReference -Confirm:$false

            It 'Should throw an exception when trying to get the deleted branch' {
                { Get-GitHubReference -OwnerName $script:ownerName -RepositoryName $repo.name -BranchName $branchName} |
                    Should -Throw
            }

            It 'Should throw an exception when the same branch is deleted again' {
                { Remove-GitHubReference -OwnerName $script:ownerName -RepositoryName $repo.name -BranchName $branchName -Confirm:$false} |
                    Should -Throw
            }
        }

        Context 'On deleting an invalid branch from a repository specified by Uri' {
            It 'Should throw an exception' {
                { Remove-GitHubReference -OwnerName -Uri $repo.svn_url -BranchName $([Guid]::NewGuid()) -Confirm:$false } |
                    Should -Throw
            }
        }

    }

    Describe 'Delete a Tag from a Repository' {
        BeforeAll {
            # AutoInit will create a readme with the GUID of the repo name
            $repo = New-GitHubRepository -RepositoryName ($repoGuid) -AutoInit
        }

        AfterAll {
            Remove-GitHubRepository -Uri $repo.svn_url -Confirm:$false
        }

        Context 'On deleting a valid tag in a repository' {
            $existingref = Get-GitHubReference -OwnerName $script:ownerName -RepositoryName $repo.name -BranchName "master"
            $sha = $existingref.object.sha
            New-GitHubReference -OwnerName $script:ownerName -RepositoryName $repo.name -TagName $tagName -Sha $sha
            Remove-GitHubReference -OwnerName $script:ownerName -RepositoryName $repo.name -TagName $tagName -Confirm:$false

            It 'Should throw an exception when trying to get the deleted tag' {
                { Get-GitHubReference -OwnerName $script:ownerName -RepositoryName $repo.name -TagName $tagName } |
                    Should -Throw
            }

            It 'Should throw an exception when the same tag is deleted again' {
                { Remove-GitHubReference -OwnerName $script:ownerName -RepositoryName $repo.name -TagName $tagName -Confirm:$false } |
                    Should -Throw
            }
        }

        Context 'On deleting an invalid tag from a repository' {
            It 'Should throw an exception' {
                { Remove-GitHubReference -OwnerName $script:ownerName -RepositoryName $repo.name -TagName $([Guid]::NewGuid()) -Confirm:$false } |
                    Should -Throw
            }
        }

        Context 'On deleting a tag in a repository specified by Uri' {
            $existingref = Get-GitHubReference -Uri $repo.svn_url -BranchName "master"
            $sha = $existingref.object.sha
            New-GitHubReference -OwnerName $script:ownerName -RepositoryName $repo.name -TagName $tagName -Sha $sha
            Remove-GitHubReference -OwnerName $script:ownerName -RepositoryName $repo.name -TagName $tagName -Confirm:$false

            It 'Should throw an exception when trying to get the deleted tag' {
                { Get-GitHubReference -OwnerName $script:ownerName -RepositoryName $repo.name -TagName $tagName } |
                    Should -Throw
            }

            It 'Should throw an exception when the same branch is deleted again' {
                { Remove-GitHubReference -OwnerName $script:ownerName -RepositoryName $repo.name -TagName $tagName -Confirm:$false } |
                    Should -Throw
            }
        }

        Context 'On deleting a tag in a repository with repo on pipeline' {
            $existingref = Get-GitHubReference -Uri $repo.svn_url -BranchName "master"
            $sha = $existingref.object.sha
            New-GitHubReference -OwnerName $script:ownerName -RepositoryName $repo.name -TagName $tagName -Sha $sha
            $repo | Remove-GitHubReference -TagName $tagName -Confirm:$false

            It 'Should throw an exception when trying to get the deleted tag' {
                { Get-GitHubReference -OwnerName $script:ownerName -RepositoryName $repo.name -TagName $tagName } |
                    Should -Throw
            }

            It 'Should throw an exception when the same branch is deleted again' {
                { Remove-GitHubReference -OwnerName $script:ownerName -RepositoryName $repo.name -TagName $tagName -Confirm:$false } |
                    Should -Throw
            }
        }

        Context 'On deleting a tag in a repository with tag reference on pipeline' {
            $existingref = Get-GitHubReference -Uri $repo.svn_url -BranchName "master"
            $sha = $existingref.object.sha
            $tagRef = New-GitHubReference -OwnerName $script:ownerName -RepositoryName $repo.name -TagName $tagName -Sha $sha
            $tagRef | Remove-GitHubReference -Confirm:$false

            It 'Should throw an exception when trying to get the deleted tag' {
                { Get-GitHubReference -OwnerName $script:ownerName -RepositoryName $repo.name -TagName $tagName } |
                    Should -Throw
            }

            It 'Should throw an exception when the same branch is deleted again' {
                { Remove-GitHubReference -OwnerName $script:ownerName -RepositoryName $repo.name -TagName $tagName -Confirm:$false } |
                    Should -Throw
            }
        }

        Context 'On deleting an invalid tag from a repository specified by Uri' {
            It 'Should throw an exception' {
                { Remove-GitHubReference -OwnerName -Uri $repo.svn_url -TagName $([Guid]::NewGuid()) -Confirm:$false } |
                    Should -Throw
            }
        }

    }

    Describe 'Update a branch in a repository' {
        BeforeAll {
            # AutoInit will create a readme with the GUID of the repo name
            $repo = New-GitHubRepository -RepositoryName ($repoGuid) -AutoInit
            $existingref = Get-GitHubReference -OwnerName $script:ownerName -RepositoryName $repo.name -BranchName $masterBranchName
            $sha = $existingref.object.sha
            New-GitHubReference -OwnerName $script:ownerName -RepositoryName $repo.name -BranchName $branchName -Sha $sha
        }

        AfterAll {
            Remove-GitHubRepository -Uri $repo.svn_url -Confirm:$false
        }

        Context 'On updating an existing branch to a different SHA' {
            It 'Should throw an exception if the SHA is invalid' {
                { Set-GithubReference -OwnerName $script:ownerName -RepositoryName $repo.name -BranchName $branchName -Sha "1234" } |
                    Should -Throw
            }
        }

        Context 'On updating a branch to a different SHA' {
            $setGitHubContentParams = @{
                Path = 'test.txt'
                CommitMessage = 'Commit Message'
                Branch = $masterBranchName
                Content = 'This is the content for test.txt'
                Uri = $repo.svn_url
            }

            Set-GitHubContent @setGitHubContentParams

            $masterSHA = $(Get-GitHubReference -OwnerName $script:ownerName -RepositoryName $repo.name -BranchName "master").object.sha
            $oldSHA = $(Get-GitHubReference -OwnerName $script:ownerName -RepositoryName $repo.name -BranchName $branchName).object.sha
            Set-GithubReference -OwnerName $script:ownerName -RepositoryName $repo.name -BranchName $branchName -Sha $masterSHA

            It 'Should return the updated SHA when the reference is queried after update' {
                $newSHA = $(Get-GitHubReference -OwnerName $script:ownerName -RepositoryName $repo.name -BranchName $branchName).object.sha
                $newSHA | Should -Be $masterSHA
                $newSHA | Should -Not -Be $oldSHA
            }
        }

        Context 'On updating a branch to a different SHA with repo on pipeline' {
            $setGitHubContentParams = @{
                Path = 'test.txt'
                CommitMessage = 'Commit Message'
                Branch = $masterBranchName
                Content = 'This is the content for test.txt'
                Uri = $repo.svn_url
            }

            Set-GitHubContent @setGitHubContentParams

            $masterSHA = $(Get-GitHubReference -OwnerName $script:ownerName -RepositoryName $repo.name -BranchName "master").object.sha
            $oldSHA = $(Get-GitHubReference -OwnerName $script:ownerName -RepositoryName $repo.name -BranchName $branchName).object.sha
            $repo | Set-GithubReference -BranchName $branchName -Sha $masterSHA

            It 'Should return the updated SHA when the reference is queried after update' {
                $newSHA = $(Get-GitHubReference -OwnerName $script:ownerName -RepositoryName $repo.name -BranchName $branchName).object.sha
                $newSHA | Should -Be $masterSHA
                $newSHA | Should -Not -Be $oldSHA
            }
        }

        Context 'On updating a branch to a different SHA with branch reference on pipeline' {
            $setGitHubContentParams = @{
                Path = 'test.txt'
                CommitMessage = 'Commit Message'
                Branch = $masterBranchName
                Content = 'This is the content for test.txt'
                Uri = $repo.svn_url
            }

            Set-GitHubContent @setGitHubContentParams

            $masterSHA = $(Get-GitHubReference -OwnerName $script:ownerName -RepositoryName $repo.name -BranchName "master").object.sha
            $branchRef = $(Get-GitHubReference -OwnerName $script:ownerName -RepositoryName $repo.name -BranchName $branchName)
            $oldSHA = $branchRef.object.sha
            $branchRef | Set-GithubReference -Sha $masterSHA

            It 'Should return the updated SHA when the reference is queried after update' {
                $newSHA = $(Get-GitHubReference -OwnerName $script:ownerName -RepositoryName $repo.name -BranchName $branchName).object.sha
                $newSHA | Should -Be $masterSHA
                $newSHA | Should -Not -Be $oldSHA
            }
        }

    }

    Describe 'Update a tag in a repository' {
        BeforeAll {
            # AutoInit will create a readme with the GUID of the repo name
            $repo = New-GitHubRepository -RepositoryName ($repoGuid) -AutoInit
            $tag = "myTag"
            $existingref = Get-GitHubReference -OwnerName $script:ownerName -RepositoryName $repo.name -BranchName $masterBranchName
            $sha = $existingref.object.sha
            New-GitHubReference -OwnerName $script:ownerName -RepositoryName $repo.name -TagName $tag -Sha $sha
        }

        AfterAll {
            Remove-GitHubRepository -Uri $repo.svn_url -Confirm:$false
        }

        Context 'On updating an existing tag to a different SHA' {
            It 'Should throw an exception if the SHA is invalid' {
                { Set-GithubReference -OwnerName $script:ownerName -RepositoryName $repo.name -TagName $tag -Sha "1234" } |
                    Should -Throw
            }
        }

        Context 'On updating a tag to a valid SHA' {
            $setGitHubContentParams = @{
                Path = 'test.txt'
                CommitMessage = 'Commit Message'
                Branch = $masterBranchName
                Content = 'This is the content for test.txt'
                Uri = $repo.svn_url
            }

            Set-GitHubContent @setGitHubContentParams

            $masterSHA = $(Get-GitHubReference -OwnerName $script:ownerName -RepositoryName $repo.name -BranchName "master").object.sha
            $oldSHA = $(Get-GitHubReference -OwnerName $script:ownerName -RepositoryName $repo.name -TagName $tag).object.sha
            Set-GithubReference -OwnerName $script:ownerName -RepositoryName $repo.name -TagName $tag -Sha $masterSHA

            It 'Should return the updated SHA when the reference is queried after update' {
                $newSHA = $(Get-GitHubReference -OwnerName $script:ownerName -RepositoryName $repo.name -TagName $tag).object.sha
                $newSHA | Should -Be $masterSHA
                $newSHA | Should -Not -Be $oldSHA
            }
        }

        Context 'On updating a tag to a valid SHA with repo on pipeline' {
            $setGitHubContentParams = @{
                Path = 'test.txt'
                CommitMessage = 'Commit Message'
                Branch = $masterBranchName
                Content = 'This is the content for test.txt'
                Uri = $repo.svn_url
            }

            Set-GitHubContent @setGitHubContentParams

            $masterSHA = $(Get-GitHubReference -OwnerName $script:ownerName -RepositoryName $repo.name -BranchName "master").object.sha
            $oldSHA = $(Get-GitHubReference -OwnerName $script:ownerName -RepositoryName $repo.name -TagName $tag).object.sha
            $repo | Set-GithubReference -TagName $tag -Sha $masterSHA

            It 'Should return the updated SHA when the reference is queried after update' {
                $newSHA = $(Get-GitHubReference -OwnerName $script:ownerName -RepositoryName $repo.name -TagName $tag).object.sha
                $newSHA | Should -Be $masterSHA
                $newSHA | Should -Not -Be $oldSHA
            }
        }

        Context 'On updating a tag to a valid SHA with tag reference on pipeline' {
            $setGitHubContentParams = @{
                Path = 'test.txt'
                CommitMessage = 'Commit Message'
                Branch = $masterBranchName
                Content = 'This is the content for test.txt'
                Uri = $repo.svn_url
            }

            Set-GitHubContent @setGitHubContentParams

            $masterSHA = $(Get-GitHubReference -OwnerName $script:ownerName -RepositoryName $repo.name -BranchName "master").object.sha
            $tagRef = $(Get-GitHubReference -OwnerName $script:ownerName -RepositoryName $repo.name -TagName $tag)
            $oldSHA = $tagRef.object.sha
            $tagRef | Set-GithubReference -Sha $masterSHA

            It 'Should return the updated SHA when the reference is queried after update' {
                $newSHA = $(Get-GitHubReference -OwnerName $script:ownerName -RepositoryName $repo.name -TagName $tag).object.sha
                $newSHA | Should -Be $masterSHA
                $newSHA | Should -Not -Be $oldSHA
            }
        }
    }
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