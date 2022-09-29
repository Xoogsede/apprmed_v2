--Reglage du temps du heure locale
SET TIMEZONE TO 'Europe/Paris'

-- Ajout_blesse_militaire
CREATE OR REPLACE FUNCTION nouveau_blesse(matricule_blesse anyelement, categorieabc VARCHAR(1), coordonneutm_blesse VARCHAR = NULL)
    RETURNS SETOF blesse
    AS
    $nouveau_blesse$
    DECLARE 
        unite VARCHAR;
        matriculedublesse VARCHAR(10);
        coordonneesutmblesse VARCHAR ;
    BEGIN
        IF matricule_blesse IS NOT NULL THEN
            matriculedublesse := (SELECT LPAD(CAST(matricule_blesse AS varchar), 10, '0')) ;
        END IF;

        IF coordonneutm_blesse IS NULL THEN
            coordonneesutmblesse := (SELECT coordonneutm FROM zfsante WHERE libeletype = 'ZFSAN');
        ELSE
            coordonneesutmblesse := (SELECT CAST(coordonneutm_blesse AS varchar));
        END IF;
        
        unite := (SELECT unite_elementaire FROM militaire WHERE matricule= matricule_blesse::VARCHAR);
        
        INSERT INTO blesse VALUES (NULL, matriculedublesse, categorieabc, coordonneesutmblesse, NOW(), null, unite, NULL);
    END;
    $nouveau_blesse$ LANGUAGE plpgsql;


--Fonction envoi EVASAN
CREATE OR REPLACE FUNCTION envoi_evasan(numero_demande_evasan int)
    RETURNS SETOF evasan 
    AS 
    $envoi_evasan$
    DECLARE
        capcite_necessaire int;
        capacit_blesse_A_necessaire int;
        coordonneutm_depart VARCHAR;
        coordonneutm_arrivee VARCHAR;
        unite_elementaire VARCHAR;
        capacite_transport_A_dispo int := 0 ;
        capacite_transport_B_dispo int := 0 ;
        capacite_transport_C_dispo int := 0 ;
        vecteurs_transports_evasan VARCHAR[] = ARRAY[]::VARCHAR[];
        vecteur_transport_dispo VARCHAR;
        numero_evasan int;
         
    BEGIN        
        
        IF numero_demande_evasan IS NULL THEN
            RAISE EXCEPTION 'Numero de demande EVASAN ne peut être vide';
        ELSIF numero_demande_evasan NOT IN (SELECT numdemande FROM demandevasan) THEN
            RAISE NOTICE 'Numero de demande EVASAN n''existe pas';
        ELSIF numero_demande_evasan IN (SELECT evasan.numdemande FROM evasan) THEN
            RAISE NOTICE 'Numero de demande EVASAN deja pris en compte';
        ELSIF (SELECT nblesseA + nblesseB + nblesseC FROM demandevasan WHERE  numdemande=numero_demande_evasan) = 0 THEN
            RAISE NOTICE 'Aucun blesse à evacuer, vérifier le besoin !';
        ELSE
            capcite_necessaire          = (SELECT nblesseA + nblesseB + nblesseC FROM demandevasan WHERE  numdemande=numero_demande_evasan);
            capacit_blesse_A_necessaire =  (SELECT nblesseA FROM demandevasan WHERE  numdemande=numero_demande_evasan);
            
            IF (SELECT DISTINCT etat FROM disponibilite_vt WHERE etat = 'DISPO') IS NULL  THEN 
                RAISE EXCEPTION 'Aucun vehicule disponible pour la mission';          
            END IF;

            FOR vecteur_transport_dispo IN (SELECT idvt FROM disponibilite_vt WHERE etat = 'DISPO') LOOP
                IF capacite_transport_A_dispo > capacit_blesse_A_necessaire AND capacite_transport_C_dispo > capcite_necessaire THEN
                    EXIT;
                ELSE
                    vecteurs_transports_evasan := array_append(vecteurs_transports_evasan, vecteur_transport_dispo);
                    capacite_transport_A_dispo := capacite_transport_A_dispo +  (SELECT capa FROM vecteur_transport WHERE idvt=vecteur_transport_dispo);
                    capacite_transport_B_dispo := capacite_transport_B_dispo +  (SELECT capb FROM vecteur_transport WHERE idvt=vecteur_transport_dispo);
                    capacite_transport_C_dispo := capacite_transport_C_dispo +  (SELECT capc FROM vecteur_transport WHERE idvt=vecteur_transport_dispo);
                END IF;
            END LOOP;
            
            IF capacite_transport_C_dispo < capcite_necessaire THEN
                RAISE EXCEPTION 'Capacite d''evacuation insuffisante';
            ELSE
                coordonneutm_depart  := (SELECT zfsante.coordonneutm FROM zfsante WHERE libeletype = 'ZFSAN');
                
                coordonneutm_arrivee := (SELECT demandevasan.coordonneutm FROM demandevasan WHERE numdemande = numero_demande_evasan);

                INSERT INTO evasan VALUES(nextval('numevasanseq'), numero_demande_evasan, NOW(), 
                                                coordonneutm_depart, coordonneutm_arrivee, capacite_transport_C_dispo, NULL, NULL);
                
                numero_evasan := (SELECT numevasan FROM evasan WHERE numdemande = numero_demande_evasan);
                
                FOREACH vecteur_transport_dispo IN ARRAY vecteurs_transports_evasan LOOP
                    INSERT INTO vt_en_mission VALUES (numero_evasan, vecteur_transport_dispo);
                    UPDATE disponibilite_vt SET etat = 'EN MISSION' WHERE idvt = vecteur_transport_dispo;
                END LOOP;
            END IF;
        END IF;
    END;
    $envoi_evasan$ 
    LANGUAGE plpgsql;




