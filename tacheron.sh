#!/bin/bash

path='/etc/tacheron'

function checkIfAllowed {
	if [ -z $1 ];then
		echo "Fournir un nom à vérifier"
	else
		if [ -s /etc/tacheron.allow ];then
			if grep --quiet ^$1$ /etc/tacheron.allow;then
				return 0
			else
				return 1
			fi
		else
			if [ -s /etc/tacheron.deny ];then
				if grep --quiet ^$1$ /etc/tacheron.deny;then
					return 1
				else
					return 0
				fi
			else
				return 0
			fi
		fi
	fi
}

echo "TacheronTab v0.01"
echo "Louis & Léo"
echo "--------------"


echo $(checkIfAllowed "louis")

if [ $EUID -ne 0 ];then
	if ! checkIfAllowed $USER;then
		echo "$USER n'es pas autorisé. Faites ajouter votre nom dans /etc/tacheron.allow ou faites-le retirer de /etc/tacheron.deny"
	else
		echo "$USER autorisé"
	fi
else
if [ ! -f /etc/tacherontab ];then
	echo "Création duf fichier /etc/tacherontab"
	touch /etc/tacherontab
fi

if [ ! -f /etc/tacheron.allow ];then
	echo "Nan mais allow quoi ! Création du fichier /etc/tacheron.allow"
	touch /etc/tacheron.allow
fi
if [ ! -f /etc/tacheron.deny ];then
	echo "Création du fichier /etc/tacheron.deny"
	touch /etc/tacheron.deny
fi

fi
