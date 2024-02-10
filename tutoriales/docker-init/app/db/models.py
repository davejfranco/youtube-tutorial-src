from typing import Optional
from pydantic import BaseModel, Field


class Store(BaseModel):
    id: Optional[int] = Field(None, description="Should be automatically asigned")
    name: str = Field(min_length=3, max_length=15)
    address: str = Field(min_length=3, max_length=300) #no optional, age range
    
class Product(BaseModel):
    id: int
    name: str = Field(min_length=3, max_length=15)
    Price: float = Field(None, gt=0, lt=1000)

class Inventory(BaseModel):
    store_id: int
    store_name: str
    product_id: int
    product_name: str
    count: int = Field(None, gt=0, lt=1000)
