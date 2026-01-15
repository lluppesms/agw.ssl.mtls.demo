// ============================================================================
// Application Gateway Module
// Deploys an Application Gateway with mTLS support
// ============================================================================

targetScope = 'resourceGroup'

// ============================================================================
// Parameters
// ============================================================================

@description('Name of the Application Gateway')
param name string

@description('Location for all resources')
param location string

@description('SKU of the Application Gateway')
@allowed([
  'Standard_v2'
  'WAF_v2'
])
param sku string

@description('Resource ID of the user-assigned managed identity')
param userAssignedIdentityResourceId string

@description('Resource ID of the WAF policy')
param wafPolicyResourceId string

@description('Resource ID of the subnet for the Application Gateway')
param subnetResourceId string

@description('Resource ID of the public IP address')
param publicIpResourceId string

@description('Key Vault secret ID for the SSL certificate')
@secure()
param sslCertificateKeyVaultSecretId string

@description('Base64-encoded trusted client CA certificate data')
@secure()
param trustedClientCertificateData string

@description('APIM backend FQDN')
param apimBackendFqdn string

@description('Host name for the mTLS listener')
param mtlsHostName string

@description('Tags for resources')
param tags object = {}

// ============================================================================
// Variables
// ============================================================================

// Build the Application Gateway resource ID manually to avoid cycles
var applicationGatewayId = '/subscriptions/${subscription().subscriptionId}/resourceGroups/${resourceGroup().name}/providers/Microsoft.Network/applicationGateways/${name}'

// Frontend configuration names
var frontendIpConfigurationName = 'appGwPublicFrontendIp'
var frontendPortHttpsName = 'port443'
var frontendPortMtlsName = 'port8443'

// Backend configuration names
var backendPoolName = 'apimBackendPool'
var backendHttpSettingsName = 'apimBackendHttpSettings'

// SSL certificate names
var sslCertificateName = 'appGwSslCertificate'
var trustedClientCertificateName = 'mtlsClientCaCertificate'

// SSL profile name
var sslProfileName = 'mtlsSslProfile'

// Listener names
var apimListenerName = 'apimListener'
var mtlsListenerName = 'mtlsListener'

// Routing rule names
var apimRoutingRuleName = 'apimRule'
var mtlsRoutingRuleName = 'mtlsRule'

// Rewrite rule set names
var mtlsRewriteRuleSetName = 'mtlsRewriteRuleSet'

// Health probe name
var healthProbeName = 'apimHealthProbe'

// Gateway IP configuration name
var gatewayIpConfigurationName = 'appGwIpConfiguration'

// ============================================================================
// Application Gateway Resource
// ============================================================================

