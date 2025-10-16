Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools

Import-Module ADDSDeployment
Install-ADDSForest `
	-DomainName "corp.migazzi.com" `
	-InstallDNS