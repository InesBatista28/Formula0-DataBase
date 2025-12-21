CREATE OR ALTER PROCEDURE sp_DeleteTeamMember
    @ID_Membro INT
AS
BEGIN
    -- Remove dependent rows first to satisfy FK constraints
    DELETE FROM Piloto WHERE ID_Membro = @ID_Membro;
    DELETE FROM Contrato WHERE ID_Membro = @ID_Membro;
    DELETE FROM Membros_da_Equipa WHERE ID_Membro = @ID_Membro;
END
