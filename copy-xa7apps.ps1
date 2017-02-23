<#
.SYNOPSIS
	Copies published (active) applications from one XenApp/XenDesktop 7.x farm to another
.DESCRIPTION
    Copies published (active) applications from one XenApp/XenDesktop 7.x farm to another.
    The script assumes that Delivery and Application groups are the same in both farms. If an Admin folder is not in the destination farm, it will be created.
    The script assumes The XenApp/XenDesktop 7 PowerShell cmdlets are installed.
.PARAMETER Folders
	Required parameter. The folders within the XenApp farm to be migrated. Should be specified as "Applications/<folderName1>/<folderName2>" If no folders are specified all applications in the farm
    will be migrated.
.PARAMETER DeliveryGroup
	Optional parameter. The Delivery Group that the applications will be published to.
.PARAMETER ApplicationGroup
	Optional parameter. The Application Group that the applications will be published to.
.PARAMETER FromFarmDC
	Required parameter. The FQDN address of a XenDesktop 7.x delivery controller in the source farm.
.PARAMETER ToFarmDC
	Required parameter. The FQDN address of a XenDesktop 7.x delivery controller in the destination farm.
.PARAMETER DisableApps
    Disable all the applications during import.
.EXAMPLE
    PS C:PSScript >copy-xa7apps.ps1 -AdminAddress myxendesktopcontroller.mydomain.com -DeliveryGroup Finance

    Will migrate all applications from the XenApp 6 farm to the Finance Delivery Group in the XenApp 7 farm.
.EXAMPLE
    PS C:PSScript >copy-xa7apps.ps1 -Folders "ApplicationsProduction","ApplicationsHuman ResourcesLive" -AdminAddress myxendesktopcontroller.mydomain.com
    -DeliveryGroup Windows2008R2

    Will migrate all the applications in the folders Production and Human ResourcesLive from the XenApp 6 farm to the
    Finance Delivery Group in the XenApp 7 farm.
.EXAMPLE
    PS C:PSScript >copy-xa7apps.ps1 -AdminAddress myxendesktopcontroller.mydomain.com -DeliveryGroup Finance -NewAccounts "MyDomainTest Group"

    Will migrate all applications from the XenApp 6 farm to the Finance Delivery Group in the XenApp 7 farm.
    The group Test Group will be added to all applications during import.
.EXAMPLE
    PS C:PSScript >copy-xa7apps.ps1 -AdminAddress myxendesktopcontroller.mydomain.com -DeliveryGroup Finance -NewAccounts "MyDomainTest Group" -ReplaceAccounts $true

    Will migrate all applications from the XenApp 6 farm to the Finance Delivery Group in the XenApp 7 farm.
    The group Test Group will replace all existing accounts and groups on the published applications during import
.EXAMPLE
   PS C:PSScript >copy-xa7apps.ps1 -AdminAddress myxendesktopcontroller.mydomain.com -DeliveryGroup Finance -DisableApps $true -Path C:Temp

    Will migrate all applications from the XenApp 6 farm to the Finance Delivery Group in the XenApp 7 farm.
    All Published Apps will be disable during import
    Report will be saved to C:temp
.INPUTS
	None. You cannot pipe objects to this script.
.OUTPUTS
	No objects are output from this script.
.LINK
	http://www.shaunritchie.co.uk
.NOTES
    NAME: copy-xa7apps.ps1
    VERSION: 1.01
    CHANGE LOG - Version - When - What - Who
    1.00 - 02/23/2017 -Initial script, portions based on Shaun Ritchie's http://euc.consulting/blog/xenapp6-to-xenapp7-app-migration-script - Alain Assaf
    1.01 - 02/23/2017 -Minor edits - Alain Assaf
    AUTHOR: Alain Assaf
    NAME: copy-xa7apps.ps1
    LASTEDIT: Feburary 23, 2017
