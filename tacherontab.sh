#!/bin/bash

path='/etc/tacheron'
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

case ${action} in
	1)
		echo "DEBUG: list"
		if [ -f ${path}/tacheron${actionUser} ];then
                        echo "DEBUG: le fichier ${path}/tacheron${actionUser} va être affiché"
                        cat ${path}/tacheron${actionUser}
                else
                        echo "Le fichier ${path}/tacheron${actionUser} n'existe pas"
                fi
	;;
	2)
		echo "DEBUG: remove"
		if [ -f ${path}/tacheron${actionUser} ];then
			echo "DEBUG: le fichier ${path}/tacheron${actionUser} va être supprimé"
			rm ${path}/tacheron${actionUser}
		else
			echo "Le fichier ${path}/tacheron${actionUser} n'existe pas"
		fi
	;;
	3)
		echo "DEBUG: edit"
		if [ -f ${path}/tacheron${actionUser} ];then
                        echo "DEBUG: le fichier ${path}/tacheron${actionUser} va être ouvert"
                        cp ${path}/tacheron${actionUser} /tmp/tacheron${actionUser}
                else
                        echo "DEBUG: Le fichier ${path}/tacheron${actionUser} n'existe pas : création"
                fi

		vi /tmp/tacheron${actionUser}
		if [ -s /tmp/tacheron${actionUser} ];then
			cp /tmp/tacheron${actionUser} ${path}/tacheron${actionUser}
		else
			echo "Action annulée"
		fi
	;;
esac

