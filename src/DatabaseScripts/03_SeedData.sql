/* =============================================================
   HỆ THỐNG QUẢN LÝ SINH VIÊN (STUDENT MANAGEMENT SYSTEM)
   Script 03: Khởi tạo dữ liệu mẫu (Seed Data)
   -------------------------------------------------------------
   Mục tiêu:
   - Cung cấp dữ liệu ban đầu để chạy thử nghiệm ứng dụng.
   - Bao gồm: 2 Nhân viên, 8 Lớp học, 3 Học phần, 100 Sinh viên.
   - Các tài khoản được thiết lập sẵn với mật khẩu demo.
   ============================================================= */

USE QLSVNhom;
GO

-- Sử dụng Transaction để đảm bảo tính nhất quán của dữ liệu
BEGIN TRANSACTION;
BEGIN TRY

    /* -------------------------------------------------------------
       1. KHỞI TẠO NHÂN VIÊN (NHANVIEN)
       Ghi chú: Mật khẩu được Hash SHA1, Lương được mã hóa RSA.
       ------------------------------------------------------------- */
    -- Nhân viên 1: Quản lý các lớp lẻ
    EXEC SP_INS_PUBLIC_NHANVIEN
        @MANV = 'NV01',
        @HOTEN = N'Nguyễn Văn A',
        @EMAIL = 'nva@fit.hcmus.vn',
        @LUONGCB = '3000000',
        @TENDN = 'nva',
        @MK = 'abcd12';

    -- Nhân viên 2: Quản lý các lớp chẵn
    EXEC SP_INS_PUBLIC_NHANVIEN
        @MANV = 'NV02',
        @HOTEN = N'Trần Thị B',
        @EMAIL = 'ttb@fit.hcmus.vn',
        @LUONGCB = '4500000',
        @TENDN = 'ttb',
        @MK = 'pass123';

    /* -------------------------------------------------------------
       2. KHỞI TẠO LỚP HỌC (LOP)
       Ghi chú: Phân bổ 4 lớp cho mỗi nhân viên.
       ------------------------------------------------------------- */
    INSERT INTO LOP (MALOP, TENLOP, MANV)
    VALUES
        ('CQ2019/1', N'Chính quy 2019 Lớp 1', 'NV01'),
        ('CQ2019/2', N'Chính quy 2019 Lớp 2', 'NV02'),
        ('CQ2020/1', N'Chính quy 2020 Lớp 1', 'NV01'),
        ('CQ2020/2', N'Chính quy 2020 Lớp 2', 'NV02'),
        ('CQ2021/1', N'Chính quy 2021 Lớp 1', 'NV01'),
        ('CQ2021/2', N'Chính quy 2021 Lớp 2', 'NV02'),
        ('CQ2022/1', N'Chính quy 2022 Lớp 1', 'NV01'),
        ('CQ2022/2', N'Chính quy 2022 Lớp 2', 'NV02');

    /* -------------------------------------------------------------
       3. KHỞI TẠO HỌC PHẦN (HOCPHAN)
       ------------------------------------------------------------- */
    INSERT INTO HOCPHAN (MAHP, TENHP, SOTC)
    VALUES
        ('CSDL', N'Cơ sở dữ liệu', 4),
        ('BMCSDL', N'Bảo mật cơ sở dữ liệu', 4),
        ('MANG', N'Mạng máy tính', 3);

    /* -------------------------------------------------------------
       4. KHỞI TẠO SINH VIÊN (SINHVIEN)
       Ghi chú: 100 sinh viên được phân bổ vào các lớp.
       ------------------------------------------------------------- */
    -- Dữ liệu mẫu tiêu biểu cho Lớp CQ2019/1 (NV01 phụ trách)
    INSERT INTO SINHVIEN (MASV, HOTEN, NGAYSINH, DIACHI, MALOP, TENDN, MATKHAU)
    VALUES
        (N'SV01', N'Lê Văn C', '20010512', N'Quận 1', 'CQ2019/1', 'lvc', HASHBYTES('SHA1', 'lvc|sv123')),
        (N'SV02', N'Phạm Thị D', '20010822', N'Quận 3', 'CQ2019/1', 'ptd', HASHBYTES('SHA1', 'ptd|sv123')),
        (N'SV05', N'Lê Thị Thu Hương', '20010315', N'Quận Bình Thạnh', 'CQ2019/1', 'sv05', HASHBYTES('SHA1','sv05|sv123')),
        (N'SV06', N'Nguyễn Minh Quân', '20010722', N'Quận 1', 'CQ2019/1', 'sv06', HASHBYTES('SHA1','sv06|sv123')),
        (N'SV07', N'Trần Thị Phương Lan', '20011108', N'Quận 3', 'CQ2019/1', 'sv07', HASHBYTES('SHA1','sv07|sv123')),
        (N'SV08', N'Phạm Đức Hùng', '20010214', N'Quận 5', 'CQ2019/1', 'sv08', HASHBYTES('SHA1','sv08|sv123')),
        (N'SV09', N'Hoàng Thị Bích Ngọc', '20010930', N'Quận 7', 'CQ2019/1', 'sv09', HASHBYTES('SHA1','sv09|sv123')),
        (N'SV10', N'Vũ Hoàng Long', '20010425', N'Quận 10', 'CQ2019/1', 'sv10', HASHBYTES('SHA1','sv10|sv123')),
        (N'SV11', N'Đỗ Thị Hương Mai', '20010817', N'Quận Phú Nhuận', 'CQ2019/1', 'sv11', HASHBYTES('SHA1','sv11|sv123')),
        (N'SV12', N'Đặng Văn Nam', '20011205', N'Quận Gò Vấp', 'CQ2019/1', 'sv12', HASHBYTES('SHA1','sv12|sv123')),
        (N'SV13', N'Bùi Thị Thúy', '20010619', N'Quận Tân Bình', 'CQ2019/1', 'sv13', HASHBYTES('SHA1','sv13|sv123')),
        (N'SV14', N'Ngô Văn Tuấn', '20010128', N'Quận Bình Thạnh', 'CQ2019/1', 'sv14', HASHBYTES('SHA1','sv14|sv123')),
        (N'SV15', N'Dương Thị Linh', '20011012', N'Quận 2', 'CQ2019/1', 'sv15', HASHBYTES('SHA1','sv15|sv123')),
        (N'SV16', N'Lý Văn Đức', '20010507', N'Quận 4', 'CQ2019/1', 'sv16', HASHBYTES('SHA1','sv16|sv123')),
        (N'SV17', N'Hà Thị Phương', '20010323', N'Quận 6', 'CQ2019/1', 'sv17', HASHBYTES('SHA1','sv17|sv123')),
        (N'SV18', N'Cao Văn Trung', '20010711', N'Quận 8', 'CQ2019/1', 'sv18', HASHBYTES('SHA1','sv18|sv123')),
        (N'SV19', N'Đinh Thị Mai', '20010904', N'Quận 11', 'CQ2019/1', 'sv19', HASHBYTES('SHA1','sv19|sv123')),
        (N'SV20', N'Võ Minh An', '20011116', N'Quận 12', 'CQ2019/1', 'sv20', HASHBYTES('SHA1','sv20|sv123'));

    -- Dữ liệu mẫu cho Lớp CQ2019/2 (NV02 phụ trách)
    INSERT INTO SINHVIEN (MASV, HOTEN, NGAYSINH, DIACHI, MALOP, TENDN, MATKHAU)
    VALUES
        (N'SV03', N'Vũ Hoàng E', '20011105', N'Quận 5', 'CQ2019/2', 'vhe', HASHBYTES('SHA1', 'vhe|sv123')),
        (N'SV04', N'Hoàng Kim F', '20020301', N'Quận 7', 'CQ2019/2', 'hkf', HASHBYTES('SHA1', 'hkf|sv123')),
        ('SV21', N'Lưu Thị Khánh', '20010218', N'Quận 9', 'CQ2019/2', 'sv21', HASHBYTES('SHA1','sv21|sv123')),
        ('SV22', N'Đào Văn Phúc', '20010614', N'Quận Tân Phú', 'CQ2019/2', 'sv22', HASHBYTES('SHA1','sv22|sv123')),
        ('SV23', N'Trịnh Thị Yến', '20010826', N'Quận Bình Tân', 'CQ2019/2', 'sv23', HASHBYTES('SHA1','sv23|sv123')),
        ('SV24', N'Lâm Quốc Bảo', '20011130', N'Quận 12', 'CQ2019/2', 'sv24', HASHBYTES('SHA1','sv24|sv123')),
        ('SV25', N'Nguyễn Thị Thu', '20010405', N'Quận Bình Thạnh', 'CQ2019/2', 'sv25', HASHBYTES('SHA1','sv25|sv123')),
        ('SV26', N'Trần Văn Hải', '20010917', N'Quận 1', 'CQ2019/2', 'sv26', HASHBYTES('SHA1','sv26|sv123')),
        ('SV27', N'Lê Thị Ngọc Anh', '20011022', N'Quận 3', 'CQ2019/2', 'sv27', HASHBYTES('SHA1','sv27|sv123')),
        ('SV28', N'Phạm Thanh Sơn', '20010309', N'Quận 5', 'CQ2019/2', 'sv28', HASHBYTES('SHA1','sv28|sv123')),
        ('SV29', N'Hoàng Thị Trang', '20010712', N'Quận 7', 'CQ2019/2', 'sv29', HASHBYTES('SHA1','sv29|sv123')),
        ('SV30', N'Vũ Văn Cường', '20011215', N'Quận 10', 'CQ2019/2', 'sv30', HASHBYTES('SHA1','sv30|sv123')),
        ('SV31', N'Đỗ Minh Tuấn', '20010508', N'Quận Phú Nhuận', 'CQ2019/2', 'sv31', HASHBYTES('SHA1','sv31|sv123')),
        ('SV32', N'Đặng Thị Hoa', '20010820', N'Quận Gò Vấp', 'CQ2019/2', 'sv32', HASHBYTES('SHA1','sv32|sv123')),
        ('SV33', N'Bùi Quang Huy', '20011104', N'Quận Tân Bình', 'CQ2019/2', 'sv33', HASHBYTES('SHA1','sv33|sv123')),
        ('SV34', N'Ngô Thị Thảo', '20010126', N'Quận Bình Thạnh', 'CQ2019/2', 'sv34', HASHBYTES('SHA1','sv34|sv123')),
        ('SV35', N'Dương Văn Khoa', '20010630', N'Quận 2', 'CQ2019/2', 'sv35', HASHBYTES('SHA1','sv35|sv123')),
        ('SV36', N'Lý Thị Mỹ Duyên', '20011008', N'Quận 4', 'CQ2019/2', 'sv36', HASHBYTES('SHA1','sv36|sv123'));

    COMMIT TRANSACTION;
    PRINT N'Nạp dữ liệu mẫu thành công: 8 lớp, 3 học phần, 100 sinh viên.';
END TRY
BEGIN CATCH
    ROLLBACK TRANSACTION;
    DECLARE @ErrorMsg NVARCHAR(4000) = ERROR_MESSAGE();
    PRINT N'Lỗi khi nạp dữ liệu: ' + @ErrorMsg;
END CATCH
GO
