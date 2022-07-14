from werkzeug.security import generate_password_hash as gph, check_password_hash as cph
from flask import Flask
# from config import *
from datetime import *
from flask_sqlalchemy import SQLAlchemy
from sqlalchemy import create_engine
from app.db_extention import *
from flask_login import UserMixin
from sqlalchemy.orm import Session
import os


uri = os.environ["DATABASE_URL"]  
if uri and uri.startswith("postgres://"): 
    uri = uri.replace("postgres://", "postgresql+psycopg2://")


#########################################
# BASE DE DONNEES StageM2_BD ############
#########################################
engine = create_engine(uri)
# app= Flask('__name__')

# app.config.from_object('config.ProductionConfig')

# db = SQLAlchemy(app)

# engine = db.engine
Base.prepare(engine, reflect=True)

session = Session(engine)


#########################################
# Utilisateurs Auxiliaire sanitaire
#########################################
@log_manager.user_loader
def load_user(user_id):
    return User.query.get(int(user_id))

class User(db.Model, UserMixin):

    __tablename__ = 'users'
    __table_args__ = {'extend_existing': True}
    id = db.Column(db.Integer(), primary_key = True)
    matricule = db.Column(db.String(10), unique = True)
    fonction = db.Column(db.String(100), nullable = False)
    mdp_hash = db.Column(db.String(128), nullable = False)
    dateinscription = db.Column(db.DateTime, default=datetime.now) 

    
    def check_password(self, mdp):
        return cph(self.mdp_hash, mdp)

    @classmethod
    def create_user(cls, matricule, fonction, mdp):

        user = cls(matricule = matricule, 
                   fonction = fonction,    
                   mdp_hash = gph(mdp))

        db.session.add(user)
        db.session.commit()
        return user



#########################################
# TABLES (MODELS) #######################
#########################################

accueil_blesse_en_zfsan = Base.classes.accueil_blesse_en_zfsan
alertes_niveaux_produit = Base.classes.alertes_niveaux_produit
armee                   = Base.classes.armee                  
attente_soin            = Base.classes.attente_soin           
blesse                  = Base.classes.blesse                 
capacite_transport      = Base.classes.capacite_transport     
categorie_vt            = Base.classes.categorie_vt           
civil                   = Base.classes.civil                  
demandevasan            = Base.classes.demandevasan           
destination             = Base.classes.destination            
disponibilite_vt        = Base.classes.disponibilite_vt       
div_bri                 = Base.classes.div_bri                
donnees_blesse          = Base.classes.donnees_blesse         
donnees_salle_soin      = Base.classes.donnees_salle_soin     
 
evasan                  = Base.classes.evasan                 

individu                = Base.classes.individu               
magasinsante            = Base.classes.magasinsante           
militaire               = Base.classes.militaire              
       
pays                    = Base.classes.pays                   
produit                 = Base.classes.produit                
salle_soin              = Base.classes.salle_soin             
sortiestrategiquezfsan  = Base.classes.sortiestrategiquezfsan 
type_vt                 = Base.classes.type_vt                
unite                   = Base.classes.unite                  
unites_elementaires     = Base.classes.unites_elementaires    
# User                    = Base.classes.users   
vecteur_transport       = Base.classes.vecteur_transport      
      
zfsante                 = Base.classes.zfsante
en_soin                 = Base.classes.en_soin     
vt_en_mission           = Base.classes.vt_en_mission 


def showblesse(maTable):
    lignes = []
    for instance in maTable:
        gdhblessure = str(instance.gdhblessure)
        gdhevacue = str(instance.gdhevacue)
        bles = [instance.matricule, instance.categorieabc, instance.coordonneesutmblesse, gdhblessure, gdhevacue, instance.unite_elementaire]
        lignes.append(bles)
    return lignes