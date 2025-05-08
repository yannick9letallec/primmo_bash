/* FONCTIONS COLOCATAIRES */
/*
 * LISTE :
 * 		lister_locataires
 * 		lister_locataires_presents
 * 		lister_locataires_anciens
 * 		locataire_existe
 * 		verbose_duration_bail
 * 		date_fin_bail
 * 		nb_locataires_present
 * 		total_loyer_payes_hc_a_date
 * 		total_provisions_payees_a_date
 * 		locataire_lire_basique_info
 * 		bilan_occupation
 * 		calcul_provisions_payees
 * 		quittance_generer
 */


DROP FUNCTION IF EXISTS test.lister_locataires( int ) RESTRICT;
CREATE OR REPLACE FUNCTION test.lister_locataires ( id_bien int )
RETURNS table( id int, nom TEXT, prenom TEXT ) AS 
$$
	select c.id, nom, prenom 
			from locataire c 
			inner join actif a on c.fk_actif = a.id 
			inner join bien b on a.fk_bien = b.id
			where b.id = id_bien 
			order by c.id;
$$
LANGUAGE sql SET search_path TO test SECURITY DEFINER;


DROP FUNCTION IF EXISTS test.lister_locataires_presents( int ) RESTRICT;
CREATE OR REPLACE FUNCTION test.lister_locataires_presents ( id_bien int )
RETURNS table( id int, nom TEXT, prenom TEXT ) AS 
$$
select c.id, nom, prenom 
			from test.locataire c 
			inner join test.actif a on c.fk_actif = a.id 
			inner join test.bien b on a.fk_bien = b.id
			where b.id = id_bien 
			and upper( periode_occupation ) is null 
			or ( upper( periode_occupation ) is not null and periode_occupation @> current_date ) 
			order by c.id; 
$$
LANGUAGE sql SET search_path TO test SECURITY DEFINER;


DROP FUNCTION IF EXISTS test.lister_locataires_anciens( int ) RESTRICT;
CREATE OR REPLACE FUNCTION test.lister_locataires_anciens ( id_bien int )
RETURNS table( id int, nom TEXT, prenom TEXT ) AS 
$$
select c.id, nom, prenom 
			from test.locataire c 
			inner join test.actif a on c.fk_actif = a.id 
			inner join test.bien b on a.fk_bien = b.id
			where b.id = id_bien 
			and current_date > upper( periode_occupation )  
			order by c.id; 
$$
LANGUAGE sql SET search_path TO test SECURITY DEFINER;


DROP FUNCTION IF EXISTS test.locataire_existe ( int ) RESTRICT;
CREATE OR REPLACE FUNCTION test.locataire_existe ( id_locataire int )
RETURNS boolean  
AS 
$$
	declare 
		id_loc int;
	begin
		id_loc = ( select id from locataire where id = id_locataire );

		if id_loc is not null then
			return true;
		else
			return false;
		end if;
 end
$$
LANGUAGE plpgsql SET search_path TO test SECURITY DEFINER;


DROP FUNCTION IF EXISTS test.verbose_duration_bail;
CREATE OR REPLACE FUNCTION test.verbose_duration_bail( locataire_id integer )
RETURNS text AS
$$
 declare
  date_fin_calcul date;
  prefix text = '';
  msg text;
 BEGIN
	 raise notice 'FONCTION : verbose_duration_bail';

	select upper( periode_occupation ) into date_fin_calcul from test.locataire where id = locataire_id;

	if date_fin_calcul is null then
		 date_fin_calcul = current_date;
		 prefix = 'BIP : ';
	end if;

	select 
		case when extract( years from age ( date_fin_calcul, lower( periode_occupation ) ) ) > 0 then 
			extract( years from age ( date_fin_calcul, lower( periode_occupation ) ) ) || ' Année(s), '   
		else '' end
	    ||
    	extract( month from age ( date_fin_calcul, lower( periode_occupation ) ) ) || ' Mois, '
    	||
   		extract( day from age( date_fin_calcul, lower( periode_occupation ) ) ) || ' Jour( s )'
	into msg
	from test.locataire  
	where id = locataire_id;

		--select upper( periode_occupation ) - lower( periode_occupation )as duration from test.locataire;

   return prefix || msg;
 end
