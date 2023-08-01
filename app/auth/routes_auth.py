from flask import render_template, request, flash, redirect, url_for
from app.auth.forms import LoginForm, RegistrationForm
from flask_login import login_user, login_required, logout_user, current_user
from app.auth import authentication as at
from app.models import User, militaire, session
from flask_jwt_extended import jwt_required, create_access_token, get_jwt_identity
from flask import jsonify



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
        user = User.query.filter_by(matricule=matricule).first()
        militaire_existant = session.query(militaire).filter_by(matricule=matricule).first()
        
        if militaire_existant and user and user.check_password(form.old_password.data):
            user.change_password(form.new_password.data)
            session.commit()
            flash("Votre mot de passe a été changé avec succès !")
            return redirect(url_for('authentication.login'))
        else:
            flash("Matricule non valide ou mot de passe incorrect. Veuillez réessayer.")
        
    return render_template('auth/registration.html', form=form)


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


@at.route('/login_mobile', methods=['POST'])
def login_mobile():
    data = request.get_json()

    matricule = data.get('matricule')
    password = data.get('password')

    user = User.query.filter_by(matricule=matricule).first()

    if user and user.check_password(password):
        token = create_access_token(identity=matricule)  # create a token and send it back
        return jsonify({'status': 'success', 'message': user.is_password_changed, 'matricule': user.matricule, 'fonction': user.fonction, 'token': token}), 200

    return jsonify({'status': 'error', 'message': 'Matricule ou mot de passe incorrect'}), 400


@at.route('/change_password', methods=['POST'])
@jwt_required()
def change_password():
    data = request.get_json()  # Récupère les données envoyées avec la requête POST
    
    matricule = get_jwt_identity()  # Récupère le matricule de l'utilisateur actuellement connecté
    user = User.query.filter_by(matricule=matricule).first()  # Récupère l'utilisateur associé à ce matricule

    if user and user.check_password(data['old_password']):
        user.set_password(data['new_password'])  # Change le mot de passe de l'utilisateur
        user.is_password_changed = True  # Marque le mot de passe comme ayant été changé
        session.commit()  # Valide la transaction

        return jsonify({'status': 'success', 'message': 'Mot de passe changé avec succès'}), 200  # Renvoie un message de succès

    return jsonify({'status': 'error', 'message': 'Ancien mot de passe incorrect'}), 400  # Renvoie un message d'erreur



@at.app_errorhandler(404)
def page_non_trouvee(error):
    return render_template('auth/404.html'), 404