from flask import render_template, request, flash, redirect, url_for
from app.auth.forms import LoginForm, RegistrationForm
from flask_login import login_user, login_required, logout_user, current_user
from app.auth import authentication as at
from app.models import User, militaire, session


@at.route('/')
def home():
    return render_template('home.html') 

@at.route('/register', methods=['GET', 'POST'])
def register_user():
    
    form = RegistrationForm()

    if current_user.is_authenticated:
        flash('Vous êtes déjà enregistré !')
        return redirect(url_for('authentication.home'))

    if form.validate_on_submit():
        matricule = form.matricule.data
        nouveau_inscrit = session.query(militaire).filter_by(matricule=matricule).all()
        deja_inscrit = User.query.filter_by(matricule=matricule).all()
        
        if nouveau_inscrit != [] and deja_inscrit == []:
            User.create_user(
                matricule = form.matricule.data, 
                fonction = form.fonction.data, 
                mdp = form.mdp.data)

            flash("Merci de vous être enregistrer")
            return redirect(url_for('authentication.login'))
        else:
            flash("Le matricule '{}' n'appartient pas à l'armée française, vous n'êtes pas autoriser à vous enregistrer.".format(form.matricule.data))
        

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
    return redirect(url_for('authentication.home'))



@at.route('/login', methods=['GET', 'POST'])
def login():
    if current_user.is_authenticated:
        flash('Vous êtes déjà connecté !')
        return redirect(url_for('authentication.home'))

    form = LoginForm()

    if form.validate_on_submit():
        user = User.query.filter_by(matricule=form.matricule.data).first()

        matricule = form.matricule.data
        militaire_francais = session.query(militaire).filter_by(matricule=matricule).all()
        

        if user is not None and militaire_francais != []:
            if user.check_password(form.mdp.data) and user is not None:
                login_user(user)
                flash('Connexion réussit !')

                next = request.args.get('next')

                if next == None or not next[0]=='/':
                    next = url_for('authentication.bienvenue')
            else: 
                flash("Erreur, merci d'essayer à nouveau")
                return redirect(url_for('authentication.login'))           
            return redirect(url_for('authentication.home'))
        
        elif user is None and militaire_francais != []:
            flash("Matricule '{}' non encore inscrit, merci de vous enregistrer.".format(form.matricule.data))
            return redirect(url_for('authentication.register_user'))
        
        else:
            flash("Matricule '{}' n'est pas autoriser à se connecter.".format(form.matricule.data))

    return render_template('auth/login.html', form=form)

@at.app_errorhandler(404)
def page_non_trouvee(error):
    return render_template('auth/404.html'), 404