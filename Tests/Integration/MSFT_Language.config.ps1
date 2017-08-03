
# Integration Test Config Template Version: 1.0.0
configuration MSFT_Language_Config {

    Import-DscResource -ModuleName LanguageDsc
    node localhost {

        Language Integration_Test {
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
}

# TODO: (Optional): Add More Configuration Templates
