@description('Azure region for network resources.')
param location string

param projectName string
param environment string
param tags object

var vnetName = 'vnet-${projectName}-${environment}-bicep'
var nsgName = 'nsg-${projectName}-${environment}-workload'
var workloadSubnetName = 'snet-workload'

resource workloadNsg 'Microsoft.Network/networkSecurityGroups@2024-05-01' = {
  name: nsgName
  location: location
  tags: tags
}

resource vnet 'Microsoft.Network/virtualNetworks@2024-05-01' = {
  name: vnetName
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.20.0.0/16'
      ]
    }
    subnets: [
      {
        name: workloadSubnetName
        properties: {
          addressPrefix: '10.20.1.0/24'
          networkSecurityGroup: {
            id: workloadNsg.id
          }
          serviceEndpoints: [
            {
              service: 'Microsoft.KeyVault'
            }
            {
              service: 'Microsoft.Storage'
            }
          ]
        }
      }
    ]
  }
}

output workloadSubnetId string = '${vnet.id}/subnets/${workloadSubnetName}'
