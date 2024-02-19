/*
*******************************************************************************************
GROUPE 9
Aurore Martorana - 22105397
*******************************************************************************************
*/

--************************************ CREATION *******************************************

SET SQLBLANKLINES ON
SET SERVEROUTPUT ON

CREATE TABLE ARTISTE(
    NUM_ARTISTE VARCHAR(10),
    NOM VARCHAR(25) CONSTRAINT NOM_ARTISTE_NN NOT NULL,
    DATE_NAISSANCE DATE,
    DATE_DECES DATE,
    NATIONALITE VARCHAR(50) CONSTRAINT NAT_ARTISTE_NN NOT NULL,
 
    CONSTRAINT PK_ARTISTE PRIMARY KEY (NUM_ARTISTE)
);

CREATE TABLE COURANT(
    NOM VARCHAR(25),
    EPOQUE VARCHAR(25) CONSTRAINT EPOQUE_COURANT_NN NOT NULL,
 
    CONSTRAINT PK_COURANT PRIMARY KEY (NOM)
);

CREATE TABLE SALLE(
    NUM_SALLE VARCHAR(10),
    NOM VARCHAR(25),
    ACCESSIBILITE VARCHAR(10) CONSTRAINT ACCESS_SALLE_NN NOT NULL,
 
    CONSTRAINT PK_SALLE PRIMARY KEY (NUM_SALLE),
    CONSTRAINT DOM_ACCESS_SALLE CHECK (ACCESSIBILITE IN ('OUVERTE','FERMEE'))
);

CREATE TABLE VISITEUR(
    NUM_VISITEUR VARCHAR(10),
    TARIF VARCHAR(25) CONSTRAINT TARIF_NN NOT NULL,
 
    CONSTRAINT PK_VISITEUR PRIMARY KEY (NUM_VISITEUR),
    CONSTRAINT DOM_TARIF CHECK (TARIF IN ('NORMAL','ETUDIANT','MINEUR','ENFANT'))
);

CREATE TABLE VISITE(
    NUM_VISITEUR VARCHAR(10),
    NUM_SALLE VARCHAR(10),
    DATE_VISITE DATE CONSTRAINT DATE_VISITE_NN NOT NULL,
 
    CONSTRAINT PK_VISITE PRIMARY KEY (NUM_VISITEUR, NUM_SALLE),
   
    CONSTRAINT FK_VISITE_VISITEUR FOREIGN KEY (NUM_VISITEUR) REFERENCES VISITEUR(NUM_VISITEUR) ON DELETE CASCADE,
    CONSTRAINT FK_VISITE_SALLE FOREIGN KEY (NUM_SALLE) REFERENCES SALLE(NUM_SALLE) ON DELETE CASCADE
);

CREATE TABLE OEUVRE(
    NUM_OEUVRE VARCHAR(10),
    NOM VARCHAR(75),
    DATE_REALISATION NUMERIC(4,0),
    DIMENSIONS VARCHAR(25) CONSTRAINT DIM_NN NOT NULL,
 
    NUM_SALLE VARCHAR(10),
    NUM_ARTISTE VARCHAR(10),
    COURANT VARCHAR(25),
 
    CONSTRAINT PK_OEUVRE PRIMARY KEY (NUM_OEUVRE),
    CONSTRAINT FK_OEUVRE_SALLE FOREIGN KEY (NUM_SALLE) REFERENCES SALLE(NUM_SALLE) ON DELETE CASCADE,
    CONSTRAINT FK_OEUVRE_ARTISTE FOREIGN KEY (NUM_ARTISTE) REFERENCES ARTISTE(NUM_ARTISTE) ON DELETE CASCADE,
    CONSTRAINT FK_OEUVRE_COURANT FOREIGN KEY (COURANT) REFERENCES COURANT(NOM) ON DELETE CASCADE
);

CREATE TABLE SCULPTURE(
    NUM_OEUVRE VARCHAR(10),
    MATERIAU VARCHAR(25) CONSTRAINT MAT_NN NOT NULL,
   
    CONSTRAINT PK_SCULPTURE PRIMARY KEY (NUM_OEUVRE),
    CONSTRAINT FK_SCULPTURE_OEUVRE FOREIGN KEY (NUM_OEUVRE) REFERENCES OEUVRE(NUM_OEUVRE) ON DELETE CASCADE
);

