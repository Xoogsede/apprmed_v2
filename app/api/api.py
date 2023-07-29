from flask import Blueprint, request, jsonify
from app.models import User
from flask_jwt_extended import jwt_required, get_jwt_identity

api = Blueprint('api', __name__)

@api.route('/user_pages', methods=['GET'])
@jwt_required()
def get_user_pages():
    matricule = get_jwt_identity()
    user = User.query.filter_by(matricule=matricule).first()

    if user:
        # définir les pages accessibles pour chaque fonction
        pages_by_function = {
            'SC': ['auxsan'],
            'EVASAN': ['auxsan','transport'],
            'CMA': ['auxsan', 'litsoin', 'magasin'],
            'PC': ['auxsan', 'litsoin', 'magasin', 'pc', 'transport'],
            'GMA': [ 'magasin'],
            'ADMIN': ['auxsan', 'litsoin', 'magasin', 'pc', 'transport'],
            # ajouter ici d'autres fonctions et leurs pages accessibles
        }
        
        user_pages = pages_by_function.get(user.fonction, [])
        return jsonify({'status': 'success', 'pages': user_pages}), 200

    return jsonify({'status': 'error', 'message': 'Utilisateur non trouvé'}), 404
