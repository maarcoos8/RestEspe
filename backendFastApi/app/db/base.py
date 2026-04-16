from sqlalchemy.orm import declarative_base

Base = declarative_base()

# Importa los modelos para que Alembic detecte las tablas al generar migraciones
# (se importan aquí para evitar problemas de orden de importación)
from app.models import establecimiento, usuario, rol, resena  # noqa: F401