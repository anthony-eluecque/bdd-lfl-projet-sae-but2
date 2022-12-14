create or replace function getNomJoueur(
    vid_joueur Joueurs.id_joueur%type
) RETURNS VARCHAR AS $$
BEGIN
    RETURN (SELECT nom FROM Joueurs where id_joueur = vid_joueur);
END;
$$ language plpgsql;

create or replace function getPrenomJoueur(
    vid_joueur Joueurs.id_joueur%type
) RETURNS VARCHAR AS $$
BEGIN 
    RETURN (SELECT prenom FROM Joueurs where id_joueur = vid_joueur);
END;
$$ language plpgsql;