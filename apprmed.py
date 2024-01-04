# Importer les modules nécessaires
from app import create_app  # importe la fonction de création de l'application
from app.db_extention import db  # importe l'extension de base de données
import os  # importe le module os pour récupérer les variables d'environnement

# Crée l'application en utilisant la configuration de production
app = create_app('config.DevelopmentConfig')

# Crée un contexte d'application
with app.app_context():
    # Crée toutes les tables de la base de données
    db.create_all()

    # Importe le modèle d'utilisateur
    from app.models import User

    # Vérifie si un utilisateur avec le matricule '0444879129' existe déjà
    if not User.query.filter_by(matricule='0444879129').first():
        # Si l'utilisateur n'existe pas, crée un nouvel utilisateur avec les données spécifiées
        User.create_user(
            matricule='0444879129',
            fonction='auxiliaire sanitaire',
            mdp='1234')

# Récupère le port de l'environnement ou utilise le port 8080 par défaut
port = int(os.environ.get('PORT', 8080))

# Essaye de trouver un port libre
try:
    # Crée un socket
    import socket
    sock = socket.socket()

    # Lie le socket à une adresse et un port libres
    sock.bind(('', 0))

    # Récupère le port libre
    port_dispo = sock.getsockname()[1]

    # Utilise le port libre comme port de l'application, sauf si un port est spécifié dans l'environnement
    port = int(os.environ.get('PORT', port_dispo))
except:
    # Si une erreur se produit, exécute l'application avec le port spécifié
    app.run(debug=True, host="0.0.0.0", port=port)

