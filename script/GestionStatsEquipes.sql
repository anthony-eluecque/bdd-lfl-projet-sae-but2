CREATE TRIGGER trigger_gestion_stats_equipes
AFTER INSERT OR UPDATE ON classement_LFL
FOR EACH ROW 
EXECUTE PROCEDURE gestion_stats_equipes();


DROP FUNCTION gestion_stats_equipes CASCADE;
DROP TABLE statistique_LFL;
-- Fonction permettant de mettre à jour automatiquement la table statistiques LFL.
CREATE OR REPLACE FUNCTION gestion_stats_equipes()
RETURNS TRIGGER AS $$
DECLARE
    v_winrate statistique_LFL.winrate%type;
    v_id_equipe Equipes.id_equipe%type;

BEGIN
    SELECT id_equipe INTO v_id_equipe FROM statistique_LFL WHERE id_equipe = new.id_equipe;
    IF (v_id_equipe IS NULL) THEN 
        INSERT INTO statistique_LFL values(
            new.id_equipe,
            calcul_winrate_equipe(new.id_equipe),
            calcul_kda_equipe(new.id_equipe),
            calcul_duree_moyenne_matchs_equipe(new.id_equipe));
    ELSE
        UPDATE statistique_LFL SET
            winrate = calcul_winrate_equipe(v_id_equipe),
            kda_equipe = calcul_kda_equipe(v_id_equipe),
            moyenne_duree_game = calcul_duree_moyenne_matchs_equipe(id_equipe)
        WHERE id_equipe = v_id_equipe;
    END IF;
    RETURN new;
END;
$$ language plpgsql;
