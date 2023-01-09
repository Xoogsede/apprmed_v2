'''
Ce code importe plusieurs modules et définit plusieurs variables qui seront utilisées dans 
l'application Flask.

    "SQLAlchemy" est une extension de Flask qui permet de gérer une base de données en utilisant le mappage objet-relationnel (ORM) de SQLAlchemy.
    "Migrate" est une extension de Flask qui permet de gérer les migrations de base de données.
    "automap_base" est une fonction de SQLAlchemy qui permet de générer automatiquement des classes de mappage de données à partir de tables de base de données existantes.
    "Session" est une classe de SQLAlchemy qui permet de gérer une session de base de données.
    "LoginManager" est une extension de Flask qui gère la gestion des connexions utilisateur.
    "Bootstrap" est une extension de Flask qui ajoute le support de Bootstrap à l'application.
    "Bcrypt" est une extension de Flask qui permet de crypter et de vérifier les mots de passe.

Le code définit également une variable "ALLOWED_EXTENSIONS" qui contient une liste de types de 
fichiers autorisés et une fonction "allowed_file" qui vérifie si un fichier a une extension autorisée.
'''
# Import des modules
from flask_sqlalchemy import SQLAlchemy
from flask_migrate import Migrate
from sqlalchemy.ext.automap import automap_base
from sqlalchemy.orm import Session
from flask_login import LoginManager
from flask_bootstrap import Bootstrap
from flask_bcrypt import Bcrypt

# Initialisation de SQLAlchemy
db = SQLAlchemy()

# Initialisation de Migrate
migrate = Migrate()

# Création de la base de mappage de données
Base = automap_base()

# Initialisation de Bootstrap
bootstrap = Bootstrap() 

# Initialisation de LoginManager
log_manager = LoginManager()
# Configuration de la vue de connexion
log_manager.login_view = 'authentication.login'
# Configuration de la protection de la session
log_manager.session_protection = 'strong'

# Initialisation de Bcrypt
bcrypt = Bcrypt()

# Définition des types de fichiers autorisés
ALLOWED_EXTENSIONS = {'txt', 'pdf', 'png', 'jpg', 'jpeg', 'gif'}

def allowed_file(filename):
    """
    Vérifie si un fichier a une extension autorisée.
    
    :param filename: Nom du fichier à vérifier.
    :return: True si le fichier a une extension autorisée, False sinon.
    """
    # Vérifie si le fichier a une extension et si cette extension est autorisée
    return '.' in filename and filename.rsplit('.', 1)[1].lower() in ALLOWED_EXTENSIONS

