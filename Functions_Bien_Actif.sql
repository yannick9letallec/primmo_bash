/* FONCTIONS - BIEN & ACTIF */
/*
 * TODO :
 * 	nb jours loués par an / total
 */

DROP FUNCTION IF EXISTS primmo_bash_dev.colocation_calculer_taux_occupation_annuel;
-- default to brut ( calcul en année pleine )
-- TODO :
	-- gestion du nb de colocataire au dela de la date du jour
CREATE OR REPLACE FUNCTION primmo_bash_dev.colocation_calculer_taux_occupation_annuel( id_actif int, net boolean = false)
RETURNS table( annee text, tx_occupation NUMERIC ) AS
$$
 declare
	r record;
	annee_min integer;
	annee_max integer;
	annee_en_cours integer;	
	jours_en_cours date;
	jour_actuel date;
	date_debut_annee date;
	date_fin_annee date;
	nb_colocataires_jour integer;
	nb_colocataire_reel_sur_annee integer = 0;
	nb_colocataire_max_sur_annee integer = 0;
	taux_occupation numeric( 10, 2 );
	nb_actifs numeric = 7;
 begin
	raise notice 'FONCTION : calculer_taux_occupation';

	jour_actuel = current_date;
	annee_min = ( select extract( year from ( min( lower( periode_occupation )))) from primmo_bash_dev.locataire );
	
	-- preferer today / current_date ?
		-- annee_max = ( select extract( year from ( max( upper( periode_occupation )))) from locataire );
	annee_max = extract( year from ( current_date ) );

	annee_en_cours = annee_min;
    
	<<annees>>
	loop 
		raise notice 'Année en cours : %', annee_en_cours;
		-- nieme_jour = 1;

		date_debut_annee = date( annee_en_cours || '-01-01' );
		jours_en_cours = date_debut_annee;

		date_fin_annee = date( annee_en_cours || '-12-31' );
		raise notice 'Année en cours : %, %', date_debut_annee, date_fin_annee;

		nb_colocataire_reel_sur_annee = 0;
		nb_colocataire_max_sur_annee = 0;

		<<jours>>
		loop 
			nb_colocataires_jour = ( select count(*) from locataire where jours_en_cours <@ periode_occupation::daterange );
			raise notice 'Jours en cours : %,  NB Colocataires Jours : %, NB Colocataires Réels : %, NB Colocaaires Max : %', jours_en_cours, nb_colocataires_jour, nb_colocataire_reel_sur_annee, nb_colocataire_max_sur_annee;

			nb_colocataire_reel_sur_annee = ( nb_colocataire_reel_sur_annee + primmo_bash_dev.nb_colocataires_present( jours_en_cours ));
 			nb_colocataire_max_sur_annee = ( nb_colocataire_max_sur_annee + nb_actifs );

			taux_occupation = ( nb_colocataire_reel_sur_annee::numeric / nb_colocataire_max_sur_annee::numeric ) * 100;

			raise notice 'NB Colocataires REEL : %', nb_colocataire_reel_sur_annee;
			raise notice 'NB Colocataires MAX : %', nb_colocataire_max_sur_annee;
			raise notice 'Taux Occupation : %', taux_occupation;

			if jours_en_cours = current_date then
				exit jours;
			end if;

			if jours_en_cours = date_fin_annee then
				exit jours;
			end if;

			jours_en_cours = jours_en_cours + 1;
		end loop;

			if annee_en_cours = extract( year from ( current_date ) ) then
				raise debug '*************************';
				annee = annee_en_cours::text || '*';
			else
				annee = annee_en_cours;
			end if;

			tx_occupation = taux_occupation;
			return next;

		if annee_en_cours = annee_max then
			exit annees;
		end if;
		annee_en_cours = annee_en_cours + 1;
	end loop;

	return;
 end
$$
LANGUAGE plpgsql SET search_path TO 'primmo_bash_dev' SECURITY DEFINER;
-- SELECT * FROM primmo_bash_dev.colocation_calculer_taux_occupation_annuel( 1 );


DROP FUNCTION IF EXISTS primmo_bash_dev.actif_nb_baux( int );
CREATE OR REPLACE FUNCTION primmo_bash_dev.actif_nb_baux ( id_bien int = 1 )
RETURNS table( id_bien int, id_actif int, LABEL TEXT, nb_baux int ) AS
$$
	select 
		distinct id_bien as id_bien,
		a.id as id_actif, 
		a.label,
		count( periode_occupation ) over ( partition by a.id ) as nb_baux
	from primmo_bash_dev.locataire c
	right outer join primmo_bash_dev.actif a on c.fk_actif = a.id
	where a.fk_bien = id_bien
	order by a.id asc, nb_baux desc;
$$
LANGUAGE SQL SET search_path TO 'primmo_bash_dev' SECURITY DEFINER;
SELECT * FROM primmo_bash_dev.actif_nb_baux();


/*
DROP FUNCTION IF EXISTS primmo_bash_dev.bien_bilan_occupation;
CREATE OR REPLACE FUNCTION primmo_bash_dev.bien_bilan_occupation( )
RETURNS table( chambre_id int, vacances datemultirange ) AS
$$
 
$$
LANGUAGE sql SET search_path TO 'primmo_bash_dev' SECURITY DEFINER;
*/

DROP FUNCTION IF EXISTS primmo_bash_dev.actif_periodes_vacance;
CREATE OR REPLACE FUNCTION primmo_bash_dev.actif_periodes_vacance( id_bien int DEFAULT 1 )
RETURNS table( chambre_id int, vacances datemultirange ) AS
$$
 declare
	r record;
	u record;
	return_row record;
	mise_en_service date;
	borne_superieure date;
	periode_activite datemultirange;
 begin
	raise notice 'FONCTION : periodes_vacance';
	
	mise_en_service = ( select t.mise_en_service from primmo_bash_dev.bien t where t.id = 1 );
	borne_superieure = date( '9999-12-31' );
	periode_activite = datemultirange( daterange( mise_en_service, borne_superieure, '[)' ));
	raise notice 'periode activite: %', periode_activite;	

	<<num_actif>>
	for r in 
		with periodes_locatives_par_chambre as (
			select 
				a.id, 
				case when ( upper_inf( periode_occupation ) ) then
					daterange( lower( periode_occupation ), '9999-12-31' )
				else 
					periode_occupation
				end as po
			from primmo_bash_dev.locataire c
			right outer join primmo_bash_dev.actif a on c.fk_actif = a.id
			where a.fk_bien = id_bien
			order by a.id
		) select
				p.id,
				range_agg( p.po ) as baux_agg
			from primmo_bash_dev.locataire c 
			right outer join periodes_locatives_par_chambre p on p.id = c.fk_actif
			group by ( p.id )
			order by baux_agg
	loop
		raise notice 'Chambre N° : %', r.id;	
		raise notice 'Val: %', r.baux_agg;

		chambre_id = r.id;

		if r.baux_agg is not null then
			vacances = periode_activite - r.baux_agg;
		else
			vacances = periode_activite;
		end if;

		return next;
	end loop;

	return;
 end
$$
LANGUAGE plpgsql SET search_path TO 'primmo_bash_dev' SECURITY DEFINER;
--SELECT * FROM primmo_bash_dev.actif_periodes_vacance( );
