USE CS_BN;
GO

SELECT MaLopHP, MaHP, MaCoSo, SiSoToiDa, SiSoHienTai,
       CAST(ROUND(ISNULL(SiSoHienTai, 0) * 100.0 / NULLIF(SiSoToiDa, 0), 2)
            AS DECIMAL(5, 2)) AS TyLeLapDay
FROM (
    SELECT MaLopHP, MaHP, MaCoSo, SiSoToiDa, SiSoHienTai
    FROM CS_BN.dbo.LopHocPhan
    UNION ALL
    SELECT MaLopHP, MaHP, MaCoSo, SiSoToiDa, SiSoHienTai
    FROM [localhost\HN].CS_HN.dbo.LopHocPhan
    UNION ALL
    SELECT MaLopHP, MaHP, MaCoSo, SiSoToiDa, SiSoHienTai
    FROM [localhost\HY].CS_HY.dbo.LopHocPhan
    UNION ALL
    SELECT MaLopHP, MaHP, MaCoSo, SiSoToiDa, SiSoHienTai
    FROM [localhost\ND].CS_ND.dbo.LopHocPhan
) AS AllLop
ORDER BY TyLeLapDay DESC;
GO
