import json
import random

def generate_store_db():
    with open('data/stores.json') as stream:
        return json.load(stream)

def generate_product_db():
    with open('data/products.json') as stream:
        return json.load(stream)

def generate_inventory_db(): 
    db = []
    inventory = {}
    stores = generate_store_db()
    products = generate_product_db()

    for store in stores:
        inventory['store_id'] = store['id']
        inventory['store_name'] = store['name']
        inv = []
        item = {}
        for product in products:
            item['product_id'] = product['id']
            item['product_name'] = product['name']
            item['count'] = random.randrange(1000)
            inv.append(item)
        inventory['inventory'] = inv
    db.append(inventory)
    return db


