from sqlalchemy import Column, Integer, String, Boolean, DateTime, ForeignKey
from geoalchemy2 import Geometry
from geoalchemy2.shape import to_shape
from app.db.base import Base


class Establecimiento(Base):
	__tablename__ = "establecimiento"

	id_establecimiento = Column(Integer, primary_key=True, index=True)
	nombre = Column(String(255), nullable=False)
	direccion_texto = Column(String(512), nullable=True)
	coordenadas = Column(Geometry(geometry_type="POINT", srid=4326), nullable=False)
	estado_verificado = Column(Boolean, default=False, nullable=False)
	ultima_verificacion = Column(DateTime(timezone=True), nullable=True)
	verificador_id = Column(Integer, ForeignKey("usuarios.id_usuario"), nullable=True)

	@property
	def latitud(self):
		if self.coordenadas is None:
			return None
		try:
			return to_shape(self.coordenadas).y
		except Exception:
			return None

	@property
	def longitud(self):
		if self.coordenadas is None:
			return None
		try:
			return to_shape(self.coordenadas).x
		except Exception:
			return None
