from flask_sqlalchemy import SQLAlchemy
from flask_migrate import Migrate
from sqlalchemy.ext.automap import automap_base
from sqlalchemy.orm import Session
from flask_login import LoginManager
from flask_bootstrap import Bootstrap
from flask_bcrypt import Bcrypt

db = SQLAlchemy()

migrate = Migrate() # migration
    
Base = automap_base()

bootstrap = Bootstrap() 

log_manager = LoginManager()
log_manager.login_view = 'authentication.login'
log_manager.session_protection = 'strong'

bcrypt = Bcrypt()

ALLOWED_EXTENSIONS = {'txt', 'pdf', 'png', 'jpg', 'jpeg', 'gif'}
def allowed_file(filename):
    return '.' in filename and \
           filename.rsplit('.', 1)[1].lower() in ALLOWED_EXTENSIONS
