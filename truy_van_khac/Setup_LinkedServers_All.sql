\xEF\xBB\xBF/* =====================================================================
   SETUP LINKED SERVER CHO CA 4 INSTANCE (BN, HN, HY, ND) - CHAY 1 LAN
   =====================================================================

   CACH CHAY:
   1. Mo file nay trong SSMS.
   2. BAT che do SQLCMD: menu  Query  ->  "SQLCMD Mode".
      (Neu khong bat, cac dong ":CONNECT" se bao loi mau do.)
   3. Ket noi voi BAT KY instance nao (vd localhost\BN) roi nhan Execute (F5).
   4. Script se tu dong nhay qua tung instance va tao linked server.

   GHI CHU:
   - Linked server duoc dat ten DUNG bang ten instance: localhost\BN, localhost\HN, ...
   - Script idempotent: chay lai nhieu lan khong loi (tu xoa link cu truoc khi tao).
   - Moi instance se co link toi 3 instance con lai (full mesh) de moi kich ban
     dang ky cheo co so deu chay duoc.
   - @srvproduct = 'SQL Server' => khong can chi dinh provider, hop voi SQL Server 2022/2025.
   ===================================================================== */

:on error exit

/* ---------- Thu tuc dung chung: tao link tu server hien tai toi 3 target ---------- */

-- =========================== TAI BAC NINH (BN) ===========================
:CONNECT localhost\BN
GO
PRINT N'>>> Dang cau hinh Linked Server tai: ' + @@SERVERNAME;
DECLARE @s SYSNAME;
DECLARE c CURSOR FOR
    SELECT v FROM (VALUES (N'localhost\HN'), (N'localhost\HY'), (N'localhost\ND')) AS t(v);
OPEN c; FETCH NEXT FROM c INTO @s;
WHILE @@FETCH_STATUS = 0
BEGIN
    IF EXISTS (SELECT 1 FROM sys.servers WHERE name = @s)
        EXEC sp_dropserver @server = @s, @droplogins = 'droplogins';
    EXEC sp_addlinkedserver    @server = @s, @srvproduct = N'SQL Server';
    EXEC sp_serveroption       @s, 'rpc',     'true';
    EXEC sp_serveroption       @s, 'rpc out', 'true';
    EXEC sp_addlinkedsrvlogin  @rmtsrvname = @s, @useself = N'True';
    PRINT N'    + Da tao link toi ' + @s;
    FETCH NEXT FROM c INTO @s;
END
CLOSE c; DEALLOCATE c;
GO

-- =========================== TAI HA NOI (HN) ===========================
:CONNECT localhost\HN
GO
PRINT N'>>> Dang cau hinh Linked Server tai: ' + @@SERVERNAME;
DECLARE @s SYSNAME;
DECLARE c CURSOR FOR
    SELECT v FROM (VALUES (N'localhost\BN'), (N'localhost\HY'), (N'localhost\ND')) AS t(v);
OPEN c; FETCH NEXT FROM c INTO @s;
WHILE @@FETCH_STATUS = 0
BEGIN
    IF EXISTS (SELECT 1 FROM sys.servers WHERE name = @s)
        EXEC sp_dropserver @server = @s, @droplogins = 'droplogins';
    EXEC sp_addlinkedserver    @server = @s, @srvproduct = N'SQL Server';
    EXEC sp_serveroption       @s, 'rpc',     'true';
    EXEC sp_serveroption       @s, 'rpc out', 'true';
    EXEC sp_addlinkedsrvlogin  @rmtsrvname = @s, @useself = N'True';
    PRINT N'    + Da tao link toi ' + @s;
    FETCH NEXT FROM c INTO @s;
END
CLOSE c; DEALLOCATE c;
GO

-- =========================== TAI HUNG YEN (HY) ===========================
:CONNECT localhost\HY
GO
PRINT N'>>> Dang cau hinh Linked Server tai: ' + @@SERVERNAME;
DECLARE @s SYSNAME;
DECLARE c CURSOR FOR
    SELECT v FROM (VALUES (N'localhost\BN'), (N'localhost\HN'), (N'localhost\ND')) AS t(v);
OPEN c; FETCH NEXT FROM c INTO @s;
WHILE @@FETCH_STATUS = 0
BEGIN
    IF EXISTS (SELECT 1 FROM sys.servers WHERE name = @s)
        EXEC sp_dropserver @server = @s, @droplogins = 'droplogins';
    EXEC sp_addlinkedserver    @server = @s, @srvproduct = N'SQL Server';
    EXEC sp_serveroption       @s, 'rpc',     'true';
    EXEC sp_serveroption       @s, 'rpc out', 'true';
    EXEC sp_addlinkedsrvlogin  @rmtsrvname = @s, @useself = N'True';
    PRINT N'    + Da tao link toi ' + @s;
    FETCH NEXT FROM c INTO @s;
END
CLOSE c; DEALLOCATE c;
GO

-- =========================== TAI NAM DINH (ND) ===========================
:CONNECT localhost\ND
GO
PRINT N'>>> Dang cau hinh Linked Server tai: ' + @@SERVERNAME;
DECLARE @s SYSNAME;
DECLARE c CURSOR FOR
    SELECT v FROM (VALUES (N'localhost\BN'), (N'localhost\HN'), (N'localhost\HY')) AS t(v);
OPEN c; FETCH NEXT FROM c INTO @s;
WHILE @@FETCH_STATUS = 0
BEGIN
    IF EXISTS (SELECT 1 FROM sys.servers WHERE name = @s)
        EXEC sp_dropserver @server = @s, @droplogins = 'droplogins';
    EXEC sp_addlinkedserver    @server = @s, @srvproduct = N'SQL Server';
    EXEC sp_serveroption       @s, 'rpc',     'true';
    EXEC sp_serveroption       @s, 'rpc out', 'true';
    EXEC sp_addlinkedsrvlogin  @rmtsrvname = @s, @useself = N'True';
    PRINT N'    + Da tao link toi ' + @s;
    FETCH NEXT FROM c INTO @s;
END
CLOSE c; DEALLOCATE c;
GO

/* ===================== KIEM TRA NHANH (chay tai BN) =====================
   Neu cac cau SELECT duoi tra ve du lieu => linked server da OK.
   ====================================================================== */
:CONNECT localhost\BN
GO
PRINT N'================ KIEM TRA KET NOI TU BN ================';
SELECT 'localhost\HN' AS LinkedServer, COUNT(*) AS SoHocPhan FROM [localhost\HN].CS_HN.dbo.HocPhan;
SELECT 'localhost\HY' AS LinkedServer, COUNT(*) AS SoHocPhan FROM [localhost\HY].CS_HY.dbo.HocPhan;
SELECT 'localhost\ND' AS LinkedServer, COUNT(*) AS SoHocPhan FROM [localhost\ND].CS_ND.dbo.HocPhan;
PRINT N'>>> Neu khong co loi => HOAN TAT cau hinh Linked Server cho ca 4 instance!';
GO