.LINK
    http://www.linkedin.com/in/alainassaf/
    http://wagthereal.com
    http://euc.consulting/blog/xenapp6-to-xenapp7-app-migration-script/
#>

#Thanks to @jeffwouters and @carlwebster for the below parameter structure.
[CmdletBinding(SupportsShouldProcess = $False, ConfirmImpact = "None", DefaultParameterSetName = "") ]
Param (
    [parameter(Mandatory=$True)]
	[Alias("F")]
	[ValidateNotNullOrEmpty()]
	[Array]$Folders="",

    [parameter(Mandatory=$false)]
	[Alias("DG")]
	[ValidateNotNullOrEmpty()]
	[String]$DeliveryGroup="",

    [parameter(Mandatory=$false)]
	[Alias("AG")]
	[ValidateNotNullOrEmpty()]
	[String]$ApplicationGroup="",
    
    [parameter(Mandatory=$True)]
	[ValidateNotNullOrEmpty()]
	[String]$FromFarmDC="",
    
    [parameter(Mandatory=$True)]
	[ValidateNotNullOrEmpty()]
	[String]$ToFarmDC="",

    [parameter(Mandatory=$False)]
	[Alias("DA")]
	[ValidateNotNullOrEmpty()]
	[Boolean]$DisableApps=$False)

Add-PSSnapin Citrix.* -ErrorAction silentlycontinue

[Array]$AppReport = @()

[Array]$AppReport = @()
[Array]$XAApplist = @()
If ($Folders -ne $null) {
    ForEach ($Folder in $Folders) {
        $SubFolders += Get-BrokerAdminFolder -AdminAddress $FromFarmDC -Name $Folder
        $XAAppList += Get-BrokerApplication -AdminAddress $FromFarmDC -AdminFolderName $Folder | where {$_.Enabled -eq $true}
    }
    If ($SubFolders -ne $null) {
        ForEach ($SubFolder in $SubFolders) {
            $XAAppList += Get-BrokerApplication -AdminAddress $FromFarmDC -AdminFolderName $SubFolder | where {$_.Enabled -eq $true}
        }
    }
    ForEach ($XAApp in $XAAppList) {
        $AppReport += Get-BrokerApplication -AdminAddress $FromFarmDC -BrowserName $XAApp.BrowserName
    }
} Else {
    $AppReport = Get-BrokerApplication -AdminAddress $FromFarmDC *
}

# Get Desktop Group UID

if ($DeliveryGroup -ne "") {
    $DeliveryGroupUID = Get-BrokerDesktopGroup -AdminAddress $ToFarmDC -Name $DeliveryGroup
}

# Get Application Group UID

if ($ApplicationGroup -ne "") {
    $ApplicationGroupUID = Get-BrokerApplicationGroup -AdminAddress $ToFarmDC -Name $ApplicationGroup
}

[Array]$AppIcons = @()

ForEach ($App in $AppReport)
{
        $AppIcons += Get-brokericon -AdminAddress $FromFarmDC -Uid $app.IconUid
}

