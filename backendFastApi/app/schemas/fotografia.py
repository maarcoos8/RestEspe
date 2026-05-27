from datetime import datetime
from typing import Optional

from pydantic import BaseModel, ConfigDict


class FotografiaBase(BaseModel):
    id_establecimiento: int
    id_usuario: int
    url_imagen: str


class FotografiaCreate(FotografiaBase):
    pass


class FotografiaUpdate(BaseModel):
    id_establecimiento: Optional[int] = None
    id_usuario: Optional[int] = None
    url_imagen: Optional[str] = None


class FotografiaOut(FotografiaBase):
    id_foto: int
    fecha_subida: Optional[datetime] = None

    model_config = ConfigDict(from_attributes=True)


class FotografiaWithUserOut(FotografiaBase):
    """Schema extendido que incluye información del usuario que subió la foto."""
    id_foto: int
    fecha_subida: Optional[datetime] = None
    nombre_usuario: Optional[str] = None
    foto_perfil: Optional[str] = None

    model_config = ConfigDict(from_attributes=True)

