param location string = 'westeurope'
param eventGridTopicNamePrefix string = 'pydanticeventgridtopic'
param functionAppNamePrefix string = 'pydanticfunctionapp'
param hostingAppPlanNamePrefix string = 'pydanticappplan'
param functionStorageAccountNamePrefix string = 'sapydanticperf'
param appInsightsNamePrefix string = 'pydanticappinsights'
param functionStorageAccountSku string = 'Standard_LRS'
param functionStorageAccountKind string = 'StorageV2'
param pydanticVersionPostfix string

// Put together the names for the resources
var hostingAppPlanName = '${hostingAppPlanNamePrefix}${pydanticVersionPostfix}'
var appInsightsName = '${appInsightsNamePrefix}${pydanticVersionPostfix}'

// FunctionApp name, Storage Account name and Event Grid Topic name need to be globally unique
var eventGridTopicName = '${eventGridTopicNamePrefix}${pydanticVersionPostfix}${substring(uniqueString(resourceGroup().id), 4)}'
var functionAppName = '${functionAppNamePrefix}${pydanticVersionPostfix}${substring(uniqueString(resourceGroup().id), 4)}'
var storageaccountnamefull = '${functionStorageAccountNamePrefix}${pydanticVersionPostfix}${uniqueString(resourceGroup().id)}'
var functionStorageAccountName = substring(storageaccountnamefull, 0, min(length(storageaccountnamefull), 24))


resource eventGridTopic 'Microsoft.EventGrid/topics@2021-06-01-preview' = {
  name: eventGridTopicName
  location: location
  sku: {
    name: 'Basic'
  }
}

resource functionStorageAccount 'Microsoft.Storage/storageAccounts@2022-05-01' = {
  name: functionStorageAccountName
  location: location
  sku: {
    name: functionStorageAccountSku
  }
  kind: functionStorageAccountKind
  properties: {
    supportsHttpsTrafficOnly: true
    defaultToOAuthAuthentication: true
  }
}

resource hostingAppPlan 'Microsoft.Web/serverfarms@2021-03-01' = {
  name: hostingAppPlanName
  location: location
  kind: 'linux'
  sku: {
    name: 'Y1'
    tier: 'Dynamic'
  }
  properties: {
    reserved: true
  }
}

resource functionApp 'Microsoft.Web/sites@2021-03-01' = {
  name: functionAppName
  location: location
  kind: 'functionapp'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: hostingAppPlan.id
    siteConfig: {
      pythonVersion: '3.10'
      appSettings: [
        {
          name: 'AzureWebJobsStorage'
          value: 'DefaultEndpointsProtocol=https;AccountName=${functionStorageAccountName};EndpointSuffix=${environment().suffixes.storage};AccountKey=${functionStorageAccount.listKeys().keys[0].value}'
        }
        {
          name: 'WEBSITE_CONTENTAZUREFILECONNECTIONSTRING'
          value: 'DefaultEndpointsProtocol=https;AccountName=${functionStorageAccountName};EndpointSuffix=${environment().suffixes.storage};AccountKey=${functionStorageAccount.listKeys().keys[0].value}'
        }
        {
          name: 'WEBSITE_CONTENTSHARE'
          value: toLower(functionAppName)
        }
        {
          name: 'FUNCTIONS_EXTENSION_VERSION'
          value: '~4'
        }
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: appInsights.properties.InstrumentationKey
        }
        {
          name: 'FUNCTIONS_WORKER_RUNTIME'
          value: 'python'
        }
        {
          name: 'WEBSITE_RUN_FROM_PACKAGE'
          value: '1'
        }
        {
          name: 'AzureWebJobsFeatureFlags'
          value: 'EnableWorkerIndexing'
        }
        
      ]

      linuxFxVersion:'Python|3.10'
    }
    httpsOnly: true
  }
}

resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: appInsightsName
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    Request_Source: 'rest'
  }
}

output functionAppName string = functionApp.name
output functionAppId string = functionApp.id
output eventgridTopicEndpoint string = eventGridTopic.properties.endpoint
output evengridTopicId string = eventGridTopic.id
