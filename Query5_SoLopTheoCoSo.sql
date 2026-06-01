USE CS_BN;
GO

SELECT MaCoSo, COUNT(*) AS SoLop
FROM (
    SELECT MaCoSo FROM CS_BN.dbo.LopHocPhan
    UNION ALL SELECT MaCoSo FROM [localhost\HN].CS_HN.dbo.LopHocPhan
    UNION ALL SELECT MaCoSo FROM [localhost\HY].CS_HY.dbo.LopHocPhan
    UNION ALL SELECT MaCoSo FROM [localhost\ND].CS_ND.dbo.LopHocPhan
) AS AllLop
GROUP BY MaCoSo
ORDER BY SoLop DESC;
GO
