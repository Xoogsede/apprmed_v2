--------------------------------------------------------------------------
--Simulation
--------------------------------------------------------------------------
-- mise à zero des donnees de simulation
CREATE OR REPLACE FUNCTION effacerdonneessimu()
    RETURNS text
    AS
    $effacer_toutes_les_donnees$
    BEGIN
        SET TIMEZONE TO 'Europe/Paris';
        ALTER SEQUENCE numdemande_seq RESTART WITH 1;
        ALTER SEQUENCE numevasanseq RESTART WITH 1;
        ALTER SEQUENCE idblesseseq RESTART WITH 1;
        ALTER SEQUENCE idcivil RESTART WITH 1000000000; 

        DELETE FROM vt_en_mission;
        DELETE FROM evasan;
        DELETE FROM en_soin;
        DELETE FROM zfsante CASCADE;
        DELETE FROM demandevasan;        
        DELETE FROM donnees_blesse;
        DELETE FROM accueil_blesse_en_ZFSAN;
        DELETE FROM blesse;        
        DELETE FROM CIVIL;
        DELETE FROM accueil_blesse_en_ZFSAN;
        UPDATE disponibilite_vt SET etat='DISPO';

        INSERT INTO zfsante VALUES (1, 'UTM4321-9876',  'ZFSAN');

    RETURN 'Donnees de simulation reinitialisées !';
    END;
    $effacer_toutes_les_donnees$
    LANGUAGE plpgsql;




CREATE OR REPLACE FUNCTION ajoutblesse(n int)
    RETURNS SETOF dataset 
    AS

    $$
    DECLARE
        l int;
        r int;
        p int;
        b1 VARCHAR(10);        
    BEGIN 
        p := (SELECT COUNT(matricule) FROM ONLY MILITAIRE); -- p est le nombre de militaire dans l'unité
        for k in 1..n loop
            r:= (n*(k^3)); -- On calcule un nombre r permettant de simuler un blesser au hasard dans l'unité  
            l:= (r % p)+1 ; -- On s'assure que le nombre soit bien compris entre 1 et p. 
            b1 := (SELECT matricule FROM militaire OFFSET l LIMIT 1);
            IF b1 NOT IN (SELECT blesse.matricule FROM blesse) THEN
                IF (l % 4 = 1) THEN
                    INSERT INTO blesse VALUES (NULL, b1 ,'A', 'UTM 1'||k||'34-5'||k||'78', NOW(), NULL);
                ELSIF (l % 4 = 2) THEN    
                INSERT INTO blesse VALUES (NULL, b1 ,'B', 'UTM 123'||k||'-'||k||'678', NOW(), NULL);
                ELSE
                    INSERT INTO blesse VALUES (NULL, b1 ,'C', 'UTM 123'||k||'-587'||k, NOW(), NULL);
                END IF;
            ELSE    
                b1 := (SELECT matricule FROM militaire WHERE matricule NOT IN (SELECT matricule FROM blesse) LIMIT 1);
                INSERT INTO blesse VALUES (NULL, b1 ,'A', 'UTM 1'||k||'34-5'||k||'78', NOW(), NULL);
            END IF;
        end loop;
    end; 
    $$ language plpgsql;

CREATE OR REPLACE FUNCTION ajoutdemandevasan(unite_elementaire VARCHAR, coordonneutm VARCHAR)
    RETURNS SETOF demandevasan 
    AS
    $ajoutdemandevasan$
    BEGIN 
        INSERT INTO demandevasan VALUES (NULL, unite_elementaire, coordonneutm, NULL, NULL, NULL, NULL);
    END;
    $ajoutdemandevasan$ 
    LANGUAGE plpgsql;




delete from individu CASCADE;
delete from pays CASCADE;
delete from type_vt CASCADE;
---------------------------------------------------------------------------------------------------------
-- TEST FONCTIONS 
---------------------------------------------------------------------------------------------------------
-- mise à zero des donnees des tableaux
SELECT effacerdonneessimu();

\COPY salle_soin FROM 'C:\Users\abdi-\Documents\Cours\M2\Stage\Projet stage\Bases de donnees\monapp\donnees_CSV\salle_soin.csv' DELIMITER ',' CSV HEADER;
UPDATE salle_soin SET typesoin = 'HOS' WHERE idsalle <=80;
UPDATE salle_soin SET typesoin = 'BO' WHERE idsalle BETWEEN 81 AND 90;
UPDATE salle_soin SET typesoin = 'REA' WHERE idsalle > 90;
UPDATE salle_soin SET capacite = ARRAY[]::bigint[];

-- Simulation de n blessés 
SELECT ajoutblesse(10);
SELECT * FROM blesse ORDER BY idblesse;

--Ajout de la zone fonctionnelle santé (deja fait dans la fonction de reinitialisation)
SELECT * FROM zfsante LIMIT 5;

-- Simulation de demande EVASAN 
SELECT ajoutdemandevasan('CIE'::VARCHAR, '31T FL 6790 9730'::VARCHAR);
SELECT ajoutdemandevasan('1CMC'::VARCHAR, 'UTM 0003-0009'::VARCHAR);
SELECT * FROM demandevasan;
SELECT * FROM blesse ORDER BY idblesse;
SELECT * FROM donnees_blesse ORDER BY idblesse;

-- Simulation d'envoi d'EVASAN
SELECT envoi_evasan(1);
SELECT envoi_evasan(2);
SELECT * FROM evasan;
SELECT * FROM disponibilite_vt;
SELECT * FROM vt_en_mission;

-- Simulation de ramassage des blessés d'une unité en une fois
SELECT ramassage_blesses_unite('1CMC', 2);
SELECT * FROM evasan;
SELECT * FROM blesse ORDER BY idblesse;
SELECT * FROM donnees_blesse ORDER BY idblesse;

-- Simulation de ramassage de blessé un par un
SELECT ramassage_blesse('1488301689', 1);
SELECT * FROM evasan;
SELECT * FROM blesse ORDER BY idblesse;
SELECT * FROM donnees_blesse ORDER BY idblesse;

-- Simulation de livraison des blessés d'une unité en une fois
SELECT livraison_blesses_unite(2);
SELECT * FROM accueil_blesse_en_ZFSAN;
SELECT * FROM disponibilite_vt;
SELECT * FROM vt_en_mission;

-- Simulation de livraison de blessé un par un
SELECT livraison_de_blesse(1488301689, 1);
SELECT * FROM accueil_blesse_en_ZFSAN;
SELECT * FROM disponibilite_vt;
SELECT * FROM vt_en_mission;

-- Simulation d'affecation de blessé aux salles de soin
UPDATE salle_soin SET capacite = ARRAY[]::bigint[];
SELECT * FROM salle_soin order by idsalle LIMIT 15;
SELECT mettre_en_soin(2,12);
SELECT mettre_en_soin(1, 8);
SELECT * FROM en_soin;
SELECT * FROM salle_soin ORDER BY idsalle LIMIT 15;
SELECT * FROM accueil_blesse_en_ZFSAN;
SELECT mettre_en_soin(9, 8);

############################################################################################
