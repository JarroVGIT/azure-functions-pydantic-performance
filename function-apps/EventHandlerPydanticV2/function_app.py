import azure.functions as func
import logging
from pydantic import ValidationError
from models import EventData

app = func.FunctionApp()

@app.function_name(name="eventHandlerPydanticv2")
@app.event_grid_trigger(arg_name="event")
def eventGridTest(event: func.EventGridEvent):
    logging.info(f'processing_{event.subject}')
    try:
        event_validated = EventData(**event.get_json())
    except ValidationError:
        logging.error("Event data is not valid")
        return

    logging.info(f'V2 Function processed: {event_validated.model_dump()}')


