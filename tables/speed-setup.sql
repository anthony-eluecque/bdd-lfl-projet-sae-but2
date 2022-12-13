-- Fichier utile pour lancer un \i en one shot, 
-- Vous retrouvez + d'explications dans les dossiers de chaque table.

set DATESTYLE to DMY;

CREATE TABLE Nationalites(
    id_nationalite SERIAL PRIMARY KEY,
    libelle_nationalite VARCHAR(50)
);

CREATE TABLE Coachs(
    id_coach SERIAL PRIMARY KEY,
    pseudo_coach VARCHAR(50) NOT NULL,
    nom_coach VARCHAR(50) NOT NULL,
    prenom_coach VARCHAR(50) NOT NULL,
    id_nationalite INTEGER NOT NULL REFERENCES Nationalites(id_nationalite)
);

CREATE TABLE Equipes(
    id_equipe SERIAL PRIMARY KEY,
    nom_equipe VARCHAR(50) NOT NULL,
    date_creation DATE NOT NULL,
    id_coach INTEGER NOT NULL REFERENCES Coachs(id_coach)
);

CREATE TABLE Matchs(
    id_match SERIAL PRIMARY KEY,
    id_equipe_1  INTEGER NOT NULL REFERENCES Equipes(id_equipe),
    id_equipe_2  INTEGER NOT NULL REFERENCES Equipes(id_equipe),
    date_match DATE NOT NULL,
    duree_match TIME NOT NULL,
    vainqueur INTEGER NOT NULL,
    perdant INTEGER NOT NULL,
    num_semaine INTEGER NOT NULL
);

CREATE TABLE Roles(
    id_role SERIAL PRIMARY KEY,
    nom_role VARCHAR(50)
);

CREATE TABLE Joueurs(
    id_joueur SERIAL PRIMARY KEY,
    pseudo VARCHAR(50) NOT NULL,
    nom VARCHAR(50) NOT NULL,
    prenom VARCHAR(50) NOT NULL,
    date_naissance DATE,
    id_nationalite INTEGER NOT NULL REFERENCES Nationalites(id_nationalite)
);

CREATE TABLE Champions(
    id_champion SERIAL PRIMARY KEY,
    nom_champion VARCHAR(50),
    id_role_1 INTEGER NOT NULL REFERENCES Roles(id_role),
    id_role_2 INTEGER REFERENCES Roles(id_role)
);

CREATE TABLE Jouer_dans(
    id_joueur INTEGER NOT NULL REFERENCES Joueurs(id_joueur),
    id_role INTEGER NOT NULL REFERENCES Roles(id_role),
    id_equipe INTEGER NOT NULL REFERENCES Equipes(id_equipe),
    debut_contrat DATE NOT NULL,
    fin_contrat DATE
);

CREATE TABLE Historique_Matchs(
    id_historique_match SERIAL PRIMARY KEY,
    id_match INTEGER NOT NULL REFERENCES Matchs(id_match),
    id_joueur INTEGER NOT NULL REFERENCES Joueurs(id_joueur),
    id_champion_choisi INTEGER NOT NULL REFERENCES Champions(id_champion),
    id_champion_banni INTEGER NOT NULL REFERENCES Champions(id_champion),
    kills_joueur INTEGER NOT NULL,
    mort_joueur INTEGER NOT NULL,
    assists_joueur INTEGER NOT NULL,
    total_creeps_tues INTEGER NOT NULL
);

-- Nécessaire pour utiliser les trigger
CREATE TABLE classement_LFL(
    id_equipe INTEGER PRIMARY KEY,
    nb_win INTEGER NOT NULL,
    nb_lose INTEGER NOT NULL
);

CREATE TABLE statistique_LFL(
    id_equipe INTEGER PRIMARY KEY,
    winrate FLOAT ,
    kda_equipe FLOAT,
    moyenne_duree_game TIME
);

CREATE TABLE PlayedChamp(
    id_joueur INTEGER PRIMARY KEY,
    id_champ1 INTEGER NOT NULL,
    id_champ2 INTEGER NOT NULL,
    id_champ3 INTEGER NOT NULL
);

CREATE TABLE classement_week_lfl(
    id_equipe INTEGER,
    nb_win INTEGER,
    nb_lose INTEGER,
    week INTEGER
);

CREATE OR REPLACE FUNCTION calcul_kda_joueur(v_id_joueur Joueurs.id_joueur%type)
RETURNS DECIMAL AS $$
DECLARE
    v_kills INTEGER;
    v_morts INTEGER;
    v_assists INTEGER;

BEGIN
    v_kills:=0;
    v_morts:=0;
    v_assists:=0;

    IF (v_id_joueur IN (SELECT id_joueur FROM joueurs)) THEN
        SELECT SUM(kills_joueur) INTO v_kills FROM Historique_Matchs WHERE id_joueur = v_id_joueur;
        SELECT SUM(mort_joueur) INTO v_morts FROM Historique_Matchs WHERE id_joueur = v_id_joueur;
        SELECT SUM(assists_joueur) INTO v_assists FROM Historique_Matchs WHERE id_joueur = v_id_joueur;

        IF (v_morts > 0) THEN 
            RETURN ROUND(((v_kills::DECIMAL+v_assists::DECIMAL) / v_morts::DECIMAL),3); -- Cas ou le joueur est mort.
        ELSE
            RETURN ROUND((v_kills::DECIMAL+v_assists::DECIMAL),3); -- Cas ou il n'est pas mort et une division par 0 est impossible.
        END IF;
    ELSE
        raise exception 'Valeur incorrect, id n existe pas dans la base de donnée des joueurs';
    END IF;
END;
$$ language plpgsql;


CREATE OR REPLACE FUNCTION calcul_kda_equipe(v_id_equipe Equipes.id_equipe%type)
RETURNS DECIMAL AS $$ 
DECLARE 

    total_kda DECIMAL;
    
    v_id_joueur Joueurs.id_joueur%type;
    v_curseur CURSOR FOR SELECT id_joueur from Jouer_Dans WHERE id_equipe = v_id_equipe;

BEGIN 
    total_kda:=0;
    OPEN v_curseur;
    LOOP 
        FETCH v_curseur INTO v_id_joueur;
        EXIT WHEN NOT FOUND;
        -- raise notice 'Kda du joueur : %',calcul_kda_joueur(v_id_joueur);
        total_kda = total_kda + calcul_kda_joueur(v_id_joueur);
    END LOOP;
    total_kda = total_kda/5;
    CLOSE v_curseur;
    RETURN total_kda;
END;
$$ language plpgsql;

CREATE OR REPLACE FUNCTION calcul_duree_moyenne_matchs_equipe(v_id_equipe Equipes.id_equipe%type)
RETURNS TIME AS $$
BEGIN
    RETURN AVG(duree_match) FROM Matchs WHERE id_equipe_1 = v_id_equipe OR id_equipe_2 = v_id_equipe;
END;
$$ language plpgsql;

CREATE OR REPLACE FUNCTION calcul_winrate_equipe(v_id_equipe Equipes.id_equipe%type)
RETURNS DECIMAL as $$ 
DECLARE

    total_wins INTEGER;
    total_matchs INTEGER;

BEGIN

    IF (v_id_equipe IN (SELECT id_equipe FROM Equipes)) THEN
        SELECT COUNT(vainqueur) INTO total_wins FROM Matchs WHERE vainqueur = v_id_equipe;
        SELECT COUNT(id_match) INTO total_matchs FROM Matchs WHERE id_equipe_1 = v_id_equipe OR id_equipe_2 = v_id_equipe;
        RETURN ROUND(((total_wins::DECIMAL) / total_matchs::DECIMAL),2)*100;
    ELSE
        raise exception 'L equipe passé en paramètre n existe pas';
    END IF;
END;
$$ language plpgsql;

CREATE OR REPLACE FUNCTION gestion_classement() RETURNS TRIGGER AS $$
DECLARE
    v_id_equipe_gagnante classement_LFL.id_equipe%type;
    v_id_equipe_perdante classement_LFL.id_equipe%type;

    nb_win_existantes classement_LFL.nb_win%type;
    nb_loses_existantes classement_LFL.nb_lose%type;

    nb_week_win INTEGER;
    nb_week_lose INTEGER;
