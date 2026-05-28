from sqlalchemy import Column, Integer, String, Text, Float, ForeignKey

from app.db.base import Base


class ItemMenu(Base):
    __tablename__ = "item_menu"

    id_item_menu = Column(Integer, primary_key=True, index=True)
    nombre_item_menu = Column(String(255), nullable=False)
    descripcion = Column(Text, nullable=True)
    precio = Column(Float, nullable=False)
    id_establecimiento = Column(Integer, ForeignKey("establecimiento.id_establecimiento"), nullable=False)
    id_tipo_item_menu = Column(Integer, ForeignKey("tipo_item_menu.id_tipo_item"), nullable=True)
