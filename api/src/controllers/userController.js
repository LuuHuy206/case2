const User = require("../models/User");

exports.searchUsers = async (req, res) => {
  try {
    const q = String(req.query.q || "").trim();
    const filter = {};

    if (q) {
      filter.$or = [
        { fullName: { $regex: q, $options: "i" } },
        { email: { $regex: q, $options: "i" } },
      ];
    }

    const users = await User.find(filter)
      .select("_id fullName email avatarUrl createdAt")
      .limit(30)
      .sort({ fullName: 1 });

    return res.status(200).json({
      success: true,
      count: users.length,
      users: users.map((u) => ({
        id: u._id,
        _id: u._id,
        fullName: u.fullName,
        email: u.email,
        avatarUrl: u.avatarUrl || "",
      })),
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: "Khong the tim kiem nguoi dung.",
      error: error.message,
    });
  }
};

exports.getUserById = async (req, res) => {
  try {
    const user = await User.findById(req.params.id).select(
      "_id fullName email avatarUrl createdAt"
    );

    if (!user) {
      return res.status(404).json({
        success: false,
        message: "Khong tim thay nguoi dung.",
      });
    }

    return res.status(200).json({
      success: true,
      user: {
        id: user._id,
        _id: user._id,
        fullName: user.fullName,
        email: user.email,
        avatarUrl: user.avatarUrl || "",
        createdAt: user.createdAt,
      },
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: "Khong the lay thong tin nguoi dung.",
      error: error.message,
    });
  }
};
