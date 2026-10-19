-- =====================================================================
-- Base d'entraînement : bibliothèque municipale (d'après ton MCD de l'exo 1)
-- Import (terminal)   : mysql -u root -p < bibliotheque.sql
-- Import (dans le CLI): SOURCE C:/Users/lciou/Desktop/SQL/revision/bibliotheque.sql;
-- =====================================================================
-- Différences volontaires avec ton rendu :
--  * name/surname -> last_name/first_name : en anglais "surname" = nom de famille,
--    ton MLD inversait donc nom et prénom.
--  * type et availability en ENUM : la liste de valeurs est fermée dans l'énoncé.
--  * Les clés étrangères sont nommées <table>_id (convention la plus répandue).
-- =====================================================================

DROP DATABASE IF EXISTS bibliotheque;
CREATE DATABASE bibliotheque CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;
USE bibliotheque;

-- Ordre de création : d'abord les tables référencées, ensuite celles qui portent les FK
CREATE TABLE subscription (
  id INT AUTO_INCREMENT PRIMARY KEY,
  label VARCHAR(50) NOT NULL UNIQUE,
  annual_rate DECIMAL(6,2) NOT NULL DEFAULT 0,
  max_concurrent_loans TINYINT UNSIGNED NOT NULL,
  CHECK (annual_rate >= 0)
) ENGINE=InnoDB;

CREATE TABLE member (
  id INT AUTO_INCREMENT PRIMARY KEY,
  last_name VARCHAR(100) NOT NULL,
  first_name VARCHAR(100) NOT NULL,
  registration_date DATE NOT NULL DEFAULT (CURRENT_DATE),
  subscription_id INT NOT NULL,
  FOREIGN KEY (subscription_id) REFERENCES subscription(id)
) ENGINE=InnoDB;

CREATE TABLE author (
  id INT AUTO_INCREMENT PRIMARY KEY,
  last_name VARCHAR(100) NOT NULL,
  first_name VARCHAR(100) NOT NULL
) ENGINE=InnoDB;

CREATE TABLE book (
  id INT AUTO_INCREMENT PRIMARY KEY,
  title VARCHAR(255) NOT NULL,
  type ENUM('roman', 'bd', 'manga', 'non-fiction') NOT NULL,
  summary TEXT NULL,
  publication_date DATE NULL,
  catalog_entry_date DATE NOT NULL,
  dewey_code VARCHAR(20) NULL,
  availability ENUM('disponible', 'emprunte', 'reserve', 'indisponible') NOT NULL DEFAULT 'disponible',
  author_id INT NOT NULL,
  FOREIGN KEY (author_id) REFERENCES author(id) ON DELETE RESTRICT
) ENGINE=InnoDB;

CREATE TABLE loan (
  id INT AUTO_INCREMENT PRIMARY KEY,
  loan_date DATE NOT NULL,
  due_date DATE NOT NULL,
  return_date DATE NULL,              -- NULL = livre pas encore rendu
  member_id INT NOT NULL,
  book_id INT NOT NULL,
  FOREIGN KEY (member_id) REFERENCES member(id) ON DELETE CASCADE,
  FOREIGN KEY (book_id) REFERENCES book(id),
  CHECK (due_date >= loan_date)
) ENGINE=InnoDB;

INSERT INTO subscription (id, label, annual_rate, max_concurrent_loans) VALUES
  (1, 'Découverte', 0.00, 2),
  (2, 'Standard', 25.00, 5),
  (3, 'Premium', 45.00, 10);

INSERT INTO member (id, last_name, first_name, registration_date, subscription_id) VALUES
  (1, 'Martin', 'Léa', '2024-01-15', 2),
  (2, 'Durand', 'Hugo', '2024-03-02', 1),
  (3, 'Bernard', 'Inès', '2025-06-20', 3),
  (4, 'Petit', 'Noah', '2025-09-01', 2),
  (5, 'Moreau', 'Jade', '2026-02-11', 1),
  (6, 'Lefèvre', 'Sami', '2026-09-30', 2);

INSERT INTO author (id, last_name, first_name) VALUES
  (1, 'Hugo', 'Victor'),
  (2, 'Toriyama', 'Akira'),
  (3, 'Goscinny', 'René'),
  (4, 'Harari', 'Yuval Noah'),
  (5, 'Rowling', 'Joanne'),
  (6, 'Zola', 'Émile');

INSERT INTO book (id, title, type, summary, publication_date, catalog_entry_date, dewey_code, availability, author_id) VALUES
  (1, 'Les Misérables', 'roman', 'Jean Valjean, ancien bagnard, cherche la rédemption.', '1862-04-03', '2019-05-10', '843', 'emprunte', 1),
  (2, 'Notre-Dame de Paris', 'roman', 'Quasimodo, Esmeralda et la cathédrale.', '1831-03-16', '2019-05-10', '843', 'disponible', 1),
  (3, 'Dragon Ball - Tome 1', 'manga', 'Son Goku rencontre Bulma.', '1985-09-10', '2021-02-01', '741.5', 'emprunte', 2),
  (4, 'Astérix le Gaulois', 'bd', 'Le premier album d''Astérix.', '1961-10-29', '2020-11-12', '741.5', 'disponible', 3),
  (5, 'Sapiens', 'non-fiction', 'Une brève histoire de l''humanité.', '2011-01-01', '2022-03-15', '909', 'reserve', 4),
  (6, 'Dr Slump - Tome 1', 'manga', NULL, '1980-08-08', '2021-02-01', '741.5', 'indisponible', 2),
  (7, 'Germinal', 'roman', 'La grève des mineurs du Nord.', '1885-03-01', '2023-09-01', '843', 'emprunte', 6),
  (8, 'L''Assommoir', 'roman', NULL, '1877-01-01', '2023-09-01', '843', 'disponible', 6);

INSERT INTO loan (id, loan_date, due_date, return_date, member_id, book_id) VALUES
  (1, '2026-09-01', '2026-09-22', '2026-09-20', 1, 2),
  (2, '2026-09-05', '2026-09-26', NULL, 1, 1),
  (3, '2026-09-10', '2026-10-01', '2026-09-30', 2, 4),
  (4, '2026-10-01', '2026-10-22', NULL, 3, 3),
  (5, '2026-10-03', '2026-10-24', '2026-10-10', 3, 5),
  (6, '2026-08-15', '2026-09-05', '2026-09-15', 4, 2),
  (7, '2026-10-05', '2026-10-26', NULL, 4, 7),
  (8, '2026-07-01', '2026-07-22', '2026-07-20', 2, 1),
  (9, '2026-09-20', '2026-10-11', '2026-10-02', 3, 8),
  (10, '2026-06-10', '2026-07-01', '2026-07-03', 1, 4);

-- Vérification rapide
SELECT 'subscription' AS t, COUNT(*) FROM subscription
UNION ALL SELECT 'member', COUNT(*) FROM member
UNION ALL SELECT 'author', COUNT(*) FROM author
UNION ALL SELECT 'book', COUNT(*) FROM book
UNION ALL SELECT 'loan', COUNT(*) FROM loan;
