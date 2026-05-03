from sqlalchemy import Column, Integer, ForeignKey
from sqlalchemy.orm import relationship
from sqlalchemy.ext.hybrid import hybrid_property

from app.db.base import Base


class EstablecimientoTipo(Base):
    __tablename__ = "establecimiento_tipo"

    id_establecimiento = Column(Integer, ForeignKey("establecimiento.id_establecimiento"), primary_key=True)
    id_tipo_establecimiento = Column(
        Integer,
        ForeignKey("tipo_establecimiento.id_tipo_establecimiento"),
        primary_key=True,
    )
    
    # Relación con TipoEstablecimiento para eager loading
    tipo = relationship("TipoEstablecimiento", lazy="joined")
    
    @hybrid_property
    def nombre_categoria(self):
        """Expone el nombre del tipo de establecimiento"""
        return self.tipo.nombre_categoria if self.tipo else None
