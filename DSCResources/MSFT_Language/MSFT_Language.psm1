function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory = $true)]
        [ValidateSet("Yes")]
        [System.String]
        $IsSingleInstance
    )

    $CULocationID = Get-ItemPropertyValue "HKCU:\Control Panel\International\Geo\" -Name "Nation"
    Write-Verbose "Current User LocationID = $CULocationID"

    $CUMUILanguage = Get-ItemPropertyValue "HKCU:\Control Panel\Desktop\" -Name "PreferredUILanguages"
    Write-Verbose "Current User MUILanguage = $CUMUILanguage"

    $CUMUIFallbackLanguage = Get-ItemPropertyValue "HKCU:\Control Panel\Desktop\LanguageConfiguration" -Name "$CUMUILanguage"
    Write-Verbose "Current User MUIFallbackLanguage = $CUMUIFallbackLanguage"

    $SystemLocale = Get-WinSystemLocale
    Write-Verbose "Current System Locale = $SystemLocale"

    $CULanguages = Get-ItemPropertyValue "HKCU:\Control Panel\International\User Profile" -Name "Languages"
    Write-Verbose "Currently Installed Languages = $CULanguages"

    $CULocale = Get-ItemPropertyValue "HKCU:\Control Panel\International" -Name "LocaleName"
    Write-Verbose "Current UserLocale = $CULocale"

    $returnValue = @{
    IsSingleInstance = 'Yes'
    LocationID = [System.Int32]$CULocationID
    MUILanguage = [System.String]$CUMUILanguage
    MUIFallbackLanguage = [System.String]$CUMUIFallbackLanguage
    SystemLocale = [System.String]$SystemLocale
    CurrentInstalledLanguages = [System.String[]]$CULanguages
    UserLocale = [System.String]$CULocale
    }

    $returnValue
}


