CREATE OR REPLACE FUNCTION append_rank(string VARCHAR(30), place INTEGER)
	returns VARCHAR(30)
	LANGUAGE plpgsql
AS
$$
BEGIN
IF place = 1 THEN
	RETURN (SELECT CONCAT(string, ' is Most Rented'));
ELSE
	RETURN (SELECT CONCAT(CONCAT(string, ' Has Rank Number '), CAST(place as varchar)));
END IF;
END;
$$

