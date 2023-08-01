from flask import Blueprint, request, jsonify
from app.models import User, civil, blesse
from flask_jwt_extended import jwt_required, get_jwt_identity
from app.db_extention import session
import datetime


api = Blueprint('api', __name__)

@api.route('/user_pages', methods=['GET'])
@jwt_required()
def get_user_pages():
    matricule = get_jwt_identity()
    user = User.query.filter_by(matricule=matricule).first()

    if user:
        # définir les pages accessibles pour chaque fonction
        pages_by_function = {
            'SC': ['SC'],
            'EVASAN': ['SC','transport'],
            'CMA': ['SC', 'litsoin', 'magasin'],
            'PC': ['SC', 'litsoin', 'magasin', 'pc', 'transport'],
            'GMA': ['magasin'],
            'ADMIN': ['SC', 'litsoin', 'magasin', 'pc', 'transport'],
            # ajouter ici d'autres fonctions et leurs pages accessibles
        }
        
        user_pages = pages_by_function.get(user.fonction, [])
        return jsonify({'status': 'success', 'pages': user_pages}), 200

    return jsonify({'status': 'error', 'message': 'Utilisateur non trouvé'}), 404



# @api.route('/change_password_mobile', methods=['POST'])
# @jwt_required()
# def change_password_mobile():
#     data = request.get_json()  # Récupère les données envoyées avec la requête POST
    
#     matricule = data.get('matricule')
#     new_password = data.get('new_password')
    
#     user = User.query.filter_by(matricule=matricule).first()  # Récupère l'utilisateur associé à ce matricule

#     if user:
#         user.set_password(new_password)  # Change le mot de passe de l'utilisateur
#         user.is_password_changed = True  # Marque le mot de passe comme ayant été changé
#         session.commit()  # Valide la transaction

#         return jsonify({'status': 'success', 'message': 'Mot de passe changé avec succès'}), 200  # Renvoie un message de succès

#     return jsonify({'status': 'error', 'message': 'Utilisateur non trouvé'}), 404  # Renvoie un message d'erreur





@api.route('/add_civil', methods=['POST'])
@jwt_required()
def add_civil():
    data = request.get_json()  # Récupère les données envoyées avec la requête POST
    
    # Crée une nouvelle instance de la classe Civil avec les données reçues
    new_civil = civil(
        firstname=data['firstname'],
        lastname=data['lastname'],
        sexe=data['sexe'],
        dateofbirth=data['dateofbirth'],
        placeofbirth=data['placeofbirth'],
        address=data['address'],
        city=data['city'],
        country=data['country'],
        nationality=data['nationality'],
        localisation=data['localisation'],
        etat=data['etat']
    )

    session.add(new_civil)  # Ajoute le nouvel objet Civil à la session
    session.commit()  # Valide la transaction

    return jsonify({'status': 'success', 'message': 'Civil ajouté avec succès'}), 201  # Renvoie un message de succès


@api.route('/SC', methods=['POST'])
@jwt_required()
def receive_data():
    data = request.get_json()  # Récupère les données envoyées avec la requête POST
    
    matricule = data.get('matricule')
    coordonnees = data.get('coordonnees')
    etatBlesse = data.get('etatBlesse')
    
    blesse = blesse.query.filter_by(matricule=matricule).first()  # Récupère l'entrée de la base de données associée à ce matricule

    if blesse:
        # Si l'entrée existe déjà, mettez à jour les coordonnées et l'état du blessé
        blesse.coordonneesutmblesse = coordonnees
        blesse.blesse_couche = etatBlesse
    else:
        # Si l'entrée n'existe pas, créez-en une nouvelle
        blesse = blesse(matricule=matricule, coordonneesutmblesse=coordonnees, blesse_couche=etatBlesse, 
        categorieabc="A", gdhblessure=datetime.now())  # 'A' et datetime.now() sont des valeurs par défaut
        session.add(blesse)
    
    session.commit()  # Valide la transaction

    return jsonify({'status': 'success', 'message': 'Données reçues et enregistrées avec succès'}), 200  # Renvoie un message de succès
