-- Fonction d'avoir le classement des joueurs
create or replace function get_classement_joueurs()
RETURNS TABLE(
    vid_joueur INTEGER,
    nom_joueur VARCHAR(50),
    classement SMALLINT,
    kda DECIMAL
) AS $$
DECLARE
    var_r RECORD;
    i SMALLINT;
BEGIN
    i :=1;
    FOR var_r IN (
        SELECT id_joueur,nom_joueur FROM Joueurs
        ORDER BY calcul_kda_joueur(id_joueur) DESC
    )
    LOOP
        classement := i;
        vid_joueur = var_r.id_joueur;
        nom_joueur = getNomJoueur(var_r.id_joueur);
        kda = calcul_kda_joueur(var_r.id_joueur);
        i = i + 1;
        RETURN next;
    END LOOP;
END;
$$ language plpgsql;

-- Fonction qui permet d'obtenir le placement d'un joueur dans la LFL.
create or replace function get_position_joueur(
    v_id_joueur Joueurs.id_joueur%type
)
RETURNS SMALLINT AS $$
BEGIN
    RETURN (SELECT classement from get_classement_joueurs() WHERE vid_joueur = v_id_joueur);
END;
$$ language plpgsql;