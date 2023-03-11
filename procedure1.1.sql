CREATE OR REPLACE PROCEDURE create_language_report()
LANGUAGE plpgsql
AS $$
BEGIN

DROP TABLE IF EXISTS language_summary_table;
DROP VIEW IF EXISTS rental_to_place;
DROP VIEW IF EXISTS detailed_table_alpha;
DROP VIEW IF EXISTS count_all_languages;
DROP VIEW IF EXISTS count_each_language;
DROP VIEW IF EXISTS rental_language_pair;
DROP VIEW IF EXISTS rental_film_pair;

CREATE VIEW rental_film_pair AS
SELECT rental.rental_id, inventory.film_id
FROM rental
INNER JOIN inventory 
ON rental.inventory_id = inventory.inventory_id;

CREATE VIEW rental_language_pair AS
SELECT rental_film_pair.rental_id, film.language_id
FROM rental_film_pair
INNER JOIN film
ON rental_film_pair.film_id = film.film_id;

CREATE VIEW count_each_language AS
SELECT rental_language_pair.language_id, COUNT(rental_language_pair.language_id)
FROM rental_language_pair
GROUP BY rental_language_pair.language_id; 

CREATE VIEW count_all_languages AS
SELECT language.language_id, coalesce(count_each_language.count, 0) as count
FROM count_each_language
RIGHT JOIN language
ON count_each_language.language_id = language.language_id;

DROP TABLE IF EXISTS detailed_language_table;
CREATE TABLE detailed_language_table ( 
	language_id INTEGER,
	language_name VARCHAR(30),
	total_rentals INTEGER,
	percentage_of_rentals INTEGER,
	place_number INTEGER
);

INSERT INTO detailed_language_table
SELECT count_all_languages.language_id, language.name, count_all_languages.count
FROM count_all_languages
INNER JOIN language
ON count_all_languages.language_id = language.language_id;

UPDATE detailed_language_table
SET percentage_of_rentals = total_rentals/(SELECT SUM(total_rentals) FROM detailed_language_table)*100;

CREATE VIEW rental_to_place AS
SELECT RANK() OVER (ORDER BY COUNT(total_rentals)), COUNT(total_rentals), total_rentals
FROM detailed_language_table
GROUP BY total_rentals
ORDER BY COUNT(total_rentals) DESC;

UPDATE detailed_language_table
SET place_number = (SELECT rank FROM rental_to_place where detailed_language_table.total_rentals = rental_to_place.total_rentals);

UPDATE detailed_language_table
SET language_name = append_rank(language_name, place_number);

DROP TABLE IF EXISTS language_summary_table;
CREATE TABLE language_summary_table (
	language_group varchar(30),
	percentage_of_rentals INTEGER
);

INSERT INTO language_summary_table
SELECT language_name, percentage_of_rentals 
FROM detailed_language_table
WHERE place_number  = 1;

INSERT INTO language_summary_table 
Values ( 'All other languages', (SELECT SUM(percentage_of_rentals) FROM detailed_language_table WHERE place_number != 1));
RETURN;
END;
$$;