--Fonction arrivée sur le front pour le ramassage des blesse

CREATE OR REPLACE FUNCTION gdh_arrivee_au_front(numero_evasan bigint)
    RETURNS VOID
    AS
    $$
    BEGIN
        SET TIMEZONE TO 'Europe/Paris';
        IF numero_evasan IN (SELECT numevasan FROM evasan) THEN
        UPDATE evasan SET gdharrivefront=NULL, gdhdepartfront=null, blessevacue = ARRAY[]::VARCHAR[];
            IF (SELECT gdharrivefront FROM evasan WHERE numevasan = numero_evasan) IS NULL THEN              
                UPDATE evasan  SET gdharrivefront = NOW() 
                    WHERE numevasan = numero_evasan ; 
            END IF;
        END IF;
    END;
    $$
    LANGUAGE plpgsql;

------------------------------------------------------------------------------------------------------------
-- RAMASSAGE BLESSES
------------------------------------------------------------------------------------------------------------
--Fonction récupération de tous les blesses de l'unite en une fois 

DROP FUNCTION ramassage_blesses_unite;
CREATE OR REPLACE FUNCTION ramassage_blesses_unite(ramasser_unite_elementaire VARCHAR, numero_evasan bigint)
    RETURNS SETOF evasan
    AS
    $ramassage_ue$
    DECLARE
        nouveau_blesse VARCHAR(10);
        blesses_evacues VARCHAR[] := ARRAY[]::VARCHAR[];
    BEGIN
        SET TIMEZONE TO 'Europe/Paris';
        -- S'assuer que l'heure d'arriver sur zone soit saisie.
        IF (SELECT gdharrivefront FROM evasan WHERE numevasan = numero_evasan) IS NULL THEN              
            UPDATE evasan  SET gdharrivefront = NOW() 
                WHERE numevasan = numero_evasan ; 
        END IF;

        -- Ajout des blessés dans au tableau d'EVASAN  
        IF (SELECT blessevacue FROM evasan WHERE numevasan = numero_evasan) IS NULL THEN 
            FOR nouveau_blesse IN (SELECT matricule FROM blesse 
                JOIN demandevasan USING (numdemande) 
                WHERE demandevasan.unite_elementaire = ramasser_unite_elementaire AND
                numdemande = (SELECT numdemande FROM evasan where numevasan = numero_evasan))
            LOOP        
                blesses_evacues := array_append(blesses_evacues, nouveau_blesse);
            END LOOP;
                   
            UPDATE evasan SET blessevacue = blesses_evacues WHERE numevasan = numero_evasan;

            -- Saisie heure d'évacuation
            UPDATE evasan  SET gdhdepartfront = NOW() 
                WHERE numevasan = numero_evasan ; 

            -- Mise à jour évacuation dans le tableau des blesses
            UPDATE blesse  SET gdhevacue = NOW()  
                WHERE blesse.gdhevacue IS NULL AND numdemande IN 
                (SELECT numdemande FROM evasan WHERE numevasan = numero_evasan) ; 
        END IF;
    END;
    $ramassage_ue$
    LANGUAGE plpgsql;




