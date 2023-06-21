output "hub_vnet_id" {
  value = azurerm_virtual_network.hub_vnet.id
}
output "agw_backend_address_pool" {
  value = azurerm_application_gateway.central_agw.backend_address_pool
}
output "agw_public_ip" {
  value = azurerm_public_ip.centrallb_pip.ip_address
}
output "resource_group_name" {
  value = azurerm_resource_group.hub_rg.name
}
output "hub_vnet_name" {
  value = azurerm_virtual_network.hub_vnet.name
}