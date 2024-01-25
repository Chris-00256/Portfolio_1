-- Using Excel data sheets, hence the 'X'
SELECT * 
FROM COVID_DeathsX

--SELECT * 
--FROM COVID_VaccinationsX
--WHERE continent is not null


--Select the data that we are going to be using

SELECT Location, date, total_cases, new_cases, total_deaths, population
FROM COVID_DeathsX
WHERE continent is not null
ORDER BY location, date 

-- Total cases Vs Total Deaths

SELECT Location, date, total_cases, total_deaths, 
(CONVERT(float, total_deaths) / NULLIF(CONVERT(float, total_cases), 0)) AS Death_Percentage
FROM COVID_DeathsX
ORDER BY 1,2

SELECT Location, date, total_cases, total_deaths, --Taking more than 8 mins to run/execute the query
(CONVERT(float, total_deaths) / NULLIF(CONVERT(float, total_cases), 0))*100 AS Death_Percentage
FROM COVID_DeathsX
WHERE total_cases != 'NULL' AND continent is not null
ORDER BY 1,2

-- Likely of dying of COVID in Uganda
SELECT Location, date, total_cases, total_deaths, 
	(CONVERT(float, total_deaths) / NULLIF(CONVERT(float, total_cases), 0))*100 AS Death_Percentage
	FROM COVID_DeathsX
	WHERE location = 'Uganda' AND total_cases != 'NULL'
	ORDER BY 1,2

-- Looking at total cases vs population
-- Shows what percentage of the population has COVID
SELECT Location, date, total_cases, population, (total_cases/population)*100 AS Population_Percentage
	FROM COVID_DeathsX
	WHERE total_cases != 'NULL' AND continent is not null
	ORDER BY 1,2

SELECT Location, date, total_cases, population, (total_cases/population)*100 AS Poplulation_Percentage
	FROM COVID_DeathsX
	WHERE location = 'Uganda' AND total_cases != 'NULL'
	ORDER BY 1,2

--Looking at countries with the highest infection rate compared to population
SELECT Location, MAX(total_cases) AS Highest_Infection_Count, population, MAX((total_cases/population))*100 AS Infection_per_Population_Percentage
	FROM COVID_DeathsX
	WHERE total_cases != 'NULL' AND continent is not null
	GROUP BY location, population
	ORDER BY Infection_per_Population_Percentage DESC

--Showing countries with highest death count per population
SELECT Location, MAX(CAST (total_deaths AS bigint)) AS Highest_death_Count
	FROM COVID_DeathsX
	WHERE continent is not null
	GROUP BY location
	ORDER BY Highest_death_Count DESC

-- GROUPING BY CONTINENT
---- will give you every figure excluding Canada
--SELECT continent, MAX(CAST (total_deaths AS bigint)) AS Highest_death_Count
--	FROM COVID_DeathsX
--	WHERE continent is not null
--	GROUP BY continent
--	ORDER BY Highest_death_Count DESC

---- will give you canada data needed to add above
--SELECT continent, location, MAX(CAST (total_deaths AS bigint)) AS Highest_death_Count
--	FROM COVID_DeathsX
--	WHERE continent is not null AND location = 'Canada'
--	GROUP BY continent, location
--	ORDER BY Highest_death_Count DESC

SELECT location, MAX(CAST (total_deaths AS bigint)) AS Highest_death_Count
	FROM COVID_DeathsX
	WHERE continent is null
	GROUP BY location
	ORDER BY Highest_death_Count DESC

-- Showing the continents with the highest death continent

SELECT continent, MAX(CAST (total_deaths AS bigint)) AS Highest_death_Count
	FROM COVID_DeathsX
	WHERE continent is not null
	GROUP BY continent
	ORDER BY Highest_death_Count DESC

-- GLOBAL NUMBERS
--givivng numbers around the world on that specific date
SELECT date, SUM(new_cases) AS Total_New_Cases, SUM(CAST(new_deaths AS bigint)) AS Total_New_Deaths, 
		(SUM(CAST(new_deaths AS bigint))/SUM(new_cases))*100 AS Death_Percentage --Taking more than 8 mins to run/execute the query
	FROM COVID_DeathsX
	WHERE continent is not null
	GROUP BY date
	ORDER BY 1,2

-- removing the date column will give the overall world total

SELECT SUM(new_cases) AS Total_New_Cases, SUM(CAST(new_deaths AS bigint)) AS Total_New_Deaths, 
		(SUM(CAST(new_deaths AS bigint))/SUM(new_cases))*100 AS Death_Percentage --Taking more than 8 mins to run/execute the query
	FROM COVID_DeathsX
	WHERE continent is not null
	ORDER BY 1,2


-- JOINING WITH COVID_VACCINATION TABLES

SELECT *
FROM COVID_VaccinationsX

SELECT * 
	FROM COVID_DeathsX Deaths
	JOIN COVID_VaccinationsX Vaccinate
	ON Deaths.location = Vaccinate.location
	AND Deaths.date = Vaccinate.date



-- Looking at total population vs total vaccinations

SELECT Deaths.continent, Deaths.location, Deaths.date, Deaths.population, Vaccinate.new_vaccinations 
	FROM COVID_DeathsX Deaths
	JOIN COVID_VaccinationsX Vaccinate
	ON Deaths.location = Vaccinate.location
	AND Deaths.date = Vaccinate.date
	WHERE Deaths.continent is not null
	ORDER BY 1,2,3

-- WITHOUT THE NULLS IN NEW VACCINATION

