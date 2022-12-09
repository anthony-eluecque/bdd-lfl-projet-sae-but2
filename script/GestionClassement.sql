CREATE TRIGGER classement_equipe
AFTER INSERT ON Matchs -- Utilisation du mot insert
FOR EACH ROW 
EXECUTE PROCEDURE gestion_classement();

CREATE OR REPLACE FUNCTION gestion_classement() RETURNS TRIGGER AS $$
DECLARE
    v_id_equipe_gagnante classement_LFL.id_equipe%type;
    v_id_equipe_perdante classement_LFL.id_equipe%type;

    nb_win_existantes classement_LFL.nb_lose%type;
    nb_loses_existantes classement_LFL.nb_win%type;

BEGIN

    nb_win_existantes :=0;
    nb_loses_existantes:=0;

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



    RETURN NEW;
END;
$$ language plpgsql;