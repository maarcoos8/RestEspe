from sqlalchemy import Column, Integer, String, Boolean, DateTime, ForeignKey, func
from sqlalchemy.ext.hybrid import hybrid_property
from geoalchemy2 import Geometry
from geoalchemy2.shape import to_shape
from app.db.base import Base


class Establecimiento(Base):
	__tablename__ = "establecimiento"

	id_establecimiento = Column(Integer, primary_key=True, index=True)
	nombre = Column(String(255), nullable=False)
	direccion_texto = Column(String(512), nullable=True)
	imagen_url = Column(String(1024), nullable=True)
	coordenadas = Column(Geometry(geometry_type="POINT", srid=4326), nullable=True)
	estado_verificado = Column(Boolean, default=False, nullable=False)
	ultima_verificacion = Column(DateTime(timezone=True), nullable=True)
	verificador_id = Column(Integer, ForeignKey("usuarios.id_usuario"), nullable=True)
	propietario_id = Column(Integer, ForeignKey("usuarios.id_usuario"), nullable=True)


	@hybrid_property
	def latitud(self):
		# Python-side access: try to convert to shape
		if self.coordenadas is None:
			return None
		try:
			return to_shape(self.coordenadas).y
		except Exception:
			return None

	@latitud.expression
	def latitud(cls):
		# SQL expression for querying: use ST_Y
		return func.ST_Y(cls.coordenadas)

	@hybrid_property
	def longitud(self):
		if self.coordenadas is None:
			return None
		try:
			return to_shape(self.coordenadas).x
		except Exception:
			return None

	@longitud.expression
	def longitud(cls):
		# SQL expression for querying: use ST_X
		return func.ST_X(cls.coordenadas)
