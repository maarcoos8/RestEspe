from pydantic import BaseModel
from pydantic import ConfigDict
from typing import Optional


class RolBase(BaseModel):
    nombre_rol: str


class RolCreate(RolBase):
    pass


class RolUpdate(BaseModel):
    nombre_rol: Optional[str] = None


class RolOut(RolBase):
    id_rol: int

    model_config = ConfigDict(from_attributes=True)
