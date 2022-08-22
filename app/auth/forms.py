from flask_wtf import FlaskForm
from wtforms import StringField, SubmitField, ValidationError, PasswordField, BooleanField
from wtforms.validators import DataRequired, EqualTo
from app.models import User


class LoginForm(FlaskForm):
    matricule = StringField(render_kw={"placeholder": "Saisir ou scanner matricule"}, validators=[DataRequired()])
    mdp = PasswordField("Mot de passe", validators=[DataRequired()])
    stay_loggedin = BooleanField('Rester connecter')
    submit = SubmitField('Connexion')



class RegistrationForm(FlaskForm):
    matricule = StringField(render_kw={"placeholder": "Saisir votre matricule"}, validators=[DataRequired()])
    fonction = StringField(render_kw={"placeholder": "Fonction"}, validators=[DataRequired()])   
    mdp = PasswordField(render_kw={"placeholder": "Mot de passe"}, validators=[DataRequired(), EqualTo('confirmer_mdp')])
    confirmer_mdp = PasswordField(render_kw={"placeholder": "Confirmez"}, validators=[DataRequired()])
    Valider = SubmitField("S'enregistrer")

    def check_matricule(self, field):
        if User.query.filter_by(matricule=field.data).first():
            raise ValidationError("Matricule déjà enregistré !")