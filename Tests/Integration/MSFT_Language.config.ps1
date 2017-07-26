
# Integration Test Config Template Version: 1.0.0
configuration MSFT_Language_Config {

    Import-DscResource -ModuleName LanguageDsc
    node localhost {

        LanguagePack Integration_Test {
            IsSingleInstance "Yes" 
            LocationID 242 
            MUILanguage "en-GB" 
            MUIFallbackLanguage "en-US"
            SystemLocale "en-GB" 
            AddInputLanguages @("en-GB") 
            RemoveInputLanguages @("en-US")
            UserLocale "en-GB"
            CopySystem $true 
            CopyNewUser $true
        }
    }
}

# TODO: (Optional): Add More Configuration Templates
