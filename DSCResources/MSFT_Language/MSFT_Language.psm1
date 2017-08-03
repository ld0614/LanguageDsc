
<#
    .SYNOPSIS
        Retrieves the current state of the specified Language Pack

    .PARAMETER IsSingleInstance
        Key Value to require only a single Language Resource to be run
        in a configuration to avoid configuration loops
#>
Function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    Param
    (
        [Parameter(Mandatory = $true)]
        [ValidateSet("Yes")]
        [System.String]
        $IsSingleInstance
    )

    $CULocationID = Get-ItemPropertyValue "HKCU:\Control Panel\International\Geo\" -Name "Nation"
    Write-Verbose "Current User LocationID = $CULocationID"

    #This is only set if the language has ever been changed, if to it defaults to system preferred
    try
    {
        $CUMUILanguage = Get-ItemPropertyValue "HKCU:\Control Panel\Desktop\" -Name "PreferredUILanguages"
    }
    catch
    {
        $CUMUILanguage = Get-ItemPropertyValue "HKCU:\Control Panel\Desktop\MuiCached\" -Name "MachinePreferredUILanguages"
    }
    #Assume there is only 1 active MUI installed
    [String]$CUMUILanguage = $CUMUILanguage[0]
    Write-Verbose "Current User MUILanguage = $CUMUILanguage"

    try
    {
        $CUMUIFallbackLanguage = Get-ItemPropertyValue "HKCU:\Control Panel\Desktop\LanguageConfiguration\" -Name "$CUMUILanguage" -ErrorAction Stop
        [String]$CUMUIFallbackLanguage = $CUMUIFallbackLanguage[0]
        Write-Verbose "Current User MUIFallbackLanguage = $CUMUIFallbackLanguage"
    }
    catch
    {
        Write-Verbose "Current User does not have a fallback language"
    }

    $SystemLocale = Get-WinSystemLocale
    Write-Verbose "Current System Locale = $($SystemLocale.Name)"

    $CULanguages = Get-ItemPropertyValue "HKCU:\Control Panel\International\User Profile\" -Name "Languages"
    Write-Verbose "Currently Installed Languages = $CULanguages"
    
    #RegEX taken from implementation error output
    $RegEx = '[0-9a-fA-F]{4}:[0-9a-fA-F]{8}|[0-9a-fA-F]{4}:\{[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}\}\{[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}\}'
    $ReturnLanguage = @{}

    foreach ($Language in $CULanguages)
    {
        $LanguageProperties = Get-ItemProperty -Path "HKCU:\Control Panel\International\User Profile\$Language\" -ErrorAction Continue
        Write-Verbose "LanguageProperties = $LanguageProperties"
        $LanguageCodeObj = $LanguageProperties | Get-Member -MemberType NoteProperty | Where-Object {$_.Name -Match $RegEx} -ErrorAction Continue
        $LanguageCode = $LanguageCodeObj.Name
        if ($null -ne $LanguageCode)
        {
            Write-Verbose "Language Code is: $LanguageCode"
            $ReturnLanguage += @{$Language=$LanguageCode}
        }
    }

    $CULocale = Get-ItemPropertyValue "HKCU:\Control Panel\International" -Name "LocaleName"
    Write-Verbose "Current UserLocale = $CULocale"

    $returnValue = @{
    IsSingleInstance = 'Yes'
    LocationID = [System.Int32]$CULocationID
    MUILanguage = [System.String]$CUMUILanguage
    MUIFallbackLanguage = [System.String]$CUMUIFallbackLanguage
    SystemLocale = [System.String]$SystemLocale.Name
    CurrentInstalledLanguages = [Hashtable]$ReturnLanguage
    UserLocale = [System.String]$CULocale
    }

    $returnValue
}

