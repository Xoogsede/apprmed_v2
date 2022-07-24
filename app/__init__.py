import os
from flask import Flask
from app.db_extention import *


def create_app(config_type):

    app = Flask(__name__)
  
    app.config.from_object(config_type)

    db.init_app(app)
    migrate.init_app(app, db)
 
    bootstrap.init_app(app)
    log_manager.init_app(app)
    bcrypt.init_app(app) 
    

    from app.auxsan.auxsan_routes import auxsan_bp
    app.register_blueprint(auxsan_bp, url_prefix='/auxsan')

    from app.auth import authentication
    app.register_blueprint(authentication)
    

    return app
    



