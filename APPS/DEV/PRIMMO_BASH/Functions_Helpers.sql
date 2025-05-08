/* HELPERS */

DROP FUNCTION IF EXISTS primmo_bash_dev.lire_dernier_jour_du_mois( date ) CASCADE;
CREATE OR REPLACE FUNCTION primmo_bash_dev.lire_dernier_jour_du_mois( d date ) 
RETURNS TEXT AS $$
 	select extract( day from ( extract ( year from d ) || '-' || extract( month from ( d + interval '1 month' )) || '-01' )::date - interval '1 day' );   
$$
LANGUAGE sql SET search_path TO primmo_bash_dev security DEFINER;


DROP FUNCTION IF EXISTS primmo_bash_dev.num_to_words_lang( numeric, TEXT, text ) CASCADE;
CREATE OR REPLACE FUNCTION primmo_bash_dev.num_to_words_lang( numeric, TEXT, text DEFAULT 'currency' )
RETURNS text AS $$
    from num2words import num2words
    return num2words(args[0], lang=args[1], to=args[2])
$$ LANGUAGE plpython3u SET search_path TO primmo_bash_dev security DEFINER;
 -- SELECT primmo_bash_dev.num_to_words_lang( 2024, 'fr', 'currency' );


DROP FUNCTION IF EXISTS primmo_bash_dev.quittance_remplir( TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT ) CASCADE;
CREATE OR REPLACE FUNCTION primmo_bash_dev.quittance_remplir( quittance_fmt TEXT, bailleur_denomination TEXT, adresse_bailleur TEXT, locataire_denomination TEXT, adresse_locataire TEXT, date_debut_quittance TEXT, 
	date_fin_quittance TEXT, date_paiement_quittance TEXT, date_emission_quittance TEXT, lieux_quittance TEXT, 
	loyer_hc TEXT, provision_charges TEXT, montant_total TEXT, montant_total_lettre TEXT, periode_couverte TEXT )
RETURNS text AS $$
begin
		-- substitution des variables et enregistrement
		select replace( quittance_fmt, '{{ bailleur_denomination }}', bailleur_denomination ) into quittance_fmt;
		select replace( quittance_fmt, '{{ bailleur_adresse }}', adresse_bailleur ) into quittance_fmt;
		select replace( quittance_fmt, '{{ locataire_denomination }}', locataire_denomination ) into quittance_fmt;
		select replace( quittance_fmt, '{{ locataire_adresse }}', adresse_locataire ) into quittance_fmt;

		select replace( quittance_fmt, '{{ periode_couverte }}', periode_couverte ) into quittance_fmt;
		select replace( quittance_fmt, '{{ quittance_debut_periode }}', date_debut_quittance ) into quittance_fmt;
		select replace( quittance_fmt, '{{ quittance_fin_periode }}', date_fin_quittance ) into quittance_fmt;
		select replace( quittance_fmt, '{{ quittance_date_paiement }}', date_paiement_quittance ) into quittance_fmt;
		select replace( quittance_fmt, '{{ quittance_date_emission }}', date_emission_quittance ) into quittance_fmt;
		select replace( quittance_fmt, '{{ quittance_lieux }}', lieux_quittance ) into quittance_fmt;

		select replace( quittance_fmt, '{{ quittance_montant_loyer_hc }}', loyer_hc ) into quittance_fmt;
		select replace( quittance_fmt, '{{ quittance_montant_provision_charges }}', provision_charges ) into quittance_fmt;
		select replace( quittance_fmt, '{{ quittance_montant_total }}', montant_total ) into quittance_fmt;
		select replace( quittance_fmt, '{{ quittance_montant_total_lettres }}', montant_total_lettre ) into quittance_fmt;

		return quittance_fmt;
	END;
$$
LANGUAGE plpgsql SET search_path TO primmo_bash_dev security DEFINER;


DROP FUNCTION IF EXISTS primmo_bash_dev.calcul_nb_jours_prorata( date, date ) CASCADE;
CREATE OR REPLACE FUNCTION primmo_bash_dev.calcul_nb_jours_prorata( fin date, deb date )
RETURNS int AS $$
	declare 
		nb_jours int;
	BEGIN
		nb_jours = ( select fin - deb );
		if nb_jours = 0 then
			nb_jours = 1;
		end if;

		return nb_jours;
	END
$$
LANGUAGE plpgsql SET search_path TO primmo_bash_dev security DEFINER;
COMMENT ON FUNCTION primmo_bash_dev.calcul_nb_jours_prorata IS 'HELPER FUNCTION. Renvoi le nombre de jours ''consommés'' dans le mois. Utile pour les mois d''arrivée et de sortie. En cas d''entrée le 01 et/ou de sortie le 30/31 ( dernier jour du mois ), force un nb jour mini à 1 au lieu de 0.';


DROP FUNCTION IF EXISTS primmo_bash_dev.quittance_periode_arret( int ) CASCADE;
CREATE OR REPLACE FUNCTION primmo_bash_dev.quittance_periode_arret( locataire_id int )
RETURNS text AS $$
	declare 
		date_fin_bail date;
		d date;
	BEGIN
		date_fin_bail = date_fin_bail( locataire_id );
		
		if date_fin_bail is not null then
			d = date_fin_bail; 
		else
			d = current_date;
		end if;

		return to_char( d, 'YYYY-MM' );
	END
$$
LANGUAGE plpgsql SET search_path TO primmo_bash_dev security DEFINER;
COMMENT ON FUNCTION primmo_bash_dev.quittance_periode_arret IS 'HELPER FUNCTION. Renvoi la période d''arret des quittances. Si fin de bail connu : la période d''arrêt est la date de fin de bail. Sinon, on s''arrete à la période courrante';


-- SELECT primmo_bash_dev.quittance_peeriode_arret( 3 );
