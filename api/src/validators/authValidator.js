function isValidEmail(email) {
  return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(String(email || "").trim());
}

exports.validateRegister = (req, res, next) => {
  const { fullName, email, password } = req.body;
  if (!fullName || !email || !password) {
    return res.status(400).json({
      success: false,
      message: "Vui long nhap ho ten, email va mat khau.",
    });
  }
  if (!isValidEmail(email)) {
    return res.status(400).json({
      success: false,
      message: "Dinh dang email khong hop le.",
    });
  }
  if (String(password).length < 8) {
    return res.status(400).json({
      success: false,
      message: "Mat khau phai co it nhat 8 ky tu.",
    });
  }
  next();
};

exports.validateLogin = (req, res, next) => {
  const { email, password } = req.body;
  if (!email || !password) {
    return res.status(400).json({
      success: false,
      message: "Vui long nhap email va mat khau.",
    });
  }
  next();
};

exports.validateChangePassword = (req, res, next) => {
  const { currentPassword, newPassword } = req.body;
  if (!currentPassword || !newPassword) {
    return res.status(400).json({
      success: false,
      message: "Vui long nhap mat khau hien tai va mat khau moi.",
    });
  }
  if (String(newPassword).length < 8) {
    return res.status(400).json({
      success: false,
      message: "Mat khau moi phai co it nhat 8 ky tu.",
    });
  }
  next();
};
