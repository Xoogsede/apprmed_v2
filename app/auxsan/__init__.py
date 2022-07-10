# app/auxsan/__init__.py
from flask import Blueprint
auxsan_blueprint = Blueprint('auxsan', __name__, template_folder='templates')


from app.auxsan import auxsan_routes