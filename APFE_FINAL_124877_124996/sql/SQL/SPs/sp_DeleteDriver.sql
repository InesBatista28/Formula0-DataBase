CREATE PROCEDURE sp_DeleteDriver
    @ID_Piloto INT
AS
BEGIN
    DELETE FROM Piloto WHERE ID_Piloto = @ID_Piloto;
END