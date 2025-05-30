
--Connecting to data base where the two tables are loaded
USE portfolio_proj;
SELECT DB_NAME();




--Checking the tables
--deaths table
SELECT 
	* 
FROM 
	portfolio_proj..CovidDeaths
ORDER BY 
	3,4;
--vaccination table
SELECT 
	* 
FROM 
	portfolio_proj..CovidVaccinations
ORDER BY 
	3,4;



--Table analysis
--Looking at total death vs cases ratio
SELECT
	SUM(new_cases) AS total_cases, 
	SUM(cast(new_deaths AS INT)) AS total_deaths, 
	SUM(cast(new_deaths AS INT))/SUM(New_Cases)*100 AS DeathPercentage
FROM
	portfolio_proj..CovidDeaths
WHERE
	continent IS NOT NULL
ORDER BY
	1,2

--Continent wise deathcount
SELECT 
	location, 
	SUM(cast(new_deaths AS INT)) AS TotalDeathCount
FROM 
	portfolio_proj..CovidDeaths
WHERE 
	continent is null 
	and location not in ('World', 'European Union', 'International')
GROUP BY 
	location
ORDER BY 
	TotalDeathCount DESC;

--Looking at countries with highest infection rate
SELECT 
	Location, 
	Population, 
	MAX(total_cases) AS HighestInfectionCount,  
	MAX((total_cases/population))*100 AS PercentPopulationInfected
FROM 
	portfolio_proj..CovidDeaths

GROUP BY 
	Location, Population
ORDER BY 
	PercentPopulationInfected DESC;


--Looking at total cases VS deaths day wise in very country
SELECT 
	location,
	date,
	total_cases,
	total_deaths,
	(total_deaths/total_cases)*100 AS death_percentage
FROM 
	portfolio_proj..CovidDeaths
ORDER BY 
	1,2

--Looking at cases VS population
SELECT 
	location,
	date,
	total_cases,
	population,
	(total_cases/population)*100 AS perc_pop
FROM 
	portfolio_proj..CovidDeaths
ORDER BY 
	1,2



--Looking at countries with highest death count per population
SELECT 
	location,
	MAX(CAST(total_deaths AS int)) AS total_death_count 
FROM 
	portfolio_proj..CovidDeaths
WHERE 
	continent is not NULL
GROUP BY 
	location
ORDER BY 
	total_death_count DESC

--Continent wise analysis
SELECT 
	continent,
	MAX(CAST(total_deaths AS int)) AS total_death_count 
FROM 
	portfolio_proj..CovidDeaths
WHERE 
	continent is not NULL
GROUP BY 
	continent
ORDER BY 
	total_death_count DESC

--Global numbers
SELECT 
	date, 
	SUM(new_cases)AS case_count,
	SUM(CAST(new_deaths AS INT)) AS death_count,
	(SUM(CAST(new_deaths AS INT))/SUM(new_cases))*100 AS death_percentage
FROM 
	portfolio_proj..CovidDeaths
WHERE 
	continent IS NOT NULL
GROUP BY 
	date
ORDER BY 
	1,2



--Joining two tables

--Check for duplicates in both tables
--For CovidDeaths:
SELECT location, date, COUNT(*)

FROM portfolio_proj..CovidDeaths

GROUP BY location, date

HAVING COUNT(*) > 1

--For CovidVaccinations:
SELECT location, date, COUNT(*)

FROM portfolio_proj..CovidVaccinations

GROUP BY location,date

HAVING COUNT(*) > 1

--Checking the join
SELECT DISTINCT
	*
FROM 
	portfolio_proj..CovidDeaths AS dea
JOIN 
	portfolio_proj..CovidVaccinations AS vac 
	ON dea.location=vac.location AND dea.date=vac.date
WHERE
	 dea.continent is NOT NULL
ORDER BY 3,2,4

--Looking at the vaccination 
SELECT 
	dea.continent,
	dea.location,
	dea.date,
	dea.population,
	vac.new_vaccinations 
FROM 
	portfolio_proj..CovidDeaths AS dea
JOIN 
	portfolio_proj..CovidVaccinations AS vac 
	ON dea.location=vac.location AND dea.date=vac.date
WHERE 
	dea.continent IS NOT NULL 
ORDER BY 
	dea.location,dea.date

--Looking at vaccination percentage of each country using CTE
WITH popvsvac (continent,location,date,population,new_vaccinations,CumulativeVacination)
AS
(
	SELECT
		dea.continent,
		dea.location,
		dea.date,
		dea.population,
		vac.new_vaccinations,
		SUM(CONVERT(INT,vac.new_vaccinations))OVER (PARTITION BY dea.location ORDER BY dea.location,dea.date) as CumulativeVacination
	FROM 
		portfolio_proj..CovidDeaths AS dea
	JOIN 
		portfolio_proj..CovidVaccinations AS vac 
		ON dea.location=vac.location AND dea.date=vac.date
	WHERE 
		dea.continent IS NOT NULL 
)
SELECT 
	*, 
	(CumulativeVacination/population)*100 AS VacPerc FROM popvsvac 
ORDER BY 
	2,3

--Looking at vaccination percentage of each country using Temp Table
--Creating the Temp Table #VaccinationPercentage
DROP TABLE IF EXISTS #VaccinationPercentage
CREATE TABLE #VaccinationPercentage
(
	continent nvarchar(255),
	location nvarchar(255),
	date datetime,
	population numeric,
	new_vaccinations numeric,
	CumulativeVacination Numeric
)

--Inserting Data into the Temp Table
INSERT INTO #VaccinationPercentage
	SELECT
		dea.continent,
		dea.location,
		dea.date,
		dea.population,
		vac.new_vaccinations,
		SUM(CONVERT(INT,vac.new_vaccinations))OVER (PARTITION BY dea.location ORDER BY dea.location,dea.date) as CumulativeVacination
	FROM 
		portfolio_proj..CovidDeaths AS dea
	JOIN 
		portfolio_proj..CovidVaccinations AS vac 
		ON dea.location=vac.location AND dea.date=vac.date
	WHERE 
		dea.continent IS NOT NULL 
--Checking the Temp Table
SELECT 
	*, 
	(CumulativeVacination/population)*100 AS VacPerc 
FROM 
	#VaccinationPercentage
ORDER BY 
	2,3


CREATE VIEW VaccinationPercentage AS
SELECT
    dea.continent,
    dea.location,
    dea.date,
    dea.population,
    vac.new_vaccinations,
    SUM(TRY_CONVERT(INT, vac.new_vaccinations)) 
        OVER (PARTITION BY dea.location ORDER BY dea.date) AS CumulativeVaccination,
    (SUM(TRY_CONVERT(FLOAT, vac.new_vaccinations)) 
        OVER (PARTITION BY dea.location ORDER BY dea.date)) * 100.0 / dea.population AS VaccinationPercentage
FROM 
    portfolio_proj..CovidDeaths AS dea
JOIN 
    portfolio_proj..CovidVaccinations AS vac 
    ON dea.location = vac.location AND dea.date = vac.date
WHERE 
    dea.continent IS NOT NULL;

