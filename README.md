# cDOT-Cifs-Config-Export-Import
backup and import cifs config from primary system to secondary system

# Export and Import cDOT config
## Purpose
Export Proteced-Volumes(Snapmirrored) cifs shares and related to XML file and import to secondary system.
This used for backing up more then volumes itself.
SCOPE
This script export the config below on specific svm only for protected volumes:
* Cifs shares
*	Mount Path
*	Unix Users
*	Unix Groups
*	Name Mapping
## Prerequisites
*	Powershell toolkit from NetApp site ----  https://mysupport.netapp.com/site/tools   (tested on 9.7)
*	Snapmirrored machines **with the same volumes name on source and destination**
## Procedure
### backup
1.	Open Powershell ISE as Administrator on Windows system where toolkit installed
2.	Run script, using .\backupConfig.ps1 with parameters.
a.	Paramters are:
**	Cluster – ip / dns for primary system
**	ClusterUser – primary admin user
**	ClusterPassword – primary admin password
**	Vserver – primary svm 
**	ClusterDR - ip / dns for secondary DR system
**	ClusterDRUser – secondary admin user
**	ClusterDRPassword – secondary admin password
**	VserverDR – secondary vserver
3.	The script generate 6 XML format files to “C:\”  (hard-coded on this version):
*	Protected Volumes
*	Cifs Shares
*	Cifs Shares ACL
*	Unix Users
*	Unix Groups
*	Name Mapping
4.	You can scheduled this for backing up the Primary system
### Import
1.	Open Powershell ISE as Administrator on Windows system where toolkit installed
2.	Run script, using .\importConfig.ps1 with parameters.
3.	Same parameters as backup.
4.	The script imports the files from C:\*.xml and use them to create cifs shares, name mapping etc…

## Example

```
 .\BackupConfig.ps1 -Cluster NetappPrimary -ClusterDR NetappSecondary -ClusterUser admin -Vserver svm -VserverDR svm_dr -ClusterPassword netapp123 -ClusterDRUser admin -ClusterDRPassword netapp123 
```
```
 .\importConfig.ps1 -Cluster NetappPrimary -ClusterDR NetappSecondary -ClusterUser admin -Vserver svm -VserverDR svm_dr -ClusterPassword netapp123 -ClusterDRUser admin -ClusterDRPassword netapp123 
```
Good luck,
NetApp PS, Daniel Maryuma





