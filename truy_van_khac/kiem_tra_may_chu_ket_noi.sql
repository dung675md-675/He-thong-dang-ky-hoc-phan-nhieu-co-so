-- Kiểm tra danh sách các máy chủ đã được liên kết thành công
SELECT 
    name AS [Tên Linked Server], 
    product AS [Sản phẩm], 
    data_source AS [Nguồn dữ liệu],
    is_linked AS [Trạng thái liên kết]
FROM sys.servers 
WHERE server_id != 0;