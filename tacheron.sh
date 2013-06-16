#!/bin/bash

path='/etc/tacheron'

function parse {
	# echo "DEBUG: $1"
	if echo "$1" | grep --quiet ^\*\/ ;then
		# echo "DEBUG: */ détecté"
		return 2
	elif echo "$1" | grep --quiet ^\* ;then
		# echo "DEBUG: * détecté"
		return 1
	elif echo "$1" | grep --quiet \-;then
		# echo "DEBUG: - détecté"
		return 3
	elif echo "$1" | grep --quiet \,;then
		# echo "DEBUG: , détecté"
		return 4
	else
		return 5
	fi
}

supprVal=""

function getTilde {
	supprVal=""
	supprVal=$(echo "$1" | cut --delimiter="~" --output-delimiter="
" -f2-)
	# Ce µ%$ù* de langage ne permet pas de renvoyer
	# un tableau ou une chaine de caractères :
	# Passer par les variables globales !

	# echo "DEBUG: contenu de supprVal=${supprVal}"
}

interval=""

function getInterval {
	# Cette fonction va parser le champ donné
	# Gestion des intervalles avec possibilité de suppresion :
	# 	On renvoit le code 0 et la liste des valeurs
	# 	(retours à la lignes entre) est dans une variable globale
	# Gestion des listes (séparation par virgule) :
	# 	On renvoit le code 0 et la liste des valeurs
	# 	est contenue dans une variable globale
	# Gestion des champs étoilés :
	# 	On renvoit le code 1 ou sinon la valeur du diviseur
	# 	Remarque : la valeur du diviseur peut-être de 1
	# 		   cela revient à un * simple

	parse "$1"
	resultat=$?

	interval=""
	supprVal=""

	# Cas d'un champ intervalle
	if [ ${resultat} -eq 3 ];then
		premiereVal=$(echo "$1" | cut --delimiter="-" -f1)
		derniereVal=$(echo "$1" | cut --delimiter="-" -f2 | cut --delimiter="~" -f1)
		if echo "$1" | grep --quiet \~;then
                        getTilde "$1"
		fi

		for((i=${premiereVal};i<=${derniereVal};i++));do
			disable=0
			if [ ! -z "${supprVal}" ];then
	                        for j in ${supprVal};do
					if [ "$j" = "$i" ];then
						disable=1
						break
					fi
				done
			fi
			if [ "${disable}" -eq 0 ];then
				# La condition suivante permet d'éviter d'avoir un
				# retour à la ligne après une valeur vide
				if [ -z "${interval}" ];then
					interval="$i"
				else
					interval="${interval}
$i"
				fi
			fi
                done
	# Cas d'un champ avec virgule
	elif [ ${resultat} -eq 4 ]||[ ${resultat} -eq 5 ];then
		interval=$(echo "$1" | cut --delimiter="," --output-delimiter="
" -f1-)
	# Cas d'un champ étoile avec division
	elif [ ${resultat} -eq 2 ];then
		return $(echo "$1" | cut --delimiter="/" -f2)
	# Cas d'un champ étoile
	else
		return 1
	fi

        # echo "DEBUG: contenu de interval=${interval}"
	return 0
}

function calculerTemps {
	# $1 : 15 secondes
	# $2 : minutes
	# $3 : heures
	# $4 : jour du mois
	# $5 : mois de l'année
	# $6 : jour de la semaine

	getInterval "$1"
	resultatSec=$?
	intervalSec=${interval}

	getInterval "$2"
	resultatMin=$?
	intervalMin=${interval}

	getInterval "$3"
	resultatHeures=$?
	intervalHeures=${interval}

	getInterval "$4"
	resultatJour=$?
	intervalJour=${interval}

	getInterval "$5"
	resultatMois=$?
	intervalMois=${interval}

	getInterval "$6"
	resultatJourSem=$?
	intervalJourSem=${interval}

	tabResultats=(${resultatSec} ${resultatMin} ${resultatHeures} ${resultatJour} ${resultatMois} ${resultatJourSem})
	tabDateCmd=("+%S" "+%M" "+%H" "+%d" "+%m" "+%w")
	tabIntervalles=("${intervalSec}" "${intervalMin}" "${intervalHeures}" "${intervalJour}" "${intervalMois}" "${intervalJourSem}")

	valider=1
	compteur=0
	for i in ${tabResultats[@]};do
		if [ $i -eq 0 ]&&[ ${valider} -eq 1 ];then
			valider=0
	                for j in ${tabIntervalles[${compteur}]};do
				# Tout sauf les secondes
        	               	if [ ${compteur} -ne 0 ]&&[ $(date $(echo "${tabDateCmd[${compteur}]}")) -eq $j ];then
                	                valider=1
				# Les secondes
				elif [ ${compteur} -eq 0 ]&&[ $(echo $(echo "$(date $(echo ${tabDateCmd[${compteur}]}))/15") | bc) -eq $j ];then
					valider=1
        	                fi
	                done
		elif [ $i -gt 1 ]&&[ ${valider} -eq 1 ];then
			# Tout sauf les secondes
			if [ ${compteur} -ne 0 ]&&[ $(echo $(date "$(echo "${tabDateCmd[${compteur}]}") % $i") | bc) -ne 0 ];then
				valider=0
			# Les secondes
			elif [ ${compteur} -eq 0 ]&&[ $(echo $(date "$(echo "${tabDateCmd[${compteur}]}")/15 % $i") | bc) -ne 0 ];then
				valider=0
			fi
		fi
		# echo "DEBUG: Evolution valide n°${compteur} i=$i ${valider}"
		compteur=$(echo "$compteur + 1" | bc)
	done

	#echo "DEBUG: Valide final : ${valider}"

	return ${valider}
}

function checkIfAllowed {
	if [ -z $1 ];then
		echo "Fournir un nom à vérifier"
	else
		if [ -s /etc/tacheron.allow ];then
			if grep --quiet ^$1$ /etc/tacheron.allow;then
				# echo "DEBUG: $USER présent allow"
				return 0
			else
				# echo "DEBUG: $USER pas présent dans allow"
				return 1
			fi
		else
			if [ -s /etc/tacheron.deny ];then
				if grep --quiet ^$1$ /etc/tacheron.deny;then
					# echo "DEBUG: $USER présent dans deny"
					return 1
				else
					# echo "DEBUG: $USER pas présent dans deny"
					return 0
				fi
			else
					# echo "DEBUG: $USER absent de allow et deny"
				return 0
			fi
		fi
	fi
}

echo "TacheronTab v0.01"
echo "Louis & Léo"
echo "--------------"

if [ $EUID -eq 0 ];then

	if [ ! -d ${path} ];then
		mkdir ${path}
		chmod o+rw ${path}
	fi

	if [ ! -f /etc/tacherontab ];then
		echo "Création du fichier /etc/tacherontab"
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

if [ ! -w ${path} ];then
	echo "L'utilisateur $USER ne peut pas écrire dans ${path}, relancez le programme en mode administrateur pour tenter de fixer le problème"
fi

if ! checkIfAllowed $USER &&[ $EUID -ne 0 ];then
        echo "$USER n'es pas autorisé. Faites ajouter votre nom dans /etc/tacheron.allow ou retirer de /etc/tacheron.deny"
else
        # echo "DEBUG: $USER autorisé"
	actionUser=$USER

	while :;do
		temps=15
		starttime=$(date +%s)
		SAVEIFS=$IFS
		IFS=$(echo -en "\n\b")
		for i in ${path}/tacheron*;do
			username=$(echo $i | sed 's/\/etc\/tacheron\/tacheron//')
			if checkIfAllowed ${username}||[ "${username}" = "root" ];then
				# echo "DEBUG: Lecture de $i"
				for j in $(cat $i);do
					ch1=$(echo "$j" | cut --delimiter=" " -f 1)
					ch2=$(echo "$j" | cut --delimiter=" " -f 2)
					ch3=$(echo "$j" | cut --delimiter=" " -f 3)
					ch4=$(echo "$j" | cut --delimiter=" " -f 4)
					ch5=$(echo "$j" | cut --delimiter=" " -f 5)
					ch6=$(echo "$j" | cut --delimiter=" " -f 6)

					ch7=$(echo "$j" | cut --delimiter=" " -f 7-)

					# NdlR : il faut quoter le paramètre SINON le "*" passe mal (listage du répertoire)
					# faire la même chose si on a un echo dedans
					calculerTemps "${ch1}" "${ch2}" "${ch3}" "${ch4}" "${ch5}" "${ch6}"
					valider="$?"

					if [ ${valider} -eq 1 ];then
						# echo "DEBUG: Execution avec les droits de ${username} de la commande : ${ch7}"
						su -l -c "${ch7} &" "${username}"
						echo "$(date) - ${username} - ($?) - ${ch7}" >> /var/log/tacheron
					fi
				done
			#else
				# echo "DEBUG: utilisateur ${username} non-autorisé."
			fi
		done
		IFS=${SAVEIFS}
		temps=$(echo "$temps - ($(date +%s) - ${starttime})" | bc)
		# echo "DEBUG: Sleeping pendant ${temps}"
		sleep "${temps}"
	done
fi

