from datetime import datetime
from typing import Optional

from pydantic import BaseModel, ConfigDict


class EstablecimientoFiltroOut(BaseModel):
    id_establecimiento: int
    nombre: str
    direccion_texto: Optional[str] = None
    latitud: Optional[float] = None
    longitud: Optional[float] = None
    estado_verificado: Optional[bool] = False
    ultima_verificacion: Optional[datetime] = None
    verificador_id: Optional[int] = None
    puntuacion_media: Optional[float] = None

    model_config = ConfigDict(from_attributes=True)


class PuntuacionMediaOut(BaseModel):
    id_establecimiento: int
    puntuacion_media: Optional[float] = None
    numero_resenas: int = 0

    model_config = ConfigDict(from_attributes=True)
