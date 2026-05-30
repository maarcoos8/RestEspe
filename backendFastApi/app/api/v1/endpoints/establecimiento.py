from typing import List, Optional

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.orm import Session
from app.db.session import get_db

from app import crud
from app.models.establecimiento import Establecimiento
from app.schemas.establecimiento import (
    EstablecimientoOut,
    EstablecimientoCreate,
    EstablecimientoUpdate,
)
from app.schemas.establecimiento_filtro import EstablecimientoFiltroOut, PuntuacionMediaOut
from sqlalchemy import select
from sqlalchemy import func as sa_func

router = APIRouter(prefix="/establecimiento", tags=["Establecimiento"])


@router.get("/filtrar", response_model=List[EstablecimientoFiltroOut])
def filtrar_establecimientos(
    latitud: Optional[float] = Query(default=None),
    longitud: Optional[float] = Query(default=None),
    distancia_metros: Optional[float] = Query(default=None, gt=0),
    tipo_establecimiento_ids: Optional[List[int]] = Query(default=None),
    nombre: Optional[str] = Query(default=None),
    categoria_dieta_ids: Optional[List[int]] = Query(default=None),
    propietario_id: Optional[int] = Query(default=None),
    solo_verificados: Optional[bool] = Query(default=None),
    puntuacion_media_minima: Optional[float] = Query(default=None, ge=0, le=5),
    skip: int = Query(default=0, ge=0),
    limit: int = Query(default=10, ge=1, le=100),
    db: Session = Depends(get_db),
):
    return crud.crud_establecimiento.get_establecimientos_filtrados(
        db,
        latitud=latitud,
        longitud=longitud,
        distancia_metros=distancia_metros,
        tipos_establecimiento_ids=tipo_establecimiento_ids,
        nombre=nombre,
        categorias_dieta_ids=categoria_dieta_ids,
        propietario_id=propietario_id,
        solo_verificados=solo_verificados,
        puntuacion_media_minima=puntuacion_media_minima,
        skip=skip,
        limit=limit,
    )


@router.get("/", response_model=List[EstablecimientoOut])
def leer_establecimientos(skip: int = 0, limit: int = 100, db: Session = Depends(get_db)):
    # Fast path: normal behaviour
    # Query DB explicitly for ST_X/ST_Y to ensure lat/long are returned
    stmt = (
        select(
            Establecimiento.id_establecimiento,
            Establecimiento.nombre,
            Establecimiento.direccion_texto,
            Establecimiento.imagen_url,
            sa_func.ST_X(Establecimiento.coordenadas).label("longitud"),
            sa_func.ST_Y(Establecimiento.coordenadas).label("latitud"),
            Establecimiento.estado_verificado,
            Establecimiento.ultima_verificacion,
            Establecimiento.verificador_id,
            Establecimiento.propietario_id,
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
                    "imagen_url": r.imagen_url,
                "latitud": float(r.latitud) if r.latitud is not None else None,
                "longitud": float(r.longitud) if r.longitud is not None else None,
                "estado_verificado": r.estado_verificado,
                "ultima_verificacion": r.ultima_verificacion,
                "verificador_id": r.verificador_id,
                "propietario_id": r.propietario_id,
            }
        )
    return result


@router.get("/{id}", response_model=EstablecimientoOut)
def leer_establecimiento(id: int, db: Session = Depends(get_db)):
    stmt = select(
        Establecimiento.id_establecimiento,
        Establecimiento.nombre,
        Establecimiento.direccion_texto,
        Establecimiento.imagen_url,
        sa_func.ST_X(Establecimiento.coordenadas).label("longitud"),
        sa_func.ST_Y(Establecimiento.coordenadas).label("latitud"),
        Establecimiento.estado_verificado,
        Establecimiento.ultima_verificacion,
        Establecimiento.verificador_id,
        Establecimiento.propietario_id,
    ).where(Establecimiento.id_establecimiento == id)

    row = db.execute(stmt).first()
    if not row:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Establecimiento no encontrado")
    return {
        "id_establecimiento": row.id_establecimiento,
        "nombre": row.nombre,
        "direccion_texto": row.direccion_texto,
        "imagen_url": row.imagen_url,
        "latitud": float(row.latitud) if row.latitud is not None else None,
        "longitud": float(row.longitud) if row.longitud is not None else None,
        "estado_verificado": row.estado_verificado,
        "ultima_verificacion": row.ultima_verificacion,
        "verificador_id": row.verificador_id,
        "propietario_id": row.propietario_id,
    }


@router.get("/{id}/puntuacion-media", response_model=PuntuacionMediaOut)
def puntuacion_media_establecimiento(id: int, db: Session = Depends(get_db)):
    obj = crud.crud_establecimiento.get_establecimiento(db, id)
    if not obj:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Establecimiento no encontrado")

    puntuacion = crud.crud_establecimiento.get_puntuacion_media_establecimiento(db, id)
    return {"id_establecimiento": id, **puntuacion}


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

    # Actualizar campos del establecimiento
    updated = crud.crud_establecimiento.update_establecimiento(db, db_obj, establecimiento_in)

    # Si se han enviado tipos en la petición, actualizarlos inteligentemente
    data = establecimiento_in.model_dump(exclude_unset=True)
    tipos_ids = data.get("tipos_establecimiento_ids")
    if tipos_ids is not None:
        try:
            crud.crud_establecimiento_tipo.update_tipos_establecimiento(db, id, tipos_ids)
        except Exception as e:
            # Si hay error actualizando tipos, devolver 400 con detalle
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(e))

    return updated


@router.delete("/{id}", response_model=EstablecimientoOut)
def eliminar_establecimiento(id: int, db: Session = Depends(get_db)):
    """Elimina un establecimiento y todas sus referencias en cascada.
    
    Esta operación eliminará:
    - Todas las relaciones establecimiento-tipo
    - Todas las relaciones establecimiento-categoria
    - Todos los favoritos del establecimiento
    - Todas las reseñas
    - Todos los items de menú
    - Todos los tipos de item de menú
    - Todas las fotografías
    - El establecimiento en sí
    
    NOTA: En un entorno de producción, se debe validar que el usuario tenga
    permisos para eliminar (superadmin o propietario del establecimiento).
    """
    obj = crud.crud_establecimiento.remove_establecimiento(db, id)
    if not obj:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Establecimiento no encontrado")
    return obj