BEGIN
    nb_win_existantes :=0;
    nb_loses_existantes:=0;
    nb_week_lose :=0;
    nb_week_win := 0;

    SELECT id_equipe INTO v_id_equipe_gagnante FROM classement_LFL WHERE id_equipe = new.vainqueur;
    SELECT id_equipe INTO v_id_equipe_perdante FROM classement_LFL WHERE id_equipe = new.perdant;

    IF (v_id_equipe_gagnante IS NULL) THEN 
        INSERT INTO classement_LFL values(new.vainqueur,1,0); -- Si il n'existe pas encore alors il a que  le match qu'il vient de jouer
    ELSE  -- On s'occupe de modifier l'existant sinon  
        -- On récupère les données existantes et on update le classement
        SELECT nb_win INTO nb_win_existantes FROM classement_LFL WHERE id_equipe = v_id_equipe_gagnante;
        nb_win_existantes = nb_win_existantes + 1;
        UPDATE classement_LFL SET nb_win = nb_win_existantes WHERE id_equipe = v_id_equipe_gagnante;
    END IF;

    IF (v_id_equipe_perdante IS NULL) THEN 
        INSERT INTO classement_LFL values(new.perdant,0,1); -- Si il n'existe pas encore alors il a que  le match qu'il vient de jouer
    ELSE  -- On s'occupe de modifier l'existant sinon  
        -- On récupère les données existantes et on update le classement
        SELECT nb_lose INTO nb_loses_existantes FROM classement_LFL WHERE id_equipe = v_id_equipe_perdante;
        nb_loses_existantes = nb_loses_existantes + 1;
        UPDATE classement_LFL SET nb_lose = nb_loses_existantes WHERE id_equipe = v_id_equipe_perdante;
    END IF;


    SELECT id_equipe INTO v_id_equipe_gagnante FROM classement_week_lfl WHERE id_equipe = new.vainqueur AND week = new.num_semaine;
    -- raise notice '% , %' , v_id_equipe_gagnante,v_id_equipe_perdante;
    IF (v_id_equipe_gagnante IS NULL) THEN
        INSERT INTO classement_week_lfl values (new.vainqueur,1,0,new.num_semaine);
    ELSE    
        SELECT nb_win INTO nb_week_win FROM classement_week_lfl WHERE id_equipe = v_id_equipe_gagnante AND week = new.num_semaine;
        nb_week_win = nb_week_win + 1;
        UPDATE classement_week_lfl SET nb_win = nb_week_win WHERE id_equipe = v_id_equipe_gagnante AND week = new.num_semaine;
    END IF;

    SELECT id_equipe INTO v_id_equipe_perdante FROM classement_week_lfl WHERE id_equipe = new.perdant AND week = new.num_semaine;
    
    IF (v_id_equipe_perdante IS NULL) THEN
        INSERT INTO classement_week_lfl values (new.perdant,0,1,new.num_semaine);
    ELSE 
        SELECT nb_lose INTO nb_week_lose FROM classement_week_lfl WHERE id_equipe = v_id_equipe_perdante AND week = new.num_semaine;
        nb_week_lose = nb_week_lose + 1;
        -- raise notice 'nb_lose : %',nb_week_lose;
        UPDATE classement_week_lfl SET nb_lose = nb_week_lose WHERE id_equipe = v_id_equipe_perdante AND week = new.num_semaine;
    END IF;

    RETURN NEW;
END;
$$ language plpgsql;

CREATE TRIGGER classement_equipe
AFTER INSERT ON Matchs -- Utilisation du mot insert
FOR EACH ROW 
EXECUTE PROCEDURE gestion_classement();

CREATE OR REPLACE FUNCTION verif_insert_matchs() RETURNS TRIGGER AS $$
BEGIN
    IF ((new.id_equipe_1 = new.vainqueur OR new.id_equipe_1 = new.perdant)
    AND  (new.id_equipe_2 = new.vainqueur OR new.id_equipe_2 = new.perdant))
    THEN
        RETURN NEW;
    ELSE
        RAISE NOTICE 'Votre valeur doit être cohérente , une équipe qui ne joue pas ne peut pas gagner ou perdre';
    END IF;
END;
$$ language plpgsql;

CREATE TRIGGER verification_matchs
BEFORE INSERT ON Matchs -- Utilisation du mot before
FOR EACH ROW 
EXECUTE PROCEDURE verif_insert_matchs();

CREATE OR REPLACE FUNCTION gestion_stats_equipes()
RETURNS TRIGGER AS $$
DECLARE
    v_winrate statistique_LFL.winrate%type;
    v_id_equipe Equipes.id_equipe%type;
    v_id_equipe_bdd Equipes.id_equipe%type;

BEGIN
    SELECT id_equipe INTO v_id_equipe_bdd FROM Jouer_dans 
                    WHERE id_joueur = new.id_joueur; 
    SELECT id_equipe INTO v_id_equipe FROM statistique_LFL 
                    WHERE id_equipe = v_id_equipe_bdd;
    IF (v_id_equipe IS NULL) THEN 
        INSERT INTO statistique_LFL values(
            v_id_equipe_bdd,
            calcul_winrate_equipe(v_id_equipe_bdd),
            calcul_kda_equipe(v_id_equipe_bdd),
            calcul_duree_moyenne_matchs_equipe(v_id_equipe_bdd));
    ELSE
        UPDATE statistique_LFL SET
            winrate = calcul_winrate_equipe(v_id_equipe),
            kda_equipe = calcul_kda_equipe(v_id_equipe),
            moyenne_duree_game = calcul_duree_moyenne_matchs_equipe(v_id_equipe)
        WHERE id_equipe = v_id_equipe;
    END IF;
    RETURN new;
END;
$$ language plpgsql;

CREATE TRIGGER trigger_gestion_stats_equipes
AFTER INSERT OR UPDATE ON Historique_Matchs
FOR EACH ROW 
EXECUTE PROCEDURE gestion_stats_equipes();


CREATE OR REPLACE FUNCTION MostPlayedChampByPlayer()
RETURNS TRIGGER AS $$
DECLARE

    vid_champ Champions.id_champion%type;

    nb_fois_joue INTEGER;
    nb_fois_champ_new_joue INTEGER;

    vid_champ_joue Champions.id_champion%type;
    v_temp Champions.id_champion%type;
    v_temp_2 Champions.id_champion%type;

