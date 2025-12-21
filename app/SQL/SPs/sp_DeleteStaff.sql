IF OBJECT_ID('sp_DeleteStaff', 'P') IS NOT NULL
    DROP PROCEDURE sp_DeleteStaff;
GO
CREATE PROCEDURE sp_DeleteStaff
    @StaffID INT
AS
BEGIN
    DELETE FROM Staff WHERE StaffID = @StaffID;
END;