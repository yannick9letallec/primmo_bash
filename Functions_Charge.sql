/* FONCTIONS CHARGES */


DROP FUNCTION IF EXISTS test.charge_est_facturee_sur_annee ( integer, numeric );
CREATE OR REPLACE FUNCTION test.charge_est_facturee_sur_annee (  arg_type_charge integer, annee numeric )
RETURNS boolean AS
$$
 declare
   start_work_year date;
   end_work_year date;
   work_year_range daterange; 
   type_charge_existe boolean;
   est_couverture_ok boolean;
 begin
	raise notice 'FONCTION : charge_est_facturee_sur_annee : arg 1 : type_charge : %, arg 2 : % ', arg_type_charge, annee;

	type_charge_existe = ( select id::boolean from type_charge where id = arg_type_charge ); 
	raise notice '%', type_charge_existe;

	if type_charge_existe is null then
		raise exception 'Le type de charge demandé est inexistant.';  
	end if;

	start_work_year = date( annee || '-01-01' );
	end_work_year = date( annee || '-12-31' );

	work_year_range = daterange( start_work_year, end_work_year, '[]' );

	est_couverture_ok = ( select coalesce( range_agg( periode ) @> work_year_range, false )
	from test.charges 
	where 
		fk_type_charge = arg_type_charge
		and ( 
			annee = extract ( year from lower( periode ) )::numeric 
			OR 
			annee = extract ( year from upper( periode ) )::numeric 
			)
	);  
	return est_couverture_ok;
 end
$$
LANGUAGE plpgsql PARALLEL SAFE SET search_path TO 'test' SECURITY DEFINER;
-- SELECT test.charge_est_facturee_sur_annee ( 3, 2024 );


DROP FUNCTION IF EXISTS charges_sont_facturees_sur_annee( integer );
CREATE OR REPLACE FUNCTION test.charges_sont_facturees_sur_annee(  arg_type_charge integer = 999999 )
RETURNS table( annee int, type_charge int, label TEXT, est_completude_annuelle boolean, periode_annuelle daterange ) AS
$$
 declare
   work_year integer;
   start_work_year date;
   end_work_year date;
   work_year_range daterange; 
   actual_year integer;
   tc int;
   label text;
   est_couverture_ok boolean;
   type_charge_requis int [] := ARRAY[1,2,3];
 begin
    raise notice 'FONCTION : charges_sont_facturees_sur_annee: arg 1 : type_charge : % ( 999999 is default )', arg_type_charge;

	SELECT EXTRACT( YEAR FROM current_date ) into actual_year;
    select min ( extract ( year from ( lower( periode ) ) ) ) into work_year from test.charges;
	
	-- renvoyer un resultat du type ( ' annee ', ' type charge ', ' est_complet ' )
	<<year_loop>>
	LOOP
		-- en l'absence de type_charge fourni on boucle sur tous les types charges requis ...
		if arg_type_charge = 999999 then 
			raise notice 'Type Charge par défaut, boucle sur tous les types charges requis.%', type_charge_requis;
			<<type_charge_loop>>
			foreach tc in array type_charge_requis loop
				raise notice 'Année en cours : %', work_year;
				raise notice 'Type Charge en cours : %', tc;
	
				-- 1 - selection des eligible sur la periode
				-- 2 - vérification de l''adjacence des factures, on cherche à ce qu'il ne manque pas de factures sur la période
				-- 3 - recherche de la couverture annuelle
				start_work_year = date( work_year || '-01-01' );
				end_work_year = date( work_year || '-12-31' );
				work_year_range = daterange( start_work_year, end_work_year, '[)' );  
 
				with couverture_factures_annuelle as (
					select * from test.charges where fk_type_charge = 2 and 2024 = extract ( year from ( lower( periode ) ) )
						UNION
					select * from test.charges where fk_type_charge = 2 and 2024 = extract ( year from ( upper( periode ) ) )
					order by id
				) select range_agg( periode ) @> work_year_range into est_couverture_ok from couverture_factures_annuelle;
	
				raise notice 'EST COUVERTURE OK : %', est_couverture_ok ;
				annee = work_year;
				type_charge = tc;
				label = 'TMP LABEL';
				est_completude_annuelle = est_couverture_ok; 
				return next;
			end loop;
		else
			raise notice 'Type Charge fourni, on limite au type charge demandé : %', type_charge;
		end if;

		if work_year = actual_year then
			raise notice 'L''année de travail est égale à l''année en cours'; 
			exit;
		end if;

		work_year := work_year + 1;

	END LOOP;
   return;
 end
$$
LANGUAGE plpgsql PARALLEL SAFE SET search_path TO 'test' SECURITY DEFINER;
-- SELECT * FROM test.charges_sont_facturees_sur_annee ( 1 );


