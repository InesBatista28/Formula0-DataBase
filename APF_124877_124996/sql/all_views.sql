USE p3g9;
GO

-- CLASSIFICAÇÃO ATUAL DE PILOTOS 
GO
CREATE OR ALTER VIEW [dbo].[View_ClassificacaoPilotos] AS
SELECT
    T.Ano AS Temporada,
    RANK() OVER (PARTITION BY T.Ano ORDER BY SUM(R.Pontos) DESC) AS Posicao,
    P.Abreviação AS Piloto,
    M.Nome AS NomePiloto,
    E.Nome AS Equipa,
    SUM(R.Pontos) AS Pontos
FROM Temporada T
INNER JOIN Grande_Prémio GP ON T.Ano = GP.Ano_Temporada
INNER JOIN Sessões S ON GP.NomeGP = S.NomeGP
INNER JOIN Resultados R ON S.NomeSessão = R.NomeSessão
INNER JOIN Piloto P ON R.ID_Piloto = P.ID_Piloto
INNER JOIN Membros_da_Equipa M ON P.ID_Membro = M.ID_Membro
INNER JOIN Equipa E ON P.ID_Equipa = E.ID_Equipa
GROUP BY T.Ano, P.Abreviação, M.Nome, E.Nome;
GO

--RESULTADOS DETALHADOS POR SESSÃO 
CREATE OR ALTER VIEW [dbo].[View_DetalhesSessao] AS
SELECT
    GP.NomeGP,
    S.NomeSessão,
    S.Estado, 
    R.PosiçãoFinal,
    R.PosiçãoGrid, 
    P.Abreviação AS Piloto,
    E.Nome AS Equipa,
    R.TempoFinal,
    R.Status,
    R.Pontos
FROM Sessões S
INNER JOIN Grande_Prémio GP ON S.NomeGP = GP.NomeGP
INNER JOIN Resultados R ON S.NomeSessão = R.NomeSessão
INNER JOIN Piloto P ON R.ID_Piloto = P.ID_Piloto
INNER JOIN Equipa E ON P.ID_Equipa = E.ID_Equipa;
GO


-- LISTA COMPLETA DE CORRIDAS PASSADAS 
CREATE OR ALTER VIEW [dbo].[View_ListaCorridasPassadas] AS
SELECT
    T.Ano AS Temporada,
    GP.NomeGP AS Corrida,
    GP.DataCorrida,
    C.Nome AS Circuito,
    S.Estado
FROM Grande_Prémio GP
INNER JOIN Temporada T ON GP.Ano_Temporada = T.Ano
INNER JOIN Circuito C ON GP.ID_Circuito = C.ID_Circuito
INNER JOIN Sessões S ON GP.NomeGP = S.NomeGP
WHERE S.NomeSessão LIKE 'Corrida%' AND S.Estado = 'Concluída';
GO


-- vw_Team_Details.sql
IF OBJECT_ID('vw_Team_Details', 'V') IS NOT NULL
    DROP VIEW vw_Team_Details;
GO
CREATE VIEW vw_Team_Details AS
SELECT 
    e.ID_Equipa,
    e.Nome,
    e.Nacionalidade,
    e.Base,
    e.ChefeEquipa,
    ChefeTecnico = e.ChefeTécnico,
    e.AnoEstreia,
    e.ModeloChassis,
    e.Power_Unit,
    e.PilotosReserva,
    ReserveDrivers = (
        SELECT STRING_AGG(m.Nome, ', ')
        FROM Membros_da_Equipa m
        WHERE m.ID_Equipa = e.ID_Equipa
          AND m.Função = 'Reserve Driver'
    )
FROM Equipa e;
GO

-- vw_Teams_List_Grid.sql
IF OBJECT_ID('vw_Teams_List_Grid', 'V') IS NOT NULL
    DROP VIEW vw_Teams_List_Grid;
GO
CREATE VIEW vw_Teams_List_Grid AS
SELECT ID_Equipa, Nome, Nacionalidade, AnoEstreia FROM Equipa;
GO

-- vw_Teams_List.sql
IF OBJECT_ID('vw_Teams_List', 'V') IS NOT NULL
    DROP VIEW vw_Teams_List;
