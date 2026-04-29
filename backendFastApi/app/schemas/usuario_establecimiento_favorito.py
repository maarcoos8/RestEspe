from pydantic import BaseModel, ConfigDict


class UsuarioEstablecimientoFavoritoCreate(BaseModel):
    id_usuario: int
    id_establecimiento: int


class UsuarioEstablecimientoFavoritoOut(BaseModel):
    id_usuario: int
    id_establecimiento: int

    model_config = ConfigDict(from_attributes=True)