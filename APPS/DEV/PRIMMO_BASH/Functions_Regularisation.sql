/* FONCTIONS REGULARISATION */


DROP FUNCTION IF EXISTS primmo_bash_dev.regularisation_est_presente;
CREATE OR REPLACE FUNCTION primmo_bash_dev.regularisation_est_presente( locataire_id integer )
RETURNS boolean AS
$$
 declare
   regularisation_existe boolean;
 begin
	RAISE notice 'FONCTION : regularisation_est_presente.';

	select exists( select count(*) from regularisation where fk_locataire = locataire_id having count(*) > 0 ) into regularisation_existe;
	raise notice 'regularisation_existe : %', regularisation_existe;
   
	return regularisation_existe;
 end
$$
LANGUAGE plpgsql PARALLEL SAFE SET search_path TO 'primmo_bash_dev' SECURITY DEFINER;


/*
 * Recherche et information des locataire pour qui une régularisation est pertinente
 */
DROP FUNCTION IF EXISTS primmo_bash_dev.regularisations_pertinentes;
CREATE OR REPLACE FUNCTION primmo_bash_dev.regularisations_pertinentes()
RETURNS boolean AS
$$
 declare
 begin
	
 end
$$
LANGUAGE plpgsql PARALLEL SAFE SET search_path TO 'primmo_bash_dev' SECURITY DEFINER;

/*
 * Pertinentes si : 
 * 		sont cloturables
 * 		ou
 * 		si regul existe ;
 * 			de nouvelles factures sont dispo
 * 		sinon
 * 			des factures existent, qui sont ultérieurs à la date de début de bail 
 */
DROP FUNCTION IF EXISTS primmo_bash_dev.regularisation_est_pertinente;
CREATE OR REPLACE FUNCTION primmo_bash_dev.regularisation_est_pertinente( id_locataire integer, date_regul text default now() )
RETURNS boolean AS
$$
 declare
	tab_char text = E'\t';
 	locataire_existe boolean;
   	est_pertinent boolean = false;
	est_cloture boolean;
    id_regul integer;
	date_debut_bail date;
	date_fin_bail date;
	periode_locataire_a_recouvrir daterange; 
	periode_charges daterange;
 BEGIN
	 RAISE notice 'FONCTION : Charges Sont Pertinentes.';
	
	-- PRECONDITIONS & SORTIES
	 SELECT EXISTS ( SELECT id FROM locataire AS c WHERE id = id_locataire ) INTO locataire_existe ;
	 IF NOT locataire_existe THEN 
	 	RAISE EXCEPTION '% Le locataire demandé n''existe pas  ...', tab_char;
	 END IF;
	
	 est_cloture = ( SELECT est_charge_cloture FROM locataire AS c WHERE id = id_locataire );
	 if est_cloture then 
	 	return false;
	 end if;
	
	 if charges_sont_cloturables( id_locataire) then 
	 	RAISE notice '% Charges cloturables, donc pertinentes.', tab_char;
	 	return true;
	 end if;
		
	-- selection de la periode la plus élargie possible des charges disponibles
	periode_charges  = ( select daterange( min( lower( periode ) ), max( upper( periode ) ) ) from charges where EST_FRACTIONNABLE );
	
	-- absence de charges
	if upper( periode_charges ) - lower( periode_charges ) is null THEN
		RAISE notice '% Aucunes charges disponibles. Régularisation non pertinente.', tab_char;
		return false;
	end if;
	
	id_regul = ( select max(id) from TEST.REGULARISATION where FK_COLOCATAIRE = id_locataire );
	IF id_regul IS NOT NULL THEN
		-- contient au moin un type de charge
		-- pour ceux absents remonter dans les regul eventuellement jusqu'au début du bail
		raise notice '% Regularisation trouvée pour le locataire : %', id_locataire, tab_char; 
		raise notice '% Lancement de l''analyse de la situation : Appel de la fonction  regularisation_moteur_de_calcul...', tab_char;
	
		RETURN regularisation_moteur_de_calcul( id_locataire, 'est_pertinent' );
	else  
		-- pas de régul. On cherche des dates de facture supérieures à la date de début de bail du locataire
		date_debut_bail = ( select lower( PERIODE_OCCUPATION  ) from TEST.COLOCATAIRE C where id = id_locataire );

		raise notice '% Regularisation non trouvée pour le locataire : %', id_locataire, tab_char;
		raise notice '% Utilisation du début de bail pour la recherche de pertinence : %', date_debut_bail, tab_char;
	
		date_fin_bail = date_fin_bail( id_locataire );

		if date_fin_bail is not null then
			periode_locataire_a_recouvrir = daterange( date_debut_bail, date_fin_bail );
		else					
			periode_locataire_a_recouvrir = daterange( date_debut_bail, current_date );
		end if;

		est_pertinent = periode_locataire_a_recouvrir && periode_charges;
		raise notice '% periode_locataire_a_recouvrir : %, periode_charges : %, est_pertinent : %.', periode_locataire_a_recouvrir, periode_charges, est_pertinent, tab_char;

		RETURN est_pertinent;
	end if;
 end 