----------------------------------------------------------------------------------------

--Fonction récupération  un blesse à la fois

DROP FUNCTION ramassage_blesse;
CREATE OR REPLACE FUNCTION ramassage_blesse(matricule_blesse VARCHAR(10), numero_evasan bigint)
    RETURNS SETOF evasan
    AS
    $ramassage_ue$
    DECLARE
        nouveau_blesse VARCHAR(10);
        blesses_evacues VARCHAR[] := ARRAY[]::VARCHAR[];
    BEGIN
        
        IF matricule_blesse NOT IN (SELECT matricule FROM blesse) THEN
            RAISE EXCEPTION 'Individu inconnu comme blesse, veuillez l''enregistrer comme blesse avant de l''evacuer';
        END IF;

        SET TIMEZONE TO 'Europe/Paris';
        -- S'assuer que l'heure d'arriver sur zone soit saisie.
        IF (SELECT gdharrivefront FROM evasan WHERE numevasan = numero_evasan) IS NULL THEN              
            UPDATE evasan  SET gdharrivefront = NOW() 
                WHERE numevasan = numero_evasan; 
        END IF;

        -- Ajout du blessé dans au tableau d'EVASAN  
        IF (SELECT blessevacue FROM evasan WHERE numevasan = numero_evasan) IS NULL 
            OR (matricule_blesse != ALL((SELECT blessevacue FROM evasan WHERE numevasan = numero_evasan)::VARCHAR[]) AND 
            (SELECT cardinality(blessevacue) FROM evasan WHERE numevasan = numero_evasan) < (SELECT capacite FROM evasan WHERE numevasan = numero_evasan)) THEN
                
                UPDATE evasan SET blessevacue = array_append(blessevacue, matricule_blesse) WHERE numevasan = numero_evasan;

            -- Saisie heure d'évacuation
            UPDATE evasan  SET gdhdepartfront = NOW() 
                WHERE numevasan = numero_evasan ; 
            -- Mise à jour évacuation dans le tableau des blesses
            FOR nouveau_blesse IN (SELECT matricule FROM blesse WHERE gdhevacue > NOW()-'00:40:00'::time OR gdhevacue IS NULL) 
            LOOP
                IF nouveau_blesse = ANY((SELECT blessevacue FROM evasan WHERE numevasan =  numero_evasan)::VARCHAR[]) THEN
                    UPDATE blesse  SET gdhevacue = NOW()  
                        WHERE matricule = nouveau_blesse;
                END IF;
            END LOOP;
        
        END IF;
    END;
    $ramassage_ue$
    LANGUAGE plpgsql;






----------------------------------------------------------------------------------------

