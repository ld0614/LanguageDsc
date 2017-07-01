function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory = $true)]
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


function Set-TargetResource
{
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidGlobalVars", "global:DSCMachineStatus")]
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $LanguagePackName,

        [System.String]
        $LanguagePackLocation,

        [ValidateSet("Present","Absent")]
        [System.String]
        $Ensure="Present"
    )

    switch ($Ensure) {
        'Present' {
                if ($PSBoundParameters.ContainsKey('LanguagePackLocation'))
                {
                    Write-Verbose "Installing Language Pack"
                    if (Test-Path -Path $LanguagePackLocation)
                    {
                        lpksetup.exe /i $LanguagePackName /p $LanguagePackLocation /r /a /s
                    }
                    else
                    {
                        Throw "Invalid source Location"
                    }
                }
                else
                {
                    throw "Language Pack location must be specified when adding a new Language Pack"
                }
            }
        'Absent' {
                Write-Verbose "Removing Language Pack"
                lpksetup.exe /u $LanguagePackName /r /a /s
            }
    }
    #Force a reboot after installing or removing a language pack
    $global:DSCMachineStatus = 1
}


function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $LanguagePackName,

        [System.String]
        $LanguagePackLocation,

        [ValidateSet("Present","Absent")]
        [System.String]
        $Ensure="Present"
    )
    
    $InstalledLanguages = (Get-CimInstance -ClassName "Win32_OperatingSystem" -Property "MUILanguages").MUILanguages

    Write-Verbose "All installed Language Packs: $InstalledLanguages"

    $Found = $InstalledLanguages -icontains $LanguagePackName

    Write-Verbose "Language Pack Found: $Found"

    switch ($Ensure) {
        'Present' {
                $result = $Found
            }
        'Absent' {
                write-verbose "here"
                $result = (-not $Found)
            }
    }

    Write-Verbose "Actual Result Returned: $result"

    return $result
}


Export-ModuleMember -Function *-TargetResource

