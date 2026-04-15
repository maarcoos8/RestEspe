from typing import List, Optional

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from app.db.session import get_db

from app import crud
from app.models.establecimiento import Establecimiento
from app.schemas.establecimiento import (
    EstablecimientoOut,
    EstablecimientoCreate,
    EstablecimientoUpdate,
)

router = APIRouter(prefix="/establecimiento", tags=["Establecimiento"])


@router.get("/", response_model=List[EstablecimientoOut])
def leer_establecimientos(skip: int = 0, limit: int = 100, db: Session = Depends(get_db)):
    return crud.crud_establecimiento.get_establecimientos(db, skip=skip, limit=limit)


@router.get("/{id}", response_model=EstablecimientoOut)
def leer_establecimiento(id: int, db: Session = Depends(get_db)):
    obj = crud.crud_establecimiento.get_establecimiento(db, id)
    if not obj:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Establecimiento no encontrado")
    return obj


@router.post("/", response_model=EstablecimientoOut, status_code=status.HTTP_201_CREATED)
def crear_establecimiento(
    establecimiento_in: EstablecimientoCreate,
    verificador_id: Optional[int] = None,
    db: Session = Depends(get_db),
):
    return crud.crud_establecimiento.create_establecimiento(db, establecimiento_in, verificador_id=verificador_id)


@router.put("/{id}", response_model=EstablecimientoOut)
def actualizar_establecimiento(
    id: int, establecimiento_in: EstablecimientoUpdate, db: Session = Depends(get_db)
):
    db_obj = crud.crud_establecimiento.get_establecimiento(db, id)
    if not db_obj:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Establecimiento no encontrado")
    return crud.crud_establecimiento.update_establecimiento(db, db_obj, establecimiento_in)


@router.delete("/{id}", response_model=EstablecimientoOut)
def eliminar_establecimiento(id: int, db: Session = Depends(get_db)):
    obj = crud.crud_establecimiento.remove_establecimiento(db, id)
    if not obj:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Establecimiento no encontrado")
    return obj