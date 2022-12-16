--Select Data we are going to be using
SELECT Location, date, total_cases, new_cases, total_deaths, population
FROM coviddeaths
WHERE continent IS NOT NULL;

--Looking at Total Cases vs Total Deaths
--Shows the likelihood of dying if you contract covid in your country
SELECT Location, date, total_cases, total_deaths, CAST(total_deaths AS real)/CAST(total_cases AS real)*100 AS deathPercentage
FROM coviddeaths
WHERE continent IS NOT NULL;

--Looking at Total Cases vs Population
--Shows what percentage of population got Covid
SELECT Location, date, population, total_cases, CAST(total_cases AS real)/CAST(population AS real)*100 AS percentageInfected
FROM coviddeaths
WHERE continent IS NOT NULL;

--Looking at Countries with Highest Infection Rate compared to population
SELECT Location, Population, MAX(total_cases) AS HighestInfectionCount, MAX(CAST(total_cases AS real)/CAST(population AS real)*100) AS percentageInfected
FROM coviddeaths
WHERE continent IS NOT NULL
GROUP BY Location, Population
ORDER BY percentageInfected DESC;

--Showing the Countries with Highest Death Count
SELECT Location, MAX(total_deaths) AS TotalDeathCount
FROM coviddeaths
WHERE continent IS NOT NULL
GROUP BY Location, Population
ORDER BY totaldeathcount DESC;

--Looking the data of Total Deaths by continent
--Showing the continent with the highest Death Count
SELECT continent, MAX(total_deaths) AS TotalDeathCount
FROM coviddeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY TotalDeathCount DESC;

--Global numbers
SELECT TO_DATE(date,'MM/DD/YYYY') AS date, SUM(new_cases) AS Total_Cases, SUM(new_deaths) AS Total_Deaths, SUM(new_deaths)/SUM(new_cases)*100 AS Death_Percentage
FROM coviddeaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY date;

--Looking at total population vs vaccinations
--Using a Subquery
SELECT *, 
SUM(new_vaccinations) OVER (PARTITION BY location ORDER BY location, date) AS RollingPeopleVaccinated FROM
(SELECT cd.continent, cd.location, TO_DATE(cd.date,'MM/DD/YYYY') AS date, cd.population, cv.new_vaccinations
FROM coviddeaths AS cd JOIN covidvaccinations AS cv 
ON cd.location = cv.location AND cd.date = cv.date
WHERE cd.continent IS NOT NULL
ORDER BY cd.location, date) AS sq
WHERE location='Colombia';

--Using CTE
WITH PopulationVSVaccinations (Continent, Location, Date, Population, New_vaccinations) AS (
SELECT cd.continent, cd.location, TO_DATE(cd.date,'MM/DD/YYYY') AS date, cd.population, cv.new_vaccinations
FROM coviddeaths AS cd JOIN covidvaccinations AS cv 
ON cd.location = cv.location AND cd.date = cv.date
WHERE cd.continent IS NOT NULL
)
SELECT Continent, Location, date, population, new_vaccinations, SUM(new_vaccinations) OVER (PARTITION BY location ORDER BY location, date) AS RollingPeopleVaccinated
FROM PopulationVSVaccinations;

--Using a Temp Table
DROP TABLE IF EXISTS PercentPopulationVaccinated;
CREATE TEMPORARY TABLE PercentPopulationVaccinated
(
	Continent varchar(255),
	Location varchar(255),
	Date date,
	Population numeric,
	New_vaccinations numeric,
	RollingPeopleVaccinated numeric
);

INSERT INTO PercentPopulationVaccinated
WITH PopulationVSVaccinations (Continent, Location, Date, Population, New_vaccinations) AS (
SELECT cd.continent, cd.location, TO_DATE(cd.date,'MM/DD/YYYY') AS date, cd.population, cv.new_vaccinations
FROM coviddeaths AS cd JOIN covidvaccinations AS cv 
ON cd.location = cv.location AND cd.date = cv.date
WHERE cd.continent IS NOT NULL
)
SELECT Continent, Location, date, population, new_vaccinations, SUM(new_vaccinations) OVER (PARTITION BY location ORDER BY location, date) AS RollingPeopleVaccinated
FROM PopulationVSVaccinations;

SELECT *, (RollingPeopleVaccinated/population)*100 AS percentageVaccinated FROM PercentPopulationVaccinated
WHERE location='Colombia';

--Creating a view for later visualization
CREATE VIEW PopulationVaccinated AS
SELECT *, 
SUM(new_vaccinations) OVER (PARTITION BY location ORDER BY location, date) AS RollingPeopleVaccinated FROM
(SELECT cd.continent, cd.location, TO_DATE(cd.date,'MM/DD/YYYY') AS date, cd.population, cv.new_vaccinations
FROM coviddeaths AS cd JOIN covidvaccinations AS cv 
ON cd.location = cv.location AND cd.date = cv.date
WHERE cd.continent IS NOT NULL
ORDER BY cd.location, date) AS sq
WHERE location='Colombia';
