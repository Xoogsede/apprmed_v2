# app launch
from app import create_app 
from app.db_extention import db
from flask import render_template
from app.models import User

rmedapp = create_app('config.DevelopmentConfig')
with rmedapp.app_context():
    db.create_all()
    if not User.query.filter_by(matricule='1000000000').first():
        User.create_user(
            matricule='1000000000',
            fonction = 'auxiliaire sanitaire',
            mdp='topsecret_')
    rmedapp.run()
