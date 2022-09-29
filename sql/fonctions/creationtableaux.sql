CREATE TABLE type_vt (
  idtypevt character varying(9), -- blindé ou nonblindé
  PRIMARY KEY (idtypevt)
);


CREATE TABLE categorie_vt (
  idcat character varying(3), -- VL, PL, SPL, TC, HM, TR, AV, BT, VAB, GRI, 
  libelecategorie text, -- Categorie en clair
  modecirculation character varying(2), -- VR, VF, VA, VM
  PRIMARY KEY (idcat)
) INHERITS (type_vt);


CREATE TABLE capacite_transport (
  idcapacite integer,
  capa integer NOT NULL,
  capb integer NOT NULL,
  capc integer NOT NULL,
  PRIMARY KEY (idcapacite)
) INHERITS (categorie_vt);

CREATE TABLE vecteur_transport (
  idvt bigint, --immatriculation, numero train, numero avion...
  appellationvt character varying(100), --nom en clair du vecteur transport
  PRIMARY KEY (idvt)
) INHERITS (capacite_transport);


CREATE TABLE disponibilite_vt (
  idvt bigint,
  etat text,
  PRIMARY KEY (idvt)
);

ALTER TABLE vecteur_transport ALTER COLUMN TYPE VARCHAR(50);

-- Vecteur transport utiliser pour la mission d'EVASAN
CREATE TABLE IF NOT EXISTS public.vt_en_mission
(
    numevasan integer NOT NULL,
    idvt character varying(50) NOT NULL,
    CONSTRAINT vt_en_mission_pkey PRIMARY KEY (numevasan, idvt),
    CONSTRAINT fk_vt_en_mission_idvt FOREIGN KEY (idvt)
        REFERENCES public.vecteur_transport (idvt) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION,
    CONSTRAINT fk_vt_en_mission_numevasan FOREIGN KEY (numevasan)
        REFERENCES public.evasan (numevasan) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS public.vt_en_mission
    OWNER to postgres;




-- Table de demande d'évacuation sanitaire
-- Table: public.demandevasan

CREATE TABLE IF NOT EXISTS public.demandevasan
(
    numdemande bigint NOT NULL,
    unite_elementaire character varying(150) COLLATE pg_catalog."default" NOT NULL,
    coordonneutm character varying COLLATE pg_catalog."default" NOT NULL,
    nblessea integer,
    nblesseb integer,
    nblessec integer,
    gdhdemande time ,
    CONSTRAINT demandevasan_pkey PRIMARY KEY (numdemande),
    CONSTRAINT demandevasan_unite_elementaire FOREIGN KEY (unite_elementaire)
        REFERENCES public.unite_elementaire (unite_elementaire) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
        NOT VALID
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS public.demandevasan
    OWNER to postgres;