param pydanticVersionPostfix string
param functionAppNamePrefix string = 'pydanticfunctionapp'
param eventGridTopicNamePrefix string = 'pydanticeventgridtopic'


var functionAppName = '${functionAppNamePrefix}${pydanticVersionPostfix}${substring(uniqueString(resourceGroup().id), 4)}'
var eventGridTopicName = '${eventGridTopicNamePrefix}${pydanticVersionPostfix}${substring(uniqueString(resourceGroup().id), 4)}'
var eventHandlerFunctionName = 'eventHandlerPydantic${pydanticVersionPostfix}'
var eventGridSubscriptionName = 'eventSubscriptionPydantic${pydanticVersionPostfix}'

resource functionApp 'Microsoft.Web/sites@2021-03-01' existing = {
  name: functionAppName
}

resource eventGridTopic 'Microsoft.EventGrid/topics@2021-06-01-preview' existing = {
  name: eventGridTopicName
}

resource eventHandlerFunction 'Microsoft.Web/sites/functions@2022-03-01' existing = {
  name: eventHandlerFunctionName
  parent: functionApp
}


resource eventSubscription 'Microsoft.EventGrid/topics/eventSubscriptions@2022-06-15' = {
  name: eventGridSubscriptionName
  parent: eventGridTopic
  properties: {
    destination: {
      endpointType: 'AzureFunction'
      properties: {
        resourceId: eventHandlerFunction.id
        maxEventsPerBatch: 1
      }
    }
    eventDeliverySchema: 'EventGridSchema'
    retryPolicy: {
      maxDeliveryAttempts: 30
      eventTimeToLiveInMinutes: 1440
    }
  }
}
