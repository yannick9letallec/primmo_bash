SET search_path TO test, public;

TRUNCATE bien RESTART identity cascade;
TRUNCATE actif RESTART identity cascade;
TRUNCATE locataire RESTART identity cascade;
TRUNCATE charges RESTART identity cascade;
TRUNCATE REGULARISATION RESTART identity CASCADE ;
TRUNCATE LIGNE_REGULARISATION RESTART identity cascade;
-- TRUNCATE regularisation_statut RESTART identity CASCADE ;
-- TRUNCATE ligne_regularisation_type RESTART identity CASCADE ;


\set quittance_tpl `cat ./quittance.md`
\set quittance_email_tpl `cat ./quittance_email.md`


-- BIEN
INSERT INTO bien ( label, surface_totale, mise_en_service, teom, config, note ) VALUES 
( 'Montlouis Maison', 200, '01-12-2023', 911, hstore( 
	ARRAY[ ['charges_obligatoires', '1,2,3'], 
			[ 'propriete_adresse', '30 rue du Maréchal Foch, N°7, 37 270 Montlouis sur Loire' ],
			[ 'bailleur_adresse', '30 rue du Maréchal Foch, Studio 5, 37 270 Montlouis sur Loire'], 
			[ 'bailleur_denomination_sociale', 'Mr Yannick Le Tallec' ],
			[ 'quittance_lieux', 'Montlouis sur Loire' ],
			[ 'quittance_tpl', :'quittance_tpl' ],
			[ 'quittance_email_tpl', :'quittance_email_tpl' ]
		] ), 
'Colocation de 7 chambres' ),
( 'Montlouis Atelier', 180, '01-07-2022', NULL, hstore( 
	ARRAY[ [ 'propriete_adresse', '30 rue du Maréchal Foch, 37 270 Montlouis sur Loire' ],
			[ 'bailleur_adresse', '30 rue du Maréchal Foch, Studio 5, 37 270 Montlouis sur Loire'],
			[ 'bailleur_denomination_sociale', 'Mr Yannick Le Tallec' ],
			[ 'quittance_lieux', 'Montlouis sur Loire' ],
			[ 'quittance_tpl', :'quittance_tpl' ]
		] ),
'Ensemble de 6 studios découpés dans ancien atelier' ),
( 'Saint Gaultier', 180, '01-07-2022', NULL, hstore( 
	ARRAY[ [ 'propriete_adresse', '38 rue Grande, 36 800 Saint Gaultier' ],
			[ 'bailleur_adresse', '30 rue du Maréchal Foch, Studio 5, 37 270 Montlouis sur Loire'],
			[ 'bailleur_denomination_sociale', 'Mr Yannick Le Tallec' ],
			[ 'quittance_lieux', 'Saint Gaultier' ],
			[ 'quittance_tpl', :'quittance_tpl' ]
		] ),
'Ensemble de logements ( 2 garages, 6 apartements, 2 commerces et réserve de croissance en comble de 125m2 environs.' );


