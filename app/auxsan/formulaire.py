from flask_wtf import FlaskForm
from wtforms import StringField, SubmitField, RadioField, TextAreaField
from wtforms.validators import DataRequired


class AjouterBlesse(FlaskForm):   
    
    matricule = StringField(render_kw={"placeholder": "Saisir ou scanner matricule"}, validators=[DataRequired()])
    categorie_blesse = StringField(render_kw={"placeholder": "Categorie blesse"}, default= "C")
    coordonnees_UTM_blesse = StringField(render_kw={"placeholder": "Coordonnees UTM"}, validators=[DataRequired()]) 
    symptomes = TextAreaField(render_kw={"placeholder": "Symptomes"})
    blesse_couche = RadioField("Blessé couché ?", validators=[DataRequired()], choices=[(True, "Oui"), (False, "Non")])
    Valider = SubmitField('Valider')

class MiseAJourblesse(FlaskForm):

    matricule = StringField(render_kw={"placeholder": "Saisir ou scanner matricule"}, validators=[DataRequired()])
    categorie_blesse = StringField(render_kw={"placeholder": "Nouvelle catégorie"}, validators=[DataRequired()])
    blesse_couche = RadioField(label="Blessé couché ?", validators=[DataRequired()], choices=[(True, "Oui"), (False, "Non")])
    Valider = SubmitField('Valider')

class MatriculeQRCode(FlaskForm):
    matricule = SubmitField("Matricule")
    Valider = SubmitField('Se connecter')
