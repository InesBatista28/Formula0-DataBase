IF OBJECT_ID('vw_Team_Details', 'V') IS NOT NULL
    DROP VIEW vw_Team_Details;
GO
CREATE VIEW vw_Team_Details AS
SELECT 
    ID_Equipa,
    Nome,
    Nacionalidade,
    Base,
    ChefeEquipa,
    ChefeTécnico,
    AnoEstreia,
    ModeloChassis,
    Power_Unit,
    PilotosReserva
FROM Equipa;