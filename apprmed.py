# app launch
from app import create_app
from app.db_extention import db


import os

if __name__ == "__main__":
    app = create_app('config.ProductionConfig')
    with app.app_context():
        from app.models import User
        db.create_all()
        if not User.query.filter_by(matricule='1000000000').first():
            User.create_user(
                matricule='1000000000',
                fonction = 'auxiliaire sanitaire',
                mdp='topsecret_')            
        port=os.environ.get('PORT',5000)
        app.run(debug=False, host="0.0.0.0", port=port)
