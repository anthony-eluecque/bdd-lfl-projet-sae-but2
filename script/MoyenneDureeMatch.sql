-- Moyenne de durée d'un match pour une équipe
CREATE OR REPLACE FUNCTION calcul_duree_moyenne_matchs_equipe(
    v_id_equipe Equipes.id_equipe%type
)
RETURNS TIME AS $$
BEGIN
    RETURN AVG(duree_match) FROM Matchs WHERE id_equipe_1 = v_id_equipe OR id_equipe_2 = v_id_equipe;
END;
$$ language plpgsql;


-- Moyenne de durée d'un match pour toutes les équipes
CREATE OR REPLACE FUNCTION calcul_duree_moyenne_total_matchs()
RETURNS TIME AS $$
BEGIN
    RETURN AVG(duree_match) FROM Matchs;
END;
$$ language plpgsql;


-- Moyenne de durée d'un match à partir d'un identifiant
CREATE OR REPLACE FUNCTION calcul_duree_moyenne_matchs_personne(
    v_id_joueur Joueurs.id_joueur%type
)
RETURNS TIME AS $$
DECLARE
    v_id_equipe Equipes.id_equipe%type;
BEGIN
    SELECT id_equipe INTO v_id_equipe FROM Jouer_Dans WHERE id_joueur = v_id_joueur;
    IF (v_id_equipe IS NOT NULL) THEN
        RETURN calcul_duree_moyenne_matchs_equipe(v_id_equipe);
    ELSE
        raise exception 'Votre joueur ne fait partie d aucune equipe';
    END IF;
END;
$$ language plpgsql;



