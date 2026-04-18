from typing import List

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app import crud
from app.db.session import get_db
from app.schemas.item_menu import ItemMenuCreate, ItemMenuOut, ItemMenuUpdate

router = APIRouter(prefix="/item_menu", tags=["ItemMenu"])


@router.get("/", response_model=List[ItemMenuOut])
def leer_items_menu(db: Session = Depends(get_db)):
    return crud.crud_item_menu.get_items_menu(db)


@router.get("/{id}", response_model=ItemMenuOut)
def leer_item_menu(id: int, db: Session = Depends(get_db)):
    obj = crud.crud_item_menu.get_item_menu(db, id)
    if not obj:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Item menu no encontrado")
    return obj


@router.get("/establecimiento/{id_establecimiento}", response_model=List[ItemMenuOut])
def leer_items_menu_por_establecimiento(id_establecimiento: int, db: Session = Depends(get_db)):
    return crud.crud_item_menu.get_items_menu_por_establecimiento(db, id_establecimiento)


@router.post("/", response_model=ItemMenuOut, status_code=status.HTTP_201_CREATED)
def crear_item_menu(item_in: ItemMenuCreate, db: Session = Depends(get_db)):
    try:
        return crud.crud_item_menu.create_item_menu(db, item_in)
    except ValueError as e:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(e))


@router.put("/{id}", response_model=ItemMenuOut)
def actualizar_item_menu(id: int, item_in: ItemMenuUpdate, db: Session = Depends(get_db)):
    db_obj = crud.crud_item_menu.get_item_menu(db, id)
    if not db_obj:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Item menu no encontrado")
    try:
        return crud.crud_item_menu.update_item_menu(db, db_obj, item_in)
    except ValueError as e:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(e))


@router.delete("/{id}", response_model=ItemMenuOut)
def eliminar_item_menu(id: int, db: Session = Depends(get_db)):
    obj = crud.crud_item_menu.remove_item_menu(db, id)
    if not obj:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Item menu no encontrado")
    return obj
