# Hệ thống Quản lý Đăng ký Học phần Phân tán (CSDLPT)

Đồ án Cơ sở dữ liệu phân tán: mô phỏng một trường đại học có **4 cơ sở** đặt tại
**Bắc Ninh (BN), Hà Nội (HN), Hưng Yên (HY), Nam Định (ND)**. Mỗi cơ sở là một
**SQL Server instance** riêng, kết nối với nhau qua **Linked Server** và **giao dịch
phân tán (MSDTC)**. Cơ sở Bắc Ninh đóng vai trò **master** cho dữ liệu dùng chung
(bảng `HocPhan`, `CoSo`).

> Cứ làm tuần tự từ trên xuống, không bỏ bước. Đặc biệt **không bỏ Bước 2 (MSDTC)**.

---

## 1. Tổng quan kiến trúc

| Cơ sở | Instance | Database | File cài đặt | Vai trò |
|-------|----------|----------|--------------|---------|
| Bắc Ninh | `localhost\BN` | `CS_BN` | `CS_BN.sql` | **Master** (ghi `HocPhan`, xử lý đăng ký) |
| Hà Nội | `localhost\HN` | `CS_HN` | `CS_HN.sql` | Slave (bản sao chỉ đọc `HocPhan`) |
| Hưng Yên | `localhost\HY` | `CS_HY` | `CS_HY.sql` | Slave |
| Nam Định | `localhost\ND` | `CS_ND` | `CS_ND.sql` | Slave |

- **Phân mảnh ngang theo `MaCoSo`**: mỗi instance chỉ chứa dữ liệu của cơ sở mình.
- **Nhân bản (replicate)**: bảng `HocPhan` và `CoSo` được sao chép sang cả 4 site.
- 4 instance kết nối 2 chiều qua Linked Server đặt **đúng tên instance**:
  `[localhost\BN]`, `[localhost\HN]`, `[localhost\HY]`, `[localhost\ND]`.

```
        ┌─────────────┐
        │ localhost\BN│  (Master - CS_BN)
        │   HocPhan*  │
        └──────┬──────┘
   Linked Server│ (2 chiều)
   ┌────────────┼────────────┐
┌──┴───┐   ┌────┴───┐   ┌────┴───┐
│  HN  │   │   HY   │   │   ND   │
│ CS_HN│   │  CS_HY │   │  CS_ND │
└──────┘   └────────┘   └────────┘
```

> ✅ **Bạn không cần tự gõ script tạo bảng hay nhập liệu.** 4 file `.sql` kèm theo đã là
> bản xuất đầy đủ từ SSMS, mỗi file tự tạo: database → bảng → **dữ liệu mẫu** → **các
> stored procedure** cho site đó. Chạy file là xong.

---

## 2. Yêu cầu cài đặt (Prerequisites)

| Phần mềm | Ghi chú |
|----------|---------|
| **SQL Server 2022 / 2025** (Developer hoặc Express) | Script gốc tạo từ SQL Server 2025 (compatibility level 170). Cần cài **4 instance có tên**: `BN`, `HN`, `HY`, `ND`. |
| **SQL Server Management Studio (SSMS)** | Để mở và chạy file `.sql` |
| **MSDTC** (Distributed Transaction Coordinator) | **Bắt buộc** bật cho giao dịch phân tán |
| Hệ điều hành | Windows |

---

## 3. Các bước cài đặt

### Bước 1 — Cài 4 instance SQL Server

Khi chạy bộ cài SQL Server, mục **Instance Configuration** chọn **Named instance** và
lần lượt đặt tên: `BN`, `HN`, `HY`, `ND`. Sau đó mở SSMS, kiểm tra kết nối được tới cả 4:

```
localhost\BN
localhost\HN
localhost\HY
localhost\ND
```

Trong **SQL Server Configuration Manager** → *Protocols for [INSTANCE]* → bật **TCP/IP**
cho từng instance → restart service. Đảm bảo dịch vụ **SQL Server Browser** đang chạy.

### Bước 2 — Bật MSDTC (bắt buộc)

Đăng ký chéo cơ sở dùng `BEGIN DISTRIBUTED TRANSACTION`; thiếu MSDTC sẽ báo lỗi
*"Unable to begin a distributed transaction"*.

1. Mở **Component Services** (`dcomcnfg`) → *Component Services* → *Computers* →
   *My Computer* → chuột phải → **Properties** → tab **MSDTC** → **Security Configuration**.
2. Tích: ✅ Network DTC Access, ✅ Allow Inbound, ✅ Allow Outbound,
   ✅ No Authentication Required (cho môi trường lab/localhost).
