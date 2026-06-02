-- CHẠY TẠI MÁY CHỦ BẮC NINH (localhost\BN) để đẩy dữ liệu sang Hà Nội
USE CS_BN;
GO
-- 1. Dọn dẹp các giao dịch đang bị treo từ lần chạy lỗi trước (nếu có)
IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
GO
-- 2. BẬT TÍNH NĂNG BẢO VỆ GIAO DỊCH PHÂN TÁN (Bắt buộc cho Linked Server)
SET XACT_ABORT ON;
GO
BEGIN DISTRIBUTED TRANSACTION;
-- 3. XÓA (DELETE): Ráp với HN, xóa những môn học ở HN không còn tồn tại ở BN
DELETE FROM [localhost\HN].[CS_HN].dbo.HocPhan
WHERE MaHP NOT IN (SELECT MaHP FROM CS_BN.dbo.HocPhan);
-- 4. CẬP NHẬT (UPDATE): Đồng bộ tên môn học nếu ở BN có sự điều chỉnh
UPDATE hn
SET hn.TenHP = bn.TenHP
FROM [localhost\HN].[CS_HN].dbo.HocPhan hn
JOIN CS_BN.dbo.HocPhan bn ON hn.MaHP = bn.MaHP
WHERE hn.TenHP <> bn.TenHP;
-- 5. THÊM MỚI (INSERT): Đẩy các môn học mới mở tại BN sang HN
INSERT INTO [localhost\HN].[CS_HN].dbo.HocPhan (MaHP, TenHP)
SELECT MaHP, TenHP
FROM CS_BN.dbo.HocPhan bn
WHERE NOT EXISTS (
    SELECT 1 FROM [localhost\HN].[CS_HN].dbo.HocPhan hn WHERE hn.MaHP = bn.MaHP
);
COMMIT TRANSACTION;
PRINT N'Đã hoàn tất đồng bộ danh mục Học phần từ Bắc Ninh sang Hà Nội!';
GO