--Fonction depart du front pour la ZFSAN avec les blesse
UPDATE evasan SET gdharrivefront=NULL, gdhdepartfront=null, blessevacue = ARRAY[]::VARCHAR[];
CREATE OR REPLACE FUNCTION gdh_depart_du_front(numero_evasan bigint)
    RETURNS VOID
    AS
    $$
    BEGIN
        SET TIMEZONE TO 'Europe/Paris';
        IF ((SELECT gdhdepartfront FROM evasan WHERE numevasan = numero_evasan) < NOW ()- '00:01:00'::time AND 
        (SELECT blessevacue FROM evasan WHERE numevasan = numero_evasan) IS NOT NULL) THEN
            UPDATE evasan  SET gdhdepartfront = NOW() 
                WHERE numevasan = numero_evasan ; 
        END IF;
    END;
    $$
    LANGUAGE plpgsql;




-- FONCTION CONNEXION 



------------------------------------------------------------------------------------------------------------
-- LIVRASON BLESSES EN ZFSAN
------------------------------------------------------------------------------------------------------------
--Fonction livraison de tous les blesses d'une EVASAN en une fois 

DROP FUNCTION livraison_blesses_unite;
CREATE OR REPLACE FUNCTION livraison_blesses_unite(numero_evasan bigint)
    RETURNS SETOF evasan
    AS
    $livraison_ue$
    DECLARE
        nouveau_blesse VARCHAR(10);  
    BEGIN
        SET TIMEZONE TO 'Europe/Paris';
        -- Livraison de tous les blesse en salle d'attente soin.
        IF (numero_evasan IN (SELECT numevasan FROM evasan)) THEN 
            
            FOREACH nouveau_blesse IN ARRAY (SELECT blessevacue FROM evasan WHERE numevasan = numero_evasan) LOOP
                IF nouveau_blesse IN (SELECT matricule FROM blesse WHERE idblesse IN (SELECT idblesse FROM accueil_blesse_en_ZFSAN)) THEN
                    RAISE EXCEPTION 'Blesses de l''unite deja livres';
                ELSE
                    INSERT INTO accueil_blesse_en_ZFSAN SELECT NULL, NULL, NULL, idblesse, categorieabc, NOW() FROM blesse WHERE matricule = nouveau_blesse;    
                END IF;
            END LOOP;

            -- Mise à jour des disponibilité des vt suite à cette livraison
            UPDATE disponibilite_vt SET etat = 'DISPO' WHERE idvt IN (SELECT idvt FROM vt_en_mission WHERE numevasan = numero_evasan);

            -- Mise à jour des vt en mission
            DELETE FROM vt_en_mission WHERE numevasan = numero_evasan;
            
            
        END IF;
    END;
    $livraison_ue$
    LANGUAGE plpgsql;



----------------------------------------------------------------------------------------

--Fonction livraison d'un blesse à la fois

