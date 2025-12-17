/*
 * Trigger: trg_AutoInsertDriver
 * Descrição: Automaticamente insere um registo na tabela Piloto quando um membro 
 *            da equipa é inserido com a função 'Driver'.
 * 
 * Nota: O número permanente e abreviação devem ser fornecidos através de uma 
 *       tabela temporária ou stored procedure, ou inseridos manualmente depois.
 *       Este trigger cria apenas a estrutura básica.
 */

-- Versão 1: Trigger básico (requer insert manual posterior na tabela Piloto para NumeroPermanente e Abreviação)
-- Esta versão apenas demonstra o conceito mas tem limitações práticas

/*
CREATE OR ALTER TRIGGER trg_AutoInsertDriver
ON Membros_da_Equipa
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Insere na tabela Piloto apenas para membros com função 'Driver'
    INSERT INTO Piloto (NumeroPermanente, Abreviação, ID_Equipa, ID_Membro)
    SELECT 
        0, -- Placeholder - precisa ser atualizado manualmente
        'TBD', -- Placeholder - precisa ser atualizado manualmente  
        i.ID_Equipa,
        i.ID_Membro
    FROM inserted i
    WHERE i.Função = 'Driver';
    
    IF @@ROWCOUNT > 0
    BEGIN
        PRINT 'Aviso: Piloto(s) inserido(s) com NumeroPermanente=0 e Abreviação=TBD. Por favor, atualizar!';
    END
END;
GO
*/

-- Versão 2: Melhor abordagem usando Stored Procedure
-- Esta SP permite fornecer todos os dados necessários numa única operação

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
        -- 1. Inserir em Membros_da_Equipa
        INSERT INTO Membros_da_Equipa (Nome, Nacionalidade, DataNascimento, Género, Função, ID_Equipa)
        VALUES (@Nome, @Nacionalidade, @DataNascimento, @Género, 'Driver', @ID_Equipa);
        
        SET @ID_Membro = SCOPE_IDENTITY();
        
        -- 2. Inserir automaticamente em Piloto
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

-- Exemplo de uso:
/*
EXEC sp_AddDriver 
    @Nome = 'Max Verstappen',
    @Nacionalidade = 'Dutch',
    @DataNascimento = '1997-09-30',
    @Género = 'M',
    @ID_Equipa = 4,
    @NumeroPermanente = 1,
    @Abreviação = 'VER';
*/
