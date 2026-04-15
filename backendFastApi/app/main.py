# Punto de entrada de la aplicación FastAPI
from fastapi import FastAPI
from app.api.v1.endpoints import restaurantes
from app.db.session import engine
from app.models import restaurante

# Esto crea las tablas en Postgres al arrancar (solo si no existen)
restaurante.Base.metadata.create_all(bind=engine)

app = FastAPI()

# Incluimos las rutas
app.include_router(restaurantes.router, prefix="/api/v1")