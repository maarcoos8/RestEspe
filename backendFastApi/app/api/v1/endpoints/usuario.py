from typing import List

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app import crud
from app.db.session import get_db
from app.schemas.usuario import UsuarioOut, UsuarioUpdate

router = APIRouter(prefix="/usuario", tags=["Usuario"])


@router.get("/", response_model=List[UsuarioOut])
def leer_usuarios(db: Session = Depends(get_db)):
    return crud.crud_usuario.get_usuarios(db)


@router.put("/{id_usuario}", response_model=UsuarioOut)
def actualizar_usuario(id_usuario: int, usuario_in: UsuarioUpdate, db: Session = Depends(get_db)):
    db_obj = crud.crud_usuario.get_usuario(db, id_usuario)
    if not db_obj:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Usuario no encontrado")
    return crud.crud_usuario.update_usuario(db, db_obj, usuario_in)


@router.delete("/{id_usuario}", response_model=UsuarioOut)
def eliminar_usuario(id_usuario: int, db: Session = Depends(get_db)):
    obj = crud.crud_usuario.remove_usuario(db, id_usuario)
    if not obj:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Usuario no encontrado")
    return obj
