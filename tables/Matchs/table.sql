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
    duree_match TIME NOT NULL,
    vainqueur INTEGER NOT NULL,
    perdant INTEGER NOT NULL,
    num_semaine INTEGER NOT NULL
);