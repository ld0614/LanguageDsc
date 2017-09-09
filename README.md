# LanguageDSC

[![Build status](https://ci.appveyor.com/api/projects/status/wfuldlhe53v09eca/branch/master?svg=true)](https://ci.appveyor.com/project/ld0614/languagedsc/branch/master)

[![codecov](https://codecov.io/gh/ld0614/LanguageDsc/branch/master/graph/badge.svg)](https://codecov.io/gh/ld0614/LanguageDsc)

This Module is designed to manage language settings on Windows Server operating systems.  It allows for the installation and removal of language packs as well as modification of the User and System Locales, Keyboard layouts and display language.

This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/).
For more information see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/) or contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with any additional questions or comments.

## How to Contribute

If you would like to contribute to this repository, please read the DSC Resource Kit [contributing guidelines](https://github.com/PowerShell/DscResource.Kit/blob/master/CONTRIBUTING.md).

## Resources

* **Language** Configure Language Settings on Windows Operating System
* **LanguagePack** Install or remove Windows Language Pack

### Language

This resource will configure the user and system locales, display language (if already installed), keyboard layout and will copy to system and new user accounts.

* **IsSingleInstance**: Must be set to Yes, this avoids multiple Language configurations in the same configuration which would create conflicts
* **LocationID**: Decimal value of the location code to be set eg. 242.  Values can be found at: https://msdn.microsoft.com/en-us/library/windows/desktop/dd374073(v=vs.85).aspx
* **MUILanguage**: Display Language to use used eg. "en-GB"
* **MUIFallbackLanguage**: Language Pack to be used when the primary language pack isn't complete  eg. "en-US"
* **SystemLocale**:  Language name for the System Locale eg. "en-GB"
* **AddInputLanguages**: Array of all input Languages to add, these must be in the long LCID format  eg. @("0809:00000809")
* **RemoveInputLanguages**: Array of all input Languages to be removed, these must be in the long LCID format @("0409:00000409")
* **UserLocale**:  Language name for the user Locale eg. "en-GB"
* **CopySystem**: Copy the configuration to the system accounts eg. $true
* **CopyNewUser**: Copy the configuration to all new user accounts eg. $true

### LanguagePack

This resource will install or remove a single language pack from the target system.  When installing a language pack a install location must be specified.  When removing a language pack a install location is not required.  The system requires a reboot after installation or removal of a language pack.

* **LanguagePackName**: Name of the Language to be effected, eg. en-GB
* **LanguagePackLocation**: When installing a language pack the install files must be made available to the system.  This can be an UNC path accessible to the target node.
* **Ensure**: Default is Present, this will attempt to install the language pack if it is not already installed.  The other option is Absent which will attempt to remove the language pack if present.

## Versions

### 1.0.0.0

* Initial release with the following resources:
  * Language
  * LanguagePack

## How to Test
This resource is configured to exclude integration tests from its automated testing utilizing appveyor.  This is due to the external dependencies required for the langagePack Resource.  To configure a valid testing environment the following prerequisites are required:
* Windows Server Operating System with en-US language installed
* Git for Windows
* C:\LanguagePacks must exist
* en-GB (English-UK) Language Pack must be in C:\LanguagePacks
* de-DE (German) Language Pack must be in C:\LanguagePacks

These specifics can be controlled by modifying the MSFT_LanguagePack.Integration.Tests.ps1 file
