
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

