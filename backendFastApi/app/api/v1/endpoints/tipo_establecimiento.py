from typing import List

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app import crud
from app.db.session import get_db
from app.schemas.tipo_establecimiento import (
    TipoEstablecimientoCreate,
    TipoEstablecimientoOut,
    TipoEstablecimientoUpdate,
)

router = APIRouter(prefix="/tipo_establecimiento", tags=["TipoEstablecimiento"])


@router.get("/", response_model=List[TipoEstablecimientoOut])
def leer_tipos_establecimiento(db: Session = Depends(get_db)):
    return crud.crud_tipo_establecimiento.get_tipos_establecimiento(db)


@router.get("/{id}", response_model=TipoEstablecimientoOut)
def leer_tipo_establecimiento(id: int, db: Session = Depends(get_db)):
    obj = crud.crud_tipo_establecimiento.get_tipo_establecimiento(db, id)
    if not obj:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Tipo establecimiento no encontrado")
    return obj


@router.post("/", response_model=TipoEstablecimientoOut, status_code=status.HTTP_201_CREATED)
def crear_tipo_establecimiento(tipo_in: TipoEstablecimientoCreate, db: Session = Depends(get_db)):
    return crud.crud_tipo_establecimiento.create_tipo_establecimiento(db, tipo_in)


@router.put("/{id}", response_model=TipoEstablecimientoOut)
def actualizar_tipo_establecimiento(id: int, tipo_in: TipoEstablecimientoUpdate, db: Session = Depends(get_db)):
    db_obj = crud.crud_tipo_establecimiento.get_tipo_establecimiento(db, id)
    if not db_obj:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Tipo establecimiento no encontrado")
    return crud.crud_tipo_establecimiento.update_tipo_establecimiento(db, db_obj, tipo_in)


@router.delete("/{id}", response_model=TipoEstablecimientoOut)
def eliminar_tipo_establecimiento(id: int, db: Session = Depends(get_db)):
    obj = crud.crud_tipo_establecimiento.remove_tipo_establecimiento(db, id)
    if not obj:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Tipo establecimiento no encontrado")
    return obj
