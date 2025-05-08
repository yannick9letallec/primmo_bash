SET search_path TO test, public;

select * FROM test.appel_de_charge( 9, est_reelle => false );
select * FROM test.appel_de_charge_reel( 9 );
SELECT test.regularisation_est_presente( 7 );
SELECT test.regularisation_est_pertinente( 7 );


truncate test.regularisation cascade;
truncate test.ligne_regularisation cascade;
truncate test.charges RESTART IDENTITY CASCADE ;
truncate test.locataire cascade;

table test.locataire;
table test.charges;
table test.type_charge;
table test.regularisation;
table test.regularisation_statut;
table test.ligne_regularisation;
table test.ligne_regularisation_type;

DELETE FROM test.regularisation WHERE id=27;
update test.locataire SET est_charge_cloturable = FALSE, est_charge_cloture = FALSE WHERE id = 1 ;

select regularisation_est_presente( 1 );
select calcul_provisions_payees( 6 );
select charges_sont_cloturables( 1 );
select lire_derniere_date_regul( 2 );
select date_fin_bail ( 2 );
select nb_locataires_present( '2024-05-25' );
select appel_de_charge( 1, true, 1200 );
select appel_de_charge( 5, true, 1200 );
select test.regularisation_est_pertinente( 7 );

select test.regularisation_creer_pour_locataire( 9 );


SELECT test.periodes_vacance();

SELECT * FROM test.periodes_vacance() p
INNER JOIN test.actif_nb_baux() n 
ON p.chambre_id = n.id_bien;

SELECT chambre_id, unnest( vacances ) FROM test.periodes_vacance() p;

SELECT 
	*,
	( NB_jours_commun::numeric( 10, 2 ) / NB_jours_total::numeric( 10, 2 ) )::NUMERIC( 10, 4 ) * 100 AS pourcentage_effectif
	--, ntile( 3 ) OVER ( PARTITION BY NB_jours_commun ORDER BY NB_jours_commun ASC ) AS "WF" // add a window function ?
from test.bilan_occupation( 7 ) AS ( NB_jours_total int, effectif int, NB_jours_commun int )
ORDER BY pourcentage_effectif DESC, effectif asc;

SELECT upper( periode ) FROM charges WHERE fk_type_charge = 1;


		SELECT ts_date_arret FROM ligne_regularisation AS lr 
		WHERE fk_regularisation = (
			SELECT max( id ) FROM regularisation WHERE fk_locataire = 5
		) AND fk_type_charge = 3;


select exists( select count(*) as c from regularisation where fk_locataire = 1 having count(*) > 0);

select ( sum( montant_total) - sum( montant_individuel ) ), sum( montant_total ) from ligne_regularisation where fk_regularisation = 56;

 select montant_journalier from charges where '2024-02-25'::date <@ periode::daterange and fk_type_charge = 1;


-- WIP RANGES
select '[2022-10-04,2023-08-22)'::daterange + '[2023-07-22,2024-05-01)'::daterange;
select '[2022-10-04,2023-08-22)'::daterange -|- '[2023-08-25,2024-05-01)'::daterange;
select '[2022-10-04,2023-08-22)'::daterange @> '[2022-10-22,2022-10-29)'::daterange;
select '[2022-10-04,2023-08-22)'::daterange && '[2023-08-20,2024-05-01)'::daterange;
select '[2022-10-04,2023-08-22)'::daterange << '[2023-07-22,2024-05-01)'::daterange;

select  '[2022-02-04,2022-02-16)'::daterange &< '[2022-02-08,2022-02-15)'::daterange;

and '[2022-02-05,2022-02-08)'::daterange -|- '[2022-02-08,2022-02-15)'::daterange

select '[2022-02-05,2022-02-08)'::daterange && '[2022-01-15,2022-02-15)'::daterange;
select '[2022-01-05,2022-01-15)'::daterange -|- '[2022-01-15,2022-02-15)'::daterange;
select not '[2022-02-05,2022-02-08)'::daterange -|- '[2022-01-15,2022-02-15)'::daterange;

select '2022-10-01'::date <@ '[2022-10-04,2023-04-22)'::daterange;


