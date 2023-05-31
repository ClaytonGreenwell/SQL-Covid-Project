/* This is a portfolio project that uses a COVID-19 public dataset to demonstrate knowledge of Joins, CTEs, 
Aggregate Functions, Creating Views, and Converting data types. This is based off a SQL tutorial 
created by "Alex the Analyst", and is explored here with explicit permission. I am using the sandbox version 
of BigQuery, and then using RSQLite to export to a .sql file, as this isn't available in BigQuery sandbox.
*/

SELECT *
FROM `clay-project-373503.PortfolioProject.CovidDeaths`
WHERE continent IS NOT NULL
ORDER BY 3, 4

-- Selecting the data that's relevant

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM `clay-project-373503.PortfolioProject.CovidDeaths`
WHERE continent IS NOT NULL
ORDER BY 1, 2

-- Looking at total_cases vs. total_deaths
-- Shows liklihood of dying if you contract COVID in your country

SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS death_percentage
FROM `clay-project-373503.PortfolioProject.CovidDeaths`
WHERE location = "United States"
ORDER BY 1, 2

-- Looking at total_cases vs. population
-- Shows what percentage of population infected with COVID

SELECT location, date, population, total_cases, (total_cases/population)*100 AS percent_population_infected
FROM `clay-project-373503.PortfolioProject.CovidDeaths`
WHERE location = "United States"
  AND continent IS NOT NULL
ORDER BY 1, 2

-- Looking at countries with highest infection rate compared to population

SELECT location, population, 
  MAX(total_cases) AS highest_infection_count, 
  MAX(total_cases/population)*100 AS percent_population_infected
FROM `clay-project-373503.PortfolioProject.CovidDeaths`
--WHERE location = "United States"
GROUP BY location, population
ORDER BY percent_population_infected DESC

-- Showing Countries with Highest Death Count per Population

SELECT location,  
  MAX(cast(total_deaths AS int)) AS total_death_count
FROM `clay-project-373503.PortfolioProject.CovidDeaths`
--WHERE location = "United States"
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY total_death_count DESC

-- Showing continents with highest death count per population

SELECT continent,  
  MAX(cast(total_deaths AS int)) AS total_death_count
FROM `clay-project-373503.PortfolioProject.CovidDeaths`
--WHERE location = "United States"
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY total_death_count DESC

-- Global Numbers

SELECT SUM(new_cases) AS total_cases, SUM(new_deaths) AS total_deaths, 
  SUM(new_deaths)/SUM(new_cases)*100 AS death_percentage
FROM `clay-project-373503.PortfolioProject.CovidDeaths`
--WHERE location = "United States"
WHERE continent IS NOT NULL
--GROUP BY date
ORDER BY 1, 2

-- Looking at Total Populations vs. Vaccinations

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
  SUM(CAST(vac.new_vaccinations AS INT64)) 
  OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rolling_people_vaccinated
 --, (rolling_people_vaccinated/population)*100
FROM `clay-project-373503.PortfolioProject.CovidDeaths` dea
JOIN `clay-project-373503.PortfolioProject.CovidVaccinations` vac
  ON dea.location = vac.location
  AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2, 3

-- Use CTE to perform calulation on Partition By in previous query

With Pop_vs_Vac AS 
(
  SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
    SUM(CAST(vac.new_vaccinations AS INT64)) 
    OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rolling_people_vaccinated
   --, (rolling_people_vaccinated/population)*100
  FROM `clay-project-373503.PortfolioProject.CovidDeaths` dea
  JOIN `clay-project-373503.PortfolioProject.CovidVaccinations` vac
    ON dea.location = vac.location
    AND dea.date = vac.date
  WHERE dea.continent IS NOT NULL
  --ORDER BY 2, 3
) 
SELECT *, (rolling_people_vaccinated/population)*100 AS rolling_population_vac_percentage
FROM Pop_vs_Vac

-- Create View to store data for later possible visualizations

CREATE VIEW PortfolioProject.percent_population_vaccinated AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
  SUM(CAST(vac.new_vaccinations AS INT64)) 
  OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rolling_people_vaccinated
FROM `clay-project-373503.PortfolioProject.CovidDeaths` dea
  JOIN `clay-project-373503.PortfolioProject.CovidVaccinations` vac
  ON dea.location = vac.location
  AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
