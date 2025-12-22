CREATE  OR ALTER PROCEDURE sp_AuthenticateStaff
    @StaffID INT,
    @Password NVARCHAR(100)
AS
BEGIN
    SELECT COUNT(1) AS IsValid
    FROM Staff
    WHERE StaffID = @StaffID AND Password = @Password;
END

-- 

CREATE OR ALTER PROCEDURE sp_DeleteCircuit
    @ID_Circuito INT
AS
BEGIN
    SET NOCOUNT ON;
    DELETE FROM Circuito WHERE ID_Circuito = @ID_Circuito;
END

--
CREATE OR ALTER PROCEDURE sp_DeleteDriver
    @ID_Piloto INT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        DELETE FROM Pitstop WHERE ID_Piloto = @ID_Piloto;
        DELETE FROM Penalizações WHERE ID_Piloto = @ID_Piloto;
        DELETE FROM Resultados WHERE ID_Piloto = @ID_Piloto;

        DELETE FROM Piloto WHERE ID_Piloto = @ID_Piloto;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH
END

--

CREATE OR ALTER PROCEDURE sp_DeleteGrandPrix
    @NomeGP NVARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        DELETE FROM Pitstop WHERE NomeGP = @NomeGP;
        DELETE FROM Penalizações WHERE NomeGP = @NomeGP;
        DELETE FROM Resultados WHERE NomeGP = @NomeGP;
        DELETE FROM Sessões WHERE NomeGP = @NomeGP;

        DELETE FROM Grande_Prémio WHERE NomeGP = @NomeGP;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        DECLARE @ErrMsg NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrState INT = ERROR_STATE();
        RAISERROR(@ErrMsg, @ErrSeverity, @ErrState);
    END CATCH
END
--
IF OBJECT_ID('sp_DeleteResult', 'P') IS NOT NULL
DROP PROCEDURE sp_DeleteResult;
GO
CREATE PROCEDURE sp_DeleteResult
    @ID_Resultado INT
AS
BEGIN
    DELETE FROM Resultados WHERE ID_Resultado = @ID_Resultado
END
GO

--
-- DELETE Sessão
GO
CREATE OR ALTER PROCEDURE sp_DeleteSessao
    @NomeSessao NVARCHAR(100),
    @NomeGP NVARCHAR(100)
AS
BEGIN
    DELETE FROM Sessões WHERE NomeSessão = @NomeSessao AND NomeGP = @NomeGP
END
GO

--
IF OBJECT_ID('sp_DeleteSession', 'P') IS NOT NULL
    DROP PROCEDURE sp_DeleteSession;
GO
CREATE PROCEDURE sp_DeleteSession
    @NomeSessao NVARCHAR(100),
    @NomeGP NVARCHAR(100)
AS
BEGIN
    DELETE FROM Sessões WHERE NomeSessão = @NomeSessao AND NomeGP = @NomeGP
END
GO

--
CREATE OR ALTER PROCEDURE sp_DeleteStaff
    @StaffID INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @ID_Membro INT;

    -- Tentar mapear o Staff para o membro correspondente
    SELECT TOP 1 @ID_Membro = m.ID_Membro
    FROM Staff s
    LEFT JOIN Membros_da_Equipa m ON m.Nome = s.NomeCompleto
    WHERE s.StaffID = @StaffID;

    BEGIN TRY
        BEGIN TRANSACTION;

        IF @ID_Membro IS NOT NULL
        BEGIN
            EXEC sp_DeleteTeamMember @ID_Membro;
        END

        DELETE FROM Staff WHERE StaffID = @StaffID;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH
END;

--
IF OBJECT_ID('sp_DeleteTeamGrid', 'P') IS NOT NULL
    DROP PROCEDURE sp_DeleteTeamGrid;
GO
CREATE PROCEDURE sp_DeleteTeamGrid
    @ID_Equipa INT
AS
BEGIN
    DELETE FROM Equipa WHERE ID_Equipa = @ID_Equipa;
END;
--
CREATE OR ALTER PROCEDURE sp_DeleteTeamMember
    @ID_Membro INT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        DECLARE @PilotId INT;
        SELECT @PilotId = ID_Piloto FROM Piloto WHERE ID_Membro = @ID_Membro;

        IF @PilotId IS NOT NULL
        BEGIN
            -- Apagar tudo o que referencia o piloto antes de remover o registo do piloto
            DELETE FROM Pitstop WHERE ID_Piloto = @PilotId;
            DELETE FROM Penalizações WHERE ID_Piloto = @PilotId;
            DELETE FROM Resultados WHERE ID_Piloto = @PilotId;
            DELETE FROM Piloto WHERE ID_Piloto = @PilotId;
        END

        DELETE FROM Contrato WHERE ID_Membro = @ID_Membro;
        DELETE FROM Membros_da_Equipa WHERE ID_Membro = @ID_Membro;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH
