#!/bin/bash
#
# DB Config
ENV=test

SCHEMA=test
DB=test_0
SCHEMA=test
USER=yannick
email_test=yannick9letallec@gmail.com
file_copy_path=/var/lib/pgsql/data/CHARGES/Scripts/TEST/Files/INDIVIDUELLE
export PGPASSWORD=Freedom4What


# arg 1 : message informatif
# arg 2 : astuce ou message complémentaire
confirm_action(){
	gum style --foreground 212 --border-foreground 212 \
		--border double --align center --width 50 \
		--margin "1 2" --padding "2 4" \
		$1

	if [ $# -eq 2 ] 
	then
	gum style --foreground 212 --border-foreground 212 \
		--border double --align center --width 50 \
		--margin "1 2" --padding "2 4" \
		$2
	fi
}
export -f confirm_action

# arg 1 : error type
# arg 2 : error msg
error(){
	gum log --structured --level error $1
	gum style --foreground 212 --border-foreground 212 \
		--border double --align center --width 50 \
		--margin "1 2" --padding "2 4" \
		$2
}

end(){
	gum style --foreground 212 --border-foreground 212 \
		--border double --align center --width 50 \
		--margin "1 2" --padding "2 4" \
		$1
}


# QUITTANCE DOMAIN
generer_quittance_io(){
	echo -e "[D] : FUNCTION generer_quittance_io"

	psql -U yannick -d test_0 -F'|' -P format=unaligned -tc "$1" | while IFS='|' read -r periode fichier nom_fichier; do
		# quittance_nom_fichier=quittance_loc_id_${loc_id}${nom_prenom}${periode}.pdf

		# bash adds a space from outer space, what's going on ?
		# quittance_nom_fichier=$( echo "${quittance_nom_fichier}" | sed 's/ //g' )
	
		# echo $quittance_nom_fichier

		echo -e "Création Quittance en cours : ${periode}" 
		echo -e ${fichier} | pandoc --wrap=preserve -f markdown_strict -t pdf -o "${quittance_dest_repo}/${nom_fichier}" 
		if [ $? -eq 0 ] 
		then
			confirm_action "OK : ${nom_fichier}" ${er}
		else
			error  "KO : Génération de la quittance ( ${nom_fichier} ) :" "$er"
		fi
	done
								
		
}
