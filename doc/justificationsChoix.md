# **Base de donnée LFL 🗄**

> Auteur : Eluecque Anthony, Fournier Benjamin, Dournel Frédéric

# **Sommaire 📃**

- 1 Introduction
    - 1.1 Le thème choisi
        - 1.1.1 Pourquoi Ce Sujet ?
        - 1.1.2 Documentation à propos de ce sujet
    - 1.2 L'approche Utilisé
    - 1.3 Travail En Groupe 
- 2 La Base De Données
    - 2.1 Structure Du projet
        - 2.1.1 Le MCD
        - 2.1.2 Le MLD
    - 2.2 La Mise En Pratique
        - 2.2.1 Création Des tables
        - 2.2.2 Ajout & Organisation Des Tuples
        - 2.2.3 La Méthodologie
    - 2.3 La Création Des Fonctions
        - 2.3.1 Les Fonctions Utilitaires Pour L'Utilisation De La BDD
        - 2.3.2 La Gestion automatique du classement
- 3 Le Site Web Associé A La BDD
    - 3.1 Les Outils
        - 3.1.1 Vue JS | Frontend
        - 3.1.2 Node JS | Backend
    - 3.2 Justification
    - 3.3 Le Lien Entre La Base De Données Et Le Site
- 4 Conclusion 
    - 4.1 Les Limites Du Projet
    - 4.2 Conclusion
- 5 Mode D'Emploi
    - 5.1 Comment Consulter La BDD
    - 5.2 Modification De La BDD
        - 5.2.1 Ajouter Un Joueur
        - 5.2.2 Supprimer Un joueur
        - 5.2.3 Ajouter Un Match

## **1 Introduction 📌**

### 1.1 Le thème choisi

> #### 1.1.1 Pourquoi Ce Sujet ?

Nous avons choisi comme sujet le championnat de la ligue Française de League Of Legends (LFL), il s'agit d'un sujet qui parlait à tout le groupe. Nous naviguons sur des sites où le championnat y est affiché et nous avons voulu créer notre propre site pour ce championnat.Pour ce sujet, nous avons récupéré des informations, statistiques du championnat sur des sites internet comportant les matchs et le championnat. Nous avons donc pris les informations concernant les coachs, les joueurs pour chaque équipe, les 90 matchs qui se sont deroulés durant le Summer Split 2022. Puis nous avons utilisé notre connaissance sur le jeu pour pouvoir apporter, completer les informations trouvées sur les différents sites internet

> #### 1.1.2 Documentation à propos de ce sujet 

Pour comprendre comment se déroule le championnat de la LFL nous avons rédigé une documentation "explicationLFL" pour avoir plus de connaissances concernant le championnat que nous avons choisi. Ce document donne des informations sur le nom des équipes, des joueurs et des coachs mais aussi des explications sur le déroulement du championnat pour élire l'équipe championne de France. Nous avons aussi rédigé une documentation "explicationLoL" qui explique le déroulement d'un match de League Of Legends. Ce document donne des explications sur les champions et leurs spécifités, les rôles jouables, la génération d'or et d'expérience. Ces 2 documents sont complémentaires mais permettent de comprendre plus en détail notre sujet.

### 1.2 L'approche Utilisé

Pour réalisé ce projet nous avons utilisé plusieurs outils qui nous ont permis de travailler en groupe comme Le Live Share de Visual Studio Code, il s'agit d'une extension qui permet de travailler en même temps sur un même fichier à la manière d'un Google Doc. Nous avons aussi utilisé Discord pour pouvoir discuter des idées en dehors des horaires de Tps et pour pouvoir échanger des fichiers. Pour pouvoir échanger des fichiers nous avons utilisé aussi GitHub.

### 1.3 Travail En Groupe

Nous avons travaillé à 3, nous avons donc organisé les travaux pour que chaque membre du groupe ait un travail a effectué 

## **2 La Base De Données 📦**

### 2.1 Structure Du projet

> #### 2.1.1 Le MCD

Afin de mieux visualiser la structure de la base de donnée. Nous avons modélisé un **Modèle Conceptuel de données**. pour cela nous avons utiliser le logiciel *Looping* prévu pour cela. 

<img>

```
𝙇é𝙜𝙚𝙣𝙙𝙚 :

𝙟𝙖𝙪𝙣𝙚 : Tables de la base de donnée
𝙗𝙡𝙚𝙪 : associations entre les tables
𝙡𝙞𝙚𝙣 : définit le type d'association entre les tables
```