$$
LANGUAGE plpgsql SET search_path TO test SECURITY DEFINER;


DROP FUNCTION IF EXISTS test.date_fin_bail;
CREATE OR REPLACE FUNCTION test.date_fin_bail( locataire_id integer )
RETURNS date AS
$$
   select upper( periode_occupation ) from locataire where id = locataire_id;
$$
LANGUAGE sql SET search_path TO test SECURITY DEFINER;


DROP FUNCTION IF EXISTS test.nb_locataires_present;
CREATE OR REPLACE FUNCTION nb_locataires_present( d date )
RETURNS integer AS
$$
 declare
   nb_locataires integer;
 begin
	raise notice 'FONCTION : nb_locataires_present ( % )', d;

    nb_locataires = ( select count(*) from locataire where d::date <@ periode_occupation::daterange );
   
  	if nb_locataires = 0 then
		nb_locataires = 1;
	end if;
   return nb_locataires;
 end
$$
LANGUAGE plpgsql SET search_path TO test SECURITY DEFINER;


DROP FUNCTION IF EXISTS test.total_loyer_payes_hc_a_date;
CREATE OR REPLACE FUNCTION test.total_loyer_payes_hc_a_date ( locataire_id integer )
RETURNS numeric AS
$$
 declare
  date_debut_calcul date;
  date_fin_calcul date;
  date_fin_bail date;
  m numeric;
 BEGIN
	 raise notice 'FONCTION : calcul du total des loyer hc payésà date';

	select upper( periode_occupation ) into date_fin_calcul from test.locataire where id = locataire_id;

	if date_fin_calcul is null then
		 date_fin_calcul = current_date;
	end if;

	select loyer_mensuel_hc * ( extract( years from age (date_fin_calcul, lower( periode_occupation )  ) ) * 12 )
	    +
    ( loyer_mensuel_hc * extract( month from age ( date_fin_calcul, lower( periode_occupation )  ) ) )
    	+
    ( ( loyer_mensuel_hc / 30.5 ) * extract( day from age( date_fin_calcul, lower( periode_occupation )  ) ) )
		into m
	from test.locataire  
	where id = locataire_id;

   return m;
 end
$$
LANGUAGE plpgsql SET search_path TO test SECURITY DEFINER;


DROP FUNCTION IF EXISTS test.total_provisions_payees_a_date;
CREATE OR REPLACE FUNCTION test.total_provisions_payees_a_date ( locataire_id integer )
RETURNS numeric AS
$$
 declare
  date_debut_calcul date;
  date_fin_calcul date;
  date_fin_bail date;
  m numeric;
 BEGIN
	 raise notice 'FONCTION : calcul du total des charges provisionnées à date';

	select upper( periode_occupation ) into date_fin_calcul from test.locataire where id = locataire_id;

	if date_fin_calcul is null then
		 date_fin_calcul = current_date;
		raise notice 'Calcul des provisions payées depuis le début du bail jusqu''à : %', date_fin_calcul;
	else
		raise notice 'Calcul des provisions payées depuis le début du bail jusqu''à la fin du bail : %', date_fin_calcul;
	end if;

	select provision_charge_mensuelle * ( extract( years from age (date_fin_calcul, lower( periode_occupation )  ) ) * 12 )
	    +
    ( provision_charge_mensuelle * extract( month from age ( date_fin_calcul, lower( periode_occupation )  ) ) )
    	+
    ( ( provision_charge_mensuelle / 30.5 ) * extract( day from age( date_fin_calcul, lower( periode_occupation )  ) ) )
		into m
	from test.locataire  
	where id = locataire_id;

   return m;
 end
$$
LANGUAGE plpgsql SET search_path TO test security DEFINER;


DROP FUNCTION IF EXISTS test.locataire_lire_basique_info( int ) RESTRICT;
CREATE OR REPLACE FUNCTION test.locataire_lire_basique_info( id_locataire int )
RETURNS table( lieu TEXT, nom TEXT, prenom TEXT, id_actif int, date_entree date, label_actif TEXT, total_provisions_reglees NUMERIC, nb_regul int ) 
AS $$
		select
			b.label as lieu,
			nom,
			prenom, 
			fk_actif as id_actif,
			lower( periode_occupation ) as date_entree,
			a.label as label_,
			test.total_provisions_payees_a_date( id_locataire )::numeric( 10, 2 ) as total_provisions_reglees,
			( select count( id ) from  test.regularisation where fk_locataire = id_locataire ) as nb_regul -- avoid the aggregate constraint ( group by all projected columns )
		from test.locataire c
		inner join test.actif a on c.fk_actif = a.id
		inner join test.bien b on b.id = a.fk_bien  
		where c.id = id_locataire;
