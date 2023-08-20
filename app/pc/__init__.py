from flask import Blueprint
pc_blueprint = Blueprint('tbdebord', __name__, template_folder='templates')

from app.pc import dashboard
