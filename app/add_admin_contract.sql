-- Script para adicionar contrato ao Staff admin existente
-- Execute este script no Azure Data Studio conectado à base de dados p3g9

USE p3g9;
GO

-- Primeiro, garantir que existe uma "equipa" administrativa para staff
DECLARE @AdminTeamID INT;

-- Verificar se existe uma equipa administrativa
SELECT @AdminTeamID = ID_Equipa 
FROM Equipa 
WHERE Nome = 'Administration' OR Nome = 'Administrative Staff';

-- Se não existir, criar uma equipa administrativa
IF @AdminTeamID IS NULL
BEGIN
    -- Pegar qualquer equipa existente como fallback
    SELECT TOP 1 @AdminTeamID = ID_Equipa FROM Equipa ORDER BY ID_Equipa;
    
    -- Se ainda não houver equipas, criar uma
    IF @AdminTeamID IS NULL
    BEGIN
        INSERT INTO Equipa (Nome, Nacionalidade)
        VALUES ('Administrative Staff', 'International');
        SET @AdminTeamID = SCOPE_IDENTITY();
        PRINT 'Equipa administrativa criada com ID: ' + CAST(@AdminTeamID AS VARCHAR(10));
    END
    ELSE
    BEGIN
        PRINT 'Usando equipa existente com ID: ' + CAST(@AdminTeamID AS VARCHAR(10));
    END
END
ELSE
BEGIN
    PRINT 'Equipa administrativa já existe com ID: ' + CAST(@AdminTeamID AS VARCHAR(10));
END

-- Agora, verificar se o admin existe e obter/criar o ID_Membro
DECLARE @AdminName NVARCHAR(100) = 'Maria'; -- Ajustar para o NomeCompleto do admin
DECLARE @MemberID INT;

-- Verificar se já existe um membro com este nome
SELECT @MemberID = ID_Membro 
FROM Membros_da_Equipa 
WHERE Nome = @AdminName;

-- Se não existir, criar o membro
IF @MemberID IS NULL
BEGIN
    -- Inserir em Membros_da_Equipa com ID_Equipa da equipa administrativa
    INSERT INTO Membros_da_Equipa (Nome, Nacionalidade, DataNascimento, Género, Função, ID_Equipa)
    VALUES (@AdminName, 'Portugal', '1990-01-01', 'F', 'Administrator', @AdminTeamID);
    
    SET @MemberID = SCOPE_IDENTITY();
    PRINT 'Membro criado com ID: ' + CAST(@MemberID AS VARCHAR(10));
END
ELSE
BEGIN
    PRINT 'Membro já existe com ID: ' + CAST(@MemberID AS VARCHAR(10));
END

-- Verificar se já existe contrato para este membro
IF NOT EXISTS (SELECT 1 FROM Contrato WHERE ID_Membro = @MemberID)
BEGIN
    -- Criar contrato para o admin
    INSERT INTO Contrato (AnoInicio, AnoFim, Função, Salário, Género, ID_Membro)
    VALUES (
        2024,           -- Ano de início
        2026,           -- Ano de fim
        'Administrator', -- Função
        75000.00,       -- Salário
        'M',            -- Género (ajustar se necessário: M ou F)
        @MemberID       -- ID do membro
    );
    
    PRINT 'Contrato criado com sucesso!';
END
ELSE
BEGIN
    PRINT 'Contrato já existe para este membro.';
END

-- Verificar o resultado
SELECT 
    s.StaffID,
    s.Username,
    s.NomeCompleto,
    s.Role,
    c.ID_Contrato,
    c.AnoInicio,
    c.AnoFim,
    c.Função,
    c.Salário,
    c.Género
FROM Staff s
LEFT JOIN Membros_da_Equipa m ON s.NomeCompleto = m.Nome
LEFT JOIN Contrato c ON m.ID_Membro = c.ID_Membro
WHERE s.Role = 'Staff'
ORDER BY s.StaffID;

PRINT 'Script executado com sucesso!';
