create or replace function get_matchs_joueur(
    vid_joueur Joueurs.id_joueur%type
) RETURNS TABLE(
    vid_match INTEGER,
    kda DECIMAL
) AS $$
DECLARE
    var_r RECORD;
BEGIN 
    FOR var_r IN (select id_match from historique_matchs
                    WHERE id_joueur=vid_joueur)
    LOOP    
        vid_match = var_r.id_match;
        kda = calcul_kda_joueur_match(vid_joueur,var_r.id_match);
        return NEXT;
    END LOOP;
END;
$$ language plpgsql;


create or replace function meilleurs_matchs_joueur(
    v_id_joueur Joueurs.id_joueur%type
) RETURNS TABLE(
    v_id_match INTEGER
) AS $$
DECLARE
    var_r RECORD;
BEGIN 
    FOR var_r IN (
        SELECT vid_match FROM  get_matchs_joueur(v_id_joueur)
        ORDER BY kda LIMIT 3
    )
    LOOP
        v_id_match = var_r.vid_match;
        return NEXT;
    END LOOP;
END;
$$ language plpgsql;