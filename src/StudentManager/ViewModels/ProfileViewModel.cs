using System;
using System.Data;
using System.Windows.Input;
using Dapper;
using StudentManager.Helpers;
using StudentManager.Models;

namespace StudentManager.ViewModels
{
    public class ProfileViewModel : ViewModelBase
    {
        public string MANV => CurrentUser.MANV;
        public string HOTEN => CurrentUser.HOTEN;
        public string EMAIL => CurrentUser.EMAIL;
        public string TENDN => CurrentUser.TENDN;
        public string PublicKeyPath => CryptoHelper.GetPublicKeyPath(CurrentUser.MANV);
        public string PrivateKeyPath => CryptoHelper.GetPrivateKeyPath(CurrentUser.MANV);

        private string _decryptedSalary = "••••••";
        public string DecryptedSalary
        {
            get => _decryptedSalary;
            set => SetProperty(ref _decryptedSalary, value);
        }

        private string _keyStatus = "";
        public string KeyStatus
        {
            get => _keyStatus;
            set => SetProperty(ref _keyStatus, value);
        }

        private string _oldPassword = "";
        public string OldPassword
        {
            get => _oldPassword;
            set => SetProperty(ref _oldPassword, value);
        }

        private string _newPassword = "";
        public string NewPassword
        {
            get => _newPassword;
            set => SetProperty(ref _newPassword, value);
        }

        private string _confirmPassword = "";
        public string ConfirmPassword
        {
            get => _confirmPassword;
            set => SetProperty(ref _confirmPassword, value);
        }

        private string _statusMessage = "";
        public string StatusMessage
        {
            get => _statusMessage;
            set => SetProperty(ref _statusMessage, value);
        }

        public ICommand ShowSalaryCommand { get; }
        public ICommand GenerateNewKeysCommand { get; }
        public ICommand ChangePasswordCommand { get; }

        public ProfileViewModel()
        {
            ShowSalaryCommand = new RelayCommand(_ => DecryptSalary());
            GenerateNewKeysCommand = new RelayCommand(_ => GenerateKeys());
            ChangePasswordCommand = new RelayCommand(_ => ChangePassword(), _ => !string.IsNullOrWhiteSpace(OldPassword) && !string.IsNullOrWhiteSpace(NewPassword));
            RefreshKeyStatus();
        }

        private void RefreshKeyStatus()
        {
            KeyStatus = CryptoHelper.HasLocalKeyPair(CurrentUser.MANV)
                ? "Đã có đủ public/private key local cho nhập điểm."
                : "Chưa có đủ cặp khóa local. Hãy tạo lại khóa trước khi nhập điểm.";
        }

        private void DecryptSalary()
        {
            try
            {
                using var conn = DatabaseHelper.GetConnection();
                var user = conn.QueryFirstOrDefault<NhanVien>(
                    "SP_SEL_PUBLIC_NHANVIEN",
                    new
                    {
                        TENDN = CurrentUser.TENDN,
                        MK = CurrentUser.CurrentPassword
                    },
                    commandType: CommandType.StoredProcedure);

                if (user == null)
                {
                    StatusMessage = "Không lấy được thông tin lương. Kiểm tra tên đăng nhập và mật khẩu đăng nhập hiện tại.";
                    return;
                }

                DecryptedSalary = user.LUONGCB ?? "(trống)";
                DatabaseHelper.LogQuery("EXEC SP_SEL_PUBLIC_NHANVIEN", new { TENDN = CurrentUser.TENDN });
            }
            catch (Exception ex)
            {
                StatusMessage = UserFacingMessage.ForSalaryQuery(ex);
            }
        }

        private void GenerateKeys()
        {
            try
            {
                RsaKeyProvisioning.RegenerateLocalKeyPair(CurrentUser.MANV);
                RefreshKeyStatus();
                StatusMessage = "Đã tạo lại cặp khóa cục bộ (thư mục Keys) để nhập bảng điểm.";
            }
            catch (Exception ex)
            {
                StatusMessage = UserFacingMessage.ForLocalKey(ex);
            }
        }

        private void ChangePassword()
        {
            if (NewPassword != ConfirmPassword)
            {
                StatusMessage = "Mật khẩu xác nhận chưa khớp.";
                return;
            }

            try
            {
                using var conn = DatabaseHelper.GetConnection();
                conn.Execute(
                    "UPDATE NHANVIEN SET MATKHAU = HASHBYTES('SHA1', TENDN + '|' + @MK_NEW) WHERE TENDN = @TENDN AND MATKHAU = HASHBYTES('SHA1', TENDN + '|' + @MK_OLD)",
                    new
                    {
                        TENDN = CurrentUser.TENDN,
                        MK_OLD = OldPassword,
                        MK_NEW = NewPassword
                    },
                    commandType: CommandType.Text);

                CurrentUser.CurrentPassword = NewPassword;
                OldPassword = "";
                NewPassword = "";
                ConfirmPassword = "";
                StatusMessage = "Đã đổi mật khẩu thành công.";
                DatabaseHelper.LogQuery("UPDATE NHANVIEN SET MATKHAU", new { TENDN = CurrentUser.TENDN });
            }
            catch (Exception ex)
            {
                StatusMessage = UserFacingMessage.ForSave(ex);
            }
        }
    }
}
