"""Add contacto to establecimiento and validation votes

Revision ID: 004_contacto_validation
Revises: 003_nullable_tipo_item
Create Date: 2026-06-11 00:00:00.000000

"""
from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = '004_contacto_validation'
down_revision = '003_nullable_tipo_item'
branch_labels = None
depends_on = None


def upgrade() -> None:
    bind = op.get_bind()
    inspector = sa.inspect(bind)

    establecimiento_columns = {column['name'] for column in inspector.get_columns('establecimiento')}
    if 'contacto' not in establecimiento_columns:
        op.add_column(
            'establecimiento',
            sa.Column('contacto', sa.String(length=255), nullable=False, server_default=''),
        )

    tables = set(inspector.get_table_names())
    if 'usuario_establecimiento_validacion' not in tables:
        op.create_table(
            'usuario_establecimiento_validacion',
            sa.Column('id_usuario', sa.Integer(), sa.ForeignKey('usuarios.id_usuario'), primary_key=True),
            sa.Column(
                'id_establecimiento',
                sa.Integer(),
                sa.ForeignKey('establecimiento.id_establecimiento'),
                primary_key=True,
            ),
            sa.Column('valor', sa.Integer(), nullable=False),
            sa.CheckConstraint('valor IN (-1, 1)', name='validacion_valor_check'),
        )


def downgrade() -> None:
    bind = op.get_bind()
    inspector = sa.inspect(bind)

    tables = set(inspector.get_table_names())
    if 'usuario_establecimiento_validacion' in tables:
        op.drop_table('usuario_establecimiento_validacion')

    establecimiento_columns = {column['name'] for column in inspector.get_columns('establecimiento')}
    if 'contacto' in establecimiento_columns:
        op.drop_column('establecimiento', 'contacto')