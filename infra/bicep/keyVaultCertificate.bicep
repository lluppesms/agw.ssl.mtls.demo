// ============================================================================
// Key Vault Certificate Module
// This module uploads a PFX certificate to an existing Key Vault as a secret
// The Application Gateway can then reference this certificate
// ============================================================================

targetScope = 'resourceGroup'

// ============================================================================
// Parameters
// ============================================================================

@description('Name of the existing Key Vault')
param keyVaultName string

@description('Name of the certificate secret to create')
param certificateSecretName string

@description('Base64 encoded PFX certificate data')
@secure()
param certificateData string

@description('Content type for the secret')
param contentType string = 'application/x-pkcs12'

@description('Tags for the secret')
param tags object = {}

// ============================================================================
// Existing Resources
// ============================================================================

resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' existing = {
  name: keyVaultName
}

// ============================================================================
// Key Vault Secret (Certificate)
// ============================================================================

resource certificateSecret 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  parent: keyVault
  name: certificateSecretName
  tags: tags
  properties: {
    value: certificateData
    contentType: contentType
    attributes: {
      enabled: true
    }
  }
}

// ============================================================================
// Outputs
// ============================================================================

@description('Resource ID of the certificate secret')
output secretResourceId string = certificateSecret.id

@description('Name of the certificate secret')
output secretName string = certificateSecret.name

@description('URI of the certificate secret')
output secretUri string = certificateSecret.properties.secretUri

@description('URI with version of the certificate secret')
output secretUriWithVersion string = certificateSecret.properties.secretUriWithVersion
