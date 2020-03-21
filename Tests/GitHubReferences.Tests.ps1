# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

<#
.Synopsis
   Tests for GitHubReferences.ps1 module
#>

# This is common test code setup logic for all Pester test files
$moduleRootPath = Split-Path -Path $PSScriptRoot -Parent
. (Join-Path -Path $moduleRootPath -ChildPath 'Tests\Common.ps1')

try
{
    if ($accessTokenConfigured)
    {
        Describe 'Create a new reference(branch) in repository' {
            $repositoryName = [Guid]::NewGuid()
            $repo = New-GitHubRepository -RepositoryName $repositoryName -AutoInit
            $masterRefName = "heads/master"
            $existingref = Get-GitHubReference -OwnerName $ownerName -RepositoryName $repositoryName -Reference $masterRefName
            $sha = $existingref.object.sha

            Context 'On creating a valid reference in a new repository from a given SHA' {
                $refName = "heads/" + [Guid]::NewGuid().ToString()
                $result = New-GitHubReference -OwnerName $ownerName -RepositoryName $repositoryName -Reference $refName -Sha $sha

                It 'Should successfully create the reference' {
                    $result.ref | Should Be "refs/$refName"
                }
            }

            Context 'On creating a valid reference in a new repository (specified by Uri) from a given SHA' {
                $refName = "heads/" + [Guid]::NewGuid().ToString()
                $result = New-GitHubReference -Uri $repo.svn_url -Reference $refName -Sha $sha

                It 'Should successfully create the reference' {
                    $result.ref | Should Be "refs/$refName"
                }
            }

            Context 'On trying to create an existing reference in a new repository from a given SHA' {
                It 'Should throw an Exception' {
                    { New-GitHubReference -OwnerName $ownerName -RepositoryName $repositoryName -Reference $masterRefName -Sha $sha } | Should Throw
                }
            }

            Context 'On creating an existing reference in a new repository (specified by Uri) from a given SHA' {
                It 'Should throw an exception' {
                    { New-GitHubReference -Uri $repo.svn_url -Reference $masterRefName -Sha $sha }  | Should Throw
                }
            }

            $null = Remove-GitHubRepository -OwnerName $ownerName -RepositoryName $repositoryName
        }

        Describe 'Getting a reference(branch) from repository' {
            $repositoryName = [Guid]::NewGuid()
            $repo = New-GitHubRepository -RepositoryName $repositoryName -AutoInit
            $masterRefName = "heads/master"
            $randomRefName = "heads/$([Guid]::NewGuid())"

            Context 'On getting a valid reference from a new repository' {
                $reference = Get-GitHubReference -OwnerName $ownerName -RepositoryName $repositoryName -Reference $masterRefName

                It 'Should return details of the reference' {
                    $reference.ref | Should be "refs/$masterRefName"
                }
            }

            Context 'On getting an invalid reference from a new repository' {
                $reference = Get-GitHubReference -OwnerName $ownerName -RepositoryName $repositoryName -Reference $randomRefName

                It 'Should not return any details' {
                    $reference | Should be $null
                }
            }

            Context 'On getting a valid reference using Uri from a new repository' {
                $reference = Get-GitHubReference -Uri $repo.svn_url -Reference $masterRefName

                It 'Should return details of the reference' {
                    $reference.ref | Should be "refs/$masterRefName"
                }
            }

            Context 'On getting an invalid reference using Uri from a new repository' {
                $reference = Get-GitHubReference -Uri $repo.svn_url -Reference $randomRefName

                It 'Should not return any details' {
                    $reference | Should be $null
                }
            }

            $null = Remove-GitHubRepository -OwnerName $ownerName -RepositoryName $repositoryName
        }

        Describe 'Getting all references from repository' {
            $repositoryName = [Guid]::NewGuid()
            $repo = New-GitHubRepository -RepositoryName $repositoryName -AutoInit
            $masterRefName = "heads/master"
            $secondRefName = "heads/branch1"
            $existingref = Get-GitHubReference -OwnerName $ownerName -RepositoryName $repositoryName -Reference $masterRefName
            $sha = $existingref.object.sha
            New-GitHubReference -OwnerName $ownerName -RepositoryName $repositoryName -Reference $secondRefName -Sha $sha
            $refNames = @("refs/$masterRefName", "refs/$secondRefName")

            Context 'On getting all references from a new repository' {
                $reference = Get-GitHubReference -OwnerName $ownerName -RepositoryName $repositoryName

                It 'Should return all references' {
                    ($reference.ref | Where-Object {$refNames -Contains $_}).Count | Should be $refNames.Count
                }
            }

            Context 'On getting all references using Uri from a new repository' {
                $reference = Get-GitHubReference -Uri $repo.svn_url

                It 'Should return all references' {
                    ($reference.ref | Where-Object {$refNames -Contains $_}).Count | Should be $refNames.Count
                }
            }

            $null = Remove-GitHubRepository -OwnerName $ownerName -RepositoryName $repositoryName
        }

        Describe 'Delete a reference(branch) from repository' {
            $repositoryName = [Guid]::NewGuid()
            New-GitHubRepository -RepositoryName $repositoryName -AutoInit

            Context 'On deleting a newly created reference in a new repository' {
                $refname = "heads/myRef"
                $existingref = Get-GitHubReference -OwnerName $ownerName -RepositoryName $repositoryName -Reference "heads/master"
                $sha = $existingref.object.sha
                New-GitHubReference -OwnerName $ownerName -RepositoryName $repositoryName -Reference $refname -Sha $sha
                Remove-GitHubReference -OwnerName $ownerName -RepositoryName $repositoryName -Reference $refname

                It 'Should not return any details when the reference is queried' {
                    Get-GitHubReference -OwnerName $ownerName -RepositoryName $repositoryName -Reference $refname |
                    Should be $null
                }

                It 'Should throw an exception when the same reference is deleted again' {
                    { Remove-GitHubReference -OwnerName $ownerName -RepositoryName $repositoryName -Reference $refname } |
                    Should Throw
                }
            }

            Context 'On deleting an invalid reference from a new repository' {
                It 'Should throw an exception' {
                    { Remove-GitHubReference -OwnerName $ownerName -RepositoryName $repositoryName -Reference "heads/$([Guid]::NewGuid())" } |
                    Should Throw
                }
            }
            $null = Remove-GitHubRepository -OwnerName $ownerName -RepositoryName $repositoryName
        }

        Describe 'Update a reference(branch) in repository' {
            $masterRefName = "heads/master"
            $repositoryName = [Guid]::NewGuid()
            New-GitHubRepository -RepositoryName $repositoryName -AutoInit
            $refname = "heads/myRef"
            $existingref = Get-GitHubReference -OwnerName $ownerName -RepositoryName $repositoryName -Reference $masterRefName
            $sha = $existingref.object.sha
            New-GitHubReference -OwnerName $ownerName -RepositoryName $repositoryName -Reference $refname -Sha $sha

            Context 'On updating a newly created reference to a different SHA' {
                It 'Should throw an exception if the SHA is invalid' {
                    { Update-GitHubReference -OwnerName $ownerName -RepositoryName $repositoryName -Reference $refname -Sha "1234" } |
                    Should Throw
                }
            }

            Context 'On updating a reference to a different SHA' {
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

                # Update branch with master SHA
                $masterSHA = $(Get-GitHubReference -OwnerName $ownerName -RepositoryName $repositoryName -Reference $masterRefName).object.sha
                $oldSHA = $(Get-GitHubReference -OwnerName $ownerName -RepositoryName $repositoryName -Reference $refname).object.sha
                Update-GitHubReference -OwnerName $ownerName -RepositoryName $repositoryName -Reference $refname -Sha $masterSHA

                It 'Should return the updated SHA when the reference is queried after update' {
                    $newSHA = $(Get-GitHubReference -OwnerName $ownerName -RepositoryName $repositoryName -Reference $refname).object.sha
                    $newSHA | Should be $masterSHA
                    $newSHA | Should Not be $oldSHA
                }
            }

            $null = Remove-GitHubRepository -OwnerName $ownerName -RepositoryName $repositoryName
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