$$
STABLE LANGUAGE plpgsql SET search_path TO 'primmo_bash_dev' SECURITY DEFINER;


DROP FUNCTION IF EXISTS primmo_bash_dev.lire_derniere_date_regul;
CREATE OR REPLACE FUNCTION lire_derniere_date_regul( locataire_id integer )
RETURNS date AS
$$
 declare
  d date;
 begin
 	raise notice 'FONCTION : lire_derniere_date_regul';

  d = ( select max( ts_date_regularisation ) from regularisation where fk_locataire = locataire_id );
  
  if d is null then
    raise warning 'Aucune Régularisation trouvée pour le locataire : %', locataire_id;
  end if;
 
  return d;
 end
$$
LANGUAGE plpgsql SET search_path TO 'primmo_bash_dev' SECURITY DEFINER STABLE;


DROP FUNCTION IF EXISTS primmo_bash_dev.locataire_lire_regularisation( int ) RESTRICT;
CREATE OR REPLACE FUNCTION primmo_bash_dev.locataire_lire_regularisation( id_locataire int )
RETURNS text  	
AS $$
	declare
		rec record;
	begin
			raise notice 'FO?CTION : locataire_lire_regularisation';
			return 'zoooom';
	end;
$$ 
LANGUAGE plpgsql SET search_path TO 'primmo_bash_dev' SECURITY DEFINER IMMUTABLE;


DROP FUNCTION IF EXISTS primmo_bash_dev.locataire_lire_lignes_regularisations( int ) RESTRICT;
CREATE OR REPLACE FUNCTION primmo_bash_dev.locataire_lire_lignes_regularisations( id_regularisation int )
RETURNS SETOF primmo_bash_dev.ligne_regularisation --table( id_regul date, provision_de_charge_affectee_a_la_periode_de_regul NUMERIC, total_individuel NUMERIC, total_charges_reelles_globalles NUMERIC )
AS $$
		select
			l.*
		from primmo_bash_dev.ligne_regularisation l 
		inner join primmo_bash_dev.regularisation r on r.id = l.fk_regularisation
		where r.id = 5;
$$ 
LANGUAGE sql SET search_path TO 'primmo_bash_dev' SECURITY DEFINER IMMUTABLE;


DROP FUNCTION IF EXISTS primmo_bash_dev.regularisation_precondition_calcul( int );
CREATE OR REPLACE FUNCTION primmo_bash_dev.regularisation_precondition_calcul( IN locataire_id integer )
RETURNS boolean AS
$$
 begin
	raise notice 'FONCTION : regularisation_precondition_calcul ( commune a un appel de charge réel / fictif ).';

	if charges_sont_cloturees( locataire_id ) then
		raise notice 'CHARGES DEJA CLOTUREES. LOCATAIRE : %', locataire_id; 
		return false;
	end if;

	if not regularisation_est_pertinente( locataire_id ) then
		raise notice 'Pas de nouvelles charges à impacter au locataire : %', locataire_id; 
		return false;
	end if;

	return true;
 end
$$
LANGUAGE plpgsql VOLATILE SET search_path TO 'primmo_bash_dev' SECURITY DEFINER;
-- SELECT primmo_bash_dev.regularisation_precondition_calcul( 7 );



DROP TYPE IF EXISTS regularisation_out_type CASCADE;
CREATE TYPE regularisation_out_type AS (
    msg TEXT,
    value numeric
);
/*
DROP FUNCTION IF EXISTS regularisation_apercu_situation_locataire( int );
CREATE OR REPLACE FUNCTION regularisation_apercu_situation_locataire( IN locataire_id integer )
RETURNS :env.regularisation_out_type AS
$$
 declare
 begin
	raise notice 'FONCTION : regularisation_apercu_situation_locataire';
end
$$
LANGUAGE plpgsql VOLATILE SET search_path TO 'primmo_bash_dev' SECURITY DEFINER;
*/


