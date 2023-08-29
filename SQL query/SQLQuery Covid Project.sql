--Selecting the covid_death table
Select *
from covid_death
order by 3,4

--Selecting the covid_vaccination table
Select *
from covid_vaccination
order by 3,4

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--Selecting all the locations and the total cases,death,vaccination in that particular location

WITH DeathData AS (
    SELECT
        location,
        population,
        SUM(new_cases) AS total_cases,
        (SUM(new_cases) / population) * 100 AS case_percentage,
        SUM(new_deaths) AS total_deaths,
        CASE WHEN SUM(new_cases) = 0 THEN NULL ELSE (SUM(new_deaths) / SUM(new_cases)) * 100 END AS death_percentage
    FROM
        covid_death
    WHERE
        continent IS NOT NULL
    GROUP BY
        location, population
),
VaccinationData AS (
    SELECT
        location,
        CASE WHEN MAX(people_fully_vaccinated) = 0 THEN NULL ELSE MAX(CONVERT(BIGINT, people_fully_vaccinated)) END AS vaccinated_people
    FROM
        covid_vaccination
    GROUP BY
        location
)
SELECT
    d.location,
    d.population,
    d.total_cases,
    d.case_percentage,
    d.total_deaths,
    d.death_percentage,
    v.vaccinated_people,
	CASE WHEN d.total_cases = 0 THEN NULL ELSE (v.vaccinated_people / d.population) * 100 END AS vaccinated_people_percentage
FROM
    DeathData d
JOIN
    VaccinationData v ON d.location = v.location
ORDER BY
    d.location;



-- Creating View for the same
CREATE VIEW CovidAgr AS
WITH DeathData AS (
    SELECT
        location,
        population,
        SUM(new_cases) AS total_cases,
        (SUM(new_cases) / population) * 100 AS case_percentage,
        SUM(new_deaths) AS total_deaths,
        CASE WHEN SUM(new_cases) = 0 THEN NULL ELSE (SUM(new_deaths) / SUM(new_cases)) * 100 END AS death_percentage
    FROM
        covid_death
    WHERE
        continent IS NOT NULL
    GROUP BY
        location, population
),
VaccinationData AS (
    SELECT
        location,
        CASE WHEN MAX(people_fully_vaccinated) = 0 THEN NULL ELSE MAX(CONVERT(BIGINT, people_fully_vaccinated)) END AS vaccinated_people
    FROM
        covid_vaccination
    GROUP BY
        location
)
SELECT
    d.location,
    d.population,
    d.total_cases,
    d.case_percentage,
    d.total_deaths,
    d.death_percentage,
    v.vaccinated_people
FROM
    DeathData d
JOIN
    VaccinationData v ON d.location = v.location;

--------------------------------------------------------------------------------
--Converting colums to rows
Create view Population_Data as (
SELECT 'World_population' AS Metric, SUM(population) AS Population FROM CovidAgr
UNION ALL
SELECT 'COVID_cases', SUM(total_cases) FROM CovidAgr
UNION ALL
SELECT 'COVID_deaths', SUM(total_deaths) FROM CovidAgr
UNION ALL
SELECT 'COVID_vaccinations', SUM(vaccinated_people) FROM CovidAgr)
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Selecting TOP 5 Locations
--Top 5 countries with total_cases
CREATE VIEW top5locations_total_cases AS
WITH Top5Countries AS (
    SELECT TOP 5 location, population, total_cases
    FROM CovidAgr
    ORDER BY total_cases DESC
),
RestOfTheWorld AS (
    SELECT 'Rest of the World' AS location,
           SUM(population) AS population,
           SUM(total_cases) AS total_cases
    FROM CovidAgr
    WHERE location NOT IN (SELECT location FROM Top5Countries)
)

SELECT location, population, total_cases
FROM Top5Countries

UNION ALL

SELECT location, population, total_cases
FROM RestOfTheWorld;
--------------------------------------------------------------------------------
--Top 5 countries with total_deaths
CREATE VIEW top5locations_total_deaths AS
WITH Top5Countries AS (
    SELECT top 5 location, population, total_deaths
    FROM CovidAgr
    ORDER BY total_deaths DESC
    
),
RestOfTheWorld AS (
    SELECT 'Rest of the World' AS location,
           SUM(population) AS population,
           SUM(total_deaths) AS total_deaths
    FROM CovidAgr
    WHERE location NOT IN (SELECT location FROM Top5Countries)
)
SELECT location, population, total_deaths
FROM Top5Countries

UNION ALL

SELECT location, population, total_deaths
FROM RestOfTheWorld;

--------------------------------------------------------------------------------
--Top 5 countries with total_vaccination
CREATE VIEW top5locations_total_vaccinations AS
WITH Top5Countries AS (
    SELECT top 5 location, population, vaccinated_people
    FROM CovidAgr
    ORDER BY vaccinated_people DESC
    
),
RestOfTheWorld AS (
    SELECT 'Rest of the World' AS location,
           SUM(population) AS population,
           SUM(vaccinated_people) AS vaccinated_people
    FROM CovidAgr
    WHERE location NOT IN (SELECT location FROM Top5Countries)
)
SELECT location, population, vaccinated_people
FROM Top5Countries

UNION ALL

SELECT location, population, vaccinated_people
FROM RestOfTheWorld;

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--Create a view to get all the cases,death,vaccination details, date wise and locationwise


create view covid_daily_data as
select t1.continent,t1.location,t1.date,t1.new_cases,t1.new_deaths,(CONVERT(BIGINT, t2.new_vaccinations))as new_vaccinations
from covid_death as t1
join covid_vaccination as t2 on t1.location=t2.location and t1.date=t2.date
where t1.continent is not null 
order by t1.location,t1.date
