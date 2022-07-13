import os
from flask import Flask
from flask_migrate import Migrate
from app.db_extention import *




# def scanmatricule():
import cv2
import numpy as np
from pyzbar.pyzbar import decode 
def video_reader():
    cam = cv2.VideoCapture(1)
    detector = cv2.QRCodeDetector()
    while True:
        _, img = cam.read()
        data, bbox, _ = detector.detectAndDecode(img)
        for matricule in decode(img):
            contour = np.array([matricule.polygon],np.int32)
            contour = contour.reshape((-1,1,2))
            cv2.polylines(img, [contour], True, (128,32, 255), 5)
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
    app.config.from_object(config_type)

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
    