DROP FUNCTION IF EXISTS regularisation_creer_pour_locataire( int );
CREATE OR REPLACE FUNCTION regularisation_creer_pour_locataire( IN locataire_id integer  )
RETURNS regularisation_out_type AS
$$
 declare
  montant_regul numeric := 0;
  oResult regularisation_out_type;
 begin
	raise notice 'FONCTION regularisation_creer_pour_locataire ( version standart - pas forfait, de moyenne ... ). ';
	-- PRE CONDITIONS & SORTIES ...


	if not regularisation_precondition_calcul( locataire_id ) then
		oResult.msg = 'KO - Les préconditions pour un appel de charge, réel ou fictif ne sont pas remplies pour le locataire : ' || locataire_id || '. ( voir notifications / logs ).';
		oResult.value = null; 
		return oResult;
	end if;
  

  -- regularisation_moteur_de_calcul = fonction en tronc commun avec est_pertinente
  PERFORM regularisation_moteur_de_calcul( locataire_id, 'calcul' );
  

  montant_regul = ( select credit_bailleur_sur_provision from regularisation where FK_COLOCATAIRE = locataire_id ORDER BY id DESC LIMIT 1 ); 

  raise notice 'A REGLER : %', montant_regul;
  
  oResult.msg = 'Nouvelle régularisation créee ';
  oResult.value = montant_regul;
  return oResult;
end
$$
LANGUAGE plpgsql VOLATILE SET search_path TO 'primmo_bash_dev' SECURITY DEFINER;


/*
 * calcul : permet d'adapter le retour de la fonction suivant la fonction d'appel
 */
