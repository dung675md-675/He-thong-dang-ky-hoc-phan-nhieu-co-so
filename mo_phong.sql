USE CS_BN;
GO
CREATE OR ALTER PROCEDURE dbo.sp_DangKyHocPhan_DemoLag
    @MaSV CHAR(10), @MaLopHP CHAR(12)
AS
BEGIN
    SET NOCOUNT ON; SET XACT_ABORT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
        DECLARE @SiSoToiDa INT, @SiSoHienTai INT;
 
        SELECT @SiSoToiDa = SiSoToiDa, @SiSoHienTai = SiSoHienTai
        FROM dbo.LopHocPhan WITH (UPDLOCK, ROWLOCK)
        WHERE MaLopHP = @MaLopHP;
 
        WAITFOR DELAY '00:00:10';   -- giu khoa 10 giay de demo tranh chap
 
        IF @SiSoHienTai >= @SiSoToiDa
            THROW 50003, N'Lop da het cho.', 1;
 
        INSERT INTO dbo.DangKy (MaDangKy, MaSV, MaLopHP, TgDangKy)
        VALUES (LEFT(@MaSV + CONVERT(VARCHAR,GETDATE(),12),15), @MaSV, @MaLopHP, GETDATE());
 
        UPDATE dbo.LopHocPhan SET SiSoHienTai = SiSoHienTai + 1
        WHERE MaLopHP = @MaLopHP;
 
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION; THROW;
    END CATCH
END;
GO