import logging
import os
import uuid
from typing import Dict

from fastapi import FastAPI, HTTPException, Request
from mangum import Mangum
from pydantic import BaseModel, Field

LOGGER = logging.getLogger("genesis-items-api")
logging.basicConfig(level=logging.INFO)

app = FastAPI(title="Genesis Items API", version="1.0.0")



ITEMS: Dict[str, Dict[str, str]] = {}


class ItemCreate(BaseModel):
    name: str = Field(..., min_length=1, max_length=100)
    description: str = Field(..., min_length=1, max_length=500)


def reset_items() -> None:
    ITEMS.clear()


def emit_items_created_metric() -> None:
    namespace = os.getenv("ITEMS_METRIC_NS")
    metric_name = os.getenv("ITEMS_METRIC_NAME")
    function_name = os.getenv("AWS_LAMBDA_FUNCTION_NAME")

    if not namespace or not metric_name or not function_name:
        return

    try:
        import boto3

        boto3.client("cloudwatch").put_metric_data(
            Namespace=namespace,
            MetricData=[
                {
                    "MetricName": metric_name,
                    "Value": 1,
                    "Unit": "Count",
                    "Dimensions": [
                        {
                            "Name": "FunctionName",
                            "Value": function_name,
                        }
                    ],
                }
            ],
        )
    except Exception:
        LOGGER.exception("Failed to publish items-created metric")


@app.get("/health")
def healthcheck() -> dict[str, str]:
    return {"status": "ok", "version": app.version}


@app.post("/items", status_code=201)
async def create_item(request: Request, payload: ItemCreate) -> dict[str, str]:
    await request.body()

    item_id = str(uuid.uuid4())
    item = {"id": item_id, "name": payload.name, "description": payload.description}
    ITEMS[item_id] = item
    emit_items_created_metric()

    return item


@app.get("/items")
def list_items() -> list[dict[str, str]]:
    return list(ITEMS.values())


@app.get("/items/{item_id}")
def get_item(item_id: str) -> dict[str, str]:
    item = ITEMS.get(item_id)
    if item is None:
        raise HTTPException(status_code=404, detail="Item not found")
    return item

handler = Mangum(app)


if __name__ == "__main__":
    port = int(os.getenv("PORT", "8000"))
    import uvicorn

    uvicorn.run("main:app", host="0.0.0.0", port=port, reload=False)
