#Installs the latest version of Chrome in the language specified in the parameter Language.

Configuration Example
{

    Import-DscResource -Module LanguageDsc

    Language ConfigureLanguage {
        IsSingleInstance = "Yes" 
        LocationID = 242 
        MUILanguage = "en-GB" 
        MUIFallbackLanguage = "en-US"
        SystemLocale = "en-GB" 
        AddInputLanguages = @("0809:00000809") 
        RemoveInputLanguages = @("0409:00000409")
        UserLocale = "en-GB"
        CopySystem = $true 
        CopyNewUser = $true
    }
}
