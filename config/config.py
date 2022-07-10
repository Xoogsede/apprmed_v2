import os
basedir = os.path.abspath(os.path.dirname(__file__))

class Config(object):
    DEBUG = False
    TESTING = False
    CSRF_ENABLED = True
    SECRET_KEY = 'Pnese45454s$$$$******ddddddddddd'
    SQLALCHEMY_DATABASE_URI = os.environ['DATABASE_URL']
    SQLALCHEMY_TRACK_MODIFICATIONS = False


class ProductionConfig(Config):
    DEBUG = False


class StagingConfig(Config):
    DEVELOPMENT = True
    DEBUG = True


class DevelopmentConfig(Config):
    DEVELOPMENT = True
    DEBUG = True


class TestingConfig(Config):
    TESTING = True



# # WTF_CSRF_SECRET_KEY = 'Pnese45454s$$$$******ddddddddddd'
# SECRET_KEY = 'Pnese45454s$$$$******ddddddddddd'

# postgresql = {
# 'HOST' : 'localhost',
# 'DATABASE' : 'StageM2_BD',
# 'USER' : 'postgres',
# 'PASSWORD' : 'Presentchezpostgresql12fois$',
# 'PORT' : 5432
# }

# # DATABASE_URI= 'postgres+psycopg2://{}:{}@{}:{}/{}'.format(USER, PASSWORD, HOST, PORT, DATABASE)
# # # 'postgres+psycopg2://{USER}:{PASSWORD}@{HOST}:{PORT}/{DATABASE}'

######################################################################################################