$$ 
LANGUAGE sql SET search_path TO test SECURITY DEFINER;


DROP FUNCTION IF EXISTS test.bilan_occupation( integer );
CREATE OR REPLACE FUNCTION test.bilan_occupation( locataire_id integer )
RETURNS SETOF record AS 
$$
 declare
  n int = 1;
  NB_jours_total int;
  NB_jours_commun int = 0;
  effectif int = 0;
  effectif_max int;
  d_current date;
  date_fin_calcul date;
  date_debut_bail date;
  date_fin_bail date;
  res record;
  m numeric;
 BEGIN
	 raise notice 'FONCTION : presence_moyenne.';

	if not locataire_existe( locataire_id ) then
		raise exception 'Aucun locataire trouvé avec l''id fourni : %.', locataire_id;
	end if;

	effectif_max = ( select count( id ) from actif a where fk_bien = (
		select fk_bien from actif a inner join locataire c on c.fk_actif = a.id and c.id = locataire_id ) 
	);

	date_debut_bail = ( select lower( periode_occupation ) from locataire where id = locataire_id );

	date_fin_bail = ( select date_fin_bail( locataire_id ) );
	if date_fin_bail is not null then
		date_fin_calcul = date_fin_bail;
	else
		date_fin_calcul = current_date;
	end if;

	NB_jours_total = ( select ( date( date_fin_calcul ) - date( date_debut_bail ) +1 ) );
 	-- raise notice 'NB_jours_total : %', NB_jours_total;

	<<actif>>
	LOOP
		raise notice '-------------> n : %', n;
		d_current = date_debut_bail;

		<<periode>>
		LOOP 
			raise notice 'Date : %', d_current;

			if( nb_locataires_present( d_current ) = effectif ) then 
				NB_jours_commun = NB_jours_commun  + 1;
				raise notice '///////////////////////////////////';		
				raise notice '///////////////////////////////////';		
			end if;
			
			if d_current = date_fin_calcul then
				exit periode;
			end if;
			d_current = d_current + 1;

		END LOOP;

		raise notice 'NB_jours_total : % --- Effectif : % --- NB_jours_commun : %', NB_jours_total, effectif, NB_jours_commun;
		
		res = row( NB_jours_total, effectif, NB_jours_commun );
		return next res; 
		-- res.NB_jours_total, n, res.NB_locataires_presents;
 
		if effectif = effectif_max then 
			exit actif;
		end if;

		effectif = effectif + 1;
		NB_jours_commun = 0;
		raise notice '///////////////////////////////////';		
	END LOOP;

	return;
 end
$$
LANGUAGE plpgsql SET search_path TO test security DEFINER;

-- PARTITION BY NB_jours_total

DROP FUNCTION IF EXISTS test.calcul_provisions_payees( integer, date );
CREATE OR REPLACE FUNCTION test.calcul_provisions_payees ( locataire_id integer, date_nouvelle_regul date DEFAULT now() )
RETURNS numeric AS
$$
 declare
  date_debut_calcul date;
  date_fin_calcul date;
  date_fin_bail date;
  m numeric;
 BEGIN
	 raise notice 'FONCTION : calcul charges provisionnées';
	 /* REPRISE 
	  * 
	  * On cherche les dates limites, les bornes de la période à calculer.... RECHERCHE DE BORNES
	  *  CAS :
	  * 	date_debut =
	  * 		régul absente  : date_debut_bail
	  * 		regul presente : date_dernière_regul
	  * 	date_fin =
	  * 		date_nouvelle_regul : si nouvelle régul et bail en cours
	  * 		date_fin_bail 		: si nouvelle régul et bail terminé 
	  * */
	 
	 -- date_debut_periode
	 date_fin_bail = date_fin_bail( locataire_id );
	
	 IF regularisation_est_presente( locataire_id ) THEN
	 	raise notice 'Régularisation présente : date debut = dernière date de regul';
	 
	 	IF date_fin_bail IS NULL THEN
	 		date_debut_calcul = lire_derniere_date_regul( locataire_id ) + 1;
	 	ELSE	 	
	 		IF date_nouvelle_regul >= date_fin_bail THEN  
	 			date_debut_calcul = date_fin_bail;
	 		ELSE
	 			date_debut_calcul = lire_derniere_date_regul( locataire_id ) + 1;
	 		END IF;
	 	END IF;
	 ELSE
	 	raise notice 'Régularisation absente : date debut = date début de bail du (co)locataire';
	 	date_debut_calcul = ( select lower( periode_occupation ) from locataire where id = locataire_id );
	 END IF;
	
	select upper( periode_occupation ) INTO date_fin_bail from locataire where id = locataire_id;
	
	-- date_fin_periode
	IF date_fin_bail IS NULL THEN
		raise notice 'Bail en cours : date fin = date nouvelle regul ( default to now() )';
		date_fin_calcul = date_nouvelle_regul;
 	ELSE
 		raise notice 'Bail terminé : ';
