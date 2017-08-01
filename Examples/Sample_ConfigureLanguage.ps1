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
        AddInputLanguages = @("en-GB") 
        RemoveInputLanguages = @("en-US")
        UserLocale = "en-GB"
        CopySystem = $true 
        CopyNewUser = $true
    }
}