GO
CREATE VIEW vw_Teams_List AS
SELECT ID_Equipa, Nome FROM Equipa;
GO

-- vw_Teams.sql
CREATE OR ALTER VIEW vw_Teams AS
SELECT ID_Equipa, Nome
FROM Equipa;
GO

-- vw_TeamMembers.sql
CREATE OR ALTER VIEW vw_TeamMembers AS
SELECT
    m.ID_Membro,
    m.Nome,
    m.Nacionalidade,
    m.DataNascimento,
    m.Género,
    m.Função,
    m.ID_Equipa,
    e.Nome AS TeamName
FROM Membros_da_Equipa m
INNER JOIN Equipa e ON m.ID_Equipa = e.ID_Equipa;
GO

-- vw_Staff_Details.sql
IF OBJECT_ID('vw_Staff_Details', 'V') IS NOT NULL
    DROP VIEW vw_Staff_Details;
GO
CREATE VIEW vw_Staff_Details AS
SELECT 
    s.StaffID,
    s.Username,
    s.Password,
    s.NomeCompleto,
    s.Role,
    c.ID_Contrato,
    c.AnoInicio,
    c.AnoFim,
    c.Função,
    c.Salário,
    c.Género,
    c.ID_Membro
FROM Staff s
LEFT JOIN Membros_da_Equipa m ON s.NomeCompleto = m.Nome
LEFT JOIN Contrato c ON m.ID_Membro = c.ID_Membro;
GO

-- vw_Sessions_ByGP.sql
IF OBJECT_ID('vw_Sessions_ByGP', 'V') IS NOT NULL
    DROP VIEW vw_Sessions_ByGP;
GO
CREATE VIEW vw_Sessions_ByGP AS
SELECT 
    NomeSessão,
    Estado,
    CondiçõesPista,
    NomeGP
FROM Sessões;
GO

-- vw_Season_TeamStandings.sql
CREATE OR ALTER VIEW vw_Season_TeamStandings AS
SELECT 
    ROW_NUMBER() OVER (ORDER BY ISNULL(SUM(r.Pontos), 0) DESC, COUNT(CASE WHEN r.PosiçãoFinal = 1 THEN 1 END) DESC) AS Position,
    e.Nome AS Team,
    ISNULL(SUM(r.Pontos), 0) AS TotalPoints,
    COUNT(CASE WHEN r.PosiçãoFinal = 1 THEN 1 END) AS Wins,
    COUNT(CASE WHEN r.PosiçãoFinal <= 3 THEN 1 END) AS Podiums,
    gp.Ano_Temporada AS Year
FROM Equipa e
INNER JOIN Piloto p ON e.ID_Equipa = p.ID_Equipa
INNER JOIN Resultados r ON p.ID_Piloto = r.ID_Piloto
INNER JOIN Grande_Prémio gp ON r.NomeGP = gp.NomeGP
WHERE r.NomeSessão = 'Race'
GROUP BY e.ID_Equipa, e.Nome, gp.Ano_Temporada
HAVING ISNULL(SUM(r.Pontos), 0) > 0;
GO

-- vw_Season_TeamPodium.sql
IF OBJECT_ID('vw_Season_TeamPodium', 'V') IS NOT NULL
    DROP VIEW vw_Season_TeamPodium;
GO
CREATE VIEW vw_Season_TeamPodium AS
SELECT 
    gp.Ano_Temporada AS Year,
    e.Nome AS TeamName,
    ISNULL(SUM(r.Pontos), 0) AS TotalPoints
FROM Grande_Prémio gp
INNER JOIN Resultados r ON r.NomeGP = gp.NomeGP
INNER JOIN Piloto p ON r.ID_Piloto = p.ID_Piloto
INNER JOIN Equipa e ON p.ID_Equipa = e.ID_Equipa
WHERE r.NomeSessão = 'Race'
GROUP BY gp.Ano_Temporada, e.ID_Equipa, e.Nome;
GO

-- vw_Season_GPCount.sql
IF OBJECT_ID('vw_Season_GPCount', 'V') IS NOT NULL
	DROP VIEW vw_Season_GPCount;
GO
CREATE VIEW vw_Season_GPCount AS
SELECT Ano_Temporada AS Year, COUNT(*) AS GPCount
FROM Grande_Prémio
GROUP BY Ano_Temporada;
GO

