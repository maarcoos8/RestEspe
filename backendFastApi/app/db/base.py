from sqlalchemy.orm import declarative_base

Base = declarative_base()

# Importa los modelos para que Alembic detecte las tablas al generar migraciones
# (se importan aquí para evitar problemas de orden de importación)
from app.models import (  # noqa: F401
	establecimiento,
	usuario,
	rol,
	resena,
	categoria_dieta,
	fotografia,
	establecimiento_categoria,
	establecimiento_tipo,
	usuario_establecimiento_favorito,
	tipo_establecimiento,
	tipo_item_menu,
	item_menu,
	item_categoria,
)