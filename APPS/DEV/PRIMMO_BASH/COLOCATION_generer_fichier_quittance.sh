#!/bin/bash

echo -e "[D] : FUNCTION generer_quittance_io"

psql -U yannick -d test_0 -F'|' -P format=unaligned -tc "$1" | while IFS='|' read -r periode fichier nom_fichier; do
	# quittance_nom_fichier=quittance_loc_id_${loc_id}${nom_prenom}${periode}.pdf

	# bash adds a space from outer space, what's going on ?
	# quittance_nom_fichier=$( echo "${quittance_nom_fichier}" | sed 's/ //g' )

	# echo $quittance_nom_fichier

	echo -e "Création Quittance en cours : ${periode}" 
	echo -e ${fichier} | pandoc --wrap=preserve -f markdown -t pdf -o "${quittance_dest_repo}/${nom_fichier}" 
	if [ $? -eq 0 ] 
	then
		confirm_action "OK : ${nom_fichier}" ${er}
	else
		error  "KO : Génération de la quittance ( ${nom_fichier} ) :" "$er"
	fi
done

