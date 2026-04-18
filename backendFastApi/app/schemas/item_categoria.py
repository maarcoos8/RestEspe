from pydantic import BaseModel, ConfigDict


class ItemCategoriaCreate(BaseModel):
    id_item_menu: int
    id_categoria: int


class ItemCategoriaOut(BaseModel):
    id_item_menu: int
    id_categoria: int

    model_config = ConfigDict(from_attributes=True)
