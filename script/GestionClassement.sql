-- Création de la table "classement_week_lfl" afin de pouvoir stocker le classement de la LFL durant un week précis.
CREATE TABLE classement_week_lfl(
    id_equipe INTEGER,
    nb_win INTEGER,
    nb_lose INTEGER,
    week INTEGER
);


-- Fonction permettant de mettre le classement à jour.
CREATE OR REPLACE FUNCTION gestion_classement() RETURNS TRIGGER AS $$
DECLARE
    v_id_equipe_gagnante classement_LFL.id_equipe%type;
    v_id_equipe_perdante classement_LFL.id_equipe%type;

    nb_win_existantes classement_LFL.nb_win%type;
    nb_loses_existantes classement_LFL.nb_lose%type;

    nb_week_win INTEGER;
    nb_week_lose INTEGER;
BEGIN
    nb_win_existantes :=0;
    nb_loses_existantes:=0;
    nb_week_lose :=0;
    nb_week_win := 0;

    SELECT id_equipe INTO v_id_equipe_gagnante FROM classement_LFL WHERE id_equipe = new.vainqueur;
    SELECT id_equipe INTO v_id_equipe_perdante FROM classement_LFL WHERE id_equipe = new.perdant;

    IF (v_id_equipe_gagnante IS NULL) THEN 
        INSERT INTO classement_LFL values(new.vainqueur,1,0); -- Si il n'existe pas encore alors il a que  le match qu'il vient de jouer
    ELSE  -- On s'occupe de modifier l'existant sinon  
        -- On récupère les données existantes et on update le classement
        SELECT nb_win INTO nb_win_existantes FROM classement_LFL WHERE id_equipe = v_id_equipe_gagnante;
        nb_win_existantes = nb_win_existantes + 1;
        UPDATE classement_LFL SET nb_win = nb_win_existantes WHERE id_equipe = v_id_equipe_gagnante;
    END IF;

    IF (v_id_equipe_perdante IS NULL) THEN 
        INSERT INTO classement_LFL values(new.perdant,0,1); -- Si il n'existe pas encore alors il a que  le match qu'il vient de jouer
    ELSE  -- On s'occupe de modifier l'existant sinon  
        -- On récupère les données existantes et on update le classement
        SELECT nb_lose INTO nb_loses_existantes FROM classement_LFL WHERE id_equipe = v_id_equipe_perdante;
        nb_loses_existantes = nb_loses_existantes + 1;
        UPDATE classement_LFL SET nb_lose = nb_loses_existantes WHERE id_equipe = v_id_equipe_perdante;
    END IF;


    SELECT id_equipe INTO v_id_equipe_gagnante FROM classement_week_lfl WHERE id_equipe = new.vainqueur AND week = new.num_semaine;
    -- raise notice '% , %' , v_id_equipe_gagnante,v_id_equipe_perdante;
    IF (v_id_equipe_gagnante IS NULL) THEN
        INSERT INTO classement_week_lfl values (new.vainqueur,1,0,new.num_semaine);
    ELSE    
        SELECT nb_win INTO nb_week_win FROM classement_week_lfl WHERE id_equipe = v_id_equipe_gagnante AND week = new.num_semaine;
        nb_week_win = nb_week_win + 1;
        UPDATE classement_week_lfl SET nb_win = nb_week_win WHERE id_equipe = v_id_equipe_gagnante AND week = new.num_semaine;
    END IF;

    SELECT id_equipe INTO v_id_equipe_perdante FROM classement_week_lfl WHERE id_equipe = new.perdant AND week = new.num_semaine;
    
    IF (v_id_equipe_perdante IS NULL) THEN
        INSERT INTO classement_week_lfl values (new.perdant,0,1,new.num_semaine);
    ELSE 
        SELECT nb_lose INTO nb_week_lose FROM classement_week_lfl WHERE id_equipe = v_id_equipe_perdante AND week = new.num_semaine;
        nb_week_lose = nb_week_lose + 1;
        -- raise notice 'nb_lose : %',nb_week_lose;
        UPDATE classement_week_lfl SET nb_lose = nb_week_lose WHERE id_equipe = v_id_equipe_perdante AND week = new.num_semaine;
    END IF;

    RETURN NEW;
END;
$$ language plpgsql;


-- Trigger qui exécute la fonction "gestion_classement" après l'insertion de tuple dans la table "Matchs".
CREATE TRIGGER classement_equipe
AFTER INSERT ON Matchs -- Utilisation du mot insert
FOR EACH ROW 
EXECUTE PROCEDURE gestion_classement();
