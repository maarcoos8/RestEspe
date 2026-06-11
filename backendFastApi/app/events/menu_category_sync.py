"""
Listeners para sincronizar `establecimiento_categoria` basados en los ítems del menú.

Regla:
 - Un establecimiento tiene asociada una CategoriaDieta (en establecimiento_categoria)
     iff tiene al menos 1 ItemMenu asociado a esa categoria (vía item_categoria).

Listeners registrados:
 - ItemCategoria: after_insert, after_delete, after_update
 - ItemMenu: before_delete (cache categories), after_insert, after_update, after_delete (usa cache)

Notas técnicas:
 - Uso SQLAlchemy Core (tables desde Base.metadata) y `connection` provisto por los eventos,
   evitando `Session` para no causar flush/loop.
 - Todas las consultas y escrituras se ejecutan usando el `connection` que está dentro
   de la misma transacción del flush que originó el evento.
"""

from typing import Iterable, Set, List, Optional

from sqlalchemy import event, select, func, inspect
from sqlalchemy.engine import Connection

from app.db.base import Base
from app.models.item_menu import ItemMenu
from app.models.item_categoria import ItemCategoria

# Tablas (SQLAlchemy Core Table) tomadas desde metadata para consultas directas
_item_menu = Base.metadata.tables["item_menu"]
_item_categoria = Base.metadata.tables["item_categoria"]
_establecimiento_categoria = Base.metadata.tables["establecimiento_categoria"]


def _get_categories_of_item(conn: Connection, item_id: int) -> List[int]:
    """Devuelve lista de id_categoria asociadas a un item (consulta en DB via connection)."""
    sel = select(_item_categoria.c.id_categoria).where(_item_categoria.c.id_item_menu == item_id)
    rows = conn.execute(sel).fetchall()
    return [r[0] for r in rows]


def _get_establishment_of_item(conn: Connection, item_id: int) -> Optional[int]:
    """Devuelve id_establecimiento del item dado (o None si no existe)."""
    sel = select(_item_menu.c.id_establecimiento).where(_item_menu.c.id_item_menu == item_id)
    row = conn.execute(sel).fetchone()
    return row[0] if row is not None else None


def _establishment_has_category(conn: Connection, est_id: int, cat_id: int) -> bool:
    sel = select(func.count()).select_from(_establecimiento_categoria).where(
        _establecimiento_categoria.c.id_establecimiento == est_id,
        _establecimiento_categoria.c.id_categoria == cat_id,
    )
    cnt = conn.execute(sel).scalar()
    return bool(cnt and cnt > 0)


def _insert_establishment_category(conn: Connection, est_id: int, cat_id: int) -> None:
    # comprobamos existencia y sólo insertamos si no existe (evita errores PK)
    if not _establishment_has_category(conn, est_id, cat_id):
        conn.execute(
            _establecimiento_categoria.insert().values(
                id_establecimiento=est_id,
                id_categoria=cat_id,
            )
        )


def _delete_establishment_category_if_exists(conn: Connection, est_id: int, cat_id: int) -> None:
    conn.execute(
        _establecimiento_categoria.delete().where(
            _establecimiento_categoria.c.id_establecimiento == est_id,
            _establecimiento_categoria.c.id_categoria == cat_id,
        )
    )


def _count_items_for_establishment_and_category(conn: Connection, est_id: int, cat_id: int) -> int:
    """Cuenta cuántos ItemMenu del establecimiento están asociados a la categoría."""
    jm = _item_menu.join(
        _item_categoria,
        _item_menu.c.id_item_menu == _item_categoria.c.id_item_menu,
    )
    sel = select(func.count()).select_from(jm).where(
        _item_menu.c.id_establecimiento == est_id,
        _item_categoria.c.id_categoria == cat_id,
    )
    return int(conn.execute(sel).scalar() or 0)


def _sync_establishment_for_categories(conn: Connection, est_id: int, category_ids: Iterable[int]) -> None:
    """
    Para cada categoría en category_ids:
    - si count >= 1 -> asegura que exista fila en establecimiento_categoria
    - si count < 1 -> elimina la fila si existía
    """
    if est_id is None:
        return

    for cat_id in set(category_ids or []):
        cnt = _count_items_for_establishment_and_category(conn, est_id, cat_id)
        if cnt >= 1:
            _insert_establishment_category(conn, est_id, cat_id)
        else:
            _delete_establishment_category_if_exists(conn, est_id, cat_id)


#
# Listeners para ItemCategoria (mapeo item <-> categoria)
#
@event.listens_for(ItemCategoria, "after_insert")
def item_categoria_after_insert(mapper, connection: Connection, target: ItemCategoria):
    """
    Cuando se asocia un item con una categoría -> la categoría afectada puede aumentar el contador.
    Determinamos el establecimiento y sincronizamos esa categoría.
    """
    item_id = target.id_item_menu
    cat_id = target.id_categoria
    est_id = _get_establishment_of_item(connection, item_id)
    if est_id is not None:
        _sync_establishment_for_categories(connection, est_id, {cat_id})


