-- SQL
set search_path to test, public;

-- psql
\set env test

\echo :env

DROP FUNCTION IF EXISTS test.f_trg_charges_insert CASCADE;
CREATE OR REPLACE FUNCTION test.f_trg_charges_insert()
RETURNS TRIGGER as $$
 DECLARE
  r locataire%rowtype;
  counter int = 0;
  rid integer;
  periode_charge daterange;
 BEGIN
  raise notice 'FUNCTION : f_trg_charges_insert WKS ! ';
  raise notice 'Type charge : %', NEW.fk_type_charge;
  -- TODO : on vérifie que les dates sont bien adjacentes
 SELECT id, periode INTO rid, periode_charge FROM charges WHERE fk_type_charge = NEW.fk_type_charge AND id != NEW.id ORDER BY id DESC LIMIT 1;

 IF FOUND THEN  
	raise notice 'FUND :) ';
 	IF NOT NEW.periode -|- periode_charge THEN
	  if new.fk_type_charge = 1 then
			raise notice 'EAU / Traitement spécifique ( facture estimative et réelles sur la même période ) ';
	  else
 	  	raise exception 'Last ID : %, nouvel id : %, Périodes non adjacentes ... ancienne : %, nouvelle : %, inexistante : %', 
			rid, NEW.id, periode_charge, NEW.periode, OLD.periode;
	  end if;
 	 ELSE
 	  raise NOTICE 'Adjacente OK ( % ) avec la dernière période ( % ) présédente pour le même type de charges ... Continuation.', 
		NEW.periode, periode_charge;  
 	END IF;

 ELSE
	raise notice 'NOT FUND :( ';
 END IF;

  -- recherche des charges cloturables
  FOR r IN
    select * from locataire where not est_charge_cloture and not est_charge_cloturable
  LOOP
    -- si date fin bail ...  les charges deviennent cloturables ... et on cherche à les marquer ainsi
    IF upper( r.periode_occupation ) IS NOT NULL THEN
      raise notice 'Fin de bail trouvée : %, %', upper( r.periode_occupation ), r.prenom;
      
      update locataire set est_charge_cloturable = charges_sont_cloturables( r.id ) where id = r.id;
    END IF;

	-- !! clôture standart ( sans la TEOM, sans facture spécifique ...
	-- A GARDER ? Utilité à automatiser ?  
	-- NOTIFY / LISTEN sur le nb / l'identité des locataires 'clôturables'
    -- perform cloturer_charges( r.id );
  END LOOP;

    -- ceci fait, on va lancer la cloture de charge
    -- cette fonctoin s'occupe de cloturer pour les charges pour les locataires / locataires éligibles.
  -- avec ce resultat, pour chaque locataire id, on cherche si les charges sont clotirables.
  -- date fin de bail <@ dans chaque periode de facture base
  
  -- pour chaque nouvelle charge insérée 
   
   RETURN NEW;
 END
$$ 
LANGUAGE plpgsql SET search_path TO test SECURITY DEFINER;
COMMENT ON FUNCTION :env.f_trg_charges_insert IS 'TRIGGER qui s''assure de la bonne adjacence des périodes de factures lors de l''ajout d''une nouvelle charge. ET qui s''occupe de mettre à jour l''aspect CLOTURABILITE des charges du locataire';


DROP FUNCTION IF EXISTS :env.f_trg_charges_map_lo CASCADE;
CREATE OR REPLACE FUNCTION test.f_trg_charges_map_lo()
RETURNS TRIGGER as $$
 DECLARE
  base_path text := 'CHARGES/Scripts/TEST/Files/';
  type_path text;
  final_path text;
  periode_charge daterange;
  oid int;
 BEGIN
  raise notice 'FUNCTION : f_trg_charges_map_lo WKS ! ';
  raise notice 'Type charge : %', NEW.fk_type_charge;

	if new.file_name is not null then 
		raise notice 'File Name : %', NEW.file_name;

		case 
			when new.fk_type_charge = 1 then
				type_path := 'EAU/';
			when new.fk_type_charge = 2 then
				type_path := 'GAZ/';
			when new.fk_type_charge = 3 then
				type_path := 'ELEC/';
			when new.fk_type_charge = 4 then
				type_path := 'PETROL/';
			when new.fk_type_charge = 5 then
				type_path := 'PELLET/';
			when new.fk_type_charge = 6 then
				type_path := 'BOIS/';
			when new.fk_type_charge = 7 then
				type_path := 'FIOUL/';
			when new.fk_type_charge = 8888 then
				type_path := 'TEOM/';
			when new.fk_type_charge = 9999 then
				type_path := 'EXCEPT/';
		end case;

		final_path := base_path || type_path || new.file_name;
		raise notice 'Full Path : %', final_path;
		
		select lo_import( final_path ) into oid;

		raise notice 'OID : %', oid;

		raise notice 'NEW : %', new;
		new.loid := oid;
		raise notice 'NEW : %', new;
 		-- SQL side : 
			-- importer le lo en fonction du 'file_name' ( fichier => OLD )
			-- recupérer et enregistrer l'OID
	end if;

  -- determiner le base_path en fonction du type de charges
  -- importer le lo en fonction du 'file_name' ( fichier => OLD )
  -- stocker l'OID correspondant
   
   RETURN new;
 END
$$
LANGUAGE plpgsql SET search_path TO test SECURITY DEFINER;
COMMENT ON FUNCTION :env.f_trg_charges_map_lo IS 'TRIGGER qui (auto) upload le fichier d''une facture dans un lo;';


DROP FUNCTION IF EXISTS :env.f_trg_locataire_update CASCADE;
CREATE OR REPLACE FUNCTION test.f_trg_locataire_update()
RETURNS TRIGGER as $$
 DECLARE
--  
 BEGIN
	if upper( new.periode_occupation ) is not null then

		if upper( new.periode_occupation )::date < current_date then
			new.periode_occupation = daterange( lower( old.periode_occupation ), null, '[)' );
			raise exception 'La date rentrée est antérieure à la date courante';
			-- new.note='1 -LOGIC OK --------------------------------' || upper( new.periode_occupation ) || '----' || current_date || '----' ;
		end if;

	else

		new.periode_occupation = daterange( lower( old.periode_occupation ), null, '[)' );
		-- new.note='2 - LOGIC KO ########################################';
	end if;

		return new;


 END
$$ 
LANGUAGE plpgsql SET search_path TO test SECURITY DEFINER;
COMMENT ON FUNCTION :env.f_trg_locataire_update IS 'TODO ';


DROP FUNCTION IF EXISTS :env.f_trg_locataire_insert_or_update;
CREATE OR REPLACE FUNCTION :env.f_trg_locataire_insert_or_update()
RETURNS TRIGGER as $$
 DECLARE

 BEGIN
/*
	 SELECT 
  	( provision_charge_mensuelle * ( EXTRACT ( YEAR FROM age(  now(), lower( periode_occupation ) ) ) *12 ) ) 
  	+ 
  	( provision_charge_mensuelle * ( EXTRACT ( MONTH FROM age(  now(), lower( periode_occupation ) ) ) ) )
  	+
  	( provision_charge_mensuelle / 30.5 * ( EXTRACT( DAY FROM age(  now(), lower( periode_occupation ) ) ) ) ) 
  		FROM locataire
  		WHERE 
*/
	END
$$ 
LANGUAGE plpgsql SET search_path TO :env SECURITY DEFINER;
COMMENT ON FUNCTION :env.f_trg_locataire_insert_or_update IS 'TODO ';


--
--
-- TRIGGER CREATION
--
--
DROP TRIGGER IF EXISTS trg_charges_insert ON :env.charges;

CREATE OR REPLACE TRIGGER trg_charges_before_insert 
BEFORE INSERT ON :env.charges
FOR EACH ROW EXECUTE FUNCTION :env.f_trg_charges_insert();
-- will call :
  -- test_est_cloturable
  -- do th e cloture

DROP TRIGGER IF EXISTS trg_charges_lo_insert ON :env.charges;

CREATE OR REPLACE TRIGGER trg_charges_lo_insert 
BEFORE INSERT ON :env.charges
FOR EACH ROW EXECUTE FUNCTION :env.f_trg_charges_map_lo();

\q
