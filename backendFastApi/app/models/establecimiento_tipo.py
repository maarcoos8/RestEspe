from sqlalchemy import Column, Integer, ForeignKey

from app.db.base import Base


class EstablecimientoTipo(Base):
    __tablename__ = "establecimiento_tipo"

    id_establecimiento = Column(Integer, ForeignKey("establecimiento.id_establecimiento"), primary_key=True)
    id_tipo_establecimiento = Column(
        Integer,
        ForeignKey("tipo_establecimiento.id_tipo_establecimiento"),
        primary_key=True,
    )
