from typing import Any, Dict

import cloudinary
import cloudinary.uploader

from app.core import config


def _ensure_cloudinary_configured() -> None:
    if not config.CLOUDINARY_CLOUD_NAME or not config.CLOUDINARY_API_KEY or not config.CLOUDINARY_API_SECRET:
        raise ValueError("Cloudinary no configurado en el servidor")

    cloudinary.config(
        cloud_name=config.CLOUDINARY_CLOUD_NAME,
        api_key=config.CLOUDINARY_API_KEY,
        api_secret=config.CLOUDINARY_API_SECRET,
        secure=True,
    )


def upload_image(file_obj: Any, folder: str) -> Dict[str, Any]:
    """Sube una imagen a Cloudinary y retorna la metadata devuelta por el SDK."""
    _ensure_cloudinary_configured()
    return cloudinary.uploader.upload(
        file_obj,
        folder=folder,
        resource_type="image",
        overwrite=False,
    )
