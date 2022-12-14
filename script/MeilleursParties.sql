    create or replace function get_matchs_joueur(
        vid_joueur Joueurs.id_joueur%type
    ) RETURNS TABLE(
        vid_match INTEGER,
        kda DECIMAL,
        id_champion INTEGER
    ) AS $$
    DECLARE
        var_r RECORD;
    BEGIN 
        FOR var_r IN (select id_match,id_champion_choisi from historique_matchs
                        WHERE id_joueur=vid_joueur)
        LOOP    
            vid_match = var_r.id_match;
            kda = calcul_kda_joueur_match(vid_joueur,var_r.id_match);
            id_champion = var_r.id_champion_choisi;
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
        -- Je crois avoir oublié le desc
    )
    LOOP
        v_id_match = var_r.vid_match;
        return NEXT;
    END LOOP;
END;
$$ language plpgsql;

create or replace function get_champions_joueur(
    v_id_joueur Joueurs.id_joueur%type
) RETURNS TABLE(
    champ_nom VARCHAR(50)
) AS $$
DECLARE
    var_r RECORD;
BEGIN
    FOR var_r IN (
        SELECT id_champion FROM get_matchs_joueur(v_id_joueur)
        ORDER BY kda LIMIT 3
    )
    LOOP
        champ_nom = getNomChampion(var_r.id_champion);
        return NEXT;
    END LOOP;
END;
$$ language plpgsql;