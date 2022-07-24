# app launch
from app import create_app
from app.db_extention import db


import os

app = create_app('config.ProductionConfig')
with app.app_context():
    db.create_all()
    from app.models import User
    if not User.query.filter_by(matricule='0444879129').first():
        User.create_user(
            matricule='0444879129',
            fonction = 'auxiliaire sanitaire',
            mdp='topsecret_')            
    port=os.environ.get('PORT',8080)
    try:
        import socket
        sock = socket.socket()
        sock.bind(('', 0))
        port_dispo = sock.getsockname()[1]
        port=os.environ.get('PORT',port_dispo)
    except:
        app.run(debug=False, host="0.0.0.0", port=port)