-- vw_Season_DriverStandings.sql
CREATE OR ALTER VIEW vw_Season_DriverStandings AS
SELECT 
    ROW_NUMBER() OVER (ORDER BY ISNULL(SUM(r.Pontos), 0) DESC, COUNT(CASE WHEN r.PosiçãoFinal = 1 THEN 1 END) DESC) AS Position,
    ISNULL(m.Nome, 'Unknown Driver') AS Driver,
    ISNULL(e.Nome, 'No Team') AS Team,
    ISNULL(SUM(r.Pontos), 0) AS TotalPoints,
    COUNT(CASE WHEN r.PosiçãoFinal = 1 THEN 1 END) AS Wins,
    COUNT(CASE WHEN r.PosiçãoFinal <= 3 THEN 1 END) AS Podiums,
    gp.Ano_Temporada AS Year
FROM Piloto p
INNER JOIN Membros_da_Equipa m ON p.ID_Membro = m.ID_Membro
INNER JOIN Equipa e ON p.ID_Equipa = e.ID_Equipa
INNER JOIN Resultados r ON p.ID_Piloto = r.ID_Piloto
INNER JOIN Grande_Prémio gp ON r.NomeGP = gp.NomeGP
WHERE r.NomeSessão = 'Race'
GROUP BY p.ID_Piloto, m.Nome, e.Nome, gp.Ano_Temporada
HAVING ISNULL(SUM(r.Pontos), 0) > 0;
GO

-- vw_Season_DriverPodium.sql
IF OBJECT_ID('vw_Season_DriverPodium', 'V') IS NOT NULL
    DROP VIEW vw_Season_DriverPodium;
GO
CREATE VIEW vw_Season_DriverPodium AS
SELECT 
    gp.Ano_Temporada AS Year,
    p.Abreviação,
    m.Nome AS DriverName,
    ISNULL(SUM(r.Pontos), 0) AS TotalPoints
FROM Grande_Prémio gp
INNER JOIN Resultados r ON r.NomeGP = gp.NomeGP
INNER JOIN Piloto p ON r.ID_Piloto = p.ID_Piloto
INNER JOIN Membros_da_Equipa m ON p.ID_Membro = m.ID_Membro
WHERE r.NomeSessão = 'Race'
GROUP BY gp.Ano_Temporada, p.ID_Piloto, p.Abreviação, m.Nome, p.NumeroPermanente;
GO

-- vw_Seasons_Overview.sql
CREATE OR ALTER VIEW vw_Seasons_Overview AS
SELECT 
    t.Ano,
    ISNULL(gp.GPCount, 0) AS NumCorridas,
    ld.DriverName AS LeaderDriver,
    lt.TeamName AS LeaderTeam
FROM Temporada t
LEFT JOIN (
    SELECT Ano_Temporada, COUNT(*) AS GPCount
    FROM Grande_Prémio
    GROUP BY Ano_Temporada
) gp ON t.Ano = gp.Ano_Temporada
OUTER APPLY (
    SELECT TOP 1
        m.Nome AS DriverName,
        SUM(r.Pontos) AS TotalPoints
    FROM Grande_Prémio gp2
    INNER JOIN Resultados r ON r.NomeGP = gp2.NomeGP
    INNER JOIN Piloto p ON r.ID_Piloto = p.ID_Piloto
    INNER JOIN Membros_da_Equipa m ON p.ID_Membro = m.ID_Membro
    WHERE gp2.Ano_Temporada = t.Ano AND r.NomeSessão = 'Race'
    GROUP BY m.Nome, p.NumeroPermanente
    ORDER BY TotalPoints DESC, p.NumeroPermanente ASC
) ld
OUTER APPLY (
    SELECT TOP 1
        e.Nome AS TeamName,
        SUM(r.Pontos) AS TotalPoints
    FROM Grande_Prémio gp3
    INNER JOIN Resultados r ON r.NomeGP = gp3.NomeGP
    INNER JOIN Piloto p ON r.ID_Piloto = p.ID_Piloto
    INNER JOIN Equipa e ON p.ID_Equipa = e.ID_Equipa
    WHERE gp3.Ano_Temporada = t.Ano AND r.NomeSessão = 'Race'
    GROUP BY e.Nome
    ORDER BY TotalPoints DESC, e.Nome ASC
) lt
GO

