import os  # importe le module os

# Définit le chemin absolu vers le répertoire de l'application
basedir = os.path.abspath(os.path.dirname(__file__))

# Récupère l'URI de la base de données depuis l'environnement
uri = os.environ["DATABASE_URI"]

# Récupère l'URL de la base de données depuis l'environnement
url = os.environ["DATABASE_URL"]

# Si l'URL de la base de données existe et commence par "postgres://", remplace "postgres://" par "postgresql+psycopg2://"
if url and url.startswith("postgres://"):
    url = url.replace("postgres://", "postgresql+psycopg2://")

# Si l'URI de la base de données existe et commence par "postgres://", remplace "postgres://" par "postgresql://"
if uri and uri.startswith("postgres://"):
    uri = uri.replace("postgres://", "postgresql://")

# Crée une classe de configuration de base
class Config(object):
    # Désactive le débogage
    DEBUG = False
    # Désactive le mode de test
    TESTING = False
    # Active la protection contre les attaques CSRF
    CSRF_ENABLED = True
    # Récupère la clé secrète depuis l'environnement
    SECRET_KEY = os.environ["SECRET_KEY"]
    # Définit l'URI de la base de données
    SQLALCHEMY_DATABASE_URI = url
    # Définit l'URL de la base de données
    SQLALCHEMY_DATABASE_URL = uri
    # Désactive le suivi des modifications de SQLAlchemy
    SQLALCHEMY_TRACK_MODIFICATIONS = False
    # Définit le répertoire de téléchargement des fichiers
    UPLOAD_FOLDER = os.getcwd() + '/app/static/img/'

# Crée une classe de configuration de production en étendant la classe de configuration de base
class ProductionConfig(Config):
    # Désactive le débogage
    DEBUG = False

# Crée une classe de configuration de staging en étendant la classe de configuration de base
class StagingConfig(Config):
    # Active le développement
    DEVELOPMENT = True
    # Active le débogage
    DEBUG = True

# Crée une classe de configuration de développement en étendant la classe de configuration de base
class DevelopmentConfig(Config):
    # Active le développement
    DEVELOPMENT = True
    # Active le débogage
    DEBUG = True
    # Définit l'hôte sur "0.0.0

# Crée une classe de configuration de test en étendant la classe de configuration de base
class TestingConfig(Config):
    # Active le mode de test
    TESTING = True
