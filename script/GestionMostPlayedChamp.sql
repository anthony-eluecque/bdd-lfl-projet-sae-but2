CREATE TABLE PlayedChamp(
    id_joueur INTEGER PRIMARY KEY,
    id champ1 INTEGER NOT NULL,
    id champ2 INTEGER ,
    id_champ3 INTEGER
);


CREATE OR REPLACE FUNCTION MostPlayedChampByPlayer()
RETURNS TRIGGER AS $$
BEGIN
    vid_champ Champions.id_champion%type;

    log_historique Historique_Matchs%rowtype;

DECLARE

    IF (new.id_joueur IN (SELECT id_joueur FROM Joueurs))
    THEN
        FOR log_historique IN SELECT * FROM Historique_Matchs 
                                WHERE id_joueur = new.id_joueur
        LOOP 


        END LOOP;
    ELSE 
    
    
    END IF;

    

END;
$$ language plpgsql;



CREATE TRIGGER trigger_gestion_champ_joueur
AFTER INSERT ON Historique_Matchs
FOR EACH ROW
EXECUTE PROCEDURE MostPlayedChampByPlayer();