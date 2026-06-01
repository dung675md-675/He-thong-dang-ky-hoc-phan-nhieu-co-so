-- CỬA SỔ 2: SV Nam Định bấm đăng ký ngay sau Tuấn 1 tích tắc
BEGIN DISTRIBUTED TRANSACTION;
BEGIN TRY
    EXEC [localhost\BN].CS_BN.dbo.sp_DangKyHocPhan 
        @MaSV = 'SV_ND01', 
        @MaLopHP = 'LHP_BN001';

    COMMIT TRANSACTION;
    PRINT N'Cửa sổ 2 (SV_ND01): Đăng ký thành công!';
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    PRINT N'Lỗi Cửa sổ 2: ' + ERROR_MESSAGE();
END CATCH