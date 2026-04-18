from typing import Optional

from pydantic import BaseModel, ConfigDict


class ItemMenuBase(BaseModel):
    nombre_item_menu: str
    descripcion: Optional[str] = None
    precio: float
    id_establecimiento: int
    id_tipo_item_menu: int


class ItemMenuCreate(ItemMenuBase):
    pass


class ItemMenuUpdate(BaseModel):
    nombre_item_menu: Optional[str] = None
    descripcion: Optional[str] = None
    precio: Optional[float] = None
    id_establecimiento: Optional[int] = None
    id_tipo_item_menu: Optional[int] = None


class ItemMenuOut(ItemMenuBase):
    id_item_menu: int

    model_config = ConfigDict(from_attributes=True)
