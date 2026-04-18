from sqlalchemy import Column, Integer, ForeignKey

from app.db.base import Base


class EstablecimientoCategoria(Base):
    __tablename__ = "establecimiento_categoria"

    id_establecimiento = Column(Integer, ForeignKey("establecimiento.id_establecimiento"), primary_key=True)
    id_categoria = Column(Integer, ForeignKey("categoria_dieta.id_categoria"), primary_key=True)