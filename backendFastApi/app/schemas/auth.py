from pydantic import BaseModel

from app.schemas.usuario import UsuarioOut


class GoogleAuthIn(BaseModel):
    id_token: str


class GoogleAuthOut(UsuarioOut):
    pass