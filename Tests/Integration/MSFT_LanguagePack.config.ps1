
# Integration Test Config Template Version: 1.0.0
configuration MSFT_LanguagePack_Config {

    Import-DscResource -ModuleName LanguageDsc
    node localhost {

        LanguagePack Integration_Test {
            LanguagePackName = "en-GB"
            LanguagePackLocation = "\\SRV1\LanguagePacks\"
            Ensure = "Present"
        }
    }
}

# TODO: (Optional): Add More Configuration Templates
