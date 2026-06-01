USE CS_BN;
GO

SELECT MaCoSo, COUNT(*) AS SoLuongDK
FROM (
    SELECT l.MaCoSo
    FROM CS_BN.dbo.DangKy d
        JOIN CS_BN.dbo.LopHocPhan l ON d.MaLopHP = l.MaLopHP
    UNION ALL
    SELECT l.MaCoSo
    FROM [localhost\HN].CS_HN.dbo.DangKy d
        JOIN [localhost\HN].CS_HN.dbo.LopHocPhan l ON d.MaLopHP = l.MaLopHP
    UNION ALL
    SELECT l.MaCoSo
    FROM [localhost\HY].CS_HY.dbo.DangKy d
        JOIN [localhost\HY].CS_HY.dbo.LopHocPhan l ON d.MaLopHP = l.MaLopHP
    UNION ALL
    SELECT l.MaCoSo
    FROM [localhost\ND].CS_ND.dbo.DangKy d
        JOIN [localhost\ND].CS_ND.dbo.LopHocPhan l ON d.MaLopHP = l.MaLopHP
) AS AllDK
GROUP BY MaCoSo
ORDER BY SoLuongDK DESC;
GO