CREATE TABLE TABLEAU(
    NUM_OEUVRE VARCHAR(10),
    TECHNIQUE VARCHAR(50) CONSTRAINT TECH_NN NOT NULL,
 
    CONSTRAINT PK_PEINTURE PRIMARY KEY (NUM_OEUVRE),
    CONSTRAINT FK_TABLEAU_OEUVRE FOREIGN KEY (NUM_OEUVRE) REFERENCES OEUVRE(NUM_OEUVRE) ON DELETE CASCADE
);


--************************ TRIGGERS / PROCEDURES / FONCTIONS  *****************************

--**************************************************************
CREATE OR REPLACE TRIGGER check_age_artiste
	BEFORE INSERT
	ON ARTISTE
	FOR EACH ROW
DECLARE
	erreur_age_artiste EXCEPTION;
BEGIN
	IF :new.DATE_NAISSANCE > :new.DATE_DECES
		THEN RAISE erreur_age_artiste;
	END IF;
 
	EXCEPTION
		WHEN erreur_age_artiste THEN RAISE_APPLICATION_ERROR(-20001, 'La date de naissance est superieure a la date de deces');
END;
/

--**************************************************************
CREATE OR REPLACE TRIGGER check_salle_ouverte
	BEFORE INSERT
	ON VISITE
	FOR EACH ROW
DECLARE
	etat SALLE.ACCESSIBILITE%TYPE;
	erreur_salle_indisponible EXCEPTION;
BEGIN
	IF :new.DATE_VISITE = SYSDATE THEN
		
		SELECT ACCESSIBILITE INTO etat FROM SALLE WHERE NUM_SALLE = :new.NUM_SALLE;
		IF etat = 'FERMEE'
			THEN RAISE erreur_salle_indisponible;
		END IF;
	END IF;
	
	EXCEPTION
		WHEN erreur_salle_indisponible THEN RAISE_APPLICATION_ERROR(-20002, 'La visite est impossible dans une salle fermee');
END;
/

--**************************************************************
CREATE OR REPLACE FUNCTION nbr_visite(date_cible IN DATE)
	RETURN NUMBER
AS
	total NUMBER;
BEGIN
	SELECT COUNT(DISTINCT NUM_VISITEUR) INTO total
		FROM VISITE
		WHERE TO_CHAR(DATE_VISITE, 'YYYY-MM-DD') = TO_CHAR(date_cible, 'YYYY-MM-DD');
	
	RETURN(total);
END;
/

--**************************************************************
CREATE OR REPLACE FUNCTION recette_journee(date_cible IN DATE)
	RETURN NUMBER
AS
	total NUMBER;
BEGIN
	total := 0;
	
	FOR visiteur IN (
		SELECT DISTINCT VISITEUR.NUM_VISITEUR, TARIF
		FROM VISITEUR INNER JOIN VISITE ON VISITEUR.NUM_VISITEUR = VISITE.NUM_VISITEUR
		WHERE TO_CHAR(DATE_VISITE, 'YYYY-MM-DD') = TO_CHAR(date_cible, 'YYYY-MM-DD'))
	LOOP
		IF visiteur.TARIF = 'NORMAL' THEN
			total := total + 12;
		ELSIF visiteur.TARIF = 'ETUDIANT' THEN
			total := total + 10;
		ELSIF visiteur.TARIF = 'MINEUR' THEN
			total := total + 8;
		END IF;
	END LOOP;
	
	RETURN(total);
END;
/

--**************************************************************
CREATE OR REPLACE PROCEDURE statistiques (date_cible IN DATE) AS
	visites NUMBER;
	recette NUMBER;
BEGIN
	recette := recette_journee(date_cible);
	visites := nbr_visite(date_cible);
	
	dbms_output.put_line('Statistiques du ' || TO_CHAR(date_cible, 'DL', 'NLS_DATE_LANGUAGE = FRENCH') || ':');
	dbms_output.put_line('Nombre de visiteurs: ' || visites);
	dbms_output.put_line('Recettes totales: ' || recette);	
END;
/



--************************************* INSERT ********************************************

