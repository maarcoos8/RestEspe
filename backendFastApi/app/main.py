# Punto de entrada de la aplicación FastAPI
from fastapi import FastAPI
from app.api.v1.endpoints import (
	establecimiento,
	db as db_endpoint,
	rol as rol_endpoint,
	resena as resena_endpoint,
	categoria_dieta as categoria_dieta_endpoint,
	fotografia as fotografia_endpoint,
)
from app.db.session import engine
from app.db.base import Base

# Crea las tablas en Postgres al arrancar (solo si no existen)
Base.metadata.create_all(bind=engine)

app = FastAPI()

# Incluimos las rutas
app.include_router(establecimiento.router, prefix="/api/v1")
# Registrar el endpoint de Rol
app.include_router(rol_endpoint.router, prefix="/api/v1")
# Registrar el endpoint de Reseñas
app.include_router(resena_endpoint.router, prefix="/api/v1")
# Registrar el endpoint de Categoria Dieta
app.include_router(categoria_dieta_endpoint.router, prefix="/api/v1")
# Registrar el endpoint de Fotografia
app.include_router(fotografia_endpoint.router, prefix="/api/v1")
# Registrar el endpoint de comprobación de BD en raíz: `/bd`
app.include_router(db_endpoint.router, prefix="")