select daterange( min( lower( periode ) ), max( upper( periode ) ) ) from charges where EST_FRACTIONNABLE and lower( PERIODE ) < '2024-02-05'; -- [2024-07-04,2024-08-04)
--( cte from previous)
do
$$ 
	declare 
		p daterange;
		r text;
	begin
	
		select daterange(  min( lower( periode ) ), max( upper( periode ) ) ) into p from charges where EST_FRACTIONNABLE and lower( PERIODE ) < '2024-02-05';
		
		select extract( days from age( upper( p ), lower( p ) ) ) into r;
		raise notice '%', r; 
	end
	$$
LANGUAGE plpgsql;

select range_agg( periode) from TEST.CHARGES C group by FK_TYPE_CHARGE;   = 2 order by periode asc;

select f, count(*) from ( select fk_type_charge as f, unnest( range_agg( periode )) from TEST.CHARGES ) c group by fk_type_charge  ;	

select fk_type_charge as f, unnest( range_agg( periode )) from TEST.CHARGES c group by fk_type_charge;

select count(*) from ( select unnest( range_agg( '{[2024-01-01,2024-01-31],[2024-02-02,2024-02-15)}'::datemultirange ))) a;

select * from (;

with p as (
	select unnest( range_agg( periode ) ) from charges group by fk_type_charge having FK_TYPE_CHARGE in ( 2 )
) select count(*) from p;

select unnest( range_agg( periode ) ) from charges group by fk_type_charge having FK_TYPE_CHARGE in ( 1)

show all;
/*
 * -- TEST Function : calcul_provisions_payees';
-- TEST case 1 : should succeed ...
select calcul_provisions_payees( 2, 1 );
select calcul_provisions_payees( 2, 2 );
select calcul_provisions_payees( 2, 3 );
select calcul_provisions_payees( 2, 4 );

-- TEST case 1 : should fail ...
select calcul_provisions_payees( 8, 1 );

select calcul_provisions_payees( 3, 4 );

select lire_derniere_date_regul( 6 );
*/

SELECT * from regularisation AS r 
INNER JOIN ligne_regularisation AS lr ON r.id = lr.fk_regularisation 
WHERE r.fk_locataire = 5
ORDER BY r.id DESC;  /* non-recursive statement */

INSERT INTO charges ( fk_type_charge, date_emission, periode, montant ) VALUES
    ( 1, '2024-10-15', '[2024-09-30,2024-11-11)', 1225.87 );

select daterange( min( lower( periode ) ), max( upper( periode ) ) ) from charges where EST_FRACTIONNABLE;
SELECT '2025-01-01'::date > '2024-11-30'::date;
TABLE locataire;
TABLE charges;
TABLE regularisation;
TABLE ligne_regularisation;
select test.charges_sont_cloturables( 2 );
select test.regularisation_est_pertinente( 1 );
SELECT EXISTS ( SELECT id FROM locataire AS c WHERE id = 1 );
   

/*
 * LARGE OBJECT :
 * DELETES ALL
 *
 */
DO $$ 
DECLARE 
    lo_id OID;
BEGIN
    FOR lo_id IN (SELECT loid FROM pg_largeobject ) 
    LOOP
        PERFORM lo_unlink(lo_id);
    END LOOP;
END $$;


select lo_import( 'CHARGES/Scripts/TEST/Files/GAZ/1448084050842905154.jpg' );

@set montant=2001
@set type_charge=2
@set date_emission='2020-01-01'
@set periode_debut='2026-01-01'
@set periode_fin='2026-01-31'


INSERT INTO test.charges ( fk_type_charge, date_emission, periode, montant, note ) VALUES ( ${type_charge}, ${date_emission}, daterange( ${periode_debut}, ${periode_fin}, '[)' ), ${montant}, ${COMMENT} );


 '${periode_debut}'::date, '${periode_fin}'::date 
 
 
 SELECT 
	nom,
	prenom, 
	lower( periode_occupation ) AS "Début Bail",
	upper( periode_occupation ) AS "Fin Bail",
	montant_caution AS "Montant Caution",
	provision_charge_mensuelle AS "Provision Mensuelle",
	test.total_provisions_payees_a_date( id )::money AS "Total Provisions Payées",
	test.total_loyer_payes_hc_a_date( id )::money AS "Total Loyers Payés",
	test.verbose_duration_bail( id ) AS "Durée du Bail",
	est_charge_cloturable AS  "Charges Cloturables ?", 
	est_charge_cloture AS "Charges Cloturées ?"
FROM
	:env_for_charges.locataire
WHERE id = :id_locataire
ORDER BY lower( periode_occupation );
	

\qecho 'Bilan occupation de la colocation :'

EXPLAIN SELECT 
	*,
	( NB_jours_commun::numeric( 10, 2 ) / NB_jours_total::numeric( 10, 2 ) )::NUMERIC( 10, 2 ) * 100 AS pourcentage
from test.bilan_occupation( 1 ) AS ( NB_jours_total int, effectif int, NB_jours_commun int )
ORDER BY pourcentage DESC, effectif asc;
 
 
UPDATE test.locataire SET periode_occupation = daterange( lower( periode_occupation ), NULL, '[)' ) WHERE id = 10;
UPDATE test.locataire SET periode_occupation = daterange( lower( periode_occupation ), '2025-05-01', '[)' ) WHERE id = 10;
UPDATE test.locataire SET periode_occupation = daterange( lower( periode_occupation ), '2025-04-01', '[)' ) WHERE id = 10;

SELECT nom, prenom, periode_occupation, note FROM test.locataire WHERE id = 10;
SELECT  '2025-04-01'::date > current_date; 


elect config -> 'bailleur_adresse' as ad                                                                                                                                                                                          │
                        from test.locataire l                                                                                                                                                                                               │
                        inner join test.actif a on l.fk_actif = a.id                                                                                                                                                                        │
                inner join test.bien b on a.fk_bien = b.id                                                                                                                                                                                  │
                where l.id = 10;                                                                                                                                                                                                            │

DO 
LANGUAGE plpgsql
$$
declare 
	a text;
	b text;
	c text;
begin
select config -> 'bailleur_adresse' as ad,
config -> 'quittance_lieux' as ql,
config -> 'bailleur_denomination_sociale' as db
into a, b, c
from test.locataire l
inner join test.actif a on l.fk_actif = a.id
inner join test.bien b on a.fk_bien = b.id
where l.id = 10;  

raise notice '%, %, %', a, b, c;
END $$;

DROP FUNCTION IF EXISTS test.a_virer(  ) CASCADE;
CREATE OR REPLACE FUNCTION test.a_virer( )
RETURNS void AS
$$
declare 
	a text;
	b text;
	c text;
begin
	select config -> 'bailleur_adresse' as ad,
	config -> 'quittance_lieux' as ql,
	config -> 'bailleur_denomination_sociale' as db
	into a, b, c
	from test.locataire l
	inner join test.actif a on l.fk_actif = a.id
	inner join test.bien b on a.fk_bien = b.id
	where l.id = 10;  
	
	raise notice '%, %, %', a, b, c;
END 
$$
LANGUAGE plpgsql PARALLEL SAFE SET search_path TO 'test' SECURITY DEFINER;
reset search_path;


CREATE OR REPLACE procedure test.a_virer( )
AS
$$
declare 
	a text;
	b text;
	c text;
begin
	select config -> 'bailleur_adresse' as ad,
	config -> 'quittance_lieux' as ql,
	config -> 'bailleur_denomination_sociale' as db
	into a, b, c
	from test.locataire l
	inner join test.actif a on l.fk_actif = a.id
	inner join test.bien b on a.fk_bien = b.id
	where l.id = 10;  
	
	raise notice '%, %, %', a, b, c;
END 
$$
LANGUAGE plpgsql;
reset search_path;
CALL test.a_virer();


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
	l.id,
	l.nom,
	CASE WHEN nb_quittance = 0 THEN 
		'QUITTANCABLE ! Aucune Quittance trouvée'
	ELSE 
		CASE WHEN test.quittance_periode_arret( l.id ) = derniere_quittance THEN 
				concat( 'A jour. ', 'NB Quittance(s) : ', nb_quittance )
			WHEN test.quittance_periode_arret( l.id ) > derniere_quittance THEN
				concat( 'QUITTANCABLE !. NB Quittance(s) : ', nb_quittance, '. Dernière en date : ', derniere_quittance )
			ELSE
				'Functionnal Error. Improvable Business Rule  Design'
			END 
	END AS Statut 
FROM loc l;

			
SELECT test.quittance_periode_arret( 1 )

SELECT to_char( '2025-04-01'::date, 'YYYY-MM' ) 

/*
 * update quittance template 
 * 
 */
UPDATE 
