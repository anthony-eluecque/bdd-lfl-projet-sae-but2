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