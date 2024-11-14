/*
This Bicep template deploys a User Assigned Managed Identity and configures a federated credential for GitHub Actions.

Parameters:
- servicePrincipalName (string): The name of the User Assigned Managed Identity.
- environment (string): The environment name (e.g., 'dev', 'prod') to be used in the federated credential.
- githubRepo (string): The GitHub repository in the format 'owner/repo'.
- location (string, optional): The Azure region where the resources will be deployed. Default is 'uksouth'.

Resources:
- spApp: Deploys a User Assigned Managed Identity.
- sp: Assigns the Contributor role to the User Assigned Managed Identity.
- federatedCredential: Configures a federated credential for GitHub Actions to authenticate using the User Assigned Managed Identity.

Outputs:
- clientId (string): The client ID of the User Assigned Managed Identity.
- tenantId (string): The tenant ID of the Azure subscription.
*/
param servicePrincipalName string
param environment string
param githubRepo string
param location string = 'uksouth'

resource spApp 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-07-31-preview' = {
  name: servicePrincipalName
  location: location
}

resource sp 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(subscription().id, resourceGroup().id, servicePrincipalName)
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'b24988ac-6180-42a0-ab88-20f7382dd24c') // Contributor role ID
    principalId: spApp.properties.principalId
  }
}

resource federatedCredential 'Microsoft.ManagedIdentity/userAssignedIdentities/federatedIdentityCredentials@2023-07-31-preview' = {
  parent: spApp
  name: 'GitHubFederatedCredential-${environment}'
  properties: {

    issuer: 'https://token.actions.githubusercontent.com'
    subject: 'repo:${githubRepo}:environment:${environment}'
    audiences: [
      'api://AzureADTokenExchange'
    ]
  }
}

output clientId string = spApp.properties.clientId
output tenantId string = subscription().tenantId
