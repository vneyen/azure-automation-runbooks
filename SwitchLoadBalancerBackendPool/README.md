# SwitchLoadBalancerBackendPool

## Scenario

A Load Balancer with one HA ports Load Balancing Rule. Two Backend Pools defined but only one used at a time by the Load Balancing Rule.

Goal is to update the Load Balancing Rule to use the other Backend Pool. 

## Configuration and prerequisites

Fix Load Balancer name and resource group that are hard coded (see ```$LoadBalancerName``` and ```$ResourceGroupName```).

Automation account must have a **system assigned identity** and granted following roles:

  * Contributor on Load Balancer
  * Network Contributor Role on Virtual Network
