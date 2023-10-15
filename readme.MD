## Pydantic V1 vs Pydantic V2 performance test in Azure Functions
This project was created to get a feel about the real-world performance improvement in Pydantic V2 compared to Pydantic V1. To read more about Pydantic and the major V2 release, please look [here](https://docs.pydantic.dev/latest/blog/pydantic-v2-final/).

# But... why?
Pydantic is widely used within the world of Python for data validation. There are tons of great use cases in which you can (and in some cases, maybe even should) use this open source package library if you want to assert that data is in the right format. One example of this is validating incoming event messages and their payload. If you have some piece of software that executes when an events happens, you typically are very much interested in the data of that event. Pydantic allows you to write `models` that will automatically validate that data (typically coming in as JSON). 

There are crazy performance improvements numbers thrown around when it comes to Pydantic V2. In essence this boils down to the fact that the entire core is rewritten in Rust. But what about real-life scenario's? That was the main reason to start this project (and to open source it); to perform some real-life scenario in which Pydantic can be used.

# Alright, what's this scenario you keep going on about?
The scenario is quite straight forward; I want to (roughly)  know what the performance difference is between an Azure Function that handles events on an Azure Event Grid topic, if the Function is using Pydantic V1 or Pydantic V2 to validate the events. 

To do this, we will need an Event Grid topic, with a subscription that triggers an Azure Function on each event. Also, an Application Insight instance where we can pull our run data from. To eliminate possible caching on the Azure side, we are going to deploy all resources seperately for both runs (V1 and V2 runs). 

# How do I repeat this test? 
To repeat this test, you can just run deploy.sh. Before you do that, make sure that:
- You have a virtual environment active, with the dependencies installed as per `requirements.txt`
- `az cli` installed and pointing to the correct Azure Subscription

Running `source deploy.sh` will:
- Deploy the infrastructure in one resource group;
- Build the Function Apps and deploy them;
- Deploy Event Grid subscriptions for the Functions;
- Runs a small python script that sends 1000 identical events to the two topics.

After the Python script has sent 1000 events, wait a minute or two for Azure to properly handle all logging in the Application Insights. Then go ahead and run the following query:
```
let invalid_data_traces=
traces
| where message startswith "Event data is not valid"
// where timestamp > ago(2hr)
| project operation_Id, state="invalid";
let valid_data_traces=
traces
| where message startswith "processing_pydantic_v"
| where timestamp > ago(2hr)
| join kind=leftanti (invalid_data_traces) on operation_Id
| project operation_Id, state="valid";
let execution_times=
traces
| where message startswith "Executed"
//| where timestamp > ago(2hr)
| project operation_Id, duration=toint(customDimensions.prop__executionDuration);
invalid_data_traces
| union valid_data_traces
| join kind=leftouter (execution_times) on operation_Id
| summarize avg(duration) by state
```
Small note on this: Azure logging is not always accurate. You might notice you are missing logging entries, or that the count of events handled are not exactly a 1000. It doesn't really matter for the purpose of this project though. 

If you ran the python script multiple times, you want to take into account only the last run. You might want to add `| where timestamp > ago(<time>)` to the above query. I've left comments on where you want to do that

# Is this a realistic test? 
To be honest, I am no expert in performance testing. I just wanted to know how this would hold up. The functions themselves are *almost* identical; pydanticV2 uses `BaseModel.model_dump()` to generate JSON where are pydanticV1 uses `BaseModel.dict()`. As this is native to both versions (and feature-wise comparable), I don't see this as a problem.


# Does this work on Apple Silicon?
Well, yes.. but actually no. The `func core tools` of Microsoft (used to deploy the Function Apps in this project) are not compatible (yet?) with Apple Silicon. However, you can run bits and pieces in `rosetta`. In the end, I created this project on Apple Silicon, but it took me a full reinstall of my Macbook because I made a mess of it. If you want to know how to do this, open an Issue and I will walk you through it (or at least how I solved it, the internet is full of clues but no straight forward walk through).

# That all sounds great but what was the outcome?
I almost forgot, here are my results:
| Average Execution Time | Pydantic V1 | Pydantic V2 |
|------------------------|-------------|-------------|
| Valid payload          | 189         | 118         |
| Invalid payload        | 282         | 268         |

That is a whopping 37% decrease in execution time. Note that this is the full Function call, where the Pydantic operations are just a part of it. Very impressive imo. 