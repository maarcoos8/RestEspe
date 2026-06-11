from datetime import datetime
from typing import Dict, List, Optional

from geoalchemy2.elements import WKTElement
from sqlalchemy import distinct, func
from sqlalchemy.orm import Session

from app.models.categoria_dieta import CategoriaDieta
from app.models.establecimiento import Establecimiento
from app.models.establecimiento_categoria import EstablecimientoCategoria
from app.models.establecimiento_tipo import EstablecimientoTipo
from app.models.item_categoria import ItemCategoria
from app.models.item_menu import ItemMenu
from app.models.resena import Resena
from app.models.usuario_establecimiento_validacion import UsuarioEstablecimientoValidacion
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
            Establecimiento.contacto.label("contacto"),
            Establecimiento.imagen_url.label("imagen_url"),
            func.ST_Y(Establecimiento.coordenadas).label("latitud"),
            func.ST_X(Establecimiento.coordenadas).label("longitud"),
            Establecimiento.estado_verificado.label("estado_verificado"),
            Establecimiento.ultima_verificacion.label("ultima_verificacion"),
            Establecimiento.verificador_id.label("verificador_id"),
            Establecimiento.responsable_id.label("responsable_id"),
            puntuacion_media_subq.c.puntuacion_media.label("puntuacion_media"),
        )
        .outerjoin(
            puntuacion_media_subq,
            puntuacion_media_subq.c.id_establecimiento == Establecimiento.id_establecimiento,
        )
    )
    return query, puntuacion_media_subq


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


def _get_categorias_con_conteo_query(db: Session, ids_establecimiento: Optional[List[int]] = None):
    total_platos_subq = (
        db.query(
            ItemMenu.id_establecimiento.label("id_establecimiento"),
            func.count(ItemMenu.id_item_menu).label("total_platos_menu"),
        )
        .group_by(ItemMenu.id_establecimiento)
        .subquery()
    )

    platos_categoria_subq = (
        db.query(
            ItemMenu.id_establecimiento.label("id_establecimiento"),
            ItemCategoria.id_categoria.label("id_categoria"),
            func.count(distinct(ItemMenu.id_item_menu)).label("platos_categoria"),
        )
        .join(ItemCategoria, ItemCategoria.id_item_menu == ItemMenu.id_item_menu)
        .group_by(ItemMenu.id_establecimiento, ItemCategoria.id_categoria)
        .subquery()
    )

    query = (
        db.query(
            platos_categoria_subq.c.id_establecimiento.label("id_establecimiento"),
            CategoriaDieta.id_categoria.label("id_categoria"),
            CategoriaDieta.nombre_dieta.label("nombre_dieta"),
            CategoriaDieta.color_hex.label("color_hex"),
            platos_categoria_subq.c.platos_categoria.label("platos_categoria"),
            func.coalesce(total_platos_subq.c.total_platos_menu, 0).label("total_platos_menu"),
        )
        .join(
            CategoriaDieta,
            CategoriaDieta.id_categoria == platos_categoria_subq.c.id_categoria,
        )
        .outerjoin(
            total_platos_subq,
            total_platos_subq.c.id_establecimiento == platos_categoria_subq.c.id_establecimiento,
        )
    )

    if ids_establecimiento:
        query = query.filter(platos_categoria_subq.c.id_establecimiento.in_(ids_establecimiento))

    return query.order_by(
        platos_categoria_subq.c.id_establecimiento.asc(),
        CategoriaDieta.nombre_dieta.asc(),
    )


def get_categorias_dieta_con_conteo_por_establecimiento(
    db: Session, id_establecimiento: int
) -> List[dict]:
    rows = _get_categorias_con_conteo_query(db, [id_establecimiento]).all()
    return [
        {
            "id_establecimiento": row.id_establecimiento,
            "id_categoria": row.id_categoria,
            "nombre_dieta": row.nombre_dieta,
            "color_hex": row.color_hex,
            "platos_categoria": int(row.platos_categoria or 0),
            "total_platos_menu": int(row.total_platos_menu or 0),
        }
        for row in rows
    ]


def get_categorias_dieta_con_conteo_por_establecimientos(
    db: Session, ids_establecimiento: List[int]
) -> Dict[int, List[dict]]:
    if not ids_establecimiento:
        return {}

    rows = _get_categorias_con_conteo_query(db, ids_establecimiento).all()
    resultado: Dict[int, List[dict]] = {}
    for row in rows:
        resultado.setdefault(row.id_establecimiento, []).append(
            {
                "id_establecimiento": row.id_establecimiento,
                "id_categoria": row.id_categoria,
                "nombre_dieta": row.nombre_dieta,
                "color_hex": row.color_hex,
                "platos_categoria": int(row.platos_categoria or 0),
                "total_platos_menu": int(row.total_platos_menu or 0),
            }
        )
    return resultado


