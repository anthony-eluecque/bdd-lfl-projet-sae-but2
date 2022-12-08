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