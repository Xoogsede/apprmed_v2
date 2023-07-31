'''Ce code importe plusieurs modules et définit une variable uri qui contient l'URI de la base de données. 
Si uri existe et commence par "postgres://", il est remplacé par "postgresql+psycopg2://".
'''
# Import des modules
from werkzeug.security import generate_password_hash as gph, check_password_hash as cph
from flask import Flask
from datetime import *
from flask_sqlalchemy import SQLAlchemy
from sqlalchemy import create_engine
from app.db_extention import *
from flask_login import UserMixin
from sqlalchemy.orm import Session
import os

# Récupération de l'URI de la base de données depuis les variables d'environnement
uri = os.environ["DATABASE_URL"]  

# Si l'URI existe et commence par "postgres://", remplacer par "postgresql+psycopg2://"
if uri and uri.startswith("postgres://"): 
    uri = uri.replace("postgres://", "postgresql+psycopg2://")



'''Ce code permet de créer une connexion à une base de données à l'aide de l'uri spécifié 
et de réfléchir à la structure de la base de données. Ensuite, une session est créée à 
partir de l'objet moteur pour permettre l'exécution de requêtes sur la base de données.
'''
# Création de l'objet moteur en utilisant l'uri de la base de données
engine = create_engine(uri)

# Préparation de la base de données en réfléchissant à sa structure
# Cela crée des classes de mappage de données pour chaque table de la base de données
Base.prepare(engine, reflect=True)

# Création d'une session à partir de l'objet moteur
# Cela permettra d'exécuter des requêtes sur la base de données
session = Session(engine)



#########################################
# Utilisateurs Auxiliaire sanitaire
#########################################
'''
Ce code définit une fonction "load_user" qui est utilisée comme chargeur d'utilisateur par le 
gestionnaire de connexion de Flask-Login. La fonction prend un identifiant d'utilisateur en 
entrée et renvoie l'objet utilisateur correspondant s'il existe.

Le code définit également une classe "User" qui représente un utilisateur de l'application. 
La classe hérite de "db.Model" et "UserMixin", qui sont des classes de base de données et de 
gestion de connexion de Flask-Login, respectivement. La classe définit plusieurs colonnes de 
base de données qui seront utilisées pour stocker les informations de l'utilisateur, telles 
que l'identifiant, le matricule, la fonction, le hash du mot de passe et la date d'inscription.

La classe "User" définit également une méthode "check_password" qui prend un mot de passe en entrée 
et vérifie si il correspond au mot de passe hashé stocké dans la base de données.

La classe "User" définit également une méthode de classe "create_user" qui prend en entrée un 
matricule, une fonction et un mot de passe, et crée un nouvel objet utilisateur en utilisant 
ces informations. Le mot de passe est hashé avant d'être stocké dans la base de données. 
L'objet utilisateur est ensuite ajouté à la session de base de données et la transaction est validée.

'''
@log_manager.user_loader
def load_user(user_id):
    # Chargement de l'utilisateur à partir de la base de données en utilisant l'identifiant d'utilisateur
    return User.query.get(int(user_id))

class User(db.Model, UserMixin):
    # Définition de la table et des colonnes de la base de données
    __tablename__ = 'users'
    __table_args__ = {'extend_existing': True}
    id = db.Column(db.Integer(), primary_key = True)
    matricule = db.Column(db.String(10), unique = True)
    fonction = db.Column(db.String(100), nullable = False)
    mdp_hash = db.Column(db.String(128), nullable = False)
    dateinscription = db.Column(db.DateTime, default=datetime.now) 
    is_password_changed = db.Column(db.Boolean(), default=False)


    # Méthode pour vérifier si un mot de passe entré correspond au mot de passe hashé stocké dans la base de données
    def check_password(self, mdp):
        return cph(self.mdp_hash, mdp)

    # Méthode de classe pour créer un nouvel utilisateur en utilisant le matricule, la fonction et le mot de passe donnés
    @classmethod
    def create_user(cls, matricule, fonction, mdp):
        # Création de l'objet utilisateur en hashant le mot de passe
        user = cls(matricule = matricule, 
                   fonction = fonction,    
                   mdp_hash = gph(mdp))

        # Ajout de l'objet utilisateur à la session de base de données et validation de la transaction
        db.session.add(user)
        db.session.commit()
        return user

    # Méthode pour changer le mot de passe d'un utilisateur
    def change_password(self, new_password):
        self.mdp_hash = gph(new_password)
        self.is_password_changed = True
        db.session.commit()



#########################################
# TABLES (MODELS) 
#########################################
'''
Ce code définit plusieurs variables qui font référence à des classes de mappage de données générées 
par SQLAlchemy. Ces classes sont utilisées pour représenter des tables de la base de données et 
permettent de manipuler les données de la base de données en utilisant des objets Python.

Chaque variable correspond à une classe de mappage de données qui a le même nom que la table 
correspondante dans la base de données. Par exemple, la variable "armee" fait référence à une 
classe de mappage de données qui représente la table "armee" de la base de données.
'''

# Définition de variables qui font référence à des classes de mappage de données
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



'''
La fonction "showblesse" prend en entrée une table de blessures (représentée par la variable "maTable") 
et retourne une liste de listes contenant les informations de chaque blessure.

La fonction parcourt chaque instance de "maTable" et extrait certaines informations, telles que le 
matricule, la catégorie ABC, les coordonnées UTM de la blessure, l'heure de la blessure et l'heure 
de l'évacuation. Ces informations sont ajoutées à une liste qui est ensuite ajoutée à la liste de lignes. 
La fonction retourne la liste de lignes une fois qu'elle a parcouru toutes les instances de "maTable".
'''
def showblesse(maTable):
    # Liste vide pour stocker les lignes de sortie
    lignes = []
    
    # Pour chaque instance de maTable, extraire certaines informations et les ajouter à une ligne
    for instance in maTable:
        # Conversion de l'heure de la blessure et de l'heure de l'évacuation en chaîne de caractères
        gdhblessure = str(instance.gdhblessure)
        gdhevacue = str(instance.gdhevacue)
        
        # Création de la ligne avec les informations extraites
        bles = [instance.matricule, instance.categorieabc, instance.coordonneesutmblesse, gdhblessure, gdhevacue, instance.unite_elementaire]
        
        # Ajout de la ligne à la liste de lignes
        lignes.append(bles)
    
    # Retour de la liste de lignes
    return lignes