DROP FUNCTION IF EXISTS regularisation_moteur_de_calcul;
CREATE OR REPLACE FUNCTION primmo_bash_dev.regularisation_moteur_de_calcul( IN locataire_id integer, algo_type TEXT, d date DEFAULT null )
RETURNS boolean AS
$$
	DECLARE
		c integer; -- charge / used by the foreach LOOP
  		r record;
  		row_count int = 0;
  	  	nb_loc int;
		nb_jour int = 0;
  	   	montant_j numeric;
  	    montant_ind_j numeric := 0;
  	    montant_ind_total numeric := 0;
		provisions_payees numeric;
		regularisation_existe boolean;
		regularisation_est_cloturable boolean;
	 	id_old_regularisation int;
	 	id_new_regularisation int;
		ligne_regularisation_type int = 1;
	 	date_regul date = now();
	 	date_debut_bail date;
	 	date_fin_bail date;
	 	date_debut_iteration date;
	 	date_fin_iteration date;
	 	date_arret_charge date;
	 	d_current date;
	 	date_max date = null;
	 	periode_charges daterange;
	    total_reel numeric := 0;
	    total_global numeric := 0;
	    total_global_ind numeric:= 0;
	    type_charges integer[] = ARRAY[ 1, 2, 3, 8888, 9999 ]; -- appeler la table de config // ARRAY[ 1, 2, 3, 9999 ];
	BEGIN
	raise notice 'FONCTION : regularisation_moteur_de_calcul';

	regularisation_est_cloturable = charges_sont_cloturables( locataire_id );
	regularisation_existe := regularisation_est_presente( locataire_id );

	id_old_regularisation = ( select max(id) from TEST.REGULARISATION where fk_locataire = locataire_id );
	select lower ( periode_occupation ), upper ( periode_occupation ) INTO date_debut_bail, date_fin_bail from locataire where id = locataire_id;

	IF algo_type = 'calcul' THEN 
		provisions_payees = calcul_provisions_payees( locataire_id, current_date );

		insert into regularisation ( fk_locataire, ts_date_regularisation, total_charges_provisionnees ) values
		( locataire_id, date_regul, provisions_payees ) returning id into id_new_regularisation;
	
	   	if regularisation_est_cloturable THEN 
	    	raise notice 'Regularisation Cloturables OU Date Fin Bail not null ( non cloturable mais bail terminé ): Date Fin Iteration = date_fin_bail';
	    	date_fin_iteration = date_fin_bail;	
		end if;
			 
	END IF;

	<<types_charges>>
	FOREACH c IN ARRAY type_charges
	LOOP
		select daterange( min( lower( periode ) ), max( upper( periode ) ) ) into periode_charges from charges where fk_type_charge = c AND EST_FRACTIONNABLE;
	/*
		IF date_fin_bail IS NOT NULL THEN
			periode_charges = '[ lower( periode_charges ), date_fin_bail ]'::daterange; 
		END IF;*/
	 
		IF algo_type = 'calcul' THEN
			IF NOT regularisation_est_cloturable THEN 
				date_fin_iteration = upper( periode_charges );
				
				IF date_fin_bail IS NOT NULL AND date_fin_bail <@ periode_charges THEN
					date_fin_iteration = date_fin_bail;
				END IF;
			END IF;
		
			IF NOT regularisation_est_cloturable AND date_fin_bail IS NOT NULL THEN 
				date_fin_iteration = date_fin_bail;
			END IF;
		END IF;
		
		IF regularisation_existe THEN 
			raise notice 'Regul Existe : %', id_old_regularisation;
		
			-- si un type de charge est absent
			IF NOT EXISTS ( SELECT fk_type_charge FROM ligne_regularisation WHERE fk_type_charge = c AND fk_regularisation = id_old_regularisation ) THEN 			
				raise notice 'Le type charge : % : est absent de la dernière régularisation : %', c, id_old_regularisation;
				raise notice 'Recherche dans les anciennes régularisations ...';
				-- on cherche dans les regularisation précédentes

				row_count = 0;
				FOR r IN EXECUTE format( '
					SELECT 
						r.id as id_regul, lr.id as id_lr, ( lr.ts_date_arret + INTERVAL ''1 DAY'' ) as date_arret, lr.fk_type_charge as type_charge 
					from regularisation AS r 
					INNER JOIN ligne_regularisation AS lr ON r.id = lr.fk_regularisation 
					WHERE r.fk_locataire = %s and lr.fk_type_charge = %s
					ORDER BY r.id DESC',  locataire_id, c )
				LOOP 
					--RAISE NOTICE 'REGUL ID : %, Type Charge : %, Date arrêt : %, periode_charges : %', r.id_regul, r.type_charge, r.date_arret, periode_charges;
					raise notice 'Type charge : %, trouvé dans une ancienne régularisation : %,  ligne : %', c, r.id_regul, r.id_lr;
				
					row_count = row_count + 1;
				
					IF date_fin_bail IS NULL THEN
						raise notice 'Bail en cours ...';
						IF  r.date_arret::date + 1 <@ periode_charges THEN
							raise notice 'L apériode du type charge inclus la deernière  date arret du type charge + 1  ...';
							CASE 
								WHEN algo_type = 'est_pertinent' THEN 
										RETURN TRUE;
								WHEN algo_type = 'calcul' THEN 
										date_debut_iteration = r.date_arret::date + 1;
							END CASE;
						END IF; 
					ELSE
						raise notice 'Bail terminé ...';
						IF  r.date_arret::date + 1 <@ periode_charges AND r.date_arret::date + 1 < date_fin_bail THEN 
							raise notice 'La dernière date d arret du type charge + 1 jour précède la fin du bail et est incluse dans la période élargie du type charge  ...';						
							CASE 
								WHEN algo_type = 'est_pertinent' THEN 
										RETURN TRUE;
								WHEN algo_type = 'calcul' THEN 
										date_debut_iteration = r.date_arret::date + 1;
							END CASE;
						ELSE
							raise notice 'La date arret de la période élargie de validité du type de charge est postérieure à la date de fin de bail. RAF  ';
							continue types_charges;
						END IF; 
					END IF; 	
				END LOOP;
							
				-- absence totale du type de charge dans les régularisations précédentes
				IF row_count = 0 THEN
 
					raise notice 'Aucune régularisation n''intègre ce type de charge';
					raise notice 'Type charge : %, non trouvé dans aucune régul, recherche sur date de début du bail. Periode charge : , %', c, periode_charges;
			
					IF lower_inf( periode_charges ) OR upper_inf( periode_charges ) THEN
							CASE 
								WHEN algo_type = 'est_pertinent' THEN
									CONTINUE;
								WHEN algo_type = 'calcul' THEN
									date_debut_iteration = date_debut_bail;										
							END CASE;
					ELSE 
						IF  date_debut_bail::date <@ periode_charges THEN 
							CASE 
								WHEN algo_type = 'est_pertinent' THEN
									RETURN TRUE;
								WHEN algo_type = 'calcul' THEN
									date_debut_iteration = date_debut_bail;										
							END CASE;
						END IF;
					END IF;					
				END IF;

			ELSE
				raise notice 'Le type charge : % : est présent dans la dernière régularisation : %', c, id_old_regularisation;
			
				SELECT ts_date_arret INTO date_arret_charge FROM ligne_regularisation WHERE fk_type_charge = c AND fk_regularisation = id_old_regularisation;
			
				IF date_arret_charge::date + 1 <@ periode_charges THEN 
					raise notice 'Une nouvelle facture est disponible, sur la période de charge suivante : %', periode_charges;
					CASE 
						WHEN algo_type = 'est_pertinent' THEN 
							IF date_arret_charge::date + 1 < date_fin_bail OR date_fin_bail IS NULL THEN 
								raise notice 'Bail en cours, ou date_arret_charge < date_fin_bail';
								RETURN TRUE;
							ELSE
								raise notice 'Bail Terminé ( Type de charge couvert sur la période du bail )';
								CONTINUE; -- erreur ? CONTINUE  ?
							END IF;
						WHEN algo_type = 'calcul' THEN
							IF DATE_FIN_BAIL IS NOT NULL AND date_arret_charge = date_fin_bail THEN
								raise notice 'Bail Terminé ( Type de charge couvert sur la période du bail ) ... RAF'; 
								CONTINUE;
							END IF;
						
							date_debut_iteration = date_arret_charge + 1;
						
							IF date_fin_bail IS NOT NULL THEN 
								date_fin_iteration = date_fin_bail;
							ELSE 
								date_fin_iteration = upper( periode_charges );
							END IF;
					END CASE;
				ELSE
					raise notice 'Pas de nouvelles facture disponible';
					CONTINUE;
					/*
					CASE 
						WHEN algo_type = 'est_pertinent' THEN NULL; -- ON doit laisser l'algo avancer
						WHEN algo_type = 'calcul' THEN 
							raise notice 'RAF - Continue LOOP !';
							CONTINUE;	
					END CASE;
					*/
				END IF;			
			END IF;			
		
		ELSE 
			raise notice 'Aucune Regularisation Trouvée';
			date_debut_iteration = date_debut_bail;
		END IF; 
	
	   
	    IF algo_type = 'calcul' THEN
	    	d_current = date_debut_iteration;

	    	<<periode>>
	 		LOOP -- temporelle : sur la période ( date debut --- date fin )
				-- Specifique Charges Individuelles Exceptionnelles
				if c = 9999 then
					total_reel = ( select sum( montant ) from charges c where fk_type_charge = 9999 and daterange( date_debut_iteration, date_fin_iteration ) @> c.date_emission::date );	

					if total_reel is not null then 
						insert into ligne_regularisation( fk_regularisation, fk_type_charge, fk_ligne_regularisation_type, montant_total, montant_individuel ) 
			        	values  ( id_new_regularisation, c, ligne_regularisation_type, total_reel, total_reel );
					end if;

					exit periode;
				end if; 

				nb_jour = nb_jour + 1 ;

		    	nb_loc = ( select nb_locataires_present( d_current ) );	
		        montant_j  = ( select montant_journalier from charges where d_current::date <@ periode::daterange and fk_type_charge = c );

				-- pas de facture sur la période, on base le calcul sur un montant arbitraire / forfaitaire / moyenné
				if montant_j is null then 

					raise notice '---- Pas de facture disponible';
					-- dans le cas de l'eau, montant forfaitaire individuel et journalier.
					case when c = 1 then
						raise notice '---- EAU : on se base sur un montant forfaitaire journalier & individuel';
						montant_j  = ( select montant_forfaitaire_journalier_individuel from type_charge where id = c );

						ligne_regularisation_type = 2;
						total_reel = total_reel + montant_j;
          				montant_ind_total = montant_ind_total + montant_j;
						-- calculer le montant journalier moyen sur la periode du bail
	
						

					-- ( cas initial ) on utilise le montant journalier basé sur une facturation réelle
					else
					  raise notice '---- ELEC / GAZ : on se base sur le plus haut montant journalier connu sur la période du bail. CE qui donne un certain reflet de la saisonnalité et optimise ( peu ) la valorisation.';

					  montant_j = ( select max( montant_journalier ) from charges where fk_type_charge = c and periode && ( select periode_occupation from locataire where id = locataire_id ) );

					  total_reel = total_reel + montant_j;
			          montant_ind_j = montant_j / nb_loc; -- on divise le montant de la charge par le nb de locataires du jour
			          montant_ind_total = montant_ind_total + montant_ind_j;
		     	  end case;

				else
					-- pour le cas ou le montant journalier de base est défini
					  total_reel = total_reel + montant_j;
			          montant_ind_j = montant_j / nb_loc; -- on divise le montant de la charge par le nb de locataires du jour
			          montant_ind_total = montant_ind_total + montant_ind_j;
				end if;


				--select * from charges where '2024-05-02'::date <@ periode; and fk_type_charge = 1;
		        raise notice 'NB LOCATAIRE : %, montant jour : %, type_charge : %, DATE MAX : %', nb_loc, montant_j, c, date_max;

	     	  	IF d_current = date_fin_iteration THEN
	     	  		raise notice 'd_current = date_fin_iteration';
	     	  		date_fin_iteration = d_current;
					date_max = d_current;
	     	  	END IF;
		         
		     	  raise notice 'MJ ........ %', montant_j;
		     	  raise notice 'Montant Ind J ........ %', montant_ind_j;
		      	  raise notice 'Montant Ind Total ........ %', montant_ind_total;
		       	  raise notice 'Montant Total Réel ........ %', total_reel;
		     	  raise notice 'TYPE CHARGE : %, DATE courante: %, date debut iter : %, date fin iter : %', c, d_current, date_debut_iteration, date_fin_iteration;
		          raise notice 'DATE MAX : %', date_max;      
		
        		-- si on a une date arret > date debut iteration, on peut ajouter la ligne regul
				if date_max is not null and date_max >= date_debut_iteration AND total_reel > 0.00::numeric then
			       		
	       			raise notice 'LIGNE REGUL INSERT';
		       		       		
			        insert into ligne_regularisation( fk_regularisation, fk_type_charge, fk_ligne_regularisation_type, montant_total, montant_individuel, ts_date_arret ) 
			        values  ( id_new_regularisation, c, ligne_regularisation_type, total_reel, montant_ind_total, date_max );
	
				end if;
		       
				EXIT periode when d_current = date_fin_iteration;

		        d_current = d_current + 1;
      		END LOOP; -- sur période
 		
			/* TODO : Traiter le cas des charges facturées directement au locataire */

      		raise notice 'Type charge : %, Date debut bail : %, Date fin bail : %, Debut Iteration : %, Fin Iteration : %, date courante dans la boucle : %', c, date_debut_bail, date_fin_bail, date_debut_iteration, date_fin_iteration, d_current;   
      
			ligne_regularisation_type = 1; -- on réinitialise à la valeur par défault
      		total_reel = 0;
		    montant_ind_total = 0;
		    date_max = null;
			nb_jour = 0 ;
   
			raise notice '/////////////////////////////////////////////////////////////';
			raise notice '/////////////////////////////////////////////////////////////';
 		END IF; 
	END LOOP; 

	IF algo_type = 'est_pertinent' THEN
 		-- aucune pertinence trouvée dans la boucle précédente, dédiées aux charges
 		RETURN false;
 	END IF; 

	IF algo_type = 'calcul' THEN
		-- TODO : recherche des charges INDIVIDUELLES
	end if;	

  	select sum( montant_total), sum( montant_individuel ) into total_global, total_global_ind from ligne_regularisation where fk_regularisation = id_new_regularisation;
  
	--montant_regul = total_global - total_global_ind;
	update regularisation set 
	 	total_charges_reelles_individuelles = total_global_ind,
		total_charges_reelles_globalles = total_global
  	where id = id_new_regularisation;

 	raise notice 'TOTAL GLOBAL: %', total_global; 
	raise notice 'TOTAL GLOBAL INDIVIDUALISE : %', total_global_ind; 
	raise notice 'PROVISION REGLEE : %', provisions_payees;
  	
    RETURN TRUE;
	END
$$
LANGUAGE plpgsql SET search_path TO 'primmo_bash_dev' security DEFINER;
