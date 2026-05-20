from typing import List, Optional

from sqlalchemy.orm import Session

from app.models.establecimiento import Establecimiento
from app.models.establecimiento_tipo import EstablecimientoTipo
from app.models.tipo_establecimiento import TipoEstablecimiento


def get_establecimiento_tipo(
    db: Session, id_establecimiento: int, id_tipo_establecimiento: int
) -> Optional[EstablecimientoTipo]:
    return (
        db.query(EstablecimientoTipo)
        .filter(
            EstablecimientoTipo.id_establecimiento == id_establecimiento,
            EstablecimientoTipo.id_tipo_establecimiento == id_tipo_establecimiento,
        )
        .first()
    )


def get_establecimiento_tipos(db: Session) -> List[EstablecimientoTipo]:
    return db.query(EstablecimientoTipo).all()


def get_tipos_por_establecimiento(db: Session, id_establecimiento: int) -> List[EstablecimientoTipo]:
    return db.query(EstablecimientoTipo).filter(EstablecimientoTipo.id_establecimiento == id_establecimiento).all()


def get_establecimientos_por_tipo(db: Session, id_tipo_establecimiento: int) -> List[EstablecimientoTipo]:
    return db.query(EstablecimientoTipo).filter(EstablecimientoTipo.id_tipo_establecimiento == id_tipo_establecimiento).all()


def create_establecimiento_tipo(db: Session, id_establecimiento: int, id_tipo_establecimiento: int) -> EstablecimientoTipo:
    if not db.query(Establecimiento).filter(Establecimiento.id_establecimiento == id_establecimiento).first():
        raise ValueError("Establecimiento no encontrado")
    if not db.query(TipoEstablecimiento).filter(TipoEstablecimiento.id_tipo_establecimiento == id_tipo_establecimiento).first():
        raise ValueError("Tipo de establecimiento no encontrado")

    existing = get_establecimiento_tipo(db, id_establecimiento, id_tipo_establecimiento)
    if existing:
        raise ValueError("La relacion establecimiento-tipo ya existe")

    db_obj = EstablecimientoTipo(
        id_establecimiento=id_establecimiento,
        id_tipo_establecimiento=id_tipo_establecimiento,
    )
    db.add(db_obj)
    db.commit()
    db.refresh(db_obj)
    return db_obj


def update_tipos_establecimiento(
    db: Session, id_establecimiento: int, nuevos_tipos_ids: List[int]
) -> List[EstablecimientoTipo]:
    """
    Actualiza inteligentemente los tipos de un establecimiento.
    
    Solo elimina y crea los tipos que han cambiado, evitando errores de duplicados.
    
    Args:
        db: Sesión de base de datos
        id_establecimiento: ID del establecimiento
        nuevos_tipos_ids: Lista de IDs de tipos nuevos
        
    Returns:
        Lista de tipos después de la actualización
    """
    # Obtener tipos actuales
    tipos_actuales = get_tipos_por_establecimiento(db, id_establecimiento)
    tipos_actuales_ids = {tipo.id_tipo_establecimiento for tipo in tipos_actuales}
    nuevos_tipos_ids_set = set(nuevos_tipos_ids)
    
    # Tipos a eliminar (están en actuales pero no en nuevos)
    a_eliminar = tipos_actuales_ids - nuevos_tipos_ids_set
    
    # Tipos a crear (están en nuevos pero no en actuales)
    a_crear = nuevos_tipos_ids_set - tipos_actuales_ids
    
    # Eliminar tipos que ya no deben estar
    for tipo_id in a_eliminar:
        remove_establecimiento_tipo(db, id_establecimiento, tipo_id)
    
    # Crear nuevos tipos
    for tipo_id in a_crear:
        create_establecimiento_tipo(db, id_establecimiento, tipo_id)
    
    # Retornar los tipos actualizados
    return get_tipos_por_establecimiento(db, id_establecimiento)


def remove_establecimiento_tipo(
    db: Session, id_establecimiento: int, id_tipo_establecimiento: int
) -> Optional[EstablecimientoTipo]:
    obj = get_establecimiento_tipo(db, id_establecimiento, id_tipo_establecimiento)
    if not obj:
        return None

    db.delete(obj)
    db.commit()
    return obj
