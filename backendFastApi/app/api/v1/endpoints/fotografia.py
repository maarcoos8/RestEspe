from typing import List

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app import crud
from app.db.session import get_db
from app.schemas.fotografia import FotografiaCreate, FotografiaOut, FotografiaUpdate
from fastapi import UploadFile, File, Form
from app.services.cloudinary_service import upload_image

router = APIRouter(prefix="/fotografia", tags=["Fotografia"])


@router.get("/", response_model=List[FotografiaOut])
def leer_fotografias(db: Session = Depends(get_db)):
    return crud.crud_fotografia.get_fotografias(db)


@router.get("/establecimiento/{id_establecimiento}", response_model=List[FotografiaOut])
def leer_fotografias_por_establecimiento(id_establecimiento: int, db: Session = Depends(get_db)):
    return crud.crud_fotografia.get_fotografias_por_establecimiento(db, id_establecimiento)


@router.get("/{id}", response_model=FotografiaOut)
def leer_fotografia(id: int, db: Session = Depends(get_db)):
    obj = crud.crud_fotografia.get_fotografia(db, id)
    if not obj:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Fotografia no encontrada")
    return obj


@router.post("/", response_model=FotografiaOut, status_code=status.HTTP_201_CREATED)
def crear_fotografia(fotografia_in: FotografiaCreate, db: Session = Depends(get_db)):
    try:
        return crud.crud_fotografia.create_fotografia(db, fotografia_in)
    except ValueError as e:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(e))


@router.post("/upload", response_model=FotografiaOut, status_code=status.HTTP_201_CREATED)
async def upload_fotografia(
    id_establecimiento: int = Form(...),
    id_usuario: int = Form(...),
    file: UploadFile = File(...),
    db: Session = Depends(get_db),
) -> FotografiaOut:
    """Recibe una imagen como multipart/form-data, la sube a Cloudinary y crea el registro en la BD.

    Form fields: `id_establecimiento`, `id_usuario`.
    File field: `file` (la imagen)
    """
    try:
        upload_result = upload_image(file.file, folder="restespe/fotografia")
    except ValueError as e:
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=status.HTTP_502_BAD_GATEWAY, detail=f"Error subiendo a Cloudinary: {e}")

    # Obtener la URL segura optimizada (secure_url)
    secure_url = upload_result.get("secure_url") or upload_result.get("url")
    if not secure_url:
        raise HTTPException(status_code=status.HTTP_502_BAD_GATEWAY, detail="Cloudinary no devolvió URL")

    # Crear el registro en BD usando el CRUD existente
    fotografia_in = FotografiaCreate(id_establecimiento=id_establecimiento, id_usuario=id_usuario, url_imagen=secure_url)
    try:
        created = crud.crud_fotografia.create_fotografia(db, fotografia_in)
        return created
    except ValueError as e:
        # Si hay error en los IDs de referencia, devolver 400
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(e))


@router.put("/{id}", response_model=FotografiaOut)
def actualizar_fotografia(id: int, fotografia_in: FotografiaUpdate, db: Session = Depends(get_db)):
    db_obj = crud.crud_fotografia.get_fotografia(db, id)
    if not db_obj:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Fotografia no encontrada")
    try:
        return crud.crud_fotografia.update_fotografia(db, db_obj, fotografia_in)
    except ValueError as e:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(e))


@router.delete("/{id}", response_model=FotografiaOut)
def eliminar_fotografia(id: int, db: Session = Depends(get_db)):
    obj = crud.crud_fotografia.remove_fotografia(db, id)
    if not obj:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Fotografia no encontrada")
    return obj