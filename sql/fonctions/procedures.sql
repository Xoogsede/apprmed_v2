CREATE TABLE DIV_BRI 
    (
        div_bri text,
        CONSTRAINT div_bri_pkey PRIMARY KEY (div_bri)
    ) INHERITS (armee);

CREATE TABLE unite_elementaire 
    (   
        unite_elementaire VARCHAR(150),
        CONSTRAINT unite_elementaire_pkey PRIMARY KEY (unite_elementaire)
    ) INHERITS (unite);

    ALTER TABLE unite ALTER COLUMN unite_elementaire TYPE VARCHAR(150);


CREATE TABLE IF NOT EXISTS public.militaire
    (
        grade text COLLATE pg_catalog."default" NOT NULL,
        catmilitaire text COLLATE pg_catalog."default"
    
    )
        INHERITS (public.unite_elementaire, public.individu)
    TABLESPACE pg_default;

    ALTER TABLE IF EXISTS public.militaire
        OWNER to postgres;



-- TABLE DE DEMANDE D'EVACUATION SANITAIRE
CREATE TABLE IF NOT EXISTS public.demandevasan
    (
        numdemande bigint NOT NULL,
        unite_elementaire character varying(150) COLLATE pg_catalog."default" NOT NULL,
        coordonneutm character varying COLLATE pg_catalog."default" NOT NULL,
        nombreblesse integer NOT NULL,
        gdhdemande time with time zone NOT NULL,
        CONSTRAINT demandevasan_pkey PRIMARY KEY (numdemande),
        CONSTRAINT demandevasan_unite_elementaire FOREIGN KEY (unite_elementaire)
            REFERENCES public.unite_elementaire (unite_elementaire) MATCH SIMPLE
            ON UPDATE NO ACTION
            ON DELETE NO ACTION
            NOT VALID
    )

    TABLESPACE pg_default;


-- DES DES EVASAN
CREATE TABLE IF NOT EXISTS public.evasan
    (
        numevasan SERIAL NOT NULL,
        numdemande bigint NOT NULL,
        gdhdepartzfsan date NOT NULL,
        coordonneutm text COLLATE pg_catalog."default" NOT NULL,
        coordonneutm1 text COLLATE pg_catalog."default" NOT NULL,
        capacite integer NOT NULL,
        gdharrivefront date,
        gdhdepartfront date,
        CONSTRAINT evasan_pkey PRIMARY KEY (numevasan),
        CONSTRAINT evasan_coordonneutm1_fkey FOREIGN KEY (coordonneutm1)
            REFERENCES public.destination (coordonneutm) MATCH SIMPLE
            ON UPDATE NO ACTION
            ON DELETE NO ACTION,
        CONSTRAINT evasan_coordonneutm_fkey FOREIGN KEY (coordonneutm)
            REFERENCES public.destination (coordonneutm) MATCH SIMPLE
            ON UPDATE NO ACTION
            ON DELETE NO ACTION,
        CONSTRAINT evasan_numdemande_fkey FOREIGN KEY (numdemande)
            REFERENCES public.demandevasan (numdemande) MATCH SIMPLE
            ON UPDATE NO ACTION
            ON DELETE NO ACTION
            NOT VALID
    )

    TABLESPACE pg_default;

    ALTER TABLE IF EXISTS public.evasan
        OWNER to postgres;



CREATE TABLE IF NOT EXISTS public.disponibilite_vt 
    (
        idvt character varying(50),
        etat text,
        CONSTRAINT dispo_pkey PRIMARY KEY (idvt),
        CONSTRAINT dispo_fkey FOREIGN KEY (idvt)
        REFERENCES public.vecteur_transport (idvt) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE CASCADE
    );

ALTER TABLE IF EXISTS public.demandevasan ALTER COLUMN nombreblesse TYPE INT;

ALTER TABLE IF EXISTS public.demandevasan RENAME COLUMN nombreblesse TO nblesseA ;
ALTER TABLE IF EXISTS public.demandevasan RENAME COLUMN gdhdemande TO nblesseB ;
ALTER TABLE IF EXISTS public.demandevasan ALTER COLUMN nblesseB TYPE INT;

ALTER TABLE demandevasan ADD COLUMN nblesseC INT ;    
ALTER TABLE demandevasan ADD COLUMN gdhdemande time ;






RETURN QUERY 
TABLE (Matricule bigint, 
    Grade_Nom_Prenom text, 
    Unite text, 
    Date_de_naissance date, 
    Lieu_de_naissance text)