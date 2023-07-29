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
    old_password = PasswordField(render_kw={"placeholder": "Ancien mot de passe"}, validators=[DataRequired()])
    new_password = PasswordField(render_kw={"placeholder": "Nouveau mot de passe"}, validators=[DataRequired(), EqualTo('confirm_password')])
    confirm_password = PasswordField(render_kw={"placeholder": "Confirmez le nouveau mot de passe"}, validators=[DataRequired()])
    submit = SubmitField("Changer le mot de passe")

    def validate_matricule(self, matricule):
        user = User.query.filter_by(matricule=matricule.data).first()
        if user is None:
            raise ValidationError("Le matricule n'est pas enregistré. Veuillez contacter l'administrateur.")
