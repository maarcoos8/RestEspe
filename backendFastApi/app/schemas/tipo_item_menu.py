from typing import Optional

from pydantic import BaseModel, ConfigDict


class TipoItemMenuBase(BaseModel):
    id_establecimiento: int
    nombre_tipo: str


class TipoItemMenuCreate(TipoItemMenuBase):
    pass


class TipoItemMenuUpdate(BaseModel):
    id_establecimiento: Optional[int] = None
    nombre_tipo: Optional[str] = None


class TipoItemMenuOut(TipoItemMenuBase):
    id_tipo_item: int

    model_config = ConfigDict(from_attributes=True)
