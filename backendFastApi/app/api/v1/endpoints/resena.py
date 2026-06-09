from typing import List

from fastapi import APIRouter, Depends, HTTPException, Request, status
from sqlalchemy.orm import Session

from app import crud
from app.core.roles import ROLE_SUPERADMIN
from app.db.session import get_db
from app.schemas.resena import ResenaOut, ResenaCreate, ResenaUpdate, ResenaOutWithUser

router = APIRouter(prefix="/resena", tags=["Resena"])


@router.get("/", response_model=List[ResenaOut])
def leer_resenas(db: Session = Depends(get_db)):
    return crud.crud_resena.get_resenas(db)


@router.get("/establecimiento/{id_establecimiento}", response_model=List[ResenaOutWithUser])
def leer_resenas_por_establecimiento(
    id_establecimiento: int,
    skip: int = 0,
    limit: int = 5,
    db: Session = Depends(get_db),
):
    """Obtiene reseñas de un establecimiento con datos del usuario con paginación"""
    resultados = crud.crud_resena.get_resenas_por_establecimiento(
        db, id_establecimiento, skip=skip, limit=limit
    )
    
    # Convertir tuplas a diccionarios
    resenas_dict = []
    for row in resultados:
        resenas_dict.append({
            "id_resena": row[0],
            "id_usuario": row[1],
            "id_establecimiento": row[2],
            "puntuacion": row[3],
            "comentario": row[4],
            "url_imagen": row[5],
            "fecha_publicacion": row[6],
            "nombre_usuario": row[7],
            "foto_perfil": row[8],
        })
    return resenas_dict


@router.get("/{id}", response_model=ResenaOut)
def leer_resena(id: int, db: Session = Depends(get_db)):
    obj = crud.crud_resena.get_resena(db, id)
    if not obj:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Resena no encontrada")
    return obj


@router.post("/", response_model=ResenaOut, status_code=status.HTTP_201_CREATED)
def crear_resena(resena_in: ResenaCreate, db: Session = Depends(get_db)):
    try:
        return crud.crud_resena.create_resena(db, resena_in)
    except ValueError as e:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(e))


@router.put("/{id}", response_model=ResenaOut)
def actualizar_resena(id: int, resena_in: ResenaUpdate, db: Session = Depends(get_db)):
    db_obj = crud.crud_resena.get_resena(db, id)
    if not db_obj:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Resena no encontrada")
    return crud.crud_resena.update_resena(db, db_obj, resena_in)


@router.delete("/{id}", response_model=ResenaOut)
def eliminar_resena(id: int, request: Request, db: Session = Depends(get_db)):
    claims = getattr(request.state, "jwt_claims", None)
    email = (claims or {}).get("email")
    if not email:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Usuario no autenticado")

    usuario_actual = crud.crud_usuario.get_usuario_por_email(db, email)
    if not usuario_actual:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Usuario no encontrado")

    obj = crud.crud_resena.get_resena(db, id)
    if not obj:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Resena no encontrada")

    es_propietario = obj.id_usuario == usuario_actual.id_usuario
    es_superadmin = usuario_actual.id_rol == ROLE_SUPERADMIN

    if not (es_propietario or es_superadmin):
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="No tienes permiso para eliminar esta reseña")

    return crud.crud_resena.remove_resena(db, id)
