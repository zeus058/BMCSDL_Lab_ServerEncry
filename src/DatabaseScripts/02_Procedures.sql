USE QLSVNhom;
GO

-- Câu ci) SP_INS_PUBLIC_NHANVIEN: Thêm nhân viên mới và khởi tạo khóa RSA
CREATE OR ALTER PROCEDURE SP_INS_PUBLIC_NHANVIEN
    @MANV VARCHAR(20),
    @HOTEN NVARCHAR(100),
    @EMAIL VARCHAR(20),
    @LUONGCB VARCHAR(50),
    @TENDN NVARCHAR(100),
    @MK NVARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRANSACTION;
    BEGIN TRY
        -- Kiểm tra trùng mã nhân viên
        IF EXISTS (SELECT 1 FROM NHANVIEN WHERE MANV = @MANV)
            THROW 50001, N'Mã nhân viên đã tồn tại.', 1;

        -- Kiểm tra trùng tên đăng nhập
        IF EXISTS (SELECT 1 FROM NHANVIEN WHERE TENDN = @TENDN)
            THROW 50002, N'Tên đăng nhập đã tồn tại.', 1;

        -- Khởi tạo Asymmetric Key (RSA) dựa trên Mã nhân viên nếu chưa có
        IF NOT EXISTS (SELECT 1 FROM sys.asymmetric_keys WHERE name = @MANV)
        BEGIN
            DECLARE @Sql NVARCHAR(MAX) = N'CREATE ASYMMETRIC KEY ' + QUOTENAME(@MANV)
                     + N' WITH ALGORITHM = RSA_2048 ENCRYPTION BY PASSWORD = N' -- Hiện tại SQL không hỗ trợ RSA_512 nữa nên em đổi thành RSA_2048 phù hợp với thực tế
                     + QUOTENAME(@MK, '''');
            EXEC sys.sp_executesql @Sql;
        END

        -- Mã hóa lương cơ bản bằng Asymmetric Key vừa tạo
        DECLARE @EncryptedLuong VARBINARY(MAX) = EncryptByAsymKey(AsymKey_ID(@MANV), CONVERT(VARBINARY(MAX), @LUONGCB));

        -- Sử dụng TENDN làm Pseudo-Salt khi băm mật khẩu
        INSERT INTO NHANVIEN (MANV, HOTEN, EMAIL, LUONG, TENDN, MATKHAU, PUBKEY)
        VALUES (@MANV, @HOTEN, @EMAIL, @EncryptedLuong, @TENDN, HASHBYTES('SHA1', @TENDN + '|' + @MK), @MANV);

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK;
        DECLARE @ErrMsg NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR(@ErrMsg, 16, 1);
    END CATCH
END
GO

/* EXEC SP_INS_PUBLIC_NHANVIEN 'NV13', 'TRAN GIA HIEN', 'TGH@', 3000000, 'TGH', 'abcd12'
SELECT * FROM NHANVIEN;
GO */

-- Câu cii) SP_SEL_PUBLIC_NHANVIEN: Lấy thông tin nhân viên (bao gồm giải mã lương)
CREATE OR ALTER PROCEDURE SP_SEL_PUBLIC_NHANVIEN
    @TENDN NVARCHAR(100),
    @MK NVARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;
    -- Sử dụng COLLATE để so khớp chính xác hoa thường cho bảo mật
    SELECT
        n.MANV,
        n.HOTEN,
        n.EMAIL,
        CONVERT(VARCHAR(50), DecryptByAsymKey(AsymKey_ID(n.PUBKEY), n.LUONG, @MK)) AS LUONGCB,
        n.PUBKEY,
        n.TENDN
    FROM NHANVIEN n
    WHERE n.TENDN = @TENDN COLLATE SQL_Latin1_General_CP1_CS_AS
      AND n.MATKHAU = HASHBYTES('SHA1', @TENDN + '|' + @MK);
END
GO

/* EXEC SP_SEL_PUBLIC_NHANVIEN 'TGH', 'abcd12'
GO */

-- Câu d)
-- SP_LOGIN_NHANVIEN: Xác thực đăng nhập nhân viên
CREATE OR ALTER PROCEDURE SP_LOGIN_NHANVIEN
    @LOGIN NVARCHAR(100),
    @MK NVARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;
    SELECT TOP (1) MANV, HOTEN, EMAIL, TENDN, PUBKEY
    FROM NHANVIEN
    WHERE MANV = @LOGIN COLLATE SQL_Latin1_General_CP1_CS_AS
      AND MATKHAU = HASHBYTES('SHA1', TENDN + '|' + @MK);
END
GO

-- SP_SEL_LOP_BY_OWNER: Lấy danh sách lớp do nhân viên quản lý
CREATE OR ALTER PROCEDURE SP_SEL_LOP_BY_OWNER
    @CALLER_MANV VARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;
    SELECT MALOP, TENLOP, MANV
    FROM LOP
    WHERE MANV = @CALLER_MANV
    ORDER BY MALOP;
END
GO

-- SP_INS_LOP: Thêm lớp học mới
CREATE OR ALTER PROCEDURE SP_INS_LOP
    @CALLER_MANV VARCHAR(20),
    @MALOP VARCHAR(20),
    @TENLOP NVARCHAR(100),
    @MANV VARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;
    -- Ràng buộc: Chỉ được tạo lớp cho chính mình phụ trách
    IF @MANV <> @CALLER_MANV
        THROW 50003, N'Chỉ được tạo lớp do chính mình phụ trách.', 1;

    INSERT INTO LOP (MALOP, TENLOP, MANV)
    VALUES (@MALOP, @TENLOP, @MANV);
END
GO

-- SP_UPD_LOP: Cập nhật thông tin lớp học
CREATE OR ALTER PROCEDURE SP_UPD_LOP
    @CALLER_MANV VARCHAR(20),
    @MALOP VARCHAR(20),
    @TENLOP NVARCHAR(100),
    @NEW_MANV VARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE LOP
    SET TENLOP = @TENLOP, MANV = @NEW_MANV
    WHERE MALOP = @MALOP;
END
GO

-- SP_DEL_LOP: Xóa lớp học (Kiểm tra điều kiện ràng buộc)
CREATE OR ALTER PROCEDURE SP_DEL_LOP
    @CALLER_MANV VARCHAR(20),
    @MALOP VARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (SELECT 1 FROM LOP WHERE MALOP = @MALOP AND MANV = @CALLER_MANV)
        THROW 50005, N'Không có quyền xóa lớp này.', 1;

    IF EXISTS (SELECT 1 FROM SINHVIEN WHERE MALOP = @MALOP)
        THROW 50006, N'Lớp vẫn còn sinh viên, không thể xóa.', 1;

    DELETE FROM LOP WHERE MALOP = @MALOP;
END
GO

-- SP_SEL_SINHVIEN_BY_OWNER: Lấy danh sách sinh viên thuộc các lớp do nhân viên quản lý
CREATE OR ALTER PROCEDURE SP_SEL_SINHVIEN_BY_OWNER
    @CALLER_MANV VARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;
    SELECT s.MASV, s.HOTEN, s.NGAYSINH, s.DIACHI, s.MALOP, s.TENDN
    FROM SINHVIEN s
    INNER JOIN LOP l ON l.MALOP = s.MALOP
    WHERE l.MANV = @CALLER_MANV
    ORDER BY s.MALOP, s.MASV;
END
GO

-- SP_INS_SINHVIEN: Thêm sinh viên mới (Hash mật khẩu SHA1)
CREATE OR ALTER PROCEDURE SP_INS_SINHVIEN
    @CALLER_MANV VARCHAR(20),
    @MASV VARCHAR(20),
    @HOTEN NVARCHAR(100),
    @NGAYSINH DATETIME,
    @DIACHI NVARCHAR(200),
    @MALOP VARCHAR(20),
    @TENDN NVARCHAR(100),
    @MK NVARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;
    -- Kiểm tra quyền quản lý lớp trước khi thêm sinh viên
    IF NOT EXISTS (SELECT 1 FROM LOP WHERE MALOP = @MALOP AND MANV = @CALLER_MANV)
        THROW 50008, N'Không có quyền thêm sinh viên vào lớp này.', 1;

    INSERT INTO SINHVIEN (MASV, HOTEN, NGAYSINH, DIACHI, MALOP, TENDN, MATKHAU)
    VALUES (@MASV, @HOTEN, @NGAYSINH, @DIACHI, @MALOP, @TENDN, HASHBYTES('SHA1', @TENDN + '|' + @MK));
END
GO

-- SP_DEL_SINHVIEN_BY_OWNER: Xóa sinh viên và bảng điểm liên quan
CREATE OR ALTER PROCEDURE SP_DEL_SINHVIEN_BY_OWNER
    @CALLER_MANV VARCHAR(20),
    @MASV VARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (
        SELECT 1 FROM SINHVIEN s
        INNER JOIN LOP l ON l.MALOP = s.MALOP
        WHERE s.MASV = @MASV AND l.MANV = @CALLER_MANV
    )
        THROW 50011, N'Không có quyền xóa sinh viên này.', 1;

    BEGIN TRANSACTION;
    BEGIN TRY
        DELETE FROM BANGDIEM WHERE MASV = @MASV;
        DELETE FROM SINHVIEN WHERE MASV = @MASV;
        COMMIT;
    END TRY
    BEGIN CATCH
        ROLLBACK;
        THROW;
    END CATCH
END
GO

-- SP_UPSERT_BANGDIEM: Cập nhật hoặc thêm mới điểm
CREATE OR ALTER PROCEDURE SP_UPSERT_BANGDIEM
    @CALLER_MANV VARCHAR(20),
    @MASV VARCHAR(20),
    @MAHP VARCHAR(20),
    @DIEMTHI VARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;
    -- Kiểm tra quyền quản lý sinh viên trước khi nhập điểm
    IF NOT EXISTS (
        SELECT 1 FROM SINHVIEN s
        INNER JOIN LOP l ON l.MALOP = s.MALOP
        WHERE s.MASV = @MASV AND l.MANV = @CALLER_MANV
    )
        THROW 50013, N'Không có quyền nhập điểm cho sinh viên này.', 1;

    -- Lấy tên Asymmetric Key của nhân viên để mã hóa điểm
    DECLARE @KeyName VARCHAR(20);
    SELECT @KeyName = PUBKEY FROM NHANVIEN WHERE MANV = @CALLER_MANV;

    -- Mã hóa điểm bằng Asymmetric Key (RSA) tại Database
    DECLARE @EncryptedDiem VARBINARY(MAX) = EncryptByAsymKey(AsymKey_ID(@KeyName), CONVERT(VARBINARY(MAX), @DIEMTHI));

    IF EXISTS (SELECT 1 FROM BANGDIEM WHERE MASV = @MASV AND MAHP = @MAHP)
        UPDATE BANGDIEM SET DIEMTHI = @EncryptedDiem WHERE MASV = @MASV AND MAHP = @MAHP;
    ELSE
        INSERT INTO BANGDIEM (MASV, MAHP, DIEMTHI) VALUES (@MASV, @MAHP, @EncryptedDiem);
END
GO

-- SP_SEL_BANGDIEM_DETAILED_BY_STUDENT: Xem bảng điểm chi tiết của sinh viên
CREATE OR ALTER PROCEDURE SP_SEL_BANGDIEM_DETAILED_BY_STUDENT
    @CALLER_MANV VARCHAR(20),
    @MASV VARCHAR(20),
    @MK NVARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;

    -- Lấy tên Asymmetric Key của nhân viên để giải mã điểm
    DECLARE @KeyName VARCHAR(20);
    SELECT @KeyName = PUBKEY FROM NHANVIEN WHERE MANV = @CALLER_MANV;

    SELECT b.MASV, b.MAHP, h.TENHP, h.SOTC,
           CONVERT(VARCHAR(50), DecryptByAsymKey(AsymKey_ID(@KeyName), b.DIEMTHI, @MK)) AS DiemSo
    FROM BANGDIEM b
    INNER JOIN HOCPHAN h ON h.MAHP = b.MAHP
    INNER JOIN SINHVIEN s ON s.MASV = b.MASV
    INNER JOIN LOP l ON l.MALOP = s.MALOP
    WHERE l.MANV = @CALLER_MANV AND b.MASV = @MASV
    ORDER BY b.MAHP;
END
GO

-- SP_SEL_DASHBOARD_SUMMARY: Tổng hợp dữ liệu cho Dashboard
CREATE OR ALTER PROCEDURE SP_SEL_DASHBOARD_SUMMARY
    @CALLER_MANV VARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;
    SELECT 
        (SELECT COUNT(*) FROM LOP WHERE MANV = @CALLER_MANV) AS TotalClasses,
        (SELECT COUNT(*) FROM SINHVIEN s JOIN LOP l ON s.MALOP = l.MALOP WHERE l.MANV = @CALLER_MANV) AS TotalStudents,
        (SELECT COUNT(*) FROM HOCPHAN) AS TotalCourses,
        (SELECT COUNT(*) FROM BANGDIEM b JOIN SINHVIEN s ON b.MASV = s.MASV JOIN LOP l ON s.MALOP = l.MALOP WHERE l.MANV = @CALLER_MANV) AS EnteredGrades;
END
GO

-- SP_SEL_HOCPHAN: Tải danh mục học phần
CREATE OR ALTER PROCEDURE SP_SEL_HOCPHAN AS
BEGIN
    SET NOCOUNT ON;
    SELECT MAHP, TENHP, SOTC FROM HOCPHAN ORDER BY MAHP;
END
GO