BEGIN
    nb_fois_champ_new_joue:=0;
    nb_fois_joue:=0;
    IF (new.id_joueur IN (SELECT id_joueur FROM PlayedChamp)) THEN

        FOR nb_fois_champ_new_joue,vid_champ_joue IN SELECT COUNT(id_champion_choisi),id_champion_choisi FROM Historique_Matchs 
                                GROUP BY id_champion_choisi,id_joueur
                                HAVING id_joueur = new.id_joueur
                                ORDER BY COUNT(id_champion_choisi) DESC LIMIT 3
        LOOP 

            IF (vid_champ_joue NOT IN (SELECT id_champ1 FROM PlayedChamp WHERE id_joueur = new.id_joueur)) THEN
                IF (vid_champ_joue NOT IN (SELECT id_champ2 FROM PlayedChamp WHERE id_joueur = new.id_joueur)) THEN
                    IF (vid_champ_joue NOT IN (SELECT id_champ3 FROM PlayedChamp WHERE id_joueur = new.id_joueur)) THEN
                        -- RAISE NOTICE 'id_champion : % , count : %',vid_champ_joue,nb_fois_champ_new_joue ;
                        -- On récup le 3ème perso le + joué
                        SELECT id_champ3 INTO vid_champ FROM PlayedChamp WHERE id_joueur = new.id_joueur;
                        SELECT COUNT(*) INTO nb_fois_joue FROM Historique_Matchs WHERE id_joueur = new.id_joueur AND id_champion_choisi = vid_champ;

                        -- Si le nouveau champ est + joué par ce joueur que son 3ème champion habituel alors on update
                        -- raise notice 'Id3 : % , count : % , count_loop : %',vid_champ,nb_fois_joue,nb_fois_champ_new_joue;
                        IF (nb_fois_champ_new_joue > nb_fois_joue) THEN 
                            -- raise notice 'Cas id3';
                            UPDATE PlayedChamp SET id_champ3 = vid_champ_joue WHERE id_joueur = new.id_joueur;
                        -- Si le nouveau champ est + joué par ce joueur que son 2ème champion habituel alors on update
                        -- Pour ça, on a besoin de passé par une variable temporaire pour décallé de 1 les id.
                        END IF;

                        SELECT id_champ2 INTO vid_champ FROM PlayedChamp WHERE id_joueur = new.id_joueur;
                        SELECT COUNT(*) INTO nb_fois_joue FROM Historique_Matchs WHERE id_joueur = new.id_joueur AND id_champion_choisi = vid_champ;
                        -- raise notice 'Id2 : % , count : % , count_loop : %',vid_champ,nb_fois_joue,nb_fois_champ_new_joue;
                        IF (nb_fois_champ_new_joue > nb_fois_joue) THEN 
                            -- raise notice 'Cas id2';
                            SELECT id_champ2 INTO v_temp FROM PlayedChamp WHERE id_joueur = new.id_joueur;
                            
                            UPDATE PlayedChamp SET id_champ2 = vid_champ_joue WHERE id_joueur = new.id_joueur;
                            UPDATE PlayedChamp SET id_champ3 = v_temp WHERE id_joueur = new.id_joueur;
                        END IF;
                        -- Si le nouveau champ est + joué par ce joueur que son principale champion habituel alors on update
                        -- Pour ça, on a besoin de passé par 2 variables temporaires pour décallé de 1 tous les id.
                        SELECT id_champ1 INTO vid_champ FROM PlayedChamp WHERE id_joueur = new.id_joueur;
                        SELECT COUNT(*) INTO nb_fois_joue FROM Historique_Matchs WHERE id_joueur = new.id_joueur AND id_champion_choisi = vid_champ;
                        -- raise notice 'Id1 : % , count : % , count_loop : %',vid_champ,nb_fois_joue,nb_fois_champ_new_joue;
                        IF (nb_fois_champ_new_joue > nb_fois_joue) THEN 
                            -- raise notice 'Cas id1';
                            SELECT id_champ1 INTO v_temp_2 FROM PlayedChamp WHERE id_joueur = new.id_joueur;
                            UPDATE PlayedChamp SET id_champ1 = vid_champ_joue WHERE id_joueur = new.id_joueur;
                            SELECT id_champ2 INTO v_temp FROM PlayedChamp WHERE id_joueur = new.id_joueur;
                            UPDATE PlayedChamp SET id_champ2 = v_temp_2 WHERE id_joueur = new.id_joueur;
                            UPDATE PlayedChamp SET id_champ3 = v_temp WHERE id_joueur = new.id_joueur;
                        END IF;
                    END IF;
                END IF;
            END IF;
        END LOOP;
    ELSE
        INSERT INTO PlayedChamp VALUES(new.id_joueur,new.id_champion_choisi,0,0);
    END IF;
    return new;
END;
$$ language plpgsql;

-- SELECT id_champion_choisi,COUNT(id_champion_choisi) FROM Historique_Matchs 
--             GROUP BY id_champion_choisi,id_joueur 
--             HAVING id_joueur = 1 
--             ORDER BY COUNT(id_champion_choisi) DESC LIMIT 3;

CREATE TRIGGER trigger_gestion_champ_joueur
AFTER INSERT ON Historique_Matchs
FOR EACH ROW
EXECUTE PROCEDURE MostPlayedChampByPlayer();

INSERT INTO nationalites (libelle_nationalite) VALUES
('Afghane'),
('Albanaise'),
('Algérienne'),
('Américaine'),
('Andorrane'),
('Angolaise'),
('Antiguaise et barbudienne'),
('Argentine'),
('Arménienne'),
('Australienne'),
('Autrichienne'),
('Azerbaïdjanaise'),
('Bahamienne'),
('Bahreïnienne'),
('Bangladaise'),
('Barbadienne'),
('Bielorusse'),
('Belge'),
('Belizienne'),
('Beninoise'),
('Bhoutanaise'),
('Bolivienne'),
('Bosnienne'),
('Brésilienne'),
('Britannique'),
('Brunéienne'),
('Bulgare'),
('Burkinabè'),
('Birmane'),
('Burundaise'),
('Cambodgienne'),
('Camerounaise'),
('Canadienne'),
('Cap-verdienne'),
('Centrafricaine'),
('Tchadienne'),
('Chilienne'),
('Chinoise'),
('Vaticane'),
('Colombienne'),
('Comorienne'),
('Congolaise'),
('Costaricaine'),
('Croate'),
('Cubaine'),
('Chypriote'),
('Tcheque'),
('Danoise'),
('Djiboutienne'),
('Dominicaine'),
('Dominiquaise'),
('Néerlandaise'),
('Est-timoraise'),
('Equatorienne'),
('Egyptienne'),
('Emirienne'),
('Equato-guinéenne'),
('Erythréenne'),
('Estonienne'),
('Ethiopienne'),
('Fidjienne'),
('Philippine'),
('Finlandaise'),
('Française'),
('Gabonaise'),
('Gambienne'),
('Géorgienne'),
('Allemande'),
('Ghanéenne'),
('Hellénique'),
('Grenadienne'),
('Guatémaltèque'),
('Guinéenne'),
('Bissau-Guinéenne'),
('Guyanienne'),
('Haïtienne'),
('Hondurienne'),
('Hongroise'),
('Kiribatienne'),
('Islandaise'),
('Indienne'),
('Indonésienne'),
('Iranienne'),
('Irakienne'),
('Irlandaise'),
('Israélienne'),
('Italienne'),
('Ivoirienne'),
('Jamaïcaine'),
('Japonaise'),
('Jordanienne'),
('Kazakhstanaise'),
('Kenyane'),
('Kossovienne'),
('Koweitienne'),
('Kirghize'),
('Kittitienne-et-névicienne'),
('Laotienne'),
('Lettone'),
('Libanaise'),
('Libérienne'),
('Libyenne'),
('Liechtensteinoise'),
('Lituanienne'),
('Luxembourgeoise'),
('Macédonienne'),
('Malgache'),
('Malawienne'),
('Malaisienne'),
('Maldivienne'),
('Malienne'),
('Maltaise'),
('Marshallaise'),
('Mauritanienne'),
('Mauricienne'),
('Mexicaine'),
('Micronésienne'),
('Moldave'),
('Monegasque'),
('Mongole'),
('Marocaine'),
('Montenegrine'),
('Lésothane'),
('Botswanaise'),
('Mozambicaine'),
('Namibienne'),
('Nauruane'),
('Népalaise'),
('Néo-zélandaise'),
('Vanuatuane'),
('Nicaraguayenne'),
('Nigériane'),
('Nigérienne'),
('Nord-coréenne'),
('Norvégienne'),
('Omanaise'),
('Pakistanaise'),
('Palau'),
('Palestinienne'),
('Panaméenne'),
('Papouane-néoguinéenne'),
('Paraguayenne'),
('Péruvienne'),
('Polonaise'),
('Portugaise'),
('Portoricaine'),
('Qatarienne'),
('Roumaine'),
('Russe'),
('Rwandaise'),
('Saint-lucienne'),
('Salvadorienne'),
('Saint-marinaise'),
('Samoane'),
('Santoméenne'),
('Saoudienne'),
('Sénégalaise'),
('Serbe'),
('Seychelloise'),
('Sierra-léonaise'),
('Singapourienne'),
('Slovaque'),
('Slovène'),
('Salomonaise'),
('Somalienne'),
('Sud-africaine'),
('Sud-coréenne'),
('Espagnole'),
('Sri-lankaise'),
('Soudanaise'),
('Surinamaise'),
('Swazie'),
('Suédoise'),
('Suisse'),
('Syrienne'),
('Taiwanaise'),
('Tadjike'),
('Tanzanienne'),
('Thaïlandaise'),
('Togolaise'),
('Tonguienne'),
('Trinidadienne'),
('Tunisienne'),
('Turque'),
('Turkmène'),
('Tuvaluane'),
('Ougandaise'),
('Ukrainienne'),
('Uruguayenne'),
('Ouzbèke'),
('Venezuelienne'),
('Vietnamienne'),
('Vincentais'),
('Yéménite'),
('Zambienne'),
('Zimbabwéenne');



