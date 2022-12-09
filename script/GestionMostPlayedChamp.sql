CREATE TABLE PlayedChamp(
    id_joueur INTEGER PRIMARY KEY,
    id_champ1 INTEGER NOT NULL,
    id_champ2 INTEGER NOT NULL,
    id_champ3 INTEGER NOT NULL
);

CREATE OR REPLACE FUNCTION MostPlayedChampByPlayer()
RETURNS TRIGGER AS $$
DECLARE

    vid_champ Champions.id_champion%type;

    nb_fois_joue INTEGER;
    nb_fois_champ_new_joue INTEGER;

    vid_champ_joue Champions.id_champion%type;
    v_temp Champions.id_champion%type;
    v_temp_2 Champions.id_champion%type;

BEGIN
    nb_fois_champ_new_joue:=0;
    nb_fois_joue:=0;
    IF (new.id_joueur IN (SELECT id_joueur FROM PlayedChamp)) THEN

        FOR nb_fois_champ_new_joue,vid_champ_joue IN SELECT COUNT(id_champion_choisi),id_champion_choisi FROM Historique_Matchs 
                                GROUP BY id_champion_choisi,id_joueur
                                HAVING id_joueur = new.id_joueur
                                ORDER BY COUNT(id_champion_choisi) DESC LIMIT 3
        LOOP 

            IF (vid_champ_joue NOT IN (SELECT id_champ1 FROM PlayedChamp WHERE id_joueur = new.id_joueur)) THEN
                IF (vid_champ_joue NOT IN (SELECT id_champ2 FROM PlayedChamp WHERE id_joueur = new.id_joueur)) THEN
                    IF (vid_champ_joue NOT IN (SELECT id_champ3 FROM PlayedChamp WHERE id_joueur = new.id_joueur)) THEN
                        RAISE NOTICE 'id_champion : % , count : %',vid_champ_joue,nb_fois_champ_new_joue ;
                        -- On récup le 3ème perso le + joué
                        SELECT id_champ3 INTO vid_champ FROM PlayedChamp WHERE id_joueur = new.id_joueur;
                        SELECT COUNT(*) INTO nb_fois_joue FROM Historique_Matchs WHERE id_joueur = new.id_joueur AND id_champion_choisi = vid_champ;

                        -- Si le nouveau champ est + joué par ce joueur que son 3ème champion habituel alors on update
                        raise notice 'Id3 : % , count : % , count_loop : %',vid_champ,nb_fois_joue,nb_fois_champ_new_joue;
                        IF (nb_fois_champ_new_joue > nb_fois_joue) THEN 
                            raise notice 'Cas id3';
                            UPDATE PlayedChamp SET id_champ3 = vid_champ_joue WHERE id_joueur = new.id_joueur;
                        -- Si le nouveau champ est + joué par ce joueur que son 2ème champion habituel alors on update
                        -- Pour ça, on a besoin de passé par une variable temporaire pour décallé de 1 les id.
                        END IF;

                        SELECT id_champ2 INTO vid_champ FROM PlayedChamp WHERE id_joueur = new.id_joueur;
                        SELECT COUNT(*) INTO nb_fois_joue FROM Historique_Matchs WHERE id_joueur = new.id_joueur AND id_champion_choisi = vid_champ;
                        raise notice 'Id2 : % , count : % , count_loop : %',vid_champ,nb_fois_joue,nb_fois_champ_new_joue;
                        IF (nb_fois_champ_new_joue > nb_fois_joue) THEN 
                            raise notice 'Cas id2';
                            SELECT id_champ2 INTO v_temp FROM PlayedChamp WHERE id_joueur = new.id_joueur;
                            
                            UPDATE PlayedChamp SET id_champ2 = vid_champ_joue WHERE id_joueur = new.id_joueur;
                            UPDATE PlayedChamp SET id_champ3 = v_temp WHERE id_joueur = new.id_joueur;
                        END IF;
                        -- Si le nouveau champ est + joué par ce joueur que son principale champion habituel alors on update
                        -- Pour ça, on a besoin de passé par 2 variables temporaires pour décallé de 1 tous les id.
                        SELECT id_champ1 INTO vid_champ FROM PlayedChamp WHERE id_joueur = new.id_joueur;
                        SELECT COUNT(*) INTO nb_fois_joue FROM Historique_Matchs WHERE id_joueur = new.id_joueur AND id_champion_choisi = vid_champ;
                        raise notice 'Id1 : % , count : % , count_loop : %',vid_champ,nb_fois_joue,nb_fois_champ_new_joue;
                        IF (nb_fois_champ_new_joue > nb_fois_joue) THEN 
                            raise notice 'Cas id1';
                            SELECT id_champ1 INTO v_temp_2 FROM PlayedChamp WHERE id_joueur = new.id_joueur;
                            UPDATE PlayedChamp SET id_champ1 = vid_champ_joue WHERE id_joueur = new.id_joueur;
                            SELECT id_champ2 INTO v_temp FROM PlayedChamp WHERE id_joueur = new.id_joueur;
                            UPDATE PlayedChamp SET id_champ2 = v_temp_2 WHERE id_joueur = new.id_joueur;
                            UPDATE PlayedChamp SET id_champ3 = v_temp WHERE id_joueur = new.id_joueur;
                        END IF;
                    END IF;
                END IF;
            END IF;
        END LOOP;
    ELSE
        INSERT INTO PlayedChamp VALUES(new.id_joueur,new.id_champion_choisi,0,0);
    END IF;
    return new;
END;
$$ language plpgsql;




SELECT id_champion_choisi,COUNT(id_champion_choisi) FROM Historique_Matchs 
            GROUP BY id_champion_choisi,id_joueur 
            HAVING id_joueur = 1 
            ORDER BY COUNT(id_champion_choisi) DESC LIMIT 3;




CREATE TRIGGER trigger_gestion_champ_joueur
AFTER INSERT ON Historique_Matchs
FOR EACH ROW
EXECUTE PROCEDURE MostPlayedChampByPlayer();