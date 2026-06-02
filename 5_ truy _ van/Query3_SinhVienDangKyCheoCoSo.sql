USE CS_BN;
GO

WITH AllSinhVien AS (
    SELECT MaSV, HoTen, MaCoSo FROM CS_BN.dbo.SinhVien
    UNION ALL SELECT MaSV, HoTen, MaCoSo FROM [localhost\HN].CS_HN.dbo.SinhVien
    UNION ALL SELECT MaSV, HoTen, MaCoSo FROM [localhost\HY].CS_HY.dbo.SinhVien
    UNION ALL SELECT MaSV, HoTen, MaCoSo FROM [localhost\ND].CS_ND.dbo.SinhVien
),
AllDangKy AS (
    SELECT MaSV, MaLopHP FROM CS_BN.dbo.DangKy
    UNION ALL SELECT MaSV, MaLopHP FROM [localhost\HN].CS_HN.dbo.DangKy
    UNION ALL SELECT MaSV, MaLopHP FROM [localhost\HY].CS_HY.dbo.DangKy
    UNION ALL SELECT MaSV, MaLopHP FROM [localhost\ND].CS_ND.dbo.DangKy
),
AllLop AS (
    SELECT MaLopHP, MaCoSo FROM CS_BN.dbo.LopHocPhan
    UNION ALL SELECT MaLopHP, MaCoSo FROM [localhost\HN].CS_HN.dbo.LopHocPhan
    UNION ALL SELECT MaLopHP, MaCoSo FROM [localhost\HY].CS_HY.dbo.LopHocPhan
    UNION ALL SELECT MaLopHP, MaCoSo FROM [localhost\ND].CS_ND.dbo.LopHocPhan
)
SELECT sv.MaSV, sv.HoTen,
       sv.MaCoSo AS CoSoCuaSV,
       l.MaCoSo  AS CoSoCuaLop
FROM AllSinhVien sv
    JOIN AllDangKy dk ON sv.MaSV = dk.MaSV
    JOIN AllLop l     ON dk.MaLopHP = l.MaLopHP
WHERE sv.MaCoSo <> l.MaCoSo;
GO
