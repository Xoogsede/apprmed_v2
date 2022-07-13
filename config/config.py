import os

from cv2 import HOUGH_STANDARD
basedir = os.path.abspath(os.path.dirname(__file__))

class Config(object):
    DEBUG = False
    TESTING = False
    CSRF_ENABLED = True
    SECRET_KEY = "qsdfq1212sdfqsdfefqfdfq"
    SQLALCHEMY_DATABASE_URI = os.environ('DATABASE_URL')
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