from datetime import datetime
from typing import List, Optional

from geoalchemy2.elements import WKTElement
from sqlalchemy import distinct, func
from sqlalchemy.orm import Session

from app.models.establecimiento import Establecimiento
from app.models.establecimiento_categoria import EstablecimientoCategoria
from app.models.establecimiento_tipo import EstablecimientoTipo
from app.models.resena import Resena
from app.schemas.establecimiento import EstablecimientoCreate, EstablecimientoUpdate


def _base_establecimiento_filtrado_query(db: Session):
    puntuacion_media_subq = (
        db.query(
            Resena.id_establecimiento.label("id_establecimiento"),
            func.avg(Resena.puntuacion).label("puntuacion_media"),
        )
        .group_by(Resena.id_establecimiento)
        .subquery()
    )

    query = (
        db.query(
            Establecimiento.id_establecimiento.label("id_establecimiento"),
            Establecimiento.nombre.label("nombre"),
            Establecimiento.direccion_texto.label("direccion_texto"),
            Establecimiento.imagen_url.label("imagen_url"),
            func.ST_Y(Establecimiento.coordenadas).label("latitud"),
            func.ST_X(Establecimiento.coordenadas).label("longitud"),
            Establecimiento.estado_verificado.label("estado_verificado"),
            Establecimiento.ultima_verificacion.label("ultima_verificacion"),
            Establecimiento.verificador_id.label("verificador_id"),
            Establecimiento.propietario_id.label("propietario_id"),
            puntuacion_media_subq.c.puntuacion_media.label("puntuacion_media"),
        )
        .outerjoin(
            puntuacion_media_subq,
            puntuacion_media_subq.c.id_establecimiento == Establecimiento.id_establecimiento,
        )
    )
    return query


def get_establecimiento(db: Session, id_establecimiento: int) -> Optional[Establecimiento]:
    return db.query(Establecimiento).filter(Establecimiento.id_establecimiento == id_establecimiento).first()


def get_establecimientos(db: Session, skip: int = 0, limit: int = 100) -> List[Establecimiento]:
    return db.query(Establecimiento).offset(skip).limit(limit).all()


def get_puntuacion_media_establecimiento(db: Session, id_establecimiento: int) -> dict:
    puntuacion_media, numero_resenas = (
        db.query(
            func.avg(Resena.puntuacion),
            func.count(Resena.id_resena),
        )
        .filter(Resena.id_establecimiento == id_establecimiento)
        .one()
    )
    return {
        "puntuacion_media": float(puntuacion_media) if puntuacion_media is not None else None,
        "numero_resenas": int(numero_resenas or 0),
    }


def get_establecimientos_filtrados(
    db: Session,
    latitud: Optional[float] = None,
    longitud: Optional[float] = None,
    distancia_metros: Optional[float] = None,
    tipos_establecimiento_ids: Optional[List[int]] = None,
    nombre: Optional[str] = None,
    categorias_dieta_ids: Optional[List[int]] = None,
    propietario_id: Optional[int] = None,
    skip: int = 0,
    limit: int = 100,
):
    query = _base_establecimiento_filtrado_query(db)

    if nombre:
        query = query.filter(Establecimiento.nombre.ilike(f"%{nombre}%"))

    if propietario_id is not None:
        query = query.filter(Establecimiento.propietario_id == propietario_id)

    if latitud is not None and longitud is not None and distancia_metros is not None:
        punto = func.ST_SetSRID(func.ST_MakePoint(longitud, latitud), 4326)
        query = query.filter(func.ST_DistanceSphere(Establecimiento.coordenadas, punto) <= distancia_metros)

    if tipos_establecimiento_ids:
        tipos_unicos = list(dict.fromkeys(tipos_establecimiento_ids))
        subquery_tipos = (
            db.query(EstablecimientoTipo.id_establecimiento)
            .filter(EstablecimientoTipo.id_tipo_establecimiento.in_(tipos_unicos))
            .group_by(EstablecimientoTipo.id_establecimiento)
            .having(func.count(distinct(EstablecimientoTipo.id_tipo_establecimiento)) == len(tipos_unicos))
        )
        query = query.filter(Establecimiento.id_establecimiento.in_(subquery_tipos))

    if categorias_dieta_ids:
        categorias_unicas = list(dict.fromkeys(categorias_dieta_ids))
        subquery_categorias = (
            db.query(EstablecimientoCategoria.id_establecimiento)
            .filter(EstablecimientoCategoria.id_categoria.in_(categorias_unicas))
            .group_by(EstablecimientoCategoria.id_establecimiento)
            .having(func.count(distinct(EstablecimientoCategoria.id_categoria)) == len(categorias_unicas))
        )
        query = query.filter(Establecimiento.id_establecimiento.in_(subquery_categorias))

    rows = query.order_by(Establecimiento.id_establecimiento.asc()).offset(skip).limit(limit).all()
    result = []
    for row in rows:
        result.append(
            {
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
                "puntuacion_media": float(row.puntuacion_media) if row.puntuacion_media is not None else None,
            }
        )
    return result


