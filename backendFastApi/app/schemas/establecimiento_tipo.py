from pydantic import BaseModel, ConfigDict


class EstablecimientoTipoCreate(BaseModel):
    id_establecimiento: int
    id_tipo_establecimiento: int


class EstablecimientoTipoOut(BaseModel):
    id_establecimiento: int
    id_tipo_establecimiento: int

    model_config = ConfigDict(from_attributes=True)
