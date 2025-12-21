CREATE OR ALTER PROCEDURE sp_DeleteGrandPrix
    @NomeGP NVARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        -- Remover dependências ligadas ao GP
        DELETE FROM Pitstop WHERE NomeGP = @NomeGP;
        DELETE FROM Penalizações WHERE NomeGP = @NomeGP;
        DELETE FROM Resultados WHERE NomeGP = @NomeGP;
        DELETE FROM Sessões WHERE NomeGP = @NomeGP;

        -- Por fim, remover o Grande Prémio
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
