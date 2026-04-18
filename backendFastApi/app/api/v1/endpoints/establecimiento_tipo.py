from typing import List

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app import crud
from app.db.session import get_db
from app.schemas.establecimiento_tipo import EstablecimientoTipoCreate, EstablecimientoTipoOut

router = APIRouter(prefix="/establecimiento_tipo", tags=["EstablecimientoTipo"])


@router.get("/", response_model=List[EstablecimientoTipoOut])
def leer_relaciones(db: Session = Depends(get_db)):
    return crud.crud_establecimiento_tipo.get_establecimiento_tipos(db)


@router.get("/establecimiento/{id_establecimiento}", response_model=List[EstablecimientoTipoOut])
def leer_tipos_por_establecimiento(id_establecimiento: int, db: Session = Depends(get_db)):
    return crud.crud_establecimiento_tipo.get_tipos_por_establecimiento(db, id_establecimiento)


@router.get("/tipo/{id_tipo_establecimiento}", response_model=List[EstablecimientoTipoOut])
def leer_establecimientos_por_tipo(id_tipo_establecimiento: int, db: Session = Depends(get_db)):
    return crud.crud_establecimiento_tipo.get_establecimientos_por_tipo(db, id_tipo_establecimiento)


@router.post("/", response_model=EstablecimientoTipoOut, status_code=status.HTTP_201_CREATED)
def crear_relacion(rel_in: EstablecimientoTipoCreate, db: Session = Depends(get_db)):
    try:
        return crud.crud_establecimiento_tipo.create_establecimiento_tipo(
            db,
            rel_in.id_establecimiento,
            rel_in.id_tipo_establecimiento,
        )
    except ValueError as e:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(e))


@router.delete("/establecimiento/{id_establecimiento}/tipo/{id_tipo_establecimiento}", response_model=EstablecimientoTipoOut)
def eliminar_relacion(id_establecimiento: int, id_tipo_establecimiento: int, db: Session = Depends(get_db)):
    obj = crud.crud_establecimiento_tipo.remove_establecimiento_tipo(
        db,
        id_establecimiento,
        id_tipo_establecimiento,
    )
    if not obj:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Relacion no encontrada")
    return obj
