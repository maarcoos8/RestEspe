from pydantic import BaseModel, ConfigDict


class EstablecimientoCategoriaCreate(BaseModel):
    id_establecimiento: int
    id_categoria: int


class EstablecimientoCategoriaOut(BaseModel):
    id_establecimiento: int
    id_categoria: int

    model_config = ConfigDict(from_attributes=True)
