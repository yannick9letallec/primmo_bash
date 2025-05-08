-- Extraire la durée du bail
set search_path to test, public;
\set env test


\ir ./Functions_Helpers.sql
\ir ./Functions_Bien_Actif.sql
\ir ./Functions_Colocataire.sql
\ir ./Functions_Charge.sql
\ir ./Functions_Regularisation.sql


-- ! IMPORTANT ! FOR SCRIPT  HANDLING ( Next calls only serving dev / test purposes )
\q