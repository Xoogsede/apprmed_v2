
-- VIEW : CREATION DE TABLEAU DE PRESENTATION DES BLESSES
-- Blesses militaire
DROP VIEW militaireblesse CASCADE;

CREATE VIEW militaireblesse AS 
    SELECT 
        blesse.idblesse AS numero_blesse,
        blesse.matricule AS matricule, 
        militaire.grade || ' ' || militaire.nom || ' ' || militaire.prenom AS Grade_Nom_Prenom,
        militaire.nomunite AS unite,
        militaire.date_naissance AS date_de_naissance,
        militaire.lieu_naissance AS Lieu_de_naissance
    FROM blesse JOIN militaire USING (matricule); 

--Exemple
SELECT * FROM militaireblesse limit 1;

-- Blesse civil
DROP VIEW civilblesse;
CREATE VIEW civilblesse AS 
    SELECT 
        blesse.idblesse AS numero_blesse,
        blesse.matricule AS matricule, 
        'Mr' || ' ' || civil.nom || ' ' || civil.prenom AS Titre_Nom_Prenom,
        'CIVIL'::VARCHAR AS unite,
        civil.date_naissance AS date_de_naissance,
        civil.lieu_naissance AS Lieu_de_naissance
    FROM blesse JOIN civil USING (matricule); 

--Exemple
SELECT * FROM civilblesse;


----------------------------------------------------------------------------------------

-- Affichage d'un blesse identifie par son matricule
DROP FUNCTION afficherblesse CASCADE;
CREATE OR REPLACE FUNCTION afficherblesse(m bigint)
    RETURNS SETOF militaireblesse AS $blesse$
    BEGIN
        IF (SELECT militaire.matricule FROM militaire WHERE militaire.matricule=m) IS NOT NULL THEN
             RETURN QUERY  SELECT * FROM militaireblesse WHERE militaireblesse.matricule=m;
        ELSIF (SELECT civil.matricule FROM civil WHERE civil.matricule=m) IS NOT NULL THEN
           RETURN QUERY  SELECT * FROM civilblesse WHERE civilblesse.matricule=m;
        END IF;
        RETURN;
    END;
    $blesse$ language plpgsql;
--Exemple
SELECT * FROM afficherblesse(1000000001)
    