INSERT INTO ARTISTE VALUES ('ART2', 'Zdzislaw Beksinski', '24-02-1929', '21-02-2005', 'Pologne, Europe');
INSERT INTO ARTISTE VALUES ('ART3', 'Gustav Klimt', '14-06-1862', '6-02-1918', 'Autriche, Europe');
INSERT INTO ARTISTE VALUES ('ART4', 'Rene Magritte', '21-11-1898', '15-08-1967', 'Belgique, Europe');
INSERT INTO ARTISTE VALUES ('ART5', 'William Turner', '23-04-1775', '19-12-1851', 'Royaume-Uni, Europe');
INSERT INTO ARTISTE VALUES ('ART7', 'Utagawa Hiroshige', '01-01-1797', '12-10-1858', 'Japon, Asie');
INSERT INTO ARTISTE VALUES ('ART8', 'Ibrahim el-Salahi', '05-09-1930', NULL, 'Soudan, Afrique');
INSERT INTO ARTISTE VALUES ('ART9', 'H.R. Giger', '5-02-1940', '12-05-2014', 'Suisse, Europe');
INSERT INTO ARTISTE VALUES ('ART10', 'Pablo Picasso', '25-10-1881', '08-04-1973', 'Espagne, Europe');
INSERT INTO ARTISTE VALUES ('ART11', 'Pierre Julien', '20-06-1731', '17-12-1804', 'France, Europe');
INSERT INTO ARTISTE VALUES ('ART12', 'Choi Xooang', '01-01-1975', NULL, 'Coree du Sud, Asie');
INSERT INTO ARTISTE VALUES ('ART13', 'Ben Enwonwu', '14-07-1917', '05-02-1994', 'Nigeria, Afrique');
INSERT INTO ARTISTE VALUES ('ART14', 'Giovanni Strazza', '01-01-1818', '18-04-1875', 'Italie, Europe');
INSERT INTO ARTISTE VALUES ('ART15', 'Benvenuto Cellini', '01-11-1500', '13-02-1571', 'Italie, Europe');
INSERT INTO ARTISTE VALUES ('ART16', 'Henri Matisse', '31-12-1869', '03-11-1954', 'France, Europe');

INSERT INTO COURANT VALUES ('Surrealisme', '20e');
INSERT INTO COURANT VALUES ('Art Nouveau', 'Fin 19e debut 20e');
INSERT INTO COURANT VALUES ('Romantisme', 'Fin 18e debut 19e');
INSERT INTO COURANT VALUES ('Cubisme', 'Debut 20e');
INSERT INTO COURANT VALUES ('Ukiyo-e', '17e');
INSERT INTO COURANT VALUES ('Contemporain', 'Depuis fin 20e');
INSERT INTO COURANT VALUES ('Expressionnisme', 'Debut 20e');
INSERT INTO COURANT VALUES ('Neo-classicisme', 'Fin 18e');
INSERT INTO COURANT VALUES ('Hyperrealisme', 'Fin 20e');
INSERT INTO COURANT VALUES ('Modernisme', 'Debut 20e');
INSERT INTO COURANT VALUES ('Renaissance', '14e au 16e');

INSERT INTO SALLE VALUES ('SAL1', 'Europe', 'OUVERTE');
INSERT INTO SALLE VALUES ('SAL2', 'Asie', 'FERMEE');
INSERT INTO SALLE VALUES ('SAL3', 'Afrique', 'OUVERTE');
INSERT INTO SALLE VALUES ('SAL4', 'Sculpture', 'OUVERTE');

INSERT INTO VISITEUR VALUES ('VIS1', 'NORMAL');
INSERT INTO VISITEUR VALUES ('VIS2', 'ENFANT');
INSERT INTO VISITEUR VALUES ('VIS3', 'NORMAL');
INSERT INTO VISITEUR VALUES ('VIS4', 'MINEUR');
INSERT INTO VISITEUR VALUES ('VIS5', 'ETUDIANT');
INSERT INTO VISITEUR VALUES ('VIS6', 'NORMAL');
INSERT INTO VISITEUR VALUES ('VIS7', 'MINEUR');
INSERT INTO VISITEUR VALUES ('VIS8', 'ETUDIANT');
INSERT INTO VISITEUR VALUES ('VIS9', 'ETUDIANT');
INSERT INTO VISITEUR VALUES ('VIS10', 'NORMAL');

