from app.db import database, models

stores =  sorted(database.generate_store_db(), key=lambda d: d['id']) #always return sorted by id
products = database.generate_product_db()
inventory = database.generate_inventory_db()

#store
def all_stores():
    return stores

def store_by_id(id: int):
    for store in stores:
        if store['id'] == id:
            return store
    return {}

def add_new_store(store: models.Store):
    new_id = stores[-1]['id'] + 1
    new_store = {
        "id": new_id,
        "name": store.name,
        "address": store.address
    }
    return stores.append(new_store)

def delete_store(id: int):
    if id <= 0:
        raise IndexError
    try:    
        for store in stores:
            if store['id'] == id:
                stores.remove(store)
    except:
        raise

def all_products():
    return products


