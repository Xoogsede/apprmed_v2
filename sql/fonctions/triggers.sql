-- Trigger ajout de militaire dans la base de donnee
CREATE OR REPLACE FUNCTION militaire_ajout()
    RETURNS TRIGGER 
    AS 
    $militaire_ajout$
    BEGIN 
        -- Vérification que les champs obligatoires soient complétés
        IF NEW.pays IS NULL THEN
            RAISE EXCEPTION 'pays ne peut être vide';
        END IF;
        
        IF NEW.nomarmee IS NULL THEN
            RAISE EXCEPTION 'Armee ne peut être vide';
        END IF;

        IF NEW.nomunite IS NULL THEN
            RAISE EXCEPTION 'Unité ou régiment ne peut être vide';
        END IF;
        
        IF NEW.div_bri IS NULL THEN
            RAISE EXCEPTION 'division ou brigade ne peut être vide';
        END IF;

        IF NEW.unite_elementaire IS NULL THEN
            RAISE EXCEPTION 'Unité élémentaire ne peut être vide';
        END IF;

        IF NEW.matricule IS NULL THEN
            RAISE EXCEPTION 'Matricule ne peut être vide';
        ELSE
            NEW.matricule := (SELECT LPAD(CAST(NEW.matricule AS varchar), 10, '0'));
        END IF;

        IF NEW.nom IS NULL THEN 
            RAISE EXCEPTION 'Le nom ne peut être vide';
        END IF;        

        IF NEW.prenom IS NULL THEN
            RAISE EXCEPTION 'Prénom ne peut être vide';
        END IF;

        IF NEW.categoriehf IS NULL THEN 
            RAISE EXCEPTION 'La catégorie homme ou femme ne peut être vide'; 
        END IF;

        IF NEW.date_naissance IS NULL THEN
            RAISE EXCEPTION 'La date de naissance ne peut être vide';
        END IF;

        IF NEW.lieu_naissance IS NULL THEN
            RAISE EXCEPTION 'Le lieu de naissance ne peut être vide';
        END IF;

        IF NEW.grade IS NULL THEN
            RAISE EXCEPTION 'Le grade ne peut être vide';
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

        IF NEW.unite_elementaire NOT IN (SELECT unite_elementaire FROM ONLY unites_elementaires) THEN
            INSERT INTO unites_elementaires  
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
    $militaire_ajout$ LANGUAGE plpgsql;

CREATE TRIGGER militaire_ajout BEFORE INSERT OR UPDATE ON militaire
    FOR EACH ROW EXECUTE PROCEDURE militaire_ajout();


-- Trigger ajout de civil dans la base de donnee
CREATE OR REPLACE FUNCTION civil_ajout()
    RETURNS TRIGGER AS $civil_ajout$

    BEGIN    

        -- Vérification que les champs obligatoires soient complétés    
        IF NEW.nom IS NULL THEN 
            RAISE EXCEPTION 'Le nom ne peut être vide';
        END IF;        

        IF NEW.prenom IS NULL THEN
            RAISE EXCEPTION 'Prénom ne peut être vide';
        END IF;

        IF NEW.categoriehf IS NULL THEN 
            RAISE EXCEPTION 'La catégorie homme ou femme ne peut être vide'; 
        END IF;

        IF NEW.date_naissance IS NULL THEN
            RAISE EXCEPTION 'La date de naissance ne peut être vide';
        END IF;

        IF NEW.lieu_naissance IS NULL THEN
            RAISE EXCEPTION 'Le lieu de naissance ne peut être vide';
        END IF;

        IF NEW.pays IS NULL THEN
            RAISE EXCEPTION 'pays ne peut être vide';
        END IF;

        IF NEW.adresse IS NULL THEN
            NEW.adresse := 'Adresse non renseignée. ';
        END IF;

        -- Verification que le civil ne soit pas deja enregiste dans la base de donnee
        IF (EXISTS (SELECT *
        FROM civil 
        WHERE nom=NEW.nom AND prenom=New.prenom AND date_naissance=NEW.date_naissance AND lieu_naissance=NEW.lieu_naissance))
        THEN 
            RAISE EXCEPTION 'Civil déjà enregistré';
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
    $civil_ajout$ LANGUAGE plpgsql;


