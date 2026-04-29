from sqlalchemy import Column, Integer, ForeignKey

from app.db.base import Base


class UsuarioEstablecimientoFavorito(Base):
    __tablename__ = "usuario_establecimiento_favorito"

    id_usuario = Column(Integer, ForeignKey("usuarios.id_usuario"), primary_key=True)
    id_establecimiento = Column(Integer, ForeignKey("establecimiento.id_establecimiento"), primary_key=True)