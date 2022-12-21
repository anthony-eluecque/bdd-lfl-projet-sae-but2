-- Creation des tables pour les fonctions.
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