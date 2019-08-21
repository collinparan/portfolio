--CREATE EXTENSION hstore;
CREATE VIEW vw_denver_university_hood AS
SELECT
	(h).KEY AS year_month,
	(h).value::NUMERIC AS med_val_per_sqft
FROM
	(
	SELECT
		"RegionID",
		EACH(hstore(t) - 'RegionID'::TEXT - 'RegionName'::TEXT - 'City'::TEXT - 'State'::TEXT - 'Metro'::TEXT - 'CountyName'::TEXT - 'SizeRank'::TEXT) AS h
	FROM
		public.zillow AS t
	WHERE
		"State" = 'CO'
		AND "City" = 'Denver'
		AND "RegionName" = 'University') AS unpivot;
