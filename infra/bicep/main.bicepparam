using 'main.bicep'

// ============================================================================
// Application Gateway with mTLS - Sample Parameters
// Update these values for your environment
// ============================================================================

// Application Gateway name
param applicationGatewayName = 'agw-mtls-001'

// Azure region
param location = 'eastus'

// Key Vault configuration
param keyVaultName = 'kv-certificates-001'
param keyVaultResourceGroupName = 'rg-shared-services'
param sslCertificateSecretName = 'agw-ssl-certificate'

// SSL certificate PFX data (base64-encoded .pfx file content)
// This certificate is used for HTTPS termination on the Application Gateway
// Replace with your actual base64-encoded PFX certificate
param sslCertificatePfxData = '<base64-encoded-pfx-certificate-data>'

// Trusted client CA certificate data (base64-encoded .cer file content)
// This certificate is used to validate client certificates in mTLS
// Replace with your actual base64-encoded CA certificate
param trustedClientCertificateData = '<base64-encoded-ca-certificate-data>'

// APIM backend configuration
param apimBackendFqdn = 'myapim.azure-api.net'

// mTLS listener host name
param mtlsHostName = 'api.contoso.com'

// Network configuration
param subnetResourceId = '/subscriptions/{subscription-id}/resourceGroups/{rg-name}/providers/Microsoft.Network/virtualNetworks/{vnet-name}/subnets/{subnet-name}'
param publicIpResourceId = '/subscriptions/{subscription-id}/resourceGroups/{rg-name}/providers/Microsoft.Network/publicIPAddresses/{pip-name}'

// Managed identity with Key Vault access
param userAssignedIdentityResourceId = '/subscriptions/{subscription-id}/resourceGroups/{rg-name}/providers/Microsoft.ManagedIdentity/userAssignedIdentities/{identity-name}'

// SKU configuration
param sku = 'WAF_v2'
param wafPolicyResourceId = '/subscriptions/{subscription-id}/resourceGroups/{rg-name}/providers/Microsoft.Network/ApplicationGatewayWebApplicationFirewallPolicies/{waf-policy-name}'

// Tags
param tags = {
  Environment: 'Production'
  Application: 'API Gateway'
  CostCenter: 'IT-001'
}
