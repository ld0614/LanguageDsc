# {ModuleName}

{AppVeyor build status badge for master branch}

{ Description of the module - Please include any requirements for running all resources in this module (e.g. Must run on Windows Server OS, must have Exchange already installed) - Requirements specific to only certain resources in this module may be listed below with the description of those resources. }

This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/).
For more information see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/) or contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with any additional questions or comments.

## How to Contribute

If you would like to contribute to this repository, please read the DSC Resource Kit [contributing guidelines](https://github.com/PowerShell/DscResource.Kit/blob/master/CONTRIBUTING.md).

## Resources

* **LanguagePack** Install or remove Windows Language Pack

### {LanguagePack}

This resource will install or remove a single language pack from the target system.  When installing a language pack a install location must be specified.  When removing a language pack a install location is not required.  The system requires a reboot after installation or removal of a language pack.  

* **LanguagePackName**: Name of the Language to be effected, eg. en-GB
* **LanguagePackLocation**: When installing a language pack the install files must be made available to the system.  This can be an UNC path accessible to the target node.  
* **Ensure**: Default is Present, this will attempt to install the language pack if it is not already installed.  The other option is Absent which will attempt to remove the language pack if present.

## Versions

### 1.0.0.0

* Initial release with the following resources:
  * LanguagePack
