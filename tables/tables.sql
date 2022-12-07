-- ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■ --
-- ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■ --
-- ■■■■■■       ■■■■■■■            ■■■■       ■■■■■■■■■■ --
-- ■■■■■■  ■■   ■■■■■■■   ■■■■■■■  ■■■■  ■■   ■■■■■■■■■■ --
-- ■■■■■■  ■■   ■■■■■■■   ■■       ■■■■  ■■   ■■■■■■■■■■ --
-- ■■■■■■  ■■      ■■■■   ■■■■   ■■■■■■  ■■       ■■■■■■ --
-- ■■■■■■  ■■■■■   ■■■■   ■■     ■■■■■■  ■■■■■■   ■■■■■■ --
-- ■■■■■■  ■■■■■   ■■■■   ■■   ■■■■■■■■  ■■■■■■   ■■■■■■ --
-- ■■■■■■          ■■■■        ■■■■■■■■           ■■■■■■ --
-- ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■ --
-- ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■ --
-- Auteur : Eluecque Anthony, Fournier Benjamin, Dournel Frédéric

-- TABLES POUR LA DATABASE LEAGUE OF LEGENDS LFL 2022 --



CREATE DATABASE LFL;

/* ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
Table Joueurs
Description : Table contenant les informations relatif à un joueur League Of Legends.  

-- Explication supplémentaire 
■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■ */
CREATE TABLE Joueurs(
    id_joueur SERIAL PRIMARY KEY,
    pseudo VARCHAR(50) NOT NULL,
    nom VARCHAR(50) NOT NULL,
    prenom VARCHAR(50) NOT NULL,
    date_naissance DATE,
    id_nationalite INTEGER NOT NULL REFERENCES Nationalites(id_nationalite)
);

/* ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
Table Jouer_Dans
Description : Table contenant la liste des joueurs de chaque équipe, avec leur role

-- Explication supplémentaire 
■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■ */
CREATE TABLE Jouer_dans(
    id_joueur INTEGER NOT NULL REFERENCES Joueurs(id_joueur),
    id_role INTEGER NOT NULL REFERENCES Roles(id_role),
    id_equipe INTEGER NOT NULL REFERENCES Equipes(id_equipe),
    debut_contrat DATE NOT NULL,
    fin_contrat DATE
);

/* ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
Table Equipees
Description : Table contenant les informations d'une équipe e-sport sur le jeu League Of Legend pticipant à la LFL.

-- Explication supplémentaiaire : 
■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■ */
CREATE TABLE Equipes(
    id_equipe SERIAL PRIMARY KEY,
    nom_equipe VARCHAR(50) NOT NULL,
    date_creation DATE NOT NULL,
    id_coach INTEGER NOT NULL REFERENCES Coachs(id_coach)
);

/* ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
Table Roles
Description : Table référensant les différents rôles dans le jeu League Of Legends.
 
-- Explication supplémentaire : 
■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■ */
CREATE TABLE Roles(
    id_role SERIAL PRIMARY KEY,
    nom_role VARCHAR(50)
);

/* ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
Table Champions
Description : Table composée des différents champions jouablent dans le jeu League Of Legends.

-- Explication supplémentaire : 
■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■ */
CREATE TABLE Champions(
    id_champion SERIAL PRIMARY KEY,
    nom_champion VARCHAR(50),
    id_role_1 INTEGER NOT NULL REFERENCES Roles(id_role),
    id_role_2 INTEGER REFERENCES Roles(id_role)
);

/* ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
Table Coachs 
Description : Table référensant les Coachs des différentes équipes e-sport League Of Legends participant à la LFL 2022.

-- Explication supplémentaire
■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■ */
CREATE TABLE Coachs(
    id_coach SERIAL PRIMARY KEY,
    pseudo_coach VARCHAR(50) NOT NULL,
    nom_coach VARCHAR(50) NOT NULL,
    prenom_coach VARCHAR(50) NOT NULL,
    id_nationalite INTEGER NOT NULL REFERENCES Nationalites(id_nationalite)
);

/* ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
Table Nationnalites
Description : Table Répertoriant des nationalités.

-- Explication supplémentaire
■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■ */
CREATE TABLE Nationalites(
    id_nationalite SERIAL PRIMARY KEY,
    libelle_nationalite VARCHAR(50)
);

/* ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
Table StatistiquesJoueursParMatch
Description : Table contenant différentes statistiques sur les joueurs professionnel de League Of Legends participant à la LFL 2022.

-- Explication supplémentaire
■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■ */
CREATE TABLE StatistiquesJoueursParMatch(
    id_match INTEGER NOT NULL REFERENCES Matchs(id_match) ,
    id_joueur INTEGER NOT NULL REFERENCES Joueurs(id_joueur),
    nb_kills INTEGER,
    morts INTEGER,
    assists INTEGER,
    total_creeps INTEGER
);

/* ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
Table Matchs
Description : Table répertoriant les matchs joué durant la LFL 2022.

Explication supplémentaire
■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■ */
CREATE TABLE Matchs(
    id_match SERIAL PRIMARY KEY,
    id_equipe_1  INTEGER NOT NULL REFERENCES Equipes(id_equipe),
    id_equipe_2  INTEGER NOT NULL REFERENCES Equipes(id_equipe),
    date_match DATE NOT NULL,
    duree_match MINUTES NOT NULL,
    vainqueur INTEGER NOT NULL,
    perdant INTEGER NOT NULL,
    num_semaine INTEGER NOT NULL
);



/* ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
                                        FIN DU SCRIPT
■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■ */