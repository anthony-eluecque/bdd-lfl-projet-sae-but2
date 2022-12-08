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