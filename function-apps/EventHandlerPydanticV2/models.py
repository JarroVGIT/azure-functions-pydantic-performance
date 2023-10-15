from pydantic import BaseModel
from pydantic.types import UUID
from pydantic.networks import HttpUrl
from datetime import datetime

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