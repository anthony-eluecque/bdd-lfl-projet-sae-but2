-- Calcul KDA d'une Equipe entière par l'id de l'équipe
CREATE OR REPLACE FUNCTION calcul_kda_equipe(v_id_equipe Equipes.id_equipe%type)
RETURNS DECIMAL AS $$ 
DECLARE 

    total_kda DECIMAL;
    
    v_id_joueur Joueurs.id_joueur%type;
    v_curseur CURSOR FOR SELECT id_joueur from Jouer_Dans WHERE id_equipe = v_id_equipe;

BEGIN 
    total_kda:=0;
    OPEN v_curseur;
    LOOP 
        FETCH v_curseur INTO v_id_joueur;
        EXIT WHEN NOT FOUND;
        -- raise notice 'Kda du joueur : %',calcul_kda_joueur(v_id_joueur);
        total_kda = total_kda + calcul_kda_joueur(v_id_joueur);
    END LOOP;
    total_kda = total_kda/5;
    CLOSE v_curseur;
    RETURN total_kda;
END;
$$ language plpgsql;