-- vw_Seasons.sql
CREATE OR ALTER VIEW vw_Seasons AS
SELECT Ano
FROM Temporada;
GO

-- vw_Results_Detailed.sql
CREATE OR ALTER VIEW vw_Results_Detailed AS
SELECT 
    r.ID_Resultado,
    r.PosiçãoGrid,
    r.TempoFinal,
    r.PosiçãoFinal,
    r.Status,
    r.Pontos,
    r.NomeSessão,
    r.ID_Piloto,
    p.NumeroPermanente,
    p.Abreviação AS DriverCode,
    m.Nome AS DriverName,
    e.Nome AS TeamName,
    ISNULL(r.NomeGP, s.NomeGP) AS GrandPrix
FROM Resultados r
INNER JOIN Piloto p ON r.ID_Piloto = p.ID_Piloto
LEFT JOIN Membros_da_Equipa m ON p.ID_Membro = m.ID_Membro
LEFT JOIN Equipa e ON p.ID_Equipa = e.ID_Equipa
LEFT JOIN Sessões s ON r.NomeSessão = s.NomeSessão 
    AND (r.NomeGP = s.NomeGP OR r.NomeGP IS NULL);
GO

-- vw_Qualification_Positions.sql
CREATE OR ALTER VIEW vw_Qualification_Positions AS
SELECT r.ID_Piloto, r.PosiçãoFinal, s.NomeSessão, s.NomeGP
FROM Resultados r
INNER JOIN Sessões s ON r.NomeSessão = s.NomeSessão AND (r.NomeGP = s.NomeGP OR r.NomeGP IS NULL)
WHERE s.NomeSessão IN ('Qualification', 'Sprint Qualification');
GO

-- vw_GrandPrixDetails.sql
CREATE OR ALTER VIEW vw_GrandPrixDetails AS
SELECT 
    gp.NomeGP,
    gp.DataCorrida,
    c.Nome AS Circuit,
    gp.ID_Circuito,
    gp.Ano_Temporada AS Season
FROM Grande_Prémio gp
INNER JOIN Circuito c ON gp.ID_Circuito = c.ID_Circuito;
GO

-- vw_GPList_BySeason.sql
CREATE OR ALTER VIEW vw_GPList_BySeason AS
SELECT 
    NomeGP AS [Grand Prix Name],
    DataCorrida AS [Race Date],
    Ano_Temporada AS Season
FROM Grande_Prémio;
GO

-- vw_GPList_ByCircuit.sql
CREATE OR ALTER VIEW vw_GPList_ByCircuit AS
SELECT 
    NomeGP AS [Grand Prix Name],
    DataCorrida AS [Race Date],
    Ano_Temporada AS Season,
    ID_Circuito
FROM Grande_Prémio;
GO

-- vw_Drivers_List.sql
CREATE OR ALTER VIEW vw_Drivers_List AS
SELECT p.ID_Piloto, p.NumeroPermanente, p.Abreviação, m.Nome AS DriverName, e.Nome AS Team
FROM Piloto p
LEFT JOIN Membros_da_Equipa m ON p.ID_Membro = m.ID_Membro
LEFT JOIN Equipa e ON p.ID_Equipa = e.ID_Equipa;
GO

-- vw_DriverPoints.sql
CREATE OR ALTER VIEW vw_DriverPoints AS
SELECT TOP 15
    p.Abreviação,
    m.Nome AS DriverName,
    e.Nome AS TeamName,
    ISNULL(SUM(r.Pontos), 0) AS TotalPoints
FROM Piloto p
INNER JOIN Membros_da_Equipa m ON p.ID_Membro = m.ID_Membro
LEFT JOIN Equipa e ON p.ID_Equipa = e.ID_Equipa
LEFT JOIN Resultados r ON p.ID_Piloto = r.ID_Piloto
GROUP BY p.Abreviação, m.Nome, p.NumeroPermanente, e.Nome
ORDER BY TotalPoints DESC, p.NumeroPermanente ASC;
GO