END

--
IF OBJECT_ID('sp_GetContractDetails', 'P') IS NOT NULL
    DROP PROCEDURE sp_GetContractDetails;
GO
CREATE PROCEDURE sp_GetContractDetails
    @ContractID INT
AS
BEGIN
    SELECT c.*, m.Nome, m.Nacionalidade
    FROM Contrato c
    INNER JOIN Membros_da_Equipa m ON c.ID_Membro = m.ID_Membro
    WHERE c.ID_Contrato = @ContractID;
END;

-- SP: Get Driver Standings for a specific season


IF OBJECT_ID('sp_GetDriverStandingsBySeason', 'P') IS NOT NULL
    DROP PROCEDURE sp_GetDriverStandingsBySeason;
GO

CREATE PROCEDURE sp_GetDriverStandingsBySeason
    @Season INT
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        ROW_NUMBER() OVER (ORDER BY ISNULL(SUM(r.Pontos), 0) DESC, 
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
    WHERE r.NomeSessão = 'Race' AND gp.Ano_Temporada = @Season
    GROUP BY p.ID_Piloto, m.Nome, e.Nome
    HAVING ISNULL(SUM(r.Pontos), 0) > 0
    ORDER BY TotalPoints DESC, Wins DESC;
END;
GO

PRINT 'Stored Procedure sp_GetDriverStandingsBySeason criada com sucesso!';
--
CREATE OR ALTER PROCEDURE sp_GetTeamCareerPoints
AS
BEGIN
    SELECT * FROM vw_Team_CareerPoints ORDER BY TotalPoints DESC, TeamName ASC;
END

-- SP: Get Team Standings for a specific season


IF OBJECT_ID('sp_GetTeamStandingsBySeason', 'P') IS NOT NULL
    DROP PROCEDURE sp_GetTeamStandingsBySeason;
GO

CREATE PROCEDURE sp_GetTeamStandingsBySeason
    @Season INT
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        ROW_NUMBER() OVER (ORDER BY ISNULL(SUM(r.Pontos), 0) DESC, 
                                    COUNT(CASE WHEN r.PosiçãoFinal = 1 THEN 1 END) DESC) AS Position,
        e.Nome AS Team,
        ISNULL(SUM(r.Pontos), 0) AS TotalPoints,
        COUNT(CASE WHEN r.PosiçãoFinal = 1 THEN 1 END) AS Wins,
        COUNT(CASE WHEN r.PosiçãoFinal <= 3 THEN 1 END) AS Podiums
    FROM Equipa e
    INNER JOIN Piloto p ON e.ID_Equipa = p.ID_Equipa
    INNER JOIN Resultados r ON p.ID_Piloto = r.ID_Piloto
    INNER JOIN Grande_Prémio gp ON r.NomeGP = gp.NomeGP
    WHERE r.NomeSessão = 'Race' AND gp.Ano_Temporada = @Season
    GROUP BY e.ID_Equipa, e.Nome
    HAVING ISNULL(SUM(r.Pontos), 0) > 0
    ORDER BY TotalPoints DESC, Wins DESC;
END;
GO

PRINT 'Stored Procedure sp_GetTeamStandingsBySeason criada com sucesso!';


--
CREATE  OR ALTER PROCEDURE sp_InsertCircuit
    @Nome NVARCHAR(100),
    @Cidade NVARCHAR(100),
    @Pais NVARCHAR(100),
    @Comprimento_km FLOAT,
    @NumCurvas INT,
    @ID_Circuito INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO Circuito (Nome, Cidade, Pais, Comprimento_km, NumCurvas)
    VALUES (@Nome, @Cidade, @Pais, @Comprimento_km, @NumCurvas);
    SET @ID_Circuito = SCOPE_IDENTITY();
END
--
IF OBJECT_ID('sp_InsertContract', 'P') IS NOT NULL
    DROP PROCEDURE sp_InsertContract;
GO
CREATE PROCEDURE sp_InsertContract
    @AnoInicio INT,
    @AnoFim INT = NULL,
    @Funcao NVARCHAR(100) = NULL,
    @Salario DECIMAL(18,2),
    @Genero NVARCHAR(10) = NULL,
    @ID_Membro INT
AS
BEGIN
    INSERT INTO Contrato (AnoInicio, AnoFim, Função, Salário, Género, ID_Membro)
    VALUES (@AnoInicio, @AnoFim, @Funcao, @Salario, @Genero, @ID_Membro);
END;
--
CREATE  OR ALTER PROCEDURE sp_InsertDriver
    @NumeroPermanente INT,
    @Abreviacao NVARCHAR(3),
    @ID_Equipa INT,
    @ID_Membro INT
AS
BEGIN
    INSERT INTO Piloto (NumeroPermanente, Abreviação, ID_Equipa, ID_Membro)
    VALUES (@NumeroPermanente, @Abreviacao, @ID_Equipa, @ID_Membro);
END
--

CREATE  OR ALTER PROCEDURE sp_InsertGrandPrix
    @NomeGP NVARCHAR(100),
    @DataCorrida DATE,
    @ID_Circuito INT,
    @Season INT
AS
BEGIN
    INSERT INTO Grande_Prémio (NomeGP, DataCorrida, ID_Circuito, Ano_Temporada)
    VALUES (@NomeGP, @DataCorrida, @ID_Circuito, @Season);
END
--
IF OBJECT_ID('sp_InsertOrGetMember', 'P') IS NOT NULL
    DROP PROCEDURE sp_InsertOrGetMember;
GO
CREATE PROCEDURE sp_InsertOrGetMember
    @Nome NVARCHAR(100),
    @Nacionalidade NVARCHAR(100) = NULL,
    @DataNascimento DATE = NULL,
    @Genero NVARCHAR(10) = NULL,
    @Funcao NVARCHAR(100) = NULL,
    @ID_Equipa INT = NULL,
    @ID_Membro INT OUTPUT
AS
BEGIN
    IF (@Funcao = 'Driver' AND @ID_Equipa IS NULL)
    BEGIN
        ;THROW 50001, 'Para criar um Driver tem de indicar a equipa (ID_Equipa).', 1;
    END

    IF NOT EXISTS (SELECT 1 FROM Membros_da_Equipa WHERE Nome = @Nome)
    BEGIN
        INSERT INTO Membros_da_Equipa (Nome, Nacionalidade, DataNascimento, Género, Função, ID_Equipa)
        VALUES (@Nome, @Nacionalidade, @DataNascimento, @Genero, @Funcao, @ID_Equipa);
    END
    ELSE
    BEGIN
        UPDATE Membros_da_Equipa
        SET Nacionalidade = COALESCE(@Nacionalidade, Nacionalidade),
            DataNascimento = COALESCE(@DataNascimento, DataNascimento),
            Género = COALESCE(@Genero, Género),
            Função = COALESCE(@Funcao, Função),
            ID_Equipa = COALESCE(@ID_Equipa, ID_Equipa)
        WHERE Nome = @Nome;
    END

    SELECT @ID_Membro = ID_Membro FROM Membros_da_Equipa WHERE Nome = @Nome;
END;

--
CREATE  OR ALTER PROCEDURE sp_InsertResult
    @PosicaoGrid INT,
    @TempoFinal TIME = NULL,
    @PosicaoFinal INT,
    @Status NVARCHAR(50),
    @Pontos DECIMAL(10,2),
    @NomeSessao NVARCHAR(100),
    @NomeGP NVARCHAR(100),
    @ID_Piloto INT
AS
BEGIN
    INSERT INTO Resultados (PosiçãoGrid, TempoFinal, PosiçãoFinal, Status, Pontos, NomeSessão, NomeGP, ID_Piloto)
    VALUES (@PosicaoGrid, @TempoFinal, @PosicaoFinal, @Status, @Pontos, @NomeSessao, @NomeGP, @ID_Piloto)
END
GO

--
-- INSERT Sessão
GO
CREATE OR ALTER PROCEDURE sp_InsertSessao
    @NomeSessao NVARCHAR(100),
    @Estado NVARCHAR(50),
    @CondicoesPista NVARCHAR(50),
    @NomeGP NVARCHAR(100)
AS
BEGIN
    INSERT INTO Sessões (NomeSessão, Estado, CondiçõesPista, NomeGP)
    VALUES (@NomeSessao, @Estado, @CondicoesPista, @NomeGP)
END
GO
--

IF OBJECT_ID('sp_InsertSession', 'P') IS NOT NULL
    DROP PROCEDURE sp_InsertSession;
GO
CREATE PROCEDURE sp_InsertSession
    @NomeSessao NVARCHAR(100),
    @Estado NVARCHAR(50),
    @CondicoesPista NVARCHAR(100),
    @NomeGP NVARCHAR(100)
AS
BEGIN
    INSERT INTO Sessões (NomeSessão, Estado, CondiçõesPista, NomeGP)
    VALUES (@NomeSessao, @Estado, @CondicoesPista, @NomeGP)
END
GO

--
IF OBJECT_ID('sp_InsertStaff', 'P') IS NOT NULL
    DROP PROCEDURE sp_InsertStaff;
GO
CREATE PROCEDURE sp_InsertStaff
    @Username NVARCHAR(50),
    @Password NVARCHAR(50),
    @NomeCompleto NVARCHAR(100),
AS
BEGIN
    INSERT INTO Staff (Username, Password, NomeCompleto)
    VALUES (@Username, @Password, @NomeCompleto);
END;
--
IF OBJECT_ID('sp_InsertTeamGrid', 'P') IS NOT NULL
    DROP PROCEDURE sp_InsertTeamGrid;
GO
CREATE PROCEDURE sp_InsertTeamGrid
    @Nome NVARCHAR(100),
    @Nacionalidade NVARCHAR(100),
    @AnoEstreia INT
AS
BEGIN
    INSERT INTO Equipa (Nome, Nacionalidade, Base, ChefeEquipa, ChefeTécnico, AnoEstreia, ModeloChassis, Power_Unit)
    VALUES (@Nome, @Nacionalidade, 'TBD', 'TBD', 'TBD', @AnoEstreia, 'TBD', 'TBD');
END;
--
CREATE  OR ALTER PROCEDURE sp_InsertTeamMember
    @Nome NVARCHAR(100),
    @Nacionalidade NVARCHAR(100),
    @DataNascimento DATE,
    @Genero NVARCHAR(1),
    @ID_Equipa INT,
    @ID_Membro INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO Membros_da_Equipa (Nome, Nacionalidade, DataNascimento, Género, Função, ID_Equipa)
    VALUES (@Nome, @Nacionalidade, @DataNascimento, @Genero, 'Driver', @ID_Equipa);
    
    SET @ID_Membro = SCOPE_IDENTITY();
END

--
CREATE  OR ALTER PROCEDURE sp_UpdateCircuit
    @ID_Circuito INT,
    @Nome NVARCHAR(100),
    @Cidade NVARCHAR(100),
    @Pais NVARCHAR(100),
    @Comprimento_km FLOAT,
    @NumCurvas INT
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE Circuito
    SET Nome = @Nome,
        Cidade = @Cidade,
        Pais = @Pais,
        Comprimento_km = @Comprimento_km,
        NumCurvas = @NumCurvas
    WHERE ID_Circuito = @ID_Circuito;
END

--
IF OBJECT_ID('sp_UpdateContract', 'P') IS NOT NULL
    DROP PROCEDURE sp_UpdateContract;
GO
CREATE PROCEDURE sp_UpdateContract
    @ContractID INT,
    @AnoInicio INT,
    @AnoFim INT = NULL,
    @Funcao NVARCHAR(100) = NULL,
    @Salario DECIMAL(18,2),
    @Genero NVARCHAR(10) = NULL
AS
BEGIN
    UPDATE Contrato 
    SET AnoInicio = @AnoInicio, 
        AnoFim = @AnoFim, 
        Função = @Funcao, 
        Salário = @Salario, 
        Género = @Genero
    WHERE ID_Contrato = @ContractID;
END;
--
CREATE  OR ALTER PROCEDURE sp_UpdateDriver
    @ID_Piloto INT,
    @NumeroPermanente INT,
    @Abreviacao NVARCHAR(3),
    @ID_Equipa INT,
    @ID_Membro INT
AS
BEGIN
    UPDATE Piloto
    SET NumeroPermanente = @NumeroPermanente,
        Abreviação = @Abreviacao,
        ID_Equipa = @ID_Equipa,
        ID_Membro = @ID_Membro
    WHERE ID_Piloto = @ID_Piloto;
END
--

CREATE OR ALTER PROCEDURE sp_UpdateGrandPrix
    @NomeGP NVARCHAR(100),
    @DataCorrida DATE,
    @ID_Circuito INT,
    @Season INT
AS
BEGIN
    UPDATE Grande_Prémio
    SET DataCorrida = @DataCorrida,
        ID_Circuito = @ID_Circuito,
        Ano_Temporada = @Season
    WHERE NomeGP = @NomeGP;
END
--
CREATE OR ALTER PROCEDURE sp_UpdateResult
    @ID_Resultado INT,
    @PosicaoGrid INT,
    @TempoFinal TIME = NULL,
    @PosicaoFinal INT,
    @Status NVARCHAR(50),
    @Pontos DECIMAL(10,2),
    @NomeGP NVARCHAR(100),
    @ID_Piloto INT
AS
BEGIN
    UPDATE Resultados
    SET PosiçãoGrid = @PosicaoGrid,
        TempoFinal = @TempoFinal,
        PosiçãoFinal = @PosicaoFinal,
        Status = @Status,
        Pontos = @Pontos,
        NomeGP = @NomeGP,
        ID_Piloto = @ID_Piloto
    WHERE ID_Resultado = @ID_Resultado
END
GO

--
IF OBJECT_ID('sp_UpdateSession', 'P') IS NOT NULL
    DROP PROCEDURE sp_UpdateSession;
GO
CREATE PROCEDURE sp_UpdateSession
    @NomeSessao NVARCHAR(100),
    @Estado NVARCHAR(50),
    @CondicoesPista NVARCHAR(100),
    @NomeGP NVARCHAR(100)
AS
BEGIN
    UPDATE Sessões
    SET Estado = @Estado,
        CondiçõesPista = @CondicoesPista
    WHERE NomeSessão = @NomeSessao AND NomeGP = @NomeGP
END
GO

--
IF OBJECT_ID('sp_UpdateStaff', 'P') IS NOT NULL
    DROP PROCEDURE sp_UpdateStaff;
GO
CREATE PROCEDURE sp_UpdateStaff
    @StaffID INT,
    @Username NVARCHAR(50),
    @Password NVARCHAR(50),
    @NomeCompleto NVARCHAR(100),
AS
BEGIN
    UPDATE Staff 
    SET Username = @Username, 
        Password = @Password, 
        NomeCompleto = @NomeCompleto,
    WHERE StaffID = @StaffID;
END;
--
IF OBJECT_ID('sp_UpdateTeamDetails', 'P') IS NOT NULL
    DROP PROCEDURE sp_UpdateTeamDetails;
GO
CREATE PROCEDURE sp_UpdateTeamDetails
    @ID_Equipa INT,
    @Nome NVARCHAR(100),
    @Nacionalidade NVARCHAR(100) = NULL,
    @Base NVARCHAR(100) = NULL,
    @ChefeEquipa NVARCHAR(100) = NULL,
    @ChefeTécnico NVARCHAR(100) = NULL,
    @AnoEstreia INT = NULL,
    @ModeloChassis NVARCHAR(100) = NULL,
    @Power_Unit NVARCHAR(100) = NULL,
    @PilotosReserva NVARCHAR(100) = NULL
AS
BEGIN
    UPDATE Equipa SET
        Nome = @Nome,
        Nacionalidade = @Nacionalidade,
        Base = @Base,
        ChefeEquipa = @ChefeEquipa,
        ChefeTécnico = @ChefeTécnico,
        AnoEstreia = @AnoEstreia,
        ModeloChassis = @ModeloChassis,
        Power_Unit = @Power_Unit,
        PilotosReserva = @PilotosReserva
    WHERE ID_Equipa = @ID_Equipa;
END;
--
IF OBJECT_ID('sp_UpdateTeamGrid', 'P') IS NOT NULL
    DROP PROCEDURE sp_UpdateTeamGrid;
GO
CREATE PROCEDURE sp_UpdateTeamGrid
    @ID_Equipa INT,
    @Nome NVARCHAR(100),
    @Nacionalidade NVARCHAR(100),
    @AnoEstreia INT
AS
BEGIN
    UPDATE Equipa SET
        Nome = @Nome,
        Nacionalidade = @Nacionalidade,
        AnoEstreia = @AnoEstreia
    WHERE ID_Equipa = @ID_Equipa;
END;
--
CREATE OR ALTER PROCEDURE sp_UpdateTeamMember
    @ID_Membro INT,
    @Nome NVARCHAR(100),
    @Nacionalidade NVARCHAR(100),
    @DataNascimento DATE,
    @Género NVARCHAR(10),
    @Função NVARCHAR(100),
    @ID_Equipa INT
AS
BEGIN
    UPDATE Membros_da_Equipa
    SET Nome = @Nome,
        Nacionalidade = @Nacionalidade,
        DataNascimento = @DataNascimento,
        Género = @Género,
        Função = @Função,
        ID_Equipa = @ID_Equipa
    WHERE ID_Membro = @ID_Membro;
END

--