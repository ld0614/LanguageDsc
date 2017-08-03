#Installs the latest version of Chrome in the language specified in the parameter Language.

Configuration Example
{
    
    Import-DscResource -module LanguageDsc
    
    LanguagePack removeEN-US
    {
        LanguagePackName = "en-US"
        Ensure = "Absent"
    }
}
