-- CỬA SỔ 1: Hưng Yên bấm đăng ký trước nhưng bị delay 10 giây
BEGIN DISTRIBUTED TRANSACTION;
BEGIN TRY
    -- Gọi thủ tục có chứa lệnh WAITFOR DELAY '00:00:10' để giữ khóa (RowLock)
    EXEC [localhost\BN].CS_BN.dbo.sp_DangKyHocPhan_DemoLag 
        @MaSV = 'SV_HY01', 
        @MaLopHP = 'LHP_BN001';

    COMMIT TRANSACTION;
    PRINT N'Cửa sổ 1 (SV_HY01): Xử lý xong độ trễ, đã đăng ký được slot cuối cùng!';
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    PRINT N'Lỗi Cửa sổ 1: ' + ERROR_MESSAGE();
END CATCH