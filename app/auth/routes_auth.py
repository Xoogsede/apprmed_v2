from flask import render_template, request, flash, redirect, url_for
from app.auth.forms import LoginForm, RegistrationForm
from flask_login import login_user, login_required, logout_user, current_user
from app.auth import authentication as at
from app.models import User


@at.route('/register', methods=['GET', 'POST'])
def register_user():
    
    form = RegistrationForm()

    if current_user.is_authenticated:
        flash('Vous êtes déjà enregistré !')
        return redirect(url_for('home'))

    if form.validate_on_submit():
        User.create_user(
            matricule = form.matricule.data, 
            fonction = form.fonction.data, 
            mdp = form.mdp.data)

        flash("Merci de vous être enregistrer")
        return redirect(url_for('authentication.login'))

    return render_template('auth/registration.html', form = form)

@at.route('/bienvenue')
@login_required
def bienvenue():
    return render_template('auth.Bienvenue.html')


@at.route('/deconnexion')
@login_required
def deconnexion():
    logout_user()
    flash("Vous etes déconnecté !")
    return redirect(url_for('home'))



@at.route('/login', methods=['GET', 'POST'])
def login():
    if current_user.is_authenticated:
        flash('Vous êtes déjà connecté !')
        return redirect(url_for('home'))

    form = LoginForm()

    if form.validate_on_submit():
        user = User.query.filter_by(matricule=form.matricule.data).first()
        if user is not None:
            if user.check_password(form.mdp.data) and user is not None:
                login_user(user)
                flash('Connexion réussit !')

                next = request.args.get('next')

                if next == None or not next[0]=='/':
                    next = url_for('authentication.bienvenue')
            else: 
                flash("Erreur, merci d'essayer à nouveau")
                return redirect(url_for('authentication.login'))           
            return redirect(url_for('home'))
        else:
            flash("Matricule '{}' inconnu, merci de vous enregistrer.".format(form.matricule.data))
            return redirect(url_for('authentication.register_user'))
    return render_template('auth/login.html', form=form)

at.app_errorhandler(404)
def page_non_trouvee(erreur):
    return render_template('404.html'), 404