INSERT INTO Coachs(pseudo_coach, nom_coach, prenom_coach,  id_nationalite) VALUES
('Zeph', 'VIGUIE', 'Quentin', 64),
('GoToOne', 'PICARD', 'Adrien',  64),
('Striker', 'KELLA', 'Yanis', 64),
('Realistik', 'RUSE', 'Andrei', 148),
('Delord', 'SZABLA', 'Pawel', 144),
('Jesiz', 'LE', 'Jesse', 48),
('Jon', 'ELLIS', 'Jonathan', 25),
('Malau', 'RESTOUBLE', 'Malaury', 64),
('Hellombre', 'L', 'Adrien', 64),
('Aries', 'BIGANZOLI', 'Grégoire', 64);


INSERT INTO  Equipes(nom_equipe, date_creation, id_coach) VALUES
('LDLC OL', '14-11-2014', 1),
('BDS ACADEMY','01-05-2019', 2),
('KARMINE CORP','30-03-2020', 3),
('VITALITY.BEE','05-08-2013', 4),
('MISFITS PREMIER','18-05-2016', 5),
('TEAM GO','13-03-2011', 6),
('SOLARY','20-10-2017', 7),
('GAMEWARD','06-08-2018', 8),
('MIRAGE ELYANDRA','29-11-2021', 9),
('TEAM OPLON','23-02-2018', 10);



INSERT INTO Matchs(id_equipe_1,id_equipe_2,date_match,duree_match,vainqueur,perdant,num_semaine) VALUES
-- ■■■■■■■■■■■■■■■■■■■■ WEEK 1 ■■■■■■■■■■■■■■■■■■■■ --

-- ■■■■■■■■■■■■■■■■■■■ DAY 1 ■■■■■■■■■■■■■■■■■■■ --
(2, 1, '01-06-2022', '00:32:15', 1 , 2, 1),
(6, 7, '01-06-2022', '00:27:27', 6, 7, 1),
(8, 5, '01-06-2022', '00:36:07', 8, 5, 1),
(3, 10,'01-06-2022', '00:24:40', 3, 10, 1),
(4, 9, '01-06-2022', '00:27:04', 4, 9, 1),

-- ■■■■■■■■■■■■■■■■■■■ DAY 2 ■■■■■■■■■■■■■■■■■■■ --
(6, 5, '02-06-2022', '00:26:37', 6, 5, 1),
(9, 2, '02-06-2022', '00:30:21', 9, 2, 1),
(8, 3, '02-06-2022', '00:31:45', 3, 8, 1),
(7, 4,'02-06-2022', '00:26:24',4, 7, 1),
(10, 1,'02-06-2022', '00:30:55', 1, 10, 1),

-- ■■■■■■■■■■■■■■■■■■■■ WEEK 2 ■■■■■■■■■■■■■■■■■■■■ --

-- ■■■■■■■■■■■■■■■■■■■ DAY 3 ■■■■■■■■■■■■■■■■■■■ --
(8, 10, '08-06-2022', '00:29:07', 8, 10, 2),
(1, 9, '08-06-2022', '00:31:23', 1, 9, 2),
(3, 6, '08-06-2022', '00:29:57', 3, 6, 2),
(4, 5, '08-06-2022', '00:28:51', 4, 5, 2),
(2, 7, '08-06-2022', '00:31:16', 2, 7, 2),

-- ■■■■■■■■■■■■■■■■■■■ DAY 4 ■■■■■■■■■■■■■■■■■■■ --
(10, 4, '09-06-2022', '00:36:53', 4, 10, 2),
(5, 9, '09-06-2022', '00:29:00', 5, 9, 2),
(1, 7, '09-06-2022', '00:26:10', 1, 7, 2),
(2, 3, '09-06-2022', '00:40:10', 3, 2, 2),
(6, 8, '09-06-2022', '00:48:11', 6, 8, 2),

-- ■■■■■■■■■■■■■■■■■■■■ WEEK 3 ■■■■■■■■■■■■■■■■■■■■ --

-- ■■■■■■■■■■■■■■■■■■■ DAY 5 ■■■■■■■■■■■■■■■■■■■ --
(1, 6, '15-06-2022', '00:36:56', 1, 6, 3),
(7, 5, '15-06-2022', '00:37:04', 7, 5, 3),
(8, 4, '15-06-2022', '00:32:53', 8, 4, 3),
(9, 3, '15-06-2022', '00:47:50', 3, 9, 3),
(10, 2, '15-06-2022', '00:34:49', 2, 10, 3),

-- ■■■■■■■■■■■■■■■■■■■ DAY 6 ■■■■■■■■■■■■■■■■■■■ --
(5, 1, '16-06-2022', '00:28:40', 1, 5, 3),
(6, 4, '16-06-2022', '00:27:31', 4, 6, 3),
(7, 3, '16-06-2022', '00:27:32', 3, 7, 3),
(8, 2, '16-06-2022', '00:37:56', 8, 2, 3),
(10, 9, '16-06-2022', '00:40:24', 10, 9, 3),

-- ■■■■■■■■■■■■■■■■■■■■ WEEK 4 ■■■■■■■■■■■■■■■■■■■■ --

-- ■■■■■■■■■■■■■■■■■■■ DAY 7 ■■■■■■■■■■■■■■■■■■■ --
(7, 10, '21-06-2022', '00:37:47', 7, 10, 4),
(9, 8, '21-06-2022', '00:37:18', 8, 9, 4),
(2, 6, '21-06-2022', '00:30:34', 2, 6, 4),
(1, 4, '21-06-2022', '00:30:35', 1, 4, 4),
(5, 3, '21-06-2022', '00:32:49', 5, 3, 4),

-- ■■■■■■■■■■■■■■■■■■■ DAY 8 ■■■■■■■■■■■■■■■■■■■ --
(5, 2, '22-06-2022', '00:43:31', 5, 2, 4),
(6, 10, '22-06-2022', '00:39:45', 6, 10, 4),
(8, 1, '22-06-2022', '00:31:01', 1, 8, 4),
(4, 3, '22-06-2022', '00:37:54', 3, 4, 4),
(9, 6, '22-06-2022', '00:37:04', 6, 9, 4),

-- ■■■■■■■■■■■■■■■■■■■ DAY 9 ■■■■■■■■■■■■■■■■■■■ --
(1, 2, '23-06-2022', '00:33:57', 1, 2, 4),
(7, 6, '23-06-2022', '00:29:42', 7, 6, 4),
(5, 8, '23-06-2022', '00:28:36', 8, 5, 4),
(10, 3, '23-06-2022', '00:35:39', 10, 3, 4),
(9, 4, '23-06-2022', '00:24:05', 4, 9, 4),

-- ■■■■■■■■■■■■■■■■■■■■ WEEK 5 ■■■■■■■■■■■■■■■■■■■■ --

-- ■■■■■■■■■■■■■■■■■■■ DAY 10 ■■■■■■■■■■■■■■■■■■■ --
(5, 6, '29-06-2022', '00:34:50', 5, 6, 5),
(6, 10, '29-06-2022', '00:29:05', 6, 10, 5),
(3, 8, '29-06-2022', '00:32:36', 8, 3, 5),
(7, 4, '29-06-2022', '00:26:12', 4, 7, 5),
(1, 10, '29-06-2022', '00:29:36', 1, 10, 5),

-- ■■■■■■■■■■■■■■■■■■■ DAY 11 ■■■■■■■■■■■■■■■■■■■ --
(10, 8, '30-07-2022', '00:42:37', 10, 8, 5),
(9, 1, '30-07-2022', '00:28:51', 1, 9, 5),
(6, 3, '30-07-2022', '00:37:36', 3, 6, 5),
(5, 4, '30-07-2022', '00:35:12', 5, 4, 5),
(2, 7, '30-07-2022', '00:36:21', 2, 7, 5),

-- ■■■■■■■■■■■■■■■■■■■■ WEEK 6 ■■■■■■■■■■■■■■■■■■■■ --

