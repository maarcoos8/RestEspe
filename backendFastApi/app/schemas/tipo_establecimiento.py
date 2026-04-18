from typing import Optional

from pydantic import BaseModel, ConfigDict


class TipoEstablecimientoBase(BaseModel):
    nombre_categoria: str


class TipoEstablecimientoCreate(TipoEstablecimientoBase):
    pass


class TipoEstablecimientoUpdate(BaseModel):
    nombre_categoria: Optional[str] = None


class TipoEstablecimientoOut(TipoEstablecimientoBase):
    id_tipo_establecimiento: int

    model_config = ConfigDict(from_attributes=True)
