from typing import List

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
from sqlalchemy import select
from sqlalchemy import func as sa_func

router = APIRouter(prefix="/establecimiento", tags=["Establecimiento"])


@router.get("/", response_model=List[EstablecimientoOut])
def leer_establecimientos(skip: int = 0, limit: int = 100, db: Session = Depends(get_db)):
    # Fast path: normal behaviour
    # Query DB explicitly for ST_X/ST_Y to ensure lat/long are returned
    stmt = (
        select(
            Establecimiento.id_establecimiento,
            Establecimiento.nombre,
            Establecimiento.direccion_texto,
            sa_func.ST_X(Establecimiento.coordenadas).label("longitud"),
            sa_func.ST_Y(Establecimiento.coordenadas).label("latitud"),
            Establecimiento.estado_verificado,
            Establecimiento.ultima_verificacion,
            Establecimiento.verificador_id,
        )
        .offset(skip)
        .limit(limit)
    )
    rows = db.execute(stmt).all()
    result = []
    for r in rows:
        result.append(
            {
                "id_establecimiento": r.id_establecimiento,
                "nombre": r.nombre,
                "direccion_texto": r.direccion_texto,
                "latitud": float(r.latitud) if r.latitud is not None else None,
                "longitud": float(r.longitud) if r.longitud is not None else None,
                "estado_verificado": r.estado_verificado,
                "ultima_verificacion": r.ultima_verificacion,
                "verificador_id": r.verificador_id,
            }
        )
    return result


@router.get("/{id}", response_model=EstablecimientoOut)
def leer_establecimiento(id: int, db: Session = Depends(get_db)):
    stmt = select(
        Establecimiento.id_establecimiento,
        Establecimiento.nombre,
        Establecimiento.direccion_texto,
        sa_func.ST_X(Establecimiento.coordenadas).label("longitud"),
        sa_func.ST_Y(Establecimiento.coordenadas).label("latitud"),
        Establecimiento.estado_verificado,
        Establecimiento.ultima_verificacion,
        Establecimiento.verificador_id,
    ).where(Establecimiento.id_establecimiento == id)

    row = db.execute(stmt).first()
    if not row:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Establecimiento no encontrado")
    return {
        "id_establecimiento": row.id_establecimiento,
        "nombre": row.nombre,
        "direccion_texto": row.direccion_texto,
        "latitud": float(row.latitud) if row.latitud is not None else None,
        "longitud": float(row.longitud) if row.longitud is not None else None,
        "estado_verificado": row.estado_verificado,
        "ultima_verificacion": row.ultima_verificacion,
        "verificador_id": row.verificador_id,
    }


@router.post("/", response_model=EstablecimientoOut, status_code=status.HTTP_201_CREATED)
def crear_establecimiento(establecimiento_in: EstablecimientoCreate, db: Session = Depends(get_db)):
    return crud.crud_establecimiento.create_establecimiento(db, establecimiento_in)


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