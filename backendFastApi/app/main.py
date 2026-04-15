# Punto de entrada de la aplicación FastAPI
from fastapi import FastAPI
from app.api.v1.endpoints import establecimiento, db as db_endpoint
from app.db.session import engine
from app.db.base import Base

# Crea las tablas en Postgres al arrancar (solo si no existen)
Base.metadata.create_all(bind=engine)

app = FastAPI()

# Incluimos las rutas
app.include_router(establecimiento.router, prefix="/api/v1")
# Registrar el endpoint de comprobación de BD en raíz: `/bd`
app.include_router(db_endpoint.router, prefix="")