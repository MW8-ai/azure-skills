targetScope = 'subscription'

@description('Azure region for the lab resources.')
param location string = 'eastus2'

@minLength(3)
@maxLength(12)
@description('Short project identifier used in resource names.')
param projectName string = 'iaclab'

@allowed([
  'dev'
  'test'
  'prod'
])
@description('Deployment environment.')
param environment string = 'dev'

@description('Owner tag applied to resources.')
param owner string = 'MW8-ai'

var uniqueSuffix = uniqueString(subscription().id, projectName, environment, 'bicep')
var resourceGroupName = 'rg-${projectName}-${environment}-bicep'
var tags = {
  application: projectName
  environment: environment
  owner: owner
  managedBy: 'bicep'
  purpose: 'portfolio-iac-lab'
}

resource labResourceGroup 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: resourceGroupName
  location: location
  tags: tags
}

module network './modules/network.bicep' = {
  scope: labResourceGroup
  params: {
    location: location
    projectName: projectName
    environment: environment
    tags: tags
  }
}

module observability './modules/observability.bicep' = {
  scope: labResourceGroup
  params: {
    location: location
    projectName: projectName
    environment: environment
    tags: tags
  }
}

module identityData './modules/identity-data.bicep' = {
  scope: labResourceGroup
  params: {
    location: location
    projectName: projectName
    environment: environment
    uniqueSuffix: uniqueSuffix
    workloadSubnetId: network.outputs.workloadSubnetId
    logAnalyticsWorkspaceId: observability.outputs.workspaceId
    tags: tags
  }
}

output resourceGroupName string = labResourceGroup.name
output managedIdentityPrincipalId string = identityData.outputs.managedIdentityPrincipalId
output storageAccountName string = identityData.outputs.storageAccountName
output keyVaultName string = identityData.outputs.keyVaultName
