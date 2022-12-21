-- Fonction permettant de vérifier la cohérences des valeurs que l'on veut insérer dans la table "Matchs".
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


-- Trigger qui exécute la fonction "verif_insert_matchs" avant l'insertion de tuple dans la table "Matchs".
CREATE TRIGGER verification_matchs
BEFORE INSERT ON Matchs -- Utilisation du mot before
FOR EACH ROW 
EXECUTE PROCEDURE verif_insert_matchs();