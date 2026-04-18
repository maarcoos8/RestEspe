from sqlalchemy import Column, Integer, String, ForeignKey

from app.db.base import Base


class TipoItemMenu(Base):
    __tablename__ = "tipo_item_menu"

    id_tipo_item = Column(Integer, primary_key=True, index=True)
    id_establecimiento = Column(Integer, ForeignKey("establecimiento.id_establecimiento"), nullable=False)
    nombre_tipo = Column(String(150), nullable=False)
