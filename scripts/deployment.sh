if ! command -v jq &> /dev/null
then
    echo "jq is required but could not be found. "
    return 1
fi

if ! command -v az &> /dev/null
then
    echo "The AZ CLI is required but could not be found."
    return 1
fi

if ! command -v func &> /dev/null
then
    echo "The Azure Functions Core Tools are required but could not be found."
    return 1
fi

if [[ "$VIRTUAL_ENV" == "" ]]
then
    echo "A virtual environment is required but could not be found."
    return 1
fi


RESOURCEGROUP_NAME=pydantic-event-functions
LOCATION=westeurope

current_subscription=$(az account show --query name -o tsv)
echo "Current subscription: $current_subscription"

# Create the resource group
echo "Creating resource group..."

az group create -n $RESOURCEGROUP_NAME -l $LOCATION
result=$?
if [ $result -ne 0 ]; then
    echo "Failed to create resource group"
    return $result
fi

# Deploy the infrastructure
echo "Deploying infrastructure..."

az deployment group create \
    --resource-group $RESOURCEGROUP_NAME \
    --template-file ./azure-infrastructure/create-infra.bicep

result=$?
if [ $result -ne 0 ]; then
    echo "Failed to deploy infrastructure"
    return $result
fi

# Deploy the functions
echo "Deploying functions..."
functionappv1=$(az functionapp list --resource-group $RESOURCEGROUP_NAME --query "[?contains(name, 'pydanticfunctionappv1')].name" -o tsv)
functionappv2=$(az functionapp list --resource-group $RESOURCEGROUP_NAME --query "[?contains(name, 'pydanticfunctionappv2')].name" -o tsv)

cd ./function-apps/EventHandlerPydanticV1/
func azure functionapp publish $functionappv1
result=$?
if [ $result -ne 0 ]; then
    echo "Failed to deploy Function 1"
    return $result
fi

cd ../EventHandlerPydanticV2/
func azure functionapp publish $functionappv2
result=$?
if [ $result -ne 0 ]; then
    echo "Failed to deploy Function 2"
    return $result
fi

# Deploy the event grid subscription
cd ../..
echo "Deploying event grid subscription..."

az deployment group create \
    --resource-group $RESOURCEGROUP_NAME \
    --template-file ./azure-infrastructure/create-subscription.bicep

result=$?
if [ $result -ne 0 ]; then
    echo "Failed to deploy Event Grid subscription"
    return $result
fi

# Setting environment variables for the test script
echo "Setting environment variables for the test script..."
export RESOURCEGROUP_NAME=$RESOURCEGROUP_NAME
export EVENTGRID_ENDPOINT_V1=$(az eventgrid topic list --query "[?resourceGroup=='$RESOURCEGROUP_NAME'] | [?contains(endpoint, 'topicv1')].endpoint" -o tsv)
export EVENTGRID_ENDPOINT_V2=$(az eventgrid topic list --query "[?resourceGroup=='$RESOURCEGROUP_NAME'] | [?contains(endpoint, 'topicv2')].endpoint" -o tsv)
topicv1=$(az eventgrid topic list --query "[?resourceGroup=='$RESOURCEGROUP_NAME'] | [?contains(endpoint, 'topicv1')].name" -o tsv)
export EVENTGRID_TOPIC_KEY_V1=$(az eventgrid topic key list --name $topicv1 -g $RESOURCEGROUP_NAME --query key1 -o tsv)
topicv2=$(az eventgrid topic list --query "[?resourceGroup=='$RESOURCEGROUP_NAME'] | [?contains(endpoint, 'topicv2')].name" -o tsv)
export EVENTGRID_TOPIC_KEY_V2=$(az eventgrid topic key list --name $topicv2 -g $RESOURCEGROUP_NAME --query key1 -o tsv)

echo "Start sending events..."
python ./scripts/send_events.py

echo "Complete, check the AppInsights instance for the results!"