INSERT INTO VISITE VALUES ('VIS1', 'SAL1', '02-09-2022');
INSERT INTO VISITE VALUES ('VIS1', 'SAL2', '02-09-2022');
INSERT INTO VISITE VALUES ('VIS1', 'SAL4', '02-09-2022');
INSERT INTO VISITE VALUES ('VIS2', 'SAL1', '12-10-2022');
INSERT INTO VISITE VALUES ('VIS2', 'SAL4', '12-10-2022');
INSERT INTO VISITE VALUES ('VIS3', 'SAL3', '12-08-2022');
INSERT INTO VISITE VALUES ('VIS4', 'SAL2', '04-12-2022');
INSERT INTO VISITE VALUES ('VIS4', 'SAL3', '04-12-2022');
INSERT INTO VISITE VALUES ('VIS5', 'SAL1', '04-12-2022');
INSERT INTO VISITE VALUES ('VIS5', 'SAL3', '04-12-2022');
INSERT INTO VISITE VALUES ('VIS6', 'SAL2', '01-11-2022');
INSERT INTO VISITE VALUES ('VIS6', 'SAL3', '01-11-2022');
INSERT INTO VISITE VALUES ('VIS6', 'SAL4', '01-11-2022');
INSERT INTO VISITE VALUES ('VIS6', 'SAL1', '01-11-2022');
INSERT INTO VISITE VALUES ('VIS7', 'SAL1', '15-08-2022');
INSERT INTO VISITE VALUES ('VIS8', 'SAL2', '19-08-2022');
INSERT INTO VISITE VALUES ('VIS8', 'SAL3', '19-08-2022');
INSERT INTO VISITE VALUES ('VIS8', 'SAL4', '19-08-2022');
INSERT INTO VISITE VALUES ('VIS9', 'SAL4', '02-09-2022');
INSERT INTO VISITE VALUES ('VIS10', 'SAL3', SYSDATE);
INSERT INTO VISITE VALUES ('VIS10', 'SAL1', SYSDATE);
INSERT INTO VISITE VALUES ('VIS10', 'SAL4', SYSDATE);

INSERT INTO OEUVRE VALUES ('OEU2', 'Untitled', '1982', '61x73', 'SAL1', 'ART2', 'Surrealisme');
INSERT INTO OEUVRE VALUES ('OEU3', 'Paysage de Cimetiere', '1970', '73x91', NULL, 'ART2', 'Surrealisme');
INSERT INTO OEUVRE VALUES ('OEU4', 'Judith II', '1909', '178x46', 'SAL1', 'ART3', 'Art Nouveau');
INSERT INTO OEUVRE VALUES ('OEU5', 'Les amants', '1928', '54x73', 'SAL1', 'ART4', 'Surrealisme');
INSERT INTO OEUVRE VALUES ('OEU6', 'Tempete de neige en mer', '1842', '91x122', 'SAL1', 'ART5', 'Romantisme');
INSERT INTO OEUVRE VALUES ('OEU8', 'Les tourbillons de Naruto au large d Awa', '1856', '32x21', 'SAL2', 'ART7', 'Ukiyo-e');
INSERT INTO OEUVRE VALUES ('OEU9', 'Nu Bleu II', '1952', '103x86', 'SAL1', 'ART16', NULL);
INSERT INTO OEUVRE VALUES ('OEU10', 'A vision of the Tomb', '1965', '91x91', 'SAL3', 'ART8', 'Surrealisme');
INSERT INTO OEUVRE VALUES ('OEU11', 'Mordor VII', '2010', '100x70', 'SAL1', 'ART9', 'Contemporain');
INSERT INTO OEUVRE VALUES ('OEU12', 'La Celestina', '1904','81x60', 'SAL1', 'ART10', 'Expressionnisme');
INSERT INTO OEUVRE VALUES ('OEU13', 'Paysage aux deux figures', '1908','60x73', NULL, 'ART10', 'Cubisme');
INSERT INTO OEUVRE VALUES ('OEU14', 'Nu couche I', '1927', '35x50x28', 'SAL1', 'ART16', NULL);
INSERT INTO OEUVRE VALUES ('OEU15', 'Jean de la Fontaine', '1785','177x127x110', 'SAL1', 'ART11', 'Neo-classicisme');
INSERT INTO OEUVRE VALUES ('OEU16', 'Biomechanoid', '2010', '58x18', 'SAL4', 'ART9', 'Contemporain');
INSERT INTO OEUVRE VALUES ('OEU17', 'The wing', '2009','176x48x48', 'SAL2', 'ART12', 'Hyperrealisme');
INSERT INTO OEUVRE VALUES ('OEU18', 'Anyanwu', '1955', '91x20x19', 'SAL3', 'ART13', 'Modernisme');
INSERT INTO OEUVRE VALUES ('OEU19', 'Atlas', NULL, '75x80x67', 'SAL3', 'ART13', 'Modernisme');
INSERT INTO OEUVRE VALUES ('OEU20', 'La vierge voilee', '1860','48', 'SAL4', 'ART14', NULL);
INSERT INTO OEUVRE VALUES ('OEU21', 'Persee avec la tete de Meduse', '1554','519', 'SAL4', 'ART15', 'Renaissance');
INSERT INTO OEUVRE VALUES ('OEU22', 'Nubian Queen', '2002', '183', NULL, 'ART9', 'Contemporain');

