import os

class Config(object):
    DEBUG = False
    TESTING = False
    CSRF_ENABLED = True
    SECRET_KEY = "qsdfq1212sdfqsdfefqfdfq"
    SQLALCHEMY_DATABASE_URI = os.environ['DATABASE_URL'].replace('postgres', 'postgresql+psycopg2')
    SQLALCHEMY_TRACK_MODIFICATIONS = False
    

class ProductionConfig(Config):
    DEBUG = False


class StagingConfig(Config):
    DEVELOPMENT = True
    DEBUG = True


class DevelopmentConfig(Config):
    DEVELOPMENT = True
    DEBUG = True
    HOST = '0.0.0.0'
    PORT = 5000


class TestingConfig(Config):
    TESTING = True