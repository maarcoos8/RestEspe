# Punto de entrada de la aplicación FastAPI
from fastapi import FastAPI
from app.api.v1.endpoints import (
	establecimiento,
	establecimiento_categoria as establecimiento_categoria_endpoint,
	establecimiento_tipo as establecimiento_tipo_endpoint,
	usuario_establecimiento_favorito as usuario_establecimiento_favorito_endpoint,
	item_categoria as item_categoria_endpoint,
	item_menu as item_menu_endpoint,
	db as db_endpoint,
	tipo_establecimiento as tipo_establecimiento_endpoint,
	tipo_item_menu as tipo_item_menu_endpoint,
	rol as rol_endpoint,
	usuario as usuario_endpoint,
	auth as auth_endpoint,
	resena as resena_endpoint,
	categoria_dieta as categoria_dieta_endpoint,
	fotografia as fotografia_endpoint,
	media as media_endpoint,
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
# Registrar el endpoint de Usuario
app.include_router(usuario_endpoint.router, prefix="/api/v1")
# Registrar el endpoint de Reseñas
app.include_router(resena_endpoint.router, prefix="/api/v1")
# Registrar el endpoint de Categoria Dieta
app.include_router(categoria_dieta_endpoint.router, prefix="/api/v1")
# Registrar el endpoint de relacion Establecimiento-Categoria
app.include_router(establecimiento_categoria_endpoint.router, prefix="/api/v1")
# Registrar el endpoint de relacion Establecimiento-Tipo
app.include_router(establecimiento_tipo_endpoint.router, prefix="/api/v1")
# Registrar el endpoint de favoritos de usuario
app.include_router(usuario_establecimiento_favorito_endpoint.router, prefix="/api/v1")
# Registrar el endpoint de Tipo Establecimiento
app.include_router(tipo_establecimiento_endpoint.router, prefix="/api/v1")
# Registrar el endpoint de Tipo Item Menu
app.include_router(tipo_item_menu_endpoint.router, prefix="/api/v1")
# Registrar el endpoint de Fotografia
app.include_router(fotografia_endpoint.router, prefix="/api/v1")
# Registrar endpoint genérico de subida de media (Cloudinary)
app.include_router(media_endpoint.router, prefix="/api/v1")
# Registrar el endpoint de autenticación
app.include_router(auth_endpoint.router, prefix="/api/v1")
# Registrar el endpoint de Item Menu
app.include_router(item_menu_endpoint.router, prefix="/api/v1")
# Registrar el endpoint de relacion Item-Categoria
app.include_router(item_categoria_endpoint.router, prefix="/api/v1")
# Registrar el endpoint de comprobación de BD en raíz: `/bd`
app.include_router(db_endpoint.router, prefix="")