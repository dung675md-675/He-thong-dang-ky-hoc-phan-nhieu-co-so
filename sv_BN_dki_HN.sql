BEGIN DISTRIBUTED TRANSACTION;
BEGIN TRY
    EXEC [localhost\HN].[CS_HN].dbo.sp_DangKyHocPhan 
        @MaSV = 'SV_BN01',
        @MaLopHP = 'LHP_HN001';
    
    COMMIT TRANSACTION;
    PRINT N'Kịch bản 3: Giao dịch phân tán thành công'; 
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    PRINT N'Lỗi Kịch bản 3: ' + ERROR_MESSAGE();
END CATCH
