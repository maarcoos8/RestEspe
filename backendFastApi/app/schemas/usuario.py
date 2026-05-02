from typing import Optional

from pydantic import BaseModel, ConfigDict


class UsuarioBase(BaseModel):
    email: str
    nombre_completo: Optional[str] = None
    fotoPerfil: Optional[str] = None
    id_rol: Optional[int] = None


class UsuarioCreate(UsuarioBase):
    pass


class UsuarioUpdate(BaseModel):
    email: Optional[str] = None
    nombre_completo: Optional[str] = None
    fotoPerfil: Optional[str] = None
    id_rol: Optional[int] = None


class UsuarioOut(UsuarioBase):
    id_usuario: int

    model_config = ConfigDict(from_attributes=True)