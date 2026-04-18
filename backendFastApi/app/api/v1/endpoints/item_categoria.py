from typing import List

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app import crud
from app.db.session import get_db
from app.schemas.item_categoria import ItemCategoriaCreate, ItemCategoriaOut

router = APIRouter(prefix="/item_categoria", tags=["ItemCategoria"])


@router.get("/", response_model=List[ItemCategoriaOut])
def leer_relaciones(db: Session = Depends(get_db)):
    return crud.crud_item_categoria.get_item_categorias(db)


@router.get("/item/{id_item_menu}", response_model=List[ItemCategoriaOut])
def leer_categorias_por_item(id_item_menu: int, db: Session = Depends(get_db)):
    return crud.crud_item_categoria.get_categorias_por_item(db, id_item_menu)


@router.get("/categoria/{id_categoria}", response_model=List[ItemCategoriaOut])
def leer_items_por_categoria(id_categoria: int, db: Session = Depends(get_db)):
    return crud.crud_item_categoria.get_items_por_categoria(db, id_categoria)


@router.post("/", response_model=ItemCategoriaOut, status_code=status.HTTP_201_CREATED)
def crear_relacion(rel_in: ItemCategoriaCreate, db: Session = Depends(get_db)):
    try:
        return crud.crud_item_categoria.create_item_categoria(db, rel_in.id_item_menu, rel_in.id_categoria)
    except ValueError as e:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(e))


@router.delete("/item/{id_item_menu}/categoria/{id_categoria}", response_model=ItemCategoriaOut)
def eliminar_relacion(id_item_menu: int, id_categoria: int, db: Session = Depends(get_db)):
    obj = crud.crud_item_categoria.remove_item_categoria(db, id_item_menu, id_categoria)
    if not obj:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Relacion no encontrada")
    return obj
