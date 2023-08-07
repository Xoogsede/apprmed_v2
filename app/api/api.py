from flask import Blueprint, request, jsonify
from app.models import User, civil, blesse, session,militaire
# from app.api import api
from flask_jwt_extended import jwt_required, get_jwt_identity
import datetime
from app.api.functions import latlon_to_utm, utm_to_latlon
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
        'DEMANDEUR':['sc', 'demandeur'],
        'EVASAN': ['sc','transport'],
        'CMA': ['sc', 'litsoin', 'magasin'],
        'PC': ['sc', 'litsoin', 'magasin', 'pc', 'transport'],
        'GMA': ['magasin'],
        'ADMIN': ['sc', 'litsoin', 'magasin', 'pc', 'transport'],
        # ajouter ici d'autres fonctions et leurs pages accessibles
    }

    user_pages = pages_by_function.get(user.fonction, [])
    return jsonify({'status': 'success', 'pages': user_pages}), 200


@api.route('/demandeur', methods=['POST'])
@jwt_required()
def demandevasan():
    data = request.get_json()  # Récupère les données envoyées avec la requête POST
    return jsonify({'status': 'succès', 'message': f'Blessés ajouté avec succès {data["data"]}'}), 200




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
    etatBlesse = eval(data.get('etatBlesse'))
    gdhblessure = data.get('gdhblessure')  # Récupérer l'heure de la blessure à partir des données

    try:
        coordonnees = latlon_to_utm(data.get('coordonnees'))
    except:
        coordonnees = data.get('coordonnees')
        
    if not all([matricule, coordonnees, str(etatBlesse), gdhblessure]):
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
            return jsonify({'status': 'erreur', 'message': 'Blessé déjà enregistré et non encore évacué', 'deja_present':1}), 201
    except Exception as e:
        return jsonify({'status': 'erreur', 'message': f"Erreur lors de l'ajout du blessé : {str(e)}"}), 400