-- vw_DriverDetails.sql
CREATE OR ALTER VIEW vw_DriverDetails AS
SELECT 
    p.ID_Piloto,
    p.NumeroPermanente,
    p.Abreviação,
    p.ID_Equipa,
    e.Nome AS TeamName,
    p.ID_Membro,
    m.Nome AS DriverName
FROM Piloto p
LEFT JOIN Equipa e ON p.ID_Equipa = e.ID_Equipa
LEFT JOIN Membros_da_Equipa m ON p.ID_Membro = m.ID_Membro;
GO

-- vw_Circuits.sql
CREATE OR ALTER VIEW vw_Circuits AS
SELECT 
	ID_Circuito, 
	Nome, 
	Cidade, 
	Pais, 
	Comprimento_km, 
	NumCurvas
FROM Circuito;
GO

-- standings_views.sql
USE p3g9;
GO
IF OBJECT_ID('vw_DriverStandings', 'V') IS NOT NULL
    DROP VIEW vw_DriverStandings;
GO
CREATE VIEW vw_DriverStandings AS
SELECT 
    ROW_NUMBER() OVER (ORDER BY ISNULL(SUM(r.Pontos), 0) DESC, 
                                COUNT(DISTINCT CASE WHEN r.PosiçãoFinal = 1 THEN r.ID_Resultado END) DESC) AS Position,
    p.ID_Piloto,
    ISNULL(p.NumeroPermanente, 0) AS Number,
    ISNULL(p.Abreviação, '---') AS Code,
    ISNULL(m.Nome, 'Unknown Driver') AS DriverName,
    ISNULL(m.Nacionalidade, 'Unknown') AS Nationality,
    ISNULL(e.Nome, 'No Team') AS Team,
    ISNULL(SUM(r.Pontos), 0) AS TotalPoints,
    COUNT(DISTINCT CASE WHEN r.PosiçãoFinal = 1 THEN r.ID_Resultado END) AS Wins,
    COUNT(DISTINCT CASE WHEN r.PosiçãoFinal <= 3 THEN r.ID_Resultado END) AS Podiums,
    COUNT(DISTINCT CASE WHEN r.NomeSessão = 'Race' THEN r.ID_Resultado END) AS Races
FROM Piloto p
INNER JOIN Membros_da_Equipa m ON p.ID_Membro = m.ID_Membro
INNER JOIN Equipa e ON p.ID_Equipa = e.ID_Equipa
INNER JOIN Resultados r ON p.ID_Piloto = r.ID_Piloto
WHERE r.NomeSessão = 'Race'
GROUP BY p.ID_Piloto, p.NumeroPermanente, p.Abreviação, m.Nome, m.Nacionalidade, e.Nome
HAVING ISNULL(SUM(r.Pontos), 0) > 0;
GO
IF OBJECT_ID('vw_TeamStandings', 'V') IS NOT NULL
    DROP VIEW vw_TeamStandings;
GO
CREATE VIEW vw_TeamStandings AS
SELECT 
    ROW_NUMBER() OVER (ORDER BY ISNULL(SUM(r.Pontos), 0) DESC, 
                                COUNT(DISTINCT CASE WHEN r.PosiçãoFinal = 1 THEN r.ID_Resultado END) DESC) AS Position,
    e.ID_Equipa,
    e.Nome AS Team,
    ISNULL(e.Nacionalidade, 'Unknown') AS Nationality,
    COUNT(DISTINCT p.ID_Piloto) AS Drivers,
    ISNULL(SUM(r.Pontos), 0) AS TotalPoints,
    COUNT(DISTINCT CASE WHEN r.PosiçãoFinal = 1 THEN r.ID_Resultado END) AS Wins,
    COUNT(DISTINCT CASE WHEN r.PosiçãoFinal <= 3 THEN r.ID_Resultado END) AS Podiums
FROM Equipa e
INNER JOIN Piloto p ON e.ID_Equipa = p.ID_Equipa
INNER JOIN Resultados r ON p.ID_Piloto = r.ID_Piloto
WHERE r.NomeSessão = 'Race'
GROUP BY e.ID_Equipa, e.Nome, e.Nacionalidade
HAVING ISNULL(SUM(r.Pontos), 0) > 0;
GO
IF OBJECT_ID('vw_DriverStandingsBySeason', 'V') IS NOT NULL
    DROP VIEW vw_DriverStandingsBySeason;
