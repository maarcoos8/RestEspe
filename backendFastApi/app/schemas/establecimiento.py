from pydantic import BaseModel
from pydantic import ConfigDict
from typing import Optional
from datetime import datetime


class EstablecimientoBase(BaseModel):
	nombre: str
	direccion_texto: Optional[str] = None
	latitud: Optional[float] = None
	longitud: Optional[float] = None
	estado_verificado: Optional[bool] = False
	ultima_verificacion: Optional[datetime] = None
	verificador_id: Optional[int] = None


class EstablecimientoCreate(EstablecimientoBase):
	pass


class EstablecimientoUpdate(BaseModel):
	nombre: Optional[str] = None
	direccion_texto: Optional[str] = None
	latitud: Optional[float] = None
	longitud: Optional[float] = None
	estado_verificado: Optional[bool] = None
	ultima_verificacion: Optional[datetime] = None
	verificador_id: Optional[int] = None


class EstablecimientoOut(EstablecimientoBase):
	id_establecimiento: int

	model_config = ConfigDict(from_attributes=True)
