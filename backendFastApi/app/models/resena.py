from sqlalchemy import Column, Integer, ForeignKey, Float, Text, DateTime, CheckConstraint
from sqlalchemy.sql import func
from app.db.base import Base


class Resena(Base):
    __tablename__ = "resena"
    __table_args__ = (
        CheckConstraint("puntuacion >= 0 AND puntuacion <= 5 AND (puntuacion * 2 = floor(puntuacion * 2))", name="puntuacion_half_step"),
    )

    id_resena = Column(Integer, primary_key=True, index=True)
    id_usuario = Column(Integer, ForeignKey("usuarios.id_usuario"), nullable=False)
    id_establecimiento = Column(Integer, ForeignKey("establecimiento.id_establecimiento"), nullable=False)
    puntuacion = Column(Float, nullable=False)
    comentario = Column(Text, nullable=True)
    fecha_publicacion = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
