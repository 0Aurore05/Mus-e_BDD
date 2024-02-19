/*
*******************************************************************************************
GROUPE 9
Aurore Martorana - 22105397
*******************************************************************************************
*/


SET SERVEROUTPUT ON

-- ==== TRIGGER #1 ====

prompt -- Test trigger 'check_age_artiste', a l'insertion d'un artiste avec une date de naissance plus grand que sa date de deces, on a une exception 'erreur_age_artiste':

INSERT INTO ARTISTE VALUES ('ART100', 'Artiste errone', '01-01-2020', '01-01-1200', 'France, Europe');

-- ==== TRIGGER #2 ====

prompt -- Test trigger 'check_salle_ouverte' qui verifie qu'une salle est bien ouverte a l'insertion d'une visite. On compare avec SYSDATE car la salle est ouverte / fermee dependamment des jours

prompt -- Le visiteur visite la salle 2, fermee, donc exception : erreur_salle_indisponible
INSERT INTO VISITE VALUES ('VIS10', 'SAL2', SYSDATE);


-- ==== PROCEDURE #1, FONCTION #1, FONCTION #2 ====

prompt -- Test procedure 'statistiques(date)' ou l'on donne une date a la procedure qui va renvoyer grace a deux fonctions des statistiques de la journee ciblee, le nombre de visites, et la recette totale :

prompt -- Aujourd'hui (SYSDATE), le visiteur 10 a visite 3 salles
EXEC statistiques(SYSDATE);

prompt -- Le 4 decembre 2022, le visiteur 4 et 5 ont visites a eux deux 3 salles
EXEC statistiques('04-12-2022');
