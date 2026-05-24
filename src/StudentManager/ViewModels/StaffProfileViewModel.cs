using System;
using System.Data;
using System.Windows.Input;
using Dapper;
using StudentManager.Helpers;
using StudentManager.Models;

namespace StudentManager.ViewModels
{
    public class StaffProfileViewModel : ViewModelBase
    {
        private string _manv = "";
        public string Manv { get => _manv; set => SetProperty(ref _manv, value); }

        private string _hoten = "";
        public string Hoten { get => _hoten; set => SetProperty(ref _hoten, value); }

        private string _email = "";
        public string Email { get => _email; set => SetProperty(ref _email, value); }

        private string _tendn = "";
        public string Tendn { get => _tendn; set => SetProperty(ref _tendn, value); }

        private string _pubkey = "";
        public string Pubkey { get => _pubkey; set => SetProperty(ref _pubkey, value); }

        private string _statusMessage = "";
        public string StatusMessage { get => _statusMessage; set => SetProperty(ref _statusMessage, value); }

        private string _viewSalaryPassword = "";
        public string ViewSalaryPassword
        {
            get => _viewSalaryPassword;
            set => SetProperty(ref _viewSalaryPassword, value);
        }

        private string _decryptedLuongcb = "";
        public string DecryptedLuongcb
        {
            get => _decryptedLuongcb;
            set => SetProperty(ref _decryptedLuongcb, value);
        }

        public ICommand LoadDecryptedSalaryCommand { get; }

        public StaffProfileViewModel()
        {
            LoadDecryptedSalaryCommand = new RelayCommand(_ => LoadDecryptedSalary());
            LoadProfile();
        }

        private void LoadProfile()
        {
            Manv = CurrentUser.MANV;
            Hoten = CurrentUser.HOTEN;
            Email = CurrentUser.EMAIL ?? "";
            Tendn = CurrentUser.TENDN;
            Pubkey = CurrentUser.PUBKEY;
        }

        private void LoadDecryptedSalary()
        {
            if (string.IsNullOrWhiteSpace(ViewSalaryPassword))
            {
                StatusMessage = "Vui lòng nhập mật khẩu để xem lương cơ bản.";
                return;
            }

            try
            {
                using var conn = DatabaseHelper.GetConnection();
                var row = conn.QueryFirstOrDefault<NhanVien>(
                    "SP_SEL_PUBLIC_NHANVIEN",
                    new { TENDN = CurrentUser.TENDN, MK = ViewSalaryPassword },
                    commandType: CommandType.StoredProcedure);

                if (row == null)
                {
                    DecryptedLuongcb = "";
                    StatusMessage = "Mật khẩu xác thực không đúng.";
                    return;
                }

                DecryptedLuongcb = row.LUONGCB ?? "0";
                StatusMessage = "Đã giải mã lương cơ bản thành công.";
                DatabaseHelper.LogQuery("EXEC SP_SEL_PUBLIC_NHANVIEN", new { TENDN = CurrentUser.TENDN });
            }
            catch (Exception ex)
            {
                DecryptedLuongcb = "";
                StatusMessage = UserFacingMessage.ForSalaryQuery(ex);
            }
        }
    }
}
