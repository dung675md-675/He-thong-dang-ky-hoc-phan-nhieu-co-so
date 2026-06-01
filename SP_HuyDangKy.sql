\xEF\xBB\xBF/* =====================================================================
   CHUC NANG HUY DANG KY HOC PHAN
   ---------------------------------------------------------------------
   - SP_HuyDangKy           : huy dang ky tai chinh site cua lop (LOCAL).
   - Demo huy dang ky cheo co so qua giao dich phan tan (DISTRIBUTED).
   Cai dat   : chay tren cac site co mo lop (vd BN). Co the chay tren ca 4.
   Yeu cau   : da co bang DangKy, LopHocPhan (co san trong CS_*.sql).
   Logic     : la logic NGUOC cua dang ky -> xoa dong DangKy + giam SiSoHienTai,
               tat ca trong 1 transaction, co khoa chong tranh chap.
   ===================================================================== */

USE CS_BN;   -- doi thanh CS_HN / CS_HY / CS_ND khi cai o site khac
GO

CREATE OR ALTER PROCEDURE dbo.SP_HuyDangKy
    @MaSV    CHAR(10),
    @MaLopHP CHAR(12)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    BEGIN TRY
        BEGIN TRANSACTION;

        /* Khoa dong lop hoc phan TRUOC (UPDLOCK, ROWLOCK) de tranh tranh chap
           voi thu tuc dang ky dang chay song song tren cung lop. */
        DECLARE @SiSoHienTai INT;
        SELECT @SiSoHienTai = SiSoHienTai
        FROM dbo.LopHocPhan WITH (UPDLOCK, ROWLOCK)
        WHERE MaLopHP = @MaLopHP;

        IF @SiSoHienTai IS NULL
            THROW 50011, N'Loi: Khong tim thay lop hoc phan.', 1;

        /* Kiem tra sinh vien co thuc su dang ky lop nay khong */
        IF NOT EXISTS (SELECT 1 FROM dbo.DangKy
                       WHERE MaSV = @MaSV AND MaLopHP = @MaLopHP)
            THROW 50012, N'Loi: Sinh vien chua dang ky lop nay, khong the huy.', 1;

        /* Xoa dang ky */
        DELETE FROM dbo.DangKy
        WHERE MaSV = @MaSV AND MaLopHP = @MaLopHP;

        /* Giam si so, khong cho am */
        UPDATE dbo.LopHocPhan
        SET SiSoHienTai = CASE WHEN SiSoHienTai > 0 THEN SiSoHienTai - 1 ELSE 0 END
        WHERE MaLopHP = @MaLopHP;

        COMMIT TRANSACTION;
        PRINT N'Huy dang ky thanh cong cho SV ' + @MaSV + N' - Lop ' + @MaLopHP;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;   -- nem lai loi de noi goi (hoac giao dich phan tan) biet ma rollback
    END CATCH
END;
GO


/* =====================================================================
   VI DU 1 - Huy dang ky CUC BO (sinh vien va lop cung site BN)
   ===================================================================== */
-- EXEC dbo.SP_HuyDangKy @MaSV = 'SV01', @MaLopHP = 'LHP_BN001';


/* =====================================================================
   VI DU 2 - Huy dang ky CHEO CO SO (giao dich phan tan)
   Sinh vien o HN huy lop dang hoc tai BN. Dang ky duoc luu tai site cua lop
   (BN), nen ta goi SP_HuyDangKy o BN qua Linked Server trong 1 distributed
   transaction. Yeu cau: da bat MSDTC + cau hinh Linked Server.
   ===================================================================== */
/*
BEGIN DISTRIBUTED TRANSACTION;
BEGIN TRY
    EXEC [localhost\BN].CS_BN.dbo.SP_HuyDangKy
         @MaSV = 'SV_HN01', @MaLopHP = 'LHP_BN001';
    COMMIT TRANSACTION;
    PRINT N'Huy dang ky cheo co so thanh cong!';
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    PRINT N'Loi khi huy: ' + ERROR_MESSAGE();
END CATCH
*/