DROP FUNCTION IF EXISTS verifier_factures_sont_adjacentes;
CREATE OR REPLACE FUNCTION verifier_factures_sont_adjacentes()
RETURNS boolean AS
$$
 DECLARE
   
 BEGIN
     RAISE NOTICE 'FUNCTION : verifier_factures_sont_adjacentes WKS !';
RETURN TRUE;
END
$$
LANGUAGE plpgsql PARALLEL SAFE SET search_path TO 'test' SECURITY DEFINER;


-- SSI on a une date de fin de bail pour un locataire donné
-- VRAI, si à la date de fin de bail, toutes les factures sont présentes
-- FAUX sinon
-- TODO : lier les charges aux biens / actifs
DROP FUNCTION IF EXISTS charges_sont_cloturables;
CREATE OR REPLACE FUNCTION charges_sont_cloturables( id_locataire integer )
RETURNS boolean AS
$$
 declare
   tab_char TEXT := E'\t';
   cloturable boolean;
   est_cloture boolean;
   date_fin_bail date;
   type_charge_requis int [] := ARRAY[1,2,3];
   nb_type_charge_requis int = cardinality( type_charge_requis ); 
 begin
	 raise notice 'FONCTION : Charges sont cloturables';
  
	 est_cloture = ( SELECT est_charge_cloture FROM locataire AS c WHERE id = id_locataire );
	 if est_cloture then 
	 	raise notice '% Charges déjà cloturée pour le locataire id : %', tab_char,  id_locataire;
		return false;
	 end if;

    date_fin_bail = ( select upper( periode_occupation) from locataire where id = id_locataire );
   
  -- la date de fin de bail doit etre incluse dans au moins une période, pour tout type de factures ;
  if date_fin_bail is null then 
		raise notice '% Bail en cours pour le locataire : %', tab_char, id_locataire; 
		return false;
  else 
		raise notice '% Bail Terminé pour le locataire : %. Fin bail : %', tab_char, id_locataire, date_fin_bail; 
	if ( select exists( 
	      select 
			count(*) 
		  from charges 
	      where date_fin_bail::date <@ periode::daterange 
	      	and fk_type_charge IN ( select unnest( type_charge_requis ) )
			-- and fk_type_charge = ANY ( type_charge_requis )
	      	having count(*) = nb_type_charge_requis )
   ) then
 		raise notice '% Toutes les factures sont disponibles pour le locataire id : %', tab_char, id_locataire;
		return true;
    else
		raise notice '% Factures manquantes pour le locataire id : %', tab_char, id_locataire; 
		return false;
  	end if;
  end if;
    
 end
$$
LANGUAGE plpgsql SET search_path TO 'test' SECURITY DEFINER STABLE;


DROP FUNCTION IF EXISTS charges_sont_cloturees( int );
CREATE OR REPLACE FUNCTION charges_sont_cloturees( IN locataire_id integer )
RETURNS boolean AS
$$
 	select EST_CHARGE_CLOTURE from TEST.LOCATAIRE C where id = locataire_id;
$$
LANGUAGE sql VOLATILE SET search_path TO 'test' SECURITY DEFINER;


DROP FUNCTION IF EXISTS charge_point_de_situation;
CREATE OR REPLACE FUNCTION charge_point_de_situation( IN locataire_id integer default null, IN est_forcee boolean DEFAULT false, IN montant integer DEFAULT 0 )
RETURNS numeric as
$$
	DECLARE 	
	BEGIN 
		raise notice 'FONCTION : charge_point_de_situation';
		-- obtenir un apercu de la situation globale du delta entre l'encours de charges réelles et les charges provisionnées
		-- loop locataires
			-- calculer les provisions payées par chacun ( suivant les cas, regul ou pas ... fin de bail ou pas )
			-- etat réel des charges 
				-- par type récurrents
				-- par type exceptionnel
		-- pp : additionner les provisions payées
		-- cp : additionner les charges payées
		-- delta : cp - pp
	end
$$
LANGUAGE plpgsql SET search_path TO 'test' security DEFINER;


DROP FUNCTION IF EXISTS charges_sont_periodes_fusionnables ;
CREATE OR REPLACE FUNCTION charges_sont_periodes_fusionnables( type_facture integer )
RETURNS boolean AS
$$
 declare
   sont_adjacentes boolean = false;
   n integer;
 begin
  
	with p as (
		select unnest( range_agg( periode ) ) from charges group by fk_type_charge having FK_TYPE_CHARGE in ( type_facture )
	) select 
		case when count(*) = 1 then
			true
		else 
			false
		end case
		into sont_adjacentes 
		from p;

   return sont_adjacentes;
 end
$$
LANGUAGE plpgsql SET search_path TO 'test' SECURITY DEFINER;


