-- Fonction qui retourne le nom d'un champion à partir de son id.
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


-- Procédure qui affiche les noms des champions banni à partir d'un id de match.
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


-- Procédure qui affiche les noms des champions choisis à partir d'un id de match.
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


-- Fonction qui donne le nombre de fois ou un champion a été banni avec le nom de ce champion.
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


-- Fonction qui donne le % où un champion a été banni par rapport à la totalité des champions bannis avec l'id du champion.
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


-- Fonction qui permet de déterminer combien de fois un champion a été choisi en donnant le nom du champion en paramètre.
CREATE OR REPLACE FUNCTION nbFoisChampPick(
    vnom_champion champions.nom_champion %type
)
RETURNS integer AS $$
DECLARE
    compteur integer;
    vid_champion champions.id_champion %type;
BEGIN
    SELECT id_champion INTO vid_champion FROM champions WHERE nom_champion LIKE vnom_champion;
    SELECT COUNT(*) INTO compteur FROM Historique_Matchs WHERE id_champion_choisi = vid_champion;
    RETURN compteur;
END;
$$ language plpgsql; 


-- Fonction qui calcule le pourcentage de partie gagné sur le total des parties jouées en donnant le nom du champion en paramètre.
CREATE OR REPLACE FUNCTION calcul_winrate_champion(
    vnom champions.nom_champion%type
)
RETURNS DECIMAL as $$ 
DECLARE
    v_id_champ champions.id_champion%type;
    total_picks INTEGER;
    v_id_joueur Joueurs.id_joueur%type;
    total_matchs_win INTEGER;
    vid_vaiqueur Matchs.vainqueur%type;
BEGIN
    total_matchs_win := 0;
    total_picks := 0;
    IF (vnom IN (SELECT nom_champion FROM champions)) THEN
        SELECT id_champion INTO v_id_champ FROM champions WHERE nom_champion = vnom;
        total_picks := nbFoisChampPick(vnom);
        -- On cherche à savoir le nombre de fois où il a été choisi et a gagné
        FOR vid_vaiqueur IN SELECT vainqueur FROM Matchs
        LOOP
            SELECT COUNT(id_champion_choisi) INTO total_matchs_win FROM Historique_Matchs
            WHERE id_champion_choisi = v_id_champ
            AND id_joueur IN (SELECT j.id_joueur FROM Jouer_dans as j WHERE j.id_equipe = vid_vaiqueur);
        END LOOP;
        -- raise notice '====> % ,  %  , %', total_picks,total_matchs_win;
        IF (total_picks > 0) THEN
            RETURN ROUND(((total_matchs_win::DECIMAL) / total_picks::DECIMAL),2)*100;
        ELSE return 0;
        END IF;
    ELSE
        raise exception 'Le champion passé en paramètre n existe pas';
    END IF;
END;
$$ language plpgsql;
