#!/bin/bash

path='/etc/tacheron'

function checkIfAllowed {
	if [ -z $1 ];then
		echo "Fournir un nom à vérifier"
	else
		if [ -s /etc/tacheron.allow ];then
			if grep --quiet ^$1$ /etc/tacheron.allow;then
#				echo "DEBUG: $USER présent allow"
				return 0
			else
#				echo "DEBUG: $USER pas présent dans allow"
				return 1
			fi
		else
			if [ -s /etc/tacheron.deny ];then
				if grep --quiet ^$1$ /etc/tacheron.deny;then
#					echo "DEBUG: $USER présent dans deny"
					return 1
				else
#					echo "DEBUG: $USER pas présent dans deny"
					return 0
				fi
			else
#				echo "DEBUG: $USER absent de allow et deny"
				return 0
			fi
		fi
	fi
}

echo "TacheronTab v0.01"
echo "Louis & Léo"
echo "--------------"

if [ $EUID -ne 0 ];then

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

if ! checkIfAllowed $USER &&[ $EUID -ne 0 ];then
        echo "$USER n'es pas autorisé. Faites ajouter votre nom dans /etc/tacheron.allow ou retirer de /etc/tacheron.deny"
else
        echo "DEBUG: $USER autorisé"
	actionUser=$USER
	action=0
	while getopts "u:lre" opts;do
		case $opts in

			u)
				echo "DEBUG: Utilisateur $OPTARG"
				actionUser=$OPTARG
			;;
			l)
				echo "DEBUG: Option l"
				action=1
			;;
			r)
				echo "DEBUG: Option r"
				action=2
			;;
			e)
				echo "DEBUG: Option e"
				action=3
			;;
		esac
	done

	echo "DEBUG: ${action} pour ${actionUser}"
fi

