from sqlalchemy import Column, Integer, String, ForeignKey
from app.db.base import Base


class Usuario(Base):
    __tablename__ = "usuarios"

    id_usuario = Column(Integer, primary_key=True, index=True)
    email = Column(String(255), unique=True, nullable=False)
    nombre_completo = Column(String(255), nullable=True)
    fotoPerfil = Column(String(512), nullable=True)
    id_rol = Column(Integer, ForeignKey("roles.id_rol"), nullable=True)