/*
DROP FUNCTION IF EXISTS appel_de_charge( int, TEXT, int, boolean );
CREATE OR REPLACE FUNCTION appel_de_charge( IN locataire_id integer , IN type_regul text, IN montant integer DEFAULT 0, est_reelle boolean DEFAULT true )
RETURNS regularisation_out_type AS
$$
 declare
  regularisation_existe boolean;
  date_derniere_regularisation date;
  regularisation_est_cloturable boolean := true;
  date_debut_bail date;
  date_fin_bail date;
  date_regul date = now();
  montant_regul numeric := 0;
  cas_calcul_provision integer;
  provisions_payees numeric;
  est_cloture boolean;
  oResult regularisation_out_type;
 begin
	   raise notice 'FONCTION appel_de_charge. Type : %', type_regul;
	 -- EXCLUSIONS ...
	est_cloture = ( select EST_CHARGE_CLOTURE from TEST.COLOCATAIRE C where id = locataire_id );

	if est_cloture then
		raise exception 'END - LOCATAIRE : % : CHARGES DEJA CLOTUREES. ', locataire_id;
	end if;

	if not est_forcee and not regularisation_est_pertinente( locataire_id ) then
		oResult.msg =  'Pas de nouvelles charges à impacter au locataire : ' || locataire_id;
		oResult.value = null; 
		return oResult;
	end if;
   
  	regularisation_est_cloturable = charges_sont_cloturables( locataire_id );

 	raise notice 'Regularisation Est Cloturables : %', regularisation_est_cloturable;
 
  if regularisation_est_cloturable THEN 
	UPDATE locataire set est_charge_cloturable = regularisation_est_cloturable where id = locataire_id;
  end if;
 
  regularisation_existe := regularisation_est_presente( locataire_id );
    
  date_debut_bail = ( select lower ( periode_occupation ) from locataire where id = locataire_id );
  date_fin_bail = ( select upper ( periode_occupation ) from locataire where id = locataire_id ); 
  date_derniere_regularisation  = ( select max( ts_date_regularisation ) from regularisation where fk_locataire = locataire_id ); 
  
  provisions_payees = calcul_provisions_payees( locataire_id, date_regul );
  raise notice 'Provisions Payées : %', provisions_payees; 


   -- possible à tout moment du bail ( fin / cours de bail )
  if est_forcee then
	-- est_forcee_forfaitaire // dans ce cas pas de ligne_regularisation. On demande un forfait au locataire
		INSERT INTO regularisation ( fk_locataire, ts_date_regularisation, total_charges_provisionnees, est_forcee_forfaitaire, note ) 
		VALUES 
		( locataire_id, date_regul, provisions_payees, true, '' );
    -- crée la régul sans autre calcul.
    -- TODO : 2 types arbitraire et basée sur moyenne

    -- pas cloturable
    if date_fin_bail is not null then
    	raise notice 'CLOTURABLE- Forçage régularisation pour bail en cours : %', date_fin_bail;
		
      -- WORK Here ! -- montant not null ! -- insert into regularisation () values ();
    else
      	raise notice 'NON CLOTURABLE - Forçage régularisation pour bail en cours : %', date_fin_bail;
     	
    end if; 
   
   IF est_reelle THEN 
		INSERT INTO regularisation ( fk_locataire, ts_date_regularisation, total_charges_provisionnees, total_charges_reelles_individuelles, est_forcee, note ) 
		VALUES 
		( locataire_id, date_regul, provisions_payees, montant, true, '' );
	END IF;
	-- else insert into view ... estimates will always run run real data ( computed regularisation ) 

	oResult.msg = 'Nouvelle régularisation créee';
	oResult.msg = montant;
	return oResult;
  end if;
 
 
	-- pas de sortie anticipée, cas d'anulation fonctionnelle purgés ... on peut créer la régul
	-- crea REGUL
	-- on crée la régularisation temporaire / manque : total_charges_reelles / total_global_ind

	-- core_charge = fonction en tronc commun avec est_pertinente
  	-- PERFORM core_charges( locataire_id, 'calcul', TRUE, provision_paye  );

 	-- TODO : recherche de type de charges exceptionnelles
 
  if regularisation_est_cloturable then
	UPDATE locataire set est_charge_cloture = true where id = locataire_id;
  end IF;
 
 	-- SELECT value INTO id_regul FROM kv_table WHERE  
  montant_regul = ( select credit_bailleur_sur_provision from regularisation where FK_COLOCATAIRE = locataire_id ORDER BY id DESC LIMIT 1 ); 

  raise notice 'A REGLER : %', montant_regul;
  
  oResult.msg = 'Nouvelle régularisation créee';
  oResult.value = montant_regul;
  return oResult;
end
$$
LANGUAGE plpgsql VOLATILE SET search_path TO 'test' SECURITY DEFINER;
*/