function Set-TargetResource
{
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidGlobalVars", "global:DSCMachineStatus")]
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory = $true)]
        [ValidateSet("Yes")]
        [System.String]
        $IsSingleInstance,

        [System.Int32]
        $LocationID,

        [System.String]
        $MUILanguage,

        [System.String]
        $MUIFallbackLanguage,

        [System.String]
        $SystemLocale,

        [System.String[]]
        $AddInputLanguages,

        [System.String[]]
        $RemoveInputLanguages,

        [System.String]
        $UserLocale,

        [System.Boolean]
        $CopySystem =$true,

        [System.Boolean]
        $CopyNewUser=$true
    )
    #Because some or all of the setting may be changed its imporssible to set mandetory parameters, instead we will
    #throw an error if no settings have been defined
    $ConfigurationRequired = $false

    $LanguageSettings = @()

    $LanguageSettings += "<gs:GlobalizationServices xmlns:gs=`"urn:longhornGlobalizationUnattend`">"

    $LanguageSettings += "<gs:UserList>"
    $LanguageSettings += "<gs:User UserID=`"Current`" CopySettingsToDefaultUserAcct=`"$($CopyNewUser.ToString().tolower())`" CopySettingsToSystemAcct=`"$($CopySystem.ToString().tolower())`"/>"
    $LanguageSettings += "</gs:UserList>"

    if ($LocationID -ne $null)
    {
        $ConfigurationRequired = $true

        $LanguageSettings += "<gs:LocationPreferences>"
        $LanguageSettings += "<gs:GeoID Value=`"$LocationID`"/>"
        $LanguageSettings += "</gs:LocationPreferences>"
    }

    if ($MUILanguage -ne $null -or $MUIFallbackLanguage -ne $null)
    {
        $ConfigurationRequired = $true

        $LanguageSettings += "<gs:MUILanguagePreferences>"

        if ($MUILanguage -ne $null)
        {
            $LanguageSettings += "<gs:MUILanguage Value=`"$MUILanguage`"/>"
        }

        if ($MUIFallbackLanguage -ne $null)
        {
            $LanguageSettings += "<gs:MUIFallback Value=`"$MUIFallbackLanguage`"/>"
        }
        
        $LanguageSettings += "</gs:MUILanguagePreferences>"
    }

    if ($SystemLocale -ne $null)
    {
        $ConfigurationRequired = $true

        $LanguageSettings += "<gs:SystemLocale Name=`"$SystemLocale`"/>"
    }

    if ($AddInputLanguages -ne $null -or $RemoveInputLanguages -ne $null)
    {
        $ConfigurationRequired = $true

        $LanguageSettings += "<gs:InputPreferences>"

        foreach ($LanguageID in $AddInputLanguages)
        {
            $LanguageSettings += "<gs:InputLanguageID Action=`"add`" ID=`"$LanguageID`"/>"
        }

        foreach ($LanguageID in $RemoveInputLanguages)
        {
            $LanguageSettings += "<gs:InputLanguageID Action=`"remove`" ID=`"$LanguageID`"/>"
        }
        
        $LanguageSettings += "</gs:InputPreferences>"
    }

    if ($UserLocale -ne $null)
    {
        $ConfigurationRequired = $true

        $LanguageSettings += "<gs:UserLocale>"
        $LanguageSettings += "<gs:Locale Name=`"$UserLocale`" SetAsCurrent=`"true`" ResetAllSettings=`"true`"/>"
        $LanguageSettings += "</gs:UserLocale>"
    }

    $LanguageSettings +=  "</gs:GlobalizationServices>"

    Write-Verbose "Created XML is:"
    $LanguageSettings | Write-Verbose

    if ($ConfigurationRequired)
    {
        #configuration command can't take a xml object, it must load the file from the filesystem
        Out-File -InputObject $LanguageSettings -FilePath "$env:TEMP\Locale.xml" -Force -Encoding ascii
        
        $arg = "intl.cpl,, /f:`"$env:TEMP\Locale.xml`""
        Start-Process -FilePath control.exe -ArgumentList $arg

        $global:DSCMachineStatus = 1
    }
    else
    {
        throw "Nothing to do as no parameters where specified"
    }
}


function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [parameter(Mandatory = $true)]
        [ValidateSet("Yes")]
        [System.String]
        $IsSingleInstance,

        [System.Int32]
        $LocationID,

        [System.String]
        $MUILanguage,

        [System.String]
        $MUIFallbackLanguage,

        [System.String]
        $SystemLocale,

        [System.String[]]
        $AddInputLanguages,

        [System.String[]]
        $RemoveInputLanguages,

        [System.String]
        $UserLocale,

        [System.Boolean]
        $CopySystem,

        [System.Boolean]
        $CopyNewUser
    )

    $result = $true

    $CULocationID = Get-ItemPropertyValue "HKCU:\Control Panel\International\Geo\" -Name "Nation"
    Write-Verbose "Current User LocationID = $CULocationID"

    $CUMUILanguage = Get-ItemPropertyValue "HKCU:\Control Panel\Desktop\" -Name "PreferredUILanguages"
    Write-Verbose "Current User MUILanguage = $CUMUILanguage"

    #This is value only exists if a fallback MUI llanguage has been configured
    $CUMUIFallbackLanguage = Get-ItemPropertyValue "HKCU:\Control Panel\Desktop\LanguageConfiguration" -Name "$CUMUILanguage" -ErrorAction SilentlyContinue
    Write-Verbose "Current User MUIFallbackLanguage = $CUMUIFallbackLanguage"

    $CUSystemLocale = Get-WinSystemLocale
    Write-Verbose "Current System Locale = $($SystemLocale.Name)"

    $CULanguages = Get-ItemPropertyValue "HKCU:\Control Panel\International\User Profile" -Name "Languages"
    Write-Verbose "Currently Installed Languages = $CULanguages"

    $CULocale = Get-ItemPropertyValue "HKCU:\Control Panel\International" -Name "LocaleName"
    Write-Verbose "Current UserLocale = $CULocale"

    $SYSLocationID = Get-ItemPropertyValue "registry::hkey_Users\S-1-5-18\Control Panel\International\Geo\" -Name "Nation"
    Write-Verbose "Current User LocationID = $SYSLocationID"

    $SYSMUILanguage = Get-ItemPropertyValue "registry::hkey_Users\S-1-5-18\Control Panel\Desktop\MuiCached" -Name "MachinePreferredUILanguages"
    Write-Verbose "Current User MUILanguage = $SYSMUILanguage"

    #This property only exists if a fallback MUI Language has been configured for a system account
    $SYSMUIFallbackLanguage = Get-ItemPropertyValue "registry::hkey_Users\S-1-5-18\Control Panel\Desktop\MuiCached\MachineLanguageConfiguration" -Name "$SYSMUILanguage" -ErrorAction SilentlyContinue
    Write-Verbose "Current User MUIFallbackLanguage = $SYSMUIFallbackLanguage"

    $SYSLanguages = Get-ItemPropertyValue "registry::hkey_Users\S-1-5-18\Control Panel\International\User Profile" -Name "Languages"
    Write-Verbose "Currently Installed Languages = $SYSLanguages"

    $SYSLocale = Get-ItemPropertyValue "registry::hkey_Users\S-1-5-18\Control Panel\International" -Name "LocaleName"
    Write-Verbose "Current UserLocale = $SYSLocale"

    $NULocationID = Get-ItemPropertyValue "registry::hkey_Users\.DEFAULT\Control Panel\International\Geo\" -Name "Nation"
    Write-Verbose "Current User LocationID = $NULocationID"

    $NUMUILanguage = Get-ItemPropertyValue "registry::hkey_Users\.DEFAULT\Control Panel\Desktop\MuiCached" -Name "MachinePreferredUILanguages"
    Write-Verbose "Current User MUILanguage = $NUMUILanguage"

    #This property only exists if a fallback MUI Language has been configured for a new user account
    $NUMUIFallbackLanguage = Get-ItemPropertyValue "registry::hkey_Users\.DEFAULT\Control Panel\Desktop\MuiCached\MachineLanguageConfiguration" -Name "$NUMUILanguage" -ErrorAction SilentlyContinue
    Write-Verbose "Current User MUIFallbackLanguage = $NUMUIFallbackLanguage"

    $NULanguages = Get-ItemPropertyValue "registry::hkey_Users\.DEFAULT\Control Panel\International\User Profile" -Name "Languages"
    Write-Verbose "Currently Installed Languages = $NULanguages"

    $NULocale = Get-ItemPropertyValue "registry::hkey_Users\.DEFAULT\Control Panel\International" -Name "LocaleName"
    Write-Verbose "Current UserLocale = $NULocale"

    #If LocationID requires configuation
    if ($LocationID -ne $null)
    {
        #Check current user
        if ($CULocationID -ne $LocationID)
        {
            $result = $false
        }

        #Check System Account if also configuring System
        if ($CopySystem -eq $true -and $SYSLocationID -ne $LocationID)
        {
            $result = $false
        }

        #Check New User Account if also configuring new users
        if ($CopyNewUser -eq $true -and $NULocationID -ne $LocationID)
        {
            $result = $false
        }
    }

    #If MUILanguage requires configuation
    if ($MUILanguage -ne $null)
    {
        #Check current user
        if ($CUMUILanguage -ne $MUILanguage)
        {
            $result = $false
        }

        #Check System Account if also configuring System
        if ($CopySystem -eq $true -and $SYSMUILanguage -ne $MUILanguage)
        {
            $result = $false
        }

        #Check New User Account if also configuring new users
        if ($CopyNewUser -eq $true -and $NUMUILanguage -ne $MUILanguage)
        {
            $result = $false
        }
    }

    #If MUILanguage requires configuation
    if ($MUIFallbackLanguage -ne $null)
    {
        #Check current user
        if ($CUMUILanguage -ne $MUIFallbackLanguage)
        {
            $result = $false
        }

        #Check System Account if also configuring System
        if ($CopySystem -eq $true -and $SYSMUIFallbackLanguage -ne $MUIFallbackLanguage)
        {
            $result = $false
        }

        #Check New User Account if also configuring new users
        if ($CopyNewUser -eq $true -and $NUMUIFallbackLanguage -ne $MUIFallbackLanguage)
        {
            $result = $false
        }
    }

    #If SystemLocale requires configuation
    if ($SystemLocale -ne $null)
    {
        if ($CUSystemLocale -ne $SystemLocale.Name)
        {
            $result = $false
        }
    }

    if ($AddInputLanguages -ne $null)
    {
        #Loop through all languages which need to be on the system
        foreach($language in $AddInputLanguages)
        {
            #check if they are already on the system for the current user
            if ($CULanguages -notcontains $language)
            {
                $result = $false
            }

            #Check System Account if also adding Languages
            if ($CopySystem -eq $true -and $SYSLanguages -notcontains $language)
            {
                $result = $false
            }

            #Check New User Account if also adding Languages
            if ($CopyNewUser -eq $true -and $NULanguages -notcontains $language)
            {
                $result = $false
            }
        }
    }

    if ($RemoveInputLanguages -ne $null)
    {
        foreach($language in $RemoveInputLanguages)
        {
            if ($CULanguages -contains $language)
            {
                $result = $false
            }

            #Check System Account if also configuring System
            if ($CopySystem -eq $true -and $SYSLanguages -contains $language)
            {
                $result = $false
            }

            #Check New User Account if also configuring new users
            if ($CopyNewUser -eq $true -and $NULanguages -contains $language)
            {
                $result = $false
            }
        }
    }

    #If User Locale requires configuation
    if ($UserLocale -ne $null)
    {
        #Check current user
        if ($CULocale -ne $UserLocale)
        {
            $result = $false
        }

        #Check System Account if also configuring System
        if ($CopySystem -eq $true -and $SYSLocale -ne $UserLocale)
        {
            $result = $false
        }

        #Check New User Account if also configuring new users
        if ($CopyNewUser -eq $true -and $NULocale -ne $UserLocale)
        {
            $result = $false
        }
    }
    
    return $result
}


Export-ModuleMember -Function *-TargetResource

