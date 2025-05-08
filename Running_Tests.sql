SET search_path TO 'test';

CREATE OR REPLACE PROCEDURE test.unit_test_charges_sont_cloturables(  )
SET search_path TO 'test'
as $$
 declare
   r locataire%rowtype;
  est_cloturable boolean;
 begin
	raise notice 'unit_test_est_cloturables';
	
	truncate locataire, charges cascade;
	INSERT INTO locataire( id, prenom, nom, numero_chambre, periode_occupation, loyer_mensuel_hc, provision_charge_mensuelle, note ) VALUES 
	( 1, 'Lorada', 'Pichon', 2, '[2023-12-12, 2024-02-24]', 340, 30, ''),
	( 2, 'Billy', 'Banc', 1, '[2023-12-11, 2024-03-31]', 450, 30, ''),
	( 3,  'Florentin', 'Hucault', 4, '[2024-02-03, 2024-06-06]', 340, 50, ''),
	( 4, 'Gaetan', 'Abessolo', 3, '[2024-02-03, 2024-08-26]', 330, 30, ''),
	( 5, 'Vincent', 'Marida', 2, '[2024-04-06,]'::daterange, 340, 50, ''),
	( 6, 'Denis', 'Rognat', 6, '[2024-05-01, 2024-11-15]', 300, 50, ''),
	( 7, 'Remi', 'Nallet', 4, '[2024-10-07,]'::daterange, 340, 50, ''),
	( 8, 'Brice', 'Rostal', 5, '[2024-10-26,]'::daterange, 280, 50, ''),
	( 9, 'Bernardo', 'Perrini', 3, '[2024-11-01,]'::daterange, 340, 50, ''); 

	-- EAU
  	INSERT INTO charges ( fk_type_charge, date_emission, periode, montant ) VALUES 
    ( 1, '2023-11-21', '[2022-10-04, 2023-08-22)', 98.30 ),
    ( 1, '2024-05-10', '[2023-08-22, 2024-04-30]', 100.72 );
   	-- eau DU 2023-11-21 au 2024-03-31
    -- GAZ
    INSERT INTO charges ( fk_type_charge, date_emission, periode, montant ) VALUES 
    ( 2, '2023-12-15', '[2023-11-04, 2023-12-04)', 246.17 ),
    ( 2, '2024-01-15', '[2023-12-04, 2024-01-04)', 395.72 ),
    ( 2, '2024-02-15', '[2024-01-04, 2024-02-04)', 532.75 ),
    ( 2, '2024-03-15', '[2024-02-04, 2024-03-04)', 373.25 ),
    ( 2, '2024-04-15', '[2024-03-04, 2024-04-04)', 273.27 ),
    ( 2, '2024-05-15', '[2024-04-04, 2024-05-04)', 197.25 ),
    ( 2, '2024-06-15', '[2024-05-04, 2024-06-04)', 113.11 ),
    ( 2, '2024-07-15', '[2024-06-04, 2024-07-04)', 65.65 ),
    ( 2, '2024-08-15', '[2024-07-04, 2024-08-04)', 48.94 );
   -- ( 2, '2024-09-15', '[2024-08-04, 2024-09-04)', 46.00 );
   
 --   ( 2, '2024-10-15', '[2024-09-04, 2024-10-04)', 83.49 ),
 --  	( 2, '2024-11-15', '[2024-10-04, 2024-11-04)', 196.94 );
   -- gaz DU 2023-11-04 au 2024-05-04
    -- ELEC
    INSERT INTO charges ( fk_type_charge, date_emission, periode, montant ) VALUES 
    ( 3, '2023-12-07', '[2023-10-07, 2023-12-06)', 75.03 ),
    ( 3, '2024-02-07', '[2023-12-06, 2024-02-06)', 124.08 ),
    ( 3, '2024-04-07', '[2024-02-06, 2024-04-06)', 188.48 ),
    ( 3, '2024-06-07', '[2024-04-06, 2024-06-06)', 167.86 ),
    ( 3, '2024-08-07', '[2024-06-06, 2024-08-06)', 199.29 );
   
    --( 3, '2024-10-07', '[2024-08-06, 2024-10-06)', 190.94 );
   -- elec DU 2023-10-07 au 2024-02-06
	
	for r in  
   		select * from locataire
   	loop   	
	   	select charges_sont_cloturables( r.id ) into est_cloturable;
	   
		raise notice '% : % : CLOTURABLE -- %, %', r.id, est_cloturable, r.nom, r.prenom;
   	end loop;
   
  	ASSERT charges_sont_cloturables( 2 ) is true, 'KO - Billy Banc ( 2 ) cloturable. Toutes charges présentes.';
  	ASSERT charges_sont_cloturables( 3 ) is false, 'KO - Florentin Huchaud ( 3 ). Non cloturable ( manque facture eau.';
	--ASSERT test.charges_sont_cloturables( r.id ) is true, 'OK - Denis Rognat ( 2 ) .';
	
 end;