-- ■■■■■■■■■■■■■■■■■■■ DAY 12 ■■■■■■■■■■■■■■■■■■■ --
(4, 10, '06-07-2022', '00:32:16', 4, 10, 6),
(9, 5, '06-07-2022', '00:33:28', 5, 9, 6),
(7, 1, '06-07-2022', '00:23:35', 1, 7, 6),
(3, 2, '06-07-2022', '00:42:16', 2, 3, 6),
(6, 8, '06-07-2022', '00:32:32', 8, 6, 6),

-- ■■■■■■■■■■■■■■■■■■■ DAY 13 ■■■■■■■■■■■■■■■■■■■ --
(6, 1, '07-07-2022', '00:36:01', 6, 1, 6),
(5, 7, '07-07-2022', '00:28:22', 5, 7, 6),
(4, 8, '07-07-2022', '00:36:32', 4, 8, 6),
(9, 3, '07-07-2022', '00:32:09', 3, 9, 6),
(2, 10, '07-07-2022', '00:35:22', 2, 10, 6),

-- ■■■■■■■■■■■■■■■■■■■■ WEEK 7 ■■■■■■■■■■■■■■■■■■■■ --

-- ■■■■■■■■■■■■■■■■■■■ DAY 14 ■■■■■■■■■■■■■■■■■■■ --
(1, 5, '13-07-2022', '00:32:17', 1, 5, 7),
(4, 6, '13-07-2022', '00:32:05', 6, 4, 7),
(3, 7, '13-07-2022', '00:32:38', 7, 3, 7),
(2, 8, '13-07-2022', '00:30:13', 2, 8, 7),
(9, 10, '13-07-2022', '00:36:09', 9, 10, 7),

-- ■■■■■■■■■■■■■■■■■■■ DAY 15 ■■■■■■■■■■■■■■■■■■■ --
(10, 8, '14-07-2022', '00:42:37', 10, 8, 7),
(9, 1, '14-07-2022', '00:28:51', 1, 9, 7),
(6, 3, '14-07-2022', '00:37:36', 3, 6, 7),
(5, 4, '14-07-2022', '00:35:12', 5, 4, 7),
(2, 7, '14-07-2022', '00:36:21', 2, 7, 7),

-- ■■■■■■■■■■■■■■■■■■■■ WEEK 8 ■■■■■■■■■■■■■■■■■■■■ --

-- ■■■■■■■■■■■■■■■■■■■ DAY 16 ■■■■■■■■■■■■■■■■■■■ --
(1, 8, '21-07-2022', '00:28:56', 1, 8, 8),
(9, 7, '21-07-2022', '00:39:44', 7, 9, 8),
(6, 10, '21-07-2022', '00:31:10', 6, 10, 8),
(2, 5, '21-07-2022', '00:41:53', 2, 5, 8),
(4, 3, '21-07-2022', '00:36:19', 4, 3, 8),

-- ■■■■■■■■■■■■■■■■■■■■ WEEK 9 ■■■■■■■■■■■■■■■■■■■■ --

-- ■■■■■■■■■■■■■■■■■■■ DAY 17 ■■■■■■■■■■■■■■■■■■■ --
(4, 1, '27-07-2022', '00:31:23', 1, 4, 9),
(3, 5, '27-07-2022', '00:35:35', 3, 5, 9),
(2, 6, '27-07-2022', '00:30:28', 2, 6, 9),
(7, 10, '27-07-2022', '00:35:07', 7, 10, 9),
(8, 9, '27-07-2022', '00:49:26', 9, 8, 9),

-- ■■■■■■■■■■■■■■■■■■■ DAY 18 ■■■■■■■■■■■■■■■■■■■ --
(3, 1, '28-07-2022', '00:27:17', 1, 3, 9),
(4, 2, '28-07-2022', '00:40:13', 2, 4, 9),
(5, 10, '28-07-2022', '00:32:35', 5, 10, 9),
(6, 9, '28-07-2022', '00:27:52', 6, 9, 9),
(8, 7, '28-07-2022', '00:32:32', 8, 7, 9);


INSERT INTO ROLES (nom_role) values 
('JUNGLER'), 
('ADC'), 
('SUPPORT'), 
('MIDLANER'), 
('TOPLANER'); 

INSERT INTO Joueurs(pseudo, nom, prenom , date_naissance , id_nationalite) VALUES 
('Ragner', 'ASLAN', 'Onurcan', '19-12-2000', 184),
('Yike', 'SUNDELIN', 'Martin', '11-11-2000' ,173),
('Eika', 'VALDENAIRE', 'Jérémy', '19-07-1996' ,64),
('Exakick', 'FOUCOU', 'Thomas', '28-09-2003' ,64),
('Doss', 'SCHWARTZ', 'Mads', '19-03-1999' ,48),
('Adam', 'MAANANE', 'Adam', '30-12-2001',64),
('Sheo', 'BORILE', 'Théo', '05-07-2001' ,64),
('Reeker', 'CHEN', 'Steven', '15-05-2001' ,68),
('Crownie', 'MARUSIC', 'Jus','17-04-1998' ,163),
('Erdote', 'NOWAK', 'Robert', '19-07-1999' ,144),
('Cabochard', 'SIMON-MESLET', 'Lucas','15-04-1997' , 64),
('113', 'BALCI', 'Dokugan','12-08-2004' , 184),
('Saken', 'FAYARD', 'Lucas','05-11-1998' , 64),
('Rekkles', 'LARSSON', 'Carl Martin Erik','20-09-1996' , 173),
('Hantera', 'BOURGEOIS', 'Jules','21-02-1999' , 64), 
('Szygenda', 'JENSEN', 'Mathias', '14-04-2001', 48),
('Skeanz', 'MARQUET', 'Duncan', '25-09-2000', 64),
('Diplex', 'PONOMAREV', 'Dimitri', '15-07-2003', 68),
('Jeskla', 'KLARIN STROMBERG', 'Jesper', '08-07-2000', 173),
('Jactroll', 'SKURZYNSKI', 'Jakub', '05-08-1998', 144),
('Kackos', 'KUBZIAKOWSKI', 'Krzysztof', NULL, 144),
('Shlatan', 'AHMAD', 'Lucjan', '23-07-2001', 144),
('Czajek', 'CZAJKA', 'Mateusz', '24-09-2003', 144),
('Woolite', 'PRUSKI', 'Pawet', '07-05-1996', 144),
('Vander', 'BOGDAN', 'Oskar', '18-04-1994', 144),
('Nuq', 'ERDOGDU', 'Erkmen', '12-05-2003', 184),
('Karim kt', 'AUBINEAU', 'Karim', '19-03-1997', 64),
('Ronaldo', 'BETEA', 'Ronaldo', '23-12-1998', 148),
('Smiley', 'GRANQUIST', 'Ludvig Erik Hugo', '30-06-1998', 173),
('Veignorem', 'LUSSIEZ', 'Dai-vinh', '31-01-2000', 64),
('Kio', 'KRALIK', 'Simon', '16-07-2004',162),
('Djoko', 'GUILLARD', 'Charly','01-03-1997',64),
('Scarlet', 'WIEDERHOFER', 'Marcel','18-11-1998', 11),
('Asza', 'JACOBS', 'Patrick',NULL, 129),
('Steeelback', 'MEDJALDI', 'Pierre','16-08-1996', 64),
('Melonik', 'SLECZKA', 'Dawid', '26-04-2002', 144),
('Akabane', 'LE', 'Philippe', '15-10-2000', 64),
('Czekolad', 'SZCZEPANIK', 'Pawel', '15-02-2003', 144),
('Innaxe', 'ALIEV', 'Nihat', '23-03-1999', 27),
('Kamilius', 'KOSTAL', 'Kamil', '06-07-2000', 162),
('Badlulu', 'PIOCHAUD', 'Lucas','13-09-2002',64),
('Memento','ELMARGHICHI','Jonas','26-04-2002',174),
('RangJun','SANG-JUN','KIM','03-06-2003',167),
('CodySun','LIYU','Sun','25-04-1997',33),
('Raxxo','BAZYDLO','Oskar','12-10-1996',144),
('Darlik', 'GARCON', 'Aymeric', '28-09-1997', 64),
('Shernfire', 'CHERNG TAI', 'Shern', '04-05-1998', 109),
('Peng','SHEN','Pengcheng','18-03-2004', 38),
('Bung','GRAMM','Jacok','31-10-1999', 11),
('Twiitz','RICHIE GARCIA SPATSIG','Elton',NULL,173);


