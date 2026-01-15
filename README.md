# Bicep implementation for Application Gateway with mTLS Support

This Bicep example project deploys an Azure Application Gateway configured for mutual TLS (mTLS) authentication, forwarding traffic to an existing API Management (APIM) backend.

## Add some GitHub Copilot Agents

I started by importing the Bicep agent instructions from [https://github.com/github/awesome-copilot/tree/main/agents](https://github.com/github/awesome-copilot/tree/main/agents)

## Starting Copilot prompt

Then I used this prompt to generate the Bicep code:

```text
I need to create a fully bicep implementation of an Application Gateway.  The gateway will forward requests on to an existing APIM server, and will need to supply certificates in the rewrite rule.  An existing KeyVault will be used to store the certificate.  Please create bicep in the /infra/bicep folder that will do the following:
- Create an application gateway
- Upload a certificate to an Azure key vault
- Create an SSL profile in the AGW with the certificate 
- In an mTLS listener, the "Enable SSL profile" option needs to be the enabled and refer to the newly created SSL profile
- A new routing rule needs to be created for mTLS. All the properties are same as "apimRule" routing rule except the listener name, which will be the mTLS listener
- A new rewrite rule will be created to pass the certificate in the custom request header "X-Client-Cert-Header". It will pick the certificate from server variable and add it to this custom request header.
- The newly created rewrite rule will need to be mapped to the new routing rule.
```

I added a few follow up prompts to refine the resulting code and ended up with the following implementation.

---

## The Resulting ReadME and Code...:

## Features

- **Application Gateway with WAF_v2 SKU** - Includes Web Application Firewall support
- **SSL Certificate from Key Vault** - Server certificate stored securely in Azure Key Vault
- **SSL Profile for mTLS** - Configures client certificate authentication
- **mTLS Listener** - Validates client certificates against trusted CA
- **Rewrite Rules** - Passes client certificate to backend via X-Client-Cert-Header header
- **Routing Rules** - Routes traffic to APIM backend with certificate forwarding

## Prerequisites

1. **Azure Key Vault** - An existing Key Vault with:
   - Server SSL certificate (PFX format) stored as a secret
   - User-assigned managed identity with Key Vault Secrets User role

2. **Network Resources**:
   - Virtual Network with a dedicated subnet for Application Gateway
   - Public IP address (Standard SKU, Static allocation)

3. **API Management** - An existing APIM instance as the backend

4. **WAF Policy** (for WAF_v2 SKU) - An Application Gateway WAF policy

## Files

| File | Description |
|------|-------------|
| [main.bicep](./infra/bicep/main.bicep) | Main Application Gateway deployment |
| [main.bicepparam](./infra/bicep/main.bicepparam) | Sample parameters file |
| [keyVaultCertificate.bicep](./infra/bicep/keyVaultCertificate.bicep) | Module to upload certificates to Key Vault |
| [applicationGateway.bicep](./infra/bicep/applicationGateway.bicep) | Module to deploy the Application Gateway |

## Deployment

### Using Azure CLI

az deployment group create --resource-group rg-name --template-file main.bicep --parameters main.bicepparam

### Using PowerShell

New-AzResourceGroupDeployment -ResourceGroupName rg-name -TemplateFile main.bicep -TemplateParameterFile main.bicepparam

## Configuration Details

### Listeners

- apimListener (port 443) - Standard HTTPS traffic
- mtlsListener (port 8443) - mTLS with client certificate validation

### Routing Rules

- apimRule - Routes standard HTTPS to APIM
- mtlsRule - Routes mTLS traffic with certificate header rewrite

### Rewrite Rules

The AddClientCertHeader rewrite rule extracts the client certificate from the var_client_certificate server variable and adds it to the X-Client-Cert-Header request header.
