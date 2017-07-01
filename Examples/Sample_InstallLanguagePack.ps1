#Installs the latest version of Chrome in the language specified in the parameter Language.

Configuration Sample_InstallLanguagePack
{
    
    Import-DscResource -module LanguageDsc
    
    LanguagePack en-GB
    {
        LanguagePackName = "en-GB"
        LanguagePackLocation = "\\fileserver1\LanguagePacks\"
    }

    LanguagePack de-DE
    {
        LanguagePackName = "de-DE"
        LanguagePackLocation = "\\fileserver1\LanguagePacks\de-DE.cab"
    }
}
