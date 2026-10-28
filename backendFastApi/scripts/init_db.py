# Prepara una base de datos nueva: crea las tablas, inserta los roles y marca las migraciones
import os
import sys

sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

from alembic import command  # noqa: E402
from alembic.config import Config  # noqa: E402
from sqlalchemy import inspect  # noqa: E402

from app.core.roles import ROLE_NAMES  # noqa: E402
from app.db.base import Base  # noqa: E402
from app.db.session import SessionLocal, engine  # noqa: E402
from app.models.rol import Rol  # noqa: E402

BACKEND_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))


def main() -> None:
    base_nueva = not inspect(engine).has_table("establecimiento")

    # Crea solo las tablas que no existen
    Base.metadata.create_all(bind=engine)

    # Los usuarios nuevos reciben el rol 1, así que los roles tienen que existir antes del primer login
    db = SessionLocal()
    try:
        for id_rol, nombre in ROLE_NAMES.items():
            if db.get(Rol, id_rol) is None:
                db.add(Rol(id_rol=id_rol, nombre_rol=nombre))
        db.commit()
    finally:
        db.close()

    # create_all ya genera el esquema final, así que las migraciones existentes se marcan como aplicadas
    if base_nueva:
        command.stamp(Config(os.path.join(BACKEND_DIR, "alembic.ini")), "head")

    print("Base de datos lista")


if __name__ == "__main__":
    main()
