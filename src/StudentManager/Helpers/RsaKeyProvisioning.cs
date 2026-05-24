namespace StudentManager.Helpers
{
    public static class RsaKeyProvisioning
    {
        public static void EnsureLocalKeyPair(string manv, int keySize = 512)
        {
            if (CryptoHelper.HasLocalKeyPair(manv))
                return;

            var keys = CryptoHelper.GenerateRSAKeyPair(keySize);
            CryptoHelper.SavePublicKeyLocal(manv, keys.PublicKeyXml);
            CryptoHelper.SavePrivateKeyLocal(manv, keys.PrivateKeyXml);
        }

        public static void RegenerateLocalKeyPair(string manv, int keySize = 512)
        {
            var keys = CryptoHelper.GenerateRSAKeyPair(keySize);
            CryptoHelper.SavePublicKeyLocal(manv, keys.PublicKeyXml);
            CryptoHelper.SavePrivateKeyLocal(manv, keys.PrivateKeyXml);
        }

        public static void GenerateAndSaveLocal(string manv, int keySize = 512)
        {
            var keys = CryptoHelper.GenerateRSAKeyPair(keySize);
            CryptoHelper.SavePublicKeyLocal(manv, keys.PublicKeyXml);
            CryptoHelper.SavePrivateKeyLocal(manv, keys.PrivateKeyXml);
        }
    }
}