3. Restart dịch vụ **Distributed Transaction Coordinator** trong `services.msc`.

### Bước 3 — Chạy 4 file SQL (mỗi file đúng một instance)

Đây là bước tạo toàn bộ database, bảng, **dữ liệu mẫu** và **stored procedure**:

1. Trong SSMS, **kết nối tới `localhost\BN`** → mở `CS_BN.sql` → **Execute (F5)**.
2. Kết nối tới `localhost\HN` → mở `CS_HN.sql` → Execute.
3. Kết nối tới `localhost\HY` → mở `CS_HY.sql` → Execute.
4. Kết nối tới `localhost\ND` → mở `CS_ND.sql` → Execute.

> ⚠️ **Lưu ý đường dẫn file vật lý:** đầu mỗi script có lệnh `CREATE DATABASE ... ON
> ( FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL17.BN\MSSQL\DATA\...' )`.
> Nếu máy bạn cài SQL Server ở thư mục khác (hoặc tên folder instance khác `MSSQL17.*`),
> hãy **sửa lại đường dẫn `FILENAME`** cho đúng, hoặc xóa luôn đoạn
> `ON PRIMARY (...) LOG ON (...)` để SQL Server tự đặt file vào thư mục mặc định.

Mỗi file đã tạo sẵn các stored procedure (bạn **không cần** file `sp_DangKyHocPhan` riêng):

| Procedure | Có ở site | Công dụng |
|-----------|-----------|-----------|
| `SP_DangKyHocPhan` | BN, HN, ND | Thủ tục đăng ký chính, dùng `UPDLOCK, ROWLOCK` chống vượt sĩ số |
| `SP_DangKyHocPhan_Local` | cả 4 | Phần xử lý ghi tại chính site của lớp |
| `SP_DangKyHocPhan_Distributed` | BN | Điều phối đăng ký chéo cơ sở qua linked server |
| `SP_DangKyHocPhan_V2` / `SP_XemSiSo_V2` | BN | Phiên bản nâng cấp + xem sĩ số |
| `sp_DangKyHocPhan_DemoLag` | BN | Bản thêm `WAITFOR DELAY` để **demo tranh chấp** |
| `sp_DangKyHocPhan_Loi_LostUpdate` | BN | Bản **cố tình lỗi** để minh họa Lost Update |

#### Bổ sung: Hủy đăng ký & Lịch học

Hai chức năng này nằm ở **file riêng** (không có trong `CS_*.sql`), chạy thêm sau khi đã
chạy 4 file database:

| File | Nội dung | Chạy ở đâu |
|------|----------|-----------|
| `SP_HuyDangKy.sql` | Thủ tục `SP_HuyDangKy` — hủy đăng ký (xóa `DangKy` + giảm `SiSoHienTai` trong 1 transaction, có `UPDLOCK/ROWLOCK`). Kèm ví dụ hủy chéo cơ sở qua giao dịch phân tán. | Trên các site mở lớp (vd BN), có thể chạy cả 4 |
| `LichHoc_PhongHoc.sql` | Tạo bảng `LichHoc` (lịch học), dữ liệu mẫu, `SP_ThemLichHoc` (thêm lịch **có kiểm tra trùng phòng**), và truy vấn xem lịch lớp / thời khóa biểu sinh viên. | **Chạy trên cả 4 site** (bảng `LichHoc` là dữ liệu cục bộ, phân mảnh theo `MaCoSo`) |

> `LichHoc` được thêm vì đề yêu cầu "phòng học **và lịch học**": bảng `PhongHoc` đã có sẵn,
> còn lịch học (thứ/tiết/phòng) tách thành bảng riêng để một lớp có thể học nhiều buổi.


### Bước 4 — Tạo Linked Server (kết nối 4 site)

Linked Server **không nằm trong 4 file `.sql`** (nó là đối tượng cấp server, không thuộc
database) nên phải tạo tay. Có 2 cách — chọn 1 trong 2:

#### Cách A (nhanh, khuyên dùng) — chạy 1 file cho cả 4 instance

Dùng file `Setup_LinkedServers_All.sql` kèm theo:

1. Mở file trong SSMS.
2. Bật **SQLCMD Mode**: menu **Query → SQLCMD Mode** (bắt buộc, nếu không các dòng
   `:CONNECT` sẽ báo lỗi đỏ).
3. Kết nối tới **bất kỳ** instance nào rồi nhấn **Execute (F5)**.

