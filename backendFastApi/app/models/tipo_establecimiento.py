from sqlalchemy import Column, Integer, String

from app.db.base import Base


class TipoEstablecimiento(Base):
    __tablename__ = "tipo_establecimiento"

    id_tipo_establecimiento = Column(Integer, primary_key=True, index=True)
    nombre_categoria = Column(String(150), unique=True, nullable=False)
