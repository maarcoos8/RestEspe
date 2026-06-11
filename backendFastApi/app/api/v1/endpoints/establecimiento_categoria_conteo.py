from fastapi import APIRouter, Depends
from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app.db.base import Base
from app.db.session import get_db
from app.schemas.establecimiento_categoria_conteo import CategoriaDietaConteoOut

router = APIRouter(prefix="/establecimiento_categoria", tags=["EstablecimientoCategoriaConteo"])

_categoria_dieta = Base.metadata.tables["categoria_dieta"]
_item_menu = Base.metadata.tables["item_menu"]
_item_categoria = Base.metadata.tables["item_categoria"]


@router.get("/establecimiento/{id_establecimiento}/conteo", response_model=list[CategoriaDietaConteoOut])
def leer_categorias_con_conteo(id_establecimiento: int, db: Session = Depends(get_db)):
	total_platos_subquery = (
		select(func.count(func.distinct(_item_menu.c.id_item_menu)))
		.where(_item_menu.c.id_establecimiento == id_establecimiento)
		.scalar_subquery()
	)

	stmt = (
		select(
			_categoria_dieta.c.id_categoria.label("id_categoria"),
			_categoria_dieta.c.nombre_dieta.label("nombre_dieta"),
			_categoria_dieta.c.color_hex.label("color_hex"),
			func.count(func.distinct(_item_menu.c.id_item_menu)).label("cantidad_platos"),
			total_platos_subquery.label("total_platos"),
		)
		.select_from(
			_categoria_dieta.join(
				_item_categoria,
				_categoria_dieta.c.id_categoria == _item_categoria.c.id_categoria,
			).join(
				_item_menu,
				_item_categoria.c.id_item_menu == _item_menu.c.id_item_menu,
			)
		)
		.where(_item_menu.c.id_establecimiento == id_establecimiento)
		.group_by(
			_categoria_dieta.c.id_categoria,
			_categoria_dieta.c.nombre_dieta,
			_categoria_dieta.c.color_hex,
		)
		.order_by(_categoria_dieta.c.nombre_dieta)
	)

	rows = db.execute(stmt).all()
	return [
		{
			"id_categoria": row.id_categoria,
			"nombre_dieta": row.nombre_dieta,
			"color_hex": row.color_hex,
			"cantidad_platos": int(row.cantidad_platos or 0),
			"total_platos": int(row.total_platos or 0),
		}
		for row in rows
	]