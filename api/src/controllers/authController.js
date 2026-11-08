const bcrypt = require("bcryptjs");
const jwt = require("jsonwebtoken");
const User = require("../models/User");

function createToken(user) {
  const secret = process.env.JWT_SECRET || "default_dev_jwt_secret";
  return jwt.sign(
    {
      id: user._id.toString(),
      email: user.email,
      fullName: user.fullName,
    },
    secret,
    {
      expiresIn: process.env.JWT_EXPIRES_IN || "7d",
    }
  );
}

function serializeUser(user) {
  return {
    id: user._id,
    _id: user._id,
    fullName: user.fullName,
    email: user.email,
    avatarUrl: user.avatarUrl || "",
    createdAt: user.createdAt,
    updatedAt: user.updatedAt,
  };
}

exports.register = async (req, res) => {
  try {
    const { fullName, email, password, avatarUrl } = req.body;

    if (!fullName || !email || !password) {
      return res.status(400).json({
        success: false,
        message: "Vui long nhap ho ten, email va mat khau.",
      });
    }

    if (String(password).length < 8) {
      return res.status(400).json({
        success: false,
        message: "Mat khau phai co it nhat 8 ky tu.",
      });
    }

    const normalizedEmail = email.trim().toLowerCase();
    const existingUser = await User.findOne({ email: normalizedEmail });

    if (existingUser) {
      return res.status(400).json({
        success: false,
        message: "Email nay da duoc su dung.",
      });
    }

    const salt = await bcrypt.genSalt(10);
    const hashedPassword = await bcrypt.hash(password, salt);

    const user = await User.create({
      fullName: fullName.trim(),
      email: normalizedEmail,
      password: hashedPassword,
      passwordHash: hashedPassword,
      avatarUrl: avatarUrl ? String(avatarUrl).trim() : "",
    });

    const token = createToken(user);

    return res.status(201).json({
      success: true,
      message: "Dang ky tai khoan thanh cong!",
      token,
      user: serializeUser(user),
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: "Khong the dang ky tai khoan.",
      error: error.message,
    });
  }
};

exports.login = async (req, res) => {
  try {
    const { email, password } = req.body;

    if (!email || !password) {
      return res.status(400).json({
        success: false,
        message: "Vui long nhap email va mat khau.",
      });
    }

    const normalizedEmail = email.trim().toLowerCase();
    const user = await User.findOne({ email: normalizedEmail }).select(
      "+password +passwordHash"
    );

    if (!user) {
      return res.status(401).json({
        success: false,
        message: "Email hoac mat khau khong dung.",
      });
    }

    const storedHash = user.password || user.passwordHash;
    const isMatch = await bcrypt.compare(password, storedHash);

    if (!isMatch) {
      return res.status(401).json({
        success: false,
        message: "Email hoac mat khau khong dung.",
      });
    }

    const token = createToken(user);

    return res.status(200).json({
      success: true,
      message: "Dang nhap thanh cong!",
      token,
      user: serializeUser(user),
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: "Khong the dang nhap.",
      error: error.message,
    });
  }
};

exports.getProfile = async (req, res) => {
  try {
    const user = await User.findById(req.user.id);

    if (!user) {
      return res.status(404).json({
        success: false,
        message: "Khong tim thay nguoi dung.",
      });
    }

    return res.status(200).json({
      success: true,
      user: serializeUser(user),
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: "Khong the lay thong tin nguoi dung.",
      error: error.message,
    });
  }
};

exports.updateProfile = async (req, res) => {
  try {
    const { fullName, avatarUrl } = req.body;
    const user = await User.findById(req.user.id);

    if (!user) {
      return res.status(404).json({
        success: false,
        message: "Khong tim thay nguoi dung.",
      });
    }

    if (fullName !== undefined) {
      if (!String(fullName).trim()) {
        return res.status(400).json({
          success: false,
          message: "Ho ten khong duoc de trong.",
        });
      }
      user.fullName = String(fullName).trim();
    }

    if (avatarUrl !== undefined) {
      user.avatarUrl = String(avatarUrl).trim();
    }

    await user.save();

    return res.status(200).json({
      success: true,
      message: "Cap nhat thong tin ca nhan thanh cong!",
      user: serializeUser(user),
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: "Khong the cap nhat thong tin ca nhan.",
      error: error.message,
    });
  }
};

exports.changePassword = async (req, res) => {
  try {
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

    const user = await User.findById(req.user.id).select(
      "+password +passwordHash"
    );

    if (!user) {
      return res.status(404).json({
        success: false,
        message: "Khong tim thay nguoi dung.",
      });
    }

    const storedHash = user.password || user.passwordHash;
    const isMatch = await bcrypt.compare(currentPassword, storedHash);

    if (!isMatch) {
      return res.status(400).json({
        success: false,
        message: "Mat khau hien tai khong chinh xac.",
      });
    }

    const salt = await bcrypt.genSalt(10);
    const hashed = await bcrypt.hash(newPassword, salt);
    user.password = hashed;
    user.passwordHash = hashed;
    await user.save();

    return res.status(200).json({
      success: true,
      message: "Doi mat khau thanh cong!",
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: "Khong the doi mat khau.",
      error: error.message,
    });
  }
};