DROP FUNCTION livraison_de_blesse;
CREATE OR REPLACE FUNCTION livraison_de_blesse(matriculeblesse anycompatible, numero_evasan bigint)
    RETURNS SETOF accueil_blesse_en_ZFSAN
    AS
    $livraison_de_blesse$
    DECLARE
        nouveau_blesse VARCHAR(10);
        matricule_blesse VARCHAR(10);
        nblesse_livre int := 0;
       
    BEGIN
        IF (SELECT pg_typeof(matriculeblesse) = pg_typeof(1000000000::bigint)) THEN
            matricule_blesse := CAST(matriculeblesse AS VARCHAR(10));
        ELSE
            matricule_blesse := matriculeblesse ;
        END IF;
        
        IF numero_evasan IN (SELECT numevasan FROM evasan) THEN 
            IF (SELECT matricule_blesse = ANY((SELECT blessevacue FROM evasan 
            WHERE numevasan = numero_evasan)::VARCHAR[]) AND
                (SELECT idblesse FROM blesse WHERE matricule = matricule_blesse) NOT IN 
                (SELECT idblesse FROM accueil_blesse_en_ZFSAN))THEN
                    INSERT INTO accueil_blesse_en_ZFSAN SELECT NULL, NULL, NULL, idblesse, categorieabc, NOW() FROM blesse 
                    WHERE matricule = matricule_blesse;    
            ELSIF (SELECT idblesse FROM blesse WHERE matricule = matricule_blesse) IN 
                (SELECT idblesse FROM accueil_blesse_en_ZFSAN) THEN
                    RAISE NOTICE 'Blesse deja accuilli';
            ELSE
                    RAISE NOTICE 'Le blessé n''est pas dans cet EVASAN';
            END IF;

            FOREACH nouveau_blesse IN ARRAY (SELECT blessevacue FROM evasan WHERE numevasan = numero_evasan) 
            LOOP
                IF ((SELECT idblesse FROM blesse WHERE matricule = nouveau_blesse) IN (SELECT idblesse FROM accueil_blesse_en_ZFSAN)) THEN
                    nblesse_livre := nblesse_livre + 1;
                END IF;
            END LOOP;
            
            IF (SELECT cardinality(blessevacue) FROM evasan WHERE numevasan = numero_evasan) = nblesse_livre THEN
                -- Mise à jour des disponibilité des vt suite à cette livraison
                UPDATE disponibilite_vt SET etat = 'DISPO' WHERE idvt IN (SELECT idvt FROM vt_en_mission WHERE numevasan = numero_evasan);

                -- Mise à jour des vt en mission
                DELETE FROM vt_en_mission WHERE numevasan = numero_evasan;
            END IF;
            
        END IF;
    END;
    $livraison_de_blesse$
    LANGUAGE plpgsql;



------------------------------------------------------------------------------------------------------------
--Fonction mettre le blesse en salle de soin adaptee

