$script:DSCModuleName      = 'LanguageDsc'
$script:DSCResourceName    = 'MSFT_Language'

#Remove any modules with the same name before importing the version for testing.  See https://blogs.technet.microsoft.com/heyscriptingguy/2015/12/17/testing-script-modules-with-pester/ for explination
Get-Module $script:DSCModuleName | Remove-Module -Force

#region HEADER

# Unit Test Template Version: 1.2.0
$script:moduleRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
Write-Output @('clone','https://github.com/PowerShell/DscResource.Tests.git',"'"+(Join-Path -Path $script:moduleRoot -ChildPath '\DSCResource.Tests')+"'")

if ( (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests'))) -or `
     (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1'))) )
{
    & git @('clone','https://github.com/PowerShell/DscResource.Tests.git',(Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests'),'--verbose')
}

Import-Module -Name (Join-Path -Path $script:moduleRoot -ChildPath (Join-Path -Path 'DSCResource.Tests' -ChildPath 'TestHelper.psm1')) -Force

$TestEnvironment = Initialize-TestEnvironment `
    -DSCModuleName $script:DSCModuleName `
    -DSCResourceName $script:DSCResourceName `
    -TestType Unit

#endregion HEADER

function Invoke-TestSetup {
    #Remove Temp file before starting testing encase it already exists
    Remove-Item -Path "$env:TEMP\Locale.xml" -Force -ErrorAction SilentlyContinue
}

function Invoke-TestCleanup {
    Restore-TestEnvironment -TestEnvironment $TestEnvironment

    #Remove Temp file after testing to keep the environment clean
    #Remove-Item -Path "$env:TEMP\Locale.xml" -Force -ErrorAction SilentlyContinue
}

# Begin Testing
try
{

    Invoke-TestSetup

    InModuleScope 'MSFT_Language' {
        #Define Static Variables used within all Tests
        $script:DSCResourceName = 'MSFT_Language'
        $CurrentLocation = "242"
        [String]$CurrentUILanguage = "en-GB"
        [String[]]$CurrentUILanguageArray = @("$CurrentUILanguage")
        [String]$CurrentUIFallbackLanguage = "en-US"
        [String[]]$CurrentUIFallbackLanguageArray = @("en-US")
        $CurrentSystemLocale = "en-GB"
        $CurrentInstalledLanguages = @("en-GB","en-US")
        $CurrentUserLocale = "en-GB"
        $LanguageToRemove = "en-US"
        $NewLocation = 58
        $NewUILanguage = "de-DE"
        $NewFallbackLanguage = "en-GB"
        $NewSystemLocale = "de-DE"
        $LanguageToInstall = "de-DE"
        $NewUserLocale = "de-DE"
        $ValidLocationConfig = '<gs:GlobalizationServices xmlns:gs="urn:longhornGlobalizationUnattend">`n    <gs:UserList>`n        <gs:User UserID="Current" CopySettingsToDefaultUserAcct="true" CopySettingsToSystemAcct="true"/>`n    </gs:UserList>`n    <gs:LocationPreferences>`n        <gs:GeoID Value="58"/>`n    </gs:LocationPreferences>`n    <gs:MUILanguagePreferences>`n        <gs:MUILanguage Value="en-GB"/>`n        <gs:MUIFallback Value="en-US"/>`n    </gs:MUILanguagePreferences>    <gs:SystemLocale Name="en-GB"/>`n    <gs:InputPreferences>`n        <gs:InputLanguageID Action="add" ID="en-GB"/>`n        <gs:InputLanguageID Action="add" ID="en-US"/>`n    </gs:InputPreferences>`n    <gs:UserLocale>`n        <gs:Locale Name="en-GB" SetAsCurrent="true" ResetAllSettings="true"/>`n    </gs:UserLocale>`n</gs:GlobalizationServices>`n'
        $ValidRemovalConfig = '<gs:GlobalizationServices xmlns:gs="urn:longhornGlobalizationUnattend">`n    <gs:UserList>`n        <gs:User UserID="Current" CopySettingsToDefaultUserAcct="true" CopySettingsToSystemAcct="true"/>`n    </gs:UserList>`n    <gs:LocationPreferences>`n        <gs:GeoID Value="58"/>`n    </gs:LocationPreferences>`n    <gs:MUILanguagePreferences>`n        <gs:MUILanguage Value="en-GB"/>`n        <gs:MUIFallback Value="en-US"/>`n    </gs:MUILanguagePreferences>`n    <gs:SystemLocale Name="en-GB"/>`n    <gs:InputPreferences>`n        <gs:InputLanguageID Action="remove" ID="en-US"/>`n    </gs:InputPreferences>`n    <gs:UserLocale>`n        <gs:Locale Name="en-GB" SetAsCurrent="true" ResetAllSettings="true"/>`n    </gs:UserLocale>`n</gs:GlobalizationServices>`n'

        # TODO: Complete the Describe blocks below and add more as needed.
        # The most common method for unit testing is to test by function. For more information
        # check out this introduction to writing unit tests in Pester:
        # https://www.simple-talk.com/sysadmin/powershell/practical-powershell-unit-testing-getting-started/#eleventh
        # You may also follow one of the patterns provided in the TestsGuidelines.md file:
        # https://github.com/PowerShell/DscResources/blob/master/TestsGuidelines.md

        Describe 'Schema' {

            Context 'Check Variable requirements' {
                $LanguageResource = Get-DscResource -Name Language

                it 'IsSingleInstance should be mandatory.' {
                
                    $LanguageResource.Properties.Where{$_.Name -eq 'IsSingleInstance'}.IsMandatory | should be $true
                }

                it 'LocationID should not be mandatory and should be an 32bit integer.' {
                    $LanguageResource.Properties.Where{$_.Name -eq 'LocationID'}.IsMandatory | should be $false
                    $LanguageResource.Properties.Where{$_.Name -eq 'LocationID'}.PropertyType | should be "[Int32]"
                }

                it 'MUILanguage should not be mandatory and should be a string.' {
                    $LanguageResource.Properties.Where{$_.Name -eq 'MUILanguage'}.IsMandatory | should be $false
                    $LanguageResource.Properties.Where{$_.Name -eq 'MUILanguage'}.PropertyType | should be "[String]"
                }

                it 'MUIFallbackLanguage should not be mandatory and should be a string.' {
                    $LanguageResource.Properties.Where{$_.Name -eq 'MUIFallbackLanguage'}.IsMandatory | should be $false
                    $LanguageResource.Properties.Where{$_.Name -eq 'MUIFallbackLanguage'}.PropertyType | should be "[String]"
                }
                it 'SystemLocale should not be mandatory and should be a string.' {
                    $LanguageResource.Properties.Where{$_.Name -eq 'SystemLocale'}.IsMandatory | should be $false
                    $LanguageResource.Properties.Where{$_.Name -eq 'SystemLocale'}.PropertyType | should be "[String]"
                }
                it 'AddInputLanguages should not be mandatory and should be a string array.' {
                    $LanguageResource.Properties.Where{$_.Name -eq 'AddInputLanguages'}.IsMandatory | should be $false
                    $LanguageResource.Properties.Where{$_.Name -eq 'AddInputLanguages'}.PropertyType | should be "[String[]]"
                }
                it 'RemoveInputLanguages should not be mandatory and should be a string array.' {
                    $LanguageResource.Properties.Where{$_.Name -eq 'RemoveInputLanguages'}.IsMandatory | should be $false
                    $LanguageResource.Properties.Where{$_.Name -eq 'RemoveInputLanguages'}.PropertyType | should be "[String[]]"
                }
                it 'UserLocale should not be mandatory and should be a string.' {
                    $LanguageResource.Properties.Where{$_.Name -eq 'UserLocale'}.IsMandatory | should be $false
                    $LanguageResource.Properties.Where{$_.Name -eq 'UserLocale'}.PropertyType | should be "[String]"
                }
                it 'CopySystem should not be mandatory and should be a boolean.' {
                    $LanguageResource.Properties.Where{$_.Name -eq 'CopySystem'}.IsMandatory | should be $false
                    $LanguageResource.Properties.Where{$_.Name -eq 'CopySystem'}.PropertyType | should be "[Bool]"
                }
                it 'CopyNewUser should not be mandatory and should be a boolean.' {
                    $LanguageResource.Properties.Where{$_.Name -eq 'CopyNewUser'}.IsMandatory | should be $false
                    $LanguageResource.Properties.Where{$_.Name -eq 'CopyNewUser'}.PropertyType | should be "[Bool]"
                }
            }
        }

        Describe "$($script:DSCResourceName)\Get-TargetResource" {
            Mock -CommandName Get-ItemPropertyValue `
                -ModuleName $($script:DSCResourceName) `
                -MockWith {"Mock Required"}
            Mock -CommandName Get-ItemPropertyValue `
                -ParameterFilter { ($Path -eq "HKCU:\Control Panel\International\Geo\") -and ($Name -eq "Nation") }`
                -ModuleName $($script:DSCResourceName) `
                -MockWith { $CurrentLocation } `
                -Verifiable
            Mock -CommandName Get-ItemPropertyValue `
                -ParameterFilter { ($Path -eq "HKCU:\Control Panel\Desktop\") -and ($Name -eq "PreferredUILanguages") }`
                -ModuleName $($script:DSCResourceName) `
                -MockWith { [String[]]@($CurrentUILanguage,"") } `
                -Verifiable
            #MockWith doesn't work with single item
            Mock -CommandName Get-ItemPropertyValue `
                -ParameterFilter { ($Path -eq "HKCU:\Control Panel\Desktop\LanguageConfiguration\") -and ($Name -eq $CurrentUILanguage) }`
                -ModuleName $($script:DSCResourceName) `
                -MockWith { @($CurrentUIFallbackLanguage,"") } `
                -Verifiable
            #MockWith doesn't work with single item
            Mock -CommandName Get-WinSystemLocale `
                -ModuleName $($script:DSCResourceName) `
                -MockWith { @{Name = $CurrentSystemLocale}} `
                -Verifiable
            Mock -CommandName Get-ItemPropertyValue `
                -ParameterFilter { ($Path -eq "HKCU:\Control Panel\International\User Profile") -and ($Name -eq "Languages") }`
                -ModuleName $($script:DSCResourceName) `
                -MockWith { $CurrentInstalledLanguages } `
                -Verifiable
            Mock -CommandName Get-ItemPropertyValue `
                -ParameterFilter { ($Path -eq "HKCU:\Control Panel\International") -and ($Name -eq "LocaleName") }`
                -ModuleName $($script:DSCResourceName) `
                -MockWith { $CurrentUserLocale } `
                -Verifiable

            Context 'Get current Language State' {
                $CurrentState = Get-TargetResource `
                    -IsSingleInstance "Yes" `
                    -Verbose

                it 'All Mocks should have run'{
                    {Assert-VerifiableMocks} | should not throw
                }

                It 'Should return hashtable with Key IsSingleInstance'{
                    $CurrentState.ContainsKey('IsSingleInstance') | Should Be $true
                    $CurrentState.IsSingleInstance -eq "Yes"  | should be $true
                }
                Write-Verbose "Returned IsSingleInstance: $($CurrentState.IsSingleInstance)" -Verbose:$true

                It "Should return hashtable with Name LocationID and a Value that matches '$CurrentLocation'" {
                    $CurrentState.ContainsKey('LocationID') | Should Be $true
                    $CurrentState.LocationID -eq $CurrentLocation | should be $true
                }
                Write-Verbose "Returned LocationID: $($CurrentState.LocationID)" -Verbose:$true

                It "Should return hashtable with Name MUILanguage and a Value that matches '$($CurrentUILanguage)'" {
                    $CurrentState.ContainsKey('MUILanguage') | Should Be $true
                    $CurrentState.MUILanguage -eq $CurrentUILanguageArray | should be $true
                }
                Write-Verbose "Returned MUILanguage: $($CurrentState.MUILanguage)" -Verbose:$true

                It "Should return hashtable with Name MUIFallbackLanguage and a Value that matches '$CurrentUIFallbackLanguage'" {
                    $CurrentState.ContainsKey('MUIFallbackLanguage') | Should Be $true
                    $CurrentState.MUIFallbackLanguage -eq $CurrentUIFallbackLanguage | should be $true
                }
                Write-Verbose "Returned MUIFallbackLanguage: $($CurrentState.MUIFallbackLanguage)" -Verbose:$true

                It "Should return hashtable with Name SystemLocale and a Value that matches '$CurrentSystemLocale'" {
                    $CurrentState.ContainsKey('SystemLocale') | Should Be $true
                    $CurrentState.SystemLocale -eq $CurrentSystemLocale | should be $true
                }
                Write-Verbose "Returned SystemLocale: $($CurrentState.SystemLocale)" -Verbose:$true

                $LanguageArray = @($CurrentState.CurrentInstalledLanguages)
                It "Should return hashtable with Name CurrentInstalledLanguages and a Value that matches '$CurrentInstalledLanguages'" {
                    $CurrentState.ContainsKey('CurrentInstalledLanguages') | Should Be $true
                    Compare-Object -ReferenceObject $CurrentInstalledLanguages -DifferenceObject $LanguageArray | Should be $null
                }
                Write-Verbose "Returned CurrentInstalledLanguages: $($LanguageArray)" -Verbose:$true

                It "Should return hashtable with Name UserLocale and a Value that matches '$CurrentUserLocale'" {
                    $CurrentState.ContainsKey('UserLocale') | Should Be $true
                    $CurrentState.UserLocale -eq $CurrentUserLocale | should be $true
                }
                Write-Verbose "Returned UserLocale: $($CurrentState.UserLocale)" -Verbose:$true
            }

            Context 'Get current Language State with failing PreferredUILanguages' {
                Mock -CommandName Get-ItemPropertyValue `
                -ParameterFilter { ($Path -eq "HKCU:\Control Panel\Desktop\") -and ($Name -eq "PreferredUILanguages") }`
                -ModuleName $($script:DSCResourceName) `
                -MockWith { Throw "Invalid Entry" } `
                -Verifiable

                Mock -CommandName Get-ItemPropertyValue `
                -ParameterFilter { ($Path -eq "HKCU:\Control Panel\Desktop\MuiCached\") -and ($Name -eq "MachinePreferredUILanguages") }`
                -ModuleName $($script:DSCResourceName) `
                -MockWith { [String[]]@($CurrentUILanguage,"") } `
                -Verifiable

                $CurrentState = Get-TargetResource `
                    -IsSingleInstance "Yes" `
                    -Verbose

                it 'All Mocks should have run'{
                    {Assert-VerifiableMocks} | should not throw
                }

                It 'Should return hashtable with Key IsSingleInstance'{
                    $CurrentState.ContainsKey('IsSingleInstance') | Should Be $true
                    $CurrentState.IsSingleInstance -eq "Yes"  | should be $true
                }
                Write-Verbose "Returned IsSingleInstance: $($CurrentState.IsSingleInstance)" -Verbose:$true

                It "Should return hashtable with Name LocationID and a Value that matches '$CurrentLocation'" {
                    $CurrentState.ContainsKey('LocationID') | Should Be $true
                    $CurrentState.LocationID -eq $CurrentLocation | should be $true
                }
                Write-Verbose "Returned LocationID: $($CurrentState.LocationID)" -Verbose:$true

                It "Should return hashtable with Name MUILanguage and a Value that matches '$($CurrentUILanguage)'" {
                    $CurrentState.ContainsKey('MUILanguage') | Should Be $true
                    $CurrentState.MUILanguage -eq $CurrentUILanguageArray | should be $true
                }
                Write-Verbose "Returned MUILanguage: $($CurrentState.MUILanguage)" -Verbose:$true

                It "Should return hashtable with Name MUIFallbackLanguage and a Value that matches '$CurrentUIFallbackLanguage'" {
                    $CurrentState.ContainsKey('MUIFallbackLanguage') | Should Be $true
                    $CurrentState.MUIFallbackLanguage -eq $CurrentUIFallbackLanguage | should be $true
                }
                Write-Verbose "Returned MUIFallbackLanguage: $($CurrentState.MUIFallbackLanguage)" -Verbose:$true

                It "Should return hashtable with Name SystemLocale and a Value that matches '$CurrentSystemLocale'" {
                    $CurrentState.ContainsKey('SystemLocale') | Should Be $true
                    $CurrentState.SystemLocale -eq $CurrentSystemLocale | should be $true
                }
                Write-Verbose "Returned SystemLocale: $($CurrentState.SystemLocale)" -Verbose:$true

                $LanguageArray = @($CurrentState.CurrentInstalledLanguages)
                It "Should return hashtable with Name CurrentInstalledLanguages and a Value that matches '$CurrentInstalledLanguages'" {
                    $CurrentState.ContainsKey('CurrentInstalledLanguages') | Should Be $true
                    Compare-Object -ReferenceObject $CurrentInstalledLanguages -DifferenceObject $LanguageArray | Should be $null
                }
                Write-Verbose "Returned CurrentInstalledLanguages: $($LanguageArray)" -Verbose:$true

                It "Should return hashtable with Name UserLocale and a Value that matches '$CurrentUserLocale'" {
                    $CurrentState.ContainsKey('UserLocale') | Should Be $true
                    $CurrentState.UserLocale -eq $CurrentUserLocale | should be $true
                }
                Write-Verbose "Returned UserLocale: $($CurrentState.UserLocale)" -Verbose:$true
            }

            Context 'Get current Language State without Fallback Language' {
                Mock -CommandName Get-ItemPropertyValue `
                -ParameterFilter { ($Path -eq "HKCU:\Control Panel\Desktop\LanguageConfiguration\") -and ($Name -eq $CurrentUILanguage) }`
                -ModuleName $($script:DSCResourceName) `
                -MockWith { Throw "Invalid Entry" } `
                -Verifiable

                $CurrentState = Get-TargetResource `
                    -IsSingleInstance "Yes" `
                    -Verbose

                it 'All Mocks should have run'{
                    {Assert-VerifiableMocks} | should not throw
                }

                It 'Should return hashtable with Key IsSingleInstance'{
                    $CurrentState.ContainsKey('IsSingleInstance') | Should Be $true
                    $CurrentState.IsSingleInstance -eq "Yes"  | should be $true
                }
                Write-Verbose "Returned IsSingleInstance: $($CurrentState.IsSingleInstance)" -Verbose:$true

                It "Should return hashtable with Name LocationID and a Value that matches '$CurrentLocation'" {
                    $CurrentState.ContainsKey('LocationID') | Should Be $true
                    $CurrentState.LocationID -eq $CurrentLocation | should be $true
                }
                Write-Verbose "Returned LocationID: $($CurrentState.LocationID)" -Verbose:$true

                It "Should return hashtable with Name MUILanguage and a Value that matches '$($CurrentUILanguage)'" {
                    $CurrentState.ContainsKey('MUILanguage') | Should Be $true
                    $CurrentState.MUILanguage -eq $CurrentUILanguageArray | should be $true
                }
                Write-Verbose "Returned MUILanguage: $($CurrentState.MUILanguage)" -Verbose:$true

                It "Should return hashtable with Name MUIFallbackLanguage and an empty string" {
                    $CurrentState.ContainsKey('MUIFallbackLanguage') | Should Be $true
                    $CurrentState.MUIFallbackLanguage -eq "" | should be $true
                }
                Write-Verbose "Returned MUIFallbackLanguage: $($CurrentState.MUIFallbackLanguage)" -Verbose:$true

                It "Should return hashtable with Name SystemLocale and a Value that matches '$CurrentSystemLocale'" {
                    $CurrentState.ContainsKey('SystemLocale') | Should Be $true
                    $CurrentState.SystemLocale -eq $CurrentSystemLocale | should be $true
                }
                Write-Verbose "Returned SystemLocale: $($CurrentState.SystemLocale)" -Verbose:$true

                $LanguageArray = @($CurrentState.CurrentInstalledLanguages)
                It "Should return hashtable with Name CurrentInstalledLanguages and a Value that matches '$CurrentInstalledLanguages'" {
                    $CurrentState.ContainsKey('CurrentInstalledLanguages') | Should Be $true
                    Compare-Object -ReferenceObject $CurrentInstalledLanguages -DifferenceObject $LanguageArray | Should be $null
                }
                Write-Verbose "Returned CurrentInstalledLanguages: $($LanguageArray)" -Verbose:$true

                It "Should return hashtable with Name UserLocale and a Value that matches '$CurrentUserLocale'" {
                    $CurrentState.ContainsKey('UserLocale') | Should Be $true
                    $CurrentState.UserLocale -eq $CurrentUserLocale | should be $true
                }
                Write-Verbose "Returned UserLocale: $($CurrentState.UserLocale)" -Verbose:$true
            }
        }

        Describe "$($script:DSCResourceName)\Test-TargetResource" {

            #Mock Current User
            Mock -CommandName Get-ItemPropertyValue `
                -ModuleName $($script:DSCResourceName) `
                -MockWith {"Mock Required"}
            Mock -CommandName Get-ItemPropertyValue `
                -ParameterFilter { ($Path -eq "HKCU:\Control Panel\International\Geo\") -and ($Name -eq "Nation") }`
                -ModuleName $($script:DSCResourceName) `
                -MockWith { $CurrentLocation } `
                -Verifiable
            Mock -CommandName Get-ItemPropertyValue `
                -ParameterFilter { ($Path -eq "HKCU:\Control Panel\Desktop\") -and ($Name -eq "PreferredUILanguages") }`
                -ModuleName $($script:DSCResourceName) `
                -MockWith { [String[]]@($CurrentUILanguage,"") } `
                -Verifiable
            Mock -CommandName Get-ItemPropertyValue `
                -ParameterFilter { ($Path -eq "HKCU:\Control Panel\Desktop\LanguageConfiguration\") -and ($Name -eq $CurrentUILanguage) }`
                -ModuleName $($script:DSCResourceName) `
                -MockWith { @($CurrentUIFallbackLanguage,"") } `
                -Verifiable
            Mock -CommandName Get-WinSystemLocale `
                -ModuleName $($script:DSCResourceName) `
                -MockWith { @{Name = $CurrentSystemLocale}} `
                -Verifiable
            Mock -CommandName Get-ItemPropertyValue `
                -ParameterFilter { ($Path -eq "HKCU:\Control Panel\International\User Profile\") -and ($Name -eq "Languages") }`
                -ModuleName $($script:DSCResourceName) `
                -MockWith { $CurrentInstalledLanguages } `
                -Verifiable
            Mock -CommandName Get-ItemPropertyValue `
                -ParameterFilter { ($Path -eq "HKCU:\Control Panel\International\") -and ($Name -eq "LocaleName") }`
                -ModuleName $($script:DSCResourceName) `
                -MockWith { $CurrentUserLocale } `
                -Verifiable

            #Mock System Account User
            Mock -CommandName Get-ItemPropertyValue `
                -ParameterFilter { ($Path -eq "registry::hkey_Users\S-1-5-18\Control Panel\International\Geo\") -and ($Name -eq "Nation") }`
                -ModuleName $($script:DSCResourceName) `
                -MockWith { $CurrentLocation } `
                -Verifiable
            Mock -CommandName Get-ItemPropertyValue `
                -ParameterFilter { ($Path -eq "registry::hkey_Users\S-1-5-18\Control Panel\Desktop\MuiCached\") -and ($Name -eq "MachinePreferredUILanguages") }`
                -ModuleName $($script:DSCResourceName) `
                -MockWith { @($CurrentUILanguage,"") } `
                -Verifiable
            Mock -CommandName Get-ItemPropertyValue `
                -ParameterFilter { ($Path -eq "registry::hkey_Users\S-1-5-18\Control Panel\Desktop\MuiCached\MachineLanguageConfiguration\") -and ($Name -eq $CurrentUILanguage) }`
                -ModuleName $($script:DSCResourceName) `
                -MockWith { @($CurrentUIFallbackLanguage,"") } `
                -Verifiable
            Mock -CommandName Get-ItemPropertyValue `
                -ParameterFilter { ($Path -eq "registry::hkey_Users\S-1-5-18\Control Panel\International\User Profile\") -and ($Name -eq "Languages") }`
                -ModuleName $($script:DSCResourceName) `
                -MockWith { $CurrentInstalledLanguages } `
                -Verifiable
            Mock -CommandName Get-ItemPropertyValue `
                -ParameterFilter { ($Path -eq "registry::hkey_Users\S-1-5-18\Control Panel\International\") -and ($Name -eq "LocaleName") }`
                -ModuleName $($script:DSCResourceName) `
                -MockWith { $CurrentUserLocale } `
                -Verifiable

            #Mock New User Settings
            Mock -CommandName Get-ItemPropertyValue `
                -ParameterFilter { ($Path -eq "registry::hkey_Users\.DEFAULT\Control Panel\International\Geo\") -and ($Name -eq "Nation") }`
                -ModuleName $($script:DSCResourceName) `
                -MockWith { $CurrentLocation } `
                -Verifiable
            Mock -CommandName Get-ItemPropertyValue `
                -ParameterFilter { ($Path -eq "registry::hkey_Users\.DEFAULT\Control Panel\Desktop\MuiCached\") -and ($Name -eq "MachinePreferredUILanguages") }`
                -ModuleName $($script:DSCResourceName) `
                -MockWith { @($CurrentUILanguage,"") } `
                -Verifiable
            Mock -CommandName Get-ItemPropertyValue `
                -ParameterFilter { ($Path -eq "registry::hkey_Users\.DEFAULT\Control Panel\Desktop\MuiCached\MachineLanguageConfiguration\") -and ($Name -eq $CurrentUILanguage) }`
                -ModuleName $($script:DSCResourceName) `
                -MockWith { @($CurrentUIFallbackLanguage,"") } `
                -Verifiable
            Mock -CommandName Get-ItemPropertyValue `
                -ParameterFilter { ($Path -eq "registry::hkey_Users\.DEFAULT\Control Panel\International\User Profile\") -and ($Name -eq "Languages") }`
                -ModuleName $($script:DSCResourceName) `
                -MockWith { $CurrentInstalledLanguages } `
                -Verifiable
            Mock -CommandName Get-ItemPropertyValue `
                -ParameterFilter { ($Path -eq "registry::hkey_Users\.DEFAULT\Control Panel\International\") -and ($Name -eq "LocaleName") }`
                -ModuleName $($script:DSCResourceName) `
                -MockWith { $CurrentUserLocale } `
                -Verifiable

            Context 'No Settings Specified' {
                $TestState = Test-TargetResource `
                    -IsSingleInstance "Yes" `
                    -Verbose
                
                It 'Should not throw exception' {
                    {
                        Test-TargetResource `
                            -IsSingleInstance "Yes"
                    } | Should Not Throw
                }
                
                It 'All Mocks should have run'{
                    {Assert-VerifiableMocks} | should not throw
                }

                It 'Function Should return true'{
                    $TestState | Should Be $true
                }
            }

            Context 'Require no changes to all accounts' {
                $TestState = Test-TargetResource `
                    -IsSingleInstance "Yes" `
                    -LocationID $CurrentLocation `
                    -MUILanguage $CurrentUILanguage `
                    -MUIFallbackLanguage $CurrentUIFallbackLanguage `
                    -SystemLocale $CurrentSystemLocale `
                    -AddInputLanguages $CurrentInstalledLanguages `
                    -UserLocale $CurrentUserLocale `
                    -CopySystem $true `
                    -CopyNewUser $true `
                    -Verbose
                
                It 'Should not throw exception' {
                    {
                        Test-TargetResource `
                            -IsSingleInstance "Yes" `
                            -LocationID $CurrentLocation `
                            -MUILanguage $CurrentUILanguage `
                            -MUIFallbackLanguage $CurrentUIFallbackLanguage `
                            -SystemLocale $CurrentSystemLocale `
                            -AddInputLanguages $CurrentInstalledLanguages `
                            -UserLocale $CurrentUserLocale `
                            -CopySystem $true `
                            -CopyNewUser $true `
                            -Verbose
                    } | Should Not Throw
                }

                It 'All Mocks should have run'{
                    {Assert-VerifiableMocks} | should not throw
                }

                It 'Function Should return true'{
                    $TestState | Should Be $true
                }
            }

            Context 'Require no changes to all accounts with failing PreferredUILanguages' {
                Mock -CommandName Get-ItemPropertyValue `
                -ParameterFilter { ($Path -eq "HKCU:\Control Panel\Desktop\") -and ($Name -eq "PreferredUILanguages") }`
                -ModuleName $($script:DSCResourceName) `
                -MockWith { Throw "Invalid Entry" } `
                -Verifiable

                Mock -CommandName Get-ItemPropertyValue `
                -ParameterFilter { ($Path -eq "HKCU:\Control Panel\Desktop\MuiCached\") -and ($Name -eq "MachinePreferredUILanguages") }`
                -ModuleName $($script:DSCResourceName) `
                -MockWith { [String[]]@($CurrentUILanguage,"") } `
                -Verifiable

                $TestState = Test-TargetResource `
                    -IsSingleInstance "Yes" `
                    -LocationID $CurrentLocation `
                    -MUILanguage $CurrentUILanguage `
                    -MUIFallbackLanguage $CurrentUIFallbackLanguage `
                    -SystemLocale $CurrentSystemLocale `
                    -AddInputLanguages $CurrentInstalledLanguages `
                    -UserLocale $CurrentUserLocale `
                    -CopySystem $true `
                    -CopyNewUser $true `
                    -Verbose
                
                It 'Should not throw exception' {
                    {
                        Test-TargetResource `
                            -IsSingleInstance "Yes" `
                            -LocationID $CurrentLocation `
                            -MUILanguage $CurrentUILanguage `
                            -MUIFallbackLanguage $CurrentUIFallbackLanguage `
                            -SystemLocale $CurrentSystemLocale `
                            -AddInputLanguages $CurrentInstalledLanguages `
                            -UserLocale $CurrentUserLocale `
                            -CopySystem $true `
                            -CopyNewUser $true `
                            -Verbose
                    } | Should Not Throw
                }

                It 'All Mocks should have run'{
                    {Assert-VerifiableMocks} | should not throw
                }

                It 'Function Should return true'{
                    $TestState | Should Be $true
                }
            }

            Context 'Require changes to all accounts as everything has changed' {
                $TestState = Test-TargetResource `
                    -IsSingleInstance "Yes" `
                    -LocationID $NewLocation `
                    -MUILanguage $NewUILanguage `
                    -MUIFallbackLanguage $NewFallbackLanguage `
                    -SystemLocale $NewSystemLocale `
                    -AddInputLanguages $LanguageToInstall `
                    -RemoveInputLanguages $LanguageToRemove `
                    -UserLocale $NewUserLocale `
                    -CopySystem $true `
                    -CopyNewUser $true `
                    -Verbose
                
                It 'Should not throw exception' {
                    {
                        Test-TargetResource `
                            -IsSingleInstance "Yes" `
                            -LocationID $NewLocation `
                            -MUILanguage $NewUILanguage `
                            -MUIFallbackLanguage $NewFallbackLanguage `
                            -SystemLocale $NewSystemLocale `
                            -AddInputLanguages $LanguageToInstall `
                            -RemoveInputLanguages $LanguageToRemove `
                            -UserLocale $NewUserLocale `
                            -CopySystem $true `
                            -CopyNewUser $true `
                            -Verbose
                    } | Should Not Throw
                }

                It 'All Mocks should have run'{
                    {Assert-VerifiableMocks} | should not throw
                }

                It 'Should return false'{
                    $TestState | Should Be $false
                }
            }

            Context "Require no changes as while the system and new user accounts don't match as no copy is required" {
                Mock -CommandName Get-ItemPropertyValue `
                -ParameterFilter { ($Path -eq "HKCU:\Control Panel\International\Geo\") -and ($Name -eq "Nation") }`
                -ModuleName $($script:DSCResourceName) `
                -MockWith { $NewLocation } `
                -Verifiable
                $TestState = Test-TargetResource `
                    -IsSingleInstance "Yes" `
                    -LocationID $NewLocation `
                    -MUILanguage $CurrentUILanguage `
                    -MUIFallbackLanguage $CurrentUIFallbackLanguage `
                    -SystemLocale $CurrentSystemLocale `
                    -AddInputLanguages $CurrentInstalledLanguages `
                    -UserLocale $CurrentUserLocale `
                    -CopySystem $false `
                    -CopyNewUser $false `
                    -Verbose
                
                It 'Should not throw exception' {
                    {
                        Test-TargetResource `
                            -IsSingleInstance "Yes" `
                            -LocationID $NewLocation `
                            -MUILanguage $CurrentUILanguage `
                            -MUIFallbackLanguage $CurrentUIFallbackLanguage `
                            -SystemLocale $CurrentSystemLocale `
                            -AddInputLanguages $CurrentInstalledLanguages `
                            -UserLocale $CurrentUserLocale `
                            -CopySystem $false `
                            -CopyNewUser $false `
                            -Verbose
                    } | Should Not Throw
                }

                It 'All Mocks should have run'{
                    {Assert-VerifiableMocks} | should not throw
                }

                It 'Should return true'{
                    $TestState | Should Be $true
                }
            }

            Context 'Require Removal of Language' {
                $TestState = Test-TargetResource `
                    -IsSingleInstance "Yes" `
                    -LocationID $NewLocation `
                    -MUILanguage $CurrentUILanguage `
                    -MUIFallbackLanguage $CurrentUIFallbackLanguage `
                    -SystemLocale $CurrentSystemLocale `
                    -RemoveInputLanguages $LanguageToRemove `
                    -UserLocale $CurrentUserLocale `
                    -CopySystem $true `
                    -CopyNewUser $true `
                    -Verbose
                
                It 'Should not throw exception' {
                    {
                        Test-TargetResource `
                            -IsSingleInstance "Yes" `
                            -LocationID $NewLocation `
                            -MUILanguage $CurrentUILanguage `
                            -MUIFallbackLanguage $CurrentUIFallbackLanguage `
                            -SystemLocale $CurrentSystemLocale `
                            -RemoveInputLanguages $LanguageToRemove `
                            -UserLocale $CurrentUserLocale `
                            -CopySystem $true `
                            -CopyNewUser $true `
                            -Verbose
                    } | Should Not Throw
                }

                It 'All Mocks should have run'{
                    {Assert-VerifiableMocks} | should not throw
                }

                It 'Should return false'{
                    $TestState | Should Be $false
                }
            }

            Context 'Require no changes to when no fallback language is used' {
                Mock -CommandName Get-ItemPropertyValue `
                -ParameterFilter { ($Path -eq "HKCU:\Control Panel\Desktop\LanguageConfiguration\") -and ($Name -eq $CurrentUILanguage) }`
                -ModuleName $($script:DSCResourceName) `
                -MockWith { Throw "Invalid Entry" } `
                -Verifiable
                Mock -CommandName Get-ItemPropertyValue `
                -ParameterFilter { ($Path -eq "registry::hkey_Users\S-1-5-18\Control Panel\Desktop\MuiCached\MachineLanguageConfiguration\") -and ($Name -eq $CurrentUILanguage) }`
                -ModuleName $($script:DSCResourceName) `
                -MockWith { Throw "Invalid Entry" } `
                -Verifiable
                Mock -CommandName Get-ItemPropertyValue `
                -ParameterFilter { ($Path -eq "registry::hkey_Users\.DEFAULT\Control Panel\Desktop\MuiCached\MachineLanguageConfiguration\") -and ($Name -eq $CurrentUILanguage) }`
                -ModuleName $($script:DSCResourceName) `
                -MockWith { Throw "Invalid Entry" } `
                -Verifiable
                $TestState = Test-TargetResource `
                    -IsSingleInstance "Yes" `
                    -LocationID $CurrentLocation `
                    -MUILanguage $CurrentUILanguage `
                    -MUIFallbackLanguage $CurrentUIFallbackLanguage `
                    -SystemLocale $CurrentSystemLocale `
                    -AddInputLanguages $CurrentInstalledLanguages `
                    -UserLocale $CurrentUserLocale `
                    -CopySystem $true `
                    -CopyNewUser $true `
                    -Verbose
                
                It 'Should not throw exception' {
                    {
                        Test-TargetResource `
                            -IsSingleInstance "Yes" `
                            -LocationID $CurrentLocation `
                            -MUILanguage $CurrentUILanguage `
                            -MUIFallbackLanguage $CurrentUIFallbackLanguage `
                            -SystemLocale $CurrentSystemLocale `
                            -AddInputLanguages $CurrentInstalledLanguages `
                            -UserLocale $CurrentUserLocale `
                            -CopySystem $true `
                            -CopyNewUser $true `
                            -Verbose
                    } | Should Not Throw
                }

                It 'All Mocks should have run'{
                    {Assert-VerifiableMocks} | should not throw
                }

                It 'Function Should return true'{
                    $TestState | Should Be $true
                }
            }
        }

        Describe "$($script:DSCResourceName)\Set-TargetResource" {
            Mock -CommandName Start-Process `
                -ModuleName $($script:DSCResourceName) `
                -Verifiable

            Context 'No Settings Specified' {
                Mock -CommandName Out-File `
                    -ModuleName $($script:DSCResourceName)
                It 'Should throw exception' {
                    {
                        Set-TargetResource `
                            -IsSingleInstance "Yes" `
                            -Verbose
                    } | Should Throw
                }
                It 'Should not call Out-File' {
                    Assert-MockCalled `
                        -CommandName Out-File `
                        -ModuleName $($script:DSCResourceName) `
                        -Exactly 0
                }

                It 'Should not call Start-Process' {
                    Assert-MockCalled `
                        -CommandName Start-Process `
                        -ModuleName $($script:DSCResourceName) `
                        -Exactly 0
                }
            }

            Context 'Change Location' {
                It 'Should not throw exception' {
                    {
                        Set-TargetResource `
                            -IsSingleInstance "Yes" `
                            -LocationID $NewLocation `
                            -MUILanguage $CurrentUILanguage `
                            -MUIFallbackLanguage $CurrentUIFallbackLanguage `
                            -SystemLocale $CurrentSystemLocale `
                            -AddInputLanguages $CurrentInstalledLanguages `
                            -UserLocale $CurrentUserLocale `
                            -CopySystem $true `
                            -CopyNewUser $true `
                            -Verbose
                    } | Should not Throw
                }
                $fileContent = Get-Content -Path "$env:TEMP\Locale.xml" | Out-String

                It 'All Mocks should have run'{
                    {Assert-VerifiableMocks} | should not throw
                }

                It 'File should have been created'{
                    Test-Path -Path "$env:TEMP\Locale.xml" | Should be $true
                }

                It 'File Content should match known good config'{
                    #Whitespace doesn't matter to the xml file so avoid pester test issues by removing it all
                    ($fileContent-eq $ValidLocationConfig) | Should be $true
                }

                #Useful when debugging XML Output
                Write-Verbose "Known File Content:" -Verbose:$true
                Write-Verbose $ValidLocationConfig -Verbose:$true
                Write-Verbose "Known File Content Length: $($ValidLocationConfig.Length)" -Verbose:$true
                Write-Verbose "Result File Content" -Verbose:$true
                Write-Verbose $fileContent -Verbose:$true
                Write-Verbose "Result File Content Length: $($fileContent.Length)" -Verbose:$true

                It 'Should call Start-Process' {
                    Assert-MockCalled `
                        -CommandName Start-Process `
                        -ModuleName $($script:DSCResourceName) `
                        -Exactly 1
                }
            }

            Context 'Remove Language' {
                                It 'Should not throw exception' {
                    {
                        Set-TargetResource `
                            -IsSingleInstance "Yes" `
                            -LocationID $NewLocation `
                            -MUILanguage $CurrentUILanguage `
                            -MUIFallbackLanguage $CurrentUIFallbackLanguage `
                            -SystemLocale $CurrentSystemLocale `
                            -RemoveInputLanguages $LanguageToRemove `
                            -UserLocale $CurrentUserLocale `
                            -CopySystem $true `
                            -CopyNewUser $true `
                            -Verbose
                    } | Should not Throw
                }
                $fileContent = Get-Content -Path "$env:TEMP\Locale.xml" | Out-String

                It 'All Mocks should have run'{
                    {Assert-VerifiableMocks} | should not throw
                }

                It 'File should have been created'{
                    Test-Path -Path "$env:TEMP\Locale.xml" | Should be $true
                }

                It 'File Content should match known good config'{
                    #Whitespace doesn't matter to the xml file so avoid pester test issues by removing it all
                    ($fileContent -eq $ValidRemovalConfig) | Should be $true
                }

                #Useful when debugging XML Output
                Write-Verbose "Known File Content" -Verbose:$true
                Write-Verbose $ValidRemovalConfig -Verbose:$true
                Write-Verbose "Result File Content" -Verbose:$true
                Write-Verbose $fileContent -Verbose:$true

                It 'Should call Start-Process' {
                    Assert-MockCalled `
                        -CommandName Start-Process `
                        -ModuleName $($script:DSCResourceName) `
                        -Exactly 1
                }
            }
        }
    }
}
finally
{
    Invoke-TestCleanup
}