File sẽ tự nhảy qua cả 4 instance (`:CONNECT`), tạo **full mesh** (mỗi instance link tới
3 instance còn lại), bật sẵn `rpc/rpc out`, thêm login, và **kiểm tra** ở cuối. Script
chạy lại nhiều lần không lỗi (tự xóa link cũ trước khi tạo).

> Chạy file này **sau Bước 3** vì khối kiểm tra cuối có truy vấn vào các database `CS_*`.

#### Cách B (thủ công) — tạo từng link trên từng instance

Chạy trên **mỗi instance** để nó nhìn thấy 3 instance còn lại. Ví dụ chạy tại BN để
liên kết tới HN (làm tương tự cho HY, ND, và lặp trên cả HN/HY/ND):

```sql
-- @srvproduct = 'SQL Server' => không cần provider, hợp với SQL Server 2022/2025
EXEC sp_addlinkedserver
     @server = N'localhost\HN', @srvproduct = N'SQL Server';

EXEC sp_serveroption N'localhost\HN', 'rpc',     'true';
EXEC sp_serveroption N'localhost\HN', 'rpc out', 'true';

EXEC sp_addlinkedsrvlogin
     @rmtsrvname = N'localhost\HN', @useself = N'True';
GO
```

Kiểm tra nhanh (chạy được = OK):

```sql
SELECT * FROM [localhost\HN].CS_HN.dbo.HocPhan;
```

### Bước 5 — (Tùy chọn) Đồng bộ lại bảng `HocPhan` từ Master

Dữ liệu `HocPhan` đã có sẵn ở cả 4 site sau Bước 3. Lệnh dưới chỉ dùng **về sau** khi bạn
thêm/sửa học phần ở BN và muốn đẩy sang các site. Chạy tại BN (lặp cho HY, ND):

```sql
USE CS_BN;
GO
SET XACT_ABORT ON;
BEGIN DISTRIBUTED TRANSACTION;

DELETE FROM [localhost\HN].CS_HN.dbo.HocPhan
WHERE MaHP NOT IN (SELECT MaHP FROM CS_BN.dbo.HocPhan);

UPDATE hn SET hn.TenHP = bn.TenHP
FROM [localhost\HN].CS_HN.dbo.HocPhan hn
JOIN CS_BN.dbo.HocPhan bn ON hn.MaHP = bn.MaHP
WHERE hn.TenHP <> bn.TenHP;

INSERT INTO [localhost\HN].CS_HN.dbo.HocPhan (MaHP, TenHP)
SELECT MaHP, TenHP FROM CS_BN.dbo.HocPhan bn
WHERE NOT EXISTS (SELECT 1 FROM [localhost\HN].CS_HN.dbo.HocPhan hn
                  WHERE hn.MaHP = bn.MaHP);

COMMIT TRANSACTION;
PRINT N'Đã đồng bộ Học phần từ Bắc Ninh sang Hà Nội!';
GO
```

---

## 4. Chạy thử (Demo)

Dữ liệu mẫu đã có sẵn các mã: sinh viên `SV01`, `SV_HN01`, `SV_HY01`, `SV_ND01`...;
lớp `LHP_BN001` (sĩ số 50, đang có 22), `LHP_BN002`...

### 4.1. Đăng ký chéo cơ sở
Sinh viên Hà Nội đăng ký lớp ở Bắc Ninh:

```sql
BEGIN DISTRIBUTED TRANSACTION;
BEGIN TRY
    EXEC [localhost\BN].CS_BN.dbo.SP_DangKyHocPhan
         @MaSV = 'SV_HN01', @MaLopHP = 'LHP_BN001';
    COMMIT TRANSACTION;
    PRINT N'Giao dịch phân tán thành công!';
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    PRINT N'Lỗi: ' + ERROR_MESSAGE();
END CATCH
```

### 4.2. Test tranh chấp đồng thời (chống vượt sĩ số)
1. Chỉnh lớp còn đúng 1 chỗ:
   `UPDATE CS_BN.dbo.LopHocPhan SET SiSoToiDa=50, SiSoHienTai=49 WHERE MaLopHP='LHP_BN001';`
2. Mở **2 cửa sổ query** kết nối tới `localhost\HN`:
   - Cửa sổ 1 gọi `sp_DangKyHocPhan_DemoLag` (có độ trễ 10 giây) cho `SV01`.
   - Cửa sổ 2 gọi `SP_DangKyHocPhan` cho `SV02`.
3. Chạy gần như cùng lúc → chỉ **1 sinh viên** đăng ký được, người kia bị từ chối
   → chứng minh khóa `UPDLOCK/ROWLOCK` chặn được Lost Update.

