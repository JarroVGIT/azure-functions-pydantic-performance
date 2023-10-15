/*
  This Bicep file is deployed *first* and creates for each test setup (v1 vs v2):
  - a function app
  - an event grid topic
  - an application insights instance
*/

param location string = 'westeurope'

module testsetupv1 'modules/test-setup.bicep' = {
  name: 'testsetupv1'
  params: {
    location: location
    pydanticVersionPostfix: 'v1'
  }
}

module testsetupv2 'modules/test-setup.bicep' = {
  name: 'testsetupv2'
  params: {
    location: location
    pydanticVersionPostfix: 'v2'
  }
}

output functionAppNamev1 string = testsetupv1.outputs.functionAppName
output functionAppNamev2 string = testsetupv2.outputs.functionAppName
output functionAppIdv1 string = testsetupv1.outputs.functionAppId
output functionAppIdv2 string = testsetupv2.outputs.functionAppId
output eventgridTopicIdv1 string = testsetupv1.outputs.evengridTopicId
output eventgridTopicIdv2 string = testsetupv2.outputs.evengridTopicId
output eventgridTopicEndpointv1 string = testsetupv1.outputs.eventgridTopicEndpoint
output eventgridTopicEndpointv2 string = testsetupv2.outputs.eventgridTopicEndpoint
