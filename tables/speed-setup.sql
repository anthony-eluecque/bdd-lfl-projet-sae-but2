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

    nb_win_existantes classement_LFL.nb_lose%type;
    nb_loses_existantes classement_LFL.nb_win%type;

BEGIN

    nb_win_existantes :=0;
    nb_loses_existantes:=0;

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
(2, 1, '01-06-2022', '00:32:15', 1 , 2, 1),
(6, 7, '01-06-2022', '00:27:27', 6, 7, 1),
(8, 5, '01-06-2022', '00:36:07', 8, 5, 1),
(3, 10,'01-06-2022', '00:24:40', 3, 10, 1),
(4, 9, '01-06-2022', '00:27:04', 4, 9, 1),
(6, 5, '02-06-2022', '00:26:37', 6, 5, 1),
(9, 2, '02-06-2022', '00:30:21', 9, 2, 1),
(8, 3, '02-06-2022', '00:31:45', 3, 8, 1),
(7, 4,'02-06-2022', '00:26:24',4, 7, 1),
(10, 1,'02-06-2022', '00:30:55', 1, 10, 1),
(8, 10, '08-06-2022', '00:29:07', 8, 10, 2),
(1, 9, '08-06-2022', '00:31:23', 1, 9, 2),
(3, 6, '08-06-2022', '00:29:57', 3, 6, 2),
(4, 5, '08-06-2022', '00:28:51', 4, 5, 2),
(2, 7, '08-06-2022', '00:31:16', 2, 7, 2),
(10, 4, '09-06-2022', '00:36:53', 4, 10, 2),
(5, 9, '09-06-2022', '00:29:00', 5, 9, 2),
(1, 7, '09-06-2022', '00:26:10', 1, 7, 2),
(2, 3, '09-06-2022', '00:40:10', 3, 2, 2),
(6, 8, '09-06-2022', '00:48:11', 6, 8, 2),
(1, 6, '15-06-2022', '00:36:56', 1, 6, 3),
(7, 5, '15-06-2022', '00:37:04', 7, 5, 3),
(8, 4, '15-06-2022', '00:32:53', 8, 4, 3),
(9, 3, '15-06-2022', '00:47:50', 3, 9, 3),
(10, 2, '15-06-2022', '00:34:49', 2, 10, 3),
(5, 1, '16-06-2022', '00:28:40', 1, 5, 3),
(6, 4, '16-06-2022', '00:27:31', 4, 6, 3),
(7, 3, '16-06-2022', '00:27:32', 3, 7, 3),
(8, 2, '16-06-2022', '00:37:56', 8, 2, 3),
(10, 9, '16-06-2022', '00:40:24', 10, 9, 3);


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
(1,6,116,143,2,3,4,284),
(1,7,39,40,5,2,4,203),
(1,8,114,125,4,1,4,285),
(1,9,51,37,1,7,4,298),
(1,10,83,101,0,4,9,26),
(1,1,35,148,6,3,4,311),
(1,2,69,24,4,1,5,217),
(1,3,2,71,3,3,5,293),
(1,4,9,124,3,0,5,334),
(1,5,97,129,1,5,8,34),
(2,26,3,4,5,3,4,207),
(2,27,143,35,4,0,9,156),
(2,28,55,2,2,0,10,231),
(2,29,54,66,5,1,7,265),
(2,30,97,141,1,1,12,42),
(2,31,91,71,0,3,1,192),
(2,32,151,148,0,3,4,157),
(2,33,144,40,1,5,2,236),
(2,34,30,101,3,4,2,224),
(2,35,17,44,1,2,4,31),
(3,36,35,131,1,0,6,333),
(3,37,143,125,4,3,3,200),
(3,38,141,48,2,0,7,267),
(3,39,30,101,4,0,3,334),
(3,40,83,97,0,0,7,31),
(3,21,145,71,0,1,2,305),
(3,22,151,148,2,4,1,187),
(3,23,2,40,1,0,2,298),
(3,24,149,51,0,2,2,353),
(3,25,17,53,0,4,2,37),
(4,11,89,131,8,1,3,247),
(4,12,143,125,2,1,11,114),
(4,13,34,48,5,0,10,208),
(4,14,30,101,7,1,4,246),
(4,15,83,97,1,1,12,33),
(4,46,35,71,0,6,1,160),
(4,47,146,148,1,8,2,120),
(4,48,144,40,1,2,2,200),
(4,49,53,51,0,4,1,190),
(4,50,97,53,2,3,2,25),
(5,16,3,66,7,1,4,223),
(5,17,148,155,7,1,5,175),
(5,18,2,69,2,0,5,258),
(5,19,30,133,2,1,4,251),
(5,20,97,70,1,1,12,32),
(5,41,40,71,2,5,0,176),
(5,42,67,35,1,2,1,161),
(5,43,90,125,0,5,2,230),
(5,44,149,55,1,2,1,269),
(5,45,83,101,0,5,3,33),
(6,26,40,131,3,2,4,220),
(6,27,39,35,6,1,8,213),
(6,28,161,2,4,2,7,200),
(6,29,124,3,0,1,9,145),
(6,30,109,37,4,1,5,41),
(6,21,48,148,2,4,2,199),
(6,22,143,71,2,3,4,155),
(6,23,12,54,1,4,3,243),
(6,24,9,67,1,4,2,209),
(6,25,83,47,1,2,3,29),
(7,41,3,124,8,1,9,245),
(7,42,143,71,5,0,8,222),
(7,43,139,66,3,0,10,275),
(7,44,51,133,7,0,8,332),
(7,45,129,116,1,1,14,37),
(7,6,36,148,1,4,0,313),
(7,7,67,125,1,5,0,144),
(7,8,144,40,0,5,1,264),
(7,9,9,2,0,5,0,291),
(7,10,83,37,0,5,0,29),
(8,36,116,34,1,1,7,244),
(8,37,148,125,4,1,9,195),
(8,38,161,67,4,3,5,238),
(8,39,71,89,9,0,4,272),
(8,40,81,66,0,0,16,11),
(8,11,23,40,1,5,0,271),
(8,12,143,2,1,4,2,151),
(8,13,106,91,2,3,2,316),
(8,14,30,144,1,2,1,309),
(8,15,97,35,0,4,3,4),
(9,31,39,149,0,5,2,215),
(9,32,143,40,1,4,1,139),
(9,33,161,125,1,4,1,224),
(9,34,53,44,1,3,0,233),
(9,35,83,4,0,4,2,28),
(9,16,35,148,4,1,6,246),
(9,17,69,71,2,0,8,194),
(9,18,2,121,7,0,9,231),
(9,19,50,91,7,0,6,241),
(9,20,97,70,0,2,18,41),
(10,46,37,9,3,2,3,269),
(10,47,67,143,2,4,6,173),
(10,48,2,40,3,2,3,269),
(10,49,149,91,2,2,6,324),
(10,50,15,116,1,2,7,30),
(10,1,49,71,3,2,7,294),
(10,2,39,148,5,3,7,242),
(10,3,139,125,5,2,4,265),
(10,4,51,35,3,2,7,321),
(10,5,129,97,0,2,13,27);