Voici le MCD qui nous à permit de conceptualiser la basde de donnée et également de bien consruire les liens entre les tables de la base de données pour être sur d'avoir une structure optimale pour enseuite faire les requêtes sur celle-ci..

<sub>Looping : https://www.looping-mcd.fr/</sub>

> #### 2.1.2 Le MLD

Grâce au logiciel *Looping*, nous avons pu avoir le **Modèle logique de donnée** déjà fait qui correspond au MCD. Grâce à cet outil, nous pouvons voir le contenu de la table avec la mise en évidence des clés primaire avec une polices en **gras** et les clés étrangères qui sont soulignées.

### 2.2 La Mise En Pratique

> #### 2.2.1 Création Des tables

Pour créer les tables, nous avions tout d'abord définit les données dont nous aurions besoin afin de faire un classement sur la LFL Spring 2022 (les Equipes, les Joueurs, les Champions, les Coachs, Les historiques des matchs, La nationalité, Les rôles).

> #### 2.2.2 Ajout & Organisation Des Tuples

Nous avons donc comme expliqué auparavant récupéré des informations sur les matchs qui se sont déjà déroulés et remplis la base de données avec ces données. Nous avons donc choisi de rentrer le nom, prenom, nationalité, date de naissance pour chaque joueur et chaque coach, le nombre de match et les statistiques de chaque joueur pour tous les matchs qu'ils ont joué, nous avons aussi rentré chaque champion du jeu avec leur rôle principal. 


> #### 2.2.3 La Méthodologie

Nous avons donc remplis la base de données avec tuples écrit à la main mais toujours en suivant une méthode très strict qui nous a permis de ne pas se perdre dans toutes ces données mais surtout pour ne pas faire d'erreur dans l'entrée de ces informations. Cette stratégie nous a permis de rentrer les tuples sans perdre de temps inutile

### 2.3 La Création Des Fonctions

Nous avons donc pour optimiser cette base de données et la rendre automatique, créer plusieurs fonctions. 

> #### 2.3.1 Les Fonctions Utilitaires Pour L'Utilisation De La BDD

`- getNomChampion(id_champion integer) ▶️ varchar`   
Permet de trouver le nom d'un champion à partie de son id 

`- AfficherChampionsBanMatch(id_match integer) ▶️ void`  
Permet d'afficher les 10 champions banni d'un match avec l'id du match

`- AfficherChampionsChoisiMatch(id_match integer) ▶️ void`  
Permet d'afficher les 10 champions choisi d'un match avec l'id du match

`- nbFoisChampBan(nom_champion varchar) ▶️ integer`  
Permet de trouver le nombre de fois qu'un champion a été banni à partir du nom de ce champion

`- rateBanChamp(id_champion integer) ▶️ real`
Permet d'obtenir le pourcentage que le champion a été banni sur tous les matchs déjà joués à partir de l'id de ce champion

`- nbFoisChampPick(nom_champion varchar) ▶️ integer`  
Permet de trouver le nombre de fois qu'un champion a été choisi à partir du nom de ce champion 

`- calcul_winrate_champion(nom_champion varchar) ▶️ decimal`  
Permet d'obtenir le taux de match gagné par champion à partir du nom de ce champion

`- calcul_winrate_equipe(id_equipe integer) ▶️ decimal`  
Permet d'obtenir le taux de match gagné par équipe à partir de l'id de cette équipe

`- calcul_kda_equipe(id_equipe integer) ▶️ decimal`  
Permet d'obtenir le kda par équipe à partir de l'id de cette équipe

`- calcul_kda_joueur(id_joueur integer) ▶️ decimal`  
Permet d'obtenir le kda par joueur à partir de l'id de ce joueur
 
> #### 2.3.2 La Gestion automatique du classement

## **3 Le Site Web Associé a La BDD 🌐**

### 3.1 Les Outils

> #### 3.1.1 Vue JS | Frontend

> #### 3.1.2 Node JS | Backend

### 3.2 Justification

### 3.3 Le Lien Entre La Base De Données Et Le Site

## **4 Conclusion 📌**

### 4.1 Les Limites Du Projet

### 4.2 Conclusion

## **5 Mode D'Emploi 📜**

### 5.1 Comment Consulter La BDD

### 5.2 Modification De La BDD

> #### 5.2.1 Ajouter Un Joueur

> #### 5.2.2 Supprimer Un joueur

> #### 5.2.3 Ajouter Un Match