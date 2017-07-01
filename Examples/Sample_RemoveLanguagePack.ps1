#Installs the latest version of Chrome in the language specified in the parameter Language.

Configuration Sample_InstallLanguagePack
{
    
    Import-DscResource -module LanguageDsc
    
    LanguagePack removeEN-US
    {
        LanguagePackName = "en-US"
        Ensure = "Absent"
    }
}
