#!/bin/bash

[ $# -ne 1 ] && echo "Missing mail address as parameter" && exit 1

DEST=$1

[ ! -e .env ] && echo "Please execute prepare.sh" && exit 1
. .env

[ ! -e .msmtprc ] && echo "Missing .msmtprc" && exit 1

cat << EOF | docker run --rm -i -v $PWD/.msmtprc:/etc/msmtprc ghcr.io/fanmovies999/msmtp:latest $DEST
Subject: Configuration de RustDesk 

Bonjour

Pour Windows merci de télécharger le fichier suivant et de l'exécuter (clic-droit Exécuter avec Powershell)

   https://${WEB_USERNAME}:${WEB_PASSWORD}@${HBBR_HOSTNAME}/windows/install.ps1

Pour Android, merci d'installer l'application RustDesk Remote Desktop 
    https://play.google.com/store/apps/details?id=com.carriez.flutter_hbb

Click sur Parametres > ID/serveur Relais
    Serveur ID : ${HBBR_HOSTNAME}
	Serveur relay : laisser vide
	Serveur Api : laisser vide
	Key : ${KEY}


Cordialement,
Laurent
EOF
