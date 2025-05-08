# Dans la continuité d'utiliser psql comme 'utilitaire' de reporting.
# Et face au manque de boucle native dans psql / Un DBA en a t-il vraiment besoin ?!?
# \gexec se rapproche de la solution, en résolvant la contrinate fonctionnelle, mais ne réponds pas aux exigences de présentation...
# Un script BSHELL / BASH est donc la clef.
# \! mérite quelques précisions :
# 	support absent de l'interprétation des variables psql
# 	ouvre un subshell
# 	dans le quel on peut récupérer des variables placées dans l'environnement / le contexte d'eeccution de psql via \setenv
#
#
# data comes from env ( the bash scope )
echo "ID Colocataire : " ${id_reguls_colocataire}
echo "Environnement : " ${env_for_charges}

file_path=./regularisation_reporting_queries.sh 

# emptiing the file
: > ${file_path}

for item in ${id_reguls_colocataire}; do
	echo "select c.nom, c.prenom, * from ${env_for_charges}.regularisation r inner join ${env_for_charges}.locataire c on c.id = r.fk_locataire where r.id = ${item} ;" >> ${file_path}
	echo "select t.label, l.* from ${env_for_charges}.ligne_regularisation l inner join ${env_for_charges}.type_charge t on t.id = l.fk_type_charge  where fk_regularisation = ${item} ;" >> ${file_path}
done




