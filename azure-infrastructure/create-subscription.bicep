/*
  This Bicep file must be deployed after the initial infra deployment (create-infra.bicep)
  and after the deployment of the Functions. The Event Grid Topic Subscription created here 
  requires the Functions to be deployed.
*/

module subscriptionv1 'modules/function-subscription.bicep' = {
  name: 'subscriptionv1'
  params: {
    pydanticVersionPostfix: 'v1'
  }
}

module subscriptionv2 'modules/function-subscription.bicep' = {
  name: 'subscriptionv2'
  params: {
    pydanticVersionPostfix: 'v2'
  }
}
