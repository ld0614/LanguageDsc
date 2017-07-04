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
    #Because some or all of the setting may be changed its impossible to set mandatory parameters, instead we will
    #throw an error if no settings have been defined
    $ConfigurationRequired = $false

    $LanguageSettings = @()

    $LanguageSettings += "<gs:GlobalizationServices xmlns:gs=`"urn:longhornGlobalizationUnattend`">"

    $LanguageSettings += "`t<gs:UserList>"
    $LanguageSettings += "`t`t<gs:User UserID=`"Current`" CopySettingsToDefaultUserAcct=`"$($CopyNewUser.ToString().tolower())`" CopySettingsToSystemAcct=`"$($CopySystem.ToString().tolower())`"/>"
    $LanguageSettings += "`t</gs:UserList>"

    if ($LocationID -ne "")
    {
        $ConfigurationRequired = $true

        $LanguageSettings += "`t<gs:LocationPreferences>"
        $LanguageSettings += "`t`t<gs:GeoID Value=`"$LocationID`"/>"
        $LanguageSettings += "`t</gs:LocationPreferences>"
    }

    if ($MUILanguage -ne "" -or $MUIFallbackLanguage -ne "")
    {
        $ConfigurationRequired = $true

        $LanguageSettings += "`t<gs:MUILanguagePreferences>"

        if ($MUILanguage -ne $null)
        {
            $LanguageSettings += "`t`t<gs:MUILanguage Value=`"$MUILanguage`"/>"
        }

        if ($MUIFallbackLanguage -ne $null)
        {
            $LanguageSettings += "`t`t<gs:MUIFallback Value=`"$MUIFallbackLanguage`"/>"
        }
        
        $LanguageSettings += "`t</gs:MUILanguagePreferences>"
    }

    if ($SystemLocale -ne "")
    {
        $ConfigurationRequired = $true

        $LanguageSettings += "`t<gs:SystemLocale Name=`"$SystemLocale`"/>"
    }

    if ($AddInputLanguages -ne $null -or $RemoveInputLanguages -ne $null)
    {
        $ConfigurationRequired = $true

        $LanguageSettings += "`t<gs:InputPreferences>"

        foreach ($LanguageID in $AddInputLanguages)
        {
            $LanguageSettings += "`t`t<gs:InputLanguageID Action=`"add`" ID=`"$LanguageID`"/>"
        }

        foreach ($LanguageID in $RemoveInputLanguages)
        {
            $LanguageSettings += "`t`t<gs:InputLanguageID Action=`"remove`" ID=`"$LanguageID`"/>"
        }
        
        $LanguageSettings += "`t</gs:InputPreferences>"
    }

    if ($UserLocale -ne "")
    {
        $ConfigurationRequired = $true

        $LanguageSettings += "`t<gs:UserLocale>"
        $LanguageSettings += "`t`t<gs:Locale Name=`"$UserLocale`" SetAsCurrent=`"true`" ResetAllSettings=`"true`"/>"
        $LanguageSettings += "`t</gs:UserLocale>"
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

        [ValidateNotNullOrEmpty()]
        [System.Int32]
        $LocationID,

        [ValidateNotNullOrEmpty()]
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
    Write-Verbose "Current User LocationID = $CULocationID type $($CULocationID.gettype())"

    $CUMUILanguage = Get-ItemPropertyValue "HKCU:\Control Panel\Desktop\" -Name "PreferredUILanguages"
    Write-Verbose "Current User MUILanguage = $CUMUILanguage type $($CUMUILanguage.gettype())"

    #This is value only exists if a fallback MUI language has been configured
    $CUMUIFallbackLanguage = Get-ItemPropertyValue "HKCU:\Control Panel\Desktop\LanguageConfiguration" -Name "$CUMUILanguage" -ErrorAction SilentlyContinue
    Write-Verbose "Current User MUIFallbackLanguage = $CUMUIFallbackLanguage type $($CUMUIFallbackLanguage.gettype())"

    $CUSystemLocale = Get-WinSystemLocale
    Write-Verbose "Current System Locale = $($CUSystemLocale.Name) type $($CULocationID.gettype())"

    $CULanguages = Get-ItemPropertyValue "HKCU:\Control Panel\International\User Profile" -Name "Languages"
    Write-Verbose "Currently Installed Languages = $CULanguages type $($CULanguages.gettype())"

    $CULocale = Get-ItemPropertyValue "HKCU:\Control Panel\International" -Name "LocaleName"
    Write-Verbose "Current UserLocale = $CULocale type $($CULocale.gettype())"

    $SYSLocationID = Get-ItemPropertyValue "registry::hkey_Users\S-1-5-18\Control Panel\International\Geo\" -Name "Nation"
    Write-Verbose "Current User LocationID = $SYSLocationID type $($SYSLocationID.gettype())"

    $SYSMUILanguage = Get-ItemPropertyValue "registry::hkey_Users\S-1-5-18\Control Panel\Desktop\MuiCached" -Name "MachinePreferredUILanguages"
    Write-Verbose "Current User MUILanguage = $SYSMUILanguage type $($SYSMUILanguage.gettype())"

    #This property only exists if a fallback MUI Language has been configured for a system account
    $SYSMUIFallbackLanguage = Get-ItemPropertyValue "registry::hkey_Users\S-1-5-18\Control Panel\Desktop\MuiCached\MachineLanguageConfiguration" -Name "$SYSMUILanguage" -ErrorAction SilentlyContinue
    Write-Verbose "Current User MUIFallbackLanguage = $SYSMUIFallbackLanguage type $($SYSMUIFallbackLanguage.gettype())"

    $SYSLanguages = Get-ItemPropertyValue "registry::hkey_Users\S-1-5-18\Control Panel\International\User Profile" -Name "Languages"
    Write-Verbose "Currently Installed Languages = $SYSLanguages type $($SYSLanguages.gettype())"

    $SYSLocale = Get-ItemPropertyValue "registry::hkey_Users\S-1-5-18\Control Panel\International" -Name "LocaleName"
    Write-Verbose "Current UserLocale = $SYSLocale type $($SYSLocale.gettype())"

    $NULocationID = Get-ItemPropertyValue "registry::hkey_Users\.DEFAULT\Control Panel\International\Geo\" -Name "Nation"
    Write-Verbose "Current User LocationID = $NULocationID type $($NULocationID.gettype())"

    $NUMUILanguage = Get-ItemPropertyValue "registry::hkey_Users\.DEFAULT\Control Panel\Desktop\MuiCached" -Name "MachinePreferredUILanguages"
    Write-Verbose "Current User MUILanguage = $NUMUILanguage type $($NUMUILanguage.gettype())"

    #This property only exists if a fallback MUI Language has been configured for a new user account
    $NUMUIFallbackLanguage = Get-ItemPropertyValue "registry::hkey_Users\.DEFAULT\Control Panel\Desktop\MuiCached\MachineLanguageConfiguration" -Name "$NUMUILanguage" -ErrorAction SilentlyContinue
    Write-Verbose "Current User MUIFallbackLanguage = $NUMUIFallbackLanguage type $($NUMUIFallbackLanguage.gettype())"

    $NULanguages = Get-ItemPropertyValue "registry::hkey_Users\.DEFAULT\Control Panel\International\User Profile" -Name "Languages"
    Write-Verbose "Currently Installed Languages = $NULanguages type $($NULanguages.gettype())"

    $NULocale = Get-ItemPropertyValue "registry::hkey_Users\.DEFAULT\Control Panel\International" -Name "LocaleName"
    Write-Verbose "Current UserLocale = $NULocale type $($NULocale.gettype())"

    #If LocationID requires configuration
    if ($LocationID -ne 0)
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
        Write-Verbose "Result after LocationID: $result"
    }
    else
    {
        Write-Verbose "LocationID not specified, skipping checks"
    }

    #If MUILanguage requires configuration
    if ($MUILanguage -ne "")
    {
        #Check current user
        if ($CUMUILanguage[0] -ne $MUILanguage)
        {
            $result = $false
        }

        #Check System Account if also configuring System
        if ($CopySystem -eq $true -and $SYSMUILanguage[0] -ne $MUILanguage)
        {
            $result = $false
        }

        #Check New User Account if also configuring new users
        if ($CopyNewUser -eq $true -and $NUMUILanguage[0] -ne $MUILanguage)
        {
            $result = $false
        }
        Write-Verbose "Result after MUILanguage: $result"
    }
    else
    {
        Write-Verbose "MUILanguage not specified, skipping checks"
    }

    #If MUIFallbackLanguage requires configuration
    if ($MUIFallbackLanguage -ne "")
    {
        #Check current user
        if ($CUMUIFallbackLanguage[0] -ne $MUIFallbackLanguage)
        {
            $result = $false
        }

        #Check System Account if also configuring System
        if ($CopySystem -eq $true -and $SYSMUIFallbackLanguage[0] -ne $MUIFallbackLanguage)
        {
            $result = $false
        }

        #Check New User Account if also configuring new users
        if ($CopyNewUser -eq $true -and $NUMUIFallbackLanguage[0] -ne $MUIFallbackLanguage)
        {
            $result = $false
        }
        Write-Verbose "Result after MUIFallbackLanguage: $result"
    }
    else
    {
        Write-Verbose "MUIFallbackLanguage not specified, skipping checks"
    }

    #If SystemLocale requires configuration
    if ($SystemLocale -ne "")
    {
        if ($CUSystemLocale.Name -ne $SystemLocale)
        {
            $result = $false
        }
        Write-Verbose "Result after SystemLocale: $result"
    }
    else
    {
        Write-Verbose "SystemLocale not specified, skipping checks"
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
        Write-Verbose "Result after AddInputLanguages: $result"
    }
    else
    {
        Write-Verbose "AddInputLanguages not specified, skipping checks"
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
        Write-Verbose "Result after RemoveInputLanguages: $result"
    }
    else
    {
        Write-Verbose "RemoveInputLanguages not specified, skipping checks"
    }

    #If User Locale requires configuration
    if ($UserLocale -ne "")
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
        Write-Verbose "Result after UserLocale: $result"
    }
    else
    {
        Write-Verbose "UserLocale not specified, skipping checks"
    }
    
    return $result
}


Export-ModuleMember -Function *-TargetResource