GO
CREATE VIEW vw_DriverStandingsBySeason AS
SELECT 
    gp.Ano_Temporada AS Season,
    ROW_NUMBER() OVER (PARTITION BY gp.Ano_Temporada 
                       ORDER BY ISNULL(SUM(r.Pontos), 0) DESC, 
                                COUNT(CASE WHEN r.PosiçãoFinal = 1 THEN 1 END) DESC) AS Position,
    ISNULL(m.Nome, 'Unknown Driver') AS Driver,
    ISNULL(e.Nome, 'No Team') AS Team,
    ISNULL(SUM(r.Pontos), 0) AS TotalPoints,
    COUNT(CASE WHEN r.PosiçãoFinal = 1 THEN 1 END) AS Wins,
    COUNT(CASE WHEN r.PosiçãoFinal <= 3 THEN 1 END) AS Podiums
FROM Piloto p
INNER JOIN Membros_da_Equipa m ON p.ID_Membro = m.ID_Membro
INNER JOIN Equipa e ON p.ID_Equipa = e.ID_Equipa
INNER JOIN Resultados r ON p.ID_Piloto = r.ID_Piloto
INNER JOIN Grande_Prémio gp ON r.NomeGP = gp.NomeGP
WHERE r.NomeSessão = 'Race'
GROUP BY gp.Ano_Temporada, p.ID_Piloto, m.Nome, e.Nome
HAVING ISNULL(SUM(r.Pontos), 0) > 0;
GO
IF OBJECT_ID('vw_TeamStandingsBySeason', 'V') IS NOT NULL
    DROP VIEW vw_TeamStandingsBySeason;
GO
CREATE VIEW vw_TeamStandingsBySeason AS
SELECT 
    gp.Ano_Temporada AS Season,
    ROW_NUMBER() OVER (PARTITION BY gp.Ano_Temporada 
                       ORDER BY ISNULL(SUM(r.Pontos), 0) DESC, 
                                COUNT(CASE WHEN r.PosiçãoFinal = 1 THEN 1 END) DESC) AS Position,
    ISNULL(e.Nome, 'Unknown Team') AS Team,
    ISNULL(SUM(r.Pontos), 0) AS TotalPoints,
    COUNT(CASE WHEN r.PosiçãoFinal = 1 THEN 1 END) AS Wins,
    COUNT(CASE WHEN r.PosiçãoFinal <= 3 THEN 1 END) AS Podiums
FROM Equipa e
INNER JOIN Piloto p ON e.ID_Equipa = p.ID_Equipa
INNER JOIN Resultados r ON p.ID_Piloto = r.ID_Piloto
INNER JOIN Grande_Prémio gp ON r.NomeGP = gp.NomeGP
WHERE r.NomeSessão = 'Race'
GROUP BY gp.Ano_Temporada, e.ID_Equipa, e.Nome
HAVING ISNULL(SUM(r.Pontos), 0) > 0;
GO
PRINT 'Views de Standings criadas com sucesso!';
GO

-- season_views.sql
USE p3g9;
GO
IF OBJECT_ID('vw_SeasonSummary', 'V') IS NOT NULL
    DROP VIEW vw_SeasonSummary;
GO
CREATE VIEW vw_SeasonSummary AS
SELECT 
    t.Ano,
    ISNULL(gp.GPCount, 0) AS NumCorridas
FROM Temporada t
LEFT JOIN (
    SELECT Ano_Temporada, COUNT(*) AS GPCount
    FROM Grande_Prémio
    GROUP BY Ano_Temporada
) gp ON t.Ano = gp.Ano_Temporada;
GO
PRINT 'Views de Temporadas criadas com sucesso!';
GO

CREATE OR ALTER VIEW [dbo].[vw_Team_CareerPoints] AS
SELECT
    e.Nome AS TeamName,
    ISNULL(SUM(r.Pontos), 0) AS TotalPoints
FROM Equipa e
LEFT JOIN Piloto p ON e.ID_Equipa = p.ID_Equipa
LEFT JOIN Resultados r ON p.ID_Piloto = r.ID_Piloto
GROUP BY e.ID_Equipa, e.Nome;
GO