$$ LANGUAGE plpgsql SECURITY DEFINER;


CREATE OR REPLACE PROCEDURE test.unit_test_calcul_provisions_payees()
SET search_path TO 'test'
as $$
 declare
    r locataire%rowtype;
    est_cloturable boolean;
 begin
	raise notice 'unit_test_est_cloturables';
	
	truncate locataire, regularisation cascade;
	INSERT INTO locataire( id, prenom, nom, numero_chambre, periode_occupation, loyer_mensuel_hc, provision_charge_mensuelle, note ) VALUES 
	( 1, 'Lorada', 'Pichon', 2, '[2023-12-12, 2024-02-24]', 340, 30, ''),
	( 5, 'Vincent', 'Marida', 2, '[2024-04-06,]'::daterange, 340, 50, ''); 

	-- 1 : cloturable / sans regularisation
	ASSERT calcul_provisions_payees( 1 ) = 72.74::money, 'KO - Lorada Pichon ( 1 ). CAS 1'; 
	-- 2 : non cloturable / sans regularisation
	ASSERT calcul_provisions_payees( 5, '2024-07-31'::date ) = 191.00::money, 'KO - Vincent Marida ( 5 ). Cas  2.';
	-- creation de la regularisation pour le meme locataire
	INSERT INTO regularisation ( fk_locataire, ts_date_regularisation, total_charges_provisionnees, total_charges_reelles_individuelles, est_finale, est_forcee, note ) VALUES 
	( 5, '2024-07-31', 191.00, 99999999, false, false, '' );

	-- 3 : non cloturable / avec regularisation
	ASSERT calcul_provisions_payees( 5, '2024-10-21'::date ) = 132.80::money, 'KO -Vincent Marida ( 5 ). Cas  3';  
	INSERT INTO regularisation ( fk_locataire, ts_date_regularisation, total_charges_provisionnees, total_charges_reelles_individuelles, est_finale, est_forcee, note ) VALUES 
		( 5, '2024-10-21', 134.44, 99999999, false, false, '' );
	
	-- 4 : cloturable / avec regularisation
	update locataire set periode_occupation = '[2024-04-06,2024-12-12]' where id = 5;
	ASSERT calcul_provisions_payees( 5 ) = 81.16::money, 'KO -Vincent Marida ( 5 ). Cas  4'; 

end;
$$ LANGUAGE plpgsql SECURITY DEFINER;


CREATE OR REPLACE PROCEDURE test.unit_test_charges_sont_periodes_fusionnables(  )
SET search_path TO 'test'
as $$
 declare
 begin
	raise notice 'unit_test_sont_periodes_fusionnables // recherche de continuité dans les factures ( garantie l''absence de gap entre 2 facture. MAIS, sans excluer la possibilité de recouvrement entre 2 factures )';
	
	-- EAU
	truncate charges cascade;
  	INSERT INTO charges ( fk_type_charge, date_emission, periode, montant ) VALUES 
    ( 1, '2023-11-21', '[2022-10-04, 2023-08-22)', 98.30 ),
    ( 1, '2024-05-10', '[2023-08-22, 2024-04-30]', 100.72 );
  	ASSERT charges_sont_periodes_fusionnables( 1 )= true, 'KO - Les charges d''eau ( id 1 ) devraient être fusionnables';
	
	truncate charges cascade;
   	INSERT INTO charges ( fk_type_charge, date_emission, periode, montant ) VALUES 
    ( 1, '2023-11-21', '[2022-10-04, 2023-08-22)', 98.30 ),
    ( 1, '2024-05-10', '[2023-08-25, 2024-04-30]', 100.72 );
	ASSERT charges_sont_periodes_fusionnables( 1 ) = false, 'KO - Les charges d''eau ( id 1 ) devraient être non fusionnables.';
	  
    INSERT INTO charges ( fk_type_charge, date_emission, periode, montant ) VALUES 
    ( 2, '2023-12-15', '[2023-11-04, 2023-12-04)', 246.17 ),
    ( 2, '2024-01-15', '[2023-12-04, 2024-01-04)', 395.72 ),
    ( 2, '2024-02-15', '[2024-01-04, 2024-02-04)', 532.75 ),
    ( 2, '2024-03-15', '[2024-02-04, 2024-03-04)', 373.25 ),
    ( 2, '2024-04-15', '[2024-03-04, 2024-04-04)', 273.27 ),
    ( 2, '2024-05-15', '[2024-04-04, 2024-05-04)', 197.25 ),
    ( 2, '2024-06-15', '[2024-05-04, 2024-06-04)', 113.11 ),
    ( 2, '2024-07-15', '[2024-06-04, 2024-07-04)', 65.65 ),
    ( 2, '2024-08-15', '[2024-07-04, 2024-08-04)', 48.94 );
	ASSERT charges_sont_periodes_fusionnables( 2 ) = true, 'KO - Les charges d''elec ( id 2 ) devraient être fusionnables.';
	

	update charges set periode = daterange( '2024-05-15'::date, upper( periode ) ) where date_emission = '2024-06-15';
	ASSERT charges_sont_periodes_fusionnables( 2 ) = false, 'KO - Les charges d''elec ( id 2 ) devraient être non fusionnables.';
    	
	truncate charges cascade;
 end;
