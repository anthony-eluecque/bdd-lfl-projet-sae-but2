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
