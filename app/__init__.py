import os
from flask import Flask
from flask_migrate import Migrate
# from config.config import DevelopmentConfig as dev , ProductionConfig as prod , TestingConfig as test 
from app.db_extention import *




# def scanmatricule():
import cv2
def video_reader():
    cam = cv2.VideoCapture(0)
    detector = cv2.QRCodeDetector()
    while True:
        _, img = cam.read()
        data, bbox, _ = detector.detectAndDecode(img)
        if data:
            break
        cv2.imshow("img", img)    
        if cv2.waitKey(1) == ord("Q"):
            break
    cam.release()
    cv2.destroyAllWindows()
    return data



def create_app(config_type):

    app = Flask(__name__)


    basedir = os.path.abspath(os.path.dirname(__file__))   
    app.config.from_object('config.DevelopmentConfig')
    # if config_type == 'dev':
    #     app.config.from_object(dev)
    # elif config_type == 'prod':
    #     app.config.from_object(prod)   
    # elif config_type == 'test':
    #     app.config.from_object(test)
    
    # app.config['SECRET_KEY'] =dev.SECRET_KEY
    # app.config['SQLALCHEMY_DATABASE_URL'] =dev.SQLALCHEMY_DATABASE_URL
    # app.config['SQLALCHEMY_DATABASE_URI'] = dev.SQLALCHEMY_DATABASE_URI
    # app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False




    db.init_app(app)    

    Migrate(app, db)
    bootstrap.init_app(app)
    log_manager.init_app(app)
    bcrypt.init_app(app)
    
    

    from app.auxsan.auxsan_routes import auxsan_bp
    app.register_blueprint(auxsan_bp, url_prefix='/auxsan')
    
    app.jinja_env.globals.update(video_reader=video_reader)

    from app.auth import authentication
    app.register_blueprint(authentication)
    

    return app
    