-- ACTIF
/*
 * 
 INSERT INTO test.actif ( id, label, fk_bien, surface, note ) VALUES 
( 1, 'Chambre 1', 1, 20, 'La plus grande ( + confort, - prix ( non bloquant )). Au RDC ( facile d''accès ), proche porte entrée. Atout charme ( sol travertin, grande cheminée ornementale, mobilier qualitatif. Nég : prix, proche PE. ',
( 2, 'Chambre 2', 1, 16, 'Taille moyenne. 1er Et. Accès partagée avec 3 chambres. Charme : sol parquet rustique. Jolie Cheminée. Murs finition vynile. Nég : sous escalier.',
( 3, 'Chambre 3', 1, 14, 'Taille moyenne. 1er Et. Accès partagée avec 3 chambres. Charme : sol parquet rustique. Niche avec bureau intégré. Vue jardin. Nég : Collée SDB + cloison ch4',
( 4, 'Chambre 4', 1, 14, 'Taille moyenne. 1er Et. Accès partagée avec 3 chambres. Charme : sol parquet rustique. Sous bassement mûr en pierre. Vue jardin. Nég : cloison ch3'),
( 5, 'Chambre 5', 1, 10, 'La plus petite. 2nd Et. Accès partagée avec 3 chambres. Charme : sous rampant. Grand rangement. Idéal petit budget / étudiant ( calme, prix ) / pied à terre. Nég : ?' ),
( 6, 'Chambre 6', 1, 18, 'Taille moyenne. 2nd Et. Accès partagée avec 3 chambres. Charme : sous rampant partiel, volumes intéressant, rangement, belle vue dégagée en hauteur, Nég : ?'  ),
( 7, 'Chambre 7', 1, 19, '' );
*/
INSERT INTO actif ( label, fk_bien, surface, adresse, note ) VALUES 
( 'Chambre 1', 1, 20, '30 rue du Maréchal Foch, N°7, Chambre 1, 37 270 Montlouis sur Loire', 'La plus grande ( + confort, - prix ( non bloquant )). Au RDC ( facile d''accès ), proche porte entrée. Atout charme ( sol travertin, grande cheminée ornementale, mobilier qualitatif. Nég : prix, proche PE. ') ,
( 'Chambre 2', 1, 16, '30 rue du Maréchal Foch, N°7, Chambre 2, 37 270 Montlouis sur Loire', 'Taille moyenne. 1er Et. Accès partagée avec 3 chambres. Charme : sol parquet rustique. Jolie Cheminée. Murs finition vynile. Nég : sous escalier.' ),
( 'Chambre 3', 1, 14, '30 rue du Maréchal Foch, N°7, Chambre 3, 37 270 Montlouis sur Loire', 'Taille moyenne. 1er Et. Accès partagée avec 3 chambres. Charme : sol parquet rustique. Niche avec bureau intégré. Vue jardin. Nég : Collée SDB + cloison ch4' ),
( 'Chambre 4', 1, 14, '30 rue du Maréchal Foch, N°7, Chambre 4, 37 270 Montlouis sur Loire', 'Taille moyenne. 1er Et. Accès partagée avec 3 chambres. Charme : sol parquet rustique. Sous bassement mûr en pierre. Vue jardin. Nég : cloison ch3' ) ,
( 'Chambre 5', 1, 10, '30 rue du Maréchal Foch, N°7, Chambre 5, 37 270 Montlouis sur Loire', 'La plus petite. 2nd Et. Accès partagée avec 3 chambres. Charme : sous rampant. Grand rangement. Idéal petit budget / étudiant ( calme, prix ) / pied à terre. Nég : ?' ),
( 'Chambre 6', 1, 18, '30 rue du Maréchal Foch, N°7, Chambre 6, 37 270 Montlouis sur Loire', 'Taille moyenne. 2nd Et. Accès partagée avec 3 chambres. Charme : sous rampant partiel, volumes intéressant, rangement, belle vue dégagée en hauteur, Nég : ?'  ),
( 'Chambre 7', 1, 19, '30 rue du Maréchal Foch, N°7, Chambre 7, 37 270 Montlouis sur Loire', '' ),
( 'Studio 1', 2, 38, '30 rue du Maréchal Foch, Studio 1, 37 270 Montlouis sur Loire', '' ),
( 'Studio 2', 2, 30, '30 rue du Maréchal Foch, Studio 2, 37 270 Montlouis sur Loire', '' ),
( 'Studio 3', 2, 20, '30 rue du Maréchal Foch, Studio 3, 37 270 Montlouis sur Loire', '' ),
( 'Studio 4', 2, 20, '30 rue du Maréchal Foch, Studio 4, 37 270 Montlouis sur Loire', '' ),
( 'Studio 5', 2, 28, '30 rue du Maréchal Foch, Studio 5, 37 270 Montlouis sur Loire', '' ),
( 'Studio 6', 2, 22, '30 rue du Maréchal Foch, Studio 6, 37 270 Montlouis sur Loire', '' ),
( 'Appt 1', 3, 35, '38 rue Grande, Apt 1, 36 800 Saint Gaultier', 'T2 - 1er logement situé sous les combles, côté jardin. Combles ayant servies d''atelier' ),
( 'Appt 2', 3, 43, '38 rue Grande, Apt 2, 36 800 Saint Gaultier', 'T2 - Dans la tour, au premier palier.' ),
( 'Appt B', 3, 29, '38 rue Grande, Apt B, 36 800 Saint Gaultier', 'T1 - Ex projet Air B''n''B. Situé au dessus de l''ancienne bouquinerie' ),
( 'Appt 3', 3, 36, '38 rue Grande, Apt 3, 36 800 Saint Gaultier', 'DUPLEX. Dans la tour, au premier palier.' ),
( 'Appt 4', 3, 36, '38 rue Grande, Apt 4, 36 800 Saint Gaultier', 'Au RDC, dans le bâtiment côté jardin.' ),
( 'Appt 6', 3, 40, '38 rue Grande, Apt 6, 36 800 Saint Gaultier', 'T3 - 1er logement situé sous les combles, côté jardin. Combles ayant servies d''atelier' ),
( 'Commerce 1', 3, 36, '38 rue Grande, MMA, 36 800 Saint Gaultier', 'MMA ...' ),
( 'Commerce 2', 3, 30, '36 rue Grande 36 800 Saint Gaultier', 'Ex bouquinerie. Située au 36 rue Grande ...' ),
( 'Garage 1', 3, 20, 'rue du centre, Garage 1, 36 800 Saint Gaultier', '' ),
( 'Garage 2', 3, 20, 'rue du centre, Garage 2, 36 800 Saint Gaultier', '' );


