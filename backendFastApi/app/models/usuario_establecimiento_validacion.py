from sqlalchemy import Column, Integer, ForeignKey, CheckConstraint

from app.db.base import Base


class UsuarioEstablecimientoValidacion(Base):
    __tablename__ = "usuario_establecimiento_validacion"
    __table_args__ = (
        CheckConstraint("valor IN (-1, 1)", name="validacion_valor_check"),
    )

    id_usuario = Column(Integer, ForeignKey("usuarios.id_usuario"), primary_key=True)
    id_establecimiento = Column(Integer, ForeignKey("establecimiento.id_establecimiento"), primary_key=True)
    valor = Column(Integer, nullable=False)