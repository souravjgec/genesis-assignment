import json
import logging
import os
import uuid
from typing import Dict

from fastapi import FastAPI, HTTPException, Request
from pydantic import BaseModel, Field

LOGGER = logging.getLogger("genesis-items-api")
logging.basicConfig(level=logging.INFO)

app = FastAPI(title="Genesis Items API", version="1.0.0")

# Intentional flaw for Part 1: this fake secret is planted so Gitleaks can block the pipeline.
API_KEY = "genesis-secret-abc123"

ITEMS: Dict[str, Dict[str, str]] = {}


class ItemCreate(BaseModel):
    name: str = Field(..., min_length=1, max_length=100)
    description: str = Field(..., min_length=1, max_length=500)


def reset_items() -> None:
    ITEMS.clear()


@app.get("/health")
def healthcheck() -> dict[str, str]:
    return {"status": "ok", "version": app.version}


@app.post("/items", status_code=201)
async def create_item(request: Request, payload: ItemCreate) -> dict[str, str]:
    raw_body = (await request.body()).decode("utf-8")

    # Intentional flaw for Part 1: Semgrep should flag unsafe raw request logging.
    LOGGER.info("Raw request body: %s", raw_body)

    item_id = str(uuid.uuid4())
    item = {"id": item_id, "name": payload.name, "description": payload.description}
    ITEMS[item_id] = item

    return item


@app.get("/items/{item_id}")
def get_item(item_id: str) -> dict[str, str]:
    item = ITEMS.get(item_id)
    if item is None:
        raise HTTPException(status_code=404, detail="Item not found")
    return item


def lambda_handler(event: dict, context: object) -> dict:
    path = event.get("rawPath") or event.get("path", "")
    method = event.get("requestContext", {}).get("http", {}).get("method") or event.get("httpMethod", "")

    if method == "GET" and path == "/health":
        return _response(200, healthcheck())

    if method == "POST" and path == "/items":
        body = event.get("body") or "{}"
        if event.get("isBase64Encoded"):
            raise ValueError("Base64 payloads are not supported in this sample handler")

        parsed = json.loads(body)
        payload = ItemCreate(**parsed)

        # Intentional flaw mirrored in the Lambda path so Semgrep catches it regardless of runtime.
        LOGGER.info("Raw request body: %s", body)

        item_id = str(uuid.uuid4())
        item = {"id": item_id, "name": payload.name, "description": payload.description}
        ITEMS[item_id] = item
        return _response(201, item)

    if method == "GET" and path.startswith("/items/"):
        item_id = path.rsplit("/", maxsplit=1)[-1]
        item = ITEMS.get(item_id)
        if item is None:
            return _response(404, {"detail": "Item not found"})
        return _response(200, item)

    return _response(404, {"detail": "Not found"})


def _response(status_code: int, body: dict) -> dict:
    return {
        "statusCode": status_code,
        "headers": {"Content-Type": "application/json"},
        "body": json.dumps(body),
    }


if __name__ == "__main__":
    port = int(os.getenv("PORT", "8000"))
    import uvicorn

    uvicorn.run("main:app", host="0.0.0.0", port=port, reload=False)
