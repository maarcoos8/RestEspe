from typing import List

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app import crud
from app.db.session import get_db
from app.schemas.fotografia import FotografiaCreate, FotografiaOut, FotografiaUpdate

router = APIRouter(prefix="/fotografia", tags=["Fotografia"])


@router.get("/", response_model=List[FotografiaOut])
def leer_fotografias(db: Session = Depends(get_db)):
    return crud.crud_fotografia.get_fotografias(db)


@router.get("/establecimiento/{id_establecimiento}", response_model=List[FotografiaOut])
def leer_fotografias_por_establecimiento(id_establecimiento: int, db: Session = Depends(get_db)):
    return crud.crud_fotografia.get_fotografias_por_establecimiento(db, id_establecimiento)


@router.get("/{id}", response_model=FotografiaOut)
def leer_fotografia(id: int, db: Session = Depends(get_db)):
    obj = crud.crud_fotografia.get_fotografia(db, id)
    if not obj:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Fotografia no encontrada")
    return obj


@router.post("/", response_model=FotografiaOut, status_code=status.HTTP_201_CREATED)
def crear_fotografia(fotografia_in: FotografiaCreate, db: Session = Depends(get_db)):
    try:
        return crud.crud_fotografia.create_fotografia(db, fotografia_in)
    except ValueError as e:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(e))


@router.put("/{id}", response_model=FotografiaOut)
def actualizar_fotografia(id: int, fotografia_in: FotografiaUpdate, db: Session = Depends(get_db)):
    db_obj = crud.crud_fotografia.get_fotografia(db, id)
    if not db_obj:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Fotografia no encontrada")
    try:
        return crud.crud_fotografia.update_fotografia(db, db_obj, fotografia_in)
    except ValueError as e:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(e))


@router.delete("/{id}", response_model=FotografiaOut)
def eliminar_fotografia(id: int, db: Session = Depends(get_db)):
    obj = crud.crud_fotografia.remove_fotografia(db, id)
    if not obj:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Fotografia no encontrada")
    return obj