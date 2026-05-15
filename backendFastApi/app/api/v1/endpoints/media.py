from fastapi import APIRouter, File, HTTPException, UploadFile, status

from app.services.cloudinary_service import upload_image

router = APIRouter(prefix="/media", tags=["Media"])


@router.post("/upload-image", status_code=status.HTTP_201_CREATED)
async def upload_image_generic(file: UploadFile = File(...), use_case: str = "general"):
    """Sube una imagen a Cloudinary y devuelve URL optimizada para guardar en BD.

    `use_case` permite separar carpetas por dominio:
    - `fotografia`
    - `establecimiento`
    - `resena`
    - `general` (default)
    """
    allowed = {"fotografia", "establecimiento", "resena", "general"}
    if use_case not in allowed:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="use_case no valido")

    try:
        result = upload_image(file.file, folder=f"pinfood/{use_case}")
    except ValueError as e:
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=status.HTTP_502_BAD_GATEWAY, detail=f"Error subiendo a Cloudinary: {e}")

    image_url = result.get("secure_url") or result.get("url")
    if not image_url:
        raise HTTPException(status_code=status.HTTP_502_BAD_GATEWAY, detail="Cloudinary no devolvio URL")

    return {
        "image_url": image_url,
        "public_id": result.get("public_id"),
        "format": result.get("format"),
        "width": result.get("width"),
        "height": result.get("height"),
    }