/*
 		IF date_nouvelle_regul >= date_fin_bail THEN
	 		raise notice '\t date de régul demandée postérieure à la date de fin du bail : date fin = date fin de bail';
  			date_fin_calcul = date_fin_bail;
  		ELSE
  			date_fin_calcul = date_nouvelle_regul;
	 	END IF;
*/
		date_fin_calcul = date_fin_bail;
	 END IF;
     	
 	raise notice 'date debut calcul : %, date fin calcul : %', date_debut_calcul, date_fin_calcul;
 
	select provision_charge_mensuelle * ( extract( years from age (date_fin_calcul, date_debut_calcul ) ) * 12 )
	    +
    ( provision_charge_mensuelle * extract( month from age ( date_fin_calcul, date_debut_calcul ) ) )
    	+
    ( ( provision_charge_mensuelle / 30.5 ) * extract( day from age( date_fin_calcul, date_debut_calcul ) ) ) 
		into m
	from locataire  
	where id = locataire_id;
       
   return m;
 end
$$
LANGUAGE plpgsql SET search_path TO test security DEFINER;


/*
 * l'algo choisi présuppose qu'il n'y a pas d'impayé. Donc, pour tout mois écoulé, une quittance est fournissable.
 * Ce qui est simpliste / Utilisation du Rasoir D'Ockham.
 * 
 * TODO : Prorata et debut de bail le 01 du mois ... 
 */
