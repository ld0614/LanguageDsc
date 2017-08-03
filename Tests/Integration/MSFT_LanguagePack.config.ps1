
# Integration Test Config Template Version: 1.0.0
configuration MSFT_LanguagePack_Config {

    Import-DscResource -ModuleName LanguageDsc
    node localhost {

        LanguagePack Integration_Test {
            LanguagePackName = "De-DE"
            LanguagePackLocation = "C:\Temp\x64fre_Server_de-de_lp.cab"
            Ensure = "Present"
        }
    }
}

# TODO: (Optional): Add More Configuration Templates
