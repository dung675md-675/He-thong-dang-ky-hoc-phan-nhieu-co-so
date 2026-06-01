USE CS_BN;
GO
UPDATE dbo.LopHocPhan
SET SiSoToiDa = 50, SiSoHienTai = 49
WHERE MaLopHP = 'LHP_BN001';
GO
SELECT MaLopHP, SiSoToiDa, SiSoHienTai FROM dbo.LopHocPhan WHERE MaLopHP = 'LHP_BN001';
GO