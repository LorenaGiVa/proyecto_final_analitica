/*
DROP TABLE IF EXISTS `wanalitica.Datas_W_Final.Data1`;
CREATE TABLE `wanalitica.Datas_W_Final.Data1`(
Year INT64 NOT NULL,
Leading_Cause STRING(255) NOT NULL,
Sex STRING(10) NOT NULL,
Race_Ethnicity STRING(50) NOT NULL,
Deaths INT64 NOT NULL,
Death_rate FLOAT64,
Age_adjusted_death_rate FLOAT64,);

DROP TABLE IF EXISTS `wanalitica.Datas_W_Final.Data2`;
CREATE TABLE `wanalitica.Datas_W_Final.Data2`(
Year INT64 NOT NULL,    
Borough STRING(200) NOT NULL,
UHF STRING(200) NOT NULL,
Gender STRING(200) NOT NULL,
Age STRING(200) NOT NULL,
Race STRING(200) NOT NULL,
HIV_diagnoses INT64,
HIV_diagnoses_rate FLOAT64,
Concurrent_diagnoses INT64,
percentage_linked_to_care_within_three_months FLOAT64,
AIDS_diagnoses INT64,
AIDS_diagnosis_rate FLOAT64,
PLWDHI_prevalence FLOAT64,
percentage_viral_suppression FLOAT64,
Deaths INT64,
Death_rate FLOAT64,
HIV_related_death_rate FLOAT64,
Non_HIV_related_death_rate FLOAT64,);

--1.¿Cuántas personas han sido infectadas en cada distrito?
SELECT UPPER(Borough) AS BOROUGH, SUM(HIV_diagnoses) AS PERSONAS_INFEC_POR_DISTRITO FROM `wanalitica.Datas_W_Final.VIH_annual_report`
group by Borough
order by PERSONAS_INFEC_POR_DISTRITO DESC

--2.¿Cual es el rango de edad que tiene un mayor número de personas infectadas?
WITH tb1 AS (SELECT Age AS EDAD, SUM(HIV_diagnoses) AS DIAGNOSTICOS FROM `wanalitica.Datas_W_Final.VIH_annual_report`
WHERE Age NOT LIKE '%All%'
GROUP BY Age)
SELECT tb1.DIAGNOSTICOS, EDAD FROM tb1
WHERE tb1.DIAGNOSTICOS = (SELECT MAX(DIAGNOSTICOS) FROM tb1)
GROUP BY EDAD, DIAGNOSTICOS

--3.¿Qué tipo de etnia/raza tiene mayor número de personas infectadas en cada barrio?
WITH TB1 AS (SELECT (Race) AS Raza, UHF AS Barrios, SUM(HIV_diagnoses) AS DIAGNOSTICOS 
FROM `wanalitica.Datas_W_Final.VIH_annual_report`
WHERE Race NOT LIKE '%All%' AND UHF NOT LIKE '%All%'
GROUP BY Race, Barrios),
TB2 AS (SELECT Barrios, MAX(DIAGNOSTICOS) AS MAX_DIAGNOSTICOS
FROM TB1
GROUP BY Barrios)
SELECT TB1.Raza, TB1.Barrios, TB1.DIAGNOSTICOS 
FROM TB1
INNER JOIN TB2 ON TB1.Barrios = TB2.Barrios AND TB1.DIAGNOSTICOS = TB2.MAX_DIAGNOSTICOS
ORDER BY TB1.Barrios ASC;

--4.¿Para qué género es más frecuente un diagnóstico de concurrencia?
SELECT lower(Gender) AS Genero, SUM(Concurrent_diagnoses) AS Total_diag_concurrentes 
FROM `wanalitica.Datas_W_Final.VIH_annual_report`
GROUP BY Gender
ORDER BY total_diag_concurrentes desc
LIMIT 1

--5.¿En qué año fueron diagnosticados más mujeres y en cúal los hombres por vih?
SELECT LOWER(Gender) AS GENERO, Year, SUM(HIV_diagnoses) AS total_contagios
FROM `wanalitica.Datas_W_Final.VIH_annual_report`
WHERE Gender IN ('Male', 'Female')
GROUP BY Gender, Year
HAVING total_contagios = (
SELECT MAX(sum_contagios)
FROM (SELECT Gender, Year, SUM(HIV_diagnoses) AS sum_contagios
FROM `wanalitica.Datas_W_Final.VIH_annual_report`
WHERE Gender IN ('Male', 'Female')
GROUP BY Gender, Year) AS subquery
WHERE subquery.Gender = `wanalitica.Datas_W_Final.VIH_annual_report`.Gender
GROUP BY subquery.Gender)

--6.¿Cuántas muertes hubo en promedio por VIH y Hepatitis en el año 2013?
WITH tb1 AS (SELECT AVG(Deaths) AS PROMEDIO_VIH, Year 
FROM `wanalitica.Datas_W_Final.VIH_annual_report`
WHERE Year = 2013
GROUP BY Year),
tb2 AS (SELECT AVG(CAST(Deaths AS INT64)) AS PROMEDIO_HEPATITIS, Leading_Cause, Year 
FROM `analitica-380317.VIH.Otras_Muertes`
WHERE Year = 2013 AND Leading_Cause ='Viral Hepatitis (B15-B19)' 
GROUP BY Leading_Cause, Year)
SELECT tb1.Year, tb1.PROMEDIO_VIH, tb2.PROMEDIO_HEPATITIS 
FROM tb1
INNER JOIN tb2 on tb1.Year = tb2.Year

--7.¿ Por distrito cuántos  infectados hay en cada grupo de edad?
SELECT Borough, Age,
SUM(HIV_diagnoses) AS Cantidad_infectados
FROM `analitica-380317.VIH.VIH_Reportes`
WHERE Age NOT LIKE '%All%' AND Borough NOT LIKE '%All%'
GROUP BY Borough, Age
ORDER BY Cantidad_infectados DESC;

--8.¿Cuál fue la principal causa de muerte de hispanos de cada año?
WITH tb1 AS (SELECT Leading_Cause AS CAUSA_DE_MUERTE,SUM(CAST(Deaths AS INT64)) AS MUERTES, Race_Ethnicity, Year
FROM `wanalitica.Datas_W_Final.causes_of_death` 
WHERE Race_Ethnicity = 'Hispanic' 
GROUP BY CAUSA_DE_MUERTE, Race_Ethnicity, Year),
tb2 AS (SELECT MAX(tb1.MUERTES) AS TOTAL,  tb1.Year 
FROM tb1
GROUP BY Year) 
SELECT tb1.CAUSA_DE_MUERTE, tb2.Year, tb2.TOTAL
FROM tb1
INNER JOIN tb2 ON tb1.MUERTES = tb2.TOTAL

--9.¿En el 2011 murieron más personas por VIH u otras causas?
WITH tb1 AS (SELECT Year,SUM(CAST(Deaths AS INT64)) AS MUERTES_OTRAS_CAUSAS 
FROM `wanalitica.Datas_W_Final.causes_of_death`
WHERE Year = 2011 AND Deaths NOT LIKE '%.%'
GROUP BY Year),
tb2 AS (SELECT Year, SUM(Deaths) AS MUERTES_VIH 
FROM `wanalitica.Datas_W_Final.VIH_annual_report`
WHERE Year IN(2011)
GROUP BY Year)
SELECT tb1.MUERTES_OTRAS_CAUSAS, tb2.MUERTES_VIH FROM tb1
LEFT JOIN tb2 on tb1.Year = tb2.Year

--10.¿En qué año fallecieron más personas respecto al total de personas infectadas en el mismo año?
WITH tb1 as (SELECT Year, sum(Deaths) as muertes_ano FROM `analitica-380317.VIH.VIH_Reportes`
GROUP BY Year),
tb2 as (SELECT YEAR, SUM(HIV_diagnoses+AIDS_diagnoses) AS INFECTADOS FROM `analitica-380317.VIH.VIH_Reportes`
GROUP BY YEAR)
select tb1.Year, muertes_ano,tb2.INFECTADOS from tb1
LEFT join tb2 on tb1.Year = tb2.YEAR
WHERE tb1.muertes_ano = (SELECT MAX(muertes_ano) from tb1)

--11.¿Qué raza/etnia tiene un mayor número de reportes y cuál tiene una tasa de supresión mayor sin tener en cuenta la categoría race = All? Lorena
SELECT Race AS Raza, COUNT(Race) AS TOTAL_REPORTES_RAZA, min(__viral_suppression) as MAX_TASA_SUPRESION 
FROM `wanalitica.Datas_W_Final.VIH_annual_report`
WHERE NOT __viral_suppression = 99999 AND NOT Race = 'All'
GROUP BY Race
ORDER BY MAX_TASA_SUPRESION DESC
LIMIT 1

--12.¿En qué rango de edad fallecen en promedio más personas por VIH/SIDA?
WITH tb1 as (SELECT Age AS EDAD, AVG(Deaths) AS muertes_PROMEDIO 
FROM `wanalitica.Datas_W_Final.VIH_annual_report`
WHERE Age NOT LIKE '%All%'
GROUP BY Age),
tb2 AS (SELECT AGE,COUNT(AGE) AS EDADES FROM `wanalitica.Datas_W_Final.VIH_annual_report`
GROUP BY AGE)
SELECT tb1.EDAD,tb1.muertes_PROMEDIO FROM tb1
LEFT JOIN tb2 ON tb1.EDAD = tb2.AGE
WHERE tb1.muertes_PROMEDIO = (SELECT MAX(tb1.muertes_PROMEDIO) FROM tb1)

--13.¿Cuál ha sido la evolución de cifras de contagios del año 2011 en comparación con el año 2015?
SELECT Year, sum(HIV_diagnoses) as DIAGNOSTICOS FROM `wanalitica.Datas_W_Final.VIH_annual_report`
where Year in (2011,2015)
group by Year

--14.¿De las personas infectadas con VIH/SIDA cuál fue el mínimo y el máximo de la tasa de  mujeres y hombres fallecidos por una causa diferente al VIH/SIDA?
SELECT Gender, max(Non_HIV_related_death_rate) AS MAYOR, min(Non_HIV_related_death_rate) AS MENOR 
FROM `wanalitica.Datas_W_Final.VIH_annual_report`
WHERE Gender IN ('Female','Male') AND NOT HIV_related_death_rate = 99999.0 AND NOT HIV_related_death_rate = 0.0
GROUP BY Gender
ORDER BY MAYOR DESC

--15.¿Cuántas personas fallecieron por otras muertes y por VIH entre el 2011 y 2014?
WITH tb1 AS (SELECT Year,SUM(CAST(Deaths AS INT64)) AS MUERTES_OTRAS 
FROM `wanalitica.Datas_W_Final.causes_of_death`
WHERE Year BETWEEN 2011 AND 2014 AND Deaths NOT LIKE '%.%'
GROUP BY Year),
tb2 AS (SELECT Year, SUM(Deaths) AS MUERTES_VIH 
FROM `wanalitica.Datas_W_Final.VIH_annual_report`
WHERE Year BETWEEN 2011 AND 2014
GROUP BY Year)
SELECT  tb1.Year, tb1.MUERTES_OTRAS, tb2.MUERTES_VIH 
FROM tb1
LEFT join tb2 on tb1.Year = tb2.Year 

--16.¿En qué Distrito hay más mujeres menores de 50 años contagiadas por SIDA? 
SELECT UPPER(Borough) AS Borough, SUM(AIDS_diagnoses) AS Total_diagnosticos
FROM `wanalitica.Datas_W_Final.VIH_annual_report`
WHERE Age NOT LIKE '%All%' AND Gender = 'Female' AND CAST(SUBSTR(Age, 1, 2) AS INT64) < 50 AND Borough NOT LIKE '%All%'
GROUP BY Borough
ORDER BY Total_diagnosticos desc
LIMIT 1

--17.¿Por distrito cual es la tasa más alta entre muertes por VIH/SIDA y muertes por otra causa segun el sexo?
SELECT UPPER(Borough) AS Borough, LOWER(Gender) AS Gender, MAX(HIV_related_death_rate) AS MAX_TASA_MUERTES_VIH, MAX(Non_HIV_related_death_rate) AS MAX_TASA_MUERTES_NO_VIH 
FROM `wanalitica.Datas_W_Final.VIH_annual_report`
WHERE NOT HIV_related_death_rate = 99999.0 AND NOT Non_HIV_related_death_rate = 99999.0 AND NOT Age = 'All' AND NOT Borough = 'All'
GROUP BY Borough, Gender
ORDER BY MAX_TASA_MUERTES_VIH DESC, MAX_TASA_MUERTES_NO_VIH  DESC, Borough DESC

--18.¿Existe una relación directamente proporcional entre  las tasas de muertes por consumo de drogas y alcohol y el VIH?
WITH tb1 AS (SELECT AVG(CAST(Death_Rate AS FLOAT64)) AS promedio_tasa_mortalidad, Leading_Cause, Year 
FROM `wanalitica.Datas_W_Final.causes_of_death`
WHERE (Death_Rate NOT LIKE '%.%') AND Leading_Cause IN ('Mental and Behavioral Disorders due to Accidental Poisoning and Other Psychoactive Substance Use (F11-F16, F18-F19, X40-X42, X44)', 'Mental and Behavioral Disorders due to Use of Alcohol (F10)')
GROUP BY Year, Leading_Cause
ORDER BY promedio_tasa_mortalidad desc),
tb2 AS (SELECT AVG(Death_rate) AS PROMEDIO_VIH, Year 
FROM `wanalitica.Datas_W_Final.VIH_annual_report`
GROUP BY Year
ORDER BY PROMEDIO_VIH)
SELECT tb1.Year, tb1.promedio_tasa_mortalidad, tb2.PROMEDIO_VIH
FROM tb1
INNER JOIN tb2 ON tb2.Year = tb1.Year 

--19.¿Cuál es el índice de mortalidad por raza/etnia, sexo y edad? 
SELECT Race, Gender, Age, ROUND(AVG(Death_rate), 0) AS Indice_Mortalidad
FROM `wanalitica.Datas_W_Final.VIH_annual_report`
WHERE NOT HIV_related_death_rate = 99999.0
GROUP BY Race, Gender, Age

--20.¿Hubo algun año entre el 2011 y el 2014 en el cual las enfermedades del corazón (causa más frecuente) superaron las muertes por VIH?
WITH tb1 AS (SELECT Year,SUM(CAST(Deaths AS INT64)) AS MUERTES_CORAZON, Leading_Cause 
FROM `wanalitica.Datas_W_Final.causes_of_death`
WHERE Year BETWEEN 2011 AND 2014 AND Deaths NOT LIKE '%.%' AND Leading_Cause = 'Diseases of Heart (I00-I09, I11, I13, I20-I51)'
GROUP BY Year, Leading_Cause),
tb2 AS (SELECT Year, SUM(Deaths) AS MUERTES_VIH 
FROM `wanalitica.Datas_W_Final.VIH_annual_report`
WHERE Year BETWEEN 2011 AND 2014
GROUP BY Year)
SELECT tb1.Year, tb1.MUERTES_CORAZON, tb2.MUERTES_VIH
FROM tb1
LEFT JOIN tb2 ON tb1.Year = tb2.Year 
WHERE tb1.MUERTES_CORAZON> tb2.MUERTES_VIH
*/