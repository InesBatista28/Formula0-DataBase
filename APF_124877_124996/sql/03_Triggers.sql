--AutoInsertDriver
CREATE OR ALTER PROCEDURE sp_AddDriver
    @Nome NVARCHAR(100),
    @Nacionalidade NVARCHAR(100),
    @DataNascimento DATE,
    @Género CHAR(1),
    @ID_Equipa INT,
    @NumeroPermanente INT,
    @Abreviação CHAR(3)
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @ID_Membro INT;
    
    BEGIN TRANSACTION;
    BEGIN TRY
        INSERT INTO Membros_da_Equipa (Nome, Nacionalidade, DataNascimento, Género, Função, ID_Equipa)
        VALUES (@Nome, @Nacionalidade, @DataNascimento, @Género, 'Driver', @ID_Equipa);
        
        SET @ID_Membro = SCOPE_IDENTITY();
        
        INSERT INTO Piloto (NumeroPermanente, Abreviação, ID_Equipa, ID_Membro)
        VALUES (@NumeroPermanente, @Abreviação, @ID_Equipa, @ID_Membro);
        
        COMMIT TRANSACTION;
        
        PRINT 'Piloto ' + @Nome + ' inserido com sucesso! (ID_Membro: ' + CAST(@ID_Membro AS NVARCHAR) + ')';
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        THROW 50000, @ErrorMessage, 1;
    END CATCH
END;
GO

--UpdateSeasonRaceCount

IF OBJECT_ID('trg_UpdateSeasonRaceCount', 'TR') IS NOT NULL
    DROP TRIGGER trg_UpdateSeasonRaceCount;
GO

CREATE OR ALTER TRIGGER trg_UpdateSeasonRaceCount
ON Grande_Prémio
AFTER INSERT, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE t
    SET t.NumCorridas = (
        SELECT COUNT(*) 
        FROM Grande_Prémio gp 
        WHERE gp.Ano_Temporada = t.Ano
    )
    FROM Temporada t
    WHERE t.Ano IN (
        SELECT DISTINCT Ano_Temporada FROM inserted
        UNION
        SELECT DISTINCT Ano_Temporada FROM deleted
    );
END;
GO

PRINT 'Trigger trg_UpdateSeasonRaceCount criado com sucesso!';


-- Block without active contract
IF OBJECT_ID('trg_BlockResultWithoutActiveContract', 'TR') IS NOT NULL
    DROP TRIGGER trg_BlockResultWithoutActiveContract;
GO

CREATE TRIGGER trg_BlockResultWithoutActiveContract
ON Resultados
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @violations INT = 0;

    ;WITH i AS (
        SELECT ID_Resultado, NomeGP, NomeSessão, ID_Piloto
        FROM inserted
    ),
    gp AS (
        SELECT i.ID_Resultado, gp.DataCorrida
        FROM i
        JOIN Grande_Prémio gp ON gp.NomeGP = i.NomeGP
    ),
    pilot AS (
        SELECT i.ID_Resultado, m.ID_Membro, m.Função
        FROM i
        JOIN Piloto p ON p.ID_Piloto = i.ID_Piloto
        JOIN Membros_da_Equipa m ON m.ID_Membro = p.ID_Membro
    ),
    active_contract AS (
        SELECT p.ID_Resultado
        FROM pilot p
        JOIN gp g ON g.ID_Resultado = p.ID_Resultado
        JOIN Contrato c ON c.ID_Membro = p.ID_Membro
        WHERE p.Função = 'Driver'
          AND YEAR(g.DataCorrida) BETWEEN c.AnoInicio AND ISNULL(c.AnoFim, YEAR(g.DataCorrida))
    )

    SELECT @violations = COUNT(*)
    FROM i src
    WHERE NOT EXISTS (
        SELECT 1 FROM active_contract ac WHERE ac.ID_Resultado = src.ID_Resultado
    );

    IF (@violations > 0)
    BEGIN
        RAISERROR('Result blocked: Driver has no active contract for this GP date.', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END
END;
GO

PRINT 'Trigger trg_BlockResultWithoutActiveContract criado com sucesso!';

--Validate Race Date

IF OBJECT_ID('trg_ValidateRaceDate', 'TR') IS NOT NULL
    DROP TRIGGER trg_ValidateRaceDate;
GO

CREATE TRIGGER trg_ValidateRaceDate
ON Grande_Prémio
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    
    IF EXISTS (
        SELECT 1 FROM inserted 
        WHERE DataCorrida > DATEADD(YEAR, 2, GETDATE())
    )
    BEGIN
        RAISERROR('A data da corrida não pode ser mais de 2 anos no futuro!', 16, 1);
        ROLLBACK TRANSACTION;
    END
END;
GO

PRINT 'Trigger trg_ValidateRaceDate criado com sucesso!';


--Validate Result Points

IF OBJECT_ID('trg_ValidateResultPoints', 'TR') IS NOT NULL
    DROP TRIGGER trg_ValidateResultPoints;
GO

CREATE TRIGGER trg_ValidateResultPoints
ON Resultados
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    
    IF EXISTS (SELECT 1 FROM inserted WHERE Pontos < 0)
    BEGIN
        RAISERROR('Os pontos não podem ser negativos!', 16, 1);
        ROLLBACK TRANSACTION;
    END
    
    IF EXISTS (SELECT 1 FROM inserted WHERE PosiçãoFinal < 0)
    BEGIN
        RAISERROR('A posição final não pode ser negativa!', 16, 1);
        ROLLBACK TRANSACTION;
    END
END;
GO

PRINT 'Trigger trg_ValidateResultPoints criado com sucesso!';


