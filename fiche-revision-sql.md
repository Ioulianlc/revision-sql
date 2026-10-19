# Fiche de révision SQL / MySQL

> Contrôle : **mardi 27 octobre 2026**. Hors programme : **INTERSECT, EXCEPT, transactions** (syntaxe).
> Version interactive : `revision-sql.html` (cours, flashcards, quiz, exercices).

---

## 1. Théorie express

| Notion | À savoir |
|---|---|
| **SGBDR** | Logiciel qui gère des données en **tables** reliées par des **clés**, interrogées en **SQL** |
| **Relationnel / NoSQL** | Tables + schéma fixe + jointures + ACID / documents, clé-valeur, colonnes, graphes + schéma souple + BASE |
| **ACID** | **A**tomicité (tout ou rien) · **C**ohérence (contraintes toujours respectées) · **I**solation (comme si les transactions s'exécutaient en série) · **D**urabilité (ce qui est validé survit à une panne) |
| **BASE** | **B**asically **A**vailable · **S**oft state · **E**ventually consistent → disponibilité et scalabilité |
| **InnoDB** | Défaut, transactions, ACID, **FK appliquées**, verrouillage par ligne |
| **MyISAM** | Ancien, **pas de FK ni de transactions**, verrouillage par table, rapide en lecture (`subways.sql` est en MyISAM) |
| **SGBDR** | MySQL (web, CMS) · MariaDB (fork de MySQL) · PostgreSQL (JSON, géo, big data) · SQL Server (.NET, propriétaire) · Oracle (grands comptes, cher) |
| **Familles** | DDL (CREATE, ALTER, DROP, TRUNCATE) · DML (SELECT, INSERT, UPDATE, DELETE) · DCL (GRANT, REVOKE) |

## 2. Clés et contraintes

- **PRIMARY KEY** : unique + NOT NULL, une seule par table (peut être composite).
- **FOREIGN KEY** : référence la PK d'une autre table → intégrité référentielle.
- **UNIQUE** (plusieurs par table, NULL accepté) · **NOT NULL** · **DEFAULT** · **CHECK** · **AUTO_INCREMENT**.
- `ON DELETE` : **RESTRICT** (défaut, erreur **1451**) · **CASCADE** (supprime les enfants) · **SET NULL** (FK nullable).
- Erreur **1452** = l'enfant pointe vers un parent qui n'existe pas.

## 3. Merise (MCD → MLD → MPD)

1. Entité → table, identifiant → **PK soulignée**.
2. **1-n** → la FK va **du côté où le max vaut 1** (`#id_parent`). Avec 0,1, la FK est nullable.
3. **n-n** → **table associative**, PK composite (les 2 FK) + attributs de l'association.
4. Lire une cardinalité depuis l'entité : `MEMBER 0,n — MAKE — 1,1 LOAN` = un membre fait 0..n emprunts, un emprunt a 1 seul membre.
5. MLD : `LOAN (id_loan, loan_date, …, #id_member, #id_book)`. Le MPD, c'est le script `CREATE TABLE`.

## 4. Types MySQL

`INT` · `DECIMAL(6,2)` (max 9999.99, pour l'argent) · `VARCHAR(n)` (longueur obligatoire) · `CHAR(n)` (fixe) · `TEXT` · `DATE 'AAAA-MM-JJ'` · `DATETIME` · `TIMESTAMP` (UTC, 1970–2038) · `BOOLEAN` = `TINYINT(1)` · `ENUM('a','b')`

## 5. Syntaxe de référence

```sql
-- Structure (parents d'abord !)
CREATE TABLE loan (
  id INT AUTO_INCREMENT PRIMARY KEY,
  loan_date DATE NOT NULL,
  return_date DATE NULL,
  member_id INT NOT NULL,
  FOREIGN KEY (member_id) REFERENCES member(id) ON DELETE CASCADE,
  CHECK (return_date IS NULL OR return_date >= loan_date)
) ENGINE=InnoDB;
ALTER TABLE member ADD COLUMN email VARCHAR(255) NULL UNIQUE AFTER first_name;
ALTER TABLE member MODIFY email VARCHAR(320);          -- type
ALTER TABLE member RENAME COLUMN email TO mail;        -- nom

-- Données
INSERT INTO author (last_name, first_name) VALUES ('Hugo', 'Victor'), ('Zola', 'Émile');
UPDATE book SET availability = 'disponible' WHERE id = 7;   -- toujours un WHERE
DELETE FROM loan WHERE id = 3;

-- Lecture : ordre d'écriture        -- ordre d'exécution
SELECT t.col, COUNT(x.id) AS nb      -- 5
FROM a t                             -- 1
LEFT JOIN b x ON x.a_id = t.id       -- 1
WHERE condition_lignes               -- 2
GROUP BY t.id, t.col                 -- 3
HAVING COUNT(x.id) > 1               -- 4
ORDER BY nb DESC                     -- 6
LIMIT 10 OFFSET 0;                   -- 7
```

**DELETE / TRUNCATE / DROP** : des lignes (WHERE possible) / toutes les lignes, AUTO_INCREMENT remis à 1 / la table entière.

## 6. Fonctions utiles

- Texte : `CONCAT` (NULL contamine), `CONCAT_WS`, `UPPER`, `LOWER`, `CHAR_LENGTH` (caractères) vs `LENGTH` (octets), `SUBSTRING(s, 1, 3)` (commence à 1).
- Nombres : `ROUND(x, 1)`, `CEIL`, `FLOOR`, `/` (décimal) vs `DIV` (entier).
- Dates : `NOW()`, `CURDATE()`, `YEAR()`, `DATEDIFF(d1, d2)` (= d1 − d2), `DATE_ADD(d, INTERVAL 21 DAY)`, `DATE_FORMAT(d, '%d/%m/%Y')`.
- Conditions : `IFNULL(a, b)`, `COALESCE(a, b, c)`, `CASE WHEN … THEN … ELSE … END`.
- Agrégats : `COUNT(*)` (lignes) / `COUNT(col)` (non NULL) / `COUNT(DISTINCT col)`, `SUM`, `AVG` (ignore NULL), `MIN`, `MAX`, `GROUP_CONCAT(x SEPARATOR ', ')`, `GROUP BY … WITH ROLLUP` (ligne de total).

## 7. Jointures

| | Renvoie |
|---|---|
| `JOIN` | Correspondances des deux côtés |
| `LEFT JOIN` | Toute la gauche + NULL à droite si pas de correspondance |
| `RIGHT JOIN` | L'inverse (réécris-le en LEFT) |
| `CROSS JOIN` | Produit cartésien |
| FULL OUTER | N'existe pas en MySQL → `LEFT … UNION … RIGHT` |

- **Auto-jointure** : la même table deux fois avec deux alias.
- **Anti-jointure** : `LEFT JOIN b … WHERE b.id IS NULL`.

## 8. Sous-requêtes et UNION

- Scalaire : `WHERE x > (SELECT AVG(x) FROM t)`.
- Table dérivée : `FROM (SELECT …) AS t` → **alias obligatoire** (erreur 1248).
- `EXISTS` / `NOT EXISTS` (corrélée) : plus sûr que `NOT IN`.
- `UNION` (sans doublons) / `UNION ALL` (tout). Même nombre de colonnes, noms du 1er SELECT, parenthèses pour un `ORDER BY`/`LIMIT` par partie.
- Ex æquo : `HAVING COUNT(*) = (SELECT MAX(nb) FROM (SELECT COUNT(*) AS nb … GROUP BY …) AS t)`.

## 9. Les 13 pièges

1. `= NULL` → **`IS NULL`**
2. Après un LEFT JOIN : `COUNT(droite.id)`, pas `COUNT(*)`
3. Filtre sur la table de droite d'un LEFT JOIN → dans le `ON`
4. Agrégat dans WHERE → `HAVING`
5. Colonne ni groupée ni agrégée → erreur 1055
6. Alias du SELECT interdit dans WHERE (autorisé dans ORDER BY)
7. AND passe avant OR → parenthèses
8. `NOT IN` + un NULL dans la sous-requête = 0 ligne
9. Table dérivée sans alias → 1248
10. `LIMIT 1` ignore les ex æquo
11. UPDATE / DELETE sans WHERE = toute la table
12. Créer les tables parents avant les enfants
13. Deux tables enfants jointes en même temps → double comptage

## 10. CLI et administration

```bash
mysql -u root -p                                   # terminal
mysqldump -u root -p base > sauvegarde.sql         # terminal (pas dans mysql>)
mysql -u root -p base < sauvegarde.sql             # import depuis le terminal
```
```sql
SOURCE C:/Users/lciou/Desktop/SQL/exo_sql/subways.sql;   -- import depuis mysql>
SHOW DATABASES; USE subways; SHOW TABLES; DESCRIBE stations; SHOW CREATE TABLE stations;
CREATE USER 'app'@'localhost' IDENTIFIED BY '…';
GRANT SELECT, INSERT, UPDATE, DELETE ON base.* TO 'app'@'localhost';
REVOKE DELETE ON base.* FROM 'app'@'localhost';
```
PATH Windows : `C:\Program Files\MySQL\MySQL Server 8.0\bin`. Moindre privilège : jamais root pour une appli.

## 11. Ton TP : à retenir

- **Exo 1** : cardinalités justes, LOAN en entité = bon choix. À corriger : fautes « lablel » et « catallog », `name/surname` → `last_name/first_name`, PK à souligner, `ENUM` pour type et disponibilité.
- **Exo 2** : juste. Souligne la PK composite de action1.
- **Exo 3** : `FOLLOWS` en majuscules (casse sous Linux), pas de `UNIQUE` sur pseudo, ni sur (user_id, artist_id), aucun `ON DELETE`.
- **Exo 4** : 3 requêtes manquantes. Résultats : Bastille → 1, 5, 8 · moyenne 19.55 (24.44 sans les lignes vides) · plus courte 3bis (JOIN) / plus longue 8 · Louis Blanc (7, 7bis) → 43 stations · Nationale (0–1 correspondance) → 268 stations.

```sql
-- Louis Blanc : auto-jointure
SELECT DISTINCT s2.name
FROM stations s1
JOIN stations_in_lines a ON a.station_id = s1.id
JOIN stations_in_lines b ON b.line_id = a.line_id
JOIN stations s2 ON s2.id = b.station_id
WHERE s1.name = 'Louis Blanc' AND s2.id <> s1.id;

-- Nationale : 0 ou 1 correspondance
SELECT DISTINCT dest.name
FROM stations start
JOIN stations_in_lines l1      ON l1.station_id = start.id
JOIN stations_in_lines hop     ON hop.line_id = l1.line_id
JOIN stations_in_lines l2      ON l2.station_id = hop.station_id
JOIN stations_in_lines arrival ON arrival.line_id = l2.line_id
JOIN stations dest             ON dest.id = arrival.station_id
WHERE start.name = 'Nationale' AND dest.id <> start.id;
```

## 12. Ressources fiables

- Doc officielle MySQL 8.4 : [instructions SQL](https://dev.mysql.com/doc/refman/8.4/en/sql-statements.html) · [manipulation (SELECT, JOIN…)](https://dev.mysql.com/doc/refman/8.4/en/sql-data-manipulation-statements.html) · [fonctions d'agrégat](https://dev.mysql.com/doc/refman/8.4/en/aggregate-functions.html) · [GROUP BY WITH ROLLUP](https://dev.mysql.com/doc/refman/8.4/en/group-by-modifiers.html)
- Entraînement interactif : [SQLBolt](https://sqlbolt.com/) (cours + exercices courts) · [SQLZoo](https://sqlzoo.net/) (exercices progressifs, dont SELECT within SELECT)
