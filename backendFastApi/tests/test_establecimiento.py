import unittest
from datetime import datetime
from types import SimpleNamespace
from unittest.mock import MagicMock, patch

from pydantic import ValidationError
from geoalchemy2.elements import WKTElement

from app.crud.crud_establecimiento import (
    create_establecimiento,
    get_establecimiento,
    get_establecimientos,
    get_establecimientos_filtrados,
    get_puntuacion_media_establecimiento,
    remove_establecimiento,
    update_establecimiento,
)
from app.models.establecimiento import Establecimiento
from app.schemas.establecimiento import EstablecimientoCreate, EstablecimientoUpdate


class TestEstablecimientoSchema(unittest.TestCase):
    def test_create_requires_contacto(self):
        with self.assertRaises(ValidationError):
            EstablecimientoCreate(nombre="Local sin contacto")


class TestEstablecimientoCrud(unittest.TestCase):
    def setUp(self):
        self.db = MagicMock()

    def test_create_establecimiento_sets_coordinates_and_verificador(self):
        entrada = EstablecimientoCreate(
            nombre="Restaurante demo",
            contacto="demo@example.com",
            latitud=40.4168,
            longitud=-3.7038,
            responsable_id=7,
            verificador_id=5,
        )

        resultado = create_establecimiento(self.db, entrada, verificador_id=9)

        self.assertEqual(resultado.nombre, "Restaurante demo")
        self.assertEqual(resultado.contacto, "demo@example.com")
        self.assertEqual(resultado.responsable_id, 7)
        self.assertEqual(resultado.verificador_id, 9)
        self.assertIsInstance(resultado.coordenadas, WKTElement)
        self.assertEqual(resultado.coordenadas.srid, 4326)
        self.assertIsNotNone(resultado.ultima_verificacion)
        self.db.add.assert_called_once()
        self.db.commit.assert_called_once()
        self.db.refresh.assert_called_once()

    def test_create_establecimiento_without_coordinates_leaves_geometry_empty(self):
        entrada = EstablecimientoCreate(
            nombre="Restaurante sin ubicacion",
            contacto="sinubicacion@example.com",
            responsable_id=3,
        )

        resultado = create_establecimiento(self.db, entrada)

        self.assertEqual(resultado.nombre, "Restaurante sin ubicacion")
        self.assertEqual(resultado.contacto, "sinubicacion@example.com")
        self.assertIsNone(resultado.coordenadas)
        self.assertIsNone(resultado.verificador_id)
        self.assertIsNone(resultado.ultima_verificacion)
        self.db.add.assert_called_once()
        self.db.commit.assert_called_once()
        self.db.refresh.assert_called_once()

    def test_get_establecimiento_by_id_returns_object(self):
        esperado = Establecimiento(nombre="Local por id", contacto="id@example.com")
        query = MagicMock()
        query.filter.return_value.first.return_value = esperado
        self.db.query.return_value = query

        resultado = get_establecimiento(self.db, 42)

        self.assertIs(resultado, esperado)

    def test_get_establecimientos_returns_list(self):
        esperado = [Establecimiento(nombre="Uno", contacto="uno@example.com")]
        query = MagicMock()
        query.offset.return_value.limit.return_value.all.return_value = esperado
        self.db.query.return_value = query

        resultado = get_establecimientos(self.db, skip=5, limit=20)

        self.assertEqual(resultado, esperado)
        query.offset.assert_called_once_with(5)
        query.offset.return_value.limit.assert_called_once_with(20)

    def test_update_establecimiento_updates_contacto_and_coordinates(self):
        establecimiento = Establecimiento(
            nombre="Local original",
            contacto="111111111",
            responsable_id=1,
        )
        cambios = EstablecimientoUpdate(
            nombre="Local actualizado",
            contacto="222222222",
            latitud=41.0,
            longitud=-4.0,
            estado_verificado=True,
            verificador_id=12,
        )

        resultado = update_establecimiento(self.db, establecimiento, cambios)

        self.assertIs(resultado, establecimiento)
        self.assertEqual(resultado.nombre, "Local actualizado")
        self.assertEqual(resultado.contacto, "222222222")
        self.assertIsInstance(resultado.coordenadas, WKTElement)
        self.assertEqual(resultado.coordenadas.srid, 4326)
        self.assertTrue(resultado.estado_verificado)
        self.assertEqual(resultado.verificador_id, 12)
        self.assertIsNotNone(resultado.ultima_verificacion)
        self.db.add.assert_called_once_with(establecimiento)
        self.db.commit.assert_called_once()
        self.db.refresh.assert_called_once_with(establecimiento)

    def test_remove_establecimiento_returns_none_when_missing(self):
        with patch("app.crud.crud_establecimiento.get_establecimiento", return_value=None):
            resultado = remove_establecimiento(self.db, 99)

        self.assertIsNone(resultado)
        self.db.delete.assert_not_called()
        self.db.commit.assert_not_called()

    def test_get_puntuacion_media_establecimiento_returns_counts(self):
        query = MagicMock()
        query.filter.return_value.one.return_value = (4.25, 8)
        self.db.query.return_value = query

        resultado = get_puntuacion_media_establecimiento(self.db, 15)

        self.assertEqual(resultado["puntuacion_media"], 4.25)
        self.assertEqual(resultado["numero_resenas"], 8)

    def test_get_establecimientos_filtrados_maps_contacto_and_rating(self):
        query = MagicMock()
        query.filter.return_value = query
        query.order_by.return_value = query
        query.offset.return_value = query
        query.limit.return_value = query
        query.all.return_value = [
            SimpleNamespace(
                id_establecimiento=1,
                nombre="Restaurante demo",
                direccion_texto="Calle Mayor 1",
                contacto="demo@example.com",
                imagen_url=None,
                latitud=40.4168,
                longitud=-3.7038,
                estado_verificado=True,
                ultima_verificacion=None,
                verificador_id=5,
                responsable_id=7,
                puntuacion_media=4.8,
            )
        ]

        with patch(
            "app.crud.crud_establecimiento._base_establecimiento_filtrado_query",
            return_value=(query, MagicMock()),
        ), patch(
            "app.crud.crud_establecimiento.get_categorias_dieta_con_conteo_por_establecimientos",
            return_value={1: []},
        ):
            resultado = get_establecimientos_filtrados(self.db)

        self.assertEqual(len(resultado), 1)
        self.assertEqual(resultado[0]["contacto"], "demo@example.com")
        self.assertEqual(resultado[0]["puntuacion_media"], 4.8)
        self.assertEqual(resultado[0]["categorias_dieta"], [])

    def test_get_establecimientos_filtrados_applies_solo_verificados(self):
        query = MagicMock()
        query.filter.return_value = query
        query.order_by.return_value = query
        query.offset.return_value = query
        query.limit.return_value = query
        query.all.return_value = []

        with patch(
            "app.crud.crud_establecimiento._base_establecimiento_filtrado_query",
            return_value=(query, MagicMock()),
        ), patch(
            "app.crud.crud_establecimiento.get_categorias_dieta_con_conteo_por_establecimientos",
            return_value={},
        ):
            resultado = get_establecimientos_filtrados(self.db, solo_verificados=True)

        self.assertEqual(resultado, [])
        self.assertEqual(query.filter.call_count, 1)