-- COLOCATAIRES :: REAL DATA
	INSERT INTO locataire( denomination, prenom, nom, email, fk_actif, periode_occupation, loyer_mensuel_hc, montant_caution, provision_charge_mensuelle, est_entree_directe, note ) VALUES 
( 'Melle', 'Lorada', 'Pichon', 'lorada1pichon@gmail.com', 2, '[2023-12-12,2024-02-24]'::daterange, 340, 680, 30, FALSE, ''),
( 'Mr', 'Billy', 'Banc', 'darksopra@gmail.com', 1, '[2023-12-11, 2024-03-31]', 450, 900, 30, TRUE, ''),
( 'Mr', 'Florentin', 'Hucault', 'florentinhucault95@gmail.com',  4, '[2024-02-03, 2024-06-06]', 340, 680, 50, TRUE, ''),
( 'Mr', 'Gaetan', 'Abessolo', 'gaetan.abessolo@wabtec.com', 3, '[2024-02-03, 2024-08-26]', 330, 660, 30, FALSE, ''),
( 'Mr', 'Vincent', 'Marida', 'vincentmaridat9@gmail.com', 2, '[2024-04-06,]'::daterange, 340, 680, 50, TRUE, ''),
( 'Mr', 'Denis', 'Rognat', 'rognatdenis@gmail.com', 6, '[2024-05-01,]', 300, 600, 50, FALSE, ''),
( 'Mr', 'Remi', 'Nallet', 'r.nallet8@gmail.com', 4, '[2024-10-07,2025-03-13]'::daterange, 340, 680, 50, FALSE, ''),
( 'Mr', 'Brice', 'Rostal', 'brice.rosta@yahoo.fr', 5, '[2024-10-26,2025-02-10]'::daterange, 280, 560, 50, FALSE, ''),
( 'Mr', 'Bernardo', 'Perrini', 'parrinibernardo@gmail.com', 3, '[2024-11-01,2025-03-08]'::daterange, 340, 680, 50, FALSE, ''),
( 'Melle', 'Lucie', 'Beya', 'luciebeya.athenza@gmail.com', 1, '[2025-02-01,]'::daterange, 400, 800, 50, TRUE, ''),
( 'Mr', 'Chris', 'Boulou', 'wilmailkrisboulou@gmail.com', 5, '[2025-02-14,]'::daterange, 280, 560, 50, FALSE, ''),
( 'Melle', 'Noémie', 'Bourdeau-Venault', 'noemiebourdeau.v@gmail.com', 4, '[2025-06-01,]'::daterange, 340, 680, 50, FALSE, '');
-- DML : SITUATION LOCATIVE A DATE
	-- selectionner les chambres libres
	-- selectionner les chambres louées
-- DML : selectionner le revenu généré par un LOCATAIRE ( loyer mensuel / total, prov. charges mensuelles / totales )
-- DML : selectionner le revenu généré pour une CHAMBRE ( loyer mensuel / total, prov. charges mensuelles / totales )
-- DML calculer les revenus pour une période donnée


