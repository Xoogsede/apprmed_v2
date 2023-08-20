from flask import Blueprint, render_template, redirect, url_for, request, flash

tbdebord = Blueprint('tbdebord', __name__, template_folder='templates')




@tbdebord.route('/tableaudebord')
def tableaudebord():
    return render_template('pc/tbdebord.html')