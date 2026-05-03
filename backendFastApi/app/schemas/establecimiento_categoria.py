from pydantic import BaseModel, ConfigDict


class EstablecimientoCategoriaCreate(BaseModel):
    id_establecimiento: int
    id_categoria: int


class EstablecimientoCategoriaOut(BaseModel):
    id_establecimiento: int
    id_categoria: int
    nombre_dieta: str

    model_config = ConfigDict(from_attributes=True)
