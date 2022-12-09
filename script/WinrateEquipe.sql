CREATE OR REPLACE FUNCTION calcul_winrate_equipe(v_id_equipe Equipes.id_equipe%type)
RETURNS DECIMAL as $$ 
DECLARE

    total_wins INTEGER;
    total_matchs INTEGER;

BEGIN

    IF (v_id_equipe IN (SELECT id_equipe FROM Equipes)) THEN
        SELECT COUNT(vainqueur) INTO total_wins FROM Matchs WHERE vainqueur = v_id_equipe;
        SELECT COUNT(id_match) INTO total_matchs FROM Matchs WHERE id_equipe_1 = v_id_equipe OR id_equipe_2 = v_id_equipe;
        RETURN ROUND(((total_wins::DECIMAL) / total_matchs::DECIMAL),2)*100;
    ELSE
        raise exception 'L equipe passé en paramètre n existe pas';
    END IF;
END;
$$ language plpgsql;