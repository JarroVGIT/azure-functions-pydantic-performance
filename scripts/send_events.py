from azure.core.credentials import AzureKeyCredential
from azure.eventgrid import EventGridPublisherClient, EventGridEvent
from pydantic import BaseModel
from pydantic.types import UUID
from pydantic.networks import HttpUrl
from datetime import datetime
import pytz
import uuid
import random
import os

# Create a basemodel for EventGrid event
class NestedModel(BaseModel):
    nested_i: int
    nested_str: str

class EventData(BaseModel):
    event_i: int
    eventdata_guid: UUID
    eventdata_str: str
    eventdata_nested: NestedModel
    eventdata_url: HttpUrl
    eventdata_dt: datetime



# Create list of 1000 events 
events_v1 = []
events_v2 = []
for i in range(1000):
    nested = NestedModel(nested_i=i, nested_str=f"nested_{i}")
    eventdata = EventData(
        event_i=i,
        eventdata_guid=uuid.uuid4(),
        eventdata_str=f"eventdata_str_{i}",
        eventdata_nested=nested,
        eventdata_url=f"https://www.example{i}.com",
        eventdata_dt=datetime.now(tz=pytz.UTC)
    )

    events_v1.append(EventGridEvent(
        data=eventdata.dict(),
        subject=f"pydantic_v1_{i}",
        event_type="PydanticV1Event",
        data_version="2.0"
    ))
    events_v2.append(EventGridEvent(
        data = eventdata.dict(),
        subject=f"pydantic_v2_{i}",
        event_type="PydanticV2Event",
        data_version="2.0"
    ))

random_idx = random.choices(range(1000), k=50)

wrong_event_data = {
    "event_i": "wrong",
    "eventdata_guid": "wrong",
    "eventdata_str": "wrong",
    "eventdata_nested": "wrong",
    "eventdata_url": "wrong",
    "eventdata_dt": "wrong"
}
for idx in random_idx:
    events_v1[idx].data = wrong_event_data
    events_v2[idx].data = wrong_event_data

endpoint_v1 = os.environ.get("EVENTGRID_ENDPOINT_V1")
endpoint_v2 = os.environ.get("EVENTGRID_ENDPOINT_V2")
topic_key_v1 = os.environ.get("EVENTGRID_TOPIC_KEY_V1")
topic_key_v2 = os.environ.get("EVENTGRID_TOPIC_KEY_V2")

#send V1 events
print("Sending events to V1 endpoint")
credential = AzureKeyCredential(topic_key_v1)
client = EventGridPublisherClient(endpoint_v1, credential)
client.send(events_v1)

#send V2 events
print("Sending events to V2 endpoint")
credential = AzureKeyCredential(topic_key_v2)
client = EventGridPublisherClient(endpoint_v2, credential)
client.send(events_v2)

print("Done sending events!")

