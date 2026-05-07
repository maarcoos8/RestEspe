import os
from typing import Optional

from dotenv import load_dotenv

# Cargar variables de entorno desde .env si existe
load_dotenv()


def get_env(name: str, default: Optional[str] = None) -> Optional[str]:
    return os.getenv(name, default)


# Cloudinary settings (expected to be provided via env vars)
CLOUDINARY_CLOUD_NAME = get_env("CLOUDINARY_CLOUD_NAME")
CLOUDINARY_API_KEY = get_env("CLOUDINARY_API_KEY")
CLOUDINARY_API_SECRET = get_env("CLOUDINARY_API_SECRET")