CREATE TRIGGER civil_ajout BEFORE INSERT OR UPDATE ON civil
    FOR EACH ROW EXECUTE PROCEDURE civil_ajout();

--Trigger ajout de blesse
CREATE OR REPLACE FUNCTION ajout_blesse()
    RETURNS TRIGGER AS $ajout_blesse$

    BEGIN    

        -- Vérification que les champs obligatoires soient complétés
    
        IF NEW.matricule IS NULL THEN
            RAISE EXCEPTION 'Le matricule ne doit pas être vide';
        END IF;

        IF NEW.categorieabc IS NULL THEN
            RAISE EXCEPTION 'La catégorie blessé ne pas être vide';
        END IF;

        IF NEW.coordonneesutmblesse IS NULL THEN
            RAISE EXCEPTION 'Les coordonnées UTM du blessé ne peuvent être vide';
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
    $ajout_blesse$ LANGUAGE plpgsql;


CREATE TRIGGER ajout_blesse BEFORE INSERT OR UPDATE ON blesse
    FOR EACH ROW EXECUTE PROCEDURE ajout_blesse();


--Trigger sauvegarde donnees blesse
CREATE OR REPLACE FUNCTION donnees_blesse()
    RETURNS TRIGGER AS $donnees_blesse$

    BEGIN
        IF (NEW.idblesse IN (SELECT idblesse FROM donnees_blesse)) THEN
            UPDATE donnees_blesse SET gdhblessure = NEW.gdhblessure, gdhevacue = NEW.gdhevacue WHERE idblesse= NEW.idblesse;
        ELSE 
            INSERT INTO donnees_blesse 
            VALUES (NEW.idblesse, NEW.gdhblessure, NEW.gdhevacue) 
            ON CONFLICT (idblesse) 
            DO UPDATE SET gdhblessure = NEW.gdhblessure, gdhevacue = NEW.gdhevacue;
        END IF;
        RETURN NEW;
    END;
    $donnees_blesse$
    LANGUAGE plpgsql;

CREATE TRIGGER donnees_blesse AFTER INSERT OR UPDATE OF idblesse, gdhblessure, gdhevacue ON blesse
    FOR EACH ROW EXECUTE PROCEDURE donnees_blesse();


CREATE OR REPLACE FUNCTION ajout_zone_fonctionnelle_sante()
    RETURNS TRIGGER AS $nouvelle_zfsante$
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
    $nouvelle_zfsante$
    LANGUAGE plpgsql;

CREATE TRIGGER ajout_zone_fonctionnelle_sante BEFORE INSERT OR UPDATE ON zfsante
    FOR EACH ROW EXECUTE PROCEDURE ajout_zone_fonctionnelle_sante();

--Trigger ajout d'une nouvelle demande EVASAN
CREATE OR REPLACE FUNCTION ajout_demandevasan()
    RETURNS TRIGGER AS $ajout_demandevasan$

    BEGIN    

        -- Vérification que les champs obligatoires soient complétés    
        IF NEW.unite_elementaire IS NULL THEN
            RAISE EXCEPTION 'Unite élémentaire ne peut être vide';
        END IF;

        IF NEW.coordonneutm IS NULL THEN
            RAISE EXCEPTION 'Les coordonnées UTM de ramassage ne peuvent être vides';
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
    $ajout_demandevasan$ LANGUAGE plpgsql;


CREATE TRIGGER ajout_demandevasan BEFORE INSERT OR UPDATE ON demandevasan
    FOR EACH ROW EXECUTE PROCEDURE ajout_demandevasan();


