--------------------------------------------------
--Suppression des anciennes donnees type "profils"
--------------------------------------------------
-- Comportait pour chaque cd_ref les dates min, dates max, altitude min, altitude max déjà présentes dans les vm_valid_profiles et vm_cor_taxon_phenology, de facon paramétrable. 
-- Les bbox de l'ancienne VM sont remplacées par les aires d'occurrences calculées sur la base de zones tampons.
DROP MATERIALIZED VIEW vm_min_max_for_taxons; 

-- Suppression de la fonction permettant de récupérer les données de la vm supprimée précédemment
DROP FUNCTION gn_synthese.fct_calculate_min_max_for_taxon(integer);

-- Supprime la fonction trigger qui rafraichissait l'ancienne vm_min_max_for_taxons 
DROP FUNCTION fct_tri_refresh_vm_min_max_for_taxons();
