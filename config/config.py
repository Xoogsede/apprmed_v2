import os

basedir = os.path.abspath(os.path.dirname(__file__))

HEROKU = 'HEROKU' or 'heroku' in os.environ

if HEROKU:
    DATABASE_URL = os.environ.get('HEROKU_DATABASE_URL')
else:
    DATABASE_URL = os.environ.get('DATABASE_URI')

class Config(object):
    DEBUG = False
    TESTING = False
    CSRF_ENABLED = True
    SECRET_KEY = "qsdfq1212sdfqsdfefqfdfq"
    SQLALCHEMY_DATABASE_URI = DATABASE_URL
    #SQLALCHEMY_DATABASE_URL = os.getenv('DATABASE_URL')
    SQLALCHEMY_TRACK_MODIFICATIONS = False
    

class ProductionConfig(Config):
    DEBUG = False


class StagingConfig(Config):
    DEVELOPMENT = True
    DEBUG = True


class DevelopmentConfig(Config):
    DEVELOPMENT = True
    DEBUG = True
    HOST = '10.211.55.18'
    PORT = 9999


class TestingConfig(Config):
    TESTING = True