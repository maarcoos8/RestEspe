from sqlalchemy import Column, Integer, ForeignKey, String, DateTime
from sqlalchemy.sql import func

from app.db.base import Base


class Fotografia(Base):
    __tablename__ = "fotografia"

    id_foto = Column(Integer, primary_key=True, index=True)
    id_establecimiento = Column(Integer, ForeignKey("establecimiento.id_establecimiento"), nullable=False)
    id_usuario = Column(Integer, ForeignKey("usuarios.id_usuario"), nullable=False)
    url_imagen = Column(String(512), nullable=False)
    fecha_subida = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)