DROP FUNCTION IF EXISTS test.quittance_generer( integer ) CASCADE;
CREATE OR REPLACE FUNCTION test.quittance_generer( locataire_id integer )
RETURNS void AS
$$
 declare
	date_debut_bail date; 
	date_fin_bail date;
  	date_derniere_quittance date;
	date_debut_premiere_quittance date;
	date_fin_premiere_quittance date;
	date_debut_quittance date;
	date_fin_quittance date;
  	date_debut_generation_quittances date;
	date_fin_generation_quittances  date;
	mois_quittance_en_cours date;	
	annee int;
	mois int;
	nb_jours_mois int;
	prorata_nb_jours int;
	dernier_jour_du_mois int;
	date_debut_mois date; 
	date_emission_quittance date = current_date;
	date_paiement_quittance date;
	loyer_hc numeric( 10, 2 );
	prorata_loyer_hc numeric( 10, 2 );
	loyer_hc_jour numeric( 10, 2 );
	provision_charges numeric( 10, 2 );
	prorata_provision_charges numeric( 10, 2 );
	prorata_loyer_total numeric( 10, 2 );
	montant_total numeric( 10, 2 );
	montant_total_lettre text = '';
	adresse_bailleur text;
	bailleur_denomination text;
	adresse_locataire text;
	locataire_denomination text;
	locataire_nom_prenom text;
	lieux_quittance text;
	quittance_tpl text;
	quittance_fmt text;
	quittance_periode text;
	quittance_nom_fichier text;
 BEGIN
	raise notice 'FONCTION : quittance_generer';
	
	if not locataire_existe( locataire_id ) then
		raise notice 'Aucun locataire trouvé avec l''id : %.', locataire_id;
		return;
	end if;

	date_derniere_quittance = ( select concat( periode_couverte, '-01' )::date from quittance where fk_locataire = locataire_id order by id desc limit 1 );
	
	-- DATA INIT
	select loyer_mensuel_hc, provision_charge_mensuelle, loyer_total, 
		concat( denomination, ' ', nom, ' ', prenom ),
		concat( '_', nom, '_', prenom, '_'), 
		adresse
		into loyer_hc, provision_charges, montant_total, locataire_denomination, locataire_nom_prenom, adresse_locataire
	from locataire l
	inner join actif a on l.fk_actif = a.id 
	where l.id = locataire_id;
	

	select 	config -> 'bailleur_adresse',
			config -> 'bailleur_denomination_sociale',
			config -> 'quittance_lieux',
			config -> 'quittance_tpl'
			into adresse_bailleur, bailleur_denomination, lieux_quittance, quittance_tpl
			from locataire l 
			inner join actif a on l.fk_actif = a.id 
		inner join bien b on a.fk_bien = b.id 
		where l.id = locataire_id;  
	-- END DATA INIT
 
	-- si le locataire existe, on peut à minima, générer la première quittance
	if date_derniere_quittance is null then
		raise notice 'Aucune quittance trouvée.';
		raise notice 'Génération des quittances depuis le début du bail ...';

		quittance_fmt = quittance_tpl;

		date_debut_bail = ( select lower( periode_occupation ) from locataire where id = locataire_id );
		-- generer premiere quittance
		date_debut_premiere_quittance = date_debut_bail; 
		quittance_periode = TO_CHAR( date_debut_bail, 'YYYY-MM');

		nb_jours_mois = lire_dernier_jour_du_mois( date_debut_bail );
		date_fin_premiere_quittance = ( select extract( year from date_debut_bail ) || '-' || extract( month from date_debut_bail ) || '-' || nb_jours_mois );
	
		-- si entrée le premier jour, mois complet. Pas de prorata.
		if ( extract( day from date_debut_bail ) = '01' ) then
			prorata_loyer_hc = loyer_hc;
			prorata_provision_charges = provision_charges;
			prorata_loyer_total = montant_total;
		else 
			-- calcul pro rata
			prorata_nb_jours = ( select calcul_nb_jours_prorata( date_fin_premiere_quittance, date_debut_bail ) );

			prorata_loyer_hc = ( loyer_hc / nb_jours_mois ) * prorata_nb_jours;
			prorata_provision_charges = ( provision_charges / nb_jours_mois ) * prorata_nb_jours;
			prorata_loyer_total = ( montant_total / nb_jours_mois ) * prorata_nb_jours;
		end if;
 
		raise notice 'Première Quittance >> Début : %, Fin : %.', date_debut_bail, date_fin_premiere_quittance; 

		montant_total_lettre = ( select concat( num_to_words_lang( prorata_loyer_total, 'fr' ), ' euros' ) );
		date_paiement_quittance = date_debut_bail;
		date_debut_generation_quittances = date_debut_bail;
		quittance_nom_fichier = 'quittance_loc_id_' || locataire_id || locataire_nom_prenom ||quittance_periode || '.pdf';
	
		quittance_fmt = ( select quittance_remplir( 
					quittance_fmt, bailleur_denomination, adresse_bailleur, locataire_denomination, adresse_locataire, 
					date_debut_premiere_quittance::text, date_fin_premiere_quittance::text,	date_paiement_quittance::text, date_emission_quittance::text, lieux_quittance, 
					prorata_loyer_hc::text, prorata_provision_charges::text, prorata_loyer_total::text, montant_total_lettre, quittance_periode ) );

		raise notice 'Quittance TPL >> %.', quittance_fmt;

		insert into quittance ( fk_locataire, ts_date_emission, periode_couverte, contenu, nom_fichier ) values 
		( locataire_id, date_emission_quittance, quittance_periode, quittance_fmt, quittance_nom_fichier );
	
		raise notice 'Première Quittance TEXT >>  %', quittance_fmt;

	-- quittance trouvée
	else
		raise notice 'Dernière Quittance en date >>  %', date_derniere_quittance;

		if ( current_date > date_derniere_quittance and TO_CHAR( date_derniere_quittance, 'YYYY-MM') >= TO_CHAR( current_date, 'YYYY-MM') ) then   
			raise notice 'Pas de nouvelle Quittance à générer >> date dernière quittance : %, date d''appel : %.', date_derniere_quittance, current_date;
			return;
		else
			date_debut_generation_quittances = date_derniere_quittance; 
		end if;
	end if;

	-- OK : on démarre après :
		--  soit le mois de début du bail si aucune quittance n'existe au moment t
		-- soit le mois suivant la dernière date de quittance trouvée
	if ( current_date > date_debut_generation_quittances and TO_CHAR( date_debut_generation_quittances, 'YYYY-MM') > TO_CHAR( current_date, 'YYYY-MM') ) then   
		raise notice 'Pas de nouvelle Quittance à générer >> date dernière quittance : %, date d''appel : %.', date_derniere_quittance, current_date;
		return;
	end if;

	--	sortie / terminaison spécifique si fin de bil connu ou pas.
	-- si absent, s'arrete t-on au mois en cours ? ( dépens si payé ou non )  

	mois_quittance_en_cours = date_debut_generation_quittances + interval '1 month';

	-- la fin de bail sert uniquement pour le calcul du prorata final
	date_fin_bail = ( select date_fin_bail ( locataire_id ));
	if date_fin_bail is not null then
		raise notice 'Date fin de bail trouvée : %.', date_fin_bail;

		if ( TO_CHAR( date_fin_bail, 'YYYY-MM') = TO_CHAR( date_derniere_quittance, 'YYYY-MM') ) then   
			raise notice 'Bail Achevé. Toutes Quittance Générées. ';
			return;
		end if;

		date_fin_generation_quittances = date_fin_bail;
	else
		date_fin_generation_quittances = current_date;
	end if;


	<<generation_quittances>>
	loop
			-- init variable indépendantes de la boucle
			annee = ( select extract( year from mois_quittance_en_cours ));
			mois = ( select extract( month from mois_quittance_en_cours ));

			nb_jours_mois = lire_dernier_jour_du_mois( mois_quittance_en_cours );
			dernier_jour_du_mois = nb_jours_mois;

			date_debut_quittance = ( select date( concat( annee, '-', mois, '-01' ) ) );
			quittance_fmt = quittance_tpl;

			quittance_periode =  TO_CHAR( mois_quittance_en_cours, 'YYYY-MM');

			-- on teste si on arrive sur la fin de bail
			-- dernière quittance
			raise notice 'Quittance : Traitement >> Mois en cours  : %, Fin Période : %.', mois_quittance_en_cours, date_fin_bail ; 
			if TO_CHAR( mois_quittance_en_cours, 'YYYY-MM') = TO_CHAR( date_fin_bail, 'YYYY-MM') then
				raise notice 'Quittance : Traitement >> Fin de bail. Génération de la dernière quittance.';
	
				date_debut_mois = ( select date( concat( annee, '-', mois, '-01' ) ) ); -- forcée au 1er jour pour couvrir tous les jours possibles de fin de bail.
				date_paiement_quittance = date_debut_mois; 
				date_fin_quittance = date_fin_bail;

				-- calcul pro rata
				-- si départ le dernier jour, mois complet. Pas de prorata.
				if ( extract( day from date_debut_bail ) = dernier_jour_du_mois ) then
					prorata_loyer_hc = loyer_hc;
					prorata_provision_charges = provision_charges;
					prorata_loyer_total = montant_total;
				else 
					prorata_nb_jours = ( select calcul_nb_jours_prorata( date_fin_bail, date_debut_mois ) );

					prorata_loyer_hc = ( loyer_hc / nb_jours_mois ) * prorata_nb_jours;
					prorata_provision_charges = ( provision_charges / nb_jours_mois ) * prorata_nb_jours;
					prorata_loyer_total = ( montant_total / nb_jours_mois ) * prorata_nb_jours;
				end if;
		
				montant_total_lettre = ( select concat( num_to_words_lang( prorata_loyer_total, 'fr' ), ' euros' ) );
		
				quittance_fmt = ( select quittance_remplir( quittance_fmt, bailleur_denomination, adresse_bailleur, locataire_denomination, adresse_locataire, 
					date_debut_quittance::text, date_fin_quittance::text,	date_paiement_quittance::text, date_emission_quittance::text, lieux_quittance, 
					prorata_loyer_hc::text, prorata_provision_charges::text, prorata_loyer_total::text, montant_total_lettre, quittance_periode ) );
				
			-- mois plein
			else

				date_paiement_quittance = ( select date( concat( annee, '-', mois, '-', FLOOR(RANDOM() * 10 + 1)::int ) ) );
				date_fin_quittance = ( select date( concat( annee, '-', mois, '-', dernier_jour_du_mois ) ) );
				montant_total_lettre = ( select concat( num_to_words_lang( montant_total, 'fr' ), ' euros' ) );

				quittance_fmt = ( select quittance_remplir( quittance_fmt, bailleur_denomination, adresse_bailleur, locataire_denomination, adresse_locataire, 
					date_debut_quittance::text, date_fin_quittance::text, date_paiement_quittance::text, date_emission_quittance::text, lieux_quittance, 
					loyer_hc::text, provision_charges::text, montant_total::text, montant_total_lettre, quittance_periode ) );
				
			end if;
			
			-- WRITE
			quittance_nom_fichier = 'quittance_loc_id_' || locataire_id || locataire_nom_prenom ||quittance_periode || '.pdf';

			insert into quittance ( fk_locataire, ts_date_emission, periode_couverte, contenu, nom_fichier) values 
			( locataire_id, date_emission_quittance, quittance_periode, quittance_fmt, quittance_nom_fichier );
  
		raise notice 'Quittance >> Début période : %, Fin Période : %.', date_debut_quittance , date_fin_quittance ; 
		raise notice 'Quittance >> Date Paiement : %.', date_paiement_quittance; 
		raise notice 'Quittance Periode >> %.', quittance_periode; 
		raise notice 'Quittance >> Loyer HC : %, provision charges : %, Loyer Total : %.',  loyer_hc, provision_charges, montant_total;

		mois_quittance_en_cours = ( select mois_quittance_en_cours + interval '1 month' ); 

		if TO_CHAR( mois_quittance_en_cours, 'YYYY-MM')> TO_CHAR( date_fin_generation_quittances, 'YYYY-MM') then
			exit generation_quittances;
		end if;

	end loop;
 end