CREATE OR REPLACE FUNCTION affecter_numdemandevasan_au_blesse()
    RETURNS TRIGGER AS $affecter_numdemandevasan_au_blesse$

    BEGIN    

    UPDATE blesse SET numdemande = NEW.numdemande 
        FROM demandevasan WHERE demandevasan.unite_elementaire = blesse.unite_elementaire 
        AND blesse.numdemande IS NULL;
        
        RETURN NEW;
    END;
    $affecter_numdemandevasan_au_blesse$ LANGUAGE plpgsql;


CREATE TRIGGER affecter_numdemandevasan_au_blesse AFTER INSERT OR UPDATE OF numdemande ON demandevasan
    FOR EACH ROW EXECUTE PROCEDURE affecter_numdemandevasan_au_blesse();


CREATE OR REPLACE FUNCTION present_en_zfsan()
    RETURNS TRIGGER AS $accueil_en_zfsan$

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
    $accueil_en_zfsan$
    LANGUAGE plpgsql;

CREATE TRIGGER accueil_blesse_en_zfsan BEFORE INSERT OR UPDATE OF idzfsante, coordonneutm, libeletype ON accueil_blesse_en_ZFSAN
    FOR EACH ROW EXECUTE PROCEDURE present_en_zfsan();

CREATE TRIGGER attente_soin_en_zfsan BEFORE INSERT OR UPDATE OF idzfsante, coordonneutm, libeletype ON attente_soin
    FOR EACH ROW EXECUTE PROCEDURE present_en_zfsan();

CREATE TRIGGER salle_soin_en_zfsan BEFORE INSERT OR UPDATE OF idzfsante, coordonneutm, libeletype ON salle_soin
    FOR EACH ROW EXECUTE PROCEDURE present_en_zfsan();

CREATE TRIGGER magasinsante_en_zfsan BEFORE INSERT OR UPDATE OF idzfsante, coordonneutm, libeletype ON magasinsante
    FOR EACH ROW EXECUTE PROCEDURE present_en_zfsan();

CREATE OR REPLACE FUNCTION en_soin()
    RETURNS TRIGGER AS $en_soin$

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
    $en_soin$
    LANGUAGE plpgsql;

CREATE TRIGGER en_soin BEFORE INSERT OR UPDATE ON en_soin
    FOR EACH ROW EXECUTE PROCEDURE en_soin();


----------------------------------------------------------------------------------------------------
-- TRIGGER VECTEUR TRANSPORT
----------------------------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION vecteur_transport_ajout()
    RETURNS TRIGGER AS $vecteur_transport_ajout$

    BEGIN    

        -- Vérification que les champs obligatoires soient complétés
        IF NEW.idtypevt IS NULL THEN
            RAISE EXCEPTION 'Identifiant type de vecteur transport ne peut être vide';
        END IF;
        
        IF NEW.idcat IS NULL THEN
            RAISE EXCEPTION 'Identifiant categorie vecteur transport ne peut être vide';
        END IF;

        IF NEW.idcapacite IS NULL THEN
            RAISE EXCEPTION 'Identifiant de la capacité d''évacution ne peut être vide';
        END IF;
        
        IF NEW.idvt IS NULL THEN
            RAISE EXCEPTION 'L''identifiant du vecteur transport ne peut être vide';
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
    $vecteur_transport_ajout$ LANGUAGE plpgsql;

CREATE TRIGGER vecteur_transport_ajout BEFORE INSERT OR UPDATE ON vecteur_transport
    FOR EACH ROW EXECUTE PROCEDURE vecteur_transport_ajout();

CREATE OR REPLACE FUNCTION disponibilite_vt_initiale()
    RETURNS TRIGGER
    AS
    $$
    BEGIN
        IF NEW.idvt NOT IN (SELECT idvt FROM disponibilite_vt) THEN
                INSERT INTO disponibilite_vt
                VALUES (NEW.idvt, 'DISPO');
        END IF;
        RETURN NEW;
    END;
    $$
    LANGUAGE plpgsql;

CREATE TRIGGER disponibilite_vt_initiale AFTER INSERT OR UPDATE OF idvt ON vecteur_transport
    FOR EACH ROW EXECUTE PROCEDURE disponibilite_vt_initiale();
