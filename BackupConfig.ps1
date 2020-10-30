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

#get protected volumes
$protectedVols = $NcDR | Get-NcSnapmirror -VserverContext $vserverDR |select SourceVolume 
$vols = @()
$vols += foreach($vol in $protectedVols) {get-ncvol -name $vol.SourceVolume -Controller $Nc -Vserver $Vserver}


#get cifs share from protectedVols
$cifsShares = foreach ($vol in $protectedVols) {Get-NcCifsShare -Controller $Nc -VserverContext $Vserver| ?{$_.Path -like "*$($vol.SourceVolume)*"}}

#get ACL from protectedVols
$cifsSharesACL = $cifsShares | Get-NcCifsShareAcl

#get unix user
$unixUsers = Get-NcNameMappingUnixUser -VserverContext $Vserver -Controller $Nc

#get unix group
$unixGroups = Get-NcNameMappingUnixGroup -VserverContext $Vserver -Controller $Nc

#get name mapping 
$nameMapping = Get-NcNameMapping -VserverContext $Vserver -Controller $Nc

#export to xml
$cifsShares | Export-Clixml -Path c:\Cifs.xml
$cifsSharesACL | Export-Clixml -Path c:\CifsACL.xml
$unixUsers | Export-Clixml -Path c:\unixUsers.xml
$unixGroups | Export-Clixml -Path c:\unixGroups.xml
$nameMapping | Export-Clixml -Path c:\nameMapping.xml
$vols | Export-Clixml -Path c:\vols.xml

if($Error.count -gt 0){Write-Host $Error[0]}else{Write-Host "Backup successfully $(get-date)" -ForegroundColor Green}