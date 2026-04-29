from typing import List

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app import crud
from app.db.session import get_db
from app.schemas.establecimiento import EstablecimientoOut
from app.schemas.usuario_establecimiento_favorito import (
    UsuarioEstablecimientoFavoritoCreate,
    UsuarioEstablecimientoFavoritoOut,
)

router = APIRouter(prefix="/usuario_establecimiento_favorito", tags=["UsuarioEstablecimientoFavorito"])


@router.get("/", response_model=List[UsuarioEstablecimientoFavoritoOut])
def leer_favoritos(db: Session = Depends(get_db)):
    return crud.crud_usuario_establecimiento_favorito.get_favoritos(db)


@router.get("/usuario/{id_usuario}", response_model=List[EstablecimientoOut])
def leer_favoritos_por_usuario(id_usuario: int, db: Session = Depends(get_db)):
    return crud.crud_usuario_establecimiento_favorito.get_establecimientos_favoritos_por_usuario(db, id_usuario)


@router.post("/", response_model=UsuarioEstablecimientoFavoritoOut, status_code=status.HTTP_201_CREATED)
def crear_favorito(favorito_in: UsuarioEstablecimientoFavoritoCreate, db: Session = Depends(get_db)):
    try:
        return crud.crud_usuario_establecimiento_favorito.create_favorito(
            db,
            favorito_in.id_usuario,
            favorito_in.id_establecimiento,
        )
    except ValueError as e:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(e))


@router.delete(
    "/usuario/{id_usuario}/establecimiento/{id_establecimiento}",
    response_model=UsuarioEstablecimientoFavoritoOut,
)
def eliminar_favorito(id_usuario: int, id_establecimiento: int, db: Session = Depends(get_db)):
    obj = crud.crud_usuario_establecimiento_favorito.remove_favorito(db, id_usuario, id_establecimiento)
    if not obj:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Favorito no encontrado")
    return obj