SELECT Deaths.continent, Deaths.location, Deaths.date, Deaths.population, Vaccinate.new_vaccinations 
	FROM COVID_DeathsX Deaths
	JOIN COVID_VaccinationsX Vaccinate
	ON Deaths.location = Vaccinate.location
	AND Deaths.date = Vaccinate.date
	WHERE Deaths.continent is not null AND Vaccinate.new_vaccinations != 'NULL'
	ORDER BY 1,2,3

-- Doing a rolling count in this query

SELECT Deaths.continent, Deaths.location, Deaths.date, Deaths.population, Vaccinate.new_vaccinations, 
		SUM(CONVERT(bigint, Vaccinate.new_vaccinations)) OVER (PARTITION BY Deaths.location 
		ORDER BY Deaths.location, Deaths.date) AS Cumulative_of_vaccinated
	FROM COVID_DeathsX Deaths
	JOIN COVID_VaccinationsX Vaccinate
	ON Deaths.location = Vaccinate.location
	AND Deaths.date = Vaccinate.date
	WHERE Deaths.continent is not null AND Vaccinate.new_vaccinations != 'NULL'
	ORDER BY 2,3


-- Using the overall cumulative total to get vaccinated per population by location
-- using a CTE - Number of columns in cte = columns in select statement

WITH Pop_vs_Vacc (continent, location, date, population, new_vaccinations, Cumulative_of_Vaccinated)
AS 
(
SELECT Deaths.continent, Deaths.location, Deaths.date, Deaths.population, Vaccinate.new_vaccinations, 
		SUM(CONVERT(bigint, Vaccinate.new_vaccinations)) OVER (PARTITION BY Deaths.location 
		ORDER BY Deaths.location, Deaths.date) AS Cumulative_of_vaccinated
	FROM COVID_DeathsX Deaths
	JOIN COVID_VaccinationsX Vaccinate
	ON Deaths.location = Vaccinate.location
	AND Deaths.date = Vaccinate.date
	WHERE Deaths.continent is not null AND Vaccinate.new_vaccinations != 'NULL'
	--ORDER BY 2,3
)
SELECT * , (Cumulative_of_Vaccinated/population)*100
FROM Pop_vs_Vacc


-- TEMP TABLES

DROP TABLE IF EXISTS #Percent_pop_vaccinated
CREATE TABLE #Percent_pop_vaccinated
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccination numeric,
Cumulative_of_vaccinated numeric
)

INSERT INTO #Percent_pop_vaccinated
	SELECT Deaths.continent, Deaths.location, Deaths.date, Deaths.population, Vaccinate.new_vaccinations, 
		SUM(CONVERT(bigint, Vaccinate.new_vaccinations)) OVER (PARTITION BY Deaths.location 
		ORDER BY Deaths.location, Deaths.date) AS Cumulative_of_vaccinated
	FROM COVID_DeathsX Deaths
	JOIN COVID_VaccinationsX Vaccinate
	ON Deaths.location = Vaccinate.location
	AND Deaths.date = Vaccinate.date
	WHERE Deaths.continent is not null AND Vaccinate.new_vaccinations != 'NULL'
	--ORDER BY 2,3

SELECT * , (Cumulative_of_Vaccinated/population)*100 AS Cumulative_percentage
FROM #Percent_pop_vaccinated




-- Creating view to store data for later visualizations


CREATE VIEW Uganda_Death_Percentage AS
	SELECT Location, date, total_cases, total_deaths, 
	(CONVERT(float, total_deaths) / NULLIF(CONVERT(float, total_cases), 0))*100 AS Death_Percentage
	FROM COVID_DeathsX
	WHERE location = 'Uganda' AND total_cases != 'NULL'
	--ORDER BY 1,2

CREATE VIEW World_Infected_Population_Percentage AS
	SELECT Location, date, total_cases, population, (total_cases/population)*100 AS Population_Percentage
	FROM COVID_DeathsX
	WHERE total_cases != 'NULL' AND continent is not null
	--ORDER BY 1,2

CREATE VIEW Uganda_Infected_Poplulation_Percentage AS
SELECT Location, date, total_cases, population, (total_cases/population)*100 AS Poplulation_Percentage
	FROM COVID_DeathsX
	WHERE location = 'Uganda' AND total_cases != 'NULL'
	--ORDER BY 1,2

CREATE VIEW World_Highest_Infection_Rate AS
	SELECT Location, MAX(total_cases) AS Highest_Infection_Count, population, MAX((total_cases/population))*100 AS Infection_per_Population_Percentage
	FROM COVID_DeathsX
	WHERE total_cases != 'NULL' AND continent is not null
	GROUP BY location, population
	--ORDER BY Infection_per_Population_Percentage DESC

CREATE VIEW World_Highest_Death_Count AS
	SELECT location, MAX(CAST (total_deaths AS bigint)) AS Highest_death_Count
	FROM COVID_DeathsX
	WHERE continent is null
	GROUP BY location
	--ORDER BY Highest_death_Count DESC

CREATE VIEW World_Cumulative_Vaccinated AS
	SELECT Deaths.continent, Deaths.location, Deaths.date, Deaths.population, Vaccinate.new_vaccinations, 
		SUM(CONVERT(bigint, Vaccinate.new_vaccinations)) OVER (PARTITION BY Deaths.location 
		ORDER BY Deaths.location, Deaths.date) AS Cumulative_of_vaccinated
	FROM COVID_DeathsX Deaths
	JOIN COVID_VaccinationsX Vaccinate
	ON Deaths.location = Vaccinate.location
	AND Deaths.date = Vaccinate.date
	WHERE Deaths.continent is not null AND Vaccinate.new_vaccinations != 'NULL'
	--ORDER BY 2,3

-- VIEWS ARE PERMANENT AND HAVE TO BE DELETED AND CAN BE QUERIED FROM AS TABLES