resource applicationGateway 'Microsoft.Network/applicationGateways@2023-11-01' = {
  name: name
  location: location
  tags: tags
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${userAssignedIdentityResourceId}': {}
    }
  }
  properties: {
    sku: {
      name: sku
      tier: sku
    }
    autoscaleConfiguration: {
      minCapacity: 1
      maxCapacity: 10
    }
    enableHttp2: true
    firewallPolicy: sku == 'WAF_v2' && !empty(wafPolicyResourceId) ? { id: wafPolicyResourceId } : null
    gatewayIPConfigurations: [
      {
        name: gatewayIpConfigurationName
        properties: {
          subnet: {
            id: subnetResourceId
          }
        }
      }
    ]
    frontendIPConfigurations: [
      {
        name: frontendIpConfigurationName
        properties: {
          publicIPAddress: {
            id: publicIpResourceId
          }
        }
      }
    ]
    frontendPorts: [
      {
        name: frontendPortHttpsName
        properties: {
          port: 443
        }
      }
      {
        name: frontendPortMtlsName
        properties: {
          port: 8443
        }
      }
    ]
    sslCertificates: [
      {
        name: sslCertificateName
        properties: {
          keyVaultSecretId: sslCertificateKeyVaultSecretId
        }
      }
    ]
    trustedClientCertificates: [
      {
        name: trustedClientCertificateName
        properties: {
          data: trustedClientCertificateData
        }
      }
    ]
    sslProfiles: [
      {
        name: sslProfileName
        properties: {
          trustedClientCertificates: [
            {
              id: '${applicationGatewayId}/trustedClientCertificates/${trustedClientCertificateName}'
            }
          ]
          clientAuthConfiguration: {
            verifyClientCertIssuerDN: true
            verifyClientRevocation: 'None'
          }
          sslPolicy: {
            policyType: 'Custom'
            minProtocolVersion: 'TLSv1_2'
            cipherSuites: [
              'TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384'
              'TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256'
            ]
          }
        }
      }
    ]
    backendAddressPools: [
      {
        name: backendPoolName
        properties: {
          backendAddresses: [
            {
              fqdn: apimBackendFqdn
            }
          ]
        }
      }
    ]
    backendHttpSettingsCollection: [
      {
        name: backendHttpSettingsName
        properties: {
          port: 443
          protocol: 'Https'
          cookieBasedAffinity: 'Disabled'
          pickHostNameFromBackendAddress: true
          requestTimeout: 30
          probe: {
            id: '${applicationGatewayId}/probes/${healthProbeName}'
          }
        }
      }
    ]
    probes: [
      {
        name: healthProbeName
        properties: {
          protocol: 'Https'
          path: '/status-0123456789abcdef'
          interval: 30
          timeout: 30
          unhealthyThreshold: 3
          pickHostNameFromBackendHttpSettings: true
          minServers: 0
          match: {
            statusCodes: [
              '200-399'
            ]
          }
        }
      }
    ]
    httpListeners: [
      {
        name: apimListenerName
        properties: {
          frontendIPConfiguration: {
            id: '${applicationGatewayId}/frontendIPConfigurations/${frontendIpConfigurationName}'
          }
          frontendPort: {
            id: '${applicationGatewayId}/frontendPorts/${frontendPortHttpsName}'
          }
          protocol: 'Https'
          sslCertificate: {
            id: '${applicationGatewayId}/sslCertificates/${sslCertificateName}'
          }
          requireServerNameIndication: false
        }
      }
      {
        name: mtlsListenerName
        properties: {
          frontendIPConfiguration: {
            id: '${applicationGatewayId}/frontendIPConfigurations/${frontendIpConfigurationName}'
          }
          frontendPort: {
            id: '${applicationGatewayId}/frontendPorts/${frontendPortMtlsName}'
          }
          protocol: 'Https'
          sslCertificate: {
            id: '${applicationGatewayId}/sslCertificates/${sslCertificateName}'
          }
          sslProfile: {
            id: '${applicationGatewayId}/sslProfiles/${sslProfileName}'
          }
          hostName: mtlsHostName
          requireServerNameIndication: true
        }
      }
    ]
    rewriteRuleSets: [
      {
        name: mtlsRewriteRuleSetName
        properties: {
          rewriteRules: [
            {
              name: 'AddClientCertHeader'
              ruleSequence: 100
              conditions: []
              actionSet: {
                requestHeaderConfigurations: [
                  {
                    headerName: 'X-Client-Cert-Header'
                    headerValue: '{var_client_certificate}'
                  }
                ]
                responseHeaderConfigurations: []
              }
            }
          ]
        }
      }
    ]
    requestRoutingRules: [
      {
        name: apimRoutingRuleName
        properties: {
          priority: 100
          ruleType: 'Basic'
          httpListener: {
            id: '${applicationGatewayId}/httpListeners/${apimListenerName}'
          }
          backendAddressPool: {
            id: '${applicationGatewayId}/backendAddressPools/${backendPoolName}'
          }
          backendHttpSettings: {
            id: '${applicationGatewayId}/backendHttpSettingsCollection/${backendHttpSettingsName}'
          }
        }
      }
      {
        name: mtlsRoutingRuleName
        properties: {
          priority: 200
          ruleType: 'Basic'
          httpListener: {
            id: '${applicationGatewayId}/httpListeners/${mtlsListenerName}'
          }
          backendAddressPool: {
            id: '${applicationGatewayId}/backendAddressPools/${backendPoolName}'
          }
          backendHttpSettings: {
            id: '${applicationGatewayId}/backendHttpSettingsCollection/${backendHttpSettingsName}'
          }
          rewriteRuleSet: {
            id: '${applicationGatewayId}/rewriteRuleSets/${mtlsRewriteRuleSetName}'
          }
        }
      }
    ]
  }
}

// ============================================================================
// Outputs
// ============================================================================

@description('Resource ID of the Application Gateway')
output resourceId string = applicationGateway.id

@description('Name of the Application Gateway')
output name string = applicationGateway.name

@description('Frontend public IP configuration ID')
output frontendIpConfigurationId string = '${applicationGateway.id}/frontendIPConfigurations/${frontendIpConfigurationName}'

@description('mTLS listener ID')
output mtlsListenerId string = '${applicationGateway.id}/httpListeners/${mtlsListenerName}'

@description('mTLS routing rule ID')
output mtlsRoutingRuleId string = '${applicationGateway.id}/requestRoutingRules/${mtlsRoutingRuleName}'

@description('mTLS rewrite rule set ID')
output mtlsRewriteRuleSetId string = '${applicationGateway.id}/rewriteRuleSets/${mtlsRewriteRuleSetName}'

@description('SSL profile ID')
output sslProfileId string = '${applicationGateway.id}/sslProfiles/${sslProfileName}'