$$ LANGUAGE plpgsql SECURITY DEFINER;


drop PROCEDURE test.unit_test_regularisation_est_pertinente;
CREATE OR REPLACE PROCEDURE test.unit_test_regularisation_est_pertinente ()
SET search_path TO 'test'
as $$
 declare
    r locataire%rowtype;
    est_cloturable boolean;
   est_cloture boolean;
 begin
	raise notice 'unit_test_appel_de_charge';

	truncate locataire, charges, regularisation, ligne_regularisation  cascade;

	raise notice 'CAS 0 - bail terminé. pas de régularisation et pas de factures ... NON pertinent';
	INSERT INTO locataire( id, prenom, nom, numero_chambre, periode_occupation, loyer_mensuel_hc, provision_charge_mensuelle, note ) VALUES 
	( 1, 'Lorada', 'Pichon', 2, '[2023-12-12, 2024-02-24]', 340, 30, ''),
	( 4, 'Gaetan', 'Abessolo', 3, '[2024-02-03, 2024-08-26]', 330, 30, ''),
	( 5, 'Vincent', 'Marida', 2, '[2024-04-06,]'::daterange, 340, 50, ''),
	( 9, 'Bernardo', 'Perrini', 3, '[2024-11-01,]'::daterange, 340, 50, ''); 
	assert regularisation_est_pertinente( 1 ) = false, 'KO. La régularisation ne devrait pas être considérée comme pertinente. Pas de charges & absence de régularisation.';


	raise notice 'CAS 1 - bail terminé. pas de régularisation mais factures ... Pertinence OK';
	INSERT INTO charges ( fk_type_charge, date_emission, periode, montant ) VALUES 
    ( 1, '2023-11-21', '[2022-10-04, 2023-08-22)', 98.30 );
   INSERT INTO charges ( fk_type_charge, date_emission, periode, montant ) VALUES
    ( 1, '2024-05-10', '[2023-08-22, 2024-04-30]', 100.72 );
   
   INSERT INTO charges ( fk_type_charge, date_emission, periode, montant ) VALUES 
    ( 2, '2023-12-15', '[2023-11-04, 2023-12-04)', 246.17 );
   INSERT INTO charges ( fk_type_charge, date_emission, periode, montant ) VALUES
    ( 2, '2024-01-15', '[2023-12-04, 2024-01-04)', 395.72 );
   INSERT INTO charges ( fk_type_charge, date_emission, periode, montant ) VALUES
    ( 2, '2024-02-15', '[2024-01-04, 2024-02-04)', 532.75 );
   INSERT INTO charges ( fk_type_charge, date_emission, periode, montant ) VALUES
    ( 2, '2024-03-15', '[2024-02-04, 2024-03-04)', 373.25 );
   INSERT INTO charges ( fk_type_charge, date_emission, periode, montant ) VALUES
    ( 2, '2024-04-15', '[2024-03-04, 2024-04-04)', 273.27 );
   INSERT INTO charges ( fk_type_charge, date_emission, periode, montant ) VALUES
    ( 2, '2024-05-15', '[2024-04-04, 2024-05-04)', 197.25 );
   INSERT INTO charges ( fk_type_charge, date_emission, periode, montant ) VALUES
    ( 2, '2024-06-15', '[2024-05-04, 2024-06-04)', 113.11 );
   INSERT INTO charges ( fk_type_charge, date_emission, periode, montant ) VALUES
    ( 2, '2024-07-15', '[2024-06-04, 2024-07-04)', 65.65 );
   INSERT INTO charges ( fk_type_charge, date_emission, periode, montant ) VALUES
    ( 2, '2024-08-15', '[2024-07-04, 2024-08-04)', 48.94 );
   
    INSERT INTO charges ( fk_type_charge, date_emission, periode, montant ) VALUES 
    ( 3, '2023-12-07', '[2023-10-07, 2023-12-06)', 75.03 );
   INSERT INTO charges ( fk_type_charge, date_emission, periode, montant ) VALUES
    ( 3, '2024-02-07', '[2023-12-06, 2024-02-06)', 124.08 );
   INSERT INTO charges ( fk_type_charge, date_emission, periode, montant ) VALUES
    ( 3, '2024-04-07', '[2024-02-06, 2024-04-06)', 188.48 );
   INSERT INTO charges ( fk_type_charge, date_emission, periode, montant ) VALUES
    ( 3, '2024-06-07', '[2024-04-06, 2024-06-06)', 167.86 );
   INSERT INTO charges ( fk_type_charge, date_emission, periode, montant ) VALUES
    ( 3, '2024-08-07', '[2024-06-06, 2024-08-06)', 199.29 );
   assert regularisation_est_pertinente( 1 ) = true, 'KO. La régularisation devrait être considérée comme pertinente. Absence de régularisation, mais présence de charges.';
  
  
 	raise notice 'CAS 2 - bail en cours. pas de régularisation, pas de factures ... Pertinence KO';
 	truncate table TEST.CHARGES cascade;
    assert regularisation_est_pertinente( 9 ) = false, 'KO. La régularisation devrait être considérée comme non pertinente. Absence de régularisation, et absence de charges.';
   
   
	INSERT INTO charges ( fk_type_charge, date_emission, periode, montant ) VALUES 
    ( 1, '2023-11-21', '[2022-10-04, 2023-08-22)', 98.30 );
   INSERT INTO charges ( fk_type_charge, date_emission, periode, montant ) VALUES
    ( 1, '2024-05-10', '[2023-08-22, 2024-04-30]', 100.72 );
   
       INSERT INTO charges ( fk_type_charge, date_emission, periode, montant ) VALUES 
    ( 2, '2023-12-15', '[2023-11-04, 2023-12-04)', 246.17 );
   INSERT INTO charges ( fk_type_charge, date_emission, periode, montant ) VALUES
    ( 2, '2024-01-15', '[2023-12-04, 2024-01-04)', 395.72 );
   INSERT INTO charges ( fk_type_charge, date_emission, periode, montant ) VALUES
    ( 2, '2024-02-15', '[2024-01-04, 2024-02-04)', 532.75 );
   INSERT INTO charges ( fk_type_charge, date_emission, periode, montant ) VALUES
    ( 2, '2024-03-15', '[2024-02-04, 2024-03-04)', 373.25 );
   INSERT INTO charges ( fk_type_charge, date_emission, periode, montant ) VALUES
    ( 2, '2024-04-15', '[2024-03-04, 2024-04-04)', 273.27 );
   INSERT INTO charges ( fk_type_charge, date_emission, periode, montant ) VALUES
    ( 2, '2024-05-15', '[2024-04-04, 2024-05-04)', 197.25 );
   INSERT INTO charges ( fk_type_charge, date_emission, periode, montant ) VALUES
    ( 2, '2024-06-15', '[2024-05-04, 2024-06-04)', 113.11 );
   INSERT INTO charges ( fk_type_charge, date_emission, periode, montant ) VALUES
    ( 2, '2024-07-15', '[2024-06-04, 2024-07-04)', 65.65 );
   INSERT INTO charges ( fk_type_charge, date_emission, periode, montant ) VALUES
    ( 2, '2024-08-15', '[2024-07-04, 2024-08-04)', 48.94 );
   
   INSERT INTO charges ( fk_type_charge, date_emission, periode, montant ) VALUES 
    ( 3, '2023-12-07', '[2023-10-07, 2023-12-06)', 75.03 );
   INSERT INTO charges ( fk_type_charge, date_emission, periode, montant ) VALUES
    ( 3, '2024-02-07', '[2023-12-06, 2024-02-06)', 124.08 );
   INSERT INTO charges ( fk_type_charge, date_emission, periode, montant ) VALUES
    ( 3, '2024-04-07', '[2024-02-06, 2024-04-06)', 188.48 );
   INSERT INTO charges ( fk_type_charge, date_emission, periode, montant ) VALUES
    ( 3, '2024-06-07', '[2024-04-06, 2024-06-06)', 167.86 );
   INSERT INTO charges ( fk_type_charge, date_emission, periode, montant ) VALUES
    ( 3, '2024-08-07', '[2024-06-06, 2024-08-06)', 199.29 );
   
   	raise notice 'CAS 3 - bail en cours. pas de régularisation, mais présence factures hosr période de bail du locataire ... Pertinence KO';
   	assert regularisation_est_pertinente( 9 ) = false, 'KO. La régularisation devrait être considérée comme non pertinente. Absence de régularisation, présences de charges, non couvrantes.';

   
	raise notice 'CAS 4 - bail en cours. pas de régularisation, mais présence d''une factures couvrante et justifiant un appel de charge ... Pertinence OK';
    INSERT INTO charges ( fk_type_charge, date_emission, periode, montant ) VALUES 
	( 3, '2024-11-01', '[2024-08-06, 2024-11-10)', 111.11 );
   	assert regularisation_est_pertinente( 9 ) = true, 'KO. La régularisation devrait être considérée comme pertinente. Absence de régularisation, présence d''une charge couvrante.';

   
	raise notice 'CAS 5 - bail en cours. Régularisation, absence de factures couvrantes ... Pertinence KO';
	delete from charges where MONTANT = 111.11::money;
	INSERT INTO regularisation ( id, fk_locataire, ts_date_regularisation, total_charges_provisionnees, total_charges_reelles_individuelles, est_finale, est_forcee, note ) VALUES 
	( 1000, 5, '2024-07-01', 191.00, 99999999.99, false, false, '' );
	assert regularisation_est_pertinente( 9 ) = false, 'KO. La régularisation devrait être considérée comme non pertinente. Régularisation, absence de charge couvrante.';


	raise notice 'CAS 6 - bail en cours. Régularisation, présence de factures couvrantes ... Pertinence OK';
    INSERT INTO charges ( fk_type_charge, date_emission, periode, montant ) VALUES 
	    ( 3, '2024-12-01', '[2024-08-06, 2024-12-31)', 222.22 );
	  
	assert regularisation_est_pertinente( 9 ) = true, 'KO. La régularisation devrait être considérée  pertinente. Régularisation, présence de charge couvrante.';


	raise notice 'CAS 6.0 - bail en cours. 2 Régularisation, absence de factures couvrantes ... Pertinence KO';
	INSERT INTO regularisation ( id, fk_locataire, ts_date_regularisation, total_charges_provisionnees, total_charges_reelles_individuelles, est_finale, est_forcee, note ) VALUES 
	( 1001, 5, '2024-07-01', 191.00, 99999999.99, false, false, '' ); 
	assert regularisation_est_pertinente( 5 ) = false, 'KO. La régularisation devrait être considérée comme non pertinente. Régularisation, absence de charge couvrante.';


	-- CLOTURABILITE
	raise notice 'CAS 7 - bail terminé. Régularisation, absence de factures couvrantes ... Pertinence KO';
	INSERT INTO regularisation ( id, fk_locataire, ts_date_regularisation, total_charges_provisionnees, total_charges_reelles_individuelles, est_finale, est_forcee, note ) VALUES 
	( 2000, 4, '2024-07-01', 191.00, 99999999.99, false, false, '' );
	delete from charges where montant = 222.22::money;
	assert regularisation_est_pertinente( 4 ) = false, 'KO. La régularisation devrait être considérée non pertinente. Régularisation, et absence de charge couvrante.';


	-- cas de la cloturabilité des charges d'un bail.... Présence de tous les types de factures requis ?
	raise notice 'CAS 8 - bail terminé. Régularisation, présence d''une seule facture couvrante ... Pertinence KO';
	INSERT INTO charges ( fk_type_charge, date_emission, periode, montant ) VALUES 
	    ( 3, '2024-12-01', '[2024-08-06, 2024-12-31)', 333.33 );
	   	
	-- FORCAGES ... Forcément une regularisation. reprise. cloture 
	assert regularisation_est_pertinente( 4 ) = false, 'KO. La régularisation devrait être considérée non pertinente. Régularisation, présence d''une charge couvrante ( non complétude des charges obligatoires ).';
