# 🤖 Protocolo de Desarrollo Frontend - Proyecto RestEspe

Este documento describe la arquitectura, estándares y el contexto funcional del frontend desarrollado en **Flutter** para el TFG "RestEspe".

## 📝 Contexto de la Aplicación
**RestEspe** es una plataforma de descubrimiento gastronómico que combina **FastAPI**, **PostGIS** y **Flutter**. La app permite a los usuarios localizar establecimientos según preferencias dietéticas específicas (Vegano, Sin Gluten, Halal, etc.) mediante un sistema de filtrado avanzado basado en una relación N:M entre platos y categorías.

---

## 🏗️ 1. Arquitectura de Carpetas
Seguimos una estructura orientada a la mantenibilidad y separación de responsabilidades:

- `lib/core/`: Constantes (URLs de API, colores del tema), utilidades y cliente HTTP.
- `lib/data/`: Modelos de Dart (mapeo de JSON) y repositorios para la comunicación con FastAPI.
- `lib/providers/`: Gestión de estado (control del mapa, sesión de usuario y filtros activos).
- `lib/screens/`: Pantallas principales (Mapa de OpenStreetMap, Detalle de Restaurante, Login).
- `lib/widgets/`: Componentes UI reutilizables (tarjetas de platos, botones de filtro).

---

## 🛠️ 2. Stack Tecnológico Principal
*   **Framework:** Flutter (Material Design 3).
*   **Mapas:** `flutter_map` con tiles de OpenStreetMap.
*   **Geolocalización:** `geolocator` para centrar el mapa en la posición del usuario.
*   **Estado:** `provider` para la gestión de datos reactivos.
*   **Conexión API:** Paquete `http` para peticiones REST.
*   **Seguridad:** `flutter_secure_storage` para persistir el JWT.

---

## 📋 3. Reglas de Código y Estilo
*   **Naming:** Archivos en `snake_case`, Clases en `PascalCase`, Métodos en `camelCase`.
*   **Widgets:** Extraer lógica a componentes pequeños en `/widgets` si el archivo supera las 150 líneas.
*   **Seguridad:** Los botones de gestión (Añadir/Editar) solo se renderizan si el rol del usuario es `admin`.

---

## 📍 4. Integración con PostGIS (Lógica Espacial)
1.  **Bounding Box:** El frontend debe enviar las coordenadas de las esquinas del mapa al backend para recibir solo los locales visibles.
2.  **Formatos:** Las coordenadas se manejan siempre como objetos `LatLng` (latlong2).
3.  **Filtros:** Las categorías dietéticas se pasan como parámetros de consulta en la URL (ej: `?categoria=vegano`).

---

## 🚀 5. Flujo de Trabajo Local
1.  **Base de Datos:** Asegurar que PostGIS esté corriendo en Docker/Local.
2.  **Backend:** Servidor FastAPI activo en el puerto 8000.
3.  **Frontend:** 
    *   Emulador Android: Usar `http://10.0.2.2:8000` como URL base.
    *   Navegador Web: Usar `http://localhost:8000`.

---

## 🔐 6. Manejo de Sesiones
*   El login contra FastAPI devuelve un JWT.
*   Este token debe incluirse en el header `Authorization: Bearer <token>` para todas las peticiones protegidas.
*   Si el token expira (401 Unauthorized), la app debe redirigir automáticamente al Login.