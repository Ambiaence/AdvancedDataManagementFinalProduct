DROP TRIGGER IF EXISTS trigger_on_completion_of_detailed_table on detailed_language_table;
DROP FUNCTION IF EXISTS create_summary_table;

CREATE FUNCTION create_summary_table()
	RETURNS TRIGGER
	LANGUAGE PLPGSQL
AS
$$
BEGIN
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
RETURN NEW;
END;
$$;

CREATE TRIGGER trigger_on_completion_of_detailed_table 
	AFTER INSERT 
	ON detailed_language_table
	FOR EACH STATEMENT
		EXECUTE PROCEDURE create_summary_table();


