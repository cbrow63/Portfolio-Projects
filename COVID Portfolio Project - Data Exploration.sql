/*--Check Import
SELECT TOP 100 *
FROM ..[Covid Vaccinations] as vac
WHERE vac.total_tests > 0

SELECT TOP 100 *
FROM ..[Covid Deaths] as dea
WHERE vac.total_tests > 0

*/--Alter Data Types
--ALTER TABLE ..[Covid Deaths]
--ALTER COLUMN date date;
--UPDATE ..[Covid Deaths]
--SET date = NULL
--WHERE date = ''

--ALTER TABLE ..[Covid Deaths]
--ALTER COLUMN population bigint;
--UPDATE ..[Covid Deaths]
--SET population = NULL
--WHERE population = ''

--ALTER TABLE ..[Covid Deaths]
--ALTER COLUMN total_cases float;
--UPDATE ..[Covid Deaths]
--SET total_cases = NULL
--WHERE total_cases = ''


--ALTER TABLE ..[Covid Deaths]
--ALTER COLUMN new_cases float;
--UPDATE ..[Covid Deaths]
--SET new_cases = NULL
--WHERE new_cases = ''

--ALTER TABLE ..[Covid Deaths]
--ALTER COLUMN total_deaths float;
--UPDATE ..[Covid Deaths]
--SET total_deaths = NULL
--WHERE total_deaths = ''


--ALTER TABLE ..[Covid Deaths]
--ALTER COLUMN new_deaths float;
--UPDATE ..[Covid Deaths]
--SET new_deaths = NULL
--WHERE new_deaths = ''

--ALTER TABLE ..[Covid Vaccinations]
--ALTER COLUMN New_vaccinations int NULL
--UPDATE ..[Covid Vaccinations]
--SET new_vaccinations = NULL
--WHERE new_vaccinations = ''

-- Data Exploration!
-- Total Cases vs. Total Deaths
-- Shows potential likelihood of dying if infected in your country over time
SELECT location AS 'Country', date, total_cases, total_deaths, 
	CASE 
		WHEN total_cases > 0 THEN CONVERT(decimal(10,8),(total_deaths/total_cases)*100)
		WHEN total_cases <= 0 THEN NULL
	END AS DeathRate
FROM ..[Covid Deaths] cd
ORDER BY 1,2


--Total Cases vs. Population
--Shows rate of infection vs. total population by country over time
SELECT continent, location AS 'Country', date, total_cases, 
	CASE 
		WHEN total_cases > 0 THEN CONVERT(decimal(10,8),(total_cases/population)*100)
		WHEN total_cases <= 0 THEN NULL
	END AS 'Infected Population %'
FROM ..[Covid Deaths] cd
WHERE location LIKE '%States'
ORDER BY 1,2

--Countries with highest infection rate
SELECT TOP 25 location, population, MAX(total_cases) AS 'Infection Count' , MAX(((total_cases/population))*100) AS 'Infected Population %'
FROM ..[Covid Deaths] cd
GROUP BY location, population
ORDER BY 4 DESC

--Countries with most deaths from Covid
SELECT location, MAX(total_deaths) AS TotalDeathCount
FROM ..[Covid Deaths] cd
WHERE continent <> '' AND continent IS NOT NULL
GROUP BY location
ORDER BY TotalDeathCount DESC

--Continental Regions with most deaths
SELECT TOP 25 continent, MAX(total_deaths) AS TotalDeaths
FROM ..[Covid Deaths] cd
WHERE continent <> ''
GROUP BY continent
ORDER BY TotalDeaths DESC

--Global numbers

SELECT SUM(new_cases) as cases, SUM(CAST(new_deaths as float)) as deaths,
	CASE 
		WHEN SUM(new_cases) > 0 THEN CONVERT(decimal(10,8),(SUM(new_deaths)/SUM(new_cases))*100)
		WHEN SUM(new_cases) <= 0 THEN NULL
	END AS 'Death Rate'
FROM ..[Covid Deaths] cd
WHERE continent <> ''
ORDER BY 1,2

--Total Population vs. Vaccinations
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
FROM ..[Covid Deaths] dea
	INNER JOIN ..[Covid Vaccinations] vac
		ON dea.location = vac.location 
		AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3

--USE CTE - Population Vs. Vaccinations
WITH popvax (continent, location, date, population, new_vaccinations, RollingTotalVax)
AS(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	SUM(CAST(vac.new_vaccinations AS float)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingTotalVax
FROM ..[Covid Deaths] dea
	INNER JOIN ..[Covid Vaccinations] vac
		ON dea.location = vac.location 
		AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
	AND dea.location LIKE 'CANADA'
)
SELECT *, CONVERT(decimal(10,6),(RollingTotalVax/population*100)) as '% Vaccinated'
FROM popvax
ORDER BY 1,2,3

-- Temp Table - percent population vaccinated
DROP TABLE IF EXISTS #_PercentPopVaccinated
CREATE TABLE #_PercentPopVaccinated
(continent nvarchar(255),
location nvarchar(255), 
date date,
population numeric,
new_vaccinations numeric,
RollingTotalVax numeric)

INSERT INTO #_PercentPopVaccinated 
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	SUM(CAST(vac.new_vaccinations AS float)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingTotalVax
FROM ..[Covid Deaths] dea
	INNER JOIN ..[Covid Vaccinations] vac
		ON dea.location = vac.location 
		AND dea.date = vac.date
WHERE dea.continent IS NOT NULL

SELECT *, CONVERT(decimal(10,6),(RollingTotalVax/population*100)) as '% Vaccinated'
FROM #_PercentPopVaccinated
ORDER BY 1,2,3


--Creating views to store data for future viz
CREATE VIEW CasesVsDeaths AS
SELECT location AS 'Country', date, total_cases, total_deaths, 
	CASE 
		WHEN total_cases > 0 THEN CONVERT(decimal(10,8),(total_deaths/total_cases)*100)
		WHEN total_cases <= 0 THEN NULL
	END AS DeathRate
FROM ..[Covid Deaths] cd;

CREATE VIEW CasesVsPopulation AS
SELECT continent, location AS 'Country', date, total_cases, 
	CASE 
		WHEN total_cases > 0 THEN CONVERT(decimal(10,8),(total_cases/population)*100)
		WHEN total_cases <= 0 THEN NULL
	END AS 'Infected Population %'
FROM ..[Covid Deaths] cd;

CREATE VIEW InfectionRate AS
SELECT location, population, MAX(total_cases) AS 'Infection Count' , MAX(((total_cases/population))*100) AS 'Infected Population %'
FROM ..[Covid Deaths] cd
GROUP BY location, population;

CREATE VIEW MortalityByCountry AS
SELECT location, MAX(total_deaths) AS TotalDeathCount
FROM ..[Covid Deaths] cd
WHERE continent <> '' AND continent IS NOT NULL
GROUP BY location;


CREATE VIEW PercentPopulationVaccinated AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	SUM(CAST(vac.new_vaccinations AS float)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingTotalVax
FROM ..[Covid Deaths] dea
	INNER JOIN ..[Covid Vaccinations] vac
		ON dea.location = vac.location 
		AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