INSERT INTO CHAMPIONS(nom_champion,id_role_1,id_role_2) VALUES
('Aatrox',5,NULL),
('Ahri',4,NULL),
('Akali',5,4),
('Akshan',4,NULL),
('Alistar',3,NULL),
('Amumu',1,3),
('Anivia',4,NULL),
('Annie',4,NULL),
('Aphelios',4,2),
('Ashe',2,3),
('Aurelion Sol',4,NULL),
('Azir',4,NULL),
('Bard',3,NULL),
('Bel Veth',1,NULL),
('Blitzcrank',1,3),
('Brand',3,NULL),
('Braum',3,NULL),
('Caitlyn',2,NULL),
('Camille',5,NULL),
('Cassiopeia',4,NULL),
('Cho Gath',5,NULL),
('Corki',4,NULL),
('Darius',5,NULL),
('Diana',1,NULL),
('Dr.Mundo',5,NULL),
('Draven',2,NULL),
('Ekko',1,4),
('Elise',1,NULL),
('Evelynn',1,NULL),
('Ezreal',2,NULL),
('Fiddlesticks',1,NULL),
('Fiora',5,NULL),
('Fizz',4,NULL),
('Galio',4,NULL),
('Gangplank',5,NULL),
('Garen',5,NULL),
('Gnar',5,NULL),
('Gragas',5,NULL),
('Graves',1,NULL),
('Gwen',5,NULL),
('Hecarim',1,NULL),
('Heimerdinger',4,3),
('Illaoi',5,NULL),
('Irelia',5,4),
('Ivern',1,NULL),
('Janna',3,NULL),
('Jarvan IV',1,NULL),
('Jax',5,NULL),
('Jayce',5,NULL),
('Jhin',2,NULL),
('Jinx',2,NULL),
('K Sante',5,NULL),
('Kai Sa',2,NULL),
('Kalista',2,NULL),
('Karma',3,NULL),
('Karthus',1,NULL),
('Kassadin',4,NULL),
('Katarina',4,NULL),
('Kayle',5,NULL),
('Kayn',1,NULL),
('Kennen',5,NULL),
('Kha Zix',1,NULL),
('Kindred',1,NULL),
('Kled',5,NULL),
('Kog Maw',2,NULL),
('LeBlanc',4,NULL),
('Lee Sin',1,NULL),
('Leona',3,NULL),
('Lillia',1,NULL),
('Lissandra',4,NULL),
('Lucian',2,NULL),
('Lulu',3,NULL),
('Lux',4,3),
('Malphite',5,NULL),
('Malzahar',4,NULL),
('Maokai',5,1),
('Master YI',1,NULL),
('Miss Fortune',2,NULL),
('Mordekaiser',5,NULL),
('Morgana',3,NULL),
('Nami',3,NULL),
('Nasus',5,NULL),
('Nautilus',3,NULL),
('Neeko',4,NULL),
('Nidalee',1,NULL),
('Nilah',2,NULL),
('Nocturne',1,NULL),
('Nunu & Willump',1,NULL),
('Olaf',5,NULL),
('Orianna',4,NULL),
('Ornn',5,NULL),
('Pantheon',1,3),
('Poppy',1,NULL),
('Pyke',3,NULL),
('Qiyana',4,NULL),
('Quinn',5,NULL),
('Rakan',3,NULL),
('Rammus',1,NULL),
('Rek Sai',1,NULL),
('Rell',3,NULL),
('Renata Glasc',3,NULL),
('Renekton',5,NULL),
('Rengar',1,NULL),
('Riven',5,NULL),
('Rumble',5,NULL),
('Ryze',4,NULL),
('Samira',2,NULL),
('Sejuani',5,1),
('Senna',3,NULL),
('Seraphine',3,NULL),
('Sett',5,NULL),
('Shaco',1,NULL),
('Shen',5,NULL),
('Shyvana',1,NULL),
('Singed',5,NULL),
('Sion',5,NULL),
('Sivir',2,NULL),
('Skarner',1,NULL),
('Sona',3,NULL),
('Soraka',3,NULL),
('Swain',4,3),
('Sylas',4,NULL),
('Syndra',4,NULL),
('Tahm Kench',5,NULL),
('Taliyah',1,4),
('Talon',1,4),
('Taric',3,NULL),
('Teemo',5,NULL),
('Tresh',3,NULL),
('Tristana',2,NULL),
('Trundle',1,NULL),
('Tryndamere',5,NULL),
('Twisted Fate',4,NULL),
('Twitch',2,NULL),
('Udyr',1,NULL),
('Urgot',5,NULL),
('Varus',4,2),
('Vayne',5,2),
('Veigar',4,NULL),
('Vel Koz',3,NULL),
('Vex',4,NULL),
('Vi',1,NULL),
('Viego',1,NULL),
('Viktor',4,NULL),
('Vladimir',4,NULL),
('Volibear',5,1),
('Warwik',1,NULL),
('Wukong',1,NULL),
('Xayah',2,NULL),
('Xerath',4,3),
('Xin Zhao',1,NULL),
('Yasuo',5,4),
('Yone',5,4),
('Yorick',5,NULL),
('Yuumi',3,NULL),
('Zac',1,NULL),
('Zed',1,4),
('Zeri',2,NULL),
('Ziggs',4,NULL),
('Zilean',3,NULL),
('Zoe',4,NULL),
('Zyra',3,NULL);


INSERT INTO Jouer_Dans(id_joueur,id_role,id_equipe,debut_contrat,fin_contrat) VALUES
(1,5,1,'01-12-2021','01-11-2022'),
(2,1,1,'01-12-2021','01-11-2022'),
(3,4,1,'01-01-2021','01-11-2022'),
(4,2,1,'01-07-2020','01-11-2022'),
(5,3,1,'01-12-2021','01-11-2022'),
(6,5,2,'01-05-2022',NULL),
(7,1,2,'01-12-2021',NULL),
(8,4,2,'01-05-2022',NULL),
(9,2,2,'01-12-2021',NULL),
(10,3,2,'01-07-2022',NULL),
(11,5,3,'01-05-2021',NULL),
(12,1,3,'01-11-2021','01-11-2022'),
(13,4,3,'01-12-2020',NULL),
(14,2,3,'01-11-2021',NULL),
(15,3,3,'01-11-2021',NULL),
(16,5,4,'01-07-2021','01-12-2021'),
(17,1,4,'01-05-2021','01-11-2022'),
(18,4,4,'01-12-2020','01-11-2022'),
(19,2,4,'01-12-2021','01-11-2022'),
(20,3,4,'01-12-2021',NULL),
(21,5,5,'01-06-2022','01-11-2022'),
(22,1,5,'01-12-2020','01-11-2022'),
(23,4,5,'01-12-2021','01-11-2022'),
(24,2,5,'01-12-2020','01-11-2022'),
(25,3,5,'01-12-2020','01-11-2022'),
(26,5,6,'01-05-2022',NULL),
(27,1,6,'01-04-2022',NULL),
(28,4,6,'01-04-2022',NULL),
(29,2,6,'01-04-2022',NULL),
(30,3,6,'01-05-2022',NULL),
(31,5,7,'01-11-2021','01-11-2022'),
(32,1,7,'01-12-2022','01-11-2022'),
(33,4,7,'01-12-2020','01-11-2022'),
(34,2,7,'01-12-2020','01-11-2022'),
(35,3,7,'01-12-2022',NULL),
(36,5,8,'01-01-2022','01-12-2022'),
(37,1,8,'01-01-2022',NULL),
(38,4,8,'01-01-2022',NULL),
(39,2,8,'01-01-2022',NULL),
(40,3,8,'01-01-2022',NULL),
(41,5,9,'01-12-2021',NULL),
(42,1,9,'01-12-2021','01-11-2022'),
(43,4,9,'01-12-2021','01-07-2022'),
(44,2,9,'01-12-2021','01-12-2022'),
(45,3,9,'01-12-2021',NULL),
(46,5,10,'01-01-2021','01-11-2022'),
(47,1,10,'01-05-2022','01-12-2022'),
(48,4,10,'01-12-2021',NULL),
(49,2,10,'01-07-2022','01-11-2022'),
(50,3,10,'01-05-2022',NULL);

