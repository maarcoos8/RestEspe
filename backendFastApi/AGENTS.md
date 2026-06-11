# Contexto del Proyecto: Aplicación para Dietas Específicas (PinFood)

## 1. Descripción General
El proyecto consiste en el desarrollo de una aplicación móvil multiplataforma orientada a la localización geográfica de establecimientos de restauración que sean aptos para dietas específicas (vegana, halal, sin gluten, etc.). El valor diferencial de esta aplicación es su **sistema de información verificada**, diseñado para eliminar la incertidumbre de los datos públicos mediante la validación por parte de responsables y administradores.

## 2. Stack Tecnológico
El proyecto sigue una arquitectura cliente-servidor con un fuerte enfoque en sistemas de información geográfica (GIS).

*   **Frontend (Cliente Móvil):** Flutter con el lenguaje Dart. Interfaz orientada a la visualización de mapas y listas interactivas.
*   **Backend (Servidor RESTful):** FastAPI con el lenguaje Python. Documentación autogenerada con OpenAPI (Swagger).
*   **Base de Datos:** PostgreSQL.
*   **Extensión Espacial:** PostGIS (Crítico para el proyecto: almacenamiento de geometrías y cálculos de distancias).
*   **ORM:** SQLAlchemy + GeoAlchemy2 (para soporte de tipos geométricos).
*   **Migraciones:** Alembic (control de versiones de la base de datos).
*   **Validación/Schemas:** Pydantic (Serialización y validación de JSON).
*   **Autenticación:** Google Identity (OAuth 2.0). **No se almacenan contraseñas en la base de datos.**
*   **Gestión Multimedia:** Cloudinary **No se almacenan archivos binarios de imágenes en la base de datos**, solo las URLs de las imágenes subidas.
*   **Servicio de Cartografía y Geocodificación:** OpenStreetMap (OSM).

## 3 Estructura del Proyecto
Se ha definido una organización modular para asegurar la escalabilidad y facilitar la integración con Flutter:


app/
├── main.py              # Punto de entrada y configuración de FastAPI
├── api/v1/              # Rutas versionadas para evitar romper la app móvil
│   └── endpoints/       # Lógica de las rutas (restaurantes.py, etc.)
├── core/                # Variables de entorno (.env) y seguridad
├── crud/                # Lógica de acceso a datos (consultas espaciales)
├── db/                  # Configuración de sesión y motor de base de datos
├── models/              # Modelos de SQLAlchemy (Definición de tablas)
└── schemas/             # Modelos de Pydantic (Lo que recibe/envía el JSON)

## 4. Control de Acceso Basado en Roles (RBAC)
El sistema cuenta con 4 actores clave. Toda acción en el backend debe validar mediante un token de sesión si el usuario posee el rol adecuado:
*   **Usuario Final (Ciudadano):** Explora el mapa, filtra por dietas, publica reseñas y sube fotografías.
*   **Responsable:** Gestiona la ficha de su establecimiento, declara su oferta gastronómica (menú) y responde a reseñas. Valida técnicamente su local.
*   **Administrador Global:** Realiza carga proactiva de datos, mantiene el catálogo de dietas y verifica locales mediante investigación.
*   **Administrador del Sistema (SuperAdmin):** Gestiona la infraestructura, asigna roles de Responsable/Admin Global a los usuarios base y asegura el funcionamiento del sistema.

## 5. Esquema de Base de Datos (PostgreSQL + PostGIS)
A continuación, se detalla el diseño relacional del sistema:

*   **`Rol`**: (id_rol, nombre_rol).
*   **`Usuario`**: (id_usuario, email [UNIQUE], nombre_completo, fotoPerfil (URL de la foto de perfil del proveedor OAuth),id_rol [FK]). *Nota: Inicio de sesión delegado a Google OAuth 2.0.*
*   **`Establecimiento`**: (id_establecimiento, nombre, direccion_texto, coordenadas [GEOMETRY(Point, 4326)], estado_verificado [BOOLEAN], ultima_verificacion(timestamp de cuando se subieron los ultimos datos), verificador[FK a Usuario] (se guarda la ultima persona que haya verificado y subido los datos)).
*   **`Categoria_Dieta`**: (id_categoria_dieta, nombre_dieta). Catálogo estático (ej. Vegana, Sin Gluten).
*   **`Tipo_Item_Menu`**: (id_tipo_item, id_establecimiento [FK],nombre_tipo). Permite crear un catálogo de tipos de items del menú para cada establecimiento (ej. Bebida, Entrantes).
*   **`Tipo_Establecimiento`**: (id_tipo_establecimiento, nombre_categoria). Catálogo estático (ej. Pizzeria, Comida rápida).
*   **`Establecimiento_Categoria`**: Tabla intermedia N:M entre Establecimiento y Categoria_Dieta (Define el filtrado a nivel de local).
*   **`Establecimiento_Tipo`**: Tabla intermedia N:M entre Establecimiento y Tipo_Establecimiento (Define el filtrado a nivel de local).
*   **`Usuario_Establecimiento_Favorito`**: Tabla intermedia N:M entre Usuario y Establecimiento para persistir los favoritos de cada usuario.
*   **`Item_Menu`**: (id_item_menu, nombre_item_menu, descripcion, precio, id_establecimiento [FK], id_tipo_item_menu [FK]).
*   **`Item_Categoria`**: Tabla intermedia N:M entre Item_Menu y Categoria_Dieta (Define los iconos a nivel de plato en la carta).
*   **`Reseña`**: (id_reseña, id_usuario [FK], id_establecimiento [FK], puntuacion, comentario, fecha_publicacion), url_imagen(opcional).
*   **`Fotografia`**: (id_foto, id_establecimiento [FK], id_usuario [FK], url_imagen [VARCHAR - URL externa Cloudinary], fecha_subida).

## 6. Reglas y Lógica de Negocio Clave
1.  **Motor de Filtrado:** La búsqueda de restaurantes debe poder cruzar simultáneamente el área espacial (coordenadas del usuario + radio) y múltiples etiquetas dietéticas (Tabla `Establecimiento_Categoria`).
2.  **Estado Verificado:** El atributo booleano `estado_verificado` en la tabla Establecimiento es vital. La UI en Flutter debe destacarlo visualmente (ej. marcador especial en el mapa o insignia en la ficha). Solo Responsables, Administradores Globales y SuperAdmins pueden alterar este estado.
3.  **Manejo Espacial:** Siempre que se interactúe con ubicaciones, el Backend debe transformar las latitudes y longitudes estándar recibidas del Frontend al formato de geometría espacial requerido por PostGIS (`SRID=4326`).
4.  **Favoritos de Usuario:** Las relaciones usuario-establecimiento que representen favoritos deben modelarse con una tabla puente dedicada, siguiendo el mismo patrón que `Establecimiento_Categoria` y `Establecimiento_Tipo`. Si se añade una relación de este tipo, hay que registrar el modelo en `app/db/base.py`, exportar el CRUD en `app/crud/__init__.py` y exponerlo con un router en `app/api/v1/endpoints/`.
