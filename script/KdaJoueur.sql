CREATE OR REPLACE FUNCTION calcul_kda_joueur(v_id_joueur Joueurs.id_joueur%type)
RETURNS DECIMAL AS $$
DECLARE
    v_kills INTEGER;
    v_morts INTEGER;
    v_assists INTEGER;

BEGIN
    v_kills:=0;
    v_morts:=0;
    v_assists:=0;

    IF (v_id_joueur IN (SELECT id_joueur FROM joueurs)) THEN
        SELECT SUM(kills_joueur) INTO v_kills FROM Historique_Matchs WHERE id_joueur = v_id_joueur;
        SELECT SUM(mort_joueur) INTO v_morts FROM Historique_Matchs WHERE id_joueur = v_id_joueur;
        SELECT SUM(assists_joueur) INTO v_assists FROM Historique_Matchs WHERE id_joueur = v_id_joueur;

        IF (v_morts > 0) THEN 
            RETURN ROUND(((v_kills::DECIMAL+v_assists::DECIMAL) / v_morts::DECIMAL),3); -- Cas ou le joueur est mort.
        ELSE
            RETURN ROUND((v_kills::DECIMAL+v_assists::DECIMAL),3); -- Cas ou il n'est pas mort et une division par 0 est impossible.
        END IF;
    ELSE
        raise exception 'Valeur incorrect, id n existe pas dans la base de donnée des joueurs';
    END IF;
END;
$$ language plpgsql;
