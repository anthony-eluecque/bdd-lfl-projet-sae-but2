CREATE OR REPLACE FUNCTION gestion_stats_equipes()
RETURNS TRIGGER AS $$
DECLARE
    v_winrate statistique_LFL.winrate%type;
    v_id_equipe Equipes.id_equipe%type;
    v_id_equipe_bdd Equipes.id_equipe%type;

BEGIN
    SELECT id_equipe INTO v_id_equipe_bdd FROM Jouer_dans 
                    WHERE id_joueur = new.id_joueur; 
    SELECT id_equipe INTO v_id_equipe FROM statistique_LFL 
                    WHERE id_equipe = v_id_equipe_bdd;
    IF (v_id_equipe IS NULL) THEN 
        INSERT INTO statistique_LFL values(
            v_id_equipe_bdd,
            calcul_winrate_equipe(v_id_equipe_bdd),
            calcul_kda_equipe(v_id_equipe_bdd),
            calcul_duree_moyenne_matchs_equipe(v_id_equipe_bdd));
    ELSE
        UPDATE statistique_LFL SET
            winrate = calcul_winrate_equipe(v_id_equipe),
            kda_equipe = calcul_kda_equipe(v_id_equipe),
            moyenne_duree_game = calcul_duree_moyenne_matchs_equipe(v_id_equipe)
        WHERE id_equipe = v_id_equipe;
    END IF;
    RETURN new;
END;
$$ language plpgsql;

CREATE TRIGGER trigger_gestion_stats_equipes
AFTER INSERT OR UPDATE ON Historique_Matchs
FOR EACH ROW 
EXECUTE PROCEDURE gestion_stats_equipes();