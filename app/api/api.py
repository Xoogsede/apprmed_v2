from flask import Blueprint, request, jsonify
from app.models import User, civil, blesse, session,militaire
# from app.api import api
from flask_jwt_extended import jwt_required, get_jwt_identity
import datetime

from flask import Blueprint


api = Blueprint('api', __name__)


@api.route('/user_pages', methods=['GET'])
@jwt_required()
def get_user_pages():
    matricule = get_jwt_identity()

    # Assurer que le matricule n'est pas None
    if not matricule:
        return jsonify({'status': 'error', 'message': 'Token invalide'}), 400

    user = User.query.filter_by(matricule=matricule).first()

    # Assurer que l'utilisateur existe
    if not user:
        return jsonify({'status': 'error', 'message': 'Utilisateur non trouvé'}), 404

    # Assurer que l'utilisateur a une fonction
    if not user.fonction:
        return jsonify({'status': 'error', 'message': 'Fonction utilisateur non définie'}), 400

    # définir les pages accessibles pour chaque fonction
    pages_by_function = {
        'SC': ['sc'],
        'EVASAN': ['sc','transport'],
        'CMA': ['sc', 'litsoin', 'magasin'],
        'PC': ['sc', 'litsoin', 'magasin', 'pc', 'transport'],
        'GMA': ['magasin'],
        'ADMIN': ['sc', 'litsoin', 'magasin', 'pc', 'transport'],
        # ajouter ici d'autres fonctions et leurs pages accessibles
    }

    user_pages = pages_by_function.get(user.fonction, [])
    return jsonify({'status': 'success', 'pages': user_pages}), 200


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


from datetime import datetime

from datetime import datetime

@api.route('/sc', methods=['POST'])
@jwt_required()
def receive_data():
    data = request.get_json()  # Récupère les données envoyées avec la requête POST
    
    if data is None:
        return jsonify({'status': 'erreur', 'message': 'Données JSON invalides'}), 400

    matricule = data.get('matricule')
    coordonnees = data.get('coordonnees')
    etatBlesse = data.get('etatBlesse')
    gdhblessure = data.get('gdhblessure')  # Récupérer l'heure de la blessure à partir des données

    if not all([matricule, coordonnees, etatBlesse, gdhblessure]):
        return jsonify({'status': 'erreur', 'message': 'Données manquantes'}), 400

    # Convertir l'heure de la blessure en un objet datetime
    gdhblessure_datetime = datetime.fromisoformat(gdhblessure)

    # Vérifier si la personne blessée est déjà enregistrée et non évacuée.
    try:
        blesse_deja_enregistrer = session.query(blesse).filter_by(matricule=matricule).all()

        if not blesse_deja_enregistrer or blesse_deja_enregistrer[-1].gdhevacue is not None:
            # Si l'entrée n'existe pas ou si la personne blessée a été évacuée, créer une nouvelle entrée
            nouveau_blesse = blesse(
                idblesse=None, 
                matricule=matricule,
                coordonneesutmblesse=coordonnees,
                blesse_couche=etatBlesse,
                categorieabc="A",  # Valeur par défaut
                gdhblessure=gdhblessure_datetime,
                gdhevacue=None,  # Valeur par défaut
                unite_elementaire=None,  # Valeur par défaut
                numdemande=None,  # Valeur par défaut
                symptomes=None,  # Valeur par défaut
            )
            session.add(nouveau_blesse)
            session.commit()
            return jsonify({'status': 'succès', 'message': 'Blessé ajouté avec succès'}), 200
        else:
            return jsonify({'status': 'erreur', 'message': 'Blessé déjà enregistré et non encore évacué', 'deja_present':1}), 400
    except Exception as e:
        return jsonify({'status': 'erreur', 'message': f"Erreur lors de l'ajout du blessé : {str(e)}"}), 400

...

# @api.route('/sc', methods=['POST'])
# @jwt_required()
# def receive_data():
#     data = request.get_json()  # Récupère les données envoyées avec la requête POST
    
#     if data is None:
#         return jsonify({'status': 'error', 'message': 'Invalid JSON data'}), 400

#     matricule = data.get('matricule')
#     coordonnees = data.get('coordonnees')
#     etatBlesse = data.get('etatBlesse')
#     gdhblessure = data.get('gdhblessure')  # Get the injury time from the data

#     nouveau_blesse = blesse.query.filter_by(matricule=matricule).first()  # Récupère l'entrée de la base de données associée à ce matricule

#     if nouveau_blesse:
#         # Si l'entrée existe déjà, mettez à jour les coordonnées et l'état du blessé
#         nouveau_blesse.coordonneesutmblesse = coordonnees
#         nouveau_blesse.blesse_couche = etatBlesse
#     else:
#         # Convert the injury time to a datetime object
#         gdhblessure_datetime = datetime.strptime(gdhblessure, '%Y-%m-%d %H:%M:%S')
#         # Si l'entrée n'existe pas, créez-en une nouvelle
#         nouveau_blesse = blesse(
#             matricule=matricule,
#             coordonneesutmblesse=coordonnees,
#             blesse_couche=etatBlesse,
#             categorieabc="A",
#             gdhblessure=gdhblessure_datetime  # Use the injury time when creating a new entry
#         )
#         session.add(blesse)
    
#     session.commit()  # Valide la transaction

#     return jsonify({'status': 'success', 'message': 'Données reçues et enregistrées avec succès'}), 200  # Renvoie un message de succès


