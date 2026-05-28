from typing import Optional, List

from pydantic import BaseModel, ConfigDict

from app.schemas.categoria_dieta import CategoriaDietaOut


class ItemMenuBase(BaseModel):
    nombre_item_menu: str
    descripcion: Optional[str] = None
    precio: float
    id_establecimiento: int
    id_tipo_item_menu: Optional[int] = None


class ItemMenuCreate(ItemMenuBase):
    id_categorias: Optional[List[int]] = None


class ItemMenuUpdate(BaseModel):
    nombre_item_menu: Optional[str] = None
    descripcion: Optional[str] = None
    precio: Optional[float] = None
    id_establecimiento: Optional[int] = None
    id_tipo_item_menu: Optional[int] = None
    id_categorias: Optional[List[int]] = None


class ItemMenuOut(ItemMenuBase):
    id_item_menu: int
    categorias: List[CategoriaDietaOut] = []

    model_config = ConfigDict(from_attributes=True)
