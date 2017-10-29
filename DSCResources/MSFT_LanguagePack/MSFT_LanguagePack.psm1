
<#
    .SYNOPSIS
        Retrieves the current state of the specified Language Pack

    .PARAMETER LanguagePackName
        The short code for the language to be tested.  ie en-GB
    
    .PARAMETER LanguagePackLocation
        Not used in Get-TargetResource.

    .PARAMETER Ensure
        Not used in Get-TargetResource.
#>
Function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    Param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $LanguagePackName
    )

    $InstalledLanguages = (Get-CimInstance -ClassName "Win32_OperatingSystem" -Property "MUILanguages").MUILanguages

    Write-Verbose "All installed Language Packs: $InstalledLanguages"
    $Found = $InstalledLanguages -icontains $LanguagePackName
    
    if ($Found)
    {
        $ensure = "Present"
    }
    else
    {
        $ensure = "Absent"
    }

    $returnValue = @{
        LanguagePackName = [System.String]$LanguagePackName
        Ensure = [System.String]$ensure
    }

    $returnValue
}

<#
    .SYNOPSIS
        Installs or uninstalls the specified Language Pack

    .PARAMETER LanguagePackName
        The short code for the language to be installed or uninstalled.  ie en-GB
    
    .PARAMETER LanguagePackLocation
        Either Local or Remote path to the language pack cab file.  This is only used
        when installing a language pack

    .PARAMETER Ensure
        Indicates whether the given language pack should be installed or uninstalled.
        Set this property to Present to install the Language Pack, and Absent to uninstall
        the Language Pack.  By Default Ensure is set to Present
#>
Function Set-TargetResource
{
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidGlobalVars", "global:DSCMachineStatus")]
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $LanguagePackName,

        [Parameter()]
        [System.String]
        $LanguagePackLocation,

        [Parameter()]
        [ValidateSet("Present","Absent")]
        [System.String]
        $Ensure="Present"
    )
    $timeout = 7200

    switch ($Ensure) 
    {
        'Present' {
            if ($PSBoundParameters.ContainsKey('LanguagePackLocation'))
            {
                Write-Verbose "Installing Language Pack"
                if (Test-Path -Path $LanguagePackLocation)
                {
                    lpksetup.exe /i $LanguagePackName /p $LanguagePackLocation /r /a /s
                    $startTime = Get-Date
                }
                else
                {
                    Throw "Invalid source Location"
                }
            }
            else
            {
                Throw "Language Pack location must be specified when adding a new Language Pack"
            }
        }
        'Absent' {
            Write-Verbose "Removing Language Pack"
            lpksetup.exe /u $LanguagePackName /r /a /s
            $startTime = Get-Date
        }
        default {
            Throw "invalid operation"
        }
    }
    do
    {
        $Process = Get-Process -Name "lpksetup" -ErrorAction SilentlyContinue
        $currentTime = (Get-Date) - $startTime
        if ($currentTime.TotalSeconds -gt $timeout)
        {
            throw "Process did not complete in under $timeout seconds"
        }
        Write-Verbose "Waiting for Process to finish.  Time Taken: $($currentTime)"
        Start-Sleep -Seconds 10
    } while ($null -ne $Process)
    #Force a reboot after installing or removing a language pack
    $global:DSCMachineStatus = 1
}

<#
    .SYNOPSIS
        Tests if a Language Pack requires installation or uninstallation

    .PARAMETER LanguagePackName
        The short code for the language to be installed or uninstalled.  ie en-GB
    
    .PARAMETER LanguagePackLocation
        Not used in Test-TargetResource.

    .PARAMETER Ensure
        Indicates whether the given language pack should be present or absent.
        Set this property to Present to install the Language Pack, and Absent to uninstall
        the Language Pack.  By Default Ensure is set to Present
#>
Function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    Param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $LanguagePackName,

        [Parameter()]
        [System.String]
        $LanguagePackLocation,

        [Parameter()]
        [ValidateSet("Present","Absent")]
        [System.String]
        $Ensure="Present"
    )
    
    $InstalledLanguages = (Get-CimInstance -ClassName "Win32_OperatingSystem" -Property "MUILanguages").MUILanguages

    Write-Verbose "All installed Language Packs: $InstalledLanguages"

    $Found = $InstalledLanguages -icontains $LanguagePackName

    Write-Verbose "Language Pack Found: $Found"

    switch ($Ensure) 
    {
        'Present' {
                $result = $Found
            }
        'Absent' {
                Write-Verbose "here"
                $result = (-not $Found)
            }
    }

    Write-Verbose "Actual Result Returned: $result"

    Return $result
}

Export-ModuleMember -Function *-TargetResource
