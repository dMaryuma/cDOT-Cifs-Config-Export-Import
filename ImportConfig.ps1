Param([parameter(Mandatory = $true)] [alias("c")] $Cluster,
      [parameter(Mandatory = $true)] [alias("cdr")] $ClusterDR,
      [parameter(Mandatory = $true)] [alias("cu")] $ClusterUser,
      [parameter(Mandatory = $true)] [alias("svm")] $Vserver,
      [parameter(Mandatory = $true)] [alias("svmdr")] $VserverDR,
      [parameter(Mandatory = $true)] [alias("cp")] $ClusterPassword,
      [parameter(Mandatory = $true)] [alias("cdru")] $ClusterDRUser,
      [parameter(Mandatory = $true)] [alias("cdrp")] $ClusterDRPassword)


$Error.Clear()

# You need to install the latest DataONTAP Powershell Toolkit. You can find it here: http://mysupport.netapp.com/NOW/download/tools/powershell_toolkit/
Import-Module DataONTAP

$ClusPasswd = ConvertTo-SecureString $ClusterPassword -AsPlainText -Force
$ClusCred = New-Object -typename System.Management.Automation.PSCredential -ArgumentList $ClusterUser, $ClusPasswd
$ClusDRPasswd = ConvertTo-SecureString $ClusterDRPassword -AsPlainText -Force
$ClusDRCred = New-Object -typename System.Management.Automation.PSCredential -ArgumentList $ClusterDRUser, $ClusDRPasswd
try{
    $Nc = Connect-NcController $Cluster -Credential $ClusCred -ErrorAction Stop 
    $NcDR = Connect-NcController $ClusterDR -Credential $ClusDRCred -ErrorAction Stop
}
catch{
    Write-Host "unable to connect to cluster, check your cred"
    exit(1)
}

#export to xml
$cifsShares = Import-Clixml -Path c:\Cifs.xml
$cifsSharesACL = Import-Clixml -Path c:\CifsACL.xml
$unixUsers = Import-Clixml -Path c:\unixUsers.xml
$unixGroups = Import-Clixml -Path c:\unixGroups.xml
$nameMapping = Import-Clixml -Path c:\nameMapping.xml
$vols = Import-Clixml -Path c:\vols.xml


#get protected volumes
$volsDR = foreach ($vol in $vols) {Get-NcVol -Controller $NcDR -Name $vol.Name -VserverContext $VserverDR}

#mount volsDR
foreach ($volDR in $volsDR){
    foreach ($vol in $vols){
        if ($vol.Name -eq $volDR.Name){
            Mount-NcVol -Name $volDR.Name -JunctionPath $vol.JunctionPath -VserverContext $VserverDR
        }
    }
} 


#create cifs share
foreach ($volDR in $volsDR){
    foreach ($share in $cifsShares){
        if ($share.Volume -eq $volDR.Name){
            try{
            Add-NcCifsShare -Name $share.ShareName -Path $share.Path -ShareProperties $share.ShareProperties -SymlinkProperties $share.SymlinkProperties -VscanProfile $share.VscanFileopProfile -VserverContext $VserverDR -ErrorAction stop
            }catch {Write-Warning "$($Error[0]) in $($share.Volume) for create cifs"}
        }
    }
} 

#modify cifs share acl
foreach ($share in $cifsShares){
    foreach ($acl in $cifsSharesACL){
        if ($share.ShareName -eq $acl.Share){
            try{
            Add-NcCifsShareAcl -Share $acl.Share -UserOrGroup $acl.UserOrGroup -UserGroupType $acl.UserGroupType -VserverContext $VserverDR -Permission $acl.permission -Controller $NcDR -ErrorAction stop
            }catch {Write-Warning "$($Error[0]) in $($share.ShareName) for create cifs ACL"}
        }
    }
} 

#create unix group
foreach ($usr in $unixGroups){
    try{
    $usr | New-NcNameMappingUnixGroup -VserverContext $VserverDR -ErrorAction stop
    }
    catch{
        Write-Warning "$($Error[0]) in $($usr.UserName) for create unix group"
    }
}

#create unix users
foreach ($usr in $unixUsers){
    try{
    $usr | New-NcNameMappingUnixUser -VserverContext $VserverDR -ErrorAction stop
    }
    catch{
        Write-Warning "$($Error[0]) in $($usr.UserName) for create unix user"
    }
}

#create name-mapping
foreach ($name in $nameMapping){
    try{
    $name | New-NcNameMapping -VserverContext $VserverDR -ErrorAction stop
    }
    catch{
        Write-Warning "$($Error[0]) in $($usr.UserName) for creating name-mapping"
    }
}

if($Error.count -gt 0){Write-Host $Error[0]}else{Write-Host "import successfully $(get-date)" -ForegroundColor Green}