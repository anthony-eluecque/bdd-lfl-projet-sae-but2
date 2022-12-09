CREATE OR REPLACE FUNCTION verif_insert_historique_matchs() RETURNS TRIGGER AS $$
BEGIN
    IF (new.kills_joueur > -1 AND new.mort_joueur > -1 AND new.assists_joueur > -1 ) THEN
        RETURN NEW;
    ELSE
        RAISE NOTICE 'Votre valeur doit être cohérente , un joueur ne peut pas avoir de stats négatives !';
    END IF;
END;
$$ language plpgsql;

CREATE TRIGGER verification_historique_match
BEFORE INSERT ON Historique_Matchs -- Utilisation du mot before
FOR EACH ROW 
EXECUTE PROCEDURE verif_insert_historique_matchs();