INSERT INTO Historique_Matchs(
    id_match, 
    id_joueur, 
    id_champion_choisi, 
    id_champion_banni, 
    kills_joueur, 
    mort_joueur, 
    assists_joueur, 
    total_creeps_tues
) VALUES


-- ■■■■■■■■■■■■■■■■■■■■ WEEK 1 ■■■■■■■■■■■■■■■■■■■■ --
(1, 6, 116, 143, 2, 3, 4, 284), 
(1, 7, 39, 40, 5, 2, 4, 203), 
(1, 8, 114, 125, 4, 1, 4, 285), 
(1, 9, 51, 37, 1, 7, 4, 298), 
(1, 10, 83, 101, 0, 4, 9, 26), 
(1, 1, 35, 148, 6, 3, 4, 311), 
(1, 2, 69, 24, 4, 1, 5, 217), 
(1, 3, 2, 71, 3, 3, 5, 293), 
(1, 4, 9, 124, 3, 0, 5, 334), 
(1, 5, 97, 129, 1, 5, 8, 34), 

(2, 26, 3, 4, 5, 3, 4, 207), 
(2, 27, 143, 35, 4, 0, 9, 156), 
(2, 28, 55, 2, 2, 0, 10, 231), 
(2, 29, 54, 66, 5, 1, 7, 265), 
(2, 30, 97, 141, 1, 1, 12, 42), 
(2, 31, 91, 71, 0, 3, 1, 192), 
(2, 32, 151, 148, 0, 3, 4, 157), 
(2, 33, 144, 40, 1, 5, 2, 236), 
(2, 24, 30, 101, 3, 4, 2, 224), 
(2, 35, 17, 44, 1, 2, 4, 31), 

(3, 36, 35, 131, 1, 0, 6, 333), 
(3, 37, 143, 125, 4, 3, 3, 200), 
(3, 38, 141, 48, 2, 0, 7, 267), 
(3, 39, 30, 101, 4, 0, 3, 334), 
(3, 40, 83, 97, 0, 0, 7, 31), 
(3, 21, 145, 71, 0, 1, 2, 305), 
(3, 22, 151, 148, 2, 4, 1, 187), 
(3, 23, 2, 40, 1, 0, 2, 298), 
(3, 24, 149, 51, 0, 2, 2, 353), 
(3, 25, 17, 53, 0, 4, 2, 37), 

(4, 11, 89, 131, 8, 1, 3, 247),
(4, 12, 143, 125, 2, 1, 11, 114), 
(4, 13, 34, 48, 5, 0, 10, 208), 
(4, 14, 30, 101, 7, 1, 4, 246), 
(4, 15, 83, 97, 1, 1, 12, 33), 
(4, 46, 35, 71, 0, 6, 1, 160), 
(4, 47, 146, 148, 1, 8, 2, 120), 
(4, 48, 144, 40, 1, 2, 2, 200), 
(4, 49, 53, 51, 0, 4, 1, 190), 
(4, 50, 97, 53, 2, 3, 2, 25), 

(5, 16, 3, 66, 7, 1, 4, 223), 
(5, 17, 148, 155, 7, 1, 5, 175), 
(5, 18, 2, 69, 2, 0, 5, 258), 
(5, 19, 30, 133, 2, 1, 4, 251), 
(5, 20, 97, 70, 1, 1, 12, 32), 
(5, 41, 40, 71, 2, 5, 0, 176), 
(5, 42, 67, 35, 1, 2, 1, 161), 
(5, 43, 90, 125, 0, 5, 2, 230), 
(5, 44, 149, 55, 1, 2, 1, 269), 
(5, 45, 83, 101, 0, 5, 3, 33), 

(6, 26, 40, 131, 3, 2, 4, 220), 
(6, 27, 39, 35, 6, 1, 8, 213), 
(6, 28, 161, 2, 4, 2, 7, 200), 
(6, 29, 124, 3, 0, 1, 9, 145), 
(6, 30, 109, 37, 4, 1, 5, 41), 
(6, 21, 48, 148, 2, 4, 2, 199), 
(6, 22, 143, 71, 2, 3, 4, 155), 
(6, 23, 12, 54, 1, 4, 3, 243), 
(6, 24, 9, 67, 1, 4, 2, 209), 
(6, 25, 83, 47, 1, 2, 3, 29), 

(7, 41, 3, 124, 8, 1, 9, 245), 
(7, 42, 143, 71, 5, 0, 8, 222), 
(7, 43, 139, 66, 3, 0, 10, 275), 
(7, 44, 51, 133, 7, 0, 8, 332), 
(7, 45, 129, 116, 1, 1, 14, 37), 
(7, 6, 36, 148, 1, 4, 0, 313), 
(7, 7, 67, 125, 1, 5, 0, 144), 
(7, 8, 144, 40, 0, 5, 1, 264), 
(7, 9, 9, 2, 0, 5, 0, 291), 
(7, 10, 83, 37, 0, 5, 0, 29), 

(8, 36, 116, 34, 1, 1, 7, 244), 
(8, 37, 148, 125, 4, 1, 9, 195), 
(8, 38, 161, 67, 4, 3, 5, 238), 
(8, 39, 71, 89, 9, 0, 4, 272), 
(8, 40, 81, 66, 0, 0, 16, 11), 
(8, 11, 23, 40, 1, 5, 0, 271), 
(8, 12, 143, 2, 1, 4, 2, 151), 
(8, 13, 106, 91, 2, 3, 2, 316), 
(8, 14, 30, 144, 1, 2, 1, 309), 
(8, 15, 97, 35, 0, 4, 3, 4), 

(9, 31, 39, 149, 0, 5, 2, 215), 
(9, 32, 143, 40, 1, 4, 1, 139), 
(9, 33, 161, 125, 1, 4, 1, 224), 
(9, 34, 53, 44, 1, 3, 0, 233), 
(9, 35, 83, 4, 0, 4, 2, 28), 
(9, 16, 35, 148, 4, 1, 6, 246), 
(9, 17, 69, 71, 2, 0, 8, 194), 
(9, 18, 2, 121, 7, 0, 9, 231), 
(9, 19, 50, 91, 7, 0, 6, 241), 
(9, 20, 97, 70, 0, 2, 18, 41), 

(10, 46, 37, 9, 3, 2, 3, 269), 
(10, 47, 67, 143, 2, 4, 6, 173), 
(10, 48, 2, 40, 3, 2, 3, 269), 
(10, 49, 149, 91, 2, 2, 6, 324), 
(10, 50, 15, 116, 1, 2, 7, 30), 
(10, 1, 49, 71, 3, 2, 7, 294), 
(10, 2, 39, 148, 5, 3, 7, 242), 
(10, 3, 139, 125, 5, 2, 4, 265), 
(10, 4, 51, 35, 3, 2, 7, 321), 
(10, 5, 129, 97, 0, 2, 13, 27),


-- ■■■■■■■■■■■■■■■■■■■■ WEEK 2 ■■■■■■■■■■■■■■■■■■■■ --
(11, 36, 35, 63, 2, 2, 11, 279), 
(11, 37, 87, 89, 2, 0, 9, 233), 
(11, 38, 2, 54, 4, 0, 7, 280), 
(11, 39, 30, 134, 7, 0, 4, 259), 
(11, 40, 55, 158, 0, 0, 10, 8), 
(11, 46, 91, 71, 1, 5, 1, 189), 
(11, 47, 143, 40, 1, 4, 1, 160), 
(11, 48, 70, 148, 0, 3, 1, 249), 
(11, 49, 9, 151, 0, 1, 0, 303), 
(11, 50, 101, 67, 0, 2, 1, 21), 

