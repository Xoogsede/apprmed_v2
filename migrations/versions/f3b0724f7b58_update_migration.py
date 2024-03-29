"""Update migration.

Revision ID: f3b0724f7b58
Revises: 
Create Date: 2022-07-24 22:34:19.842056

"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

# revision identifiers, used by Alembic.
revision = 'f3b0724f7b58'
down_revision = None
branch_labels = None
depends_on = None


def upgrade():
    # ### commands auto generated by Alembic - please adjust! ###
    op.drop_table('salle_soin')
    op.drop_table('destination')
    op.drop_table('donnees_blesse')
    op.drop_table('vt_en_mission')
    op.drop_table('blesse')
    op.drop_table('evasan')
    op.drop_table('sortiestrategiquezfsan')
    op.drop_table('individu')
    op.drop_table('categorie_vt')
    op.drop_table('capacite_transport')
    op.drop_table('div_bri')
    op.drop_table('militaire')
    op.drop_table('donnees_salle_soin')
    op.drop_table('produit')
    op.drop_table('accueil_blesse_en_zfsan')
    op.drop_table('zfsante')
    op.drop_table('armee')
    op.drop_table('magasinsante')
    op.drop_table('unite')
    op.drop_table('pays')
    op.drop_table('vecteur_transport')
    op.drop_table('type_vt')
    op.drop_table('disponibilite_vt')
    op.drop_table('civil')
    op.drop_table('unites_elementaires')
    op.drop_table('alertes_niveaux_produit')
    op.drop_table('demandevasan')
    op.drop_table('attente_soin')
    op.drop_table('en_soin')
    op.alter_column('users', 'matricule',
               existing_type=sa.VARCHAR(length=10),
               nullable=True)
    # ### end Alembic commands ###


def downgrade():
    # ### commands auto generated by Alembic - please adjust! ###
    op.alter_column('users', 'matricule',
               existing_type=sa.VARCHAR(length=10),
               nullable=False)
    op.create_table('en_soin',
    sa.Column('idblesse', sa.INTEGER(), autoincrement=False, nullable=False),
    sa.Column('idsalle', sa.INTEGER(), autoincrement=False, nullable=False),
    sa.Column('numsoin', sa.INTEGER(), autoincrement=True, nullable=False),
    sa.ForeignKeyConstraint(['idblesse'], ['blesse.idblesse'], name='fk_ensoin_idblesse'),
    sa.ForeignKeyConstraint(['idsalle'], ['salle_soin.idsalle'], name='fk_ensoin_idsalle'),
    sa.PrimaryKeyConstraint('numsoin', name='en_soin_pkey')
    )
    op.create_table('attente_soin',
    sa.Column('idzfsante', sa.INTEGER(), autoincrement=False, nullable=False),
    sa.Column('coordonneutm', sa.VARCHAR(), autoincrement=False, nullable=False),
    sa.Column('libeletype', sa.VARCHAR(length=50), autoincrement=False, nullable=True),
    sa.Column('idblesse', sa.BIGINT(), autoincrement=False, nullable=False),
    sa.Column('categorieabc', sa.VARCHAR(length=1), autoincrement=False, nullable=False),
    sa.Column('gdharrivee', postgresql.TIMESTAMP(timezone=True), server_default=sa.text('now()'), autoincrement=False, nullable=False),
    sa.ForeignKeyConstraint(['idblesse'], ['blesse.idblesse'], name='attentesoin_idblesse_fkey'),
    sa.PrimaryKeyConstraint('idblesse', name='attentesoin_pkey')
    )
    op.create_table('demandevasan',
    sa.Column('numdemande', sa.BIGINT(), autoincrement=False, nullable=False),
    sa.Column('unite_elementaire', sa.VARCHAR(length=150), autoincrement=False, nullable=False),
    sa.Column('coordonneutm', sa.VARCHAR(), autoincrement=False, nullable=False),
    sa.Column('nblessea', sa.INTEGER(), autoincrement=False, nullable=True),
    sa.Column('nblesseb', sa.INTEGER(), autoincrement=False, nullable=True),
    sa.Column('nblessec', sa.INTEGER(), autoincrement=False, nullable=True),
    sa.Column('gdhdemande', postgresql.TIME(timezone=True), server_default=sa.text('now()'), autoincrement=False, nullable=False),
    sa.ForeignKeyConstraint(['unite_elementaire'], ['unites_elementaires.unite_elementaire'], name='demandevasan_unite_elementaire'),
    sa.PrimaryKeyConstraint('numdemande', name='demandevasan_pkey'),
    postgresql_ignore_search_path=False
    )
    op.create_table('alertes_niveaux_produit',
    sa.Column('idproduit', sa.INTEGER(), autoincrement=False, nullable=False),
    sa.Column('qtemin', sa.INTEGER(), server_default=sa.text('0'), autoincrement=False, nullable=False),
    sa.Column('qtemax', sa.INTEGER(), autoincrement=False, nullable=False),
    sa.Column('datelimite', sa.DATE(), autoincrement=False, nullable=False),
    sa.ForeignKeyConstraint(['idproduit'], ['produit.idproduit'], name='fk_alertes_niveaux_produit_idproduit'),
    sa.PrimaryKeyConstraint('idproduit', name='alertes_niveaux_produit_pkey')
    )
    op.create_table('unites_elementaires',
    sa.Column('codepays', sa.VARCHAR(length=2), autoincrement=False, nullable=False),
    sa.Column('pays', sa.TEXT(), autoincrement=False, nullable=False),
    sa.Column('nomarmee', sa.TEXT(), autoincrement=False, nullable=False),
    sa.Column('nomunite', sa.VARCHAR(), autoincrement=False, nullable=False),
    sa.Column('div_bri', sa.TEXT(), autoincrement=False, nullable=False),
    sa.Column('unite_elementaire', sa.VARCHAR(length=150), autoincrement=False, nullable=False),
    sa.PrimaryKeyConstraint('unite_elementaire', name='unite_elementaire_pkey'),
    postgresql_ignore_search_path=False
    )
    op.create_table('civil',
    sa.Column('matricule', sa.VARCHAR(length=10), server_default=sa.text("nextval('idcivil'::regclass)"), autoincrement=False, nullable=False),
    sa.Column('nom', sa.TEXT(), autoincrement=False, nullable=False),
    sa.Column('prenom', sa.TEXT(), autoincrement=False, nullable=False),
    sa.Column('categoriehf', sa.TEXT(), autoincrement=False, nullable=False),
    sa.Column('date_naissance', sa.DATE(), autoincrement=False, nullable=False),
    sa.Column('lieu_naissance', sa.TEXT(), autoincrement=False, nullable=True),
    sa.Column('pays', sa.VARCHAR(length=50), autoincrement=False, nullable=True),
    sa.Column('adresse', sa.VARCHAR(length=50), autoincrement=False, nullable=True),
    sa.CheckConstraint("date_naissance > '1900-01-01'::date", name='individu_date_naissance_check'),
    sa.PrimaryKeyConstraint('matricule', name='civil_pkey')
    )
    op.create_table('disponibilite_vt',
    sa.Column('idvt', sa.VARCHAR(length=50), autoincrement=False, nullable=False),
    sa.Column('etat', sa.TEXT(), server_default=sa.text("'DISPO'::text"), autoincrement=False, nullable=False),
    sa.ForeignKeyConstraint(['idvt'], ['vecteur_transport.idvt'], name='dispo_fkey', ondelete='CASCADE'),
    sa.PrimaryKeyConstraint('idvt', name='dispo_pkey')
    )
    op.create_table('type_vt',
    sa.Column('idtypevt', sa.VARCHAR(length=9), autoincrement=False, nullable=False),
    sa.PrimaryKeyConstraint('idtypevt', name='type_vt_pkey')
    )
    op.create_table('vecteur_transport',
    sa.Column('idtypevt', sa.VARCHAR(length=9), autoincrement=False, nullable=False),
    sa.Column('idcat', sa.VARCHAR(length=3), autoincrement=False, nullable=False),
    sa.Column('libelecategorie', sa.TEXT(), autoincrement=False, nullable=True),
    sa.Column('modecirculation', sa.VARCHAR(length=2), autoincrement=False, nullable=True),
    sa.Column('idcapacite', sa.INTEGER(), autoincrement=False, nullable=False),
    sa.Column('capa', sa.INTEGER(), autoincrement=False, nullable=False),
    sa.Column('capb', sa.INTEGER(), autoincrement=False, nullable=False),
    sa.Column('capc', sa.INTEGER(), autoincrement=False, nullable=False),
    sa.Column('idvt', sa.VARCHAR(length=50), autoincrement=False, nullable=False),
    sa.Column('appellationvt', sa.VARCHAR(length=100), autoincrement=False, nullable=True),
    sa.PrimaryKeyConstraint('idvt', name='vecteur_transport_pkey'),
    postgresql_ignore_search_path=False
    )
    op.create_table('pays',
    sa.Column('codepays', sa.VARCHAR(length=2), autoincrement=False, nullable=False),
    sa.Column('pays', sa.TEXT(), autoincrement=False, nullable=False),
    sa.PrimaryKeyConstraint('codepays', name='allies_pkey'),
    sa.UniqueConstraint('codepays', name='allies_codepays_key')
    )
    op.create_table('unite',
    sa.Column('codepays', sa.VARCHAR(length=2), autoincrement=False, nullable=False),
    sa.Column('pays', sa.TEXT(), autoincrement=False, nullable=False),
    sa.Column('nomarmee', sa.TEXT(), autoincrement=False, nullable=False),
    sa.Column('nomunite', sa.VARCHAR(), autoincrement=False, nullable=False),
    sa.Column('div_bri', sa.TEXT(), autoincrement=False, nullable=False),
    sa.PrimaryKeyConstraint('nomunite', name='unite_pkey'),
    sa.UniqueConstraint('nomunite', name='unite_nomunite_key')
    )
    op.create_table('magasinsante',
    sa.Column('idzfsante', sa.INTEGER(), autoincrement=False, nullable=False),
    sa.Column('coordonneutm', sa.VARCHAR(), autoincrement=False, nullable=False),
    sa.Column('libeletype', sa.VARCHAR(length=50), autoincrement=False, nullable=True),
    sa.Column('idmagasin', sa.INTEGER(), autoincrement=False, nullable=False),
    sa.Column('typemagasin', sa.VARCHAR(), autoincrement=False, nullable=True),
    sa.PrimaryKeyConstraint('idmagasin', name='magasinsante_pkey'),
    postgresql_ignore_search_path=False
    )
    op.create_table('armee',
    sa.Column('codepays', sa.VARCHAR(length=2), autoincrement=False, nullable=False),
    sa.Column('pays', sa.TEXT(), autoincrement=False, nullable=False),
    sa.Column('nomarmee', sa.TEXT(), autoincrement=False, nullable=False),
    sa.PrimaryKeyConstraint('nomarmee', name='armee_pkey'),
    sa.UniqueConstraint('nomarmee', name='armee_nomarmee_key')
    )
    op.create_table('zfsante',
    sa.Column('idzfsante', sa.INTEGER(), autoincrement=False, nullable=False),
    sa.Column('coordonneutm', sa.VARCHAR(), autoincrement=False, nullable=False),
    sa.Column('libeletype', sa.VARCHAR(length=50), autoincrement=False, nullable=True),
    sa.PrimaryKeyConstraint('idzfsante', name='zfsante_pkey')
    )
    op.create_table('accueil_blesse_en_zfsan',
    sa.Column('idzfsante', sa.INTEGER(), autoincrement=False, nullable=False),
    sa.Column('coordonneutm', sa.VARCHAR(), autoincrement=False, nullable=False),
    sa.Column('libeletype', sa.VARCHAR(length=50), autoincrement=False, nullable=True),
    sa.Column('idblesse', sa.BIGINT(), autoincrement=False, nullable=False),
    sa.Column('categorieabc', sa.VARCHAR(length=1), autoincrement=False, nullable=False),
    sa.Column('gdharrivee', postgresql.TIMESTAMP(timezone=True), server_default=sa.text('now()'), autoincrement=False, nullable=False),
    sa.ForeignKeyConstraint(['idblesse'], ['blesse.idblesse'], name='accueil_idblesse_fkey'),
    sa.PrimaryKeyConstraint('idblesse', name='accueil_blesse_pkey')
    )
    op.create_table('produit',
    sa.Column('idproduit', sa.INTEGER(), autoincrement=False, nullable=False),
    sa.Column('idmagasin', sa.INTEGER(), autoincrement=False, nullable=False),
    sa.Column('nomproduit', sa.TEXT(), autoincrement=False, nullable=False),
    sa.Column('qteproduit', sa.INTEGER(), autoincrement=False, nullable=False),
    sa.Column('conditionstockage', sa.TEXT(), autoincrement=False, nullable=False),
    sa.Column('dureestockage', sa.DATE(), autoincrement=False, nullable=False),
    sa.ForeignKeyConstraint(['idmagasin'], ['magasinsante.idmagasin'], name='fk_produit_idmagasin'),
    sa.PrimaryKeyConstraint('idproduit', name='produit_pkey')
    )
    op.create_table('donnees_salle_soin',
    sa.Column('idsalle', sa.INTEGER(), autoincrement=False, nullable=False),
    sa.Column('gdhentree', sa.DATE(), autoincrement=False, nullable=True),
    sa.Column('gdhsortie', sa.DATE(), autoincrement=False, nullable=True),
    sa.ForeignKeyConstraint(['idsalle'], ['salle_soin.idsalle'], name='fk_donnees_salle_soin_idsalle'),
    sa.PrimaryKeyConstraint('idsalle', name='donnees_salle_soin_pkey')
    )
    op.create_table('militaire',
    sa.Column('codepays', sa.VARCHAR(length=2), autoincrement=False, nullable=False),
    sa.Column('pays', sa.TEXT(), autoincrement=False, nullable=False),
    sa.Column('nomarmee', sa.TEXT(), autoincrement=False, nullable=False),
    sa.Column('nomunite', sa.VARCHAR(), autoincrement=False, nullable=False),
    sa.Column('div_bri', sa.TEXT(), autoincrement=False, nullable=False),
    sa.Column('unite_elementaire', sa.VARCHAR(length=150), autoincrement=False, nullable=False),
    sa.Column('matricule', sa.VARCHAR(length=10), server_default=sa.text("nextval('idcivil'::regclass)"), autoincrement=False, nullable=False),
    sa.Column('nom', sa.TEXT(), autoincrement=False, nullable=False),
    sa.Column('prenom', sa.TEXT(), autoincrement=False, nullable=False),
    sa.Column('categoriehf', sa.TEXT(), autoincrement=False, nullable=False),
    sa.Column('date_naissance', sa.DATE(), autoincrement=False, nullable=False),
    sa.Column('lieu_naissance', sa.TEXT(), autoincrement=False, nullable=True),
    sa.Column('grade', sa.TEXT(), autoincrement=False, nullable=False),
    sa.Column('catmilitaire', sa.TEXT(), autoincrement=False, nullable=True),
    sa.CheckConstraint("date_naissance > '1900-01-01'::date", name='individu_date_naissance_check'),
    sa.PrimaryKeyConstraint('matricule', name='militaire_pkey'),
    sa.UniqueConstraint('matricule', name='matricule_militaire')
    )
    op.create_table('div_bri',
    sa.Column('codepays', sa.VARCHAR(length=2), autoincrement=False, nullable=False),
    sa.Column('pays', sa.TEXT(), autoincrement=False, nullable=False),
    sa.Column('nomarmee', sa.TEXT(), autoincrement=False, nullable=False),
    sa.Column('div_bri', sa.TEXT(), autoincrement=False, nullable=False),
    sa.PrimaryKeyConstraint('div_bri', name='div_bri_pkey')
    )
    op.create_table('capacite_transport',
    sa.Column('idtypevt', sa.VARCHAR(length=9), autoincrement=False, nullable=False),
    sa.Column('idcat', sa.VARCHAR(length=3), autoincrement=False, nullable=False),
    sa.Column('libelecategorie', sa.TEXT(), autoincrement=False, nullable=True),
    sa.Column('modecirculation', sa.VARCHAR(length=2), autoincrement=False, nullable=True),
    sa.Column('idcapacite', sa.INTEGER(), autoincrement=False, nullable=False),
    sa.Column('capa', sa.INTEGER(), autoincrement=False, nullable=False),
    sa.Column('capb', sa.INTEGER(), autoincrement=False, nullable=False),
    sa.Column('capc', sa.INTEGER(), autoincrement=False, nullable=False),
    sa.PrimaryKeyConstraint('idcapacite', name='capacite_transport_pkey')
    )
    op.create_table('categorie_vt',
    sa.Column('idtypevt', sa.VARCHAR(length=9), autoincrement=False, nullable=False),
    sa.Column('idcat', sa.VARCHAR(length=3), autoincrement=False, nullable=False),
    sa.Column('libelecategorie', sa.TEXT(), autoincrement=False, nullable=True),
    sa.Column('modecirculation', sa.VARCHAR(length=2), autoincrement=False, nullable=True),
    sa.PrimaryKeyConstraint('idcat', name='categorie_vt_pkey')
    )
    op.create_table('individu',
    sa.Column('matricule', sa.VARCHAR(length=10), server_default=sa.text("nextval('idcivil'::regclass)"), autoincrement=False, nullable=False),
    sa.Column('nom', sa.TEXT(), autoincrement=False, nullable=False),
    sa.Column('prenom', sa.TEXT(), autoincrement=False, nullable=False),
    sa.Column('categoriehf', sa.TEXT(), autoincrement=False, nullable=False),
    sa.Column('date_naissance', sa.DATE(), autoincrement=False, nullable=False),
    sa.Column('lieu_naissance', sa.TEXT(), autoincrement=False, nullable=True),
    sa.CheckConstraint("date_naissance > '1900-01-01'::date", name='individu_date_naissance_check'),
    sa.PrimaryKeyConstraint('matricule', name='individu_pkey'),
    postgresql_ignore_search_path=False
    )
    op.create_table('sortiestrategiquezfsan',
    sa.Column('idblesse', sa.BIGINT(), autoincrement=False, nullable=False),
    sa.Column('gdhdemandesortie', postgresql.TIME(timezone=True), server_default=sa.text('now()'), autoincrement=False, nullable=False),
    sa.ForeignKeyConstraint(['idblesse'], ['blesse.idblesse'], name='sortiestrategiquezfsan_fkey'),
    sa.PrimaryKeyConstraint('idblesse', name='sortiestrategiquezfsan_pkey')
    )
    op.create_table('evasan',
    sa.Column('numevasan', sa.BIGINT(), autoincrement=False, nullable=False),
    sa.Column('numdemande', sa.BIGINT(), autoincrement=False, nullable=False),
    sa.Column('gdhdepartzfsan', postgresql.TIME(timezone=True), autoincrement=False, nullable=False),
    sa.Column('coordonneutm', sa.TEXT(), autoincrement=False, nullable=False),
    sa.Column('coordonneutm1', sa.TEXT(), autoincrement=False, nullable=False),
    sa.Column('capacite', sa.INTEGER(), autoincrement=False, nullable=False),
    sa.Column('gdharrivefront', postgresql.TIMESTAMP(timezone=True), autoincrement=False, nullable=True),
    sa.Column('gdhdepartfront', postgresql.TIMESTAMP(timezone=True), autoincrement=False, nullable=True),
    sa.Column('blessevacue', postgresql.ARRAY(sa.VARCHAR()), autoincrement=False, nullable=True),
    sa.ForeignKeyConstraint(['coordonneutm'], ['destination.coordonneutm'], name='evasan_coordonneutm_fkey'),
    sa.ForeignKeyConstraint(['coordonneutm1'], ['destination.coordonneutm'], name='evasan_coordonneutm1_fkey'),
    sa.ForeignKeyConstraint(['numdemande'], ['demandevasan.numdemande'], name='evasan_numdemande_fkey'),
    sa.PrimaryKeyConstraint('numevasan', name='evasan_pkey'),
    postgresql_ignore_search_path=False
    )
    op.create_table('blesse',
    sa.Column('idblesse', sa.INTEGER(), server_default=sa.text("nextval('idblesseseq'::regclass)"), autoincrement=True, nullable=False),
    sa.Column('matricule', sa.VARCHAR(length=10), autoincrement=False, nullable=False),
    sa.Column('categorieabc', sa.VARCHAR(length=1), autoincrement=False, nullable=False),
    sa.Column('coordonneesutmblesse', sa.VARCHAR(length=50), autoincrement=False, nullable=False),
    sa.Column('gdhblessure', postgresql.TIMESTAMP(timezone=True), autoincrement=False, nullable=False),
    sa.Column('gdhevacue', postgresql.TIMESTAMP(timezone=True), autoincrement=False, nullable=True),
    sa.Column('unite_elementaire', sa.VARCHAR(length=150), autoincrement=False, nullable=True),
    sa.Column('numdemande', sa.BIGINT(), autoincrement=False, nullable=True),
    sa.Column('symptomes', sa.VARCHAR(), autoincrement=False, nullable=True),
    sa.Column('blesse_couche', sa.BOOLEAN(), server_default=sa.text('true'), autoincrement=False, nullable=False),
    sa.ForeignKeyConstraint(['matricule'], ['individu.matricule'], name='blesse_fkey'),
    sa.PrimaryKeyConstraint('idblesse', name='blesse_pkey'),
    postgresql_ignore_search_path=False
    )
    op.create_table('vt_en_mission',
    sa.Column('numevasan', sa.BIGINT(), autoincrement=False, nullable=False),
    sa.Column('idvt', sa.VARCHAR(length=50), autoincrement=False, nullable=False),
    sa.Column('numission', sa.INTEGER(), autoincrement=True, nullable=False),
    sa.ForeignKeyConstraint(['idvt'], ['vecteur_transport.idvt'], name='fk_vt_en_mission_idvt'),
    sa.ForeignKeyConstraint(['numevasan'], ['evasan.numevasan'], name='fk_vt_en_mission_numevasan'),
    sa.PrimaryKeyConstraint('numission', name='vt_en_mission_pkey')
    )
    op.create_table('donnees_blesse',
    sa.Column('idblesse', sa.INTEGER(), autoincrement=False, nullable=False),
    sa.Column('gdhblessure', postgresql.TIMESTAMP(timezone=True), autoincrement=False, nullable=False),
    sa.Column('gdhevacue', postgresql.TIMESTAMP(timezone=True), autoincrement=False, nullable=True),
    sa.ForeignKeyConstraint(['idblesse'], ['blesse.idblesse'], name='donnees_blesse_idblesse', onupdate='CASCADE', ondelete='RESTRICT'),
    sa.PrimaryKeyConstraint('idblesse', name='donnees_blesse_pkey')
    )
    op.create_table('destination',
    sa.Column('coordonneutm', sa.VARCHAR(), autoincrement=False, nullable=False),
    sa.Column('libele', sa.VARCHAR(), autoincrement=False, nullable=True),
    sa.PrimaryKeyConstraint('coordonneutm', name='destination_pkey')
    )
    op.create_table('salle_soin',
    sa.Column('idzfsante', sa.INTEGER(), autoincrement=False, nullable=False),
    sa.Column('coordonneutm', sa.VARCHAR(), autoincrement=False, nullable=False),
    sa.Column('libeletype', sa.VARCHAR(length=50), autoincrement=False, nullable=True),
    sa.Column('idsalle', sa.INTEGER(), autoincrement=False, nullable=False),
    sa.Column('typesoin', sa.VARCHAR(length=50), autoincrement=False, nullable=True),
    sa.Column('capacite', postgresql.ARRAY(sa.BIGINT()), server_default=sa.text('ARRAY[]::bigint[]'), autoincrement=False, nullable=True),
    sa.PrimaryKeyConstraint('idsalle', name='salle_soin_pkey')
    )
    # ### end Alembic commands ###