def create_establecimiento(
    db: Session, establecimiento_in: EstablecimientoCreate, verificador_id: Optional[int] = None
) -> Establecimiento:
    data = establecimiento_in.model_dump(exclude_unset=True)
    lat = data.pop("latitud", None)
    lon = data.pop("longitud", None)
    if lat is not None and lon is not None:
        # Use WKTElement to create a geometry value with SRID so SQLAlchemy stores it properly
        data["coordenadas"] = WKTElement(f"POINT({lon} {lat})", srid=4326)

    # Allow verificador_id to come either from the optional arg or from the request body
    body_verificador = data.get("verificador_id")
    verificador = verificador_id if verificador_id is not None else body_verificador
    if verificador is not None:
        data["verificador_id"] = verificador
        data["ultima_verificacion"] = datetime.utcnow()

    db_obj = Establecimiento(**data)
    db.add(db_obj)
    db.commit()
    db.refresh(db_obj)
    return db_obj


def update_establecimiento(
    db: Session, db_obj: Establecimiento, establecimiento_in: EstablecimientoUpdate
) -> Establecimiento:
    data = establecimiento_in.model_dump(exclude_unset=True)
    lat = data.pop("latitud", None)
    lon = data.pop("longitud", None)
    if lat is not None and lon is not None:
        db_obj.coordenadas = WKTElement(f"POINT({lon} {lat})", srid=4326)

    for field, value in data.items():
        setattr(db_obj, field, value)

    if "verificador_id" in data:
        db_obj.ultima_verificacion = datetime.utcnow()

    db.add(db_obj)
    db.commit()
    db.refresh(db_obj)
    return db_obj


def remove_establecimiento(db: Session, id_establecimiento: int) -> Optional[Establecimiento]:
    """Elimina un establecimiento y todas sus referencias en cascada.
    
    Elimina en el siguiente orden para evitar violaciones de FK:
    1. establecimiento_tipo
    2. establecimiento_categoria
    3. usuario_establecimiento_favorito
    4. resena
    5. item_menu
    6. tipo_item_menu
    7. fotografia
    8. establecimiento
    """
    obj = get_establecimiento(db, id_establecimiento)
    if not obj:
        return None
    
    # Eliminar referencias en cascada
    # 1. Eliminar relaciones establecimiento-tipo
    db.query(EstablecimientoTipo).filter(
        EstablecimientoTipo.id_establecimiento == id_establecimiento
    ).delete()
    
    # 2. Eliminar relaciones establecimiento-categoria
    db.query(EstablecimientoCategoria).filter(
        EstablecimientoCategoria.id_establecimiento == id_establecimiento
    ).delete()
    
    # 3. Eliminar favoritos del usuario
    from app.models.usuario_establecimiento_favorito import UsuarioEstablecimientoFavorito
    db.query(UsuarioEstablecimientoFavorito).filter(
        UsuarioEstablecimientoFavorito.id_establecimiento == id_establecimiento
    ).delete()
    
    # 4. Eliminar reseñas
    db.query(Resena).filter(
        Resena.id_establecimiento == id_establecimiento
    ).delete()
    
    # 5. Eliminar items de menú
    from app.models.item_menu import ItemMenu
    db.query(ItemMenu).filter(
        ItemMenu.id_establecimiento == id_establecimiento
    ).delete()
    
    # 6. Eliminar tipos de item de menú
    from app.models.tipo_item_menu import TipoItemMenu
    db.query(TipoItemMenu).filter(
        TipoItemMenu.id_establecimiento == id_establecimiento
    ).delete()
    
    # 7. Eliminar fotografías
    from app.models.fotografia import Fotografia
    db.query(Fotografia).filter(
        Fotografia.id_establecimiento == id_establecimiento
    ).delete()
    
    # 8. Finalmente, eliminar el establecimiento
    db.delete(obj)
    db.commit()
    
    return obj
