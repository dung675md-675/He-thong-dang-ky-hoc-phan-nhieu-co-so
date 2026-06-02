-- CHẠY TẠI MÁY CHỦ BẮC NINH (localhost\BN)
USE CS_BN;
GO

-- Kiểm tra danh sách sinh viên đã đăng ký thành công vào lớp LHP_BN001
SELECT
    MaDangKy AS [Mã Đăng Ký],
    MaSV AS [Mã Sinh Viên],
    MaLopHP AS [Mã Lớp Học Phần],
    FORMAT(TgDangKy, 'dd/MM/yyyy HH:mm:ss') AS [Thời Gian Đăng Ký]
FROM dbo.DangKy
WHERE MaLopHP = 'LHP_BN001'
ORDER BY TgDangKy DESC;