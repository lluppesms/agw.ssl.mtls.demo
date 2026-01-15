// ============================================================================
// Application Gateway with mTLS Support - Main Orchestration
// This template orchestrates the deployment of an Application Gateway 
// configured for mTLS with an existing APIM backend.
// ============================================================================

targetScope = 'resourceGroup'

// ============================================================================
// Parameters
// ============================================================================

@description('Name of the Application Gateway')
param applicationGatewayName string

@description('Location for all resources')
param location string = resourceGroup().location

@description('Name of the existing Key Vault containing the SSL certificate')
param keyVaultName string

@description('Resource group name of the existing Key Vault')
param keyVaultResourceGroupName string = resourceGroup().name

@description('Name of the SSL certificate in Key Vault (stored as a secret)')
param sslCertificateSecretName string

@description('Base64-encoded PFX certificate data for the SSL certificate')
@secure()
param sslCertificatePfxData string

@description('Base64-encoded trusted client CA certificate data (.cer format) for mTLS validation')
@secure()
param trustedClientCertificateData string

@description('APIM backend FQDN (e.g., myapim.azure-api.net)')
param apimBackendFqdn string

@description('Host name for the mTLS listener')
param mtlsHostName string

@description('Resource ID of the subnet for the Application Gateway')
param subnetResourceId string

@description('Resource ID of the public IP address for the Application Gateway')
param publicIpResourceId string

@description('Resource ID of the user-assigned managed identity with Key Vault access')
param userAssignedIdentityResourceId string

@description('SKU of the Application Gateway')
@allowed([
  'Standard_v2'
  'WAF_v2'
])
param sku string = 'WAF_v2'

@description('Resource ID of the WAF policy (required for WAF_v2 SKU)')
param wafPolicyResourceId string = ''

@description('Tags for resources')
param tags object = {}

// ============================================================================
// Modules
// ============================================================================

// Upload SSL certificate to Key Vault
module sslCertificate 'keyVaultCertificate.bicep' = {
  name: 'deploy-${sslCertificateSecretName}'
  scope: resourceGroup(keyVaultResourceGroupName)
  params: {
    keyVaultName: keyVaultName
    certificateSecretName: sslCertificateSecretName
    certificateData: sslCertificatePfxData
    tags: tags
  }
}

// Deploy Application Gateway
module applicationGateway 'applicationGateway.bicep' = {
  name: 'deploy-${applicationGatewayName}'
  dependsOn: [ sslCertificate ]
  params: {
    name: applicationGatewayName
    location: location
    sku: sku
    userAssignedIdentityResourceId: userAssignedIdentityResourceId
    wafPolicyResourceId: wafPolicyResourceId
    subnetResourceId: subnetResourceId
    publicIpResourceId: publicIpResourceId
    sslCertificateKeyVaultSecretId: sslCertificate.outputs.secretUri
    trustedClientCertificateData: trustedClientCertificateData
    apimBackendFqdn: apimBackendFqdn
    mtlsHostName: mtlsHostName
    tags: tags
  }
}

// ============================================================================
// Outputs
// ============================================================================

@description('Resource ID of the Application Gateway')
output applicationGatewayResourceId string = applicationGateway.outputs.resourceId

@description('Name of the Application Gateway')
output applicationGatewayName string = applicationGateway.outputs.name

@description('Frontend public IP configuration ID')
output frontendIpConfigurationId string = applicationGateway.outputs.frontendIpConfigurationId

@description('mTLS listener ID')
output mtlsListenerId string = applicationGateway.outputs.mtlsListenerId

@description('mTLS routing rule ID')
output mtlsRoutingRuleId string = applicationGateway.outputs.mtlsRoutingRuleId

@description('mTLS rewrite rule set ID')
output mtlsRewriteRuleSetId string = applicationGateway.outputs.mtlsRewriteRuleSetId

@description('SSL profile ID')
output sslProfileId string = applicationGateway.outputs.sslProfileId