ForEach ($App in $AppReport) {
    [Array]$CommandLines = @()
    If (($App.CommandLineExecutable.Contains(" /")) -eq $True) {
        $CommandLines = $App.CommandLineExecutable -split " /"
        $CommandLines[1] = "/" + $CommandLines[1]
    } ElseIf (($App.CommandLineExecutable.Contains('" ')) -eq $True) {
        $CommandLines = $App.CommandLineExecutable -split '" '
    } ElseIf (($App.CommandLineExecutable.Contains('"')) -eq $True) {
        $CommandLines += ($App.CommandLineExecutable -replace '"', "")
    } Else {
        $CommandLines += ($App.CommandLineExecutable)
    }

    If (($App.CommandLineArguments.Contains(" /")) -eq $True) {
        $CommandLines = $App.CommandLineArguments -split " /"
        $CommandLines[1] = "/" + $CommandLines[1]
    } ElseIf (($App.CommandLineArguments.Contains('" ')) -eq $True) {
        $CommandLines = $App.CommandLineArguments -split '" '
    } ElseIf (($App.CommandLineArguments.Contains('"')) -eq $True) {
        $CommandLines += ($App.CommandLineArguments -replace '"', "")
    } Else {
        $CommandLines += ($App.CommandLineArguments)
    }

    # Create the application icon

    $IconData = $AppIcons | Where-Object {$_.Uid -eq $app.IconUid}
    $BrokerIcon = New-BrokerIcon -AdminAddress $ToFarmDC -EncodedIconData $($IconData[0].EncodedIconData -as [string])

    #Create Admin folder if it does not exist

    if ((Get-BrokerAdminFolder -AdminAddress $ToFarmDC  -foldername $app.AdminFolderName.split("\")[0]) -eq $null) {
        new-brokeradminfolder -AdminAddress $ToFarmDC -FolderName $app.AdminFolderName.split("\")[0]
    }

    #Create the application

    if ($DeliveryGroup -ne "") {
        If ($CommandLines[1] -eq $null -and $DisableApps -eq $True) {
            New-BrokerApplication -Name $App.PublishedName  -AdminAddress $ToFarmDC -ApplicationType 'HostedOnDesktop' -BrowserName $App.PublishedName -ClientFolder $App.ClientFolder -CommandLineExecutable ($CommandLines[0] -Replace '"', "") -CpuPriorityLevel $($App.CpuPriorityLevel -as [string]) -Description $App.Description -DesktopGroup $DeliveryGroupUID.Uid -Enabled $False -IconUid $BrokerIcon.Uid -Priority 0 -PublishedName $App.PublishedName -SecureCmdLineArgumentsEnabled $True -ShortcutAddedToDesktop $($App.ShortcutAddedToDesktop -as [bool]) -ShortcutAddedToStartMenu $($App.ShortcutAddedToStartMenu -as [bool]) -UserFilterEnabled $True -Visible $False -WaitForPrinterCreation $($App.WaitOnPrinterCretion -as [bool]) -WorkingDirectory $App.WorkingDirectory -AdminFolder $app.adminfoldername | Out-Null
        } ElseIf ($CommandLines[1] -eq $null -and $DisableApps -eq $False) {
            New-BrokerApplication -Name $App.PublishedName  -AdminAddress $ToFarmDC -ApplicationType 'HostedOnDesktop' -BrowserName $App.PublishedName -ClientFolder $App.ClientFolder -CommandLineExecutable ($CommandLines[0] -Replace '"', "") -CpuPriorityLevel $($App.CpuPriorityLevel -as [string]) -Description $App.Description -DesktopGroup $DeliveryGroupUID.Uid -Enabled $($App.Enabled -as [bool]) -IconUid $BrokerIcon.Uid -Priority 0 -PublishedName $App.PublishedName -SecureCmdLineArgumentsEnabled $True -ShortcutAddedToDesktop $($App.ShortcutAddedToDesktop -as [bool]) -ShortcutAddedToStartMenu $($App.ShortcutAddedToStartMenu -as [bool]) -UserFilterEnabled $True -Visible $True -WaitForPrinterCreation $($App.WaitForPrinterCreation -as [bool]) -WorkingDirectory $App.WorkingDirectory -AdminFolder $app.adminfoldername | Out-Null
        } ElseIf ($CommandLines[1] -ne $null -and $DisableApps -eq $True) {
            New-BrokerApplication -Name $App.PublishedName  -AdminAddress $ToFarmDC -ApplicationType 'HostedOnDesktop' -BrowserName $App.PublishedName -ClientFolder $App.ClientFolder -CommandLineExecutable ($CommandLines[0] -Replace '"', "") -CommandLineArguments (($CommandLines[1] -Replace '"', "") + ($CommandLines[2]  -Replace '"', "") + ($CommandLines[3]  -Replace '"', "") + ($CommandLines[4]  -Replace '"', ""))  -CpuPriorityLevel $($App.CpuPriorityLevel -as [string]) -Description $App.Description -DesktopGroup $DeliveryGroupUID.Uid -Enabled $False -IconUid $BrokerIcon.Uid -Priority 0 -PublishedName $App.PublishedName -SecureCmdLineArgumentsEnabled $True -ShortcutAddedToDesktop $($App.ShortcutAddedToDesktop -as [bool]) -ShortcutAddedToStartMenu $($App.ShortcutAddedToStartMenu -as [bool]) -UserFilterEnabled $True -Visible $False -WaitForPrinterCreation $($App.WaitForPrinterCreation -as [bool]) -WorkingDirectory $App.WorkingDirectory -AdminFolder $app.adminfoldername | Out-Null 
        } ElseIf ($CommandLines[1] -ne $null -and $DisableApps -eq $False) {
            New-BrokerApplication -Name $App.PublishedName -AdminAddress $ToFarmDC -ApplicationType 'HostedOnDesktop' -BrowserName $App.PublishedName -ClientFolder $App.ClientFolder -CommandLineExecutable ($CommandLines[0] -Replace '"', "") -CommandLineArguments (($CommandLines[1] -Replace '"', "") + ($CommandLines[2]  -Replace '"', "") + ($CommandLines[3]  -Replace '"', "") + ($CommandLines[4]  -Replace '"', ""))  -CpuPriorityLevel $($App.CpuPriorityLevel -as [string]) -Description $App.Description -DesktopGroup $DeliveryGroupUID.Uid -Enabled $($App.Enabled -as [bool]) -IconUid $BrokerIcon.Uid -Priority 0 -PublishedName $App.PublishedName -SecureCmdLineArgumentsEnabled $True -ShortcutAddedToDesktop $($App.ShortcutAddedToDesktop -as [bool]) -ShortcutAddedToStartMenu $($App.ShortcutAddedToStartMenu -as [bool]) -UserFilterEnabled $True -Visible $False -WaitForPrinterCreation $($App.WaitForPrinterCreation -as [bool]) -WorkingDirectory $App.WorkingDirectory -AdminFolder $app.adminfoldername | Out-Null 
        }
    } elseif ($ApplicationGroup -ne "") {
        If ($CommandLines[1] -eq $null -and $DisableApps -eq $True) {
            New-BrokerApplication -Name $App.PublishedName  -AdminAddress $ToFarmDC -ApplicationType 'HostedOnDesktop' -BrowserName $App.PublishedName -ClientFolder $App.ClientFolder -CommandLineExecutable ($CommandLines[0] -Replace '"', "") -CpuPriorityLevel $($App.CpuPriorityLevel -as [string]) -Description $App.Description -ApplicationGroup $ApplicationGroupUID.Uid -Enabled $False -IconUid $BrokerIcon.Uid -PublishedName $App.PublishedName -SecureCmdLineArgumentsEnabled $True -ShortcutAddedToDesktop $($App.ShortcutAddedToDesktop -as [bool]) -ShortcutAddedToStartMenu $($App.ShortcutAddedToStartMenu -as [bool]) -UserFilterEnabled $True -Visible $False -WaitForPrinterCreation $($App.WaitOnPrinterCretion -as [bool]) -WorkingDirectory $App.WorkingDirectory -AdminFolder $app.adminfoldername | Out-Null 
        } ElseIf ($CommandLines[1] -eq $null -and $DisableApps -eq $False) {
            New-BrokerApplication -Name $App.PublishedName  -AdminAddress $ToFarmDC -ApplicationType 'HostedOnDesktop' -BrowserName $App.PublishedName -ClientFolder $App.ClientFolder -CommandLineExecutable ($CommandLines[0] -Replace '"', "") -CpuPriorityLevel $($App.CpuPriorityLevel -as [string]) -Description $App.Description -ApplicationGroup $ApplicationGroupUID.Uid -Enabled $($App.Enabled -as [bool]) -IconUid $BrokerIcon.Uid -PublishedName $App.PublishedName -SecureCmdLineArgumentsEnabled $True -ShortcutAddedToDesktop $($App.ShortcutAddedToDesktop -as [bool]) -ShortcutAddedToStartMenu $($App.ShortcutAddedToStartMenu -as [bool]) -UserFilterEnabled $True -Visible $True -WaitForPrinterCreation $($App.WaitForPrinterCreation -as [bool]) -WorkingDirectory $App.WorkingDirectory -AdminFolder $app.adminfoldername | Out-Null 
        } ElseIf ($CommandLines[1] -ne $null -and $DisableApps -eq $True) {
            New-BrokerApplication -Name $App.PublishedName  -AdminAddress $ToFarmDC -ApplicationType 'HostedOnDesktop' -BrowserName $App.PublishedName -ClientFolder $App.ClientFolder -CommandLineExecutable ($CommandLines[0] -Replace '"', "") -CommandLineArguments (($CommandLines[1] -Replace '"', "") + ($CommandLines[2]  -Replace '"', "") + ($CommandLines[3]  -Replace '"', "") + ($CommandLines[4]  -Replace '"', ""))  -CpuPriorityLevel $($App.CpuPriorityLevel -as [string]) -Description $App.Description -ApplicationGroup $ApplicationGroupUID.Uid -Enabled $False -IconUid $BrokerIcon.Uid -PublishedName $App.PublishedName -SecureCmdLineArgumentsEnabled $True -ShortcutAddedToDesktop $($App.ShortcutAddedToDesktop -as [bool]) -ShortcutAddedToStartMenu $($App.ShortcutAddedToStartMenu -as [bool]) -UserFilterEnabled $True -Visible $False -WaitForPrinterCreation $($App.WaitForPrinterCreation -as [bool]) -WorkingDirectory $App.WorkingDirectory -AdminFolder $app.adminfoldername | Out-Null 
        } ElseIf ($CommandLines[1] -ne $null -and $DisableApps -eq $False) {
            New-BrokerApplication -Name $App.PublishedName -AdminAddress $ToFarmDC -ApplicationType 'HostedOnDesktop' -BrowserName $App.PublishedName -ClientFolder $App.ClientFolder -CommandLineExecutable ($CommandLines[0] -Replace '"', "") -CommandLineArguments (($CommandLines[1] -Replace '"', "") + ($CommandLines[2]  -Replace '"', "") + ($CommandLines[3]  -Replace '"', "") + ($CommandLines[4]  -Replace '"', ""))  -CpuPriorityLevel $($App.CpuPriorityLevel -as [string]) -Description $App.Description -ApplicationGroup $ApplicationGroupUID.Uid -Enabled $($App.Enabled -as [bool]) -IconUid $BrokerIcon.Uid -PublishedName $App.PublishedName -SecureCmdLineArgumentsEnabled $True -ShortcutAddedToDesktop $($App.ShortcutAddedToDesktop -as [bool]) -ShortcutAddedToStartMenu $($App.ShortcutAddedToStartMenu -as [bool]) -UserFilterEnabled $True -Visible $False -WaitForPrinterCreation $($App.WaitForPrinterCreation -as [bool]) -WorkingDirectory $App.WorkingDirectory -AdminFolder $app.adminfoldername | Out-Null 
        }
    } else {
        write-host $App.PublishedName.ToString()" not created"
    }

    # Create the user / groups in the database and map to the application

    #[Array]$Accounts = @()
    If ($ReplaceAccounts -ne $true) {
        $Accounts = $App.AssociatedUsernames
        ForEach ($Account in $Accounts) {
            New-BrokerUser -Name $Account | out-null
            Get-BrokerApplication -AdminAddress $ToFarmDC | where {$_.PublishedName -eq $app.PublishedName} | Add-BrokerUser -name $Account
        }
    }
}