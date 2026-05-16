from sqlalchemy import Column, Integer, ForeignKey
from sqlalchemy.orm import relationship
from sqlalchemy.ext.hybrid import hybrid_property

from app.db.base import Base


class EstablecimientoCategoria(Base):
    __tablename__ = "establecimiento_categoria"

    id_establecimiento = Column(Integer, ForeignKey("establecimiento.id_establecimiento"), primary_key=True)
    id_categoria = Column(Integer, ForeignKey("categoria_dieta.id_categoria"), primary_key=True)
    
    # Relación con CategoriaDieta para eager loading
    categoria = relationship("CategoriaDieta", lazy="joined")
    
    @hybrid_property
    def nombre_dieta(self):
        """Expone el nombre de la categoría de dieta"""
        return self.categoria.nombre_dieta if self.categoria else None

    @hybrid_property
    def color_hex(self):
        """Expone el color hex de la categoría de dieta"""
        return self.categoria.color_hex if self.categoria else '#FF6B6B'