DROP FUNCTION mettre_en_soin;
CREATE OR REPLACE FUNCTION mettre_en_soin(identifant_blesse bigint, salle_de_soin integer)
    RETURNS SETOF en_soin
    AS
    $mettre_en_soin$
    DECLARE
        identifiantblesse VARCHAR;
    BEGIN
        identifiantblesse := CAST(identifant_blesse AS VARCHAR);
        -- On verifie l'existance du numero de salle de soin
        IF (salle_de_soin IN (SELECT idsalle FROM salle_soin)) THEN 
            
            -- Verification que la capacite de la salle est respectee
            IF ((SELECT cardinality(capacite) FROM salle_soin WHERE idsalle=salle_de_soin) < 2) THEN 

                -- Si l'identifiant saisie est l'identifiant blesse (non le matricule)
                -- Verification que l'identifiant du blesse existe et qu'il est en zone fonctionnelle sante
                IF identifant_blesse IN ((SELECT idblesse FROM attente_soin)  
                UNION (SELECT idblesse FROM accueil_blesse_en_ZFSAN)) THEN
                 
                    -- On verifie que le blesse n'est pas deja en soin.
                    -- S'il ne l'est pas on l'affecte à la salle de soin demandee 
                    IF identifant_blesse NOT IN (SELECT idblesse FROM en_soin) THEN
                        INSERT INTO en_soin VALUES (identifant_blesse, salle_de_soin);
                        RAISE NOTICE 'insere ! ';
                        UPDATE salle_soin SET capacite = array_append(capacite, identifant_blesse) WHERE idsalle = salle_de_soin;
                    ELSE
                        UPDATE salle_soin SET capacite = array_remove(capacite, identifant_blesse) 
                            WHERE idsalle = (SELECT idsalle FROM en_soin WHERE idblesse = identifant_blesse);
                        UPDATE salle_soin SET capacite = array_append(capacite, identifant_blesse) 
                            WHERE idsalle = salle_de_soin;                        
                        UPDATE en_soin SET idsalle = salle_de_soin 
                            WHERE idblesse = identifant_blesse;
                        RAISE NOTICE 'Mis a jour ! ';
                    END IF;
                -- Si l'identifiant saisie est  le matricule on recherche le dernier identifiant blesse correspondant
                ELSIF identifiantblesse IN ((SELECT matricule FROM blesse 
                    WHERE idblesse IN (SELECT idblesse FROM attente_soin 
                    UNION SELECT idblesse FROM accueil_blesse_en_ZFSAN))) THEN
                        IF (SELECT idblesse FROM blesse WHERE matricule = identifiantblesse AND idblesse IN 
                            (SELECT idblesse FROM attente_soin 
                            UNION SELECT idblesse FROM accueil_blesse_en_ZFSAN)) NOT IN 
                            (SELECT idblesse FROM en_soin) THEN
                                INSERT INTO en_soin SELECT idblesse, salle_de_soin FROM blesse 
                                    WHERE matricule = identifant_bless AND idblesse IN
                                    (SELECT idblesse FROM attente_soin 
                                    UNION SELECT idblesse FROM accueil_blesse_en_ZFSAN);
                                UPDATE salle_soin SET capacite = array_append(capacite, (SELECT idblesse FROM en_soin 
                                    WHERE idblesse NOT IN (SELECT idblesse FROM salle_soin WHERE idsalle = salle_de_soin))) WHERE idsalle = salle_de_soin; 
                                RAISE NOTICE 'insere grace au matricule ! ';
                        ELSE
                            UPDATE salle_soin SET capacite = array_remove(capacite, (idblesse = (SELECT idblesse FROM blesse 
                                WHERE matricule = identifiantblesse AND idblesse IN 
                                    (SELECT idblesse FROM attente_soin 
                                        UNION SELECT idblesse FROM accueil_blesse_en_ZFSAN 
                                        UNION SELECT idblesse FROM en_soin)))) 
                                WHERE idsalle = (SELECT idsalle FROM en_soin 
                                        WHERE idblesse = (idblesse = (SELECT idblesse FROM blesse 
                                            WHERE matricule = identifiantblesse AND idblesse IN 
                                (SELECT idblesse FROM attente_soin 
                                    UNION SELECT idblesse FROM accueil_blesse_en_ZFSAN 
                                    UNION SELECT idblesse FROM en_soin))));
                            
                            UPDATE salle_soin SET capacite = array_append(capacite, (idblesse = (SELECT idblesse FROM blesse 
                                WHERE matricule = identifiantblesse AND idblesse IN 
                                (SELECT idblesse FROM attente_soin 
                                UNION SELECT idblesse FROM accueil_blesse_en_ZFSAN 
                                UNION SELECT idblesse FROM en_soin)))) 
                                    WHERE idsalle = salle_de_soin;
                            
                            UPDATE en_soin SET idsalle = salle_de_soin WHERE idblesse = (SELECT idblesse FROM blesse 
                                WHERE matricule = identifiantblesse AND idblesse IN 
                                (SELECT idblesse FROM attente_soin 
                                UNION SELECT idblesse FROM accueil_blesse_en_ZFSAN 
                                UNION SELECT idblesse FROM en_soin));
                            RAISE NOTICE 'Mis a jour grace matricule ! ';
                        END IF;
                ELSE 
                    RAISE EXCEPTION 'Blesse inconnu, veuillez l''enregister';
                END IF;
            ELSIF salle_de_soin IN (SELECT idsalle FROM en_soin) THEN
                RAISE NOTICE 'Salle de soin aucupee, choisir une autre ou mettre le patient en salle d''attente soin';
            END IF;
        END IF;
    END;
    $mettre_en_soin$
    LANGUAGE plpgsql;

---------------------------------------------------------------------------------------------------------------
CREATE FUNCTION check_password(uname TEXT, pass TEXT)
    RETURNS BOOLEAN AS $$
    DECLARE passed BOOLEAN;
    BEGIN
            SELECT  (pwd = $2) INTO passed
            FROM    pwds
            WHERE   username = $1;

            RETURN passed;
    END;
    $$  LANGUAGE plpgsql
        SECURITY DEFINER
        -- Set a secure search_path: trusted schema(s), then 'pg_temp'.
        SET search_path = admin, pg_temp;
