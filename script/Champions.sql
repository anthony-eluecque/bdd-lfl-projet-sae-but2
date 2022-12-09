-- Crée une fonction qui retourne le nom d'un champion à partir de son id

CREATE or REPLACE function getNomChampion(
    vid_champion champions.id_champion%type
)
RETURNS VARCHAR AS $$
DECLARE
    vchamp champions.nom_champion %type;
BEGIN
    SELECT nom_champion INTO vchamp FROM champions 
                WHERE id_champion = vid_champion;
    RETURN vchamp;
END;
$$ language plpgsql;


-- Crée une procédure qui affiche les noms des champions banni à partir d'un id de match
-- Condition : utiliser la fonction d'au dessus

CREATE or REPLACE function AfficherChampionsBanMatch(
    vid_match matchs.id_match %type
)
RETURNS void AS $$
DECLARE
    vid_champion champions.id_champion %type;
    vnom_champion champions.nom_champion %type;
    curseur_banni cursor for SELECT id_champion_banni FROM historique_matchs WHERE id_match = vid_match;
BEGIN
    OPEN curseur_banni;
    LOOP
        FETCH curseur_banni INTO vid_champion;
        EXIT WHEN NOT FOUND;
        vnom_champion = getNomChampion(vid_champion);
        RAISE NOTICE 'Le champion % a été banni de la game', vnom_champion;
    END LOOP;
END;
$$ language plpgsql;


-- Crée une procédure qui affiche les noms des champions choisis à partir d'un id de match
-- Condition : utiliser la fonction d'au dessus

CREATE OR REPLACE FUNCTION AfficherChampionsChoisisMatch(
    vid_match matchs.id_match %type
)
RETURNS VOID AS $$
DECLARE
    vid_champion champions.id_champion %type;
    vnom_champion champions.nom_champion %type;
    moncurseur cursor FOR SELECT id_champion_choisi FROM Historique_Matchs WHERE id_match = vid_match;
BEGIN
    open moncurseur;
    LOOP
        FETCH moncurseur INTO vid_champion;
        EXIT WHEN NOT FOUND;
        vnom_champion := getNomChampion(vid_champion);
        raise notice 'Le champion % a ete choisi.', vnom_champion;
    END LOOP;
    close moncurseur;
END;
$$ language plpgsql;


-- Crée une fonction qui donne le nombre de fois ou un champion a été banni

CREATE OR REPLACE FUNCTION nbFoisChampBan(
    vnom_champion champions.nom_champion %type
)
RETURNS integer AS $$
DECLARE
    compteur integer;
    vid_champion champions.id_champion %type;
BEGIN
    SELECT id_champion INTO vid_champion FROM champions WHERE nom_champion LIKE vnom_champion;
    SELECT COUNT(*) INTO compteur FROM Historique_Matchs WHERE id_champion_banni = vid_champion;
    RETURN compteur;
END;
$$ language plpgsql; 


-- Crée une fonction qui donne le % ou il a été banni par rapport à la totalité des champions bannis
-- Pour cela, il faut passer par paramètre l'id d'un champion
-- Conditon : utiliser la fonction d'au dessus 
 
CREATE OR REPLACE FUNCTION rateBanChamp(
    vid_champion champions.id_champion %type
)
RETURNS real AS $$
DECLARE
    vtotal_banni integer;
    vnb_ban_champ integer;
    pourcentage real;
BEGIN
    SELECT COUNT(id_champion_banni) INTO vtotal_banni FROM historique_matchs;
    vnb_ban_champ := nbFoisChampBan(vid_champion);
    pourcentage := vnb_ban_champ / vtotal_banni * 100;
    RETURN pourcentage;
END;
$$ language plpgsql;







