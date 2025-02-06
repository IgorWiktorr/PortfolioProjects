SELECT *
FROM `arsenal-448013.covid_project.covid_deaths`
ORDER BY 3,4

--SELECT *
--FROM `arsenal-448013.covid_project.covid_vaccinations`
--ORDER BY 3,4

--Select Data we are going to be using
Select Location, date, total_cases, new_cases, total_deaths, population
From `arsenal-448013.covid_project.covid_deaths`
Where continent is not null 
order by 1,2

-- Total Cases vs Total Deaths
-- Shows likelihood of dying if you contract covid in your country

Select Location, date, total_cases,total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
From `arsenal-448013.covid_project.covid_deaths`
Where location like '%Poland%'
and continent is not null 
order by 1,2

-- Total Cases vs Population
-- Shows what percentage of population infected with Covid

Select Location, date, Population, total_cases,  (total_cases/population)*100 as PercentPopulationInfected
From `arsenal-448013.covid_project.covid_deaths`
Where location like '%Poland%'
order by 1,2

-- Countries with Highest Infection Rate compared to Population

Select Location, Population, MAX(total_cases) as HighestInfectionCount,  Max((total_cases/population))*100 as PercentPopulationInfected
From `arsenal-448013.covid_project.covid_deaths`
--Where location like '%Poland%'
Group by Location, Population
order by PercentPopulationInfected desc

-- Countries with Highest Death Count per Population

Select Location, MAX(cast(Total_deaths as int)) as TotalDeathCount
From `arsenal-448013.covid_project.covid_deaths`
--Where location like '%Poland%'
Where continent is not null 
Group by Location
order by TotalDeathCount desc

-- BREAKING THINGS DOWN BY CONTINENT

-- Showing contintents with the highest death count per population

Select continent, MAX(cast(Total_deaths as int)) as TotalDeathCount
From `arsenal-448013.covid_project.covid_deaths`
--Where location like '%Poland%'
Where continent is not null 
Group by continent
order by TotalDeathCount desc

-- GLOBAL NUMBERS

Select SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(New_Cases)*100 as DeathPercentage
From `arsenal-448013.covid_project.covid_deaths`
--Where location like '%Poland%'
where continent is not null 
--Group By date
order by 1,2

-- Total Population vs Vaccinations
-- Shows Percentage of Population that has recieved at least one Covid Vaccine

SELECT 
    dea.continent, 
    dea.location, 
    dea.date, 
    dea.population, 
    vac.new_vaccinations,
    SUM(CAST(vac.new_vaccinations AS INT64)) OVER (
        PARTITION BY dea.location 
        ORDER BY dea.date
    ) AS RollingPeopleVaccinated
-- , (RollingPeopleVaccinated/population)*100
FROM `arsenal-448013.covid_project.covid_deaths` AS dea
JOIN `arsenal-448013.covid_project.covid_vaccinations` AS vac
    ON dea.location = vac.location
    AND dea.date = vac.date
WHERE dea.continent IS NOT NULL 
ORDER BY dea.location, dea.date;

-- Using CTE to perform Calculation on Partition By in previous query

WITH PopvsVac AS (
    SELECT 
        dea.continent, 
        dea.location, 
        dea.date, 
        dea.population, 
        vac.new_vaccinations,
        SUM(CAST(COALESCE(vac.new_vaccinations, 0) AS INT64)) OVER (
            PARTITION BY dea.location 
            ORDER BY dea.date
        ) AS RollingPeopleVaccinated
    FROM `arsenal-448013.covid_project.covid_deaths` AS dea
    JOIN `arsenal-448013.covid_project.covid_vaccinations` AS vac
        ON dea.location = vac.location
        AND dea.date = vac.date
    WHERE dea.continent IS NOT NULL 
)
SELECT *, (RollingPeopleVaccinated / Population) * 100 AS PercentageVaccinated
FROM PopvsVac
ORDER BY location, date;

-- Using Temp Table to perform Calculation on Partition By in previous query

CREATE TEMP TABLE PercentPopulationVaccinated AS 
SELECT 
    dea.continent AS Continent, 
    dea.location AS Location, 
    dea.date AS Date, 
    dea.population AS Population, 
    vac.new_vaccinations AS New_Vaccinations,
    SUM(CAST(COALESCE(vac.new_vaccinations, 0) AS INT64)) OVER (
        PARTITION BY dea.Location 
        ORDER BY dea.Date
    ) AS RollingPeopleVaccinated
FROM `arsenal-448013.covid_project.covid_deaths` AS dea
JOIN `arsenal-448013.covid_project.covid_vaccinations` AS vac
    ON dea.location = vac.location
    AND dea.date = vac.date
WHERE dea.continent IS NOT NULL;

-- Select from the temp table
SELECT *, 
       (RollingPeopleVaccinated / Population) * 100 AS PercentageVaccinated
FROM PercentPopulationVaccinated
ORDER BY Location, Date;

-- Creating View to store data for later visualizations

CREATE VIEW `arsenal-448013.covid_project.PercentPopulationVaccinated` AS
SELECT 
    dea.continent AS Continent, 
    dea.location AS Location, 
    dea.date AS Date, 
    dea.population AS Population, 
    vac.new_vaccinations AS New_Vaccinations,
    SUM(CAST(COALESCE(vac.new_vaccinations, 0) AS INT64)) OVER (
        PARTITION BY dea.Location 
        ORDER BY dea.Date
    ) AS RollingPeopleVaccinated
-- , (RollingPeopleVaccinated / Population) * 100 AS PercentageVaccinated
FROM `arsenal-448013.covid_project.covid_deaths` AS dea
JOIN `arsenal-448013.covid_project.covid_vaccinations` AS vac
    ON dea.location = vac.location
    AND dea.date = vac.date
WHERE dea.continent IS NOT NULL;
