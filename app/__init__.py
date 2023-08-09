'''
Ce code définit une fonction create_app qui prend en entrée un objet de configuration et crée une 
application Flask.

La fonction commence par créer une instance de Flask en lui passant en paramètre le nom du module 
courant (__name__). Ensuite, elle charge les configurations de l'application à partir de l'objet de 
configuration passé en paramètre.

Elle initialise ensuite les extensions db, migrate, bootstrap, log_manager et bcrypt en leur passant 
l'application Flask.

La fonction enregistre également deux blueprints (ensemble de routes et de vues liées) auprès de 
l'application : auxsan_bp et authentication. Le premier est enregistré avec un préfixe d'URL /auxsan, 
ce qui signifie que toutes les routes définies dans ce blueprint seront préfixées par /auxsan.

Enfin, la fonction retourne l'application Flask créée.
'''

import os
from flask import Flask, jsonify, request
from flask_jwt_extended import JWTManager, create_access_token
from app.db_extention import *
# from brouillon.optimisation_v1 import *
from app.models import User, blesse, session  # assurez-vous que cet import est correct
import dash
from dash import dcc
from dash import html
import plotly.express as px
import pandas as pd



def create_app(config_type):
    """
    Crée une application Flask.
    
    :param config_type: Type de configuration à utiliser.
    :return: L'application Flask créée.
    """
    # Création de l'application Flask
    app = Flask(__name__)
    
    # Chargement des configurations
    app.config.from_object(config_type)

    # Configure application to store JWTs securely
    app.config['JWT_SECRET_KEY'] = 'Secret_teporaire$'  # Change this!

    jwt = JWTManager(app)

    # Initialisation de SQLAlchemy
    db.init_app(app)
    # Initialisation de Migrate
    migrate.init_app(app, db)
 
    # Initialisation de Bootstrap
    bootstrap.init_app(app)
    # Initialisation de LoginManager
    log_manager.init_app(app)
    # Initialisation de Bcrypt
    bcrypt.init_app(app) 
    
    create_dashboard(app)

    # Enregistrement du blueprint auxsan_bp avec un préfixe d'URL
    from app.auxsan.auxsan_routes import auxsan_bp
    app.register_blueprint(auxsan_bp, url_prefix='/auxsan')

    # Enregistrement du blueprint authentication
    from app.auth import authentication
    app.register_blueprint(authentication)
    
    from app.api.api import api
    app.register_blueprint(api, url_prefix='/api')
    # Retour de l'application Flask
    return app




def create_dashboard(server):
    # ... (Le code pour obtenir les données et créer les autres graphes reste le même)
    dash_app = dash.Dash(server=server, routes_pathname_prefix='/dashboard/')
    
    # Requêtes pour obtenir les données nécessaires
    with server.app_context():
        blesses_attente = session.query(blesse).filter(blesse.gdhevacue == None).count()
        blesses_evacues_aujourdhui = session.query(blesse).filter(func.date(blesse.gdhevacue) == func.date(func.now())).count()
        blesses_evacues_total = session.query(blesse).filter(blesse.gdhevacue != None).count()
        blesses_couche = session.query(blesse).filter(blesse.blesse_couche == True).count()
        unite_impactee = session.query(func.count(blesse.unite_elementaire.distinct())).scalar()
        subquery = session.query(func.count(blesse.unite_elementaire).label("unite")).group_by(blesse.unite_elementaire).subquery('moyenne')
        moyenne_blesses_unite = session.query(func.avg(subquery.c.unite)).scalar()

        # moyenne_blesses_unite = session.query(func.avg(session.query(func.count(blesse.unite_elementaire)).group_by(blesse.unite_elementaire))).scalar()

    # Création des graphiques
    # fig1 = px.bar(x=["En attente d'évacuation"], y=[blesses_attente], title='Nombre de blessés en attente d\'évacuation')
    # fig2 = px.bar(x=["Évacués aujourd'hui"], y=[blesses_evacues_aujourdhui], title='Nombre de blessés évacués aujourd\'hui')
    # fig3 = px.bar(x=["Évacués en tout"], y=[blesses_evacues_total], title='Nombre de blessés évacués en tout')
    # fig4 = px.bar(x=["Blessés couchés"], y=[blesses_couche], title='Nombre de blessés couchés')
    # fig5 = px.bar(x=["Unités impactées"], y=[unite_impactee], title='Nombre d\'unités élémentaires impactées')
    # fig6 = px.bar(x=["Moyenne par unité"], y=[moyenne_blesses_unite], title='Nombre moyen de blessés par unité élémentaire')

    # Créer des figures avec 3 barres chacune
    fig1 = px.bar(x=["En attente d'évacuation", "Évacués aujourd'hui", "Évacués en tout"],
              y=[blesses_attente, blesses_evacues_aujourdhui, blesses_evacues_total])
    fig1.update_layout(
        title={
            'text': 'Statistiques des blessés',
            'y':0.9,
            'x':0.5,
            'xanchor': 'center',
            'yanchor': 'top'})

    fig2 = px.bar(x=["Blessés couchés", "Unités impactées", "Moyenne par unité"],
                y=[blesses_couche, unite_impactee, moyenne_blesses_unite])
    fig2.update_layout(
        title={
            'text': 'Statistiques supplémentaires',
            'y':0.9,
            'x':0.5,
            'xanchor': 'center',
            'yanchor': 'top'})

    

    # Obtenir les coordonnées des blessés
    blesses_coordinates = session.query(blesse.coordonneesutmblesse).all()

    # Créer un DataFrame avec les coordonnées
    blesses_df = pd.DataFrame(blesses_coordinates, columns=['coordonneesutmblesse'])
    # Supposons que 'coordonneesutmblesse' contienne des tuples sous forme de chaînes, comme "(latitude, longitude)"
    pattern = r'\((?P<latitude>.*),\s*(?P<longitude>.*)\)'
    coordinates = blesses_df['coordonneesutmblesse'].str.extract(pattern)

    # Convertir les colonnes extraites en types numériques si nécessaire
    blesses_df['latitude'] = coordinates['latitude'].astype(float)
    blesses_df['longitude'] = coordinates['longitude'].astype(float)


    # Créer un tracé de carte avec les coordonnées
    map_fig = px.scatter_geo(blesses_df,
                             lat='latitude',
                             lon='longitude',
                             title='Position des blessés',
                             projection='natural earth')

    # Disposition du tableau de bord avec la carte au centre
    dash_app.layout = html.Div([
        html.H1('Situation Soutien Médical', style={'textAlign': 'center', 'margin-bottom': '20px'}),

        html.Div([
            dcc.Graph(figure=fig1),
            # dcc.Graph(figure=fig2),
            # dcc.Graph(figure=fig3),
        ], style={'width': '20%', 'display': 'inline-block'}),

        html.Div([
            dcc.Graph(figure=map_fig),
        ], style={'width': '60%', 'display': 'inline-block'}),

        html.Div([
            dcc.Graph(figure=fig2),
            # dcc.Graph(figure=fig5),
            # dcc.Graph(figure=fig6),
        ], style={'width': '20%', 'display': 'inline-block'}),
    ])


    # Créer la carte avec Folium
    # carte = afficher_carte(optimal_routes, ambulance_nodes, patient_nodes, patient_urgence_etat, hospital_nodes, ambulance_patients, hospital_patients)

    # # Enregistrer la carte dans un fichier HTML
    # carte.save('map.html')

    # # Disposition du tableau de bord
    # dash_app.layout = html.Div([
    #     html.H1('Situation Soutien Médical', style={'textAlign': 'center', 'margin-bottom': '20px'}),

    #     html.Div([
    #         dcc.Graph(figure=fig1),
    #     ], style={'width': '20%', 'display': 'inline-block'}),

    #     html.Div([
    #         # Intégrer la carte à partir du fichier HTML
    #         html.Iframe(id='map', srcDoc=open('map.html', 'r').read(), width='100%', height='500px')
    #     ], style={'width': '60%', 'display': 'inline-block'}),

    #     html.Div([
    #         dcc.Graph(figure=fig2),
    #     ], style={'width': '20%', 'display': 'inline-block'}),
    # ])

    return dash_app