<#
    .SYNOPSIS
        Sets the configuration for all specified settings

    .PARAMETER IsSingleInstance
        Key Value to require only a single Language Resource to be run
        in a configuration to avoid configuration loops
    
    .PARAMETER LocationID
        Integer specifying the country location code, this can be found
        https://msdn.microsoft.com/en-us/library/windows/desktop/dd374073(v=vs.85).aspx

    .PARAMETER MUILanguage
        User Interface language, should be in the format en-GB

    .PARAMETER MUIFallbackLanguage
        User Interface language to be used when the primary does not cover the
        required settings, should be in the format en-GB

    .PARAMETER SystemLocale
        The Language used for the system locale, should be in the format en-GB

    .PARAMETER AddInputLanguages
        Array Specifying the keyboard input languages to be added to the available list

    .PARAMETER RemoveInputLanguages
        Array specifying the keyboard input languages to be removed from the available list
    
    .PARAMETER UserLocale
        The Language used for the user locale, should be in the format en-GB

    .PARAMETER CopySystem
        Boolean value to copy all settings to the system accounts, the default is true.

    .PARAMETER CopyNewUser
        Boolean value to copy all settings for new user accounts, the default is true.
#>
Function Set-TargetResource
{
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidGlobalVars", "global:DSCMachineStatus")]
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory = $true)]
        [ValidateSet("Yes")]
        [System.String]
        $IsSingleInstance,

        [Parameter(Mandatory = $false)]
        [System.Int32]
        $LocationID,

        [Parameter(Mandatory = $false)]
        [System.String]
        $MUILanguage,

        [Parameter(Mandatory = $false)]
        [System.String]
        $MUIFallbackLanguage,

        [Parameter(Mandatory = $false)]
        [System.String]
        $SystemLocale,

        [Parameter(Mandatory = $false)]
        [System.String[]]
        $AddInputLanguages,

        [Parameter(Mandatory = $false)]
        [System.String[]]
        $RemoveInputLanguages,

        [Parameter(Mandatory = $false)]
        [System.String]
        $UserLocale,

        [Parameter(Mandatory = $false)]
        [System.Boolean]
        $CopySystem =$true,

        [Parameter(Mandatory = $false)]
        [System.Boolean]
        $CopyNewUser=$true
    )
    #Because some or all of the setting may be changed its impossible to set mandatory parameters, instead we will
    #throw an error if no settings have been defined
    $ConfigurationRequired = $false

    $LanguageSettings = @()

    $LanguageSettings += "<gs:GlobalizationServices xmlns:gs=`"urn:longhornGlobalizationUnattend`">"

    $LanguageSettings += "    <gs:UserList>"
    $LanguageSettings += "        <gs:User UserID=`"Current`" CopySettingsToDefaultUserAcct=`"$($CopyNewUser.ToString().tolower())`" CopySettingsToSystemAcct=`"$($CopySystem.ToString().tolower())`"/>"
    $LanguageSettings += "    </gs:UserList>"

    if ($LocationID -ne "")
    {
        $ConfigurationRequired = $true

        $LanguageSettings += "    <gs:LocationPreferences>"
        $LanguageSettings += "        <gs:GeoID Value=`"$LocationID`"/>"
        $LanguageSettings += "    </gs:LocationPreferences>"
    }
    else
    {
        Write-Verbose "LocationID configuration not required"
    }

    if ($MUILanguage -ne "" -or $MUIFallbackLanguage -ne "")
    {
        $ConfigurationRequired = $true

        $LanguageSettings += "    <gs:MUILanguagePreferences>"

        if ($MUILanguage -ne "")
        {
            $LanguageSettings += "        <gs:MUILanguage Value=`"$MUILanguage`"/>"
        }

        if ($MUIFallbackLanguage -ne "")
        {
            $LanguageSettings += "        <gs:MUIFallback Value=`"$MUIFallbackLanguage`"/>"
        }
        
        $LanguageSettings += "    </gs:MUILanguagePreferences>"
    }
    else
    {
        Write-Verbose "MUILanguage and MUIFallbackLanguage configuration not required"
    }

    if ($SystemLocale -ne "")
    {
        $ConfigurationRequired = $true

        $LanguageSettings += "    <gs:SystemLocale Name=`"$SystemLocale`"/>"
    }
    else
    {
        Write-Verbose "SystemLocale configuration not required"
    }

    if ($null -ne $AddInputLanguages -or $null -ne $RemoveInputLanguages)
    {
        #RegEX taken from implementation error output
        $RegEx = '[0-9a-fA-F]{4}:[0-9a-fA-F]{8}|[0-9a-fA-F]{4}:\{[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}\}\{[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}\}'
        $ConfigurationRequired = $true

        $LanguageSettings += "    <gs:InputPreferences>"

        foreach ($LanguageID in $AddInputLanguages)
        {
            if ($LanguageID -notmatch $RegEx)
            {
                Throw "Invalid Keyboard code.  Code must be in the format $RegEx"
            }

            $LanguageSettings += "        <gs:InputLanguageID Action=`"add`" ID=`"$LanguageID`"/>"
        }

        foreach ($LanguageID in $RemoveInputLanguages)
        {
            if ($LanguageID -notmatch $RegEx)
            {
                Throw "Invalid Keyboard code.  Code must be in the format $RegEx"
            }

            $LanguageSettings += "        <gs:InputLanguageID Action=`"remove`" ID=`"$LanguageID`"/>"
        }
        
        $LanguageSettings += "    </gs:InputPreferences>"
    }
    else
    {
        Write-Verbose "Keyboard Layout configuration not required"
    }

    if ($UserLocale -ne "")
    {
        $ConfigurationRequired = $true

        $LanguageSettings += "    <gs:UserLocale>"
        $LanguageSettings += "        <gs:Locale Name=`"$UserLocale`" SetAsCurrent=`"true`" ResetAllSettings=`"true`"/>"
        $LanguageSettings += "    </gs:UserLocale>"
    }
    else
    {
        Write-Verbose "UserLocale configuration not required"
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
        Throw "Nothing to do as no parameters where specified"
    }
}