end;
$$ LANGUAGE plpgsql SECURITY DEFINER;

call test.unit_test_regularisation_est_pertinente();
table TEST.COLOCATAIRE ;
table TEST.CHARGES  ;
table TEST.ligne_regularisation  ;
select test.appel_de_charge ( 5 );


CREATE OR REPLACE PROCEDURE test.unit_test_appel_de_charge()
SET search_path TO 'test'
as $$
 DECLARE
 	v_state  text;
	v_msg    text;
	v_detail text;
	v_hint   text;
	v_context text;

    r locataire%rowtype;
    est_cloturable boolean;
    est_cloture boolean;
  	low date;
 begin
	raise notice 'unit_test_appel_de_charge';

	truncate locataire, charges, regularisation, ligne_regularisation  cascade;
    ---------------
	-------------------------------------- FORCAGE DES CHARGES / Montant fixe ( TODO Charge Forcée depuis moyenne )
	---------------
	
	-- 0.0 : appel forcé
	raise notice 'CAS 0.0 - REGULARISATION FORCEE - cloturable';
	INSERT INTO locataire( id, prenom, nom, numero_chambre, periode_occupation, loyer_mensuel_hc, provision_charge_mensuelle, note ) VALUES 
	( 1, 'Lorada', 'Pichon', 2, '[2023-12-12, 2024-02-24]', 340, 30, ''),
	( 5, 'Vincent', 'Marida', 2, '[2024-04-06,]'::daterange, 340, 50, ''); 
	assert appel_de_charge( 1, true, 1200 ) = 1200.00::money, 'KO. Appel de charge forcé';

	-- 0.1 : appel forcé
	raise notice 'CAS 0.0 - REGULARISATION FORCEE - non cloturable';
	assert appel_de_charge( 5, true, 1200 ) = 1200.00::money, 'KO. Appel de charge forcé';

	truncate locataire, regularisation, ligne_regularisation  cascade;
    ---------------
	-------------------------------------- CHARGES CLASSIQUES ET DIRECTES ( sans régularisations ) / Montant fixe ( TODO Charge Forcée depuis moyenne )
	---------------
	-- 1.1 : cloturable / sans regularisation
	raise notice 'CAS 1.1 : Pas d''antécédant de regularisation et clôturable';

	INSERT INTO locataire( id, prenom, nom, numero_chambre, periode_occupation, loyer_mensuel_hc, provision_charge_mensuelle, note ) VALUES 
	( 1, 'Lorada', 'Pichon', 2, '[2023-12-12, 2024-02-24]', 340, 30, ''),
	( 2, 'Billy', 'Banc', 1, '[2023-12-11, 2024-03-31]', 450, 30, ''),
	( 3,  'Florentin', 'Hucault', 4, '[2024-02-03, 2024-06-06]', 340, 50, ''),
	( 4, 'Gaetan', 'Abessolo', 3, '[2024-02-03, 2024-08-26]', 330, 30, ''),
	( 5, 'Vincent', 'Marida', 2, '[2024-04-06,]'::daterange, 340, 50, ''),
	( 6, 'Denis', 'Rognat', 6, '[2024-05-01, 2024-11-15]', 300, 50, ''),
	( 7, 'Remi', 'Nallet', 4, '[2024-10-07,]'::daterange, 340, 50, ''),
	( 8, 'Brice', 'Rostal', 5, '[2024-10-26,]'::daterange, 280, 50, ''),
	( 9, 'Bernardo', 'Perrini', 3, '[2024-11-01,]'::daterange, 340, 50, ''); 

	INSERT INTO charges ( fk_type_charge, date_emission, periode, montant ) VALUES 
    ( 1, '2023-11-21', '[2022-10-04, 2023-08-22)', 98.30 ),
    ( 1, '2024-05-10', '[2023-08-22, 2024-04-30)', 100.72 );
    INSERT INTO charges ( fk_type_charge, date_emission, periode, montant ) VALUES 
    ( 2, '2023-12-15', '[2023-11-04, 2023-12-04)', 246.17 ),
    ( 2, '2024-01-15', '[2023-12-04, 2024-01-04)', 395.72 ),
    ( 2, '2024-02-15', '[2024-01-04, 2024-02-04)', 532.75 ),
    ( 2, '2024-03-15', '[2024-02-04, 2024-03-04)', 373.25 ),
    ( 2, '2024-04-15', '[2024-03-04, 2024-04-04)', 273.27 ),
    ( 2, '2024-05-15', '[2024-04-04, 2024-05-04)', 197.25 ),
    ( 2, '2024-06-15', '[2024-05-04, 2024-06-04)', 113.11 ),
    ( 2, '2024-07-15', '[2024-06-04, 2024-07-04)', 65.65 ),
    ( 2, '2024-08-15', '[2024-07-04, 2024-08-04)', 48.94 );
    INSERT INTO charges ( fk_type_charge, date_emission, periode, montant ) VALUES 
    ( 3, '2023-12-07', '[2023-10-07, 2023-12-06)', 75.03 ),
    ( 3, '2024-02-07', '[2023-12-06, 2024-02-06)', 124.08 ),
    ( 3, '2024-04-07', '[2024-02-06, 2024-04-06)', 188.48 ),
    ( 3, '2024-06-07', '[2024-04-06, 2024-06-06)', 167.86 ),
    ( 3, '2024-08-07', '[2024-06-06, 2024-08-06)', 199.29 );
   
	ASSERT appel_de_charge ( 1 ) = (490.23)::money, 'KO - Lorada Pichon ( 1 ). CAS 1.1'; 

	raise notice 'VERIFICATION DE LA MAJ DES COLONNES : est_cloturable, est_cloture';
	select est_charge_cloturable, est_charge_cloture into est_cloturable, est_cloture from TEST.COLOCATAIRE C where id = 1;
	ASSERT est_cloturable = true, 'KO - Lorada Pichon, devrait etre marquée ''est_cloturable''.';
	ASSERT est_cloture = true, 'KO - Lorada Pichon, devrait etre marquée ''est_cloture''.';


	-- 2.1 : non cloturable / regularisation
	raise notice 'CAS 2.0 : Pas d''antécédant de regularisation et non clôturable ... 1ère régularisation';
	ASSERT appel_de_charge ( 5 ) = (-156.54)::money, 'KO - Vincent Marida ( 5 ). CAS 2.0'; 


	raise notice 'CAS 2.1 : Regularisation existante ( facture eau absente de la précédente, qu''on ajoute pour le test ) ), non clôturable ... 2nde régularisation';
	INSERT INTO charges ( fk_type_charge, date_emission, periode, montant ) VALUES 
    ( 1, '2024-11-01', '[2024-04-30, 2024-09-30)', 411.57 );
	ASSERT appel_de_charge ( 5 ) = (142.44)::money, 'KO - Vincent Marida ( 5 ). CAS 2.1'; 
	
	raise notice 'CAS 2.2 : Regularisation existante ( facture eau absente de la précédente, qu''on ajoute pour le test ) ), non clôturable ... 2nde régularisation';
	INSERT INTO charges ( fk_type_charge, date_emission, periode, montant ) VALUES
    ( 2, '2024-10-15', '[2024-08-04,2024-10-04)', 1225.87 ),
	( 3, '2024-10-07', '[2024-08-06,2024-10-04)', 1993.29 );
	ASSERT appel_de_charge ( 5 ) = (1377.77)::money, 'KO - Vincent Marida ( 5 ). CAS 2.2'; 
	--truncate locataire, charges, regularisation, ligne_regularisation  cascade;


	select lower( periode_occupation ) INTO low FROM locataire WHERE id = 2;
	update locataire SET periode_occupation = daterange( low, '2024-12-31' ) where id = 2;
	INSERT INTO charges ( fk_type_charge, date_emission, periode, montant ) VALUES
    ( 1, '2024-10-15', '[2024-09-30,2025-01-31)', 100.05 ),
	( 2, '2024-12-30', '[2024-10-04, 2025-01-31)', 367.21 ),
	( 3, '2024-10-07', '[2024-10-04,2025-01-31)', 609.34 );
	ASSERT appel_de_charge ( 5 ) = (1000)::money, 'KO - Vincent Marida ( 5 ). CAS 2.3'; 

	exception when others then 

        GET STACKED diagnostics 
        	v_state   = RETURNED_SQLSTATE,
            v_msg     = MESSAGE_TEXT,
            v_detail  = PG_EXCEPTION_DETAIL,
            v_hint    = PG_EXCEPTION_HINT,
            v_context = PG_EXCEPTION_CONTEXT;
       
		raise notice ' % % % % % ', v_state, v_msg, v_detail, v_hint, v_context;
		raise notice '[KO] : ERROR';
