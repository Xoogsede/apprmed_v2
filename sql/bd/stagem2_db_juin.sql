--
-- PostgreSQL database dump
--

-- Dumped from database version 14.2
-- Dumped by pg_dump version 14.2

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: dataset; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.dataset AS (
	idblesse integer,
	mat bigint,
	a text,
	t timestamp without time zone,
	x timestamp without time zone,
	y timestamp without time zone
);


ALTER TYPE public.dataset OWNER TO postgres;

--
-- Name: affecter_numdemandevasan_au_blesse(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.affecter_numdemandevasan_au_blesse() RETURNS trigger
    LANGUAGE plpgsql
    AS $$

    BEGIN    

    UPDATE blesse SET numdemande = NEW.numdemande 
        FROM demandevasan WHERE demandevasan.unite_elementaire = blesse.unite_elementaire 
        AND blesse.numdemande IS NULL;
        
        RETURN NEW;
    END;
    $$;


ALTER FUNCTION public.affecter_numdemandevasan_au_blesse() OWNER TO postgres;

--
-- Name: ajout_blesse(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.ajout_blesse() RETURNS trigger
    LANGUAGE plpgsql
    AS $$

    BEGIN    

        -- V‚rification que les champs obligatoires soient compl‚t‚s

    
        IF NEW.matricule IS NULL THEN
            RAISE EXCEPTION 'Le matricule ne doit pas ˆtre vide';
        END IF;

        IF NEW.categorieabc IS NULL THEN
            RAISE EXCEPTION 'La cat‚gorie bless‚ ne pas ˆtre vide';
        END IF;

        IF NEW.coordonneesutmblesse IS NULL THEN
            RAISE EXCEPTION 'Les coordonn‚es UTM du bless‚ ne peuvent ˆtre vide';
        END IF;

        IF NEW.gdhblessure IS NULL THEN
            NEW.gdhblessure := NOW();
        END IF;

        IF NEW.matricule IN (SELECT matricule FROM militaire) THEN       
            NEW.unite_elementaire := (SELECT unite_elementaire FROM militaire WHERE matricule=NEW.matricule);
        ELSE 
            NEW.unite_elementaire := 'CIVIL';
        END IF;

        IF NEW.idblesse IS NULL THEN
            NEW.idblesse := (SELECT nextval('idblesseseq'));
        END IF;

        RETURN NEW;
    END;
    $$;


ALTER FUNCTION public.ajout_blesse() OWNER TO postgres;

--
-- Name: ajout_demandevasan(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.ajout_demandevasan() RETURNS trigger
    LANGUAGE plpgsql
    AS $$

    BEGIN    

        -- V‚rification que les champs obligatoires soient compl‚t‚s    
        IF NEW.unite_elementaire IS NULL THEN
            RAISE EXCEPTION 'Unite ‚l‚mentaire ne peut ˆtre vide';
        END IF;

        IF NEW.coordonneutm IS NULL THEN
            RAISE EXCEPTION 'Les coordonn‚es UTM de ramassage ne peuvent ˆtre vides';
        END IF;

        IF NEW.numdemande IS NULL THEN
            NEW.numdemande := nextval('numdemande_seq');
        END IF;

        IF NEW.gdhdemande IS NULL THEN
            NEW.gdhdemande := NOW(); 
        END IF;

        IF NEW.nblesseA IS NULL THEN
            NEW.nblesseA := (SELECT COUNT(*) FROM blesse WHERE numdemande IS NULL AND categorieabc='A' AND unite_elementaire= NEW.unite_elementaire);
        END IF;

        IF NEW.nblesseB IS NULL THEN
            NEW.nblesseB := (SELECT COUNT(*) FROM blesse WHERE numdemande IS NULL AND categorieabc='B' AND unite_elementaire= NEW.unite_elementaire);
        END IF;

        IF NEW.nblesseC IS NULL THEN
            NEW.nblesseC := (SELECT COUNT(*) FROM blesse WHERE numdemande IS NULL AND categorieabc='C' AND unite_elementaire= NEW.unite_elementaire);
        END IF;

        IF ((NEW.nblesseA + NEW.nblesseB + NEW.nblesseC  = 0) OR  (NEW.nblesseA IS NULL AND NEW.nblesseB IS NULL AND NEW.nblesseC IS NULL))  THEN
            RAISE NOTICE 'Aucun blesse a evacuer, verifiez le besoin en evacuation !';
            RETURN NULL;
        ELSE
            INSERT INTO destination VALUES (NEW.coordonneutm, NEW.unite_elementaire) ON CONFLICT (coordonneutm) DO UPDATE SET libele=NEW.unite_elementaire;
            RETURN NEW;
        END IF;      
    END;
    $$;


ALTER FUNCTION public.ajout_demandevasan() OWNER TO postgres;

--
-- Name: ajout_zone_fonctionnelle_sante(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.ajout_zone_fonctionnelle_sante() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
    BEGIN
        IF NEW.idzfsante IS NULL THEN
            RAISE EXCEPTION 'L''identifiant de la zone fonctionnelle sante ne peut etre vide';
        ELSIF NEW.idzfsante IN (SELECT idzfsante FROM zfsante) THEN
            RAISE EXCEPTION 'Zone fonctionnelle sante deja enregistree';
        END IF;

        IF NEW.coordonneutm IS NULL THEN
            RAISE EXCEPTION 'Les coordonnees UTM de la zone fonctionnelle sante ne peuvent etre vides';
        ELSIF NEW.coordonneutm IN (SELECT coordonneutm FROM zfsante) AND NEW.idzfsante NOT IN (SELECT idzfsante FROM zfsante)  THEN
            RAISE EXCEPTION 'Il y a deja une zone fonctionnelle a ces coordonnees';
        END IF;
        RETURN NEW;
    END;
    $$;


ALTER FUNCTION public.ajout_zone_fonctionnelle_sante() OWNER TO postgres;

--
-- Name: ajoutblesse(integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.ajoutblesse(n integer) RETURNS SETOF public.dataset
    LANGUAGE plpgsql
    AS $$
    DECLARE
        l int;
        r int;
        p int;
        b1 VARCHAR(10);        
    BEGIN 
        p := (SELECT COUNT(matricule) FROM ONLY MILITAIRE); -- p est le nombre de militaire dans l'unit‚
        for k in 1..n loop
            r:= (n*(k^3)); -- On calcule un nombre r permettant de simuler un blesser au hasard dans l'unit‚  
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
    $$;


ALTER FUNCTION public.ajoutblesse(n integer) OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: demandevasan; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.demandevasan (
    numdemande bigint NOT NULL,
    unite_elementaire character varying(150) NOT NULL,
    coordonneutm character varying NOT NULL,
    nblessea integer,
    nblesseb integer,
    nblessec integer,
    gdhdemande time with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.demandevasan OWNER TO postgres;

--
-- Name: ajoutdemandevasan(character varying, character varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.ajoutdemandevasan(unite_elementaire character varying, coordonneutm character varying) RETURNS SETOF public.demandevasan
    LANGUAGE plpgsql
    AS $$
    BEGIN 
        INSERT INTO demandevasan VALUES (NULL, unite_elementaire, coordonneutm, NULL, NULL, NULL, NULL);
    END;
    $$;


ALTER FUNCTION public.ajoutdemandevasan(unite_elementaire character varying, coordonneutm character varying) OWNER TO postgres;

--
-- Name: check_password(text, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.check_password(uname text, pass text) RETURNS boolean
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'admin', 'pg_temp'
    AS $_$
    DECLARE passed BOOLEAN;
    BEGIN
            SELECT  (pwd = $2) INTO passed
            FROM    pwds
            WHERE   username = $1;

            RETURN passed;
    END;
    $_$;


ALTER FUNCTION public.check_password(uname text, pass text) OWNER TO postgres;

--
-- Name: civil_ajout(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.civil_ajout() RETURNS trigger
    LANGUAGE plpgsql
    AS $$

    BEGIN    

        -- V‚rification que les champs obligatoires soient compl‚t‚s    
        IF NEW.nom IS NULL THEN 
            RAISE EXCEPTION 'Le nom ne peut ˆtre vide';
        END IF;        

        IF NEW.prenom IS NULL THEN
            RAISE EXCEPTION 'Pr‚nom ne peut ˆtre vide';
        END IF;

        IF NEW.categoriehf IS NULL THEN 
            RAISE EXCEPTION 'La cat‚gorie homme ou femme ne peut ˆtre vide'; 
        END IF;

        IF NEW.date_naissance IS NULL THEN
            RAISE EXCEPTION 'La date de naissance ne peut ˆtre vide';
        END IF;

        IF NEW.lieu_naissance IS NULL THEN
            RAISE EXCEPTION 'Le lieu de naissance ne peut ˆtre vide';
        END IF;

        IF NEW.pays IS NULL THEN
            RAISE EXCEPTION 'pays ne peut ˆtre vide';
        END IF;

        IF NEW.adresse IS NULL THEN
            NEW.adresse := 'Adresse non renseign‚e. ';
        END IF;

        -- Verification que le civil ne soit pas deja enregiste dans la base de donnee
        IF (EXISTS (SELECT *
        FROM civil 
        WHERE nom=NEW.nom AND prenom=New.prenom AND date_naissance=NEW.date_naissance AND lieu_naissance=NEW.lieu_naissance))
        THEN 
            RAISE EXCEPTION 'Civil d‚j… enregistr‚';
        END IF;

        -- affectation d'un numero de matricule commencant par 1 000 000 000
        IF NEW.matricule IS NULL THEN
            NEW.matricule := (SELECT LPAD(CAST(nextval('idcivil') AS varchar), 10, '0'));
        END IF;

        -- Insertion des donnees dans le tableau parent
        IF NEW.matricule NOT IN (SELECT matricule FROM ONLY individu) THEN
            INSERT INTO individu
            VALUES (NEW.matricule, NEW.nom, NEW.prenom, NEW.categoriehf, NEW.date_naissance, NEW.lieu_naissance);
        END IF;
        
        RETURN NEW;
    END;
    $$;


ALTER FUNCTION public.civil_ajout() OWNER TO postgres;

--
-- Name: disponibilite_vt_initiale(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.disponibilite_vt_initiale() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
    BEGIN
        IF NEW.idvt NOT IN (SELECT idvt FROM disponibilite_vt) THEN
                INSERT INTO disponibilite_vt
                VALUES (NEW.idvt, 'DISPO');
        END IF;
        RETURN NEW;
    END;
    $$;


ALTER FUNCTION public.disponibilite_vt_initiale() OWNER TO postgres;

--
-- Name: donnees_blesse(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.donnees_blesse() RETURNS trigger
    LANGUAGE plpgsql
    AS $$

    BEGIN
        IF (NEW.idblesse IN (SELECT idblesse FROM donnees_blesse)) THEN
            UPDATE donnees_blesse SET gdhblessure = NEW.gdhblessure, gdhevacue = NEW.gdhevacue WHERE idblesse= NEW.idblesse;
        ELSE 
            INSERT INTO donnees_blesse VALUES (NEW.idblesse, NEW.gdhblessure, NEW.gdhevacue) ON CONFLICT (idblesse) DO UPDATE SET gdhblessure = NEW.gdhblessure, gdhevacue = NEW.gdhevacue; 
            --INSERT INTO donnees_blesse SELECT NEW.idblesse, NEW.gdhblessure, NEW.gdhevacue FROM blesse WHERE NEW.idblesse NOT IN (select idblesse from donnees_blesse);           
            --INSERT INTO destination VALUES (NEW.coordonneutm, NEW.unite_elementaire) ON CONFLICT (coordonneutm) DO UPDATE SET libele=NEW.unite_elementaire;
        END IF;
        RETURN NEW;
    END;
    $$;


ALTER FUNCTION public.donnees_blesse() OWNER TO postgres;

--
-- Name: donnees_initiales_vecteur_transport(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.donnees_initiales_vecteur_transport() RETURNS text
    LANGUAGE plpgsql
    AS $$
    
    BEGIN
        ----------------------------------------------------------------------------------------------------------------------------------------------------
        -- Partie matariel
        ----------------------------------------------------------------------------------------------------------------------------------------------------

        --inserer les donnees vehicule dans le tableau de disponibilite 
        INSERT INTO disponibilite_vt
        (WITH insert_dispo AS (
            SELECT idvt FROM vecteur_transport

        )
        SELECT 
            *
        FROM insert_dispo);

        UPDATE disponibilite_vt SET etat='DISPO';

        RETURN 'Vecteurs transport disponibles correctement ins‚r‚s ! ';
    END;

    $$;


ALTER FUNCTION public.donnees_initiales_vecteur_transport() OWNER TO postgres;

--
-- Name: effacerdonneessimu(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.effacerdonneessimu() RETURNS text
    LANGUAGE plpgsql
    AS $$
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

        UPDATE disponibilite_vt SET etat='DISPO';

        INSERT INTO zfsante VALUES (1, 'UTM4321-9876',  'ZFSAN');

    RETURN 'Donnees de simulation reinitialis‚es !';
    END;
    $$;


ALTER FUNCTION public.effacerdonneessimu() OWNER TO postgres;

--
-- Name: en_soin(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.en_soin() RETURNS trigger
    LANGUAGE plpgsql
    AS $$

    BEGIN
        
        IF NEW.idblesse IS NULL THEN
            RAISE EXCEPTION 'Saisir l''identifiant du blesse';
        END IF;

        IF NEW.idsalle IS NULL THEN
            RAISE EXCEPTION 'Saisir le numero de la salle de soin';
        END IF;

        IF NEW.idsalle NOT IN (SELECT idsalle FROM salle_soin) THEN
            RAISE EXCEPTION 'Numero de salle de soin inconnu ! ';
        END IF;
        RETURN NEW;
    END;
    $$;


ALTER FUNCTION public.en_soin() OWNER TO postgres;

--
-- Name: evasan; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.evasan (
    numevasan bigint NOT NULL,
    numdemande bigint NOT NULL,
    gdhdepartzfsan time with time zone NOT NULL,
    coordonneutm text NOT NULL,
    coordonneutm1 text NOT NULL,
    capacite integer NOT NULL,
    gdharrivefront timestamp with time zone,
    gdhdepartfront timestamp with time zone,
    blessevacue character varying[]
);


ALTER TABLE public.evasan OWNER TO postgres;

--
-- Name: envoi_evasan(integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.envoi_evasan(numero_demande_evasan integer) RETURNS SETOF public.evasan
    LANGUAGE plpgsql
    AS $$
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
            RAISE EXCEPTION 'Numero de demande EVASAN ne peut ˆtre vide';
        ELSIF numero_demande_evasan NOT IN (SELECT numdemande FROM demandevasan) THEN
            RAISE NOTICE 'Numero de demande EVASAN n''existe pas';
        ELSIF numero_demande_evasan IN (SELECT evasan.numdemande FROM evasan) THEN
            RAISE NOTICE 'Numero de demande EVASAN deja pris en compte';
        ELSIF (SELECT nblesseA + nblesseB + nblesseC FROM demandevasan WHERE  numdemande=numero_demande_evasan) = 0 THEN
            RAISE NOTICE 'Aucun blesse … evacuer, v‚rifier le besoin !';
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
                coordonneutm_depart  := (SELECT destination.coordonneutm FROM destination WHERE libele = 'ZFSAN');
                
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
    $$;


ALTER FUNCTION public.envoi_evasan(numero_demande_evasan integer) OWNER TO postgres;

--
-- Name: gdh_arrivee_au_front(bigint); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.gdh_arrivee_au_front(numero_evasan bigint) RETURNS void
    LANGUAGE plpgsql
    AS $$
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
    $$;


ALTER FUNCTION public.gdh_arrivee_au_front(numero_evasan bigint) OWNER TO postgres;

--
-- Name: gdh_depart_du_front(bigint); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.gdh_depart_du_front(numero_evasan bigint) RETURNS void
    LANGUAGE plpgsql
    AS $$
    BEGIN
        SET TIMEZONE TO 'Europe/Paris';
        IF ((SELECT gdhdepartfront FROM evasan WHERE numevasan = numero_evasan) < NOW ()- '00:01:00'::time AND 
        (SELECT blessevacue FROM evasan WHERE numevasan = numero_evasan) IS NOT NULL) THEN
            UPDATE evasan  SET gdhdepartfront = NOW() 
                WHERE numevasan = numero_evasan ; 
        END IF;
    END;
    $$;


ALTER FUNCTION public.gdh_depart_du_front(numero_evasan bigint) OWNER TO postgres;

--
-- Name: livraison_blesses_unite(bigint); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.livraison_blesses_unite(numero_evasan bigint) RETURNS SETOF public.evasan
    LANGUAGE plpgsql
    AS $$
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

            -- Mise … jour des disponibilit‚ des vt suite … cette livraison
            UPDATE disponibilite_vt SET etat = 'DISPO' WHERE idvt IN (SELECT idvt FROM vt_en_mission WHERE numevasan = numero_evasan);

            -- Mise … jour des vt en mission
            DELETE FROM vt_en_mission WHERE numevasan = numero_evasan;
            
            
        END IF;
    END;
    $$;


ALTER FUNCTION public.livraison_blesses_unite(numero_evasan bigint) OWNER TO postgres;

--
-- Name: zfsante; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.zfsante (
    idzfsante integer NOT NULL,
    coordonneutm character varying NOT NULL,
    libeletype character varying(50)
);


ALTER TABLE public.zfsante OWNER TO postgres;

--
-- Name: accueil_blesse_en_zfsan; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.accueil_blesse_en_zfsan (
    idblesse bigint NOT NULL,
    categorieabc character varying(1) NOT NULL,
    gdharrivee timestamp with time zone DEFAULT now() NOT NULL
)
INHERITS (public.zfsante);


ALTER TABLE public.accueil_blesse_en_zfsan OWNER TO postgres;

--
-- Name: livraison_de_blesse(anycompatible, bigint); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.livraison_de_blesse(matriculeblesse anycompatible, numero_evasan bigint) RETURNS SETOF public.accueil_blesse_en_zfsan
    LANGUAGE plpgsql
    AS $$
    DECLARE
        nouveau_blesse VARCHAR(10);
        matricule_blesse VARCHAR(10);
        nblesse_livre int := 0;
       
    BEGIN
        IF (SELECT pg_typeof(matriculeblesse) = pg_typeof(1000000000::bigint)) THEN
            matricule_blesse := CAST(matriculeblesse AS VARCHAR(10));
            RAISE NOTICE 'matricule converti';
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
                    RAISE NOTICE 'Le bless‚ n''est pas dans cet EVASAN';
            END IF;

            FOREACH nouveau_blesse IN ARRAY (SELECT blessevacue FROM evasan WHERE numevasan = numero_evasan) 
            LOOP
                IF ((SELECT idblesse FROM blesse WHERE matricule = nouveau_blesse) IN (SELECT idblesse FROM accueil_blesse_en_ZFSAN)) THEN
                    nblesse_livre := nblesse_livre + 1;
                END IF;
            END LOOP;
            
            IF (SELECT cardinality(blessevacue) FROM evasan WHERE numevasan = numero_evasan) = nblesse_livre THEN
                -- Mise … jour des disponibilit‚ des vt suite … cette livraison
                UPDATE disponibilite_vt SET etat = 'DISPO' WHERE idvt IN (SELECT idvt FROM vt_en_mission WHERE numevasan = numero_evasan);

                -- Mise … jour des vt en mission
                DELETE FROM vt_en_mission WHERE numevasan = numero_evasan;
            END IF;
            
        END IF;
    END;
    $$;


ALTER FUNCTION public.livraison_de_blesse(matriculeblesse anycompatible, numero_evasan bigint) OWNER TO postgres;

--
-- Name: en_soin; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.en_soin (
    idblesse bigint NOT NULL,
    idsalle integer
);


ALTER TABLE public.en_soin OWNER TO postgres;

--
-- Name: mettre_en_soin(bigint, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.mettre_en_soin(identifant_blesse bigint, salle_de_soin integer) RETURNS SETOF public.en_soin
    LANGUAGE plpgsql
    AS $$
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
                    -- S'il ne l'est pas on l'affecte … la salle de soin demandee 
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
    $$;


ALTER FUNCTION public.mettre_en_soin(identifant_blesse bigint, salle_de_soin integer) OWNER TO postgres;

--
-- Name: militaire_ajout(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.militaire_ajout() RETURNS trigger
    LANGUAGE plpgsql
    AS $$

    BEGIN    

        -- V‚rification que les champs obligatoires soient compl‚t‚s
        IF NEW.pays IS NULL THEN
            RAISE EXCEPTION 'pays ne peut ˆtre vide';
        END IF;
        
        IF NEW.nomarmee IS NULL THEN
            RAISE EXCEPTION 'Armee ne peut ˆtre vide';
        END IF;

        IF NEW.nomunite IS NULL THEN
            RAISE EXCEPTION 'Unit‚ ou r‚giment ne peut ˆtre vide';
        END IF;
        
        IF NEW.div_bri IS NULL THEN
            RAISE EXCEPTION 'division ou brigade ne peut ˆtre vide';
        END IF;

        IF NEW.unite_elementaire IS NULL THEN
            RAISE EXCEPTION 'Unit‚ ‚l‚mentaire ne peut ˆtre vide';
        END IF;

        IF NEW.matricule IS NULL THEN
            RAISE EXCEPTION 'Matricule ne peut ˆtre vide';
        ELSE
            NEW.matricule := (SELECT LPAD(CAST(NEW.matricule AS varchar), 10, '0'));
        END IF;

        IF NEW.nom IS NULL THEN 
            RAISE EXCEPTION 'Le nom ne peut ˆtre vide';
        END IF;        

        IF NEW.prenom IS NULL THEN
            RAISE EXCEPTION 'Pr‚nom ne peut ˆtre vide';
        END IF;

        IF NEW.categoriehf IS NULL THEN 
            RAISE EXCEPTION 'La cat‚gorie homme ou femme ne peut ˆtre vide'; 
        END IF;

        IF NEW.date_naissance IS NULL THEN
            RAISE EXCEPTION 'La date de naissance ne peut ˆtre vide';
        END IF;

        IF NEW.lieu_naissance IS NULL THEN
            RAISE EXCEPTION 'Le lieu de naissance ne peut ˆtre vide';
        END IF;

        IF NEW.grade IS NULL THEN
            RAISE EXCEPTION 'Le grade ne peut ˆtre vide';
        END IF;

        -- Auto remplisage de la categorie de militaire suivant le grade fourni
        IF NEW.grade IN ('GA', 'GCA', 'GBR', 'COL', 'LCL',  'CDT', 'CBA', 'CEN', 'CES', 'CNE', 'LTN', 'SLT', 'ASP') THEN
            NEW.catmilitaire := 'OFFICIER';
        ELSE 
            NEW.catmilitaire := 'NON-OFFICIER';
        END IF;

        -- Insertion des donnees dans les tableau parents 
        IF NEW.matricule NOT IN (SELECT matricule FROM ONLY individu) THEN
            INSERT INTO individu  
            VALUES (NEW.matricule, NEW.nom, NEW.prenom, NEW.categoriehf, NEW.date_naissance, NEW.lieu_naissance);
        END IF;

        IF NEW.unite_elementaire NOT IN (SELECT unite_elementaire FROM ONLY unite_elementaire) THEN
            INSERT INTO unite_elementaire  
            VALUES (NEW.codepays, NEW.pays, NEW.nomarmee, NEW.nomunite, NEW.div_bri, NEW.unite_elementaire);
        END IF;

         IF NEW.nomunite NOT IN (SELECT nomunite FROM ONLY unite) THEN
            INSERT INTO unite
            VALUES (NEW.codepays, NEW.pays, NEW.nomarmee, NEW.nomunite, NEW.div_bri);
        END IF;

         IF NEW.div_bri NOT IN (SELECT div_bri FROM ONLY div_bri) THEN
            INSERT INTO div_bri
            VALUES (NEW.codepays, NEW.pays, NEW.nomarmee, NEW.div_bri);
        END IF;

        IF NEW.nomarmee NOT IN (SELECT nomarmee FROM ONLY armee) THEN
            INSERT INTO armee
            VALUES (NEW.codepays, NEW.pays, NEW.nomarmee);
        END IF;

        IF UPPER(NEW.pays) NOT IN (SELECT UPPER(pays) FROM ONLY pays) THEN
            NEW.codepays := 'AA';
            INSERT INTO pays
            VALUES (NEW.codepays, NEW.pays);
        ELSE 
            NEW.codepays := (SELECT codepays FROM ONLY pays WHERE UPPER(pays)=UPPER(NEW.pays));
        END IF;

        RETURN NEW;
    END;
    $$;


ALTER FUNCTION public.militaire_ajout() OWNER TO postgres;

--
-- Name: present_en_zfsan(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.present_en_zfsan() RETURNS trigger
    LANGUAGE plpgsql
    AS $$

    BEGIN
         IF NEW.idzfsante IS NULL THEN
            NEW.idzfsante := (SELECT idzfsante FROM ONLY zfsante WHERE libeletype = 'ZFSAN');
        END IF;

        IF NEW.coordonneutm IS NULL THEN
            NEW.coordonneutm := (SELECT coordonneutm FROM ONLY zfsante WHERE libeletype = 'ZFSAN');
        END IF;

        IF NEW.libeletype IS NULL THEN
            NEW.libeletype := (SELECT libeletype FROM ONLY zfsante WHERE libeletype = 'ZFSAN');
        END IF;
        RETURN NEW;
    END;
    $$;


ALTER FUNCTION public.present_en_zfsan() OWNER TO postgres;

--
-- Name: ramassage_blesse(character varying, bigint); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.ramassage_blesse(matricule_blesse character varying, numero_evasan bigint) RETURNS SETOF public.evasan
    LANGUAGE plpgsql
    AS $$
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

        -- Ajout du bless‚ dans au tableau d'EVASAN  
        IF (SELECT blessevacue FROM evasan WHERE numevasan = numero_evasan) IS NULL 
            OR (matricule_blesse != ALL((SELECT blessevacue FROM evasan WHERE numevasan = numero_evasan)::VARCHAR[]) AND 
            (SELECT cardinality(blessevacue) FROM evasan WHERE numevasan = numero_evasan) < (SELECT capacite FROM evasan WHERE numevasan = numero_evasan)) THEN
                
                UPDATE evasan SET blessevacue = array_append(blessevacue, matricule_blesse) WHERE numevasan = numero_evasan;

            -- Saisie heure d'‚vacuation
            UPDATE evasan  SET gdhdepartfront = NOW() 
                WHERE numevasan = numero_evasan ; 
            -- Mise … jour ‚vacuation dans le tableau des blesses
            FOR nouveau_blesse IN (SELECT matricule FROM blesse WHERE gdhevacue > NOW()-'00:40:00'::time OR gdhevacue IS NULL) 
            LOOP
                IF nouveau_blesse = ANY((SELECT blessevacue FROM evasan WHERE numevasan =  numero_evasan)::VARCHAR[]) THEN
                    UPDATE blesse  SET gdhevacue = NOW()  
                        WHERE matricule = nouveau_blesse;
                END IF;
            END LOOP;
        
        END IF;
    END;
    $$;


ALTER FUNCTION public.ramassage_blesse(matricule_blesse character varying, numero_evasan bigint) OWNER TO postgres;

--
-- Name: ramassage_blesses_unite(character varying, bigint); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.ramassage_blesses_unite(ramasser_unite_elementaire character varying, numero_evasan bigint) RETURNS SETOF public.evasan
    LANGUAGE plpgsql
    AS $$
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

        -- Ajout des bless‚s dans au tableau d'EVASAN  
        IF (SELECT blessevacue FROM evasan WHERE numevasan = numero_evasan) IS NULL THEN 
            FOR nouveau_blesse IN (SELECT matricule FROM blesse 
                JOIN demandevasan USING (numdemande) 
                WHERE demandevasan.unite_elementaire = ramasser_unite_elementaire)
            LOOP        
                blesses_evacues := array_append(blesses_evacues, nouveau_blesse);
            END LOOP;
                   
            UPDATE evasan SET blessevacue = blesses_evacues WHERE numevasan = numero_evasan;

            -- Saisie heure d'‚vacuation
            UPDATE evasan  SET gdhdepartfront = NOW() 
                WHERE numevasan = numero_evasan ; 

            -- Mise … jour ‚vacuation dans le tableau des blesses
            UPDATE blesse  SET gdhevacue = NOW()  
                WHERE blesse.gdhevacue IS NULL AND numdemande IN 
                (SELECT numdemande FROM evasan WHERE numevasan = numero_evasan) ; 
        END IF;
    END;
    $$;


ALTER FUNCTION public.ramassage_blesses_unite(ramasser_unite_elementaire character varying, numero_evasan bigint) OWNER TO postgres;

--
-- Name: vecteur_transport_ajout(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.vecteur_transport_ajout() RETURNS trigger
    LANGUAGE plpgsql
    AS $$

    BEGIN    

        -- V‚rification que les champs obligatoires soient compl‚t‚s
        IF NEW.idtypevt IS NULL THEN
            RAISE EXCEPTION 'Identifiant type de vecteur transport ne peut ˆtre vide';
        END IF;
        
        IF NEW.idcat IS NULL THEN
            RAISE EXCEPTION 'Identifiant categorie vecteur transport ne peut ˆtre vide';
        END IF;

        IF NEW.idcapacite IS NULL THEN
            RAISE EXCEPTION 'Identifiant de la capacit‚ d''‚vacution ne peut ˆtre vide';
        END IF;
        
        IF NEW.idvt IS NULL THEN
            RAISE EXCEPTION 'L''identifiant du vecteur transport ne peut ˆtre vide';
        END IF;

        -- Insertion des donnees dans les tableau parents 
        IF NEW.idtypevt NOT IN (SELECT idtypevt FROM ONLY type_vt) THEN
            INSERT INTO type_vt  
            VALUES (NEW.idtypevt);
        END IF;

        IF NEW.idcat NOT IN (SELECT idcat FROM ONLY categorie_vt) THEN
            INSERT INTO categorie_vt  
            VALUES (NEW.idtypevt, NEW.idcat, NEW.libelecategorie, NEW.modecirculation);
        END IF;

         IF NEW.idcapacite NOT IN (SELECT idcapacite FROM ONLY capacite_transport) THEN
            INSERT INTO capacite_transport
            VALUES (NEW.idtypevt, NEW.idcat, NEW.libelecategorie, NEW.modecirculation, 
                    NEW.idcapacite, NEW.capa, NEW.capb, NEW.capc);
        END IF;
        RETURN NEW;
    END;
    $$;


ALTER FUNCTION public.vecteur_transport_ajout() OWNER TO postgres;

--
-- Name: alertes_niveaux_produit; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.alertes_niveaux_produit (
    idproduit integer NOT NULL,
    qtemin integer DEFAULT 0 NOT NULL,
    qtemax integer NOT NULL,
    datelimite date NOT NULL
);


ALTER TABLE public.alertes_niveaux_produit OWNER TO postgres;

--
-- Name: pays; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.pays (
    codepays character varying(2) NOT NULL,
    pays text NOT NULL
);


ALTER TABLE public.pays OWNER TO postgres;

--
-- Name: armee; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.armee (
    codepays character varying(2),
    pays text,
    nomarmee text NOT NULL
)
INHERITS (public.pays);


ALTER TABLE public.armee OWNER TO postgres;

--
-- Name: attente_soin; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.attente_soin (
    idblesse bigint NOT NULL,
    categorieabc character varying(1) NOT NULL,
    gdharrivee timestamp with time zone DEFAULT now() NOT NULL
)
INHERITS (public.zfsante);


ALTER TABLE public.attente_soin OWNER TO postgres;

--
-- Name: idblesseseq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.idblesseseq
    START WITH 1
    INCREMENT BY 1
    MINVALUE 0
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.idblesseseq OWNER TO postgres;

--
-- Name: blesse; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.blesse (
    idblesse integer DEFAULT nextval('public.idblesseseq'::regclass) NOT NULL,
    matricule character varying(10) NOT NULL,
    categorieabc character varying(1) NOT NULL,
    coordonneesutmblesse character varying(50) NOT NULL,
    gdhblessure timestamp with time zone NOT NULL,
    gdhevacue timestamp with time zone,
    unite_elementaire character varying(150),
    numdemande bigint
);


ALTER TABLE public.blesse OWNER TO postgres;

--
-- Name: type_vt; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.type_vt (
    idtypevt character varying(9) NOT NULL
);


ALTER TABLE public.type_vt OWNER TO postgres;

--
-- Name: categorie_vt; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.categorie_vt (
    idcat character varying(3) NOT NULL,
    libelecategorie text,
    modecirculation character varying(2)
)
INHERITS (public.type_vt);


ALTER TABLE public.categorie_vt OWNER TO postgres;

--
-- Name: capacite_transport; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.capacite_transport (
    idcapacite integer NOT NULL,
    capa integer NOT NULL,
    capb integer NOT NULL,
    capc integer NOT NULL
)
INHERITS (public.categorie_vt);


ALTER TABLE public.capacite_transport OWNER TO postgres;

--
-- Name: idcivil; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.idcivil
    START WITH 1000000000
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.idcivil OWNER TO postgres;

--
-- Name: individu; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.individu (
    matricule character varying(10) DEFAULT nextval('public.idcivil'::regclass) NOT NULL,
    nom text NOT NULL,
    prenom text NOT NULL,
    categoriehf text NOT NULL,
    date_naissance date NOT NULL,
    lieu_naissance text
);


ALTER TABLE public.individu OWNER TO postgres;

--
-- Name: civil; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.civil (
    matricule character varying(10) DEFAULT nextval('public.idcivil'::regclass),
    pays character varying(50),
    adresse character varying(50)
)
INHERITS (public.individu);


ALTER TABLE public.civil OWNER TO postgres;

--
-- Name: destination; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.destination (
    coordonneutm character varying NOT NULL,
    libele character varying
);


ALTER TABLE public.destination OWNER TO postgres;

--
-- Name: disponibilite_vt; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.disponibilite_vt (
    idvt character varying(50) NOT NULL,
    etat text DEFAULT 'DISPO'::text NOT NULL
);


ALTER TABLE public.disponibilite_vt OWNER TO postgres;

--
-- Name: div_bri; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.div_bri (
    div_bri text NOT NULL
)
INHERITS (public.armee);


ALTER TABLE public.div_bri OWNER TO postgres;

--
-- Name: donnees_blesse; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.donnees_blesse (
    idblesse integer NOT NULL,
    gdhblessure timestamp with time zone NOT NULL,
    gdhevacue timestamp with time zone
);


ALTER TABLE public.donnees_blesse OWNER TO postgres;

--
-- Name: donnees_salle_soin; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.donnees_salle_soin (
    idsalle integer NOT NULL,
    gdhentree date,
    gdhsortie date
);


ALTER TABLE public.donnees_salle_soin OWNER TO postgres;

--
-- Name: magasinsante; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.magasinsante (
    idmagasin integer NOT NULL,
    typemagasin character varying
)
INHERITS (public.zfsante);


ALTER TABLE public.magasinsante OWNER TO postgres;

--
-- Name: unite; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.unite (
    codepays character varying(2),
    pays text,
    nomarmee text,
    nomunite character varying NOT NULL,
    div_bri text
)
INHERITS (public.div_bri);


ALTER TABLE public.unite OWNER TO postgres;

--
-- Name: unite_elementaire; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.unite_elementaire (
    unite_elementaire character varying(150) NOT NULL
)
INHERITS (public.unite);


ALTER TABLE public.unite_elementaire OWNER TO postgres;

--
-- Name: militaire; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.militaire (
    grade text NOT NULL,
    catmilitaire text
)
INHERITS (public.unite_elementaire, public.individu);


ALTER TABLE public.militaire OWNER TO postgres;

--
-- Name: numdemande_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.numdemande_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.numdemande_seq OWNER TO postgres;

--
-- Name: numdemande_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.numdemande_seq OWNED BY public.demandevasan.numdemande;


--
-- Name: numevasanseq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.numevasanseq
    START WITH 0
    INCREMENT BY 1
    MINVALUE 0
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.numevasanseq OWNER TO postgres;

--
-- Name: produit; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.produit (
    idproduit integer NOT NULL,
    idmagasin integer NOT NULL,
    nomproduit text NOT NULL,
    qteproduit integer NOT NULL,
    conditionstockage text NOT NULL,
    dureestockage date NOT NULL
);


ALTER TABLE public.produit OWNER TO postgres;

--
-- Name: salle_soin; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.salle_soin (
    idsalle integer NOT NULL,
    typesoin character varying(50),
    capacite bigint[] DEFAULT ARRAY[]::bigint[]
)
INHERITS (public.zfsante);


ALTER TABLE public.salle_soin OWNER TO postgres;

--
-- Name: sortiestrategiquezfsan; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.sortiestrategiquezfsan (
    idblesse bigint NOT NULL,
    gdhdemandesortie time with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.sortiestrategiquezfsan OWNER TO postgres;

--
-- Name: vecteur_transport; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.vecteur_transport (
    idvt character varying(50) NOT NULL,
    appellationvt character varying(100)
)
INHERITS (public.capacite_transport);


ALTER TABLE public.vecteur_transport OWNER TO postgres;

--
-- Name: vt_en_mission; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.vt_en_mission (
    numevasan integer NOT NULL,
    idvt character varying(50) NOT NULL
);


ALTER TABLE public.vt_en_mission OWNER TO postgres;

--
-- Name: militaire matricule; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.militaire ALTER COLUMN matricule SET DEFAULT nextval('public.idcivil'::regclass);


--
-- Data for Name: accueil_blesse_en_zfsan; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.accueil_blesse_en_zfsan (idzfsante, coordonneutm, libeletype, idblesse, categorieabc, gdharrivee) FROM stdin;
1	UTM4321-9876	ZFSAN	1	C	2022-06-08 01:47:05.554927+00
1	UTM4321-9876	ZFSAN	2	A	2022-06-08 01:47:05.554927+00
1	UTM4321-9876	ZFSAN	9	A	2022-06-08 01:47:05.554927+00
1	UTM4321-9876	ZFSAN	10	A	2022-06-08 01:47:05.554927+00
1	UTM4321-9876	ZFSAN	8	A	2022-06-08 01:47:31.177419+00
\.


--
-- Data for Name: alertes_niveaux_produit; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.alertes_niveaux_produit (idproduit, qtemin, qtemax, datelimite) FROM stdin;
\.


--
-- Data for Name: armee; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.armee (codepays, pays, nomarmee) FROM stdin;
FR	France	Armee de Terre
\.


--
-- Data for Name: attente_soin; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.attente_soin (idzfsante, coordonneutm, libeletype, idblesse, categorieabc, gdharrivee) FROM stdin;
\.


--
-- Data for Name: blesse; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.blesse (idblesse, matricule, categorieabc, coordonneesutmblesse, gdhblessure, gdhevacue, unite_elementaire, numdemande) FROM stdin;
3	0406703310	C	UTM 1233-5873	2022-06-08 01:46:37.393589+00	\N	4CMC	\N
4	5786047245	A	UTM 1434-5478	2022-06-08 01:46:37.393589+00	\N	2CMC	\N
5	8952965957	C	UTM 1235-5875	2022-06-08 01:46:37.393589+00	\N	4CMC	\N
6	4635053644	A	UTM 1634-5678	2022-06-08 01:46:37.393589+00	\N	4CMC	\N
7	3044660831	C	UTM 1237-5877	2022-06-08 01:46:37.393589+00	\N	2CMC	\N
1	5913367685	C	UTM 1231-5871	2022-06-08 01:46:37.393589+00	2022-06-08 01:46:37.971443+00	1CMC	2
2	4982362521	A	UTM 1234-5278	2022-06-08 01:46:37.393589+00	2022-06-08 01:46:37.971443+00	1CMC	2
9	0861922336	A	UTM 1934-5978	2022-06-08 01:46:37.393589+00	2022-06-08 01:46:37.971443+00	1CMC	2
10	1664863109	A	UTM 11034-51078	2022-06-08 01:46:37.393589+00	2022-06-08 01:46:37.971443+00	1CMC	2
8	1488301689	A	UTM 1834-5878	2022-06-08 01:46:37.393589+00	2022-06-08 01:46:38.146412+00	CCL	1
\.


--
-- Data for Name: capacite_transport; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.capacite_transport (idtypevt, idcat, libelecategorie, modecirculation, idcapacite, capa, capb, capc) FROM stdin;
Blinde	VAB	VEHICULE A L'AVANT BLINDE	VR	1	3	3	4
\.


--
-- Data for Name: categorie_vt; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.categorie_vt (idtypevt, idcat, libelecategorie, modecirculation) FROM stdin;
Blinde	VAB	VEHICULE A L'AVANT BLINDE	VR
\.


--
-- Data for Name: civil; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.civil (matricule, nom, prenom, categoriehf, date_naissance, lieu_naissance, pays, adresse) FROM stdin;
\.


--
-- Data for Name: demandevasan; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.demandevasan (numdemande, unite_elementaire, coordonneutm, nblessea, nblesseb, nblessec, gdhdemande) FROM stdin;
1	CCL	UTM 1123-9999	1	0	0	03:46:37.53447+02
2	1CMC	UTM 0003-0009	3	0	1	03:46:37.573938+02
\.


--
-- Data for Name: destination; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.destination (coordonneutm, libele) FROM stdin;
UTM1234-5678	1Cie
UTM4321-9876	ZFSAN
UTM 1231-0987	1CMC
UTM 1123-9999	CCL
UTM 0003-0009	1CMC
\.


--
-- Data for Name: disponibilite_vt; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.disponibilite_vt (idvt, etat) FROM stdin;
2G4WB52K811567655	DISPO
3C6LD5AT5CG114462	DISPO
1GYS3FEJ9CR055500	DISPO
JN1CV6AR6FM439707	DISPO
WAUML44E95N806464	DISPO
1G6YV34A255131288	DISPO
JH4DC54853C056667	DISPO
JTJHY7AX1F4154859	DISPO
WAUVT58E83A065006	DISPO
1G6DF577290201463	DISPO
5GADV23L26D293374	DISPO
5NPEB4AC5CH561091	DISPO
2C3CDZBT5FH447526	DISPO
WBAWV1C58AP425805	DISPO
4A31K5DF6BE965670	DISPO
WAUDF98E16A196504	DISPO
WAUFL44D82N508936	DISPO
WUAGNAFG5BN749511	DISPO
1G6DN57U870444197	DISPO
1FMEU2DEXAU722980	DISPO
\.


--
-- Data for Name: div_bri; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.div_bri (codepays, pays, nomarmee, div_bri) FROM stdin;
FR	France	Armee de Terre	COMLOG
\.


--
-- Data for Name: donnees_blesse; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.donnees_blesse (idblesse, gdhblessure, gdhevacue) FROM stdin;
3	2022-06-08 01:46:37.393589+00	\N
4	2022-06-08 01:46:37.393589+00	\N
5	2022-06-08 01:46:37.393589+00	\N
6	2022-06-08 01:46:37.393589+00	\N
7	2022-06-08 01:46:37.393589+00	\N
1	2022-06-08 01:46:37.393589+00	2022-06-08 01:46:37.971443+00
2	2022-06-08 01:46:37.393589+00	2022-06-08 01:46:37.971443+00
9	2022-06-08 01:46:37.393589+00	2022-06-08 01:46:37.971443+00
10	2022-06-08 01:46:37.393589+00	2022-06-08 01:46:37.971443+00
8	2022-06-08 01:46:37.393589+00	2022-06-08 01:46:38.146412+00
\.


--
-- Data for Name: donnees_salle_soin; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.donnees_salle_soin (idsalle, gdhentree, gdhsortie) FROM stdin;
\.


--
-- Data for Name: en_soin; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.en_soin (idblesse, idsalle) FROM stdin;
2	12
1	10
9	10
8	5
\.


--
-- Data for Name: evasan; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.evasan (numevasan, numdemande, gdhdepartzfsan, coordonneutm, coordonneutm1, capacite, gdharrivefront, gdhdepartfront, blessevacue) FROM stdin;
2	2	03:46:37.792235+02	UTM4321-9876	UTM 0003-0009	8	2022-06-08 01:46:37.971443+00	2022-06-08 01:46:37.971443+00	{5913367685,4982362521,0861922336,1664863109}
1	1	03:46:37.753712+02	UTM4321-9876	UTM 1123-9999	4	2022-06-08 01:46:38.146412+00	2022-06-08 01:46:38.146412+00	{1488301689}
\.


--
-- Data for Name: individu; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.individu (matricule, nom, prenom, categoriehf, date_naissance, lieu_naissance) FROM stdin;
4212317095	Freeland	JÃº	F	1978-09-18	Caen
3003866575	Betteriss	IntÃ©ressant	F	1970-05-06	Ivry-sur-Seine
7273754749	Pledger	MÃ©ghane	F	1977-11-06	Lattes
7587816011	Shyram	AÃ­	M	1994-06-16	Antony
2543391878	Billion	BjÃ¶rn	M	1994-06-18	Bordeaux
8528106012	Rumbold	LÃ©one	M	1997-03-06	Annecy
6223862377	Pes	AlizÃ©e	M	1994-08-14	Reims
7485441000	Blofield	YÃ¨	F	1990-04-15	Paris 07
4330138476	Loughnan	MÃ©diamass	M	1985-04-16	Le Teil
6619571395	Cleen	UÃ²	M	1989-09-29	Reims
2262635544	Scibsey	JudicaÃ«l	M	1982-11-14	Aubenas
6688492563	Crasford	TorbjÃ¶rn	F	2001-11-02	Nantes
9572000314	Walak	YÃº	F	1960-09-22	Lille
1124119477	Coggin	DesirÃ©e	F	1967-06-26	Limoges
2593662743	Esherwood	MaÃ©na	F	1964-10-18	NÃ®mes
0202469875	Kezourec	AurÃ©lie	M	1982-02-24	Nanterre
9476590823	Luto	MÃ©lissandre	M	1978-05-04	La Rochelle
8310618069	Ebdin	AlmÃ©rinda	M	1985-02-14	Cergy-Pontoise
8050253171	Nussen	MaÃ«lann	M	1982-04-29	Roubaix
3438492377	Wasmuth	RÃ©gine	F	2002-01-09	MontÃ©limar
3370265761	Mishaw	ClÃ©a	F	1982-04-09	Gentilly
4714460714	Stockbridge	DorothÃ©e	M	1975-05-17	Paris 07
4594536697	Meece	MaÃ«ly	M	1970-09-04	Avignon
7559722474	Chestnutt	BÃ©nÃ©dicte	F	1964-02-11	Paris 12
3243208912	Swetenham	JosÃ©phine	M	1964-04-12	Paris 12
9517734018	Oppery	VÃ©ronique	M	1989-05-11	Paris 03
8829745278	Rabl	ElÃ©a	F	1997-08-15	Toulouse
4263434021	Kirton	ClÃ©a	F	1996-02-29	Carcassonne
7271539875	Godbehere	NuÃ³	F	1978-08-08	Cergy-Pontoise
0111589363	Poile	DesirÃ©e	F	2002-07-19	Saint-Herblain
4821187930	Edelheid	CÃ©cilia	F	2001-06-27	Nantes
0453553915	Spalton	MaÃ©na	F	1966-02-01	BollÃ¨ne
2482258189	Jephcott	MÃ©lissandre	M	1998-07-15	Molsheim
9334455659	McNess	GarÃ§on	M	1964-07-09	Lille
6571388138	Grzelak	PÃ²	M	1970-10-20	Suresnes
4510289510	Casillas	NÃ©hÃ©mie	M	1977-03-24	PlÃ©rin
9362930838	Auden	VÃ©rane	F	1983-06-25	Levallois-Perret
9816474174	Macvain	MÃ©n	M	1992-07-10	Brie-Comte-Robert
5657485637	Bridge	DaphnÃ©e	F	1979-05-06	Tarbes
7723871392	Carlyle	FaÃ®tes	F	1997-10-04	Annecy
2850389587	Reisenberg	PÃ²	F	1987-04-28	Agen
8132162129	Rennie	LÃ©ana	F	1990-10-27	Ã‰pinal
7950934549	Kreber	MarylÃ¨ne	F	1978-03-07	Le Blanc-Mesnil
1419681613	Hawket	MaÃ¯lys	M	1962-07-04	Paris 08
7234242481	Matten	JosÃ©e	M	1988-03-31	BagnÃ¨res-de-Bigorre
3975661003	Reignould	Ã–rjan	F	1987-08-19	Clermont-Ferrand
9901453585	Putnam	HÃ¥kan	F	1979-12-17	Paris La DÃ©fense
9334454156	Kesteven	DesirÃ©e	M	2001-09-09	Paris 14
3903668435	Hugin	LoÃ¯ca	M	1969-03-09	Ã‰lancourt
4614838383	Ranfield	ChloÃ©	M	1983-02-16	OrlÃ©ans
7865720203	Gibbe	AurÃ©lie	F	2002-12-21	La TalaudiÃ¨re
7979234308	Grills	AngÃ¨le	F	2001-12-11	OrlÃ©ans
6923860547	Worsnup	MÃ 	F	1978-11-09	Paris La DÃ©fense
4450932838	Lerwell	FaÃ®tes	M	1979-01-29	Paris La DÃ©fense
5699197664	Showl	EstÃ©e	M	1975-10-28	Rennes
2085120369	Martin	NuÃ³	M	1999-01-12	Lyon
2866719670	Duprey	AmÃ©lie	M	1966-03-10	Rouen
0110285824	Brann	RÃ©gine	F	1994-09-23	Suresnes
1654569240	Cottrill	ElÃ©onore	M	1984-10-04	Lagny-sur-Marne
8854609021	Minocchi	CÃ©lia	F	1967-10-21	Valence
1258115964	Poulden	SalomÃ©	F	1984-03-13	AlenÃ§on
9653513001	Lambrechts	MÃ©lanie	M	1970-07-18	Metz
8215215386	Lipscomb	NuÃ³	M	1976-02-07	BrÃ©tigny-sur-Orge
2317735286	Tuhy	DaphnÃ©e	F	1985-08-19	Croissy-sur-Seine
9821060226	Loker	LaurÃ¨ne	F	1978-08-02	Paris 20
1330110234	Asplin	AnaÃ«lle	F	1986-01-09	Rennes
5608978358	Looker	AmÃ©lie	M	1993-05-15	Marseille
1092918698	Nissle	TÃ¡ng	M	1987-01-17	Bordeaux
7268577915	Jarry	VÃ©rane	F	1986-05-28	Annecy
0406703310	Accombe	YÃ©nora	M	1988-01-14	Caen
4243958548	Maletratt	SalomÃ©	M	1998-02-07	Dinan
4486256174	Hargreves	CÃ©line	F	1987-03-17	Champigny-sur-Marne
2766113622	Gilleson	MÃ©linda	M	1984-01-11	Noyal-sur-Vilaine
8861431275	Menhenitt	MÃ©ryl	M	2001-10-11	Manosque
2603186299	Sherlaw	InÃ¨s	F	1984-03-27	Perpignan
3749026750	Baudino	MÃ¤rta	M	1989-08-04	Toulouse
6839631796	Patise	InÃ¨s	M	1966-09-28	Ploemeur
4966716764	Stanfield	ChloÃ©	M	1972-01-07	Versailles
3440857093	Ovitts	MarlÃ¨ne	F	1969-09-24	Maisons-Laffitte
6365096437	Capner	ZhÃ¬	F	1961-11-29	Lunel
5128647587	Honisch	EsbjÃ¶rn	M	1978-06-21	Avallon
4531198484	Dulwitch	FaÃ®tes	F	1991-03-10	Saint-Claude
6378316295	Caller	GaÃ¯a	M	1971-09-02	La Chapelle-sur-Erdre
0491451644	Olyfant	EstÃ©e	M	1994-11-27	Niort
2577530048	Vallintine	ErwÃ©i	F	1974-02-06	Rennes
4833748398	McGregor	LÃ©one	M	1963-12-09	Avignon
9611429320	Farnaby	InÃ¨s	M	1983-11-18	Paris 09
4635053644	Zapata	EdmÃ©e	M	2004-02-15	L'Union
1107341884	Vogeller	MaÃ¯lis	M	1964-11-02	AlÃ¨s
2048677657	Spellworth	PersonnalisÃ©e	M	1996-11-15	Quimper
4583370318	Matthieson	BÃ©nÃ©dicte	M	1971-04-09	Dijon
5280422622	Chiles	AloÃ¯s	M	1985-04-25	Pau
0308343999	Gasson	MÃ©ghane	F	1996-04-03	Paris 12
8425781019	Mabbot	EstÃ¨ve	M	1984-09-20	Vendargues
1800272510	Rudloff	GÃ¶rel	M	2001-12-11	Lavaur
2555150722	Upson	NadÃ¨ge	M	2004-03-20	Paris La DÃ©fense
2655315316	Mitroshinov	MaÃ«lyss	F	1984-03-23	Lyon
6703174946	Cluff	MarylÃ¨ne	M	1987-05-27	Saint-Quentin-en-Yvelines
0861922336	Schlagtmans	AmÃ©lie	M	1993-10-25	Paris 13
1664863109	Rosenschein	LorÃ¨ne	F	1972-09-03	Valence
2060293685	Accombe	AnnotÃ©s	F	1961-11-29	Mundolsheim
4692278188	Kasper	ClÃ©mence	F	1978-09-08	Istres
2086962339	Zorzoni	EstÃ¨ve	F	1991-10-29	RezÃ©
7834470469	Claridge	ErwÃ©i	F	1996-07-07	Saint-Dizier
0576570265	Dybbe	LÃ©andre	F	1982-06-26	Lillers
9720498579	Olle	FÃ©licie	F	2002-08-14	Rueil-Malmaison
0062822047	Bruinsma	Marie-noÃ«l	F	1986-09-20	Toulon
6578583637	MacCawley	MÃ©ryl	F	2003-10-18	Aubagne
7981847621	Penella	MÃ 	M	2000-12-02	AsniÃ¨res-sur-Seine
5913367685	Sign	MaÃ«lann	M	1962-12-14	Paris 01
2347881531	Warlowe	MaÃ«lyss	F	1966-08-25	Lomme
2129484654	Jopke	UÃ²	M	2003-03-25	Nantes
5832690745	Lichfield	GÃ¶ran	F	1960-12-31	Poligny
3166681353	De Bruyn	AngÃ¨le	M	1985-06-21	Poitiers
3510523997	Ornelas	AudrÃ©anne	M	1966-12-02	Villefranche-sur-Mer
2518085602	Gregoriou	Ã…slÃ¶g	F	2001-02-24	Schiltigheim
6240423971	Juanico	LÃ©one	F	1981-06-24	Chalon-sur-SaÃ´ne
3633160329	Antal	Marie-hÃ©lÃ¨ne	F	1998-12-26	Suresnes
0932812511	Flowith	CÃ©line	F	1994-09-17	Granville
8797488658	Bugler	MarlÃ¨ne	M	1966-03-13	Saint-Pierre-des-Corps
4799920219	Pencott	ClÃ©a	F	1994-05-08	Rouen
9518069247	Crighton	AndrÃ©anne	M	1965-04-25	Paris 12
2947710053	Huntingdon	AndrÃ©	F	1998-02-13	Wintzenheim
4667143967	Goodhew	KÃ¹	M	1982-07-05	Saint-Denis
1109902905	Domeny	EstÃ¨ve	M	1971-04-26	Paris La DÃ©fense
5977330340	Lightwood	IntÃ©ressant	F	1979-09-18	Cergy-Pontoise
6269198402	Hadwen	NaÃ«lle	F	1962-06-03	Saint-Pierre-des-Corps
8028925618	Staunton	MaÃ«line	M	1966-08-05	Villeneuve-la-Garenne
1209045109	Akerman	EsbjÃ¶rn	M	1960-07-19	Romorantin-Lanthenay
0260459860	Maxsted	PÃ©nÃ©lope	M	1973-05-31	Nice
9580618526	Pulbrook	StÃ©vina	F	1989-05-27	Paris 13
2768438715	McQuarter	RÃ©jane	F	1980-05-13	Montauban
7246966803	Spratling	BÃ©rengÃ¨re	M	1973-07-11	Mulhouse
2094823369	Klinck	RuÃ¬	F	1969-03-28	Wasquehal
1823024157	Veivers	DaniÃ¨le	F	1993-10-03	Nice
0999996770	Edwardes	ErwÃ©i	M	1985-10-18	Ussel
6213608044	Gosselin	FÃ¨i	F	1971-10-05	Aurillac
5873157774	Flaherty	MÃ¥rten	M	1995-08-01	Paris 04
9723036061	Anthill	LaurÃ©na	F	1993-06-10	Montpellier
4743783836	Labeuil	GarÃ§on	M	1973-03-09	Colomiers
8669664119	Licquorish	GaÃ©tane	M	1982-01-23	Nanterre
2268504387	Stansby	LÃ©onie	F	1966-12-21	Saint-DiÃ©-des-Vosges
2556101695	Hallaways	NoÃ«lla	F	1994-12-12	Tours
8008926562	Vanyukhin	Ã…sa	F	2001-03-06	Paris 15
3851234758	Noury	Marie-Ã¨ve	F	1996-06-19	FrÃ©jus
7491922368	Uden	ThÃ©rÃ¨sa	M	1994-07-24	Cagnes-sur-Mer
7106776254	Beere	MaÃ¯	F	1994-09-29	Puteaux
2743756268	McFade	AmÃ©lie	F	2000-09-07	Paris La DÃ©fense
9562469700	Colin	KÃ©vina	F	1981-01-19	Marseille
7336155359	Hollingsbee	AdÃ©laÃ¯de	F	1962-07-12	Laon
2874387886	Garshore	BÃ©atrice	M	1980-08-29	AlÃ¨s
9955507578	Umpleby	MarlÃ¨ne	M	1978-07-24	NÃ®mes
4817076356	Czajkowska	AloÃ¯s	F	1964-08-23	Laval
4206757518	Turmall	CÃ©lestine	F	1980-11-13	CrÃ©teil
0990570681	Yushkov	CÃ©cilia	F	1996-03-29	Reims
7209677461	Hatwells	ThÃ©rÃ¨sa	M	1962-12-02	Paris 10
5922628798	Hindhaugh	AdÃ¨le	M	2004-04-19	Valence
1968659390	Jaegar	ClÃ©a	M	1975-07-30	Paris 20
1772892297	Varvell	AndrÃ©e	M	1968-02-05	Nantes
7118440817	Rawll	LÃ©a	F	1977-08-17	Salon-de-Provence
8199219521	Staker	RachÃ¨le	M	1981-08-28	PÃ©rigueux
0456044906	Heeley	MÃ©diamass	F	1975-05-04	Rochefort
8563648470	Letty	RuÃ¬	M	1988-01-17	Meaux
0626111382	Hartegan	MahÃ©lie	F	1967-03-18	Perpignan
4838255705	Ivanikov	MÃ©lia	F	1990-03-09	La Roche-sur-Yon
4096899070	Slocum	RuÃ¬	F	1992-07-26	Bobigny
0856544221	Dash	SÃ©rÃ©na	F	1962-07-22	Hagondange
0289703565	Vickery	Marie-thÃ©rÃ¨se	M	1992-06-08	Amiens
9950674093	Estoile	MaÃ«lann	M	1967-10-07	MontbÃ©liard
7016562050	Lamperd	SimplifiÃ©s	M	1982-03-24	PÃ©rigny
4405111979	Bushel	MaÃ¯lys	M	1992-10-13	Ã‰tampes
0025727494	Bruggeman	NÃ©lie	M	2003-09-07	Perpignan
9256552841	Settle	MaÃ¯	F	1977-12-04	Tours
2374823032	Izatson	LÃ©one	F	1969-09-29	Paris La DÃ©fense
8282226394	Hebblethwaite	MÃ©lina	F	1996-04-03	Bastia
4716750957	Stothart	SalomÃ©	M	2002-04-26	Lens
6610952353	Braxton	MylÃ¨ne	M	1973-02-28	Cergy-Pontoise
9987346251	Mattea	MÃ¥ns	F	1988-12-09	Laxou
8371529252	Armstrong	PÃ©nÃ©lope	M	1982-08-03	Sannois
4982362521	Wackett	EstÃ©e	M	1964-08-04	Berck
8431684402	Geerits	SÃ²ng	M	1967-11-01	Perpignan
9919236705	Kelwaybamber	ZhÃ¬	M	1997-03-27	Valence
3434613102	Carress	AlmÃ©rinda	F	1967-10-03	Grenoble
9290501731	Klishin	MaÃ«lyss	M	1992-05-13	Balma
9698272623	Snoad	GaÃ¯a	F	1984-02-20	Pontarlier
8234305026	Cicconetti	ThÃ©rÃ¨se	M	1975-01-24	Versailles
8199727934	Beese	NÃ©hÃ©mie	M	1994-03-23	Valence
3270382995	Pfertner	StÃ©phanie	M	2001-02-21	Paris 12
8655116181	Westhoff	KuÃ­	M	1975-09-10	Paris La DÃ©fense
5617319345	Keary	AdÃ©laÃ¯de	M	1978-11-19	MÃ©rignac
8492314729	Chittey	EdmÃ©e	F	1990-06-11	Saint-Brieuc
4829905808	Crocetto	CunÃ©gonde	M	2003-07-23	Aubervilliers
2236059299	Kirkhouse	AndrÃ©e	F	1989-07-09	Le Perreux-sur-Marne
8083384569	Riditch	FÃ¨i	F	2003-05-18	Saint-Ã‰tienne
4286421244	Gazey	MÃ©lia	M	1972-03-14	Colombes
0916223272	Coster	MÃ¥ns	F	1995-02-04	Vincennes
4643871008	Dennick	FaÃ®tes	F	1987-09-08	Albi
2599040566	Banstead	ThÃ©rÃ¨se	M	1990-04-08	Brest
2956397583	Amott	OphÃ©lie	M	1995-09-03	Saint-LÃ´
6764955859	Petrelli	Marie-hÃ©lÃ¨ne	F	1987-08-22	Lons-le-Saunier
6410418035	Mowbray	CÃ©lestine	F	1995-09-06	AngoulÃªme
1850375240	Skaife d'Ingerthorpe	MÃ¤rta	M	1988-10-21	Le Puy-en-Velay
1438544510	Belsher	MÃ©lys	M	1987-10-18	Toulouse
6925727550	Emberson	WÃ¡	F	1976-01-27	Saumur
2295108918	Griss	YÃ³u	M	1983-04-21	Limoges
8782345864	Readwin	SÃ©rÃ©na	M	1973-05-03	Melun
1351768182	Lambard	CamÃ©lia	M	1998-10-29	Mulhouse
9041062653	Patel	Ã…ke	M	1999-03-01	OrlÃ©ans
0482352361	Goggey	ClÃ©mence	M	1974-07-12	Millau
1309110956	Maiden	MarylÃ¨ne	M	1960-06-24	Lille
8752893898	Tasseler	LÃ©onore	F	1969-09-19	La Roche-sur-Yon
9340120663	Dyche	RÃ©servÃ©s	F	1981-11-08	Toulouse
9307825769	Gowenlock	LysÃ©a	M	2002-01-27	ChÃ¢teaurenard
3010154267	Seacombe	MaÃ«lann	F	1976-11-30	BesanÃ§on
7629864531	Simenot	MÃ©gane	M	1986-09-02	Lomme
6337841727	Ambrogio	RÃ©becca	M	2003-10-13	Saint-Nazaire
2390082629	Talman	Ã–sten	M	1970-09-04	Vierzon
8027491061	Ducrow	MagdalÃ¨ne	M	1980-03-10	Cergy-Pontoise
6618256534	Blankley	StyrbjÃ¶rn	M	1971-09-22	Gap
9002526172	Blunt	LÃ i	M	1984-12-11	ChÃ¢teaudun
2536081281	Mulbry	AimÃ©e	F	1995-07-01	Auray
1534945474	Carsey	LaurÃ¨ne	M	2004-03-07	Limoges
1649880146	Arter	VÃ©nus	M	1971-01-18	Nevers
2730706941	Hanway	SolÃ¨ne	F	1991-04-26	Melun
2405270528	Blasiak	GeneviÃ¨ve	F	1985-09-28	Carpentras
5249250823	Kretchmer	BÃ¶rje	F	1972-04-18	OrlÃ©ans
7708959209	Battson	LÃ©one	M	1988-07-15	Chantilly
3726010203	Larvin	AudrÃ©anne	M	1972-08-06	Saint-LÃ´
4496290308	Quenell	NÃ©lie	M	1995-01-05	Mont-Saint-Aignan
9277406070	Capin	FÃ©licie	M	1971-09-08	Paris 15
6704395679	Goulstone	GwenaÃ«lle	M	1962-03-20	Ã‰lancourt
2773130464	Wardingley	AlmÃ©rinda	F	1974-07-16	Thaon-les-Vosges
2847566074	Budleigh	PÃ²	F	1976-09-02	Toul
9375384357	Timmes	PÃ²	F	1994-05-02	Limoges
1703634934	Lockery	GÃ©raldine	F	2000-08-18	CrÃ©teil
7908119255	Licciardi	LysÃ©a	M	1995-10-22	Digne-les-Bains
6412931147	Brastead	KuÃ­	M	1963-04-21	Domont
7350324324	Bullocke	LaurÃ¨ne	M	1988-11-02	Royan
0149103522	Treswell	InÃ¨s	M	1982-07-22	Ã‰vry
3153161798	McCullen	GÃ¶sta	F	1965-01-07	Angers
2491379430	Mayzes	NadÃ¨ge	F	1990-10-09	Sophia Antipolis
0102365911	Canwell	EloÃ¯se	F	1988-06-13	NÃ®mes
3664628969	Johnsee	Marie-noÃ«l	F	1963-03-10	Saint-Ã‰tienne
9163718103	Aldrick	SolÃ¨ne	F	1980-07-08	Noisy-le-Grand
0455145733	Ordish	LoÃ¯c	F	2003-09-22	Douarnenez
2583091034	Forber	MarylÃ¨ne	M	1973-03-20	Paris 12
8309644124	Meere	LysÃ©a	M	1992-08-27	Nantes
3068292247	Kenwrick	BÃ©cassine	F	2003-01-08	Chantepie
0405684940	Pexton	PersonnalisÃ©e	F	2001-02-01	MÃ©ru
6678203321	Hurdwell	RÃ©servÃ©s	M	1985-11-09	Villefranche-sur-Mer
5544444730	Trengrouse	MaÃ«ly	M	1965-11-15	AngoulÃªme
4842593423	Blaisdell	LÃ¨i	F	1966-11-17	Paris 12
3867451915	McCurry	LÃ¨i	F	1992-11-11	Gif-sur-Yvette
3044660831	Duiged	MÃ©lissandre	F	1965-07-15	Sophia Antipolis
3621845763	Lifton	MÃ©line	F	1997-06-16	Bourges
7007352693	Egell	MaÃ¯ly	F	1978-07-18	Belfort
2226788387	Workes	RuÃ²	F	2000-09-03	Senlis
1765233178	Ellingworth	HÃ©lÃ¨na	M	1966-11-21	Lons-le-Saunier
9325698552	Blakes	AnaÃ©	F	1972-11-27	AlÃ¨s
3079406877	Ruggier	CÃ©cilia	M	1981-07-01	Cambrai
1954245653	Bidgood	SÃ©rÃ©na	M	1967-03-15	Lyon
9335079456	Micheau	SolÃ¨ne	M	1965-08-18	Albi
9409180147	Bate	BÃ¶rje	M	1974-03-13	Blois
1169646190	Balam	MylÃ¨ne	M	2000-07-03	Le Mans
8716469321	Wadge	AngÃ©lique	F	1998-06-23	Le Mans
2910811743	Gallear	NuÃ³	F	1974-09-27	Longwy
4583742177	Mantrup	AnnotÃ©e	M	1963-07-02	Saint-Brieuc
5231687413	Chanson	BÃ©nÃ©dicte	F	1996-05-01	Hendaye
5242710179	Sainer	MaÃ¯ly	M	1970-03-26	Bobigny
3866393547	Pringour	RachÃ¨le	M	1968-02-02	Ã‰pinal
6594783831	Stockill	BjÃ¶rn	F	2002-03-05	Chartres
5786047245	Billanie	AnaÃ©	M	2001-07-23	Paris 14
6072295347	Skippings	MaÃ¯wenn	F	1972-10-28	Issy-les-Moulineaux
7989931737	Huyge	EugÃ©nie	M	2004-02-11	Courtaboeuf
5138937553	Loveard	BÃ©rÃ©nice	M	1998-01-07	Le Mans
8354041735	Havelin	UÃ²	M	1995-12-07	Taverny
5041013144	Marsland	MÃ©gane	M	1971-10-30	Gif-sur-Yvette
6737778674	McCaighey	LÃ©ana	F	2001-03-30	Romilly-sur-Seine
3937913300	Hickeringill	ThÃ©rÃ¨sa	F	1960-05-24	ChambÃ©ry
9623478933	Woodnutt	ValÃ©rie	F	1998-05-04	Pontivy
3088157132	Wombwell	DÃ¹	F	1970-12-01	Marseille
2271455715	Lapslie	GÃ©raldine	F	1970-01-05	Bezons
1233881132	Ludron	DaniÃ¨le	M	1969-07-12	Val-de-Reuil
9936902246	Taveriner	BÃ©atrice	M	1983-12-09	Lomme
1754810314	Sail	YÃ¨	M	1961-10-26	Parthenay
5259300122	Schober	EugÃ©nie	F	1961-05-02	Creil
4362404139	Housam	KuÃ­	M	1997-07-13	Calais
5930836965	Yter	EstÃ©e	M	1981-07-29	Vitry-sur-Seine
6489306069	Rossoni	AmÃ©lie	F	2001-11-15	Sophia Antipolis
7875426146	Leipelt	LÃ©ane	M	1995-11-09	Marseille
1486195938	Kenealy	LoÃ¯c	F	1991-07-24	Paris 15
6040596961	Martina	CunÃ©gonde	F	1965-09-14	Saint-Amand-les-Eaux
1095264370	Balazot	MaÃ«ly	M	1989-03-21	Bernay
4064870557	Comazzo	CloÃ©	F	1982-05-17	Thiers
7061974850	Dreigher	Marie-josÃ©e	M	1991-09-04	Roissy Charles-de-Gaulle
5807095952	Barbosa	DaphnÃ©e	M	1989-08-06	Ã‰vry
9300243519	Langcastle	FÃ©licie	M	1984-03-06	Laval
1675730849	Di Giorgio	GeneviÃ¨ve	F	1968-04-28	Chantilly
4910229361	Milley	CÃ©cile	M	1993-08-31	Mougins
3352721858	Attwell	YÃ¡o	M	1991-02-24	Nantes
6805022525	Aikman	AgnÃ¨s	F	2003-12-22	Lyon
6673937033	Concklin	MÃ©n	F	1993-08-12	Rungis
8444848697	Stoggell	Marie-thÃ©rÃ¨se	M	1966-06-23	Saint-Avertin
0866980784	Spada	LÃ©ana	F	1985-05-13	Lyon
6959851491	Exell	RÃ©jane	M	1995-03-27	Villeneuve-lÃ¨s-Avignon
2365043038	O'Luby	AlmÃ©rinda	M	1966-06-25	Rivesaltes
7466680607	Sinclar	MÃ©thode	M	1998-11-24	Saint-Ã‰grÃ¨ve
1216659826	Evert	LysÃ©a	F	2001-11-17	Istres
9996400735	Dudeney	AloÃ¯s	F	1973-12-17	Montpellier
9290975342	Buckmaster	BÃ©nÃ©dicte	M	1984-02-06	Agen
4446060724	Sickamore	MaÃ¯lys	F	1981-10-05	Lescar
0444879129	Reggiani	KÃ¹	F	1984-07-26	Istres
4770408056	Haycraft	KuÃ­	M	1963-12-22	Cherbourg-Octeville
7955627318	Wilcot	LÃ i	M	1970-09-11	Noisy-le-Grand
3386914209	Kamenar	RÃ©becca	M	1979-01-06	BesanÃ§on
8952965957	Ley	SÃ²ng	F	1973-03-06	Paris 16
6466724522	McLoughlin	Ã…ke	F	1995-10-13	Cholet
9307862079	Filipputti	ZoÃ©	F	2001-03-29	CompiÃ¨gne
7546395968	Egdell	RÃ©becca	M	1988-11-12	Toulon
6922695879	McCambrois	MagdalÃ¨ne	F	2000-09-10	Angers
0007071159	Finnimore	YÃ¡o	F	1972-08-31	Le Havre
1736146076	Wombwell	JosÃ©e	M	1976-06-05	Paris 20
2760309142	Amar	ElÃ©a	M	1971-05-15	Palaiseau
1587883376	Sprowles	MÃ©lissandre	M	1987-07-13	Paris La DÃ©fense
1737639637	Dodswell	LÃ©n	M	1972-05-26	CarriÃ¨res-sur-Seine
3777544566	Raitt	LÃ i	F	1994-06-20	Paris 13
0932663788	Luty	PÃ²	M	1978-08-06	Roanne
3601087944	Szymanowski	MaÃ©na	F	1961-02-19	LocminÃ©
9253287217	MacTrustam	HÃ©lÃ¨na	M	1992-11-11	Lyon
0479530564	Ouslem	SÃ©rÃ©na	F	1966-09-19	Yvetot
3125127912	Beck	AngÃ©lique	M	1962-06-26	Saint-Fargeau-Ponthierry
2381724907	Clint	RuÃ¬	M	1989-08-07	Sophia Antipolis
5522003618	Lanphier	AgnÃ¨s	F	1996-06-07	Meylan
9833956289	Abdy	EstÃ¨ve	F	1963-04-07	Romilly-sur-Seine
5988870465	Rymmer	ClÃ©opatre	M	1992-07-13	Montpellier
8979999674	Case	EstÃ¨ve	F	1976-04-25	Aubenas
3947905092	Mewis	PublicitÃ©	F	1970-12-27	Soissons
4424182975	Le land	PÃ©nÃ©lope	M	1990-07-13	Eybens
5751279840	McGerr	ZoÃ©	M	2001-06-24	Toulouse
5893162773	Leere	MÃ¥ns	M	1998-08-03	Annecy
7543825767	Gaither	FrÃ©dÃ©rique	F	2000-12-29	Poligny
7028545369	Pontefract	ClÃ©opatre	F	2001-08-07	Charenton-le-Pont
0445397810	Bennie	LÃ©ane	M	1979-06-27	Le Mans
3377456465	Vanacci	MaÃ¯wenn	F	1984-03-10	Poitiers
1654692565	Gavan	MÃ¥rten	M	1965-02-12	Troyes
2815070839	Dwelly	DÃ 	M	1982-09-07	Reims
9063019629	Swanborough	BÃ©rengÃ¨re	F	1970-05-09	Lyon
1883084334	Golly	BÃ©rÃ©nice	M	1968-07-21	MontbÃ©liard
9100707805	Blaxeland	AmÃ©lie	F	2003-03-02	Nantes
9231121685	Hulmes	GwenaÃ«lle	F	2000-07-22	DÃ©cines-Charpieu
4033677712	Likely	GaÃ«lle	F	1987-11-06	Lyon
4748511427	Mell	AthÃ©na	F	1983-01-09	Tours
5508310711	Vivians	LÃ©onie	M	1996-06-30	Metz
1176780573	Jewes	YÃº	F	1980-12-27	Arnage
4751653016	Whyley	GÃ¶ran	M	1965-04-15	Puget-sur-Argens
4951889862	Gauson	KÃ©vina	M	1973-04-30	Montreuil
5961056929	Burgis	NoÃ©mie	F	1984-11-10	Orange
1165667681	Galbraeth	IrÃ¨ne	F	1994-12-12	Cergy-Pontoise
6610110158	Boole	MaÃ¯wenn	M	1992-03-03	Apt
5189037819	Pearsall	BÃ©cassine	M	1969-12-02	Troyes
2916326960	Maberley	FÃ¨i	F	1989-05-30	LocminÃ©
5949912039	Guitton	LÃ©one	F	2001-08-24	Montpellier
1189580594	Jachimiak	InÃ¨s	M	1980-03-12	Ivry-sur-Seine
2331758670	Aireton	MaÃ¯	F	1999-09-07	OrlÃ©ans
9224950922	De Santos	MaÃ«lle	M	1990-04-22	Paris 17
7786652183	Hadkins	AnaÃ¯s	F	1960-06-03	Morez
0215346947	Takle	LÃ©onie	F	1986-05-14	Nantes
6177580564	Feuell	ClÃ©mentine	F	1995-01-25	Paris La DÃ©fense
4886299598	Mardy	CÃ©cile	M	2001-10-22	Dijon
5469733777	Glowacz	CinÃ©ma	F	1975-04-10	Blois
0476281075	Deakes	MylÃ¨ne	F	1966-06-27	Caluire-et-Cuire
5772264591	MacClure	MÃ©lys	F	1966-01-19	Nantes
4190628670	Iglesias	Marie-hÃ©lÃ¨ne	M	1967-08-21	Quimper
9172213760	Antram	LoÃ¯s	M	1999-02-07	Sedan
1994778679	Eve	NoÃ©mie	F	1972-06-14	Pau
9223618681	Face	MaÃ«lyss	F	1976-05-23	Ã‰vry
8963147304	Josifovitz	EliÃ¨s	M	2002-08-25	Clermont-Ferrand
0683618105	Kamena	VÃ©ronique	F	1970-01-17	Roissy Charles-de-Gaulle
4909058125	Jahnke	ThÃ©rÃ¨sa	F	1981-04-20	Ã‰pinal
2439546410	Melville	CunÃ©gonde	F	1965-09-06	Perpignan
4887673418	Readwood	BÃ¶rje	M	1976-04-20	Niort
8359128960	Davenall	AudrÃ©anne	M	1967-07-09	Sallanches
5546780495	Starbeck	PÃ©nÃ©lope	M	1965-04-05	Le Mans
5261804590	Dhenin	Marie-franÃ§oise	M	1966-04-03	Argentan
7931708962	Gomer	ClÃ©a	M	1997-06-07	Cluses
0475953126	Sayce	AndrÃ©a	F	1962-07-22	Troyes
8504705382	Dinzey	StÃ©vina	F	1961-01-22	Cahors
3481041233	Gaymer	YÃº	M	1990-10-05	Paris 08
5753698557	Grigaut	EstÃ¨ve	M	2000-03-13	Ã‰vreux
0724612289	Mosdall	SolÃ¨ne	F	1962-08-27	Roissy Charles-de-Gaulle
4468092963	Neiland	InÃ¨s	F	1988-12-07	Ajaccio
3002491705	Thickett	MaÃ©na	M	1960-11-16	Melun
4086722534	Kubista	AnaÃ¯s	F	1962-11-25	Calais
3679294468	Yepiskov	AdÃ¨le	M	1965-03-05	Toulouse
5214691890	Marlen	RuÃ²	M	1988-06-07	Paris 06
7028815994	Pluck	InÃ¨s	M	1988-12-25	Ã‰vreux
3633994459	Ensley	MaÃ¯	F	2004-01-11	Nogent-sur-Marne
0291769098	Reeks	Marie-noÃ«l	M	1999-06-08	Orvault
6892987303	Eubank	LucrÃ¨ce	F	1969-06-21	Marne-la-VallÃ©e
2272406432	Juanes	ClÃ©lia	F	1995-06-29	Floirac
2389669700	Ferreiro	GÃ¶rel	M	1993-05-06	Nanterre
5065797382	Mulcock	UÃ²	M	1982-10-24	Lyon
2843152127	Broddle	NÃ©lie	M	1983-02-18	Goussainville
0927298929	Darridon	AnnotÃ©s	F	1990-08-18	Poitiers
9990957282	MacGilrewy	DaphnÃ©e	M	2000-08-17	Limoges
9338902501	O'Dowd	AndrÃ©a	M	1998-02-25	Croix
9871789068	O' Gara	RÃ©gine	M	1989-10-25	Reims
4536917055	Cheverell	AgnÃ¨s	M	1972-06-11	Ancenis
7542235346	Bridgwater	LÃ i	F	1988-05-15	Lyon
7881564245	Redpath	AnnotÃ©s	F	1969-02-14	Pau
7513156913	Nursey	SÃ©lÃ¨ne	M	1963-12-17	BesanÃ§on
8370531768	Morrant	RenÃ©e	M	2003-07-08	Rungis
0929782127	Pardal	LysÃ©a	M	1961-02-11	Lille
8660804910	Turfrey	JudicaÃ«l	F	1983-04-11	Bonneville
8545674414	Backshell	AthÃ©na	F	1992-01-17	Le Blanc-Mesnil
3847851853	Huffey	MÃ©n	M	1987-11-02	Lille
2738830668	Heatlie	MÃ©lodie	M	1968-07-20	Morangis
1438497547	Roxburch	MaÃ«lyss	F	2004-01-01	La Roche-sur-Yon
7813429508	MacConneely	ClÃ©lia	F	1976-05-20	Altkirch
1691723878	Vanner	MÃ©lodie	M	1971-09-27	Le Grand-Quevilly
7612879123	Foale	ChloÃ©	M	1986-12-04	ChÃ¢teauroux
5000327454	Gow	LÃ©a	M	2000-02-06	Montpellier
0403266351	McKendo	NÃ©hÃ©mie	M	1973-10-15	Aubagne
8565074978	Linder	MahÃ©lie	M	1963-04-17	Auch
2732207977	Ziemens	AnaÃ«lle	M	1990-02-16	Mazamet
6618804345	Ayars	AÃ­	M	2003-04-30	Angers
7967847903	Devita	MaÃ«line	F	1988-02-23	NÃ®mes
5468035324	Rawstorne	PÃ©nÃ©lope	F	1975-06-20	Paris 18
6936932010	Bartolini	MÃ©lanie	M	1973-07-22	Nogent-sur-Marne
7052929856	Cridlon	DÃ 	F	2003-08-05	Nemours
7080788617	Scotchmur	MÃ©lys	F	1975-05-15	Avignon
7904843617	Marjoribanks	MichÃ¨le	F	1962-08-29	Tours
7852106935	Boast	CinÃ©ma	M	1969-02-05	La Valette-du-Var
1084490811	Stanbury	TÃ¡ng	F	1972-07-03	Cognac
0312348738	Lockton	NaÃ«lle	M	1992-04-19	Montreuil
5362157760	Matteini	CloÃ©	F	1963-07-13	Quetigny
5229464488	Meenehan	OcÃ©ane	M	1985-05-14	Toulouse
1866047906	Colvine	LaÃ¯la	F	1968-01-31	Nice
4841120440	Lorraine	MÃ©lys	F	1974-11-29	Haguenau
2889766926	Fairlie	MÃ©lys	F	1998-08-26	Angers
4227285186	Beynkn	AnnotÃ©e	F	1991-06-28	Paris 19
1488301689	Stalf	AngÃ¨le	F	1986-12-09	Brest
3605529542	Combe	DafnÃ©e	M	1970-12-03	ChÃ¢tillon
4922740198	Gosnoll	MaÃ¯	F	1998-08-06	Strasbourg
5800713952	Haycock	CinÃ©ma	F	1999-07-28	Kingersheim
2519960094	Vigar	Ã–rjan	M	1989-06-28	Issoire
2003722270	Canero	Ã–rjan	F	1970-12-11	Toulouse
7268452640	Grosvenor	MilÃ©na	F	1980-06-04	Dijon
7169891549	Dallas	AlmÃ©rinda	F	1995-07-12	Ancenis
7900360727	Newsham	AlmÃ©rinda	F	1970-06-19	Brest
8635401883	Emery	AnaÃ«lle	F	2002-10-30	Haguenau
4076444744	Godlip	CloÃ©	F	1986-10-20	OrlÃ©ans
2950187048	Grigolashvill	BjÃ¶rn	M	1984-10-14	Lomme
4284554301	Tockell	CloÃ©	M	1984-08-10	Rungis
6822820434	Allcoat	AnaÃ©	M	1991-08-14	Paris 13
7801457978	Stidever	AudrÃ©anne	M	1988-06-07	Voiron
7006738083	Bea	GwenaÃ«lle	M	1997-07-22	Bobigny
3313013775	Bloys	MÃ©lina	F	1963-01-14	CrÃ©py-en-Valois
1412547873	Tejada	JosÃ©e	M	2003-01-06	Paris 09
6633798849	Denniss	RÃ¡o	F	1991-08-22	Saint-Denis
4947976772	Firminger	LoÃ¯s	M	1993-03-22	Longjumeau
3223663347	Dornin	HÃ¥kan	F	1987-10-28	OrlÃ©ans
3409052631	Stearn	CunÃ©gonde	M	1974-08-07	Saint-Pierre-Montlimart
7021231032	Castagne	Marie-josÃ©e	F	1980-03-02	Caen
6455744055	Bellenie	OphÃ©lie	M	1984-05-22	Saint-Chamond
5408685748	Loud	PÃ¥l	M	1975-06-29	Blois
4509167040	Alison	CunÃ©gonde	F	1968-06-29	Niort
6013237018	Couve	MahÃ©lie	F	1981-02-22	Paris 03
\.


--
-- Data for Name: magasinsante; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.magasinsante (idzfsante, coordonneutm, libeletype, idmagasin, typemagasin) FROM stdin;
\.


--
-- Data for Name: militaire; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.militaire (codepays, pays, nomarmee, nomunite, div_bri, unite_elementaire, matricule, nom, prenom, categoriehf, date_naissance, lieu_naissance, grade, catmilitaire) FROM stdin;
AA	France	Armee de Terre	RMED	COMLOG	1CMC	0861922336	Schlagtmans	AmÃ©lie	M	1993-10-25	Paris 13	SDT	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	1CMC	1664863109	Rosenschein	LorÃ¨ne	F	1972-09-03	Valence	CPL	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	1CMC	2060293685	Accombe	AnnotÃ©s	F	1961-11-29	Mundolsheim	ADC	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	1CMC	4692278188	Kasper	ClÃ©mence	F	1978-09-08	Istres	1CL	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	1CMC	2086962339	Zorzoni	EstÃ¨ve	F	1991-10-29	RezÃ©	ADJ	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	1CMC	7834470469	Claridge	ErwÃ©i	F	1996-07-07	Saint-Dizier	LTN	OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	1CMC	0576570265	Dybbe	LÃ©andre	F	1982-06-26	Lillers	CNE	OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	1CMC	9720498579	Olle	FÃ©licie	F	2002-08-14	Rueil-Malmaison	LTN	OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	1CMC	0062822047	Bruinsma	Marie-noÃ«l	F	1986-09-20	Toulon	SDT	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	1CMC	6578583637	MacCawley	MÃ©ryl	F	2003-10-18	Aubagne	CCH	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	1CMC	7981847621	Penella	MÃ 	M	2000-12-02	AsniÃ¨res-sur-Seine	ADJ	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	1CMC	5913367685	Sign	MaÃ«lann	M	1962-12-14	Paris 01	MAJ	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	1CMC	2347881531	Warlowe	MaÃ«lyss	F	1966-08-25	Lomme	CNE	OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	1CMC	2129484654	Jopke	UÃ²	M	2003-03-25	Nantes	SCH	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	1CMC	5832690745	Lichfield	GÃ¶ran	F	1960-12-31	Poligny	1CL	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	1CMC	3166681353	De Bruyn	AngÃ¨le	M	1985-06-21	Poitiers	1CL	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	1CMC	3510523997	Ornelas	AudrÃ©anne	M	1966-12-02	Villefranche-sur-Mer	ADC	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	1CMC	2518085602	Gregoriou	Ã…slÃ¶g	F	2001-02-24	Schiltigheim	1CL	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	1CMC	6240423971	Juanico	LÃ©one	F	1981-06-24	Chalon-sur-SaÃ´ne	ADC	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	1CMC	3633160329	Antal	Marie-hÃ©lÃ¨ne	F	1998-12-26	Suresnes	ASP	OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	1CMC	0932812511	Flowith	CÃ©line	F	1994-09-17	Granville	SCH	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	1CMC	8797488658	Bugler	MarlÃ¨ne	M	1966-03-13	Saint-Pierre-des-Corps	SLT	OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	1CMC	4799920219	Pencott	ClÃ©a	F	1994-05-08	Rouen	1CL	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	1CMC	9518069247	Crighton	AndrÃ©anne	M	1965-04-25	Paris 12	CDT	OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	1CMC	2947710053	Huntingdon	AndrÃ©	F	1998-02-13	Wintzenheim	SGT	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	1CMC	4667143967	Goodhew	KÃ¹	M	1982-07-05	Saint-Denis	1CL	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	1CMC	1109902905	Domeny	EstÃ¨ve	M	1971-04-26	Paris La DÃ©fense	SCH	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	1CMC	5977330340	Lightwood	IntÃ©ressant	F	1979-09-18	Cergy-Pontoise	CPL	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	1CMC	6269198402	Hadwen	NaÃ«lle	F	1962-06-03	Saint-Pierre-des-Corps	SDT	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	1CMC	8028925618	Staunton	MaÃ«line	M	1966-08-05	Villeneuve-la-Garenne	ADJ	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	1CMC	1209045109	Akerman	EsbjÃ¶rn	M	1960-07-19	Romorantin-Lanthenay	LTN	OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	1CMC	0260459860	Maxsted	PÃ©nÃ©lope	M	1973-05-31	Nice	SGT	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	1CMC	9580618526	Pulbrook	StÃ©vina	F	1989-05-27	Paris 13	SCH	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	1CMC	2768438715	McQuarter	RÃ©jane	F	1980-05-13	Montauban	SGT	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	1CMC	7246966803	Spratling	BÃ©rengÃ¨re	M	1973-07-11	Mulhouse	1CL	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	1CMC	2094823369	Klinck	RuÃ¬	F	1969-03-28	Wasquehal	1CL	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	1CMC	1823024157	Veivers	DaniÃ¨le	F	1993-10-03	Nice	SLT	OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	1CMC	0999996770	Edwardes	ErwÃ©i	M	1985-10-18	Ussel	1CL	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	1CMC	6213608044	Gosselin	FÃ¨i	F	1971-10-05	Aurillac	CCH	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	1CMC	5873157774	Flaherty	MÃ¥rten	M	1995-08-01	Paris 04	1CL	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	1CMC	9723036061	Anthill	LaurÃ©na	F	1993-06-10	Montpellier	1CL	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	1CMC	4743783836	Labeuil	GarÃ§on	M	1973-03-09	Colomiers	1CL	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	1CMC	8669664119	Licquorish	GaÃ©tane	M	1982-01-23	Nanterre	SDT	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	1CMC	2268504387	Stansby	LÃ©onie	F	1966-12-21	Saint-DiÃ©-des-Vosges	SDT	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	1CMC	2556101695	Hallaways	NoÃ«lla	F	1994-12-12	Tours	CDT	OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	1CMC	8008926562	Vanyukhin	Ã…sa	F	2001-03-06	Paris 15	SCH	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	1CMC	3851234758	Noury	Marie-Ã¨ve	F	1996-06-19	FrÃ©jus	SDT	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	1CMC	7491922368	Uden	ThÃ©rÃ¨sa	M	1994-07-24	Cagnes-sur-Mer	ADJ	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	1CMC	7106776254	Beere	MaÃ¯	F	1994-09-29	Puteaux	CPL	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	1CMC	2743756268	McFade	AmÃ©lie	F	2000-09-07	Paris La DÃ©fense	1CL	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	1CMC	9562469700	Colin	KÃ©vina	F	1981-01-19	Marseille	MAJ	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	1CMC	7336155359	Hollingsbee	AdÃ©laÃ¯de	F	1962-07-12	Laon	1CL	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	1CMC	2874387886	Garshore	BÃ©atrice	M	1980-08-29	AlÃ¨s	SGT	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	1CMC	9955507578	Umpleby	MarlÃ¨ne	M	1978-07-24	NÃ®mes	SDT	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	1CMC	4817076356	Czajkowska	AloÃ¯s	F	1964-08-23	Laval	SGT	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	1CMC	4206757518	Turmall	CÃ©lestine	F	1980-11-13	CrÃ©teil	1CL	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	1CMC	0990570681	Yushkov	CÃ©cilia	F	1996-03-29	Reims	ASP	OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	1CMC	7209677461	Hatwells	ThÃ©rÃ¨sa	M	1962-12-02	Paris 10	SLT	OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	1CMC	5922628798	Hindhaugh	AdÃ¨le	M	2004-04-19	Valence	SLT	OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	1CMC	1968659390	Jaegar	ClÃ©a	M	1975-07-30	Paris 20	1CL	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	1CMC	1772892297	Varvell	AndrÃ©e	M	1968-02-05	Nantes	CCH	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	1CMC	7118440817	Rawll	LÃ©a	F	1977-08-17	Salon-de-Provence	SDT	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	1CMC	8199219521	Staker	RachÃ¨le	M	1981-08-28	PÃ©rigueux	CCH	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	1CMC	0456044906	Heeley	MÃ©diamass	F	1975-05-04	Rochefort	1CL	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	1CMC	8563648470	Letty	RuÃ¬	M	1988-01-17	Meaux	CPL	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	1CMC	0626111382	Hartegan	MahÃ©lie	F	1967-03-18	Perpignan	CCH	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	1CMC	4838255705	Ivanikov	MÃ©lia	F	1990-03-09	La Roche-sur-Yon	ADJ	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	1CMC	4096899070	Slocum	RuÃ¬	F	1992-07-26	Bobigny	SDT	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	1CMC	0856544221	Dash	SÃ©rÃ©na	F	1962-07-22	Hagondange	SDT	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	1CMC	0289703565	Vickery	Marie-thÃ©rÃ¨se	M	1992-06-08	Amiens	SDT	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	1CMC	9950674093	Estoile	MaÃ«lann	M	1967-10-07	MontbÃ©liard	SCH	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	1CMC	7016562050	Lamperd	SimplifiÃ©s	M	1982-03-24	PÃ©rigny	1CL	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	1CMC	4405111979	Bushel	MaÃ¯lys	M	1992-10-13	Ã‰tampes	SDT	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	1CMC	0025727494	Bruggeman	NÃ©lie	M	2003-09-07	Perpignan	SCH	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	1CMC	9256552841	Settle	MaÃ¯	F	1977-12-04	Tours	SGT	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	1CMC	2374823032	Izatson	LÃ©one	F	1969-09-29	Paris La DÃ©fense	CPL	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	1CMC	8282226394	Hebblethwaite	MÃ©lina	F	1996-04-03	Bastia	ASP	OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	1CMC	4716750957	Stothart	SalomÃ©	M	2002-04-26	Lens	SDT	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	1CMC	6610952353	Braxton	MylÃ¨ne	M	1973-02-28	Cergy-Pontoise	SGT	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	1CMC	9987346251	Mattea	MÃ¥ns	F	1988-12-09	Laxou	LCL	OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	1CMC	8371529252	Armstrong	PÃ©nÃ©lope	M	1982-08-03	Sannois	SDT	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	1CMC	4982362521	Wackett	EstÃ©e	M	1964-08-04	Berck	SDT	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	1CMC	8431684402	Geerits	SÃ²ng	M	1967-11-01	Perpignan	SGT	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	1CMC	9919236705	Kelwaybamber	ZhÃ¬	M	1997-03-27	Valence	SDT	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	1CMC	3434613102	Carress	AlmÃ©rinda	F	1967-10-03	Grenoble	SGT	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	1CMC	9290501731	Klishin	MaÃ«lyss	M	1992-05-13	Balma	MAJ	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	1CMC	9698272623	Snoad	GaÃ¯a	F	1984-02-20	Pontarlier	LCL	OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	1CMC	8234305026	Cicconetti	ThÃ©rÃ¨se	M	1975-01-24	Versailles	SGT	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	1CMC	8199727934	Beese	NÃ©hÃ©mie	M	1994-03-23	Valence	CCH	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	1CMC	3270382995	Pfertner	StÃ©phanie	M	2001-02-21	Paris 12	CPL	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	1CMC	8655116181	Westhoff	KuÃ­	M	1975-09-10	Paris La DÃ©fense	CPL	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	1CMC	5617319345	Keary	AdÃ©laÃ¯de	M	1978-11-19	MÃ©rignac	SDT	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	1CMC	8492314729	Chittey	EdmÃ©e	F	1990-06-11	Saint-Brieuc	SDT	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	1CMC	4829905808	Crocetto	CunÃ©gonde	M	2003-07-23	Aubervilliers	1CL	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	2CMC	2236059299	Kirkhouse	AndrÃ©e	F	1989-07-09	Le Perreux-sur-Marne	SGT	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	2CMC	8083384569	Riditch	FÃ¨i	F	2003-05-18	Saint-Ã‰tienne	SDT	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	2CMC	4286421244	Gazey	MÃ©lia	M	1972-03-14	Colombes	SDT	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	2CMC	0916223272	Coster	MÃ¥ns	F	1995-02-04	Vincennes	SDT	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	2CMC	4643871008	Dennick	FaÃ®tes	F	1987-09-08	Albi	SDT	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	2CMC	2599040566	Banstead	ThÃ©rÃ¨se	M	1990-04-08	Brest	SDT	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	2CMC	2956397583	Amott	OphÃ©lie	M	1995-09-03	Saint-LÃ´	1CL	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	2CMC	6764955859	Petrelli	Marie-hÃ©lÃ¨ne	F	1987-08-22	Lons-le-Saunier	CPL	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	2CMC	6410418035	Mowbray	CÃ©lestine	F	1995-09-06	AngoulÃªme	1CL	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	2CMC	1850375240	Skaife d'Ingerthorpe	MÃ¤rta	M	1988-10-21	Le Puy-en-Velay	1CL	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	2CMC	1438544510	Belsher	MÃ©lys	M	1987-10-18	Toulouse	SGT	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	2CMC	6925727550	Emberson	WÃ¡	F	1976-01-27	Saumur	SCH	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	2CMC	2295108918	Griss	YÃ³u	M	1983-04-21	Limoges	ADJ	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	2CMC	8782345864	Readwin	SÃ©rÃ©na	M	1973-05-03	Melun	1CL	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	2CMC	1351768182	Lambard	CamÃ©lia	M	1998-10-29	Mulhouse	1CL	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	2CMC	9041062653	Patel	Ã…ke	M	1999-03-01	OrlÃ©ans	ADJ	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	2CMC	0482352361	Goggey	ClÃ©mence	M	1974-07-12	Millau	1CL	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	2CMC	1309110956	Maiden	MarylÃ¨ne	M	1960-06-24	Lille	SDT	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	2CMC	8752893898	Tasseler	LÃ©onore	F	1969-09-19	La Roche-sur-Yon	SGT	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	2CMC	9340120663	Dyche	RÃ©servÃ©s	F	1981-11-08	Toulouse	SLT	OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	2CMC	9307825769	Gowenlock	LysÃ©a	M	2002-01-27	ChÃ¢teaurenard	SDT	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	2CMC	3010154267	Seacombe	MaÃ«lann	F	1976-11-30	BesanÃ§on	ASP	OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	2CMC	7629864531	Simenot	MÃ©gane	M	1986-09-02	Lomme	1CL	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	2CMC	6337841727	Ambrogio	RÃ©becca	M	2003-10-13	Saint-Nazaire	CPL	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	2CMC	2390082629	Talman	Ã–sten	M	1970-09-04	Vierzon	1CL	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	2CMC	8027491061	Ducrow	MagdalÃ¨ne	M	1980-03-10	Cergy-Pontoise	CNE	OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	2CMC	6618256534	Blankley	StyrbjÃ¶rn	M	1971-09-22	Gap	CPL	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	2CMC	9002526172	Blunt	LÃ i	M	1984-12-11	ChÃ¢teaudun	SCH	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	2CMC	2536081281	Mulbry	AimÃ©e	F	1995-07-01	Auray	SGT	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	2CMC	1534945474	Carsey	LaurÃ¨ne	M	2004-03-07	Limoges	MAJ	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	2CMC	1649880146	Arter	VÃ©nus	M	1971-01-18	Nevers	CCH	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	2CMC	2730706941	Hanway	SolÃ¨ne	F	1991-04-26	Melun	SCH	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	2CMC	2405270528	Blasiak	GeneviÃ¨ve	F	1985-09-28	Carpentras	CNE	OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	2CMC	5249250823	Kretchmer	BÃ¶rje	F	1972-04-18	OrlÃ©ans	1CL	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	2CMC	7708959209	Battson	LÃ©one	M	1988-07-15	Chantilly	SLT	OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	2CMC	3726010203	Larvin	AudrÃ©anne	M	1972-08-06	Saint-LÃ´	CPL	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	2CMC	4496290308	Quenell	NÃ©lie	M	1995-01-05	Mont-Saint-Aignan	1CL	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	2CMC	9277406070	Capin	FÃ©licie	M	1971-09-08	Paris 15	SDT	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	2CMC	6704395679	Goulstone	GwenaÃ«lle	M	1962-03-20	Ã‰lancourt	SDT	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	2CMC	2773130464	Wardingley	AlmÃ©rinda	F	1974-07-16	Thaon-les-Vosges	SGT	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	2CMC	2847566074	Budleigh	PÃ²	F	1976-09-02	Toul	SGT	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	2CMC	9375384357	Timmes	PÃ²	F	1994-05-02	Limoges	SDT	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	2CMC	1703634934	Lockery	GÃ©raldine	F	2000-08-18	CrÃ©teil	SDT	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	2CMC	7908119255	Licciardi	LysÃ©a	M	1995-10-22	Digne-les-Bains	SGT	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	2CMC	6412931147	Brastead	KuÃ­	M	1963-04-21	Domont	CPL	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	2CMC	7350324324	Bullocke	LaurÃ¨ne	M	1988-11-02	Royan	CPL	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	2CMC	0149103522	Treswell	InÃ¨s	M	1982-07-22	Ã‰vry	SGT	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	2CMC	3153161798	McCullen	GÃ¶sta	F	1965-01-07	Angers	SCH	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	2CMC	2491379430	Mayzes	NadÃ¨ge	F	1990-10-09	Sophia Antipolis	ADC	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	2CMC	0102365911	Canwell	EloÃ¯se	F	1988-06-13	NÃ®mes	ADJ	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	2CMC	3664628969	Johnsee	Marie-noÃ«l	F	1963-03-10	Saint-Ã‰tienne	1CL	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	2CMC	9163718103	Aldrick	SolÃ¨ne	F	1980-07-08	Noisy-le-Grand	CDT	OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	2CMC	0455145733	Ordish	LoÃ¯c	F	2003-09-22	Douarnenez	CCH	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	2CMC	2583091034	Forber	MarylÃ¨ne	M	1973-03-20	Paris 12	1CL	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	2CMC	8309644124	Meere	LysÃ©a	M	1992-08-27	Nantes	SCH	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	2CMC	3068292247	Kenwrick	BÃ©cassine	F	2003-01-08	Chantepie	SDT	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	2CMC	0405684940	Pexton	PersonnalisÃ©e	F	2001-02-01	MÃ©ru	MAJ	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	2CMC	6678203321	Hurdwell	RÃ©servÃ©s	M	1985-11-09	Villefranche-sur-Mer	1CL	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	2CMC	5544444730	Trengrouse	MaÃ«ly	M	1965-11-15	AngoulÃªme	ADJ	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	2CMC	4842593423	Blaisdell	LÃ¨i	F	1966-11-17	Paris 12	SDT	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	2CMC	3867451915	McCurry	LÃ¨i	F	1992-11-11	Gif-sur-Yvette	CNE	OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	2CMC	3044660831	Duiged	MÃ©lissandre	F	1965-07-15	Sophia Antipolis	1CL	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	2CMC	3621845763	Lifton	MÃ©line	F	1997-06-16	Bourges	LCL	OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	2CMC	7007352693	Egell	MaÃ¯ly	F	1978-07-18	Belfort	SDT	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	2CMC	2226788387	Workes	RuÃ²	F	2000-09-03	Senlis	1CL	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	2CMC	1765233178	Ellingworth	HÃ©lÃ¨na	M	1966-11-21	Lons-le-Saunier	1CL	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	2CMC	9325698552	Blakes	AnaÃ©	F	1972-11-27	AlÃ¨s	SDT	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	2CMC	3079406877	Ruggier	CÃ©cilia	M	1981-07-01	Cambrai	SLT	OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	2CMC	1954245653	Bidgood	SÃ©rÃ©na	M	1967-03-15	Lyon	LTN	OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	2CMC	9335079456	Micheau	SolÃ¨ne	M	1965-08-18	Albi	SGT	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	2CMC	9409180147	Bate	BÃ¶rje	M	1974-03-13	Blois	CPL	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	2CMC	1169646190	Balam	MylÃ¨ne	M	2000-07-03	Le Mans	CCH	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	2CMC	8716469321	Wadge	AngÃ©lique	F	1998-06-23	Le Mans	SDT	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	2CMC	2910811743	Gallear	NuÃ³	F	1974-09-27	Longwy	CCH	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	2CMC	4583742177	Mantrup	AnnotÃ©e	M	1963-07-02	Saint-Brieuc	LTN	OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	2CMC	5231687413	Chanson	BÃ©nÃ©dicte	F	1996-05-01	Hendaye	SDT	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	2CMC	5242710179	Sainer	MaÃ¯ly	M	1970-03-26	Bobigny	1CL	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	2CMC	3866393547	Pringour	RachÃ¨le	M	1968-02-02	Ã‰pinal	ADC	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	2CMC	6594783831	Stockill	BjÃ¶rn	F	2002-03-05	Chartres	CCH	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	2CMC	5786047245	Billanie	AnaÃ©	M	2001-07-23	Paris 14	SCH	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	2CMC	6072295347	Skippings	MaÃ¯wenn	F	1972-10-28	Issy-les-Moulineaux	SCH	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	2CMC	7989931737	Huyge	EugÃ©nie	M	2004-02-11	Courtaboeuf	SCH	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	2CMC	5138937553	Loveard	BÃ©rÃ©nice	M	1998-01-07	Le Mans	ADC	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	2CMC	8354041735	Havelin	UÃ²	M	1995-12-07	Taverny	ADC	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	2CMC	5041013144	Marsland	MÃ©gane	M	1971-10-30	Gif-sur-Yvette	LTN	OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	2CMC	6737778674	McCaighey	LÃ©ana	F	2001-03-30	Romilly-sur-Seine	LTN	OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	2CMC	3937913300	Hickeringill	ThÃ©rÃ¨sa	F	1960-05-24	ChambÃ©ry	LCL	OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	2CMC	9623478933	Woodnutt	ValÃ©rie	F	1998-05-04	Pontivy	SDT	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	2CMC	3088157132	Wombwell	DÃ¹	F	1970-12-01	Marseille	ASP	OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	2CMC	2271455715	Lapslie	GÃ©raldine	F	1970-01-05	Bezons	SLT	OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	2CMC	1233881132	Ludron	DaniÃ¨le	M	1969-07-12	Val-de-Reuil	1CL	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	2CMC	9936902246	Taveriner	BÃ©atrice	M	1983-12-09	Lomme	1CL	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	2CMC	1754810314	Sail	YÃ¨	M	1961-10-26	Parthenay	SGT	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	2CMC	5259300122	Schober	EugÃ©nie	F	1961-05-02	Creil	1CL	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	3CMC	4362404139	Housam	KuÃ­	M	1997-07-13	Calais	1CL	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	3CMC	5930836965	Yter	EstÃ©e	M	1981-07-29	Vitry-sur-Seine	SDT	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	3CMC	6489306069	Rossoni	AmÃ©lie	F	2001-11-15	Sophia Antipolis	CCH	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	3CMC	7875426146	Leipelt	LÃ©ane	M	1995-11-09	Marseille	1CL	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	3CMC	1486195938	Kenealy	LoÃ¯c	F	1991-07-24	Paris 15	SGT	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	3CMC	6040596961	Martina	CunÃ©gonde	F	1965-09-14	Saint-Amand-les-Eaux	ADJ	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	3CMC	1095264370	Balazot	MaÃ«ly	M	1989-03-21	Bernay	ADJ	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	3CMC	4064870557	Comazzo	CloÃ©	F	1982-05-17	Thiers	SCH	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	3CMC	7061974850	Dreigher	Marie-josÃ©e	M	1991-09-04	Roissy Charles-de-Gaulle	LCL	OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	3CMC	5807095952	Barbosa	DaphnÃ©e	M	1989-08-06	Ã‰vry	LTN	OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	3CMC	9300243519	Langcastle	FÃ©licie	M	1984-03-06	Laval	CPL	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	3CMC	1675730849	Di Giorgio	GeneviÃ¨ve	F	1968-04-28	Chantilly	SCH	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	3CMC	4910229361	Milley	CÃ©cile	M	1993-08-31	Mougins	SLT	OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	3CMC	3352721858	Attwell	YÃ¡o	M	1991-02-24	Nantes	SGT	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	3CMC	4212317095	Freeland	JÃº	F	1978-09-18	Caen	1CL	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	3CMC	3003866575	Betteriss	IntÃ©ressant	F	1970-05-06	Ivry-sur-Seine	ADC	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	3CMC	7273754749	Pledger	MÃ©ghane	F	1977-11-06	Lattes	MAJ	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	3CMC	7587816011	Shyram	AÃ­	M	1994-06-16	Antony	CNE	OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	3CMC	2543391878	Billion	BjÃ¶rn	M	1994-06-18	Bordeaux	SGT	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	3CMC	8528106012	Rumbold	LÃ©one	M	1997-03-06	Annecy	SCH	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	3CMC	6223862377	Pes	AlizÃ©e	M	1994-08-14	Reims	1CL	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	3CMC	7485441000	Blofield	YÃ¨	F	1990-04-15	Paris 07	SDT	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	3CMC	4330138476	Loughnan	MÃ©diamass	M	1985-04-16	Le Teil	ASP	OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	3CMC	6619571395	Cleen	UÃ²	M	1989-09-29	Reims	SGT	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	3CMC	2262635544	Scibsey	JudicaÃ«l	M	1982-11-14	Aubenas	MAJ	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	3CMC	6688492563	Crasford	TorbjÃ¶rn	F	2001-11-02	Nantes	SDT	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	3CMC	9572000314	Walak	YÃº	F	1960-09-22	Lille	CCH	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	3CMC	1124119477	Coggin	DesirÃ©e	F	1967-06-26	Limoges	SDT	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	3CMC	2593662743	Esherwood	MaÃ©na	F	1964-10-18	NÃ®mes	SGT	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	3CMC	0202469875	Kezourec	AurÃ©lie	M	1982-02-24	Nanterre	SGT	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	3CMC	9476590823	Luto	MÃ©lissandre	M	1978-05-04	La Rochelle	SDT	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	3CMC	8310618069	Ebdin	AlmÃ©rinda	M	1985-02-14	Cergy-Pontoise	SCH	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	3CMC	8050253171	Nussen	MaÃ«lann	M	1982-04-29	Roubaix	1CL	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	3CMC	3438492377	Wasmuth	RÃ©gine	F	2002-01-09	MontÃ©limar	CPL	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	3CMC	3370265761	Mishaw	ClÃ©a	F	1982-04-09	Gentilly	SLT	OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	3CMC	4714460714	Stockbridge	DorothÃ©e	M	1975-05-17	Paris 07	CNE	OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	3CMC	4594536697	Meece	MaÃ«ly	M	1970-09-04	Avignon	ADJ	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	3CMC	7559722474	Chestnutt	BÃ©nÃ©dicte	F	1964-02-11	Paris 12	ADC	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	3CMC	3243208912	Swetenham	JosÃ©phine	M	1964-04-12	Paris 12	SDT	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	3CMC	9517734018	Oppery	VÃ©ronique	M	1989-05-11	Paris 03	CPL	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	3CMC	8829745278	Rabl	ElÃ©a	F	1997-08-15	Toulouse	LTN	OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	3CMC	4263434021	Kirton	ClÃ©a	F	1996-02-29	Carcassonne	SCH	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	3CMC	7271539875	Godbehere	NuÃ³	F	1978-08-08	Cergy-Pontoise	1CL	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	3CMC	0111589363	Poile	DesirÃ©e	F	2002-07-19	Saint-Herblain	SGT	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	3CMC	4821187930	Edelheid	CÃ©cilia	F	2001-06-27	Nantes	SDT	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	3CMC	0453553915	Spalton	MaÃ©na	F	1966-02-01	BollÃ¨ne	SDT	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	3CMC	2482258189	Jephcott	MÃ©lissandre	M	1998-07-15	Molsheim	1CL	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	3CMC	9334455659	McNess	GarÃ§on	M	1964-07-09	Lille	1CL	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	3CMC	6571388138	Grzelak	PÃ²	M	1970-10-20	Suresnes	SDT	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	3CMC	4510289510	Casillas	NÃ©hÃ©mie	M	1977-03-24	PlÃ©rin	SDT	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	3CMC	9362930838	Auden	VÃ©rane	F	1983-06-25	Levallois-Perret	SDT	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	3CMC	9816474174	Macvain	MÃ©n	M	1992-07-10	Brie-Comte-Robert	LTN	OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	3CMC	5657485637	Bridge	DaphnÃ©e	F	1979-05-06	Tarbes	1CL	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	3CMC	7723871392	Carlyle	FaÃ®tes	F	1997-10-04	Annecy	COL	OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	3CMC	2850389587	Reisenberg	PÃ²	F	1987-04-28	Agen	SDT	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	3CMC	8132162129	Rennie	LÃ©ana	F	1990-10-27	Ã‰pinal	1CL	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	3CMC	7950934549	Kreber	MarylÃ¨ne	F	1978-03-07	Le Blanc-Mesnil	CPL	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	3CMC	1419681613	Hawket	MaÃ¯lys	M	1962-07-04	Paris 08	CPL	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	3CMC	7234242481	Matten	JosÃ©e	M	1988-03-31	BagnÃ¨res-de-Bigorre	CCH	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	3CMC	3975661003	Reignould	Ã–rjan	F	1987-08-19	Clermont-Ferrand	1CL	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	3CMC	9901453585	Putnam	HÃ¥kan	F	1979-12-17	Paris La DÃ©fense	SDT	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	3CMC	9334454156	Kesteven	DesirÃ©e	M	2001-09-09	Paris 14	SDT	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	3CMC	3903668435	Hugin	LoÃ¯ca	M	1969-03-09	Ã‰lancourt	CPL	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	3CMC	4614838383	Ranfield	ChloÃ©	M	1983-02-16	OrlÃ©ans	LTN	OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	3CMC	7865720203	Gibbe	AurÃ©lie	F	2002-12-21	La TalaudiÃ¨re	1CL	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	3CMC	7979234308	Grills	AngÃ¨le	F	2001-12-11	OrlÃ©ans	ASP	OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	3CMC	6923860547	Worsnup	MÃ 	F	1978-11-09	Paris La DÃ©fense	1CL	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	3CMC	4450932838	Lerwell	FaÃ®tes	M	1979-01-29	Paris La DÃ©fense	1CL	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	3CMC	5699197664	Showl	EstÃ©e	M	1975-10-28	Rennes	ADC	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	3CMC	2085120369	Martin	NuÃ³	M	1999-01-12	Lyon	ADC	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	4CMC	2866719670	Duprey	AmÃ©lie	M	1966-03-10	Rouen	SCH	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	4CMC	0110285824	Brann	RÃ©gine	F	1994-09-23	Suresnes	SDT	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	4CMC	1654569240	Cottrill	ElÃ©onore	M	1984-10-04	Lagny-sur-Marne	SGT	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	4CMC	8854609021	Minocchi	CÃ©lia	F	1967-10-21	Valence	1CL	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	4CMC	1258115964	Poulden	SalomÃ©	F	1984-03-13	AlenÃ§on	SDT	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	4CMC	9653513001	Lambrechts	MÃ©lanie	M	1970-07-18	Metz	1CL	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	4CMC	8215215386	Lipscomb	NuÃ³	M	1976-02-07	BrÃ©tigny-sur-Orge	SDT	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	4CMC	2317735286	Tuhy	DaphnÃ©e	F	1985-08-19	Croissy-sur-Seine	LTN	OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	4CMC	9821060226	Loker	LaurÃ¨ne	F	1978-08-02	Paris 20	LTN	OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	4CMC	1330110234	Asplin	AnaÃ«lle	F	1986-01-09	Rennes	ADC	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	4CMC	5608978358	Looker	AmÃ©lie	M	1993-05-15	Marseille	MAJ	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	4CMC	1092918698	Nissle	TÃ¡ng	M	1987-01-17	Bordeaux	SCH	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	4CMC	7268577915	Jarry	VÃ©rane	F	1986-05-28	Annecy	ASP	OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	4CMC	0406703310	Accombe	YÃ©nora	M	1988-01-14	Caen	CNE	OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	4CMC	4243958548	Maletratt	SalomÃ©	M	1998-02-07	Dinan	LTN	OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	4CMC	4486256174	Hargreves	CÃ©line	F	1987-03-17	Champigny-sur-Marne	CCH	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	4CMC	2766113622	Gilleson	MÃ©linda	M	1984-01-11	Noyal-sur-Vilaine	ASP	OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	4CMC	8861431275	Menhenitt	MÃ©ryl	M	2001-10-11	Manosque	SGT	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	4CMC	2603186299	Sherlaw	InÃ¨s	F	1984-03-27	Perpignan	1CL	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	4CMC	3749026750	Baudino	MÃ¤rta	M	1989-08-04	Toulouse	CCH	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	4CMC	6839631796	Patise	InÃ¨s	M	1966-09-28	Ploemeur	ADJ	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	4CMC	4966716764	Stanfield	ChloÃ©	M	1972-01-07	Versailles	SCH	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	4CMC	3440857093	Ovitts	MarlÃ¨ne	F	1969-09-24	Maisons-Laffitte	SGT	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	4CMC	6365096437	Capner	ZhÃ¬	F	1961-11-29	Lunel	SDT	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	4CMC	5128647587	Honisch	EsbjÃ¶rn	M	1978-06-21	Avallon	SLT	OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	4CMC	4531198484	Dulwitch	FaÃ®tes	F	1991-03-10	Saint-Claude	SCH	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	4CMC	6378316295	Caller	GaÃ¯a	M	1971-09-02	La Chapelle-sur-Erdre	1CL	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	4CMC	0491451644	Olyfant	EstÃ©e	M	1994-11-27	Niort	SDT	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	4CMC	2577530048	Vallintine	ErwÃ©i	F	1974-02-06	Rennes	CPL	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	4CMC	4833748398	McGregor	LÃ©one	M	1963-12-09	Avignon	ASP	OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	4CMC	9611429320	Farnaby	InÃ¨s	M	1983-11-18	Paris 09	CPL	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	4CMC	4635053644	Zapata	EdmÃ©e	M	2004-02-15	L'Union	COL	OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	4CMC	1107341884	Vogeller	MaÃ¯lis	M	1964-11-02	AlÃ¨s	1CL	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	4CMC	2048677657	Spellworth	PersonnalisÃ©e	M	1996-11-15	Quimper	1CL	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	4CMC	4583370318	Matthieson	BÃ©nÃ©dicte	M	1971-04-09	Dijon	SGT	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	4CMC	5280422622	Chiles	AloÃ¯s	M	1985-04-25	Pau	SDT	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	4CMC	0308343999	Gasson	MÃ©ghane	F	1996-04-03	Paris 12	CPL	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	4CMC	8425781019	Mabbot	EstÃ¨ve	M	1984-09-20	Vendargues	1CL	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	4CMC	1800272510	Rudloff	GÃ¶rel	M	2001-12-11	Lavaur	1CL	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	4CMC	2555150722	Upson	NadÃ¨ge	M	2004-03-20	Paris La DÃ©fense	SCH	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	4CMC	2655315316	Mitroshinov	MaÃ«lyss	F	1984-03-23	Lyon	ADJ	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	4CMC	6703174946	Cluff	MarylÃ¨ne	M	1987-05-27	Saint-Quentin-en-Yvelines	1CL	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	4CMC	6805022525	Aikman	AgnÃ¨s	F	2003-12-22	Lyon	CNE	OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	4CMC	6673937033	Concklin	MÃ©n	F	1993-08-12	Rungis	CCH	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	4CMC	8444848697	Stoggell	Marie-thÃ©rÃ¨se	M	1966-06-23	Saint-Avertin	COL	OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	4CMC	0866980784	Spada	LÃ©ana	F	1985-05-13	Lyon	SDT	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	4CMC	6959851491	Exell	RÃ©jane	M	1995-03-27	Villeneuve-lÃ¨s-Avignon	1CL	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	4CMC	2365043038	O'Luby	AlmÃ©rinda	M	1966-06-25	Rivesaltes	ADC	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	4CMC	7466680607	Sinclar	MÃ©thode	M	1998-11-24	Saint-Ã‰grÃ¨ve	ADJ	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	4CMC	1216659826	Evert	LysÃ©a	F	2001-11-17	Istres	SDT	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	4CMC	9996400735	Dudeney	AloÃ¯s	F	1973-12-17	Montpellier	SLT	OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	4CMC	9290975342	Buckmaster	BÃ©nÃ©dicte	M	1984-02-06	Agen	1CL	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	4CMC	4446060724	Sickamore	MaÃ¯lys	F	1981-10-05	Lescar	ADC	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	4CMC	0444879129	Reggiani	KÃ¹	F	1984-07-26	Istres	SGT	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	4CMC	4770408056	Haycraft	KuÃ­	M	1963-12-22	Cherbourg-Octeville	SDT	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	4CMC	7955627318	Wilcot	LÃ i	M	1970-09-11	Noisy-le-Grand	SGT	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	4CMC	3386914209	Kamenar	RÃ©becca	M	1979-01-06	BesanÃ§on	SDT	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	4CMC	8952965957	Ley	SÃ²ng	F	1973-03-06	Paris 16	1CL	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	4CMC	6466724522	McLoughlin	Ã…ke	F	1995-10-13	Cholet	SCH	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	4CMC	9307862079	Filipputti	ZoÃ©	F	2001-03-29	CompiÃ¨gne	SDT	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	4CMC	7546395968	Egdell	RÃ©becca	M	1988-11-12	Toulon	CPL	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	4CMC	6922695879	McCambrois	MagdalÃ¨ne	F	2000-09-10	Angers	1CL	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	4CMC	0007071159	Finnimore	YÃ¡o	F	1972-08-31	Le Havre	1CL	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	4CMC	1736146076	Wombwell	JosÃ©e	M	1976-06-05	Paris 20	MAJ	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	4CMC	2760309142	Amar	ElÃ©a	M	1971-05-15	Palaiseau	1CL	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	4CMC	1587883376	Sprowles	MÃ©lissandre	M	1987-07-13	Paris La DÃ©fense	CPL	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	4CMC	1737639637	Dodswell	LÃ©n	M	1972-05-26	CarriÃ¨res-sur-Seine	SDT	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	4CMC	3777544566	Raitt	LÃ i	F	1994-06-20	Paris 13	CPL	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	4CMC	0932663788	Luty	PÃ²	M	1978-08-06	Roanne	SDT	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	4CMC	3601087944	Szymanowski	MaÃ©na	F	1961-02-19	LocminÃ©	LTN	OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	5CMC	9253287217	MacTrustam	HÃ©lÃ¨na	M	1992-11-11	Lyon	ADJ	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	5CMC	0479530564	Ouslem	SÃ©rÃ©na	F	1966-09-19	Yvetot	LTN	OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	5CMC	3125127912	Beck	AngÃ©lique	M	1962-06-26	Saint-Fargeau-Ponthierry	CPL	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	5CMC	2381724907	Clint	RuÃ¬	M	1989-08-07	Sophia Antipolis	SCH	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	5CMC	5522003618	Lanphier	AgnÃ¨s	F	1996-06-07	Meylan	ADJ	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	5CMC	9833956289	Abdy	EstÃ¨ve	F	1963-04-07	Romilly-sur-Seine	SGT	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	5CMC	5988870465	Rymmer	ClÃ©opatre	M	1992-07-13	Montpellier	1CL	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	5CMC	8979999674	Case	EstÃ¨ve	F	1976-04-25	Aubenas	COL	OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	5CMC	3947905092	Mewis	PublicitÃ©	F	1970-12-27	Soissons	CPL	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	5CMC	4424182975	Le land	PÃ©nÃ©lope	M	1990-07-13	Eybens	1CL	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	5CMC	5751279840	McGerr	ZoÃ©	M	2001-06-24	Toulouse	LTN	OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	5CMC	5893162773	Leere	MÃ¥ns	M	1998-08-03	Annecy	SDT	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	5CMC	7543825767	Gaither	FrÃ©dÃ©rique	F	2000-12-29	Poligny	1CL	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	5CMC	7028545369	Pontefract	ClÃ©opatre	F	2001-08-07	Charenton-le-Pont	LTN	OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	5CMC	0445397810	Bennie	LÃ©ane	M	1979-06-27	Le Mans	ADC	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	5CMC	3377456465	Vanacci	MaÃ¯wenn	F	1984-03-10	Poitiers	SDT	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	5CMC	1654692565	Gavan	MÃ¥rten	M	1965-02-12	Troyes	CCH	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	5CMC	2815070839	Dwelly	DÃ 	M	1982-09-07	Reims	SDT	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	5CMC	9063019629	Swanborough	BÃ©rengÃ¨re	F	1970-05-09	Lyon	1CL	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	5CMC	1883084334	Golly	BÃ©rÃ©nice	M	1968-07-21	MontbÃ©liard	SGT	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	5CMC	9100707805	Blaxeland	AmÃ©lie	F	2003-03-02	Nantes	CCH	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	5CMC	9231121685	Hulmes	GwenaÃ«lle	F	2000-07-22	DÃ©cines-Charpieu	1CL	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	5CMC	4033677712	Likely	GaÃ«lle	F	1987-11-06	Lyon	SDT	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	5CMC	4748511427	Mell	AthÃ©na	F	1983-01-09	Tours	SDT	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	5CMC	5508310711	Vivians	LÃ©onie	M	1996-06-30	Metz	1CL	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	5CMC	1176780573	Jewes	YÃº	F	1980-12-27	Arnage	LTN	OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	5CMC	4751653016	Whyley	GÃ¶ran	M	1965-04-15	Puget-sur-Argens	ADJ	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	5CMC	4951889862	Gauson	KÃ©vina	M	1973-04-30	Montreuil	SDT	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	5CMC	5961056929	Burgis	NoÃ©mie	F	1984-11-10	Orange	SCH	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	5CMC	1165667681	Galbraeth	IrÃ¨ne	F	1994-12-12	Cergy-Pontoise	1CL	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	5CMC	6610110158	Boole	MaÃ¯wenn	M	1992-03-03	Apt	1CL	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	5CMC	5189037819	Pearsall	BÃ©cassine	M	1969-12-02	Troyes	SCH	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	5CMC	2916326960	Maberley	FÃ¨i	F	1989-05-30	LocminÃ©	MAJ	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	5CMC	5949912039	Guitton	LÃ©one	F	2001-08-24	Montpellier	CPL	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	5CMC	1189580594	Jachimiak	InÃ¨s	M	1980-03-12	Ivry-sur-Seine	SGT	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	5CMC	2331758670	Aireton	MaÃ¯	F	1999-09-07	OrlÃ©ans	SDT	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	5CMC	9224950922	De Santos	MaÃ«lle	M	1990-04-22	Paris 17	1CL	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	5CMC	7786652183	Hadkins	AnaÃ¯s	F	1960-06-03	Morez	ADC	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	5CMC	0215346947	Takle	LÃ©onie	F	1986-05-14	Nantes	1CL	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	5CMC	6177580564	Feuell	ClÃ©mentine	F	1995-01-25	Paris La DÃ©fense	SGT	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	5CMC	4886299598	Mardy	CÃ©cile	M	2001-10-22	Dijon	SDT	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	5CMC	5469733777	Glowacz	CinÃ©ma	F	1975-04-10	Blois	CPL	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	5CMC	0476281075	Deakes	MylÃ¨ne	F	1966-06-27	Caluire-et-Cuire	ASP	OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	5CMC	5772264591	MacClure	MÃ©lys	F	1966-01-19	Nantes	SDT	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	5CMC	4190628670	Iglesias	Marie-hÃ©lÃ¨ne	M	1967-08-21	Quimper	SDT	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	5CMC	9172213760	Antram	LoÃ¯s	M	1999-02-07	Sedan	COL	OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	5CMC	1994778679	Eve	NoÃ©mie	F	1972-06-14	Pau	SDT	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	5CMC	9223618681	Face	MaÃ«lyss	F	1976-05-23	Ã‰vry	SLT	OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	5CMC	8963147304	Josifovitz	EliÃ¨s	M	2002-08-25	Clermont-Ferrand	ADC	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	5CMC	0683618105	Kamena	VÃ©ronique	F	1970-01-17	Roissy Charles-de-Gaulle	1CL	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	5CMC	4909058125	Jahnke	ThÃ©rÃ¨sa	F	1981-04-20	Ã‰pinal	SLT	OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	5CMC	2439546410	Melville	CunÃ©gonde	F	1965-09-06	Perpignan	ASP	OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	5CMC	4887673418	Readwood	BÃ¶rje	M	1976-04-20	Niort	ASP	OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	5CMC	8359128960	Davenall	AudrÃ©anne	M	1967-07-09	Sallanches	CPL	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	5CMC	5546780495	Starbeck	PÃ©nÃ©lope	M	1965-04-05	Le Mans	1CL	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	5CMC	5261804590	Dhenin	Marie-franÃ§oise	M	1966-04-03	Argentan	SGT	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	5CMC	7931708962	Gomer	ClÃ©a	M	1997-06-07	Cluses	SCH	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	5CMC	0475953126	Sayce	AndrÃ©a	F	1962-07-22	Troyes	CNE	OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	5CMC	8504705382	Dinzey	StÃ©vina	F	1961-01-22	Cahors	1CL	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	5CMC	3481041233	Gaymer	YÃº	M	1990-10-05	Paris 08	SGT	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	5CMC	5753698557	Grigaut	EstÃ¨ve	M	2000-03-13	Ã‰vreux	SDT	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	5CMC	0724612289	Mosdall	SolÃ¨ne	F	1962-08-27	Roissy Charles-de-Gaulle	CPL	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	5CMC	4468092963	Neiland	InÃ¨s	F	1988-12-07	Ajaccio	SDT	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	5CMC	3002491705	Thickett	MaÃ©na	M	1960-11-16	Melun	ADJ	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	5CMC	4086722534	Kubista	AnaÃ¯s	F	1962-11-25	Calais	1CL	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	5CMC	3679294468	Yepiskov	AdÃ¨le	M	1965-03-05	Toulouse	CNE	OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	5CMC	5214691890	Marlen	RuÃ²	M	1988-06-07	Paris 06	1CL	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	5CMC	7028815994	Pluck	InÃ¨s	M	1988-12-25	Ã‰vreux	CCH	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	5CMC	3633994459	Ensley	MaÃ¯	F	2004-01-11	Nogent-sur-Marne	SCH	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	5CMC	0291769098	Reeks	Marie-noÃ«l	M	1999-06-08	Orvault	SCH	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	CCL	6892987303	Eubank	LucrÃ¨ce	F	1969-06-21	Marne-la-VallÃ©e	SGT	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	CCL	2272406432	Juanes	ClÃ©lia	F	1995-06-29	Floirac	1CL	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	CCL	2389669700	Ferreiro	GÃ¶rel	M	1993-05-06	Nanterre	SCH	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	CCL	5065797382	Mulcock	UÃ²	M	1982-10-24	Lyon	ASP	OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	CCL	2843152127	Broddle	NÃ©lie	M	1983-02-18	Goussainville	SDT	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	CCL	0927298929	Darridon	AnnotÃ©s	F	1990-08-18	Poitiers	CNE	OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	CCL	9990957282	MacGilrewy	DaphnÃ©e	M	2000-08-17	Limoges	SDT	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	CCL	9338902501	O'Dowd	AndrÃ©a	M	1998-02-25	Croix	SCH	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	CCL	9871789068	O' Gara	RÃ©gine	M	1989-10-25	Reims	SCH	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	CCL	4536917055	Cheverell	AgnÃ¨s	M	1972-06-11	Ancenis	ADJ	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	CCL	7542235346	Bridgwater	LÃ i	F	1988-05-15	Lyon	1CL	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	CCL	7881564245	Redpath	AnnotÃ©s	F	1969-02-14	Pau	CNE	OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	CCL	7513156913	Nursey	SÃ©lÃ¨ne	M	1963-12-17	BesanÃ§on	SCH	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	CCL	8370531768	Morrant	RenÃ©e	M	2003-07-08	Rungis	CPL	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	CCL	0929782127	Pardal	LysÃ©a	M	1961-02-11	Lille	SDT	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	CCL	8660804910	Turfrey	JudicaÃ«l	F	1983-04-11	Bonneville	LTN	OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	CCL	8545674414	Backshell	AthÃ©na	F	1992-01-17	Le Blanc-Mesnil	SDT	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	CCL	3847851853	Huffey	MÃ©n	M	1987-11-02	Lille	CPL	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	CCL	2738830668	Heatlie	MÃ©lodie	M	1968-07-20	Morangis	SDT	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	CCL	1438497547	Roxburch	MaÃ«lyss	F	2004-01-01	La Roche-sur-Yon	LTN	OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	CCL	7813429508	MacConneely	ClÃ©lia	F	1976-05-20	Altkirch	CPL	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	CCL	1691723878	Vanner	MÃ©lodie	M	1971-09-27	Le Grand-Quevilly	COL	OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	CCL	7612879123	Foale	ChloÃ©	M	1986-12-04	ChÃ¢teauroux	ADJ	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	CCL	5000327454	Gow	LÃ©a	M	2000-02-06	Montpellier	ADJ	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	CCL	0403266351	McKendo	NÃ©hÃ©mie	M	1973-10-15	Aubagne	LTN	OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	CCL	8565074978	Linder	MahÃ©lie	M	1963-04-17	Auch	SDT	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	CCL	2732207977	Ziemens	AnaÃ«lle	M	1990-02-16	Mazamet	LTN	OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	CCL	6618804345	Ayars	AÃ­	M	2003-04-30	Angers	SCH	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	CCL	7967847903	Devita	MaÃ«line	F	1988-02-23	NÃ®mes	SGT	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	CCL	5468035324	Rawstorne	PÃ©nÃ©lope	F	1975-06-20	Paris 18	1CL	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	CCL	6936932010	Bartolini	MÃ©lanie	M	1973-07-22	Nogent-sur-Marne	SGT	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	CCL	7052929856	Cridlon	DÃ 	F	2003-08-05	Nemours	1CL	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	CCL	7080788617	Scotchmur	MÃ©lys	F	1975-05-15	Avignon	SGT	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	CCL	7904843617	Marjoribanks	MichÃ¨le	F	1962-08-29	Tours	SDT	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	CCL	7852106935	Boast	CinÃ©ma	M	1969-02-05	La Valette-du-Var	COL	OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	CCL	1084490811	Stanbury	TÃ¡ng	F	1972-07-03	Cognac	1CL	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	CCL	0312348738	Lockton	NaÃ«lle	M	1992-04-19	Montreuil	CCH	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	CCL	5362157760	Matteini	CloÃ©	F	1963-07-13	Quetigny	SLT	OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	CCL	5229464488	Meenehan	OcÃ©ane	M	1985-05-14	Toulouse	1CL	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	CCL	1866047906	Colvine	LaÃ¯la	F	1968-01-31	Nice	1CL	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	CCL	4841120440	Lorraine	MÃ©lys	F	1974-11-29	Haguenau	ADJ	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	CCL	2889766926	Fairlie	MÃ©lys	F	1998-08-26	Angers	SDT	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	CCL	4227285186	Beynkn	AnnotÃ©e	F	1991-06-28	Paris 19	CPL	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	CCL	1488301689	Stalf	AngÃ¨le	F	1986-12-09	Brest	SDT	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	CCL	3605529542	Combe	DafnÃ©e	M	1970-12-03	ChÃ¢tillon	MAJ	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	CCL	4922740198	Gosnoll	MaÃ¯	F	1998-08-06	Strasbourg	ADC	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	CCL	5800713952	Haycock	CinÃ©ma	F	1999-07-28	Kingersheim	CCH	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	CCL	2519960094	Vigar	Ã–rjan	M	1989-06-28	Issoire	SDT	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	CCL	2003722270	Canero	Ã–rjan	F	1970-12-11	Toulouse	1CL	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	CCL	7268452640	Grosvenor	MilÃ©na	F	1980-06-04	Dijon	SLT	OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	CCL	7169891549	Dallas	AlmÃ©rinda	F	1995-07-12	Ancenis	1CL	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	CCL	7900360727	Newsham	AlmÃ©rinda	F	1970-06-19	Brest	CPL	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	CCL	8635401883	Emery	AnaÃ«lle	F	2002-10-30	Haguenau	SDT	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	CCL	4076444744	Godlip	CloÃ©	F	1986-10-20	OrlÃ©ans	1CL	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	CCL	2950187048	Grigolashvill	BjÃ¶rn	M	1984-10-14	Lomme	CCH	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	CCL	4284554301	Tockell	CloÃ©	M	1984-08-10	Rungis	SDT	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	CCL	6822820434	Allcoat	AnaÃ©	M	1991-08-14	Paris 13	SCH	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	CCL	7801457978	Stidever	AudrÃ©anne	M	1988-06-07	Voiron	ASP	OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	CCL	7006738083	Bea	GwenaÃ«lle	M	1997-07-22	Bobigny	SCH	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	CCL	3313013775	Bloys	MÃ©lina	F	1963-01-14	CrÃ©py-en-Valois	1CL	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	CCL	1412547873	Tejada	JosÃ©e	M	2003-01-06	Paris 09	CPL	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	CCL	6633798849	Denniss	RÃ¡o	F	1991-08-22	Saint-Denis	1CL	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	CCL	4947976772	Firminger	LoÃ¯s	M	1993-03-22	Longjumeau	ADC	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	CCL	3223663347	Dornin	HÃ¥kan	F	1987-10-28	OrlÃ©ans	SGT	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	CCL	3409052631	Stearn	CunÃ©gonde	M	1974-08-07	Saint-Pierre-Montlimart	ASP	OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	CCL	7021231032	Castagne	Marie-josÃ©e	F	1980-03-02	Caen	1CL	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	CCL	6455744055	Bellenie	OphÃ©lie	M	1984-05-22	Saint-Chamond	SGT	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	CCL	5408685748	Loud	PÃ¥l	M	1975-06-29	Blois	SGT	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	CCL	4509167040	Alison	CunÃ©gonde	F	1968-06-29	Niort	1CL	NON-OFFICIER
AA	France	Armee de Terre	RMED	COMLOG	CCL	6013237018	Couve	MahÃ©lie	F	1981-02-22	Paris 03	SDT	NON-OFFICIER
\.


--
-- Data for Name: pays; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.pays (codepays, pays) FROM stdin;
AA	France
AF	Afghanistan
ZA	Afrique du Sud
AX	Ã…land, ÃŽles
AL	Albanie
DZ	AlgÃ©rie
DE	Allemagne
DD	Allemagne de l'EST
AD	Andorre
AO	Angola
AI	Anguilla
AQ	Antarctique
AG	Antigua et Barbuda
AN	Antilles nÃ©erlandaises
SA	Arabie Saoudite
AR	Argentine
AM	ArmÃ©nie
AW	Aruba
AU	Australie
AT	Autriche
AZ	AzerbaÃ¯djan
BS	Bahamas
BH	Bahrein
BD	Bangladesh
BB	Barbade
BY	BÃ©larus
BE	Belgique
BZ	BÃ©lize
BJ	BÃ©nin
BM	Bermudes
BT	Bhoutan
BO	Bolivie (Ã‰tat plurinational de)
BQ	Bonaire, Saint-Eustache et Saba
BA	Bosnie-HerzÃ©govine
BW	Botswana
BV	Bouvet, Ile
BR	BrÃ©sil
BN	BrunÃ©i Darussalam
BG	Bulgarie
BF	Burkina Faso
BI	Burundi
CV	Cabo Verde
KY	CaÃ¯mans, Iles
KH	Cambodge
CM	Cameroun
CA	Canada
CL	Chili
CN	Chine
CX	Christmas, Ã®le
CY	Chypre
CC	Cocos/Keeling (ÃŽles)
CO	Colombie
KM	Comores
CG	Congo
CD	Congo, RÃ©publique dÃ©mocratique du
CK	Cook, Iles
KR	CorÃ©e, RÃ©publique de
KP	CorÃ©e, RÃ©publique populaire dÃ©mocratique de
CR	Costa Rica
CI	CÃ´te d'Ivoire
HR	Croatie
CU	Cuba
CW	CuraÃ§ao
DK	Danemark
DJ	Djibouti
DO	Dominicaine, RÃ©publique
DM	Dominique
EG	Egypte
SV	El Salvador
AE	Emirats arabes unis
EC	Equateur
ER	ErythrÃ©e
ES	Espagne
EE	Estonie
US	Etats-Unis d'AmÃ©rique
ET	Ethiopie
FK	Falkland/Malouines (ÃŽles)
FO	FÃ©roÃ©, Ã®les
FJ	Fidji
FI	Finlande
GA	Gabon
GM	Gambie
GE	GÃ©orgie
GS	GÃ©orgie du sud et les Ã®les Sandwich du sud
GH	Ghana
GI	Gibraltar
GR	GrÃ¨ce
GD	Grenade
GL	Groenland
GP	Guadeloupe
GU	Guam
GT	Guatemala
GG	Guernesey
GN	GuinÃ©e
GW	GuinÃ©e-Bissau
GQ	GuinÃ©e Ã©quatoriale
GY	Guyana
GF	Guyane franÃ§aise
HT	HaÃ¯ti
HM	Heard, Ile et MacDonald, Ã®les
HN	Honduras
HK	Hong Kong
HU	Hongrie
IM	ÃŽle de Man
UM	ÃŽles mineures Ã©loignÃ©es des Etats-Unis
VG	ÃŽles vierges britanniques
VI	ÃŽles vierges des Etats-Unis
IN	Inde
IO	Indien (Territoire britannique de l'ocÃ©an)
ID	IndonÃ©sie
IR	Iran, RÃ©publique islamique d'
IQ	Iraq
IE	Irlande
IS	Islande
IL	IsraÃ«l
IT	Italie
JM	JamaÃ¯que
JP	Japon
JE	Jersey
JO	Jordanie
KZ	Kazakhstan
KE	Kenya
KG	Kirghizistan
KI	Kiribati
KW	KoweÃ¯t
LA	Lao, RÃ©publique dÃ©mocratique populaire
LS	Lesotho
LV	Lettonie
LB	Liban
LR	LibÃ©ria
LY	Libye
LI	Liechtenstein
LT	Lituanie
LU	Luxembourg
MO	Macao
MK	MacÃ©doine, l'ex-RÃ©publique yougoslave de
MG	Madagascar
MY	Malaisie
MW	Malawi
MV	Maldives
ML	Mali
MT	Malte
MP	Mariannes du nord, Iles
MA	Maroc
MH	Marshall, Iles
MQ	Martinique
MU	Maurice
MR	Mauritanie
YT	Mayotte
MX	Mexique
FM	MicronÃ©sie, Etats FÃ©dÃ©rÃ©s de
MD	Moldova, RÃ©publique de
MC	Monaco
MN	Mongolie
ME	MontÃ©nÃ©gro
MS	Montserrat
MZ	Mozambique
MM	Myanmar
NA	Namibie
NR	Nauru
NP	NÃ©pal
NI	Nicaragua
NE	Niger
NG	NigÃ©ria
NU	Niue
NF	Norfolk, Ile
NO	NorvÃ¨ge
NC	Nouvelle-CalÃ©donie
NZ	Nouvelle-ZÃ©lande
OM	Oman
UG	Ouganda
UZ	OuzbÃ©kistan
PK	Pakistan
PW	Palaos
PS	Palestine, Etat de
PA	Panama
PG	Papouasie-Nouvelle-GuinÃ©e
PY	Paraguay
NL	Pays-Bas
XX	Pays inconnu
ZZ	Pays multiples
PE	PÃ©rou
PH	Philippines
PN	Pitcairn
PL	Pologne
PF	PolynÃ©sie franÃ§aise
PR	Porto Rico
PT	Portugal
QA	Qatar
SY	RÃ©publique arabe syrienne
CF	RÃ©publique centrafricaine
RE	RÃ©union
RO	Roumanie
GB	Royaume-Uni de Grande-Bretagne et d'Irlande du Nord
RU	Russie, FÃ©dÃ©ration de
RW	Rwanda
EH	Sahara occidental
BL	Saint-BarthÃ©lemy
KN	Saint-Kitts-et-Nevis
SM	Saint-Marin
MF	Saint-Martin (partie franÃ§aise)
SX	Saint-Martin (partie nÃ©erlandaise)
PM	Saint-Pierre-et-Miquelon
VA	Saint-SiÃ¨ge
VC	Saint-Vincent-et-les-Grenadines
SH	Sainte-HÃ©lÃ¨ne, Ascension et Tristan da Cunha
LC	Sainte-Lucie
SB	Salomon, Iles
WS	Samoa
AS	Samoa amÃ©ricaines
ST	Sao TomÃ©-et-Principe
SN	SÃ©nÃ©gal
RS	Serbie
SC	Seychelles
SL	Sierra Leone
SG	Singapour
SK	Slovaquie
SI	SlovÃ©nie
SO	Somalie
SD	Soudan
SS	Soudan du Sud
LK	Sri Lanka
SE	SuÃ¨de
CH	Suisse
SR	Suriname
SJ	Svalbard et Ã®le Jan Mayen
SZ	Swaziland
TJ	Tadjikistan
TW	TaÃ¯wan, Province de Chine
TZ	Tanzanie, RÃ©publique unie de
TD	Tchad
CS	TchÃ©coslovaquie
CZ	TchÃ¨que, RÃ©publique
TF	Terres australes franÃ§aises
TH	ThaÃ¯lande
TL	Timor-Leste
TG	Togo
TK	Tokelau
TO	Tonga
TT	TrinitÃ©-et-Tobago
TN	Tunisie
TM	TurkmÃ©nistan
TC	Turks-et-CaÃ¯cos (ÃŽles)
TR	Turquie
TV	Tuvalu
UA	Ukraine
SU	URSS
UY	Uruguay
VU	Vanuatu
VE	Venezuela (RÃ©publique bolivarienne du)
VN	Viet Nam
VD	Viet Nam (Sud)
WF	Wallis et Futuna
YE	YÃ©men
YU	Yougoslavie
ZR	ZaÃ¯re
ZM	Zambie
ZW	Zimbabwe
\.


--
-- Data for Name: produit; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.produit (idproduit, idmagasin, nomproduit, qteproduit, conditionstockage, dureestockage) FROM stdin;
\.


--
-- Data for Name: salle_soin; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.salle_soin (idzfsante, coordonneutm, libeletype, idsalle, typesoin, capacite) FROM stdin;
1	UTM4321-9876	ZFSAN	1	HOS	{}
1	UTM4321-9876	ZFSAN	2	HOS	{}
1	UTM4321-9876	ZFSAN	3	HOS	{}
1	UTM4321-9876	ZFSAN	4	HOS	{}
1	UTM4321-9876	ZFSAN	6	HOS	{}
1	UTM4321-9876	ZFSAN	7	HOS	{}
1	UTM4321-9876	ZFSAN	9	HOS	{}
1	UTM4321-9876	ZFSAN	11	HOS	{}
1	UTM4321-9876	ZFSAN	13	HOS	{}
1	UTM4321-9876	ZFSAN	14	HOS	{}
1	UTM4321-9876	ZFSAN	15	HOS	{}
1	UTM4321-9876	ZFSAN	16	HOS	{}
1	UTM4321-9876	ZFSAN	17	HOS	{}
1	UTM4321-9876	ZFSAN	18	HOS	{}
1	UTM4321-9876	ZFSAN	19	HOS	{}
1	UTM4321-9876	ZFSAN	20	HOS	{}
1	UTM4321-9876	ZFSAN	21	HOS	{}
1	UTM4321-9876	ZFSAN	22	HOS	{}
1	UTM4321-9876	ZFSAN	23	HOS	{}
1	UTM4321-9876	ZFSAN	24	HOS	{}
1	UTM4321-9876	ZFSAN	25	HOS	{}
1	UTM4321-9876	ZFSAN	26	HOS	{}
1	UTM4321-9876	ZFSAN	27	HOS	{}
1	UTM4321-9876	ZFSAN	28	HOS	{}
1	UTM4321-9876	ZFSAN	29	HOS	{}
1	UTM4321-9876	ZFSAN	30	HOS	{}
1	UTM4321-9876	ZFSAN	31	HOS	{}
1	UTM4321-9876	ZFSAN	32	HOS	{}
1	UTM4321-9876	ZFSAN	33	HOS	{}
1	UTM4321-9876	ZFSAN	34	HOS	{}
1	UTM4321-9876	ZFSAN	35	HOS	{}
1	UTM4321-9876	ZFSAN	36	HOS	{}
1	UTM4321-9876	ZFSAN	37	HOS	{}
1	UTM4321-9876	ZFSAN	38	HOS	{}
1	UTM4321-9876	ZFSAN	39	HOS	{}
1	UTM4321-9876	ZFSAN	40	HOS	{}
1	UTM4321-9876	ZFSAN	41	HOS	{}
1	UTM4321-9876	ZFSAN	42	HOS	{}
1	UTM4321-9876	ZFSAN	43	HOS	{}
1	UTM4321-9876	ZFSAN	44	HOS	{}
1	UTM4321-9876	ZFSAN	45	HOS	{}
1	UTM4321-9876	ZFSAN	12	HOS	{2}
1	UTM4321-9876	ZFSAN	8	HOS	{}
1	UTM4321-9876	ZFSAN	10	HOS	{1,9}
1	UTM4321-9876	ZFSAN	5	HOS	{8}
1	UTM4321-9876	ZFSAN	46	HOS	{}
1	UTM4321-9876	ZFSAN	47	HOS	{}
1	UTM4321-9876	ZFSAN	48	HOS	{}
1	UTM4321-9876	ZFSAN	49	HOS	{}
1	UTM4321-9876	ZFSAN	50	HOS	{}
1	UTM4321-9876	ZFSAN	51	HOS	{}
1	UTM4321-9876	ZFSAN	52	HOS	{}
1	UTM4321-9876	ZFSAN	53	HOS	{}
1	UTM4321-9876	ZFSAN	54	HOS	{}
1	UTM4321-9876	ZFSAN	55	HOS	{}
1	UTM4321-9876	ZFSAN	81	BO	{}
1	UTM4321-9876	ZFSAN	82	BO	{}
1	UTM4321-9876	ZFSAN	83	BO	{}
1	UTM4321-9876	ZFSAN	84	BO	{}
1	UTM4321-9876	ZFSAN	85	BO	{}
1	UTM4321-9876	ZFSAN	86	BO	{}
1	UTM4321-9876	ZFSAN	87	BO	{}
1	UTM4321-9876	ZFSAN	88	BO	{}
1	UTM4321-9876	ZFSAN	89	BO	{}
1	UTM4321-9876	ZFSAN	90	BO	{}
1	UTM4321-9876	ZFSAN	91	REA	{}
1	UTM4321-9876	ZFSAN	92	REA	{}
1	UTM4321-9876	ZFSAN	93	REA	{}
1	UTM4321-9876	ZFSAN	94	REA	{}
1	UTM4321-9876	ZFSAN	95	REA	{}
1	UTM4321-9876	ZFSAN	96	REA	{}
1	UTM4321-9876	ZFSAN	97	REA	{}
1	UTM4321-9876	ZFSAN	98	REA	{}
1	UTM4321-9876	ZFSAN	99	REA	{}
1	UTM4321-9876	ZFSAN	100	REA	{}
1	UTM4321-9876	ZFSAN	56	HOS	{}
1	UTM4321-9876	ZFSAN	57	HOS	{}
1	UTM4321-9876	ZFSAN	58	HOS	{}
1	UTM4321-9876	ZFSAN	59	HOS	{}
1	UTM4321-9876	ZFSAN	60	HOS	{}
1	UTM4321-9876	ZFSAN	61	HOS	{}
1	UTM4321-9876	ZFSAN	62	HOS	{}
1	UTM4321-9876	ZFSAN	63	HOS	{}
1	UTM4321-9876	ZFSAN	64	HOS	{}
1	UTM4321-9876	ZFSAN	65	HOS	{}
1	UTM4321-9876	ZFSAN	66	HOS	{}
1	UTM4321-9876	ZFSAN	67	HOS	{}
1	UTM4321-9876	ZFSAN	68	HOS	{}
1	UTM4321-9876	ZFSAN	69	HOS	{}
1	UTM4321-9876	ZFSAN	70	HOS	{}
1	UTM4321-9876	ZFSAN	71	HOS	{}
1	UTM4321-9876	ZFSAN	72	HOS	{}
1	UTM4321-9876	ZFSAN	73	HOS	{}
1	UTM4321-9876	ZFSAN	74	HOS	{}
1	UTM4321-9876	ZFSAN	75	HOS	{}
1	UTM4321-9876	ZFSAN	76	HOS	{}
1	UTM4321-9876	ZFSAN	77	HOS	{}
1	UTM4321-9876	ZFSAN	78	HOS	{}
1	UTM4321-9876	ZFSAN	79	HOS	{}
1	UTM4321-9876	ZFSAN	80	HOS	{}
\.


--
-- Data for Name: sortiestrategiquezfsan; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.sortiestrategiquezfsan (idblesse, gdhdemandesortie) FROM stdin;
\.


--
-- Data for Name: type_vt; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.type_vt (idtypevt) FROM stdin;
Blinde
\.


--
-- Data for Name: unite; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.unite (codepays, pays, nomarmee, nomunite, div_bri) FROM stdin;
FR	France	Armee de Terre	RMED	COMLOG
\.


--
-- Data for Name: unite_elementaire; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.unite_elementaire (codepays, pays, nomarmee, nomunite, div_bri, unite_elementaire) FROM stdin;
FR	France	Armee de Terre	RMED	COMLOG	1CMC
FR	France	Armee de Terre	RMED	COMLOG	2CMC
FR	France	Armee de Terre	RMED	COMLOG	3CMC
FR	France	Armee de Terre	RMED	COMLOG	4CMC
FR	France	Armee de Terre	RMED	COMLOG	5CMC
FR	France	Armee de Terre	RMED	COMLOG	CCL
\.


--
-- Data for Name: vecteur_transport; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.vecteur_transport (idtypevt, idcat, libelecategorie, modecirculation, idcapacite, capa, capb, capc, idvt, appellationvt) FROM stdin;
Blinde	VAB	VEHICULE A L'AVANT BLINDE	VR	1	3	3	4	JTJHY7AX1F4154859	VABSAN
Blinde	VAB	VEHICULE A L'AVANT BLINDE	VR	1	3	3	4	WAUVT58E83A065006	VABSAN
Blinde	VAB	VEHICULE A L'AVANT BLINDE	VR	1	3	3	4	1G6DF577290201463	VABSAN
Blinde	VAB	VEHICULE A L'AVANT BLINDE	VR	1	3	3	4	2C3CDZBT5FH447526	VABSAN
Blinde	VAB	VEHICULE A L'AVANT BLINDE	VR	1	3	3	4	5GADV23L26D293374	VABSAN
Blinde	VAB	VEHICULE A L'AVANT BLINDE	VR	1	3	3	4	5NPEB4AC5CH561091	VABSAN
Blinde	VAB	VEHICULE A L'AVANT BLINDE	VR	1	3	3	4	WBAWV1C58AP425805	VABSAN
Blinde	VAB	VEHICULE A L'AVANT BLINDE	VR	1	3	3	4	WAUFL44D82N508936	VABSAN
Blinde	VAB	VEHICULE A L'AVANT BLINDE	VR	1	3	3	4	4A31K5DF6BE965670	VABSAN
Blinde	VAB	VEHICULE A L'AVANT BLINDE	VR	1	3	3	4	WAUDF98E16A196504	VABSAN
Blinde	VAB	VEHICULE A L'AVANT BLINDE	VR	1	3	3	4	1FMEU2DEXAU722980	VABSAN
Blinde	VAB	VEHICULE A L'AVANT BLINDE	VR	1	3	3	4	WUAGNAFG5BN749511	VABSAN
Blinde	VAB	VEHICULE A L'AVANT BLINDE	VR	1	3	3	4	1G6DN57U870444197	VABSAN
Blinde	VAB	VEHICULE A L'AVANT BLINDE	VR	1	3	3	4	2G4WB52K811567655	VABSAN
Blinde	VAB	VEHICULE A L'AVANT BLINDE	VR	1	3	3	4	3C6LD5AT5CG114462	VABSAN
Blinde	VAB	VEHICULE A L'AVANT BLINDE	VR	1	3	3	4	1GYS3FEJ9CR055500	VABSAN
Blinde	VAB	VEHICULE A L'AVANT BLINDE	VR	1	3	3	4	JN1CV6AR6FM439707	VABSAN
Blinde	VAB	VEHICULE A L'AVANT BLINDE	VR	1	3	3	4	WAUML44E95N806464	VABSAN
Blinde	VAB	VEHICULE A L'AVANT BLINDE	VR	1	3	3	4	1G6YV34A255131288	VABSAN
Blinde	VAB	VEHICULE A L'AVANT BLINDE	VR	1	3	3	4	JH4DC54853C056667	VABSAN
\.


--
-- Data for Name: vt_en_mission; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.vt_en_mission (numevasan, idvt) FROM stdin;
\.


--
-- Data for Name: zfsante; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.zfsante (idzfsante, coordonneutm, libeletype) FROM stdin;
1	UTM4321-9876	ZFSAN
\.


--
-- Name: idblesseseq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.idblesseseq', 10, true);


--
-- Name: idcivil; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.idcivil', 1000000000, false);


--
-- Name: numdemande_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.numdemande_seq', 2, true);


--
-- Name: numevasanseq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.numevasanseq', 2, true);


--
-- Name: accueil_blesse_en_zfsan accueil_blesse_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.accueil_blesse_en_zfsan
    ADD CONSTRAINT accueil_blesse_pkey PRIMARY KEY (idblesse);


--
-- Name: individu age; Type: CHECK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE public.individu
    ADD CONSTRAINT age CHECK ((date_naissance > '1900-01-01'::date)) NOT VALID;


--
-- Name: alertes_niveaux_produit alertes_niveaux_produit_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.alertes_niveaux_produit
    ADD CONSTRAINT alertes_niveaux_produit_pkey PRIMARY KEY (idproduit);


--
-- Name: pays allies_codepays_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pays
    ADD CONSTRAINT allies_codepays_key UNIQUE (codepays);


--
-- Name: pays allies_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pays
    ADD CONSTRAINT allies_pkey PRIMARY KEY (codepays);


--
-- Name: armee armee_nomarmee_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.armee
    ADD CONSTRAINT armee_nomarmee_key UNIQUE (nomarmee);


--
-- Name: armee armee_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.armee
    ADD CONSTRAINT armee_pkey PRIMARY KEY (nomarmee);


--
-- Name: attente_soin attentesoin_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.attente_soin
    ADD CONSTRAINT attentesoin_pkey PRIMARY KEY (idblesse);


--
-- Name: blesse blesse_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.blesse
    ADD CONSTRAINT blesse_pkey PRIMARY KEY (idblesse);


--
-- Name: capacite_transport capacite_transport_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.capacite_transport
    ADD CONSTRAINT capacite_transport_pkey PRIMARY KEY (idcapacite);


--
-- Name: categorie_vt categorie_vt_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.categorie_vt
    ADD CONSTRAINT categorie_vt_pkey PRIMARY KEY (idcat);


--
-- Name: civil civil_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.civil
    ADD CONSTRAINT civil_pkey PRIMARY KEY (matricule);


--
-- Name: demandevasan demandevasan_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.demandevasan
    ADD CONSTRAINT demandevasan_pkey PRIMARY KEY (numdemande);


--
-- Name: destination destination_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.destination
    ADD CONSTRAINT destination_pkey PRIMARY KEY (coordonneutm);


--
-- Name: disponibilite_vt dispo_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.disponibilite_vt
    ADD CONSTRAINT dispo_pkey PRIMARY KEY (idvt);


--
-- Name: div_bri div_bri_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.div_bri
    ADD CONSTRAINT div_bri_pkey PRIMARY KEY (div_bri);


--
-- Name: donnees_blesse donnees_blesse_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.donnees_blesse
    ADD CONSTRAINT donnees_blesse_pkey PRIMARY KEY (idblesse);


--
-- Name: donnees_salle_soin donnees_salle_soin_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.donnees_salle_soin
    ADD CONSTRAINT donnees_salle_soin_pkey PRIMARY KEY (idsalle);


--
-- Name: en_soin en_soin_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.en_soin
    ADD CONSTRAINT en_soin_pkey PRIMARY KEY (idblesse);


--
-- Name: evasan evasan_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.evasan
    ADD CONSTRAINT evasan_pkey PRIMARY KEY (numevasan);


--
-- Name: individu individu_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.individu
    ADD CONSTRAINT individu_pkey PRIMARY KEY (matricule);


--
-- Name: magasinsante magasinsante_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.magasinsante
    ADD CONSTRAINT magasinsante_pkey PRIMARY KEY (idmagasin);


--
-- Name: militaire matricule_militaire; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.militaire
    ADD CONSTRAINT matricule_militaire UNIQUE (matricule);


--
-- Name: produit produit_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.produit
    ADD CONSTRAINT produit_pkey PRIMARY KEY (idproduit);


--
-- Name: salle_soin salle_soin_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.salle_soin
    ADD CONSTRAINT salle_soin_pkey PRIMARY KEY (idsalle);


--
-- Name: sortiestrategiquezfsan sortiestrategiquezfsan_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sortiestrategiquezfsan
    ADD CONSTRAINT sortiestrategiquezfsan_pkey PRIMARY KEY (idblesse);


--
-- Name: type_vt type_vt_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.type_vt
    ADD CONSTRAINT type_vt_pkey PRIMARY KEY (idtypevt);


--
-- Name: unite_elementaire unite_elementaire_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.unite_elementaire
    ADD CONSTRAINT unite_elementaire_pkey PRIMARY KEY (unite_elementaire);


--
-- Name: unite unite_nomunite_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.unite
    ADD CONSTRAINT unite_nomunite_key UNIQUE (nomunite);


--
-- Name: unite unite_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.unite
    ADD CONSTRAINT unite_pkey PRIMARY KEY (nomunite);


--
-- Name: vecteur_transport vecteur_transport_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.vecteur_transport
    ADD CONSTRAINT vecteur_transport_pkey PRIMARY KEY (idvt);


--
-- Name: vt_en_mission vt_en_mission_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.vt_en_mission
    ADD CONSTRAINT vt_en_mission_pkey PRIMARY KEY (numevasan, idvt);


--
-- Name: zfsante zfsante_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.zfsante
    ADD CONSTRAINT zfsante_pkey PRIMARY KEY (idzfsante);


--
-- Name: accueil_blesse_en_zfsan accueil_blesse_en_zfsan; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER accueil_blesse_en_zfsan BEFORE INSERT OR UPDATE OF idzfsante, coordonneutm, libeletype ON public.accueil_blesse_en_zfsan FOR EACH ROW EXECUTE FUNCTION public.present_en_zfsan();


--
-- Name: demandevasan affecter_numdemandevasan_au_blesse; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER affecter_numdemandevasan_au_blesse AFTER INSERT OR UPDATE OF numdemande ON public.demandevasan FOR EACH ROW EXECUTE FUNCTION public.affecter_numdemandevasan_au_blesse();


--
-- Name: blesse ajout_blesse; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER ajout_blesse BEFORE INSERT OR UPDATE ON public.blesse FOR EACH ROW EXECUTE FUNCTION public.ajout_blesse();


--
-- Name: demandevasan ajout_demandevasan; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER ajout_demandevasan BEFORE INSERT OR UPDATE ON public.demandevasan FOR EACH ROW EXECUTE FUNCTION public.ajout_demandevasan();


--
-- Name: zfsante ajout_zone_fonctionnelle_sante; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER ajout_zone_fonctionnelle_sante BEFORE INSERT OR UPDATE ON public.zfsante FOR EACH ROW EXECUTE FUNCTION public.ajout_zone_fonctionnelle_sante();


--
-- Name: attente_soin attente_soin_en_zfsan; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER attente_soin_en_zfsan BEFORE INSERT OR UPDATE OF idzfsante, coordonneutm, libeletype ON public.attente_soin FOR EACH ROW EXECUTE FUNCTION public.present_en_zfsan();


--
-- Name: civil civil_ajout; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER civil_ajout BEFORE INSERT OR UPDATE ON public.civil FOR EACH ROW EXECUTE FUNCTION public.civil_ajout();


--
-- Name: vecteur_transport disponibilite_vt_initiale; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER disponibilite_vt_initiale AFTER INSERT OR UPDATE OF idvt ON public.vecteur_transport FOR EACH ROW EXECUTE FUNCTION public.disponibilite_vt_initiale();


--
-- Name: blesse donnees_blesse; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER donnees_blesse AFTER INSERT OR UPDATE OF idblesse, gdhblessure, gdhevacue ON public.blesse FOR EACH ROW EXECUTE FUNCTION public.donnees_blesse();


--
-- Name: en_soin en_soin; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER en_soin BEFORE INSERT OR UPDATE ON public.en_soin FOR EACH ROW EXECUTE FUNCTION public.en_soin();


--
-- Name: magasinsante magasinsante_en_zfsan; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER magasinsante_en_zfsan BEFORE INSERT OR UPDATE OF idzfsante, coordonneutm, libeletype ON public.magasinsante FOR EACH ROW EXECUTE FUNCTION public.present_en_zfsan();


--
-- Name: militaire militaire_ajout; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER militaire_ajout BEFORE INSERT OR UPDATE ON public.militaire FOR EACH ROW EXECUTE FUNCTION public.militaire_ajout();


--
-- Name: salle_soin salle_soin_en_zfsan; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER salle_soin_en_zfsan BEFORE INSERT OR UPDATE OF idzfsante, coordonneutm, libeletype ON public.salle_soin FOR EACH ROW EXECUTE FUNCTION public.present_en_zfsan();


--
-- Name: vecteur_transport vecteur_transport_ajout; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER vecteur_transport_ajout BEFORE INSERT OR UPDATE ON public.vecteur_transport FOR EACH ROW EXECUTE FUNCTION public.vecteur_transport_ajout();


--
-- Name: accueil_blesse_en_zfsan accueil_idblesse_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.accueil_blesse_en_zfsan
    ADD CONSTRAINT accueil_idblesse_fkey FOREIGN KEY (idblesse) REFERENCES public.blesse(idblesse);


--
-- Name: attente_soin attentesoin_idblesse_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.attente_soin
    ADD CONSTRAINT attentesoin_idblesse_fkey FOREIGN KEY (idblesse) REFERENCES public.blesse(idblesse);


--
-- Name: blesse blesse_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.blesse
    ADD CONSTRAINT blesse_fkey FOREIGN KEY (matricule) REFERENCES public.individu(matricule);


--
-- Name: demandevasan demandevasan_unite_elementaire; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.demandevasan
    ADD CONSTRAINT demandevasan_unite_elementaire FOREIGN KEY (unite_elementaire) REFERENCES public.unite_elementaire(unite_elementaire) NOT VALID;


--
-- Name: disponibilite_vt dispo_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.disponibilite_vt
    ADD CONSTRAINT dispo_fkey FOREIGN KEY (idvt) REFERENCES public.vecteur_transport(idvt) ON DELETE CASCADE;


--
-- Name: donnees_blesse donnees_blesse_idblesse; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.donnees_blesse
    ADD CONSTRAINT donnees_blesse_idblesse FOREIGN KEY (idblesse) REFERENCES public.blesse(idblesse) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: evasan evasan_coordonneutm1_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.evasan
    ADD CONSTRAINT evasan_coordonneutm1_fkey FOREIGN KEY (coordonneutm1) REFERENCES public.destination(coordonneutm);


--
-- Name: evasan evasan_coordonneutm_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.evasan
    ADD CONSTRAINT evasan_coordonneutm_fkey FOREIGN KEY (coordonneutm) REFERENCES public.destination(coordonneutm);


--
-- Name: evasan evasan_numdemande_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.evasan
    ADD CONSTRAINT evasan_numdemande_fkey FOREIGN KEY (numdemande) REFERENCES public.demandevasan(numdemande) NOT VALID;


--
-- Name: alertes_niveaux_produit fk_alertes_niveaux_produit_idproduit; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.alertes_niveaux_produit
    ADD CONSTRAINT fk_alertes_niveaux_produit_idproduit FOREIGN KEY (idproduit) REFERENCES public.produit(idproduit);


--
-- Name: donnees_salle_soin fk_donnees_salle_soin_idsalle; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.donnees_salle_soin
    ADD CONSTRAINT fk_donnees_salle_soin_idsalle FOREIGN KEY (idsalle) REFERENCES public.salle_soin(idsalle);


--
-- Name: en_soin fk_ensoin_idblesse; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.en_soin
    ADD CONSTRAINT fk_ensoin_idblesse FOREIGN KEY (idblesse) REFERENCES public.blesse(idblesse);


--
-- Name: en_soin fk_ensoin_idsalle; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.en_soin
    ADD CONSTRAINT fk_ensoin_idsalle FOREIGN KEY (idsalle) REFERENCES public.salle_soin(idsalle);


--
-- Name: produit fk_produit_idmagasin; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.produit
    ADD CONSTRAINT fk_produit_idmagasin FOREIGN KEY (idmagasin) REFERENCES public.magasinsante(idmagasin);


--
-- Name: vt_en_mission fk_vt_en_mission_idvt; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.vt_en_mission
    ADD CONSTRAINT fk_vt_en_mission_idvt FOREIGN KEY (idvt) REFERENCES public.vecteur_transport(idvt);


--
-- Name: vt_en_mission fk_vt_en_mission_numevasan; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.vt_en_mission
    ADD CONSTRAINT fk_vt_en_mission_numevasan FOREIGN KEY (numevasan) REFERENCES public.evasan(numevasan);


--
-- Name: sortiestrategiquezfsan sortiestrategiquezfsan_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sortiestrategiquezfsan
    ADD CONSTRAINT sortiestrategiquezfsan_fkey FOREIGN KEY (idblesse) REFERENCES public.blesse(idblesse) MATCH FULL;


--
-- PostgreSQL database dump complete
--