<#
    .SYNOPSIS
        Tests the configuration for all specified settings

    .PARAMETER IsSingleInstance
        Key Value to require only a single Language Resource to be run
        in a configuration to avoid configuration loops
    
    .PARAMETER LocationID
        Integer specifying the country location code, this can be found
        https://msdn.microsoft.com/en-us/library/windows/desktop/dd374073(v=vs.85).aspx

    .PARAMETER MUILanguage
        User Interface language, should be in the format en-GB

    .PARAMETER MUIFallbackLanguage
        User Interface language to be used when the primary does not cover the
        required settings, should be in the format en-GB

    .PARAMETER SystemLocale
        The Language used for the system locale, should be in the format en-GB

    .PARAMETER AddInputLanguages
        Array Specifying the keyboard input languages to be added to the available list

    .PARAMETER RemoveInputLanguages
        Array specifying the keyboard input languages to be removed from the available list
    
    .PARAMETER UserLocale
        The Language used for the user locale, should be in the format en-GB

    .PARAMETER CopySystem
        Boolean value to copy all settings to the system accounts, the default is true.

    .PARAMETER CopyNewUser
        Boolean value to copy all settings for new user accounts, the default is true.
#>
Function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    Param
    (
        [Parameter(Mandatory = $true)]
        [ValidateSet("Yes")]
        [System.String]
        $IsSingleInstance,

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [System.Int32]
        $LocationID,

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $MUILanguage,

        [Parameter(Mandatory = $false)]
        [System.String]
        $MUIFallbackLanguage,

        [Parameter(Mandatory = $false)]
        [System.String]
        $SystemLocale,

        [Parameter(Mandatory = $false)]
        [System.String[]]
        $AddInputLanguages,

        [Parameter(Mandatory = $false)]
        [System.String[]]
        $RemoveInputLanguages,

        [Parameter(Mandatory = $false)]
        [System.String]
        $UserLocale,

        [Parameter(Mandatory = $false)]
        [System.Boolean]
        $CopySystem,

        [Parameter(Mandatory = $false)]
        [System.Boolean]
        $CopyNewUser
    )
    #RegEX taken from implementation error output
    $RegEx = '[0-9a-fA-F]{4}:[0-9a-fA-F]{8}|[0-9a-fA-F]{4}:\{[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}\}\{[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}\}'

    $result = $true

    if ($null -ne $AddInputLanguages)
    {
        #ensure that keyboard layouts are in the required format
        foreach ($LanguageID in $AddInputLanguages)
        {
            if ($LanguageID -notmatch $RegEx)
            {
                Throw "Invalid Keyboard code.  Code must be in the format $RegEx"
            }
        }
    }

    if ($null -ne $RemoveInputLanguages)
    {
        #ensure that keyboard layouts are in the required format
        foreach ($LanguageID in $RemoveInputLanguages)
        {
            if ($LanguageID -notmatch $RegEx)
            {
                Throw "Invalid Keyboard code.  Code must be in the format $RegEx"
            }
        }
    }

    $CULocationID = Get-ItemPropertyValue "HKCU:\Control Panel\International\Geo\" -Name "Nation"
    Write-Verbose "Current User LocationID = $CULocationID type $($CULocationID.gettype())"

    #This is only set if the language has ever been changed, if to it defaults to system preferred
    try
    {
        $CUMUILanguage = Get-ItemPropertyValue "HKCU:\Control Panel\Desktop\" -Name "PreferredUILanguages"
    }
    catch
    {
        $CUMUILanguage = Get-ItemPropertyValue "HKCU:\Control Panel\Desktop\MuiCached\" -Name "MachinePreferredUILanguages"
    }
    #Assume there is only 1 active MUI installed
    [String]$CUMUILanguage = $CUMUILanguage[0]
    Write-Verbose "Current User MUILanguage = $CUMUILanguage type $($CUMUILanguage.gettype())"

    #This is value only exists if a fallback MUI language has been configured
    try
    {
        $CUMUIFallbackLanguage = Get-ItemPropertyValue "HKCU:\Control Panel\Desktop\LanguageConfiguration\" -Name "$CUMUILanguage" -ErrorAction Stop
        #Assume there is only 1 active MUI installed
        [String]$CUMUIFallbackLanguage = $CUMUIFallbackLanguage[0]
        Write-Verbose "Current User MUIFallbackLanguage = $CUMUIFallbackLanguage  type $($CUMUIFallbackLanguage.gettype())"
    }
    catch
    {
        Write-Verbose "Current User does not have a fallback language"
    }

    $CUSystemLocale = Get-WinSystemLocale
    Write-Verbose "Current System Locale = $($CUSystemLocale.Name) type $($CULocationID.gettype())"

    $CULanguages = Get-ItemPropertyValue "HKCU:\Control Panel\International\User Profile\" -Name "Languages"
    Write-Verbose "Currently Installed Languages = $CULanguages type $($CULanguages.gettype())"

    [String[]]$CULanguageCodeList = @()

    foreach ($Language in $CULanguages)
    {
        $LanguageProperties = Get-ItemProperty "HKCU:\Control Panel\International\User Profile\$Language\" -ErrorAction Stop
        $LanguageCodeObj = $LanguageProperties | Get-Member -MemberType NoteProperty | Where-Object {$_.Name -Match $RegEx} -ErrorAction Stop
        $LanguageCode = $LanguageCodeObj.Name
        if ($null -ne $LanguageCode)
        {
            $CULanguageCodeList += $LanguageCode
        }
    }

    $CULocale = Get-ItemPropertyValue "HKCU:\Control Panel\International\" -Name "LocaleName"
    Write-Verbose "Current UserLocale = $CULocale type $($CULocale.gettype())"

    $SYSLocationID = Get-ItemPropertyValue "registry::hkey_Users\S-1-5-18\Control Panel\International\Geo\" -Name "Nation"
    Write-Verbose "System User LocationID = $SYSLocationID type $($SYSLocationID.gettype())"

    $SYSMUILanguage = Get-ItemPropertyValue "registry::hkey_Users\S-1-5-18\Control Panel\Desktop\MuiCached\" -Name "MachinePreferredUILanguages"
    [String]$SYSMUILanguage = $SYSMUILanguage[0]
    Write-Verbose "System User MUILanguage = $SYSMUILanguage type $($SYSMUILanguage.gettype())"

    #This property only exists if a fallback MUI Language has been configured for a system account
    try
    {
        $SYSMUIFallbackLanguage = Get-ItemPropertyValue "registry::hkey_Users\S-1-5-18\Control Panel\Desktop\MuiCached\MachineLanguageConfiguration\" -Name "$SYSMUILanguage" -ErrorAction Stop
        Write-Verbose "System User MUIFallbackLanguage = $SYSMUIFallbackLanguage type $($SYSMUIFallbackLanguage.gettype())"
    }
    catch
    {
        Write-Verbose "System User does not have a fallback language"
    }

    $SYSLanguages = Get-ItemPropertyValue "registry::hkey_Users\S-1-5-18\Control Panel\International\User Profile\" -Name "Languages"
    Write-Verbose "System Currently Installed Languages = $SYSLanguages type $($SYSLanguages.gettype())"

    [String[]]$SYSLanguageCodeList = @()

    foreach ($Language in $SYSLanguages)
    {
        $LanguageProperties = Get-ItemProperty "registry::hkey_Users\S-1-5-18\Control Panel\International\User Profile\$Language\" -ErrorAction Stop
        $LanguageCodeObj = $LanguageProperties | Get-Member -MemberType NoteProperty | Where-Object {$_.Name -Match $RegEx} -ErrorAction Stop
        $LanguageCode = $LanguageCodeObj.Name
        if ($nulll -ne $LanguageCode)
        {
            $SYSLanguageCodeList += $LanguageCode
        }
    }

    $SYSLocale = Get-ItemPropertyValue "registry::hkey_Users\S-1-5-18\Control Panel\International\" -Name "LocaleName"
    Write-Verbose "System UserLocale = $SYSLocale type $($SYSLocale.gettype())"

    $NULocationID = Get-ItemPropertyValue "registry::hkey_Users\.DEFAULT\Control Panel\International\Geo\" -Name "Nation"
    Write-Verbose "New User LocationID = $NULocationID type $($NULocationID.gettype())"

    $NUMUILanguage = Get-ItemPropertyValue "registry::hkey_Users\.DEFAULT\Control Panel\Desktop\MuiCached\" -Name "MachinePreferredUILanguages"
    [String]$NUMUILanguage = $NUMUILanguage[0]
    Write-Verbose "New User MUILanguage = $NUMUILanguage type $($NUMUILanguage.gettype())"

    #This property only exists if a fallback MUI Language has been configured for a new user account
    try
    {
        $NUMUIFallbackLanguage = Get-ItemPropertyValue "registry::hkey_Users\.DEFAULT\Control Panel\Desktop\MuiCached\MachineLanguageConfiguration\" -Name "$NUMUILanguage" -ErrorAction Stop
        Write-Verbose "New User MUIFallbackLanguage = $NUMUIFallbackLanguage type $($NUMUIFallbackLanguage.gettype())"
    }
    catch
    {
        Write-Verbose "New User does not have a fallback language"
    }

    $NULanguages = Get-ItemPropertyValue "registry::hkey_Users\.DEFAULT\Control Panel\International\User Profile\" -Name "Languages"
    Write-Verbose "New Installed Languages = $NULanguages type $($NULanguages.gettype())"

    [String[]]$NULanguageCodeList = @()

    foreach ($Language in $NULanguages)
    {
        $LanguageProperties = Get-ItemProperty "registry::hkey_Users\.DEFAULT\Control Panel\International\User Profile\$Language\" -ErrorAction Stop
        $LanguageCodeObj = $LanguageProperties | Get-Member -MemberType NoteProperty | Where-Object {$_.Name -Match $RegEx} -ErrorAction Stop
        $LanguageCode = $LanguageCodeObj.Name
        if ($null -ne $LanguageCode)
        {
            $NULanguageCodeList += $LanguageCode
        }
    }

    $NULocale = Get-ItemPropertyValue "registry::hkey_Users\.DEFAULT\Control Panel\International\" -Name "LocaleName"
    Write-Verbose "New UserLocale = $NULocale type $($NULocale.gettype())"

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
        if ($CUMUILanguage -ne $MUILanguage)
        {
            $result = $false
            Write-Verbose "New MUILanguage: $MUILanguage"
            Write-Verbose "New CUMUILanguage: $CUMUILanguage"
            Write-Verbose "MUILanguage Current User requires update"
        }

        #Check System Account if also configuring System
        if ($CopySystem -eq $true -and $SYSMUILanguage -ne $MUILanguage)
        {
            $result = $false
            Write-Verbose "MUILanguage System User requires update"
        }

        #Check New User Account if also configuring new users
        if ($CopyNewUser -eq $true -and $NUMUILanguage -ne $MUILanguage)
        {
            $result = $false
            Write-Verbose "MUILanguage New User requires update"
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
        if ($null -ne $CUMUIFallbackLanguage)
        {
            if ($CUMUIFallbackLanguage -ne $MUIFallbackLanguage)
            {
                $result = $false
                Write-Verbose "New MUIFallbackLanguage: $MUIFallbackLanguage"
                Write-Verbose "New CUMUIFallbackLanguage: $CUMUIFallbackLanguage"
                Write-Verbose "MUIFallbackLanguage Current User requires update"
            }
        }

        #Check System Account if also configuring System
        if ($null -ne $SYSMUIFallbackLanguage)
        {
            if ($CopySystem -eq $true -and $SYSMUIFallbackLanguage -ne $MUIFallbackLanguage)
            {
                $result = $false
                Write-Verbose "MUIFallbackLanguage System User requires update"
            }
        }

        #Check New User Account if also configuring new users
        if ($null -ne $NUMUIFallbackLanguage)
        {
            if ($CopyNewUser -eq $true -and $NUMUIFallbackLanguage -ne $MUIFallbackLanguage)
            {
                $result = $false
                Write-Verbose "MUIFallbackLanguage New User requires update"
            }
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

    if ($null -ne $AddInputLanguages)
    {
        #Loop through all languages which need to be on the system
        foreach($language in $AddInputLanguages)
        {
            #check if they are already on the system for the current user
            if ($CULanguageCodeList -notcontains $language)
            {
                $result = $false
                Write-Verbose "AddInputLanguages Current User requires update"
            }

            #Check System Account if also adding Languages
            if ($CopySystem -eq $true -and $SYSLanguageCodeList -notcontains $language)
            {
                $result = $false
            }

            #Check New User Account if also adding Languages
            if ($CopyNewUser -eq $true -and $NULanguageCodeList -notcontains $language)
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

    if ($null -ne $RemoveInputLanguages)
    {
        foreach($language in $RemoveInputLanguages)
        {
            if ($CULanguageCodeList -contains $language)
            {
                $result = $false
            }

            #Check System Account if also configuring System
            if ($CopySystem -eq $true -and $SYSLanguageCodeList -contains $language)
            {
                $result = $false
            }

            #Check New User Account if also configuring new users
            if ($CopyNewUser -eq $true -and $NULanguageCodeList -contains $language)
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