end;
$$ LANGUAGE plpgsql SECURITY INVOKER;


CREATE OR REPLACE PROCEDURE test.run_tests()
SET search_path TO 'test'
as $$
 declare
 begin
	 /*
	call test.unit_test_charges_sont_cloturables();
	call unit_test_regularisation_est_pertinente();
	call unit_test_charges_sont_periodes_fusionnables();
	call unit_test_calcul_provisions_payees();
*/
	-- appel de charge forcé 
	call unit_test_appel_de_charge(); 
  end
$$ LANGUAGE plpgsql SECURITY DEFINER;

call unit_test_calcul_provisions_payees();

call test.run_tests();



select test.lire_derniere_date_regul( 5 );

select test.calcul_provisions_payees( 5,2, '2024-07-31' );
select calcul_provisions_payees( 5, 3, '2024-10-21' );
select calcul_provisions_payees( 5, 4 );


table test.regularisation ;
table test.ligne_regularisation ;
select * from test.locataire;
select * from test.charges;
   

   	

INSERT INTO locataire( id, prenom, nom, numero_chambre, periode_occupation, loyer_mensuel_hc, provision_charge_mensuelle, note ) VALUES (
1000001, 'test_bail_fini_et_charges_cloturable', 'test_03_nom', 1002, '[2024-01-01,2024-02-25]'::daterange, 280, 50, 'test' ); 



