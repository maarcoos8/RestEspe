from pydantic import BaseModel, ConfigDict


class CategoriaDietaConteoOut(BaseModel):
	id_categoria: int
	nombre_dieta: str
	color_hex: str
	cantidad_platos: int
	total_platos: int

	model_config = ConfigDict(from_attributes=True)