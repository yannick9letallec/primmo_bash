#!/bin/bash
#
## TODO :
#	Modularisation
#	Charges / Régularisation : par (co)locataire ... filtrage par bien inutile

# import des constantes et fonctions
. ./COLOCATION_utils.sh



# ############### TMP WORK ZONE
#############################


ACTION_phrase="Que souhaitez vous faire ?"


DOMAINE=$(gum choose --header="Quel domaine métier souhaitez-vous travailler ?" "Propriétés" "Colocataires" "Charges" "Régularisation"  "Quittances" "Assurances" "Reporting")


echo "Domaine de travail > $DOMAINE"
echo $ACTION_phrase

case $DOMAINE in
	Propriétés)
		A=$(gum choose --header="Que souhaitez vous faire ?" --label-delimiter=":" "Lister:1" "Ajouter:2" "Modifier Les Charges Obligatoires:3" "Gestion Actifs:4"  )

		case $A in
			1)
				psql -U $USER -d $DB --csv -c "select * from ${SCHEMA}.bien" | gum table
			;;
			2)

				label=$( gum input --placeholder "Label ?" )
				surface=$( gum input --placeholder "Surface Totale, en m2 ?" )
				date_mise_en_service=$( gum input --placeholder "Date mise en service ( YYYY-MM-DD ) ?" )
				teom=$( gum input --placeholder "TEOM ?" )
				comment=$( gum write --header "Ajouter un commentaire :" )

				charges_oblig=$( psql -U $USER -d $DB --csv -t -c "select concat(  label, ':', id ) from ${SCHEMA}.type_charge" | gum choose --header="Quelles sont les charges collectives obligatoires ?" --no-limit --label-delimiter=":")
				charges_arr=$( echo $charges_oblig | sed 's/ /,/g' )

				# echo $label $surface $date_mise_en_service $teom $comment $charges_oblig
				echo "Vous aller ajouter une Propriété avec les informations suivantes :"
				echo -e "\t Label : $label"
				echo -e "\t Surface : $surface"
				echo -e "\t Date mise en service : $date_mise_en_service"
				echo -e "\t TEOM : $teom"
				echo -e "\t Commentaire : $comment"
				echo -e "\t Charges Obligatoires : $charges_arr"


				gum confirm "Souhaitez vous poursuivre et enregistrer les informations ?"
				if [ $? -eq 1 ] 
				then
					: # noop
				else
					er=$( gum spin --show-error --show-stderr --title "Ecriture des données en cours ..." -- psql -U $USER -d $DB -c "INSERT INTO ${SCHEMA}.bien ( label, surface_totale, mise_en_service, teom, config, note ) VALUES ( '${label}', '${surface}', '${date_mise_en_service}', '${teom}', hstore( 'charges_obligatoires', '${charges_arr}' ), '${comment}');" 2>&1 )

					if [ $? -eq 0 ] 
					then
						confirm_action "OK : Insertion Data." "Pensez à ajouter des actifs à votre nouvelle Propriété !"
					else
						error  "KO : Erreur en insérant les données :" "$er"
					fi

				fi

			;;
			3)
				# choix de la propriété
				prop_id=$( psql -U $USER -d $DB --csv -t -c "select concat( label, ':', id ) from ${SCHEMA}.bien" | gum choose --header="Choisissez la propriété à impacter :"--label-delimiter=":" )

				charges_oblig=$( psql -U $USER -d $DB --csv -t -c "select concat(  label, ':', id ) from ${SCHEMA}.type_charge" | gum choose --header="Quelles sont les nouvelles charges obligatoires ?" --no-limit --label-delimiter=":")
				charges_arr=$( echo $charges_oblig | sed 's/ /,/g' )
					
				er=$( gum spin --show-error --show-stderr --title "Enregistrement des modifications en cours ..." -- psql -U $USER -d $DB -c "UPDATE ${SCHEMA}.bien set config = '\"charges_obligatoires\" => \"ARRAY[ $charges_arr ]\" ' where id = $prop_id;" 2>&1 )
				if [ $? -eq 0 ]
				then
						confirm_action "OK : Modification Data."  "Attentionx aux impacts sur les charges et les réguls. Nouveau cas : changement de charges obligatoires en cours de route. ( ex : remplacement chaudière par pompe à chaleur )"
				else
					error  "KO : Erreur en modifiant les données :" "$er"
				fi
				exit
			;;
			4)
				echo "Choisissez une propriété :"
				prop_id=$( psql -U $USER -d $DB --csv -t -c "select concat( label, ':', id ) from ${SCHEMA}.bien" | gum choose --header="Choisissez la propriété à impacter :" --label-delimiter=":" )

				A=$(gum choose "Lister" "Ajouter")

				case $A in
					Lister)
						psql -U $USER -d $DB --csv -c "select * from ${SCHEMA}.actif where fk_bien = $prop_id" | gum table
					;;
					Ajouter)
						label=$( gum input --placeholder "Label ?" )
						surface=$( gum input --placeholder "Surface, en m2 ?" )
						comment=$( gum write --header "Ajouter un commentaire :" )
							
						er=$( gum spin --show-error --show-stderr --title "Ecriture des données en cours ..." -- psql -U $USER -d $DB -c "INSERT INTO ${SCHEMA}.actif ( label, fk_bien, surface, note ) VALUES ( '${label}', '${prop_id}', '${surface}', '${comment}');" 2>&1 )

						if [ $? -eq 0 ]
						then
							confirm_action "OK : Insertion Data."
						else
							error "KO : Erreur en insérant les données :" "$er"
						fi
					;;
				esac
			;;
		esac
		;;

	Colocataires)
		A=$(gum choose --label-delimiter=":" "Lister Tout:1" "Lister Présents:2" "Lister Anciens:3" "Ajouter:4" "Demander Congé:5" "Annuler Demande Congé:6" "Régulariser les charge:7" )

		echo "Choisissez une propriété :"
		prop_id=$( psql -U $USER -d $DB --csv -t -c "select concat( label, ':', id ) from ${SCHEMA}.bien" | gum choose --header="Choisissez la propriété à impacter :" --label-delimiter=":" )

		case $A in
			1)
				echo "LISTER TOUT"
				psql -U $USER -d $DB --csv -c "select * from ${SCHEMA}.lister_locataires( $prop_id )" | gum table
				exit
			;;
			2)
				echo "LISTER PRESENTS"
				psql -U $USER -d $DB --csv -c "select * from ${SCHEMA}.lister_locataires_presents( $prop_id )" | gum table

			;;
			3)
				echo "LISTER ANCIENS"
				psql -U $USER -d $DB --csv -c "select * from ${SCHEMA}.lister_locataires_anciens( $prop_id )" | gum table
				
			;;
			4)
				echo "AJOUTER"
				
			;;
			5)
				echo "DEMANDER CONGE"
				echo "LISTER PRESENTS"
				loc_id=$( psql -U $USER -d $DB --csv -t -c "select concat( nom, ' ', prenom, ':', id ) from ${SCHEMA}.locataire where upper( periode_occupation ) is null or ( upper( periode_occupation ) is not null and periode_occupation @> current_date ) order by id" | gum choose --header="Affecter la demande de congé au colcoataire :" --label-delimiter=":" )

				date_fin_bail=$( gum input --placeholder "Date Fin de Bail Initiale ( YYYY-MM-DD ) ?" )
				echo -e "\t Date Fin de Bail Initiale : $date_fin_bail"

				if [ -z $date_fin_bail ]
				then
					gum style --foreground 212 --border-foreground 212 \
						--border double --align center --width 50 \
						--margin "1 2" --padding "2 4" \
						"ARRET : La date de fin de bail est vide. "
				else
					er=$( gum spin --show-error --show-stderr --title "Ecriture des modifications en cours ..." -- psql -U $USER -d $DB -c "update ${SCHEMA}.locataire set periode_occupation = daterange( lower( periode_occupation ), '${date_fin_bail}'::date ) where id = $loc_id;" 2>&1 )

					if [ $? -eq 0 ]
					then
						confirm_action "OK : Demande Congé Enregistrée."
						
					else
						error "KO : Erreur en modifiant les données :" "$er"
					fi
					
				fi
					
			;;
			6)
				echo "ANNULER DEMANDE CONGE"
				echo -e "\t -> Baux en cours, avec congé : exprimé et annulable"
				# on suppose que si la date de fin de bail est supérieure à la date courante, alors la demande de congé est ferme et définitive.
				loc_id=$( psql -U $USER -d $DB --csv -t -c "select concat( nom, ' ', prenom, ':', id ) from ${SCHEMA}.locataire where upper( periode_occupation ) is not null and ( upper( periode_occupation ) >= current_date ) order by id" | gum choose --header="Quel est le locataire concerné par l'annulation de la demande de congé ?" --label-delimiter=":" )

				if [ $? -eq 0 ] 
				then
					gum confirm "Souhaitez vous poursuivre et valider l'annulation de demande de congé initiale ?"
					if [ $? -eq 1 ] 
					then
						# no ...
						:
					else
						er=$( gum spin --show-error --show-stderr --title "Ecriture des modifications en cours ..." -- psql -U $USER -d $DB -c "update ${SCHEMA}.locataire set periode_occupation = daterange( lower( periode_occupation ), NULL ) where id = $loc_id;" 2>&1 )

						if [ $? -eq 0 ]
						then
							confirm_action "OK : Demande Congé Annulée."
							
						else
							error "KO : Erreur en modifiant les données :" "$er"
						fi
					fi
				else
					error "KO : Aucun locataire éligible pour annuler une demande de congé."
				fi
					
			;;
			7)
				echo "REGULARISER LES CHARGES ( par locataire )"
				echo -e "\t -> TODOs ...."
				echo -e "\t -> Créer / Pertinence / Clôturer ...."
					
			;;
			8)
				echo "GENERER QUITTANCES"
			;;
		esac
		;;

	Charges)
		A=$(gum choose --label-delimiter=":" "Lister:1" "Ajouter:2" )

		case $A in
			1)
				psql -U $USER -d $DB --csv -c "select * from ${SCHEMA}.charges" | gum table --no-hide-count
			;;
			2)
				echo "Ajouter une charge :"

				
				prop_id=$( psql -U $USER -d $DB --csv -t -c "select concat( label, ':', id ) from ${SCHEMA}.bien" | gum choose --label-delimiter=":" --header="Choisissez la propriété a affecter :" )

				gum confirm --show-output --affirmative="Collective" --negative="Individuelle" "Choisissez le mode comptable de la charge ?"

				if [ $? -eq 1 ]
				then
					loc_id=$( psql -U $USER -d $DB --csv -t -c "select concat( nom, ' ', prenom, ':', id ) from ${SCHEMA}.locataire where upper( periode_occupation ) is null or ( upper( periode_occupation ) is not null and periode_occupation @> current_date ) order by id" | gum choose --header="Colocataire à imputer :" --label-delimiter=":" )
					mode_charge=individuel
					type_charge=9999 # charges individuelles
				else
					mode_charge=collectif
					type_charge=$( psql -U $USER -d $DB --csv -t -c "select concat( label, ':', t.id ) from test.type_charge as t join ( select unnest( string_to_array( config -> 'charges_obligatoires', ',' ) )::integer id from test.bien b where id = ${prop_id} ) as b on t.id = b.id" | gum choose --header="Choisissez le type de charge collective à ajouter :" --label-delimiter=":")

				fi

				date_emission=$( gum input --placeholder "Date Emission ( YYYY-MM-DD ) ?" )
				periode_debut=$( gum input --placeholder "Période Début ( YYYY-MM-DD ) ?" )
				periode_fin=$( gum input --placeholder "Période Fin ( YYYY-MM-DD ) ?" )
				montant=$( gum input --placeholder "Montant ?" )
				comment=$( gum write --header "Ajouter un commentaire :" )
				file=$( gum file /home/yannickletallec/Téléchargements/IMMO_APP_Bannette )

				echo "Vous aller ajouter une Charge avec les informations suivantes :"
				echo -e "\t Mode Charge : $mode_charge"
				echo -e "\t Type Charge : $type_charge"
				echo -e "\t Date Emission : $date_emission"
				echo -e "\t Période Début : $periode_debut"
				echo -e "\t Période Fin : $periode_fin"
				echo -e "\t Montant : $montant"
				echo -e "\t Commentaire : $comment"

				if [ -z $file ]
				then
					echo -e "\t Fichier : $file"
				else
					echo -e "\t Aucun Fichier Sélectionné ..."
				fi


				gum confirm "Souhaitez vous poursuivre et enregistrer les informations ?"
				
				if [ $? -eq 1 ] 
				then
					: # noop ...
				else
					case $mode_charge in
						collectif)
							sql="INSERT INTO ${SCHEMA}.charges ( fk_type_charge, fk_bien, date_emission, periode, montant, file_name, note ) VALUES ( ${type_charge}, ${prop_id}, '${date_emission}', '[ ${periode_debut}, ${periode_fin} )', ${montant}, '${file}', '${comment}');" 
							;;
						individuel)
							sql="INSERT INTO ${SCHEMA}.charges ( fk_type_charge, fk_locataire, fk_bien, date_emission, montant, file_name, note ) VALUES ( ${type_charge}, ${loc_id}, ${prop_id}, '${date_emission}', ${montant}, '${file}', '${comment}');" 
							;;
					esac

					if [ -z $file ]
					then
						echo -e "\t Copie Fichier : $file"
						er=$( gum spin --show-error --show-stderr --title "Ecriture des données en cours ..." -- cp $file  2>&1 )

						if [ $? -eq 0 ] 
						then
							confirm_action "OK : Fichier Copié."
						else
							error "KO : Erreur en insérant les données :" "$er"
						fi
					fi

					er=$( gum spin --show-error --show-stderr --title "Ecriture des données en cours ..." -- psql -U $USER -d $DB -c "${sql}" 2>&1 )

					if [ $? -eq 0 ] 
					then
						confirm_action "OK : Insertion Data."
					else
						error "KO : Erreur en insérant les données :" "$er"
					fi
				fi
			;;
		esac
		;;

	Régularisation)
		A=$(gum choose "Lister:1" "Pertinence:2" "Créer:3")

		case $A in
			1)
				psql -U $USER -d $DB --csv -c "select * from ${SCHEMA}.regularisation" | gum table --no-hide-count 
			;;
			2)

			;;
			3)
				
			;;
			Modifier)
					
			;;
		esac
		echo "#5#"
		;;

	Quittances)
		. ./COLOCATION_quittance.sh
		;;
	Assurance)
		echo "- SECTION ASSURANCE"
		# Alerte si un des colocataire n'est pas assuré
		# Ajouter / Renouveler une assurance
		;;
	Reporting)
		echo "- SECTION REPORTING - PROJECT :: Mini/CLI - Dashboard "
		A=$(gum choose --label-delimiter=":" "Colocataires:1" "Charges:2" "Propriétées:3")
		case $A in 
			1)
			;;
			2)
			;;
			3)
			;;
		esac
		;;
esac


# PG/psql 'hack' to avoid interactive pwd prompt
# needs reset for obvious security reasons
unset $PGPASSWORD
exit