DELETE from charges where note = 'test';
DELETE from locataire where note = 'test';
DELETE from regularisation where note = 'test';

update locataire set est_charge_cloturable = false;


table test.regularisation ;
table test.ligne_regularisation ;
SELECT ts_date_arret FROM ligne_regularisation AS lr 
WHERE fk_regularisation = (
	SELECT max( id ) FROM regularisation WHERE fk_locataire = 5
);

SELECT COALESCE( "SELECT max( id ) FROM regularisation WHERE fk_locataire = 5", 12 );

INNER JOIN regularisation AS r ON lr.fk_regularisation = r.id
INNER JOIN locataire AS c ON r.fk_locataire = c.id
GROUP BY fk_regularisation, ts_date_arret, fk_type_charge, c.id
having lr.fk_type_charge = 1 AND c.id = 5;

-- INSERT INTO regularisation ( fk_locataire, ts_date_regularisation, periode_couverte, montant_regularisation, total_charges_provisionnees, total_charges_reelles, est_finale, est_forcee, note ) VALUES 
  ( 1000, '2024-03-31', '[2023-10-07, 2023-12-06]', 100.00, 30.00, 120.00, true, true, 'test' );

select charges_sont_cloturables( 1000001 );

INSERT INTO charges ( fk_type_charge, date_emission, periode, montant, note ) VALUES 
    ( 1, '2024-12-31', '[2024-01-01,2024-11-30)',142.51, 'test' );
    ( 2, '2024-11-15', '[2024-10-04,2024-11-04)',207.39, 'test' ),
    ( 2, '2024-12-15', '[2024-11-04,2024-12-04)',300.77, 'test' ),
    ( 3, '2024-12-07', '[2024-10-06,2024-12-06)',142.51, 'test' );

    INSERT INTO charges ( fk_type_charge, date_emission, periode, montant, est_fractionnable ) VALUES 
    ( 6, '2023-12-07', '[2023-10-07, 2023-10-07)', 100, false );

delete from regularisation where fk_locataire = 6;


CREATE TABLE IF NOT EXISTS locataire_test ( LIKE locataire INCLUDING ALL );

-- should insert
INSERT INTO locataire( prenom, nom, numero_chambre, periode_occupation, loyer_mensuel_hc, provision_charge_mensuelle, note ) VALUES (
  'Lorada', 'Pichon', 2, '[2023-12-12, 2024-02-24]', 340, 30, ''); 

-- should generate exclusion on chambre / periode_occupation overlap
INSERT INTO locataire( prenom, nom, numero_chambre, periode_occupation, loyer_mensuel_hc, provision_charge_mensuelle, note ) VALUES (
  'Lorene', 'Dubois', 2, '[2024-02-24, 2024-02-24]', 350, 50, ''); 


-- should insert
INSERT INTO locataire( prenom, nom, numero_chambre, periode_occupation, loyer_mensuel_hc, provision_charge_mensuelle, note ) VALUES (
  'Billy', 'Banc', 1, '[2023-12-11, 2024-04-11]', 450, 30, ''); 

DROP TABLE IF EXISTS locataire_test;

RESET search_path;
