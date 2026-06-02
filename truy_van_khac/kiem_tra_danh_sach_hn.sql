-- CHẠY TẠI CỬA SỔ HÀ NỘI (localhost\HN)
USE CS_HN;
GO

-- Kiểm tra danh sách sinh viên đã đăng ký vào lớp LHP_HN001 tại Hà Nội
SELECT
    MaDangKy AS [Mã Đăng Ký],
    MaSV AS [Mã Sinh Viên],
    MaLopHP AS [Mã Lớp Học Phần],
    FORMAT(TgDangKy, 'dd/MM/yyyy HH:mm:ss') AS [Thời Gian Đăng Ký]
FROM dbo.DangKy
WHERE MaLopHP = 'LHP_HN001'
ORDER BY TgDangKy DESC;