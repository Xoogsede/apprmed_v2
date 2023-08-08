from flask import Blueprint, render_template, redirect, url_for, request, flash
from app.models import *
from .formulaire import *
import dash
import dash_core_components as dcc
import dash_html_components as html
from dash.dependencies import Input, Output
import plotly.express as px

auxsan_bp = Blueprint('auxsan', __name__, template_folder='templates')

#####################################################################################
# Ajout de blessé #
#####################################################################################
@auxsan_bp.route('/AjouterBlesse', methods=['GET', 'POST'])
def AjoutBlesse():

    form = AjouterBlesse()     

    
    if form.validate_on_submit():
        matricule = form.matricule.data
        categorie_blesse = form.categorie_blesse.data
        coordonnees_UTM_blesse = form.coordonnees_UTM_blesse.data
        symptomes = form.symptomes.data
        blesse_couche = 'True'==form.blesse_couche.data


        # Controle que le blessé n'est pas déjà enregistrer et qu'il n'est pas évacué.
        try :
            blesse_deja_enregistrer = session.query(blesse).filter_by(matricule=matricule).all()

            if not blesse_deja_enregistrer :
                session.add(blesse(idblesse=None, matricule= matricule, 
                                    categorieabc = categorie_blesse, 
                                    coordonneesutmblesse=coordonnees_UTM_blesse,
                                    gdhblessure=datetime.now(),gdhevacue= None,
                                    unite_elementaire= None,
                                    numdemande= None, symptomes=symptomes, 
                                    blesse_couche=blesse_couche))                                
                session.commit()

                flash("Blessé '{}' ajouté ! ".format(matricule))
                return redirect(url_for('auxsan.liste_blesses'))

            elif (blesse_deja_enregistrer[-1].gdhevacue is not None):
                session.add(blesse(idblesse=None, matricule= matricule, 
                                    categorieabc = categorie_blesse, 
                                    coordonneesutmblesse=coordonnees_UTM_blesse,
                                    gdhblessure=datetime.now(),gdhevacue= None,
                                    unite_elementaire= None,
                                    numdemande= None, symptomes=symptomes, 
                                    blesse_couche=blesse_couche))
                session.commit()

                flash('Blessé à nouveau ajouté ! ')
                return redirect(url_for('auxsan.liste_blesses'))

            else:
                flash("Blessé '{}' déjà enregistré mais non encore évacué !".format(matricule))
                return redirect(url_for('auxsan.AjoutBlesse'))
        
        except:
            flash("Blessé '{}' n'est pas un militaire français !".format(matricule))

    return render_template('auxsan/AjouterBlesse.html', form=form)



#####################################################################################
# Tableau de tous les blessés #
#####################################################################################
@auxsan_bp.route('/liste_blesses')
def liste_blesses():
    headings = ("N° blessé", "Matricule", "Categorie A B C", 
                "coordonnees UTM", "GDH blessure", 
                "GDH évacué","Unité", "Blesse couché")

    blesses = session.query(blesse).all()
    data = []
    for b in blesses:
        if b.gdhevacue != None: 
            evac = b.gdhevacue.strftime("%d%H%M %b %Y") 
        else: 
            evac = b.gdhevacue
        data.append((b.idblesse, b.matricule, b.categorieabc, 
                    b.coordonneesutmblesse, b.gdhblessure.strftime("%d%H%M %b %Y"), 
                    evac, b.unite_elementaire, b.blesse_couche))

    return render_template('auxsan/liste_blesses.html', headings=headings, data=data) 



#####################################################################################
# Mise à jour du blessé #
#####################################################################################
@auxsan_bp.route('/MiseAJourblesse', methods=['GET', 'POST'])
def MiseAJour():
    
    form = MiseAJourblesse()

    if form.validate_on_submit():
        matricule = form.matricule.data
        blesse_couche = 'True'==form.blesse_couche.data
        categorie_blesse = form.categorie_blesse.data
        
        blesseamettreajour = session.query(blesse).filter_by(matricule=matricule).all() 
        if blesseamettreajour :
            id = [blesse for blesse  in blesseamettreajour]
            m=max([n.idblesse for n in id])
            blesseamettreajour = session.query(blesse).filter_by(idblesse=m).first()
            blesseamettreajour.categorieabc = categorie_blesse
            blesseamettreajour.blesse_couche = blesse_couche
            session.add(blesseamettreajour)
            session.commit()
            flash("Le blessé '{}' a été mis à jour avec succès !".format(matricule))
        else:
            flash("'{}' inconnu parmi les blessés, merci de vérifier.".format(matricule))
            return redirect(url_for('auxsan.MiseAJour'))

        return redirect(url_for('auxsan.liste_blesses'))
    
    return render_template('auxsan/MiseAJourblesse.html', form=form)
