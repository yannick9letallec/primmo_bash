# USE CASES :
# 	Cas 0 : Aucune quittance générée / éditée
# 	Cas : 1 DEs Quittances Existent
# 		1.1 : Mise à jour nécessaire
# 		1.2 : A jour
# 	Dans tous les cas, on souhaite pouvoir réenvoyer les quittances par email

email_subject=Quittances


echo "- SECTION QUITTANCES -"
export quittance_dest_repo="./Files/QUITTANCES"

loc_id=$( psql -U $USER -d $DB --csv -t -c "select * from ${SCHEMA}.quittance_statut_from_gum()" | gum choose --header="Choisir le locataire pour lequel générer la/les quittances :" --label-delimiter=":" )

if [ -z $loc_id ]
then
	gum style --foreground 212 --border-foreground 212 \
		--border double --align center --width 50 \
		--margin "1 2" --padding "2 4" \
		"ARRET : Aucun locataire sélectionné"
	exit
else
	gum confirm "Poursuivre et générer les quittances ?"
	if [ $? -eq 0 ] 
	then
		er=$( gum spin --show-error --show-stderr --title "Génération des quittances en cours" -- psql -U $USER -d $DB -c "select ${SCHEMA}.quittance_generer( ${loc_id} );" 2>&1 )
		if [ $? -eq 0 ] 
		then
			confirm_action "OK : Formattage & Enregistrement des Quittances ( format : .md )." ${er}

			gum confirm "Générer les fichiers liés aux quittances ?"

			if [ $? -eq 0 ] 
			then
				# 0 - recherche de quittance préexistante 
			
				quittance_listing=$( find ${quittance_dest_repo} -name "quittance_loc_id_${loc_id}*" -type f -printf '%f\n' ) 
				nb_quittance=$(   find ${quittance_dest_repo} -name "quittance_loc_id_${loc_id}*" -type f -printf '%f\n' | wc -l )

				# aucune quittance
				if [ $nb_quittance -eq  0 ]
				then
					echo 'AUCUNE QUITTANCE TROUVEE'
					#on génère toutes les quittances
					 gum spin --show-error --show-stderr --title "Génération fichiers en cours ..." -- ./COLOCATION_generer_fichier_quittance.sh "copy ( select periode_couverte || '|' || contenu || '|' || nom_fichier from test.quittance where fk_locataire = ${loc_id} ) to stdout;"
				# quittances trouvées ( partiel ou total )
				else
					quittance_derniere=$( echo -e "${quittance_listing}" | sort -r | head -1 | grep -oP '\d{4}-\d{2}' )
					# echo -e $quittance_derniere
					echo -e ""${nb_quittance}" QUITTANCE(S) TROUVEE(S). Dernière en date : "${quittance_derniere}""

					gum spin --show-error --show-stderr --title "Génération fichiers en cours ..." -- ./COLOCATION_generer_fichier_quittance.sh "copy ( select periode_couverte || '|' || nom_fichier from test.quittance where fk_locataire = ${loc_id} and periode_couverte > "\'${quittance_derniere}\'" ) to stdout;"
				fi

				# gestion des quittances à jour, on selectionne celles à envoyer par email.
				id_quittances_a_envoyer=$( psql -U $USER -d $DB --csv -t -c "select  concat( periode_couverte, ':', id ) from ${SCHEMA}.quittance where fk_locataire=${loc_id}" | gum choose --header="Envoyer des quittances par mail ?" --no-limit --label-delimiter=":" --output-delimiter=" " )

				ids=""
				for id in ${id_quittances_a_envoyer}; do
					ids+="'${id}',"
				done

				# ! EMAIL DESTINATAIRE SELECTION
				if [ ${ENV} = 'PROD' ]
				then
					email_dest=$( psql -U yannick -d test_0 -tc "select email from ${SCHEMA}.locataire where id = ${loc_id};" )
				else
					email_dest=${email_test} 
				fi

				quittances_a_envoyer=$( psql -U $USER -d $DB --csv -t -c "select concat( '"${quittance_dest_repo}"', '/', nom_fichier ) from ${SCHEMA}.quittance where id in ( "${ids::-1}" )" ) 

				gum spin --show-error --show-stderr --title "Envoi de(s) email(s) en cours ..." -- mutt -s "Quittances" -s ${email_subject} ${email_dest} -a ${quittances_a_envoyer} < <( psql -U yannick -d test_0 -tc "copy ( select config -> 'quittance_email_tpl' from ${SCHEMA}.bien b inner join ${SCHEMA}.actif a on b.id = a.fk_bien inner join ${SCHEMA}.locataire l on a.id = l.fk_actif where l.id = ${loc_id} ) to stdout" | sed -e 's/\\n/\n/g'  )

				if [ $? -eq 0 ] 
				then
					confirm_action "OK : Envoi email : " ${er}
				else
					error  "KO : Envoi email :" "$er"
				fi
				# 1 - scan le repo des quittances
				# 2 - on cherche les quittances qui commencent par l'id du locataire
				# 3 - on extrait la dernière période de quittance

			else
				end "OK, SO GOOD BYE !!"
			fi
		else
			error  "KO : Erreur en générant les quittances :" "$er"
		fi
	else

		end "PK, SO GOOD BYE !"
	fi
fi



