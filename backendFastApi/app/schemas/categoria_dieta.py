from pydantic import BaseModel, ConfigDict
from typing import Optional


class CategoriaDietaBase(BaseModel):
    nombre_dieta: str
    color_hex: Optional[str] = None


class CategoriaDietaCreate(CategoriaDietaBase):
    pass


class CategoriaDietaUpdate(BaseModel):
    nombre_dieta: Optional[str] = None
    color_hex: Optional[str] = None


class CategoriaDietaOut(CategoriaDietaBase):
    id_categoria: int
    color_hex: str

    model_config = ConfigDict(from_attributes=True)
