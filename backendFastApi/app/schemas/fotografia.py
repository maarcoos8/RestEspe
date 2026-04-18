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