$$ LANGUAGE plpgsql SET search_path TO test,public security DEFINER;


DROP FUNCTION IF EXISTS test.quittance_statut_from_gum( ) CASCADE;
CREATE OR REPLACE FUNCTION test.quittance_statut_from_gum( )
RETURNS TABLE( statut TEXT ) AS
$$
 	 WITH loc AS (
		select 
			l.id,
			nom, 
			prenom,
			count( q.id ) nb_quittance,
			max( q.periode_couverte )  derniere_quittance
		from test.locataire l
		LEFT OUTER JOIN test.quittance q
		ON q.fk_locataire = l.id
		GROUP BY l.id
		order by id
	) SELECT 
		concat( 
			'> ', l.nom, ' ', prenom, '. ',
			CASE WHEN nb_quittance = 0 THEN 
				'QUITTANCABLE ! Aucune Quittance trouvée'
			ELSE 
				CASE WHEN test.quittance_periode_arret( l.id ) = derniere_quittance THEN 
						concat( 'A jour. ', l.nb_quittance, ' Quittance(s)' )
					WHEN test.quittance_periode_arret( l.id ) > derniere_quittance THEN
						concat( 'QUITTANCABLE !. ', l.nb_quittance, ' Quittance(s). Dernière ( ', derniere_quittance, ' )' )
					ELSE
						'Functionnal Error. Improvable Business Rule  Design'
					END 
			END,
			' ',
			':', l.id
		)
	FROM loc l;
$$ LANGUAGE sql SET search_path TO test,public security DEFINER;
COMMENT ON FUNCTION test.quittance_statut_from_gum IS 'FUNCTION. Renvoi un statut simple des quittances par locataire. Formattage spécialisé pour GUM CHOOSE ';

\q
---------------------







TRUNCATE TABLE test.quittance RESTART IDENTITY;
SELECT test.quittance_generer( 1 );
SELECT test.quittance_statut_from_gum();

TABLE test.quittance;

DELETE FROM test.quittance WHERE id > 7 AND fk_locataire = 5;


 select test.date_fin_bail ( 10 );
