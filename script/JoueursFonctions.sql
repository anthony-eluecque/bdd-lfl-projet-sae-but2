create or replace function getNomJoueur(
    vid_joueur Joueurs.id_joueur%type
) RETURNS VARCHAR AS $$
BEGIN
    RETURN (SELECT nom FROM Joueurs where id_joueur = vid_joueur);
END;
$$ language plpgsql;

create or replace function getPrenomJoueur(
    vid_joueur Joueurs.id_joueur%type
) RETURNS VARCHAR AS $$
BEGIN 
    RETURN (SELECT prenom FROM Joueurs where id_joueur = vid_joueur);
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