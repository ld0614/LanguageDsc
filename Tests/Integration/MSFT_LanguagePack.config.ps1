
# Integration Test Config Template Version: 1.0.0
configuration MSFT_LanguagePack_Config {
    Param
    (
        [Parameter(Mandatory=$true)]
        [String]
        $LangaugePackName,
        [Parameter(Mandatory=$false)]
        [String]
        $LangaugePackLocation,
        [Parameter(Mandatory=$true)]
        [ValidateSet("Present","Absent")]
        [String]
        $Ensure
    )

    Import-DscResource -ModuleName LanguageDsc
    node localhost {

        LanguagePack Integration_Test {
            LanguagePackName = $LangaugePackName
            LanguagePackLocation = $LangaugePackLocation
            Ensure = $Ensure
        }
    }
}

# TODO: (Optional): Add More Configuration Templates