(12, 1, 91, 155, 0, 0, 11, 260), 
(12, 2, 148, 40, 5, 1, 5, 192), 
(12, 3, 12, 101, 3, 1, 6, 268), 
(12, 4, 54, 19, 4, 2, 7, 352), 
(12, 5, 97, 37, 1, 1, 11, 37), 
(12, 41, 116, 71, 0, 4, 4, 200), 
(12, 42, 69, 125, 0, 2, 1, 203), 
(12, 43, 153, 35, 1, 2, 2, 293), 
(12, 44, 51, 2, 4, 1, 1, 297), 
(12, 45, 83, 66, 0, 4, 4, 44), 

(13, 11, 48, 3, 4, 2, 4, 234), 
(13, 12, 146, 148, 2, 1, 7, 122), 
(13, 13, 125, 71, 1, 0, 6, 285), 
(13, 14, 149, 124, 3, 0, 2, 327), 
(13, 15, 97, 39, 0, 0, 7, 35), 
(13, 26, 40, 67, 2, 4, 1, 277), 
(13, 27, 87, 143, 0, 3, 0, 145), 
(13, 28, 55, 89, 1, 0, 1, 214), 
(13, 29, 110, 155, 0, 1, 0, 211), 
(13, 30, 109, 83, 0, 2, 0, 38), 

(14, 16, 37, 131, 3, 1, 7, 276), 
(14, 17, 125, 109, 10, 0, 5, 220), 
(14, 18, 122, 134, 1, 0, 7, 239), 
(14, 19, 30, 83, 3, 1, 12, 262), 
(14, 20, 55, 155, 3, 2, 14, 22), 
(14, 21, 35, 148, 0, 5, 1, 226), 
(14, 22, 69, 71, 1, 4, 2, 159), 
(14, 23, 2, 40, 0, 3, 1, 224), 
(14, 24, 51, 49, 3, 4, 1, 251), 
(14, 25, 5, 19, 0, 4, 3, 43), 

(15, 6, 89, 121, 4, 0, 4, 344), 
(15, 7, 148, 40, 5, 1, 3, 179), 
(15, 8, 55, 69, 0, 1, 6, 219), 
(15, 9, 134, 37, 3, 4, 4, 286), 
(15, 10, 155, 3, 0, 0, 9, 7), 
(15, 31, 4, 71, 1, 5, 0, 179), 
(15, 32, 143, 125, 3, 1, 1, 214), 
(15, 33, 2, 9, 0, 3, 4, 293), 
(15, 34, 149, 23, 2, 3, 2, 301), 
(15, 35, 97, 27, 0, 0, 5, 32),

(16, 46, 89, 71, 1, 4, 2, 312),
(16, 47, 69, 55, 1, 9, 4, 231),
(16, 48, 2, 40, 4, 1, 3, 292),
(16, 49, 158, 109, 4, 2, 2, 376),
(16, 50, 160, 30, 0, 3, 4, 22),
(16, 16, 35, 134, 4, 3, 6, 300),
(16, 17, 148, 65, 3, 2, 13, 204),
(16, 18, 139, 125, 6, 3, 5, 335),
(16, 19, 51, 155, 5, 1, 6, 354),
(16, 20, 101, 83, 1, 1, 11, 21),

(17, 21, 116, 69, 1, 0, 4, 255),
(17, 22, 148, 125, 3, 3, 2, 175),
(17, 23, 139, 40, 1, 1, 6, 296),
(17, 24, 134, 155, 4, 1, 3, 250),
(17, 25, 101, 55, 1, 0, 6, 21),
(17, 41, 91, 71, 0, 1, 1, 219),
(17, 42, 39, 131, 0, 1, 4, 202),
(17, 43, 12, 35, 4, 3, 1, 272),
(17, 44, 149, 37, 1, 4, 1, 212),
(17, 45, 97, 19, 0, 1, 2, 42),

(18, 31, 145, 121, 2, 0, 3, 245), 
(18, 32, 143, 40, 5, 0, 5, 189), 
(18, 33, 2, 101, 2, 1, 6, 260), 
(18, 34, 9, 47, 2, 0, 4, 272), 
(18, 35, 83, 89, 1, 0, 5, 28), 
(18, 1, 36, 71, 0, 3, 0, 184), 
(18, 2, 87, 54, 0, 2, 1, 160), 
(18, 3, 161, 148, 0, 4, 1, 209), 
(18, 4, 149, 116, 1, 2, 0, 261), 
(18, 5, 97, 49, 0, 1, 1, 34), 

(19, 6, 102, 109, 0, 2, 5, 364),
(19, 7, 143, 146, 1, 3, 4, 217),
(19, 8, 3, 149, 4, 6, 3, 255),
(19, 9, 30, 48, 4, 3, 1, 380),
(19, 10, 155, 37, 0, 2, 7, 9),
(19, 11, 91, 148, 1, 1, 9, 314),
(19, 12, 47, 125, 3, 4, 12, 161),
(19, 13, 121, 89, 3, 1, 8, 320),
(19, 14, 78, 2, 9, 1, 6, 405),
(19, 15, 97, 122, 0, 2, 11, 33),

(20, 26, 3, 35, 4, 7, 6, 334),
(20, 27, 143, 125, 4, 3, 9, 212),
(20, 28, 122, 81, 3, 4, 11, 364),
(20, 29, 54, 116, 7, 3, 10, 510),
(20, 30, 94, 91, 4, 5, 7, 97),
(20, 36, 49, 40, 5, 5, 8, 422),
(20, 37, 63, 148, 6, 5, 8, 306),
(20, 38, 2, 69, 3, 6, 8, 395),
(20, 39, 30, 83, 8, 2, 11, 416),
(20, 40, 55, 101, 0, 4, 18, 39),


-- ■■■■■■■■■■■■■■■■■■■■ WEEK 3 ■■■■■■■■■■■■■■■■■■■■ --
(21, 1, 91, 54, 1, 6, 11, 227),
(21, 2, 62, 40, 6, 1, 12, 249),
(21, 3, 2, 71, 2, 5, 11, 306),
(21, 4, 9, 155, 8, 4, 3 , 371),
(21, 5, 97, 3, 1, 6, 12, 36),
(21, 26, 1, 125, 7, 3, 10, 269),
(21, 27, 143, 35, 5, 4, 10, 147),
(21, 28, 122, 148, 3, 5, 16, 282),
(21, 29, 30, 95, 7, 2, 6, 344),
(21, 30, 160, 63, 0, 4, 17, 26),

(22, 31, 40, 55, 1, 1, 5, 325),
(22, 32, 151, 131, 1, 0, 2, 212),
(22, 33, 144, 101, 3, 1, 3, 332),
(22, 34, 71, 59, 7, 0, 1, 389),
(22, 35, 81, 48, 0, 0, 10, 13),
(22, 21, 37, 121, 1, 3, 0, 362),
(22, 22, 143, 148, 1, 3, 0, 193),
(22, 23, 12, 109, 0, 1, 1, 411),
(22, 24, 9, 47, 0, 2, 0, 349),
(22, 25, 72, 146, 0, 3, 1, 20),

(23, 36, 121, 101, 2, 1, 13, 299),
(23, 37, 143, 125, 5, 2, 7, 225),
(23, 38, 2, 148, 3, 1, 10, 325),
(23, 39, 54, 137, 13, 0, 6, 272),
(23, 40, 83, 109, 0, 1, 16, 37),
(23, 16, 35, 71, 1, 3, 0, 305),
(23, 17, 69, 12, 1, 6, 0, 191),
(23, 18, 139, 155, 1, 4, 3, 275),
(23, 19, 30, 59, 0, 4, 0, 252),
(23, 20, 111, 161, 2, 6, 0, 47),

(24, 41, 32, 89, 1, 2, 5, 427), 
(24, 42, 63, 146, 2, 3, 4, 335), 
(24, 43, 125, 47, 4, 1, 0, 453), 
(24, 44, 110, 49, 1, 1, 4, 394), 
(24, 45, 10, 35, 0, 3, 8, 35), 
(24, 11, 37, 148, 3, 0, 3, 425), 
(24, 12, 143, 40, 1, 5, 2, 215), 
(24, 13, 12, 71, 2, 2, 5, 450), 
(24, 14, 78, 153, 4, 0, 4, 525), 
(24, 15, 101, 19, 0, 1, 7, 29);


-- ■■■■■■■■■■■■■■■■■■■■ WEEK 4 ■■■■■■■■■■■■■■■■■■■■ --


