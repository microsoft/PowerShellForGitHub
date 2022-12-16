# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

<#
.Synopsis
   Tests for GitHubGraphQl.ps1 module
#>

[CmdletBinding()]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '',
    Justification = 'Suppress false positives in Pester code blocks')]
param()

BeforeAll {
    # This is common test code setup logic for all Pester test files
    $moduleRootPath = Split-Path -Path $PSScriptRoot -Parent
    . (Join-Path -Path $moduleRootPath -ChildPath 'Tests\Common.ps1')
}

Describe 'GitHubCore/Invoke-GHGraphQl' {
    BeforeAll {
        $Description = 'description'
        $AccessToken = ''
        $TelemetryEventName = $null
        $TelemetryProperties = @{}
        $TelemetryExceptionBucket = $null

        Mock -CommandName Invoke-UpdateCheck -ModuleName $script:moduleName
    }

    Context 'When a valid query is specified' {
        BeforeAll {
            $testBody = '{ "query": "query login { viewer { login } }" }'
        }

        BeforeEach {
            $invokeGHGraphQLParms = @{
                Body = $testBody
            }
            $result = Invoke-GHGraphQl @invokeGHGraphQLParms
        }

        It 'Should return the expected result' {

            $result.data.viewer.login | Should -Be $script:ownerName
        }

        It 'Should call the expected mocks' {
            Assert-MockCalled -CommandName Invoke-UpdateCheck `
                -ModuleName $script:moduleName `
                -Exactly -Times 1
        }
    }

    Context 'When there is a Web/HTTP Request exception in Invoke-WebRequest' {
        BeforeAll {
            $testHostName = 'invalidhostname'
            $testBody = 'testBody'

            if ($PSVersionTable.PSEdition -eq 'Core')
            {
                # The exception message varies per platform.  We could special-case it, but the exact message
                # may change over time and the module itself doesn't care about the specific message.
                # We'll just do a best-case match.
                # Windows: "No such host is known. ($($testHostName):443)"
                # Mac: "nodename nor servname provided, or not known ($($testHostName):443)"
                # Linux: "Resource temporarily unavailable ($($testHostName):443)"
                $exceptionMessage = "*$testHostName*"
                $categoryInfo = 'InvalidOperation'
                $targetName = "*$testHostName*"
            }
            else
            {
                $exceptionMessage = "The remote name could not be resolved: '$testHostName'"
                $categoryInfo = 'NotSpecified'
                $targetName = $testBody
            }

            Mock -CommandName Get-GitHubConfiguration -ModuleName $script:moduleName `
                -ParameterFilter { $Name -eq 'ApiHostName' } `
                -MockWith { 'invalidhostname' }
        }

        It 'Should throw the correct exception' {
            $invokeGHGraphQLParms = @{
                Body = $testBody
            }
            { Invoke-GHGraphQl @invokeGHGraphQlParms } |
            Should -Throw

            $Error[0].Exception.Message | Should -BeLike $exceptionMessage
            $Error[0].CategoryInfo.Category | Should -Be $categoryInfo
            $Error[0].CategoryInfo.TargetName | Should -BeLike $targetName
            $Error[0].FullyQualifiedErrorId | Should -BeLike '*Invoke-GHGraphQl'
        }
    }

    Context 'When there is a Web/HTTP Response exception in Invoke-WebRequest' {
        Context 'When there is invalid JSON in the request body' {
            BeforeAll {
                $testBody = 'InvalidJson'

                if ($PSVersionTable.PSEdition -eq 'Core')
                {
                    $exceptionMessage1 = '*Response status code does not indicate success: 400 (Bad Request)*'
                }
                else
                {
                    $exceptionMessage1 = '*The remote server returned an error: (400) Bad Request*'
                }

                $exceptionMessage2 = '*Problems parsing JSON | https://docs.github.com/graphql*'
            }

            It 'Should throw the correct exception' {
                $invokeGHGraphQLParms = @{
                    Body = $testBody
                }
                { Invoke-GHGraphQl @invokeGHGraphQlParms } |
                Should -Throw

                $Error[0].Exception.Message | Should -BeLike $exceptionMessage1
                $Error[0].Exception.Message | Should -BeLike $exceptionMessage2
                $Error[0].Exception.Message | Should -BeLike '*RequestId:*'
                $Error[0].CategoryInfo.Category | Should -Be 'InvalidOperation'
                $Error[0].CategoryInfo.TargetName | Should -Be $testBody
                $Error[0].FullyQualifiedErrorId | Should -BeLike '*Invoke-GHGraphQl'
            }
        }

        Context 'When the query user is not authenticated' {
            BeforeAll {
                $testBody = '{ "query": "query login { viewer { login } }" }'

                if ($PSVersionTable.PSEdition -eq 'Core')
                {
                    $exceptionMessage1 = '*Response status code does not indicate success: 401 (Unauthorized)*'
                }
                else
                {
                    $exceptionMessage1 = '*The remote server returned an error: (401) Unauthorized*'
                }

                $exceptionMessage2 = '*This endpoint requires you to be authenticated.*'

                Mock -CommandName Get-AccessToken -ModuleName $script:moduleName
            }

            It 'Should throw the correct exception' {
                $invokeGHGraphQLParms = @{
                    Body = $testBody
                }
                { Invoke-GHGraphQl @invokeGHGraphQlParms } |
                Should -Throw

                $Error[0].Exception.Message | Should -BeLike $exceptionMessage1
                $Error[0].Exception.Message | Should -BeLike $exceptionMessage2
                $Error[0].Exception.Message | Should -BeLike '*RequestId:*'
                $Error[0].CategoryInfo.Category | Should -Be 'InvalidOperation'
                $Error[0].CategoryInfo.TargetName | Should -Be $testBody
                $Error[0].FullyQualifiedErrorId | Should -BeLike '*Invoke-GHGraphQl'
            }
        }
    }

    Context 'When there is an other exception in Invoke-WebRequest' {
        BeforeAll {
            $testWebRequestTimeoutSec = 'invalid'
            $testBody = 'testBody'

            Mock -CommandName Get-GitHubConfiguration -ModuleName $script:moduleName `
                -ParameterFilter { $Name -eq 'WebRequestTimeoutSec' } `
                -MockWith { 'invalid' }
        }

        It 'Should throw the correct exception' {
            $invokeGHGraphQLParms = @{
                Body = $testBody
            }
            { Invoke-GHGraphQl @invokeGHGraphQlParms } |
            Should -Throw

            $Error[0].CategoryInfo.Category | Should -Be 'InvalidArgument'
            $Error[0].CategoryInfo.TargetName | Should -Be $testBody
            $Error[0].FullyQualifiedErrorId | Should -BeLike 'CannotConvertArgumentNoMessage*'
        }
    }

    Context 'When the GraphQl JSON Query is Invalid' {
        BeforeAll {
            $invalidQuery = 'InvalidQuery'
            $testBody = "{ ""query"":""$invalidQuery"" }"
        }

        It 'Should throw the correct exception' {
            $invokeGHGraphQLParms = @{
                Body = $testBody
            }
            { Invoke-GHGraphQl @invokeGHGraphQlParms } | Should -Throw

            $Error[0].Exception.Message | Should -BeLike "*Parse error on ""$invalidQuery""*"
            $Error[0].Exception.Message | Should -BeLike '*RequestId:*'
            $Error[0].CategoryInfo.Category | Should -Be 'NotSpecified'
            $Error[0].CategoryInfo.TargetName | Should -Be $testBody
            $Error[0].FullyQualifiedErrorId | Should -BeLike '*Invoke-GHGraphQl'
        }
    }

    Context 'When the GraphQl JSON query returns an error of ''NOT_FOUND''' {
        BeforeAll {
            $testOwner = 'microsoft'
            $testRepo = 'nonexisting-repo'
            $testQuery = "query repo { repository(name: \""$testRepo\"", owner: \""$testOwner\"") { id } }"
            $testBody = "{ ""query"": ""$testQuery"" }"
        }

        It 'Should throw the correct exception' {
            $invokeGHGraphQLParms = @{
                Body = $testBody
            }
            { Invoke-GHGraphQl @invokeGHGraphQlParms } | Should -Throw

            $Error[0].Exception.Message | Should -BeLike "*Could not resolve to a Repository with the name '$testOwner/$testRepo'*"
            $Error[0].Exception.Message | Should -BeLike '*RequestId:*'
            $Error[0].CategoryInfo.Category | Should -Be 'ObjectNotFound'
            $Error[0].CategoryInfo.TargetName | Should -Be $testBody
            $Error[0].FullyQualifiedErrorId | Should -Be 'NOT_FOUND,Invoke-GHGraphQl'
        }
    }
}

AfterAll {
    if (Test-Path -Path $script:originalConfigFile -PathType Leaf)
    {
        # Restore the user's configuration to its pre-test state
        Restore-GitHubConfiguration -Path $script:originalConfigFile
        $script:originalConfigFile = $null
    }
}
