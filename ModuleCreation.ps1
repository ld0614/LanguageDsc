$LanguagePackName = New-xDscResourceProperty -Name "LanguagePackName" -Type String -Attribute Key
$LanguagePackLocation = New-xDscResourceProperty -Name "LanguagePackLocation" -Type String -Attribute Write
$Ensure = New-xDscResourceProperty –Name Ensure -Type String -Attribute Write –ValidateSet “Present”, “Absent”

$IsSingleInstance = New-xDscResourceProperty -Name "IsSingleInstance" -Type String -Attribute Key -ValidateSet “Yes”
$LocationID = New-xDscResourceProperty -Name "LocationID" -Type Sint32 -Attribute Write
$MUILanguage = New-xDscResourceProperty -Name "MUILanguage" -Type String -Attribute Write
$MUIFallbackLanguage = New-xDscResourceProperty -Name "MUIFallbackLanguage" -Type String -Attribute Write
$SystemLocale = New-xDscResourceProperty -Name "SystemLocale" -Type String -Attribute Write
$AddInputLanguages = New-xDscResourceProperty -Name "AddInputLanguages" -Type String[] -Attribute Write
$RemoveInputLanguages = New-xDscResourceProperty -Name "RemoveInputLanguages" -Type String[] -Attribute Write
$UserLocale = New-xDscResourceProperty -Name "UserLocale" -Type String -Attribute Write
$CopySystem = New-xDscResourceProperty -Name "CopySystem" -Type Boolean -Attribute Write
$CopyNewUser = New-xDscResourceProperty -Name "CopyNewUser" -Type Boolean -Attribute Write
$CurrentInstalledLanguages = New-xDscResourceProperty -Name CurrentInstalledLanguages -Type String[] -Attribute Read

New-xDscResource -Name "MSFT_LanguagePack" -FriendlyName "LanguagePack" -Property $LanguagePackName, $LanguagePackLocation, $Ensure -Path "C:\Temp\DSCResources" -ModuleName "LanguageDsc"

New-xDscResource -Name "MSFT_Language" -FriendlyName "Language" -Property $IsSingleInstance, $LocationID, $MUILanguage, $MUIFallbackLanguage, $SystemLocale, $AddInputLanguages, $RemoveInputLanguages, $UserLocale, $CopySystem, $CopyNewUser, $CurrentInstalledLanguages -Path "C:\Temp\DSCResources" -ModuleName "LanguageDsc"
