USE CS_BN;
GO

SELECT TOP 1 MaHP, TenHP, COUNT(*) AS TongDK
FROM (
    SELECT hp.MaHP, hp.TenHP
    FROM CS_BN.dbo.DangKy d
        JOIN CS_BN.dbo.LopHocPhan l ON d.MaLopHP = l.MaLopHP
        JOIN CS_BN.dbo.HocPhan hp   ON l.MaHP = hp.MaHP
    UNION ALL
    SELECT hp.MaHP, hp.TenHP
    FROM [localhost\HN].CS_HN.dbo.DangKy d
        JOIN [localhost\HN].CS_HN.dbo.LopHocPhan l ON d.MaLopHP = l.MaLopHP
        JOIN [localhost\HN].CS_HN.dbo.HocPhan hp   ON l.MaHP = hp.MaHP
    UNION ALL
    SELECT hp.MaHP, hp.TenHP
    FROM [localhost\HY].CS_HY.dbo.DangKy d
        JOIN [localhost\HY].CS_HY.dbo.LopHocPhan l ON d.MaLopHP = l.MaLopHP
        JOIN [localhost\HY].CS_HY.dbo.HocPhan hp   ON l.MaHP = hp.MaHP
    UNION ALL
    SELECT hp.MaHP, hp.TenHP
    FROM [localhost\ND].CS_ND.dbo.DangKy d
        JOIN [localhost\ND].CS_ND.dbo.LopHocPhan l ON d.MaLopHP = l.MaLopHP
        JOIN [localhost\ND].CS_ND.dbo.HocPhan hp   ON l.MaHP = hp.MaHP
) AS AllDK
GROUP BY MaHP, TenHP
ORDER BY TongDK DESC;
GO
