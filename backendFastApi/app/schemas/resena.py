from pydantic import BaseModel, field_validator, ConfigDict
from typing import Optional
from datetime import datetime


def _validate_puntuacion(value: float) -> float:
    try:
        v = float(value)
    except Exception:
        raise ValueError("puntuacion must be a number")
    if v < 0 or v > 5:
        raise ValueError("puntuacion must be between 0 and 5")
    # allow halves: multiply by 2 should be integer
    if abs(round(v * 2) - (v * 2)) > 1e-8:
        raise ValueError("puntuacion must be an integer or half (.5) step")
    return v


class ResenaBase(BaseModel):
    id_usuario: int
    id_establecimiento: int
    puntuacion: float
    comentario: Optional[str] = None
    url_imagen: Optional[str] = None

    @field_validator("puntuacion")
    def check_puntuacion(cls, v):
        return _validate_puntuacion(v)


class ResenaCreate(ResenaBase):
    pass


class ResenaUpdate(BaseModel):
    puntuacion: Optional[float] = None
    comentario: Optional[str] = None
    url_imagen: Optional[str] = None

    @field_validator("puntuacion")
    def check_puntuacion(cls, v):
        if v is None:
            return v
        return _validate_puntuacion(v)


class ResenaOut(ResenaBase):
    id_resena: int
    fecha_publicacion: Optional[datetime] = None

    model_config = ConfigDict(from_attributes=True)