-- disable trigger all / bugs in neon cloud... triggers seems to be auto added to users table / security / performance issues ... ?
ALTER TABLE charges DISABLE TRIGGER ALL;


-- CHARGES :: REAL DATA
    -- EAU : pas / peu de variation saisonnière. Linéaire au nombre d''occupant. Fractionnable. Donc moyenne basée sur les factures est OK
INSERT INTO charges ( fk_type_charge, fk_bien, fk_locataire, date_emission, periode, montant, note, file_name ) VALUES 
( 1, 1, null, '2023-11-21', '[2022-10-04, 2023-08-22)', 98.30, 'réelle', NULL ),
( 1, 1, null, '2024-05-10', '[2023-08-22, 2024-09-16)', 527.80, 'estimative', NULL);
--( 1, 1, null, '2024-11-18', '[2023-08-22, 2024-09-16]', 427.08, 'réelle', NULL );
--( 1, 1,  1,null, '2024-05-10', '[2023-08-22, 2024-03-31)', 100.72, 'estimative', NULL );
   
    
   -- GAZ : pas / Saisonnalité forte. Linéaire au nombre d''occupant. Fractionnable. Donc moyenne basée sur les factures est OK.
   -- TODO : FIX SOME FILE UNLOADING. All seems ISO ( rights : 755 / size ~120 k < 4To / lo_compat_mode : ON, is it good ? /  ) But lasts files fails to load
INSERT INTO charges ( fk_type_charge, fk_bien, date_emission, periode, montant, file_name, note ) VALUES 
( 2, 1, '2023-12-15', '[2023-11-04, 2023-12-04)', 246.17, 'Energie - a4J3W000000mxaW.pdf', '' ),
( 2, 1, '2024-01-15', '[2023-12-04, 2024-01-04)', 395.72, 'Energie - a4J3W000000ndor.pdf', '' ),
( 2, 1, '2024-02-15', '[2024-01-04, 2024-02-04)', 532.75, 'Energie - a4J3W0000015CCJ.pdf', '' ),
( 2, 1, '2024-03-15', '[2024-02-04, 2024-03-04)', 373.25, 'Energie - a4J3W0000015w3z.pdf', '' ),
( 2, 1, '2024-04-15', '[2024-03-04, 2024-04-04)', 273.27, 'Energie - a4J3W0000016gLB.pdf', '' ),
( 2, 1, '2024-05-15', '[2024-04-04, 2024-05-04)', 197.25, 'Energie - a4J3W000000alry.pdf', '' ),
( 2, 1, '2024-06-15', '[2024-05-04, 2024-06-04)', 113.11, 'Energie - a4J3W000000bUh9.pdf', '' ),
( 2, 1, '2024-07-15', '[2024-06-04, 2024-07-04)', 65.65, 'Energie - a4JSm000000DfOo.pdf', '' ),
( 2, 1, '2024-08-15', '[2024-07-04, 2024-08-04)', 48.94, 'Energie - a4JSm000000PAig.pdf', '' ),
( 2, 1, '2024-09-15', '[2024-08-04, 2024-09-04)', 46.00, 'Energie - a4JSm000000c0H4.pdf', '' ),
( 2, 1, '2024-10-15', '[2024-09-04, 2024-10-04)', 83.49, 'Energie - a4JSm000000oku8.pdf', '' ),
( 2, 1, '2024-11-15', '[2024-10-04, 2024-11-04)', 196.94, 'Energie - a4JSm0000010dqT.pdf', '' ),
( 2, 1, '2024-12-15', '[2024-11-04, 2024-12-04)', 426.63, 'Energie - a4JSm000001ECyZ.pdf', '' ),
( 2, 1, '2025-01-15', '[2024-12-04, 2025-01-04)', 600.11, 'Energie - a4JSm000001UZpP.pdf', '' ),
( 2, 1, '2025-02-15', '[2025-01-04, 2025-02-04)', 731.59, 'Energie - a4JSm000001jNhi.pdf', '' ),
( 2, 1, '2025-03-15', '[2025-02-04, 2025-03-04)', 557.73, 'Energie - a4JSm000001wlr1.pdf', '' );

