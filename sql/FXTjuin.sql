
SELECT effacerdonneessimu();

\COPY salle_soin FROM 'C:\Users\abdi-\Documents\Cours\M2\Stage\Projet stage\Bases de donnees\monapp\donnees_CSV\salle_soin.csv' DELIMITER ',' CSV HEADER;
UPDATE salle_soin SET typesoin = 'HOS' WHERE idsalle <=80;
UPDATE salle_soin SET typesoin = 'BO' WHERE idsalle BETWEEN 81 AND 90;
UPDATE salle_soin SET typesoin = 'REA' WHERE idsalle > 90;
UPDATE salle_soin SET capacite = ARRAY[]::bigint[];

--BLESSES EVASAN 1 (35RI)
insert into blesse values (null, '0444879129', 'A', '31T FL 6790 9730', '2022-06-14 13:21:34'::timestamp with time zone, null, 'CIE', null);

insert into blesse values (null, '0491451644', 'A', '31T FL 6790 9730', '2022-06-14 13:21:34'::timestamp with time zone, null, 'CIE', null);

insert into blesse values (null, '0866980784', 'A', '31T FL 6790 9730', '2022-06-14 13:21:34'::timestamp with time zone, null, 'CIE', null);

SELECT ajoutdemandevasan('CIE'::VARCHAR, '31T FL 6790 9730'::VARCHAR);
UPDATE demandevasan set gdhdemande = '13:13:00'::time WHERE numdemande=1;
SELECT envoi_evasan(1);
update evasan set gdhdepartzfsan= '13:53:00'::time where numevasan=1;
SELECT ramassage_blesses_unite('CIE', 1);
update blesse set gdhevacue='2022-06-14 14:30:33'::timestamp with time zone where numdemande=1;
update evasan set gdharrivefront='2022-06-14 14:20:33'::timestamp with time zone where numevasan=1;
update evasan set gdhdepartfront='2022-06-14 14:30:33'::timestamp with time zone where numevasan=1;

SELECT livraison_blesses_unite(1);
update accueil_blesse_en_ZFSAN set gdharrivee='2022-06-14 15:00:33'::timestamp with time zone where idzfsante=1;

SELECT * FROM accueil_blesse_en_ZFSAN ;


--BLESSES EVASAN 2 (1RC)
insert into blesse values (null, '0932663788', 'A', '31T FL 6920 7080', '2022-06-14 15:52:34'::timestamp with time zone, null, 'CIE', null);

insert into blesse values (null, '0110285824', 'B', '31T FL 6920 7080', '2022-06-14 15:52:34'::timestamp with time zone, null, 'CIE', null);

insert into blesse values (null, '0308343999', 'B', '31T FL 6920 7080', '2022-06-14 15:52:34'::timestamp with time zone, null, 'CIE', null);
select * from blesse;

SELECT ajoutdemandevasan('CIE'::VARCHAR, '31T FL 6790 9730'::VARCHAR);
UPDATE demandevasan set gdhdemande = '15:52:34'::time WHERE numdemande=2;
select * from demandevasan;

SELECT envoi_evasan(2);
update evasan set gdhdepartzfsan= '16:06:33'::time where numevasan=2;
SELECT ramassage_blesses_unite('CIE', 2);
update blesse set gdhevacue='2022-06-14 16:26:33'::timestamp with time zone where numdemande=2;
update evasan set gdharrivefront='2022-06-14 16:16:33'::timestamp with time zone where numevasan=2;
update evasan set gdhdepartfront='2022-06-14 16:26:33'::timestamp with time zone where numevasan=2;
select * from evasan ;

SELECT livraison_blesses_unite(2);
update accueil_blesse_en_ZFSAN set gdharrivee='2022-06-14 16:40:33'::timestamp with time zone where idblesse BETWEEN 4 AND 6;

SELECT * FROM accueil_blesse_en_ZFSAN ;



--BLESSES EVASAN 3 (152RI)
insert into blesse values (null, '0007071159', 'A', '31T FL 6430 6830', '2022-06-14 16:30:34'::timestamp with time zone, null, 'CIE', null);

insert into blesse values (null, '1107341884', 'A', '31T FL 6430 6830', '2022-06-14 16:30:34'::timestamp with time zone, null, 'CIE', null);

--insert into blesse values (null, 'xxxx', 'B', '31T FL 6430 6830', '2022-06-14 16:30:34'::timestamp with time zone, null, 'CIE', null);

--insert into blesse values (null, 'xxxxxxxx', 'C', '31T FL 6430 6830', '2022-06-14 16:30:34'::timestamp with time zone, null, 'CIE', null);


SELECT ajoutdemandevasan('CIE'::VARCHAR, '31T FL 6790 9730'::VARCHAR);
UPDATE demandevasan set gdhdemande = '16:30:34'::time WHERE numdemande=3;
SELECT envoi_evasan(3);
update evasan set gdhdepartzfsan= '16:43:33'::time where numevasan=2;
SELECT ramassage_blesses_unite('CIE', 3);
update blesse set gdhevacue='2022-06-14 17:02:33'::timestamp with time zone where numdemande=1;
update evasan set gdharrivefront='2022-06-14 17:02:33'::timestamp with time zone where numevasan=1;
update evasan set gdhdepartfront='2022-06-14 17:20:33'::timestamp with time zone where numevasan=1;

SELECT livraison_blesses_unite(3);
update accueil_blesse_en_ZFSAN set gdharrivee='2022-06-14 18:10:33'::timestamp with time zone where idzfsante=1;

SELECT * FROM accueil_blesse_en_ZFSAN ;