INSERT INTO SCULPTURE VALUES ('OEU14', 'Bronze');
INSERT INTO SCULPTURE VALUES ('OEU15', 'Marbre');
INSERT INTO SCULPTURE VALUES ('OEU16', 'Bronze');
INSERT INTO SCULPTURE VALUES ('OEU17', 'Resine');
INSERT INTO SCULPTURE VALUES ('OEU18', 'Bronze');
INSERT INTO SCULPTURE VALUES ('OEU19', 'Bronze');
INSERT INTO SCULPTURE VALUES ('OEU20', 'Marbre');
INSERT INTO SCULPTURE VALUES ('OEU21', 'Bronze');
INSERT INTO SCULPTURE VALUES ('OEU22', 'Aluminium');

INSERT INTO TABLEAU VALUES ('OEU2', 'Huile sur panneau');
INSERT INTO TABLEAU VALUES ('OEU3', 'Huile sur panneau');
INSERT INTO TABLEAU VALUES ('OEU4', 'Huile sur toile');
INSERT INTO TABLEAU VALUES ('OEU5', 'Huile sur toile');
INSERT INTO TABLEAU VALUES ('OEU6', 'Huile sur toile');
INSERT INTO TABLEAU VALUES ('OEU8', 'Impression au bloc de bois');
INSERT INTO TABLEAU VALUES ('OEU9', 'Collage');
INSERT INTO TABLEAU VALUES ('OEU10', 'Huile sur toile');
INSERT INTO TABLEAU VALUES ('OEU11', 'Acrylique sur bois');
INSERT INTO TABLEAU VALUES ('OEU12', 'Huile sur toile');
INSERT INTO TABLEAU VALUES ('OEU13', 'Huile sur toile');


--************************************* REQUÊTES ********************************************

prompt -- 1) Le nom et le matériau de toutes les sculptures dont l’artiste est Africain.
SELECT OEUVRE.NOM AS NOM_OEUVRE, MATERIAU, ARTISTE.NOM AS NOM_ARTISTE FROM SCULPTURE JOIN OEUVRE ON SCULPTURE.NUM_OEUVRE = OEUVRE.NUM_OEUVRE JOIN ARTISTE ON OEUVRE.NUM_ARTISTE = ARTISTE.NUM_ARTISTE AND NATIONALITE LIKE '%Afrique';

prompt -- 2) Le nom du courant artistique ainsi que le nombre d'œuvres qui y appartiennent, pour les courants représentés par au moins 2 œuvres.
SELECT COURANT, COUNT(COURANT) AS NOMBRE_D_OEUVRES FROM OEUVRE GROUP BY COURANT HAVING COUNT(COURANT) >= 2 ORDER BY NOMBRE_D_OEUVRES DESC;

prompt -- 3) Le nom des artistes qui ont réalisé des oeuvres de différents courants artistiques 
SELECT A1.NOM FROM ARTISTE A1 JOIN OEUVRE O1 ON A1.NUM_ARTISTE = O1.NUM_ARTISTE WHERE EXISTS ( SELECT * FROM ARTISTE A2 JOIN OEUVRE O2 ON  A2.NUM_ARTISTE = O2.NUM_ARTISTE AND A1.NUM_ARTISTE = A2.NUM_ARTISTE AND O1.COURANT <> O2.COURANT) GROUP BY A1.NUM_ARTISTE, A1.NOM;

prompt -- 4) Le nom des oeuvres exposées dans la salle qui expose le plus d’oeuvres
SELECT NOM FROM OEUVRE WHERE NUM_SALLE IN (SELECT NUM_SALLE FROM OEUVRE GROUP BY NUM_SALLE HAVING COUNT(NUM_SALLE) >= ALL(SELECT COUNT(NUM_SALLE) FROM OEUVRE GROUP BY NUM_SALLE));

prompt -- 5) Les visiteurs qui ont visité toutes les salles du musée
SELECT * FROM VISITEUR V1 WHERE NOT EXISTS ( SELECT * FROM SALLE S JOIN VISITE ON VISITE.NUM_SALLE = S.NUM_SALLE WHERE NOT EXISTS ( SELECT * FROM VISITEUR V2 JOIN VISITE ON V2.NUM_VISITEUR = VISITE.NUM_VISITEUR AND S.NUM_SALLE = VISITE.NUM_SALLE AND V1.NUM_VISITEUR = V2.NUM_VISITEUR));