/*------------------------   	
   	( 2, '2025-02-15', '[2025-01-04, 2025-02-04)', 731.59, NULL, 'Energie - a4JSm000001jNhi.pdf' ),
   	( 2, '2025-03-15', '[2025-02-04, 2025-03-04)', 557.73, NULL, 'Energie - a4JSm000001wlr1.pdf' );
*/
   
-- ELEC
INSERT INTO charges ( fk_type_charge, fk_bien, date_emission, periode, montant, file_name  ) VALUES 
( 3, 1, '2023-12-07', '[2023-10-07, 2023-12-06)', 75.03, NULL ),
( 3, 1, '2024-02-07', '[2023-12-06, 2024-02-06)', 124.08, NULL ),
( 3, 1, '2024-04-07', '[2024-02-06, 2024-04-06)', 188.48, NULL ),
( 3, 1, '2024-06-07', '[2024-04-06, 2024-06-06)', 167.86, NULL ),
( 3, 1, '2024-08-07', '[2024-06-06, 2024-08-06)', 199.29, NULL ),
( 3, 1, '2024-10-07', '[2024-08-06, 2024-10-06)', 190.94, NULL ),
( 3, 1, '2024-12-08', '[2024-10-06, 2024-12-06)', 246.24, NULL ),
( 3, 1, '2025-02-10', '[2024-12-06, 2025-02-06)', 324.93, NULL );
   
   -- TEOM : pas de variation saisonnière. Indépendant du nombre d''occupant ( le plus d'occupants, le moins la charge ). Fractionnable. Donc moyenne basée sur les factures est OK.'
INSERT INTO charges ( fk_type_charge, fk_bien, date_emission, periode, montant, file_name  ) VALUES 
( 8888, 1, '2024-05-01', '[2023-01-01, 2023-12-31]', 1000, NULL ),
( 8888, 1, '2025-05-01', '[2024-01-01, 2024-12-31]', 1000, NULL ),
( 8888, 1, '2026-05-01', '[2025-01-01, 2025-12-31]', 1000, NULL );
    
-- EXCEPTION / SPECIFIC LOCATAIRE. Aucune saisonnalité. Décorrélée du nombre d''occupant. Non Fractionnable. A considérer telle quelle.'
INSERT INTO charges ( fk_type_charge, fk_bien, fk_locataire, date_emission, montant, file_name, note  ) VALUES
( 9999, 1, 1, '2024-03-05', 200, NULL, 'Parquet : reprises rayures' ),
( 9999, 1, 7, '2025-03-10', 246, NULL, 'LRF : Ménage : couverture poussières / particules sur les murs et plafond. Parquet rayé' );


    
ALTER TABLE charges ENABLE TRIGGER ALL;



-- REGULARISATIONS
-- \copy test.regularisation from '/home/yannickletallec/Documents/IMMO-APP/CODE/SQL/CHARGES/Scripts/TEST/Files/LIVE_DATA/regularisation_montlouis.csv' delimiter ';';
-- \copy test.ligne_regularisation from '/home/yannickletallec/Documents/IMMO-APP/CODE/SQL/CHARGES/Scripts/TEST/Files/LIVE_DATA/ligne_regularisation_montlouis.csv' delimiter ';';    


RESET search_path;


\q

TABLE test.bien;
TABLE test.actif;
TABLE test.type_charge;
TABLE test.charges;
TABLE test.locataire;
TABLE test.regularisation;
TABLE test.ligne_regularisation;
TABLE test.ligne_regularisation_type;



TRUNCATE test.bien cascade;
TRUNCATE test.actif cascade;
TRUNCATE test.locataire cascade;
TRUNCATE test.charges RESTART identity CASCADE;
TRUNCATE TEST.REGULARISATION   CASCADE;
TRUNCATE TEST.LIGNE_REGULARISATION RESTART identity cascade;

-----------------------------------------------------------
-----------------------------------------------------------
HIERARCHICAL MODEL

charge 
	id
	fk_type_charge
	ts_date_emission
	montant
	
charge_fractionnable
	periode
	
charge_non_fractionnable
	fk_locataire