def get_establecimientos_filtrados(
    db: Session,
    latitud: Optional[float] = None,
    longitud: Optional[float] = None,
    distancia_metros: Optional[float] = None,
    tipos_establecimiento_ids: Optional[List[int]] = None,
    nombre: Optional[str] = None,
    categorias_dieta_ids: Optional[List[int]] = None,
    responsable_id: Optional[int] = None,
    solo_verificados: Optional[bool] = None,
    puntuacion_media_minima: Optional[float] = None,
    skip: int = 0,
    limit: int = 100,
):
    query, puntuacion_media_subq = _base_establecimiento_filtrado_query(db)

    if nombre:
        query = query.filter(Establecimiento.nombre.ilike(f"%{nombre}%"))

    if responsable_id is not None:
        query = query.filter(Establecimiento.responsable_id == responsable_id)

    if solo_verificados:
        query = query.filter(Establecimiento.estado_verificado.is_(True))

    if latitud is not None and longitud is not None and distancia_metros is not None:
        punto = func.ST_SetSRID(func.ST_MakePoint(longitud, latitud), 4326)
        query = query.filter(func.ST_DistanceSphere(Establecimiento.coordenadas, punto) <= distancia_metros)

    if puntuacion_media_minima is not None:
        query = query.filter(
            func.coalesce(puntuacion_media_subq.c.puntuacion_media, 0) >= puntuacion_media_minima
        )

    if tipos_establecimiento_ids:
        tipos_unicos = list(dict.fromkeys(tipos_establecimiento_ids))
        subquery_tipos = (
            db.query(EstablecimientoTipo.id_establecimiento)
            .filter(EstablecimientoTipo.id_tipo_establecimiento.in_(tipos_unicos))
            .distinct()
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
    categorias_por_establecimiento = get_categorias_dieta_con_conteo_por_establecimientos(
        db, [row.id_establecimiento for row in rows]
    )
    result = []
    for row in rows:
        result.append(
            {
                "id_establecimiento": row.id_establecimiento,
                "nombre": row.nombre,
                "direccion_texto": row.direccion_texto,
                "contacto": row.contacto,
                "imagen_url": row.imagen_url,
                "latitud": float(row.latitud) if row.latitud is not None else None,
                "longitud": float(row.longitud) if row.longitud is not None else None,
                "estado_verificado": row.estado_verificado,
                "ultima_verificacion": row.ultima_verificacion,
                "verificador_id": row.verificador_id,
                "responsable_id": row.responsable_id,
                "puntuacion_media": float(row.puntuacion_media) if row.puntuacion_media is not None else None,
                "categorias_dieta": categorias_por_establecimiento.get(row.id_establecimiento, []),
            }
        )
    return result


def create_establecimiento(
    db: Session, establecimiento_in: EstablecimientoCreate, verificador_id: Optional[int] = None
) -> Establecimiento:
    data = establecimiento_in.model_dump(exclude_unset=True)
    lat = data.pop("latitud", None)
    lon = data.pop("longitud", None)
    responsable_id = data.pop("responsable_id", None)
    if lat is not None and lon is not None:
        # Use WKTElement to create a geometry value with SRID so SQLAlchemy stores it properly
        data["coordenadas"] = WKTElement(f"POINT({lon} {lat})", srid=4326)

    if responsable_id is not None:
        data["responsable_id"] = responsable_id

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
    """
    Actualiza un establecimiento y maneja sus tipos y categorías.
    
    - Actualiza los campos básicos del establecimiento
    - Si se incluyen tipos, actualiza solo los que han cambiado
    - Si se incluyen categorías, actualiza solo las que han cambiado
    """
    data = establecimiento_in.model_dump(exclude_unset=True)
    lat = data.pop("latitud", None)
    lon = data.pop("longitud", None)
    responsable_id = data.pop("responsable_id", None)
    if lat is not None and lon is not None:
        db_obj.coordenadas = WKTElement(f"POINT({lon} {lat})", srid=4326)

    if responsable_id is not None:
        data["responsable_id"] = responsable_id

    for field, value in data.items():
        setattr(db_obj, field, value)

    if data.get("estado_verificado") is True and data.get("verificador_id") is not None:
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

    # 4. Eliminar validaciones de usuarios
    db.query(UsuarioEstablecimientoValidacion).filter(
        UsuarioEstablecimientoValidacion.id_establecimiento == id_establecimiento
    ).delete()
    
    # 5. Eliminar reseñas
    db.query(Resena).filter(
        Resena.id_establecimiento == id_establecimiento
    ).delete()
    
    # 6. Eliminar items de menú
    from app.models.item_menu import ItemMenu
    db.query(ItemMenu).filter(
        ItemMenu.id_establecimiento == id_establecimiento
    ).delete()
    
    # 7. Eliminar tipos de item de menú
    from app.models.tipo_item_menu import TipoItemMenu
    db.query(TipoItemMenu).filter(
        TipoItemMenu.id_establecimiento == id_establecimiento
    ).delete()
    
    # 8. Eliminar validaciones y fotografías
    from app.models.fotografia import Fotografia
    db.query(Fotografia).filter(
        Fotografia.id_establecimiento == id_establecimiento
    ).delete()
    
    # 9. Finalmente, eliminar el establecimiento
    db.delete(obj)
    db.commit()
    
    return obj
