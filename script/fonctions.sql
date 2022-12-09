
-------------------
-- Niveau Facile
-- Connaître tous les bans d'une game (procédure avec raise notice par exemple)
-- Connaitre tous les personnages choisi d'une game passé par paramètre (fonction)
-- Passer un nom / un prénom en paramètre et que ça nous retourne l'équipe, ... (à voir avec les autres)
-- 



------------------------------

-- Niveau avancé
-- Connaître le % de pick de chaque champion sur la totalité du SPLIT  avec une procédure | table (au choix)
-- Ne pas afficher si celui-ci vaut 0
-- Connaître le % de pick de chaque champion POUR LES ROLES sur la totalité du SPLIT avec une procédure | table (au choix)



-- Trigger à faire : 
-- Une table KDA , qui dès qu'on rentre le score d'un joueur dans une game se met à jour pour toute la saison
--                          Attention : il est impossible de rentrer le score d'un joueur SI la game n'a pas encore eu lieu (faut y penser)
                                        -- =>>>>> Gérer ça avec un raise notice et un if 



-- Partie classement (hard)


-- Dès qu'on rentre un match, il faut que le classement des équipes se fasse PAR SEMAINE ET POUR LE SPLIT ENTIER
-- Explication nécessaire :
                        /*
                            Le classement de la LFL se fait sur 18 games par équipe (au total) , il faut donc pour chaque équipe insérée une ligne par
                            défault (ex : id_equipe, 0 game joué, 0 gagné, 0 perdu)
                            Ou faire avec un IF NOT FOUND THEN (par exemple ça semble mieux pour la note)

                            -- Faut s'occuper du Tri (meilleur équipe en haut, la plus nul en bas)

                            On update la ligne dès un insert dans la table match.


                                            -- aller rechercher le vainqueur et le perdant dans la table match 

                    
                            Il est aussi possible de crée un trigger sur la durée moyenne des games d'une équipe qui se met auto à jour après un insert
                            dans la table match , ainsi que le winrate de l'équipe (entre 0% et 100%)


                        */

CREATE TABLE classement_LFL(
    id_equipe INTEGER PRIMARY KEY,
    nb_win INTEGER NOT NULL,
    nb_lose INTEGER NOT NULL
);

CREATE TABLE statistique_LFL(
    id_equipe INTEGER PRIMARY KEY,
    winrate FLOAT ,
    kda_equipe FLOAT,
    moyenne_duree_game TIME
);


CREATE TRIGGER classement_equipe
AFTER INSERT ON Matchs -- Utilisation du mot insert
FOR EACH ROW 
EXECUTE PROCEDURE gestion_classement();

CREATE OR REPLACE FUNCTION gestion_classement() RETURNS TRIGGER AS $$
DECLARE
    v_id_equipe_gagnante classement_LFL.id_equipe%type;
    v_id_equipe_perdante classement_LFL.id_equipe%type;

    nb_win_existantes classement_LFL.nb_lose%type;
    nb_loses_existantes classement_LFL.nb_win%type;

BEGIN

    nb_win_existantes :=0;
    nb_loses_existantes:=0;

    SELECT id_equipe INTO v_id_equipe_gagnante FROM classement_LFL WHERE id_equipe = new.vainqueur;
    SELECT id_equipe INTO v_id_equipe_perdante FROM classement_LFL WHERE id_equipe = new.perdant;

    IF (v_id_equipe_gagnante IS NULL) THEN 
        INSERT INTO classement_LFL values(new.vainqueur,1,0); -- Si il n'existe pas encore alors il a que  le match qu'il vient de jouer
    ELSE  -- On s'occupe de modifier l'existant sinon  
        -- On récupère les données existantes et on update le classement
        SELECT nb_win INTO nb_win_existantes FROM classement_LFL WHERE id_equipe = v_id_equipe_gagnante;
        nb_win_existantes = nb_win_existantes + 1;
        UPDATE classement_LFL SET nb_win = nb_win_existantes WHERE id_equipe = v_id_equipe_gagnante;
    END IF;


    IF (v_id_equipe_perdante IS NULL) THEN 
        INSERT INTO classement_LFL values(new.perdant,0,1); -- Si il n'existe pas encore alors il a que  le match qu'il vient de jouer
    ELSE  -- On s'occupe de modifier l'existant sinon  
        -- On récupère les données existantes et on update le classement
        SELECT nb_lose INTO nb_loses_existantes FROM classement_LFL WHERE id_equipe = v_id_equipe_perdante;
        nb_loses_existantes = nb_loses_existantes + 1;
        UPDATE classement_LFL SET nb_lose = nb_loses_existantes WHERE id_equipe = v_id_equipe_perdante;
    END IF;



    RETURN NEW;
END;
$$ language plpgsql;


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



CREATE OR REPLACE FUNCTION calcul_duree_moyenne_matchs_equipe(v_id_equipe Equipes.id_equipe%type)
RETURNS TIME AS $$
BEGIN
    RETURN AVG(duree_match) FROM Matchs WHERE id_equipe_1 = v_id_equipe OR id_equipe_2 = v_id_equipe;
END;
$$ language plpgsql;


-- Calcul d'un Winrate à partir d'un ID d'équipe
CREATE OR REPLACE FUNCTION calcul_winrate_equipe(v_id_equipe Equipes.id_equipe%type)
RETURNS DECIMAL as $$ 
DECLARE

    total_wins INTEGER;
    total_matchs INTEGER;

BEGIN
    SELECT COUNT(vainqueur) INTO total_wins FROM Matchs WHERE vainqueur = v_id_equipe;
    SELECT COUNT(id_match) INTO total_matchs FROM Matchs WHERE id_equipe_1 = v_id_equipe OR id_equipe_2 = v_id_equipe;
    RETURN ROUND(((total_wins::DECIMAL) / total_matchs::DECIMAL),2)*100;
END;
$$ language plpgsql;


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



-- Calcul KDA d'un Joueur par son ID
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








-- Check In que les inserts sont correct, sinon soucis au niveau des logs
CREATE TRIGGER verification_matchs
BEFORE INSERT ON Matchs -- Utilisation du mot before
FOR EACH ROW 
EXECUTE PROCEDURE verif_insert_matchs();

CREATE OR REPLACE FUNCTION verif_insert_matchs() RETURNS TRIGGER AS $$
BEGIN
    IF ((new.id_equipe_1 = new.vainqueur OR new.id_equipe_1 = new.perdant)
    AND  (new.id_equipe_2 = new.vainqueur OR new.id_equipe_2 = new.perdant))
    THEN
        RETURN NEW;
    ELSE
        RAISE NOTICE 'Votre valeur doit être cohérente , une équipe qui ne joue pas ne peut pas gagner ou perdre';
    END IF;
END;
$$ language plpgsql;








