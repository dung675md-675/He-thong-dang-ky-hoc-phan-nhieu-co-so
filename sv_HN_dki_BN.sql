BEGIN DISTRIBUTED TRANSACTION;
BEGIN TRY
    EXEC [localhost\BN].CS_BN.dbo.sp_DangKyHocPhan
        @MaSV = 'SV_HN01',
        @MaLopHP = 'LHP_BN001';
    
    COMMIT TRANSACTION;
    PRINT N'Giao dịch phân tán thành công!'; 
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    PRINT N'Lỗi: ' + ERROR_MESSAGE();
END CATCH
