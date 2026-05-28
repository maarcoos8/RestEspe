"""Add propietario_id to establecimiento

Revision ID: 002_add_propietario_id
Revises: 001_add_color_hex
Create Date: 2026-05-16 12:05:00.000000

"""
from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = '002_add_propietario_id'
down_revision = '001_add_color_hex'
branch_labels = None
depends_on = None


def upgrade() -> None:
    bind = op.get_bind()
    inspector = sa.inspect(bind)

    columns = {column['name'] for column in inspector.get_columns('establecimiento')}
    if 'propietario_id' not in columns:
        op.add_column('establecimiento', sa.Column('propietario_id', sa.Integer(), nullable=True))

    foreign_keys = inspector.get_foreign_keys('establecimiento')
    has_fk = any(fk.get('name') == 'fk_establecimiento_propietario_id' for fk in foreign_keys)
    if not has_fk:
        op.create_foreign_key(
            'fk_establecimiento_propietario_id',
            'establecimiento',
            'usuarios',
            ['propietario_id'],
            ['id_usuario'],
        )


def downgrade() -> None:
    bind = op.get_bind()
    inspector = sa.inspect(bind)

    foreign_keys = inspector.get_foreign_keys('establecimiento')
    has_fk = any(fk.get('name') == 'fk_establecimiento_propietario_id' for fk in foreign_keys)
    if has_fk:
        op.drop_constraint('fk_establecimiento_propietario_id', 'establecimiento', type_='foreignkey')

    columns = {column['name'] for column in inspector.get_columns('establecimiento')}
    if 'propietario_id' in columns:
        op.drop_column('establecimiento', 'propietario_id')
