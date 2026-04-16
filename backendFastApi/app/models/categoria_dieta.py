from sqlalchemy import Column, Integer, String
from app.db.base import Base


class CategoriaDieta(Base):
    __tablename__ = "categoria_dieta"

    id_categoria = Column(Integer, primary_key=True, index=True)
    nombre_dieta = Column(String(150), unique=True, nullable=False)
