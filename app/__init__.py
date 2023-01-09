'''
Ce code définit une fonction create_app qui prend en entrée un objet de configuration et crée une 
application Flask.

La fonction commence par créer une instance de Flask en lui passant en paramètre le nom du module 
courant (__name__). Ensuite, elle charge les configurations de l'application à partir de l'objet de 
configuration passé en paramètre.

Elle initialise ensuite les extensions db, migrate, bootstrap, log_manager et bcrypt en leur passant 
l'application Flask.

La fonction enregistre également deux blueprints (ensemble de routes et de vues liées) auprès de 
l'application : auxsan_bp et authentication. Le premier est enregistré avec un préfixe d'URL /auxsan, 
ce qui signifie que toutes les routes définies dans ce blueprint seront préfixées par /auxsan.

Enfin, la fonction retourne l'application Flask créée.
'''
import os
from flask import Flask
from app.db_extention import *

def create_app(config_type):
    """
    Crée une application Flask.
    
    :param config_type: Type de configuration à utiliser.
    :return: L'application Flask créée.
    """
    # Création de l'application Flask
    app = Flask(__name__)
  
    # Chargement des configurations
    app.config.from_object(config_type)

    # Initialisation de SQLAlchemy
    db.init_app(app)
    # Initialisation de Migrate
    migrate.init_app(app, db)
 
    # Initialisation de Bootstrap
    bootstrap.init_app(app)
    # Initialisation de LoginManager
    log_manager.init_app(app)
    # Initialisation de Bcrypt
    bcrypt.init_app(app) 
    
    # Enregistrement du blueprint auxsan_bp avec un préfixe d'URL
    from app.auxsan.auxsan_routes import auxsan_bp
    app.register_blueprint(auxsan_bp, url_prefix='/auxsan')

    # Enregistrement du blueprint authentication
    from app.auth import authentication
    app.register_blueprint(authentication)
    
    # Retour de l'application Flask
    return app