### 4.3. Truy vấn phân tích toàn cục (chạy tại BN)
Đếm lượt đăng ký theo cơ sở (gom 4 site bằng `UNION ALL`):

```sql
SELECT MaCoSo, COUNT(*) AS SoLuongDK
FROM (
    SELECT l.MaCoSo FROM CS_BN.dbo.DangKy d
        JOIN CS_BN.dbo.LopHocPhan l ON d.MaLopHP = l.MaLopHP
    UNION ALL
    SELECT l.MaCoSo FROM [localhost\HN].CS_HN.dbo.DangKy d
        JOIN [localhost\HN].CS_HN.dbo.LopHocPhan l ON d.MaLopHP = l.MaLopHP
    UNION ALL
    SELECT l.MaCoSo FROM [localhost\HY].CS_HY.dbo.DangKy d
        JOIN [localhost\HY].CS_HY.dbo.LopHocPhan l ON d.MaLopHP = l.MaLopHP
    UNION ALL
    SELECT l.MaCoSo FROM [localhost\ND].CS_ND.dbo.DangKy d
        JOIN [localhost\ND].CS_ND.dbo.LopHocPhan l ON d.MaLopHP = l.MaLopHP
) AS AllDK
GROUP BY MaCoSo;
```

4 truy vấn còn lại (môn đăng ký nhiều nhất, sinh viên học chéo, tỷ lệ lấp đầy lớp,
số lớp theo cơ sở) nằm ở **Mục 6 của báo cáo**, chạy theo cùng mẫu `UNION ALL`.

---

## 5. Xử lý lỗi thường gặp (Troubleshooting)

| Lỗi | Nguyên nhân & cách xử lý |
|-----|--------------------------|
| `Unable to begin a distributed transaction` | MSDTC chưa bật/chưa cấu hình → làm lại **Bước 2**, restart service. |
| Lỗi khi chạy `CREATE DATABASE` (đường dẫn không tồn tại) | Sửa `FILENAME` trong file `.sql` cho khớp thư mục cài SQL Server của bạn (xem ghi chú Bước 3). |
| `Login failed ... linked server` | Sửa `sp_addlinkedsrvlogin`: dùng `@useself='True'` hoặc khai báo SQL login cụ thể. |
| `... unable to begin a distributed transaction` (khi EXEC qua linked server) | Linked server chưa bật `rpc out` (Bước 4) **và/hoặc** MSDTC chặn (Bước 2). |
| Không kết nối được `localhost\HN` | Chưa bật TCP/IP hoặc SQL Server Browser chưa chạy (Bước 1). |
| So sánh mã bị "không khớp" dù nhìn giống nhau | Các cột là kiểu `CHAR` nên dữ liệu có **khoảng trắng đệm** (vd `'BN  '`, `'SV_HN01   '`). Khi viết điều kiện thủ công nên dùng `LIKE` hoặc `RTRIM()` nếu cần. |
| Truy vấn phân tán báo lỗi khi 1 site offline | Đúng theo thiết kế (hạn chế nêu ở Mục 7.2 báo cáo): `UNION ALL` cần tất cả site online. |

---

## 6. Thứ tự chạy tóm tắt (checklist)

- [ ] Bước 1: Cài 4 instance (BN, HN, HY, ND) + bật TCP/IP + SQL Browser
- [ ] Bước 2: Bật & cấu hình MSDTC
- [ ] Bước 3: Chạy `CS_BN.sql`, `CS_HN.sql`, `CS_HY.sql`, `CS_ND.sql` (mỗi file đúng instance)
- [ ] Bước 4: Tạo Linked Server — chạy `Setup_LinkedServers_All.sql` (SQLCMD Mode) hoặc tạo tay
- [ ] Bước 5 (tùy chọn): Đồng bộ lại `HocPhan` khi có thay đổi
- [ ] Mục 4: Chạy demo + truy vấn phân tích

---

## Phụ lục — Cách "lấy tất cả dữ liệu mẫu" (cho lần sau)

4 file `.sql` này chính là dữ liệu mẫu đầy đủ rồi. Nếu sau này bạn muốn **xuất lại** từ
một database đang chạy:

> SSMS → chuột phải database → **Tasks → Generate Scripts...** → chọn bảng/đối tượng →
> **Advanced** → mục **Types of data to script** chọn **"Schema and data"** → Next → Finish.

Đó chính là cách 4 file này được tạo ra (bao gồm cả CREATE TABLE, INSERT dữ liệu và CREATE PROCEDURE).

---

*Đồ án môn Cơ sở dữ liệu phân tán (CSDLPT).*
