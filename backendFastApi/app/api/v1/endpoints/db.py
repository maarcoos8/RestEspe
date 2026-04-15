from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import text
from sqlalchemy.orm import Session

from app.db.session import get_db, engine

router = APIRouter(prefix="/bd", tags=["BD"])


@router.get("/")
def check_bd(db: Session = Depends(get_db)):
    try:
        # Ejecutar una consulta mínima para comprobar conexión
        with engine.connect() as conn:
            conn.execute(text("SELECT 1"))
        return {"ok": True, "message": "Conectado a la base de datos"}
    except Exception as e:
        raise HTTPException(status_code=status.HTTP_503_SERVICE_UNAVAILABLE, detail=str(e))
