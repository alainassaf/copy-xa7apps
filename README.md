# copy-xa7apps
Copies published (active) applications from one XenApp/XenDesktop 7.x farm to another

#Contributions to this script
I'd like to highlight the posts that helped me write this scrip below.
* http://euc.consulting/blog/xenapp6-to-xenapp7-app-migration-script/

$ get-help .\copy-xa7apps.ps1 -full

NAME
    copy-xa7apps.ps1
    
SYNOPSIS
    Copies published (active) applications from one XenApp/XenDesktop 7.x farm to another
    
SYNTAX
    copy-xa7apps.ps1 [-Folders] <Array> [[-DeliveryGroup] 
    <String>] [[-ApplicationGroup] <String>] [-FromFarmDC] <String> [-ToFarmDC] <String> [[-DisableApps] <Boolean>] 
    [<CommonParameters>]
    
    
DESCRIPTION
    Copies published (active) applications from one XenApp/XenDesktop 7.x farm to another.
    The script assumes that Delivery and Application groups are the same in both farms. If an Admin folder is not 
    in the destination farm, it will be created.
    The script assumes The XenApp/XenDesktop 7 PowerShell cmdlets are installed.
    

PARAMETERS
    -Folders <Array>
        Required parameter. The folders within the XenApp farm to be migrated. Should be specified as 
        "Applications/<folderName1>/<folderName2>" If no folders are specified all applications in the farm
           will be migrated.
        
        Required?                    true
        Position?                    1
        Default value                
        Accept pipeline input?       false
        Accept wildcard characters?  false
        
    -DeliveryGroup <String>
        Optional parameter. The Delivery Group that the applications will be published to.
        
        Required?                    false
        Position?                    2
        Default value                
        Accept pipeline input?       false
        Accept wildcard characters?  false
        
    -ApplicationGroup <String>
        Optional parameter. The Application Group that the applications will be published to.
        
        Required?                    false
        Position?                    3
        Default value                
        Accept pipeline input?       false
        Accept wildcard characters?  false
        
    -FromFarmDC <String>
        Required parameter. The FQDN address of a XenDesktop 7.x delivery controller in the source farm.
        
        Required?                    true
        Position?                    4
        Default value                
        Accept pipeline input?       false
        Accept wildcard characters?  false
        
    -ToFarmDC <String>
        Required parameter. The FQDN address of a XenDesktop 7.x delivery controller in the destination farm.
        
        Required?                    true
        Position?                    5
        Default value                
        Accept pipeline input?       false
        Accept wildcard characters?  false
        
    -DisableApps <Boolean>
        Disable all the applications during import.
        
        Required?                    false
        Position?                    6
        Default value                False
        Accept pipeline input?       false
        Accept wildcard characters?  false
        
    <CommonParameters>
        This cmdlet supports the common parameters: Verbose, Debug,
        ErrorAction, ErrorVariable, WarningAction, WarningVariable,
        OutBuffer, PipelineVariable, and OutVariable. For more information, see 
        about_CommonParameters (http://go.microsoft.com/fwlink/?LinkID=113216). 
    
INPUTS
    None. You cannot pipe objects to this script.
    
OUTPUTS
    No objects are output from this script.
    
NOTES
    
        NAME: copy-xa7apps.ps1
        VERSION: 1.01
        CHANGE LOG - Version - When - What - Who
        1.00 - 02/23/2017 -Initial script, portions based on Shaun Ritchie's 
        http://euc.consulting/blog/xenapp6-to-xenapp7-app-migration-script - Alain Assaf
        1.01 - 02/23/2017 -Minor edits - Alain Assaf
        AUTHOR: Alain Assaf
        NAME: copy-xa7apps.ps1
        LASTEDIT: Feburary 23, 2017
    
    -------------------------- EXAMPLE 1 --------------------------
    
    PS C:PSScript >copy-xa7apps.ps1 -AdminAddress myxendesktopcontroller.mydomain.com -DeliveryGroup Finance
    
    Will migrate all applications from the XenApp 6 farm to the Finance Delivery Group in the XenApp 7 farm.
    
    -------------------------- EXAMPLE 2 --------------------------
    
    PS C:PSScript >copy-xa7apps.ps1 -Folders "ApplicationsProduction","ApplicationsHuman ResourcesLive" 
    -AdminAddress myxendesktopcontroller.mydomain.com
    
    -DeliveryGroup Windows2008R2
    
    Will migrate all the applications in the folders Production and Human ResourcesLive from the XenApp 6 farm to 
    the Finance Delivery Group in the XenApp 7 farm.
    
    -------------------------- EXAMPLE 3 --------------------------
    
    PS C:PSScript >copy-xa7apps.ps1 -AdminAddress myxendesktopcontroller.mydomain.com -DeliveryGroup Finance 
    -NewAccounts "MyDomainTest Group"
    
    Will migrate all applications from the XenApp 6 farm to the Finance Delivery Group in the XenApp 7 farm.
    The group Test Group will be added to all applications during import.
    
    -------------------------- EXAMPLE 4 --------------------------
    
    PS C:PSScript >copy-xa7apps.ps1 -AdminAddress myxendesktopcontroller.mydomain.com -DeliveryGroup Finance 
    -NewAccounts "MyDomainTest Group" -ReplaceAccounts $true
    
    Will migrate all applications from the XenApp 6 farm to the Finance Delivery Group in the XenApp 7 farm.
    The group Test Group will replace all existing accounts and groups on the published applications during import
    
    -------------------------- EXAMPLE 5 --------------------------
    
    PS C:PSScript >copy-xa7apps.ps1 -AdminAddress myxendesktopcontroller.mydomain.com -DeliveryGroup Finance 
    -DisableApps $true -Path C:Temp
    
    Will migrate all applications from the XenApp 6 farm to the Finance Delivery Group in the XenApp 7 farm.
    All Published Apps will be disable during import
    Report will be saved to C:temp
    
# Legal and Licensing
The copy-xa7apps.ps1 script is licensed under the [MIT license][].

[MIT license]: LICENSE

# Want to connect?
* LinkedIn - https://www.linkedin.com/in/alainassaf
* Twitter - http://twitter.com/alainassaf
* Wag the Real - my blog - https://wagthereal.com
* Edgesightunderthehood - my other - blog https://edgesightunderthehood.com

# Help
I welcome any feedback, ideas or contributors.
