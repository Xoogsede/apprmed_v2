# app launch
from app import create_app
from app.db_extention import db
from app.models import User
import os

rmedapp = create_app('config.ProductionConfig')
with rmedapp.app_context():
    db.create_all()
    try:    
        if not User.query.filter_by(matricule='1000000000').first():
            User.create_user(
                matricule='1000000000',
                fonction = 'auxiliaire sanitaire',
                mdp='topsecret_')            
    except ImportError: 
        port=os.environ.get('PORT',5000)
        rmedapp.run(debug=False, host="0.0.0.0", port=port)
