# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

<#
.Synopsis
   Tests for GitHubReferences.ps1 module
#>

# This is common test code setup logic for all Pester test files
$moduleRootPath = Split-Path -Path $PSScriptRoot -Parent
. (Join-Path -Path $moduleRootPath -ChildPath 'Tests\Common.ps1')

function Update-MasterSHA()
{
    # Add a new file in master in order to create a new commit and hence, an updated SHA
    # TODO: Replace this when the Content updation related APIs are made available
    $fileContent = "Hello powershell!"
    $fileName = "powershell.txt"
    $encodedFile = [System.Convert]::ToBase64String(([System.Text.Encoding]::UTF8).GetBytes($fileContent))

    $fileData = @{
        "message" = "added new file"
        "content" = "$encodedFile"
    }

    $params = @{
        'UriFragment' = "repos/$ownerName/$repositoryName/contents/$fileName"
        'Method' = 'Put'
        'Body' = (ConvertTo-Json -InputObject $fileData)
        'AccessToken' = $AccessToken
    }
    Invoke-GHRestMethod @params
}

try
{
    if ($accessTokenConfigured)
    {
        $masterBranchName = "master"
        Describe 'Create a new branch in repository' {
            $repositoryName = [Guid]::NewGuid()
            $repo = New-GitHubRepository -RepositoryName $repositoryName -AutoInit
            $existingref = Get-GitHubReference -OwnerName $ownerName -RepositoryName $repositoryName -Branch $masterBranchName
            $sha = $existingref.object.sha

            Context 'On creating a new branch in a repository from a given SHA' {
                $branchName = [Guid]::NewGuid().ToString()
                $result = New-GitHubReference -OwnerName $ownerName -RepositoryName $repositoryName -Branch $branchName -Sha $sha

                It 'Should successfully create the new branch' {
                    $result.ref | Should Be "refs/heads/$branchName"
                }

                It 'Should throw an Exception when trying to create it again' {
                    { New-GitHubReference -OwnerName $ownerName -RepositoryName $repositoryName -Branch $masterBranchName -Sha $sha } | Should Throw
                }
            }

            Context 'On creating a new branch in a repository (specified by Uri) from a given SHA' {
                $branchName = [Guid]::NewGuid().ToString()
                $result = New-GitHubReference -Uri $repo.svn_url -Branch $branchName -Sha $sha

                It 'Should successfully create the branch' {
                    $result.ref | Should Be "refs/heads/$branchName"
                }

                It 'Should throw an exception when trying to create it again' {
                    { New-GitHubReference -Uri $repo.svn_url -Branch $masterBranchName -Sha $sha }  | Should Throw
                }
            }

            $null = Remove-GitHubRepository -OwnerName $ownerName -RepositoryName $repositoryName -Confirm:$false
        }

        Describe 'Create a new tag in a repository' {
            $repositoryName = [Guid]::NewGuid()
            $repo = New-GitHubRepository -RepositoryName $repositoryName -AutoInit
            $existingref = Get-GitHubReference -OwnerName $ownerName -RepositoryName $repositoryName -Branch $masterBranchName
            $sha = $existingref.object.sha

            Context 'On creating a new tag in a repository referring to a given SHA' {
                $tagName = [Guid]::NewGuid().ToString()
                $result = New-GitHubReference -OwnerName $ownerName -RepositoryName $repositoryName -Tag $tagName -Sha $sha

                It 'Should successfully create the new tag' {
                    $result.ref | Should Be "refs/tags/$tagName"
                }

                It 'Should throw an Exception when trying to create it again' {
                    { New-GitHubReference -OwnerName $ownerName -RepositoryName $repositoryName -Tag $tagName -Sha $sha } | Should Throw
                }
            }

            Context 'On creating a new tag in a repository (specified by Uri) from a given SHA' {
                $tagName = [Guid]::NewGuid().ToString()
                $result = New-GitHubReference -Uri $repo.svn_url -Tag $tagName -Sha $sha

                It 'Should successfully create the reference' {
                    $result.ref | Should Be "refs/tags/$tagName"
                }

                It 'Should throw an exception when trying to create it again' {
                    { New-GitHubReference -Uri $repo.svn_url -Tag $tagName -Sha $sha }  | Should Throw
                }
            }

            $null = Remove-GitHubRepository -OwnerName $ownerName -RepositoryName $repositoryName -Confirm:$false
        }

        Describe 'Getting branch(es) from repository' {
            $repositoryName = [Guid]::NewGuid()
            $repo = New-GitHubRepository -RepositoryName $repositoryName -AutoInit
            $randomBranchName = [Guid]::NewGuid()
            $existingref = Get-GitHubReference -OwnerName $ownerName -RepositoryName $repositoryName -Branch $masterBranchName
            $sha = $existingref.object.sha

            Context 'On getting an existing branch from a repository' {
                $reference = Get-GitHubReference -OwnerName $ownerName -RepositoryName $repositoryName -Branch $masterBranchName

                It 'Should return details of the branch' {
                    $reference.ref | Should be "refs/heads/$masterBranchName"
                }
            }

            Context 'On getting an non-existent branch from a repository' {

                It 'Should throw an exception' {
                    { Get-GitHubReference -OwnerName $ownerName -RepositoryName $repositoryName -Branch $randomBranchName } |
                    Should Throw
                }
            }

            Context 'On getting an existing branch using Uri from a repository' {
                $reference = Get-GitHubReference -Uri $repo.svn_url -Branch $masterBranchName

                It 'Should return details of the branch' {
                    $reference.ref | Should be "refs/heads/$masterBranchName"
                }
            }

            Context 'On getting an invalid branch using Uri from a repository' {

                It 'Should throw an exception' {
                    { Get-GitHubReference -Uri $repo.svn_url -Branch $randomBranchName } |
                    Should Throw
                }
            }

            Context 'On getting branches by prefix from a repository' {
                $branch1 = "elements_" + $([Guid]::NewGuid().ToString())
                $branch2 = "elements_" + $([Guid]::NewGuid().ToString())
                New-GitHubReference -OwnerName $ownerName -RepositoryName $repositoryName -Branch $branch1 -Sha $sha
                New-GitHubReference -OwnerName $ownerName -RepositoryName $repositoryName -Branch $branch2 -Sha $sha

                $references = Get-GitHubReference -OwnerName $ownerName -RepositoryName $repositoryName -Branch "elements" -MatchPrefix

                It 'Should return all branches matching the prefix' {
                    $expected = @("refs/heads/$branch1", "refs/heads/$branch2")
                    $references.ref | Should Be $expected
                }
            }

            Context 'On getting branches by prefix using Uri from a repository' {
                $branch1 = "uri_" + $([Guid]::NewGuid().ToString())
                $branch2 = "uri_" + $([Guid]::NewGuid().ToString())
                New-GitHubReference -Uri $repo.svn_url -Branch $branch1 -Sha $sha
                New-GitHubReference -Uri $repo.svn_url -Branch $branch2 -Sha $sha

                $references = Get-GitHubReference -Uri $repo.svn_url -Branch "uri" -MatchPrefix

                It 'Should return all branches matching the prefix' {
                    $expected = @("refs/heads/$branch1", "refs/heads/$branch2")
                    $references.ref | Should Be $expected
                }
            }

            $null = Remove-GitHubRepository -OwnerName $ownerName -RepositoryName $repositoryName -Confirm:$false
        }

        Describe 'Getting tag(s) from repository' {
            $repositoryName = [Guid]::NewGuid()
            $repo = New-GitHubRepository -RepositoryName $repositoryName -AutoInit
            $randomTagName = [Guid]::NewGuid()
            $validTag = "master-tag"
            $existingref = Get-GitHubReference -OwnerName $ownerName -RepositoryName $repositoryName -Branch $masterBranchName
            $sha = $existingref.object.sha
            New-GitHubReference -Uri $repo.svn_url -Tag $validTag -Sha $sha

            Context 'On getting an existing tag from a repository' {
                $reference = Get-GitHubReference -OwnerName $ownerName -RepositoryName $repositoryName -Tag $validTag

                It 'Should return details of the tag' {
                    $reference.ref | Should be "refs/tags/$validTag"
                }
            }

            Context 'On getting an non-existent tag from a repository' {

                It 'Should throw an exception' {
                    { Get-GitHubReference -OwnerName $ownerName -RepositoryName $repositoryName -Tag $randomTagName } |
                    Should Throw
                }
            }

            Context 'On getting an existing tag using Uri from a repository' {
                $reference = Get-GitHubReference -Uri $repo.svn_url -Tag $validTag

                It 'Should return details of the tag' {
                    $reference.ref | Should be "refs/tags/$validTag"
                }
            }

            Context 'On getting an invalid tag using Uri from a repository' {

                It 'Should throw an exception' {
                    { Get-GitHubReference -Uri $repo.svn_url -Tag $randomTagName } |
                    Should Throw
                }
            }

            Context 'On getting tags by prefix from a repository' {
                $tag1 = "elements_" + $([Guid]::NewGuid().ToString())
                $tag2 = "elements_" + $([Guid]::NewGuid().ToString())
                New-GitHubReference -OwnerName $ownerName -RepositoryName $repositoryName -Tag $tag1 -Sha $sha
                New-GitHubReference -OwnerName $ownerName -RepositoryName $repositoryName -Tag $tag2 -Sha $sha

                $references = Get-GitHubReference -OwnerName $ownerName -RepositoryName $repositoryName -Tag "elements" -MatchPrefix

                It 'Should return all tags matching the prefix' {
                    $expected = @("refs/tags/$tag1", "refs/tags/$tag2")
                    $references.ref | Should Be $expected
                }
            }

            Context 'On getting tags by prefix from a repository specified By Uri' {
                $tag1 = "uri_" + $([Guid]::NewGuid().ToString())
                $tag2 = "uri_" + $([Guid]::NewGuid().ToString())
                New-GitHubReference -Uri $repo.svn_url -Tag $tag1 -Sha $sha
                New-GitHubReference -Uri $repo.svn_url -Tag $tag2 -Sha $sha

                $references = Get-GitHubReference -Uri $repo.svn_url -Tag "uri" -MatchPrefix

                It 'Should return all tags matching the prefix' {
                    $expected = @("refs/tags/$tag1", "refs/tags/$tag2")
                    $references.ref | Should Be $expected
                }
            }

            $null = Remove-GitHubRepository -OwnerName $ownerName -RepositoryName $repositoryName -Confirm:$false
        }
        Describe 'Getting all references from repository' {
            $repositoryName = [Guid]::NewGuid()
            $repo = New-GitHubRepository -RepositoryName $repositoryName -AutoInit
            $branchName = "forked-from-master"
            $tagName = "master-fork-tag"
            $existingref = Get-GitHubReference -OwnerName $ownerName -RepositoryName $repositoryName -Branch $masterBranchName
            $sha = $existingref.object.sha
            New-GitHubReference -OwnerName $ownerName -RepositoryName $repositoryName -Branch $branchName -Sha $sha
            New-GitHubReference -OwnerName $ownerName -RepositoryName $repositoryName -Tag $tagName -Sha $sha

            $refNames = @("refs/heads/$masterBranchName", "refs/heads/$branchName", "refs/tags/$tagName")

            Context 'On getting all references from a repository' {
                $reference = Get-GitHubReference -OwnerName $ownerName -RepositoryName $repositoryName -All

                It 'Should return all branches and tags' {
                    $reference.ref | Should be $refNames
                }
            }

            Context 'On getting all references using Uri from a repository' {
                $reference = Get-GitHubReference -Uri $repo.svn_url -All

                It 'Should return all branches and tags' {
                    $reference.ref | Should be $refNames
                }
            }

            $null = Remove-GitHubRepository -OwnerName $ownerName -RepositoryName $repositoryName -Confirm:$false
        }

        Describe 'Delete a branch from a repository' {
            $repositoryName = [Guid]::NewGuid()
            $repo = New-GitHubRepository -RepositoryName $repositoryName -AutoInit
            $branchName = "myBranch"

            Context 'On deleting a newly created branch in a repository' {
                $existingref = Get-GitHubReference -OwnerName $ownerName -RepositoryName $repositoryName -Branch "master"
                $sha = $existingref.object.sha
                New-GitHubReference -OwnerName $ownerName -RepositoryName $repositoryName -Branch $branchName -Sha $sha
                Remove-GitHubReference -OwnerName $ownerName -RepositoryName $repositoryName -Branch $branchName -Confirm:$false

                It 'Should throw an exception when trying to get the deleted branch' {
                    { Get-GitHubReference -OwnerName $ownerName -RepositoryName $repositoryName -Branch $branchName } |
                    Should Throw
                }

                It 'Should throw an exception when the same branch is deleted again' {
                    { Remove-GitHubReference -OwnerName $ownerName -RepositoryName $repositoryName -Branch $branchName -Confirm:$false} |
                    Should Throw
                }
            }

            Context 'On deleting an invalid branch from a repository' {
                It 'Should throw an exception' {
                    { Remove-GitHubReference -OwnerName $ownerName -RepositoryName $repositoryName -Branch $([Guid]::NewGuid()) -Confirm:$false} |
                    Should Throw
                }
            }

            Context 'On deleting a newly created branch in a repository specified by Uri' {
                $branchName = "myBranch"
                $existingref = Get-GitHubReference -Uri $repo.svn_url -Branch "master"
                $sha = $existingref.object.sha
                New-GitHubReference -OwnerName $ownerName -RepositoryName $repositoryName -Branch $branchName -Sha $sha
                Remove-GitHubReference -OwnerName $ownerName -RepositoryName $repositoryName -Branch $branchName -Confirm:$false

                It 'Should throw an exception when trying to get the deleted branch' {
                    { Get-GitHubReference -OwnerName $ownerName -RepositoryName $repositoryName -Branch $branchName} |
                    Should Throw
                }

                It 'Should throw an exception when the same branch is deleted again' {
                    { Remove-GitHubReference -OwnerName $ownerName -RepositoryName $repositoryName -Branch $branchName -Confirm:$false} |
                    Should Throw
                }
            }

            Context 'On deleting an invalid branch from a repository specified by Uri' {
                It 'Should throw an exception' {
                    { Remove-GitHubReference -OwnerName -Uri $repo.svn_url -Branch $([Guid]::NewGuid()) -Confirm:$false } |
                    Should Throw
                }
            }

            $null = Remove-GitHubRepository -OwnerName $ownerName -RepositoryName $repositoryName -Confirm:$false
        }

        Describe 'Delete a Tag from a Repository' {
            $repositoryName = [Guid]::NewGuid()
            $repo = New-GitHubRepository -RepositoryName $repositoryName -AutoInit
            $tagName = "myTag"

            Context 'On deleting a valid tag in a repository' {
                $existingref = Get-GitHubReference -OwnerName $ownerName -RepositoryName $repositoryName -Branch "master"
                $sha = $existingref.object.sha
                New-GitHubReference -OwnerName $ownerName -RepositoryName $repositoryName -Tag $tagName -Sha $sha
                Remove-GitHubReference -OwnerName $ownerName -RepositoryName $repositoryName -Tag $tagName -Confirm:$false

                It 'Should throw an exception when trying to get the deleted tag' {
                    { Get-GitHubReference -OwnerName $ownerName -RepositoryName $repositoryName -Tag $tagName } |
                    Should Throw
                }

                It 'Should throw an exception when the same tag is deleted again' {
                    { Remove-GitHubReference -OwnerName $ownerName -RepositoryName $repositoryName -Tag $tagName -Confirm:$false } |
                    Should Throw
                }
            }

            Context 'On deleting an invalid tag from a repository' {
                It 'Should throw an exception' {
                    { Remove-GitHubReference -OwnerName $ownerName -RepositoryName $repositoryName -Tag $([Guid]::NewGuid()) -Confirm:$false } |
                    Should Throw
                }
            }

            Context 'On deleting a tag in a repository specified by Uri' {
                $existingref = Get-GitHubReference -Uri $repo.svn_url -Branch "master"
                $sha = $existingref.object.sha
                New-GitHubReference -OwnerName $ownerName -RepositoryName $repositoryName -Tag $tagName -Sha $sha
                Remove-GitHubReference -OwnerName $ownerName -RepositoryName $repositoryName -Tag $tagName -Confirm:$false

                It 'Should throw an exception when trying to get the deleted tag' {
                    { Get-GitHubReference -OwnerName $ownerName -RepositoryName $repositoryName -Tag $tagName } |
                    Should Throw
                }

                It 'Should throw an exception when the same branch is deleted again' {
                    { Remove-GitHubReference -OwnerName $ownerName -RepositoryName $repositoryName -Tag $tagName -Confirm:$false } |
                    Should Throw
                }
            }

            Context 'On deleting an invalid tag from a repository specified by Uri' {
                It 'Should throw an exception' {
                    { Remove-GitHubReference -OwnerName -Uri $repo.svn_url -Tag $([Guid]::NewGuid()) -Confirm:$false } |
                    Should Throw
                }
            }

            $null = Remove-GitHubRepository -OwnerName $ownerName -RepositoryName $repositoryName -Confirm:$false
        }

        Describe 'Update a branch in a repository' {
            $repositoryName = [Guid]::NewGuid()
            New-GitHubRepository -RepositoryName $repositoryName -AutoInit
            $branchName = "myBranch"
            $existingref = Get-GitHubReference -OwnerName $ownerName -RepositoryName $repositoryName -Branch $masterBranchName
            $sha = $existingref.object.sha
            New-GitHubReference -OwnerName $ownerName -RepositoryName $repositoryName -Branch $branchName -Sha $sha

            Context 'On updating an existing branch to a different SHA' {
                It 'Should throw an exception if the SHA is invalid' {
                    { Update-GitHubReference -OwnerName $ownerName -RepositoryName $repositoryName -Branch $branchName -Sha "1234" } |
                    Should Throw
                }
            }

            Context 'On updating a branch to a different SHA' {
                Update-MasterSHA
                $masterSHA = $(Get-GitHubReference -OwnerName $ownerName -RepositoryName $repositoryName -Branch "master").object.sha
                $oldSHA = $(Get-GitHubReference -OwnerName $ownerName -RepositoryName $repositoryName -Branch $branchName).object.sha
                Update-GitHubReference -OwnerName $ownerName -RepositoryName $repositoryName -Branch $branchName -Sha $masterSHA

                It 'Should return the updated SHA when the reference is queried after update' {
                    $newSHA = $(Get-GitHubReference -OwnerName $ownerName -RepositoryName $repositoryName -Branch $branchName).object.sha
                    $newSHA | Should be $masterSHA
                    $newSHA | Should Not be $oldSHA
                }
            }

            $null = Remove-GitHubRepository -OwnerName $ownerName -RepositoryName $repositoryName -Confirm:$false
        }

        Describe 'Update a tag in a repository' {
            $repositoryName = [Guid]::NewGuid()
            New-GitHubRepository -RepositoryName $repositoryName -AutoInit
            $tag = "myTag"
            $existingref = Get-GitHubReference -OwnerName $ownerName -RepositoryName $repositoryName -Branch $masterBranchName
            $sha = $existingref.object.sha
            New-GitHubReference -OwnerName $ownerName -RepositoryName $repositoryName -Tag $tag -Sha $sha

            Context 'On updating an existing tag to a different SHA' {
                It 'Should throw an exception if the SHA is invalid' {
                    { Update-GitHubReference -OwnerName $ownerName -RepositoryName $repositoryName -Tag $tag -Sha "1234" } |
                    Should Throw
                }
            }

            Context 'On updating a tag to a valid SHA' {
                Update-MasterSHA
                $masterSHA = $(Get-GitHubReference -OwnerName $ownerName -RepositoryName $repositoryName -Branch "master").object.sha
                $oldSHA = $(Get-GitHubReference -OwnerName $ownerName -RepositoryName $repositoryName -Tag $tag).object.sha
                Update-GitHubReference -OwnerName $ownerName -RepositoryName $repositoryName -Tag $tag -Sha $masterSHA

                It 'Should return the updated SHA when the reference is queried after update' {
                    $newSHA = $(Get-GitHubReference -OwnerName $ownerName -RepositoryName $repositoryName -Tag $tag).object.sha
                    $newSHA | Should be $masterSHA
                    $newSHA | Should Not be $oldSHA
                }
            }

            $null = Remove-GitHubRepository -OwnerName $ownerName -RepositoryName $repositoryName -Confirm:$false
        }
    }
}
catch
{
    if (Test-Path -Path $script:originalConfigFile -PathType Leaf)
    {
        # Restore the user's configuration to its pre-test state
        Restore-GitHubConfiguration -Path $script:originalConfigFile
        $script:originalConfigFile = $null
    }
}