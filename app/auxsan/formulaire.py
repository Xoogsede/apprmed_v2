from flask_wtf import FlaskForm
from wtforms import StringField, SubmitField, TextAreaField, SelectField
from wtforms.validators import DataRequired


class AjouterBlesse(FlaskForm):   
    
    matricule = StringField(render_kw={"placeholder": "Saisir ou scanner matricule"}, validators=[DataRequired()])
    categorie_blesse = SelectField("Catégorie blessé",  validators=[DataRequired()], choices=[('A', "A"), ('B', "B"), ('C', "C")])
    coordonnees_UTM_blesse = StringField("Position du blessé", render_kw={"placeholder": "Coordonnées UTM"}, validators=[DataRequired()]) 
    symptomes = TextAreaField(render_kw={"placeholder": "Symptomes"})
    blesse_couche = SelectField("Blessé couché ?", validators=[DataRequired()], choices=[(True, "Oui"), (False, "Non")])
    Valider = SubmitField('Valider')

class MiseAJourblesse(FlaskForm):

    matricule = StringField(render_kw={"placeholder": "Saisir ou scanner matricule"}, validators=[DataRequired()])
    categorie_blesse = SelectField("Nouvelle catégorie blessé",  validators=[DataRequired()], choices=[('A', "A"), ('B', "B"), ('C', "C")])
    blesse_couche = SelectField("Blessé couché ?", validators=[DataRequired()], choices=[(True, "Oui"), (False, "Non")])
    nouvelle_position = StringField("Nouvelle position", render_kw={"placeholder": "Nouvelles coordonnées UTM"})
    Valider = SubmitField('Valider')

class MatriculeQRCode(FlaskForm):
    matricule = SubmitField("Matricule")
    Valider = SubmitField('Se connecter')
