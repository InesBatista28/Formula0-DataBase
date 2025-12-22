-- UDF: Calcular idade de um membro
IF OBJECT_ID('dbo.fn_CalculateAge', 'FN') IS NOT NULL
    DROP FUNCTION dbo.fn_CalculateAge;
GO

CREATE FUNCTION dbo.fn_CalculateAge(@BirthDate DATE)
RETURNS INT
AS
BEGIN
    DECLARE @Age INT;
    
    SET @Age = DATEDIFF(YEAR, @BirthDate, GETDATE()) - 
               CASE 
                   WHEN (MONTH(@BirthDate) > MONTH(GETDATE())) OR 
                        (MONTH(@BirthDate) = MONTH(GETDATE()) AND DAY(@BirthDate) > DAY(GETDATE()))
                   THEN 1 
                   ELSE 0 
               END;
    
    RETURN @Age;
END;
GO

PRINT 'UDF fn_CalculateAge criada com sucesso!';

-- UDF: Obter nome completo do piloto

IF OBJECT_ID('dbo.fn_GetDriverFullName', 'FN') IS NOT NULL
    DROP FUNCTION dbo.fn_GetDriverFullName;
GO

CREATE FUNCTION dbo.fn_GetDriverFullName(@DriverID INT)
RETURNS NVARCHAR(100)
AS
BEGIN
    DECLARE @FullName NVARCHAR(100);
    
    SELECT @FullName = m.Nome
    FROM Piloto p
    INNER JOIN Membros_da_Equipa m ON p.ID_Membro = m.ID_Membro
    WHERE p.ID_Piloto = @DriverID;
    
    RETURN ISNULL(@FullName, 'Unknown');
END;
GO

PRINT 'UDF fn_GetDriverFullName criada com sucesso!';

-- UDF: Obter total de pontos de um piloto


IF OBJECT_ID('dbo.fn_GetDriverTotalPoints', 'FN') IS NOT NULL
    DROP FUNCTION dbo.fn_GetDriverTotalPoints;
GO

CREATE FUNCTION dbo.fn_GetDriverTotalPoints(@DriverID INT)
RETURNS INT
AS
BEGIN
    DECLARE @TotalPoints INT;
    
    SELECT @TotalPoints = ISNULL(SUM(r.Pontos), 0)
    FROM Resultados r
    WHERE r.ID_Piloto = @DriverID AND r.NomeSessão = 'Race';
    
    RETURN @TotalPoints;
END;
GO

PRINT 'UDF fn_GetDriverTotalPoints criada com sucesso!';

-- Obter total de vitórias de um piloto


IF OBJECT_ID('dbo.fn_GetDriverWins', 'FN') IS NOT NULL
    DROP FUNCTION dbo.fn_GetDriverWins;
GO

CREATE FUNCTION dbo.fn_GetDriverWins(@DriverID INT)
RETURNS INT
AS
BEGIN
    DECLARE @Wins INT;
    
    SELECT @Wins = COUNT(*)
    FROM Resultados r
    WHERE r.ID_Piloto = @DriverID 
      AND r.NomeSessão = 'Race' 
      AND r.PosiçãoFinal = 1;
    
    RETURN @Wins;
END;
GO

PRINT 'UDF fn_GetDriverWins criada com sucesso!';

-- Verificar se um piloto está ativo (tem resultados recentes)


IF OBJECT_ID('dbo.fn_IsDriverActive', 'FN') IS NOT NULL
    DROP FUNCTION dbo.fn_IsDriverActive;
GO

CREATE FUNCTION dbo.fn_IsDriverActive(@DriverID INT)
RETURNS BIT
AS
BEGIN
    DECLARE @IsActive BIT = 0;
    
    IF EXISTS (
        SELECT 1 
        FROM Resultados r
        INNER JOIN Grande_Prémio gp ON r.NomeGP = gp.NomeGP
        WHERE r.ID_Piloto = @DriverID 
          AND gp.Ano_Temporada >= YEAR(GETDATE()) - 1
    )
        SET @IsActive = 1;
    
    RETURN @IsActive;
END;
GO

PRINT 'UDF fn_IsDriverActive criada com sucesso!';
