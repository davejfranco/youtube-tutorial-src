"""
This is the main entrypoint
"""
from fastapi import FastAPI, HTTPException

from .db import models
from .api import api

VERSION=0.1
app = FastAPI()


@app.get("/status", status_code=200)
def get_stores():
    """Return status"""
    return {"status":"healthy", "version":VERSION}

#Stores
@app.get("/stores")
def get_stores():
    """Return all the stores in the DB"""
    return api.all_stores()

@app.get("/stores/{store_id}")
def get_store(store_id: int):
    """Return the store by its ID"""
    req = api.store_by_id(store_id)
    if req != {}:
        return req
    raise HTTPException(status_code=404, detail="Store not found")

@app.post("/stores", status_code=201)
def add_store(store: models.Store):
    """Add a store to the DB"""
    try:
        api.add_new_store(store)
    except Exception as err:
        raise HTTPException(status_code=422, detail=err) from None


@app.delete("/stores/{store_id}", status_code=201)
def delete_store(store_id: int):
    """Delete store from the DB"""
    try:
        api.delete_store(store_id)
    except IndexError:
        raise HTTPException(status_code=404, detail="store not found") from None
    except Exception as err:
        raise HTTPException(status_code=422, detail=err) from None
