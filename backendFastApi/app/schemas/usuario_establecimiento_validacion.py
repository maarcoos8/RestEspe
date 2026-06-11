from typing import Optional

from pydantic import BaseModel, ConfigDict, field_validator


class UsuarioEstablecimientoValidacionBase(BaseModel):
    id_usuario: int
    id_establecimiento: int
    valor: int

    @field_validator("valor")
    @classmethod
    def check_valor(cls, value: int) -> int:
        if value not in (-1, 1):
            raise ValueError("valor must be 1 for like or -1 for dislike")
        return value


class UsuarioEstablecimientoValidacionCreate(UsuarioEstablecimientoValidacionBase):
    pass


class UsuarioEstablecimientoValidacionOut(UsuarioEstablecimientoValidacionBase):
    model_config = ConfigDict(from_attributes=True)


class UsuarioEstablecimientoValidacionResumenOut(BaseModel):
    id_establecimiento: int
    likes: int = 0
    dislikes: int = 0
    current_user_vote: Optional[int] = None

    model_config = ConfigDict(from_attributes=True)