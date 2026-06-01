\xEF\xBB\xBF/* =====================================================================
   QUAN LY PHONG HOC & LICH HOC (THOI KHOA BIEU)
   ---------------------------------------------------------------------
   Bang PhongHoc da co san trong CS_*.sql. Phan con thieu la LICH HOC.
   File nay them:
     1) Bang LichHoc (chay tren CA 4 SITE - du lieu cuc bo theo MaCoSo)
     2) Du lieu mau cho BN
     3) SP_ThemLichHoc - them lich co KIEM TRA TRUNG PHONG (1 tinh huong
        dong thoi thu 2, manh cho phan bien)
     4) Cac truy van: xem lich 1 lop, xem TKB cua sinh vien

   MO HINH: moi lop hoc phan co the hoc nhieu buoi -> tach bang LichHoc rieng
   (1 lop : nhieu dong lich). Lich thuoc site cua lop nen phan manh ngang theo
   MaCoSo giong LopHocPhan; viec xep phong khong can giao dich phan tan vi phong
   chi thuoc 1 co so.
   ===================================================================== */

USE CS_BN;   -- doi thanh CS_HN / CS_HY / CS_ND khi chay o site khac
GO

/* --------------------- 1) Tao bang LichHoc --------------------- */
IF OBJECT_ID('dbo.LichHoc', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.LichHoc (
        MaLich     CHAR(12) NOT NULL PRIMARY KEY,
        MaLopHP    CHAR(12) NULL,
        MaPhong    CHAR(6)  NULL,
        Thu        TINYINT  NULL,   -- 2..8 (Thu 2 ... Chu Nhat = 8)
        TietBatDau TINYINT  NULL,   -- tiet bat dau trong ngay (1..12)
        SoTiet     TINYINT  NULL,   -- so tiet lien tuc
        MaCoSo     CHAR(4)  NULL
    );

    ALTER TABLE dbo.LichHoc
        ADD CONSTRAINT FK_LichHoc_LopHP
        FOREIGN KEY (MaLopHP) REFERENCES dbo.LopHocPhan(MaLopHP);

    ALTER TABLE dbo.LichHoc
        ADD CONSTRAINT FK_LichHoc_Phong
        FOREIGN KEY (MaPhong) REFERENCES dbo.PhongHoc(MaPhong);

    PRINT N'Da tao bang LichHoc.';
END
ELSE
    PRINT N'Bang LichHoc da ton tai, bo qua tao moi.';
GO

/* --------------------- 2) Du lieu mau (cho BN) --------------------- */
-- LHP_BN001 dang dat o phong P101; LHP_BN002 o PH_BN1 (theo du lieu san co)
IF NOT EXISTS (SELECT 1 FROM dbo.LichHoc WHERE MaLich = 'LICH_BN001')
INSERT INTO dbo.LichHoc (MaLich, MaLopHP, MaPhong, Thu, TietBatDau, SoTiet, MaCoSo)
VALUES
('LICH_BN001', 'LHP_BN001', 'P101',   2, 1, 3, 'BN'),   -- Thu 2, tiet 1-3
('LICH_BN002', 'LHP_BN002', 'PH_BN1', 4, 7, 3, 'BN');   -- Thu 4, tiet 7-9
GO


/* --------------------- 3) Them lich co kiem tra trung phong --------------------- */
/* Tinh huong dong thoi: 2 nguoi cung xep 2 lop vao CUNG phong, CUNG thu, trung tiet.
   Phai chan trung phong. Dung khoa pham vi (HOLDLOCK + UPDLOCK) tren PhongHoc de
   serialize cac lan xep lich vao cung phong. */
CREATE OR ALTER PROCEDURE dbo.SP_ThemLichHoc
    @MaLich      CHAR(12),
    @MaLopHP     CHAR(12),
    @MaPhong     CHAR(6),
    @Thu         TINYINT,
    @TietBatDau  TINYINT,
    @SoTiet      TINYINT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    BEGIN TRY
        BEGIN TRANSACTION;

        DECLARE @MaCoSo CHAR(4);

        /* Giu khoa tren dong phong de cac lan xep cung phong phai noi tiep nhau */
        SELECT @MaCoSo = MaCoSo
        FROM dbo.PhongHoc WITH (UPDLOCK, HOLDLOCK)
        WHERE MaPhong = @MaPhong;

        IF @MaCoSo IS NULL
            THROW 50021, N'Loi: Khong tim thay phong hoc.', 1;

        /* Kiem tra trung lich: cung phong, cung thu, va khoang tiet GIAO NHAU.
           Hai khoang [a, a+n) va [b, b+m) giao nhau khi a < b+m VA b < a+n. */
        IF EXISTS (
            SELECT 1 FROM dbo.LichHoc WITH (UPDLOCK, HOLDLOCK)
            WHERE MaPhong = @MaPhong
              AND Thu = @Thu
              AND @TietBatDau < TietBatDau + SoTiet
              AND TietBatDau  < @TietBatDau + @SoTiet
        )
            THROW 50022, N'Loi: Phong da co lop khac vao khung gio nay (trung lich).', 1;

        INSERT INTO dbo.LichHoc
            (MaLich, MaLopHP, MaPhong, Thu, TietBatDau, SoTiet, MaCoSo)
        VALUES
            (@MaLich, @MaLopHP, @MaPhong, @Thu, @TietBatDau, @SoTiet, @MaCoSo);

        COMMIT TRANSACTION;
        PRINT N'Da them lich hoc ' + @MaLich;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO
-- Vi du: EXEC dbo.SP_ThemLichHoc 'LICH_BN003','LHP_BN001','P101',3,1,2;  -- Thu 3
-- Vi du gay trung: EXEC dbo.SP_ThemLichHoc 'LICH_BN004','LHP_BN002','P101',2,2,2; -> bao loi


/* --------------------- 4a) Xem lich hoc cua 1 lop --------------------- */
SELECT lh.MaLich, lh.MaLopHP, ph.TenPhong,
       N'Thu ' + CAST(lh.Thu AS VARCHAR) AS Thu,
       lh.TietBatDau, lh.SoTiet,
       lh.TietBatDau AS TuTiet,
       (lh.TietBatDau + lh.SoTiet - 1) AS DenTiet
FROM dbo.LichHoc lh
    JOIN dbo.PhongHoc ph ON lh.MaPhong = ph.MaPhong
WHERE lh.MaLopHP = 'LHP_BN001'
ORDER BY lh.Thu, lh.TietBatDau;
GO

/* --------------------- 4b) Thoi khoa bieu cua 1 sinh vien (tai site BN) --------------------- */
-- Lay cac lop sinh vien da dang ky tai BN + lich tuong ung
SELECT dk.MaSV, l.MaLopHP, hp.TenHP, ph.TenPhong,
       N'Thu ' + CAST(lh.Thu AS VARCHAR) AS Thu,
       lh.TietBatDau, lh.SoTiet
FROM dbo.DangKy dk
    JOIN dbo.LopHocPhan l ON dk.MaLopHP = l.MaLopHP
    JOIN dbo.HocPhan hp   ON l.MaHP = hp.MaHP
    JOIN dbo.LichHoc lh   ON lh.MaLopHP = l.MaLopHP
    JOIN dbo.PhongHoc ph  ON lh.MaPhong = ph.MaPhong
WHERE dk.MaSV = 'SV_HN01'
ORDER BY lh.Thu, lh.TietBatDau;
GO

/* GHI CHU MO RONG (cho phan bien):
   Vi sinh vien co the hoc cheo co so, TKB DAY DU toan truong la truy van phan tan:
   gom DangKy + LichHoc cua ca 4 site bang UNION ALL (giong mau 5 truy van phan tich),
   roi loc theo @MaSV. Lich nam tai site cua lop nen phai duyet ca 4 site. */