@event.listens_for(ItemCategoria, "after_delete")
def item_categoria_after_delete(mapper, connection: Connection, target: ItemCategoria):
    """
    Cuando se elimina la asociación item-categoria -> la categoría afectada puede bajar el contador.
    Determinamos el establecimiento (a partir del item) y sincronizamos esa categoría.
    """
    item_id = target.id_item_menu
    cat_id = target.id_categoria
    # Dependiendo del orden de borrado, item puede haber sido borrado primero; intentamos obtener establecimiento:
    est_id = _get_establishment_of_item(connection, item_id)
    if est_id is not None:
        _sync_establishment_for_categories(connection, est_id, {cat_id})
    else:
        # Si el item ya no existe, no hay necesidad de sincronizar (el delete de ItemMenu se encargará).
        pass


@event.listens_for(ItemCategoria, "after_update")
def item_categoria_after_update(mapper, connection: Connection, target: ItemCategoria):
    """
    Si se modifica la relación (por ejemplo se reasigna la categoria o el item), tratamos
    las categorías previas y las nuevas como afectadas.
    """
    state = inspect(target)
    affected_cats: Set[int] = set()

    # historial de categoria
    hist_cat = state.attrs.id_categoria.history
    if hist_cat.added:
        affected_cats.update([v for v in hist_cat.added if v is not None])
    if hist_cat.deleted:
        affected_cats.update([v for v in hist_cat.deleted if v is not None])

    # historial de item
    hist_item = state.attrs.id_item_menu.history
    affected_items = set()
    if hist_item.added:
        affected_items.update([v for v in hist_item.added if v is not None])
    if hist_item.deleted:
        affected_items.update([v for v in hist_item.deleted if v is not None])
    if not affected_items:
        # si no hay cambio en item id, usamos el current
        affected_items.add(target.id_item_menu)

    # Por cada item afectado, obtenemos su establecimiento y sincronizamos las categorías afectadas
    for itm in affected_items:
        est_id = _get_establishment_of_item(connection, itm)
        if est_id is not None and affected_cats:
            _sync_establishment_for_categories(connection, est_id, affected_cats)


#
# Listeners para ItemMenu (creación, actualización, borrado)
#
@event.listens_for(ItemMenu, "before_delete")
def item_menu_before_delete(mapper, connection: Connection, target: ItemMenu):
    """
    Capturamos las categorías del item ANTES de que se borre, y las guardamos temporalmente
    en un atributo en memoria del objeto (no persistente) para usarlo en after_delete.
    """
    cats = _get_categories_of_item(connection, target.id_item_menu)
    # Guardamos en atributo temporal para after_delete
    try:
        setattr(target, "_cached_item_categories", cats)
    except Exception:
        # garantía de no romper si target no permite atributos dinámicos
        pass


@event.listens_for(ItemMenu, "after_delete")
def item_menu_after_delete(mapper, connection: Connection, target: ItemMenu):
    """
    Tras borrar el item, sincronizamos las categorías previamente asociadas usando la cache.
    """
    est_id = getattr(target, "id_establecimiento", None)
    cats = getattr(target, "_cached_item_categories", None)
    if est_id is None:
        # si no tenemos establecimiento, intentamos obtenerlo por query (aunque tras delete puede no existir)
        # en ese caso nada que hacer
        return
    if not cats:
        # si no había categorías cacheadas, no hay nada que sincronizar aquí
        return
    _sync_establishment_for_categories(connection, est_id, set(cats))


@event.listens_for(ItemMenu, "after_insert")
def item_menu_after_insert(mapper, connection: Connection, target: ItemMenu):
    """
    Tras crear un item, si ya existen asociaciones en item_categoria (raro si se crean después),
    sincronizamos categorías del item (p.e. cuando la inserción y relaciones ocurren en la misma transacción).
    """
    est_id = getattr(target, "id_establecimiento", None)
    if est_id is None:
        return
    cats = _get_categories_of_item(connection, target.id_item_menu)
    if cats:
        _sync_establishment_for_categories(connection, est_id, set(cats))


@event.listens_for(ItemMenu, "after_update")
def item_menu_after_update(mapper, connection: Connection, target: ItemMenu):
    """
    Si un ItemMenu cambia (p.e. se reasigna a otro establecimiento), debemos sincronizar
    para los establecimientos afectados (anterior y nuevo).
    """
    state = inspect(target)
    est_prev = None
    est_curr = getattr(target, "id_establecimiento", None)

    hist = state.attrs.id_establecimiento.history
    if hist.deleted:
        est_prev = hist.deleted[0]
    if hist.added:
        est_curr = hist.added[0]

    # categorias asociadas actualmente al item
    cats = _get_categories_of_item(connection, target.id_item_menu)

    affected_est_ids = set()
    if est_prev is not None:
        affected_est_ids.add(est_prev)
    if est_curr is not None:
        affected_est_ids.add(est_curr)

    for est in affected_est_ids:
        if cats:
            _sync_establishment_for_categories(connection, est, set(cats))
