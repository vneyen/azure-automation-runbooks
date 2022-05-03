$LoadBalancerName = "vnylb01"
$ResourceGroupName = "rg01"

$ErrorActionPreference = "Stop"

# Connecting to Azure using system-assigned managed identity
Disable-AzContextAutosave -Scope Process | Out-Null
$AzureContext = (Connect-AzAccount -Identity).context
if ($AzureContext.Subscription -eq $null) {
	Write-Error -Message "AzureContext.Subscription is null, check RBAC" 
}
$AzureContext = Set-AzContext -SubscriptionName $AzureContext.Subscription -DefaultProfile $AzureContext
Write-Output "Connection to Azure using system-assigned managed identity successful" 

# Retrieve Load Balancer
Write-Output "Retrieving the load balancer '$LoadBalancerName' in resource group '$ResourceGroupName'"
$lb = (Get-AzLoadBalancer -ResourceGroupName $ResourceGroupName -Name $LoadBalancerName)

# Retrieve defined Backend Pools
if ($lb.BackendAddressPools.Count -ne 2) {
	Write-Error -Message "Load Balancer must have 2 and only 2 backend pools defined" 
}

$BackendPool1Name = $lb.BackendAddressPools[0].Name
$BackendPool2Name = $lb.BackendAddressPools[1].Name
Write-Output "Defined backend pools are $BackendPool1Name and $BackendPool2Name"

# Retrieve Current Backend Pool
$BalancerRule = $lb.LoadBalancingRules[0]
$CurrentBackendPoolName = $BalancerRule.BackendAddressPool.Id.split('/')[-1]
Write-Output "Current backend pool is $CurrentBackendPoolName"

# Switch BackendPool
switch ($CurrentBackendPoolName) {
	({$PSItem -eq $BackendPool1Name}) {
		Write-Output "Switching from $BackendPool1Name to $BackendPool2Name"
		$NewBackendPool = Get-AzLoadBalancerBackendAddressPoolConfig -LoadBalancer $lb -Name $BackendPool2Name
	}
	({$PSItem -eq $BackendPool2Name}) {
		Write-Output "Switching from $BackendPool2Name to $BackendPool1Name"
		$NewBackendPool = Get-AzLoadBalancerBackendAddressPoolConfig -LoadBalancer $lb -Name $BackendPool1Name
		
	}
	default {
		Write-Error -Message "Unexpected current backend pool, do not known what to do :("
	}
}

Set-AzLoadBalancerRuleConfig -LoadBalancer $lb -Name $BalancerRule.Name -BackendAddressPool $NewBackendPool -FrontendIpConfiguration $lb.FrontendIpConfigurations[0] -Protocol "All" -FrontendPort 0 -BackendPort 0 | Out-Null
$newlb = Set-AzLoadBalancer -LoadBalancer $lb

# Final Check
$NewCurrentBackendPoolName = $newlb.LoadBalancingRules[0].BackendAddressPool.Id.split('/')[-1]
if ($CurrentBackendPoolName -ne $NewCurrentBackendPoolName) {
	Write-Output "NEW current backend pool is $NewCurrentBackendPoolName"
} else {
	Write-Error -Message "We have a problem, Current Backend pool has not been switched !?"
}
