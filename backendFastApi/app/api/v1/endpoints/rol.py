from typing import List

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.db.session import get_db
from app import crud
from app.schemas.rol import RolOut, RolCreate, RolUpdate

router = APIRouter(prefix="/rol", tags=["Rol"])


@router.get("/", response_model=List[RolOut])
def leer_roles(db: Session = Depends(get_db)):
    return crud.crud_rol.get_roles(db)


@router.get("/{id}", response_model=RolOut)
def leer_rol(id: int, db: Session = Depends(get_db)):
    obj = crud.crud_rol.get_rol(db, id)
    if not obj:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Rol no encontrado")
    return obj


@router.post("/", response_model=RolOut, status_code=status.HTTP_201_CREATED)
def crear_rol(rol_in: RolCreate, db: Session = Depends(get_db)):
    return crud.crud_rol.create_rol(db, rol_in)


@router.put("/{id}", response_model=RolOut)
def actualizar_rol(id: int, rol_in: RolUpdate, db: Session = Depends(get_db)):
    db_obj = crud.crud_rol.get_rol(db, id)
    if not db_obj:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Rol no encontrado")
    return crud.crud_rol.update_rol(db, db_obj, rol_in)


@router.delete("/{id}", response_model=RolOut)
def eliminar_rol(id: int, db: Session = Depends(get_db)):
    obj = crud.crud_rol.remove_rol(db, id)
    if not obj:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Rol no encontrado")
    return obj
