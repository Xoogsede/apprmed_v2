# app launch
from app import create_app
from app.db_extention import db


import os

app = create_app('config.ProductionConfig')
with app.app_context():
    db.create_all()
    from app.models import User
    if not User.query.filter_by(matricule='1000000000').first():
        User.create_user(
            matricule='1000000000',
            fonction = 'auxiliaire sanitaire',
            mdp='topsecret_')            
    app.run()