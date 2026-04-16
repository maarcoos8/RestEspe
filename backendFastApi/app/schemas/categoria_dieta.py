from pydantic import BaseModel, ConfigDict
from typing import Optional


class CategoriaDietaBase(BaseModel):
    nombre_dieta: str


class CategoriaDietaCreate(CategoriaDietaBase):
    pass


class CategoriaDietaUpdate(BaseModel):
    nombre_dieta: Optional[str] = None


class CategoriaDietaOut(CategoriaDietaBase):
    id_categoria: int

    model_config = ConfigDict(from_attributes=True)
