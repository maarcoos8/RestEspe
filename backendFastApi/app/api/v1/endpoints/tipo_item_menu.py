from typing import List

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app import crud
from app.db.session import get_db
from app.schemas.tipo_item_menu import TipoItemMenuCreate, TipoItemMenuOut, TipoItemMenuUpdate

router = APIRouter(prefix="/tipo_item_menu", tags=["TipoItemMenu"])


@router.get("/", response_model=List[TipoItemMenuOut])
def leer_tipos_item_menu(db: Session = Depends(get_db)):
    return crud.crud_tipo_item_menu.get_tipos_item_menu(db)


@router.get("/{id}", response_model=TipoItemMenuOut)
def leer_tipo_item_menu(id: int, db: Session = Depends(get_db)):
    obj = crud.crud_tipo_item_menu.get_tipo_item_menu(db, id)
    if not obj:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Tipo item menu no encontrado")
    return obj


@router.get("/establecimiento/{id_establecimiento}", response_model=List[TipoItemMenuOut])
def leer_tipos_item_menu_por_establecimiento(id_establecimiento: int, db: Session = Depends(get_db)):
    return crud.crud_tipo_item_menu.get_tipos_item_menu_por_establecimiento(db, id_establecimiento)


@router.post("/", response_model=TipoItemMenuOut, status_code=status.HTTP_201_CREATED)
def crear_tipo_item_menu(tipo_in: TipoItemMenuCreate, db: Session = Depends(get_db)):
    try:
        return crud.crud_tipo_item_menu.create_tipo_item_menu(db, tipo_in)
    except ValueError as e:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(e))


@router.put("/{id}", response_model=TipoItemMenuOut)
def actualizar_tipo_item_menu(id: int, tipo_in: TipoItemMenuUpdate, db: Session = Depends(get_db)):
    db_obj = crud.crud_tipo_item_menu.get_tipo_item_menu(db, id)
    if not db_obj:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Tipo item menu no encontrado")
    try:
        return crud.crud_tipo_item_menu.update_tipo_item_menu(db, db_obj, tipo_in)
    except ValueError as e:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(e))


@router.delete("/{id}", response_model=TipoItemMenuOut)
def eliminar_tipo_item_menu(id: int, db: Session = Depends(get_db)):
    obj = crud.crud_tipo_item_menu.remove_tipo_item_menu(db, id)
    if not obj:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Tipo item menu no encontrado")
    return obj
