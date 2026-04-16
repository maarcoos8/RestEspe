from typing import List

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.db.session import get_db
from app import crud
from app.schemas.resena import ResenaOut, ResenaCreate, ResenaUpdate

router = APIRouter(prefix="/resena", tags=["Resena"])


@router.get("/", response_model=List[ResenaOut])
def leer_resenas(db: Session = Depends(get_db)):
    return crud.crud_resena.get_resenas(db)


@router.get("/{id}", response_model=ResenaOut)
def leer_resena(id: int, db: Session = Depends(get_db)):
    obj = crud.crud_resena.get_resena(db, id)
    if not obj:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Resena no encontrada")
    return obj


@router.post("/", response_model=ResenaOut, status_code=status.HTTP_201_CREATED)
def crear_resena(resena_in: ResenaCreate, db: Session = Depends(get_db)):
    try:
        return crud.crud_resena.create_resena(db, resena_in)
    except ValueError as e:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(e))


@router.put("/{id}", response_model=ResenaOut)
def actualizar_resena(id: int, resena_in: ResenaUpdate, db: Session = Depends(get_db)):
    db_obj = crud.crud_resena.get_resena(db, id)
    if not db_obj:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Resena no encontrada")
    return crud.crud_resena.update_resena(db, db_obj, resena_in)


@router.delete("/{id}", response_model=ResenaOut)
def eliminar_resena(id: int, db: Session = Depends(get_db)):
    obj = crud.crud_resena.remove_resena(db, id)
    if not obj:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Resena no encontrada")
    return obj
