import os
uri = os.environ["DATABASE_URI"] 
url = os.environ["DATABASE_URL"] 
if url and url.startswith("postgres://"): 
    url = url.replace("postgres://", "postgresql+psycopg2://")
    uri = uri.replace("postgres://", "postgresql://")


class Config(object):
    DEBUG = False
    TESTING = False
    CSRF_ENABLED = True
    SECRET_KEY = os.environ["SECRET_KEY"]
    SQLALCHEMY_DATABASE_URI = url # os.environ['DATABASE_URL'].replace('postgres', 'postgresql+psycopg2')
    SQLALCHEMY_DATABASE_URL = uri # os.environ['DATABASE_URL'].replace['DATABASE_URI']
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