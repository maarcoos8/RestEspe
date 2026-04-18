from sqlalchemy import Column, Integer, ForeignKey

from app.db.base import Base


class ItemCategoria(Base):
    __tablename__ = "item_categoria"

    id_item_menu = Column(Integer, ForeignKey("item_menu.id_item_menu"), primary_key=True)
    id_categoria = Column(Integer, ForeignKey("categoria_dieta.id_categoria"), primary_key=True)
