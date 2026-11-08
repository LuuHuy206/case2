const Notification = require("../models/Notification");

exports.getNotifications = async (req, res) => {
  try {
    const notifications = await Notification.find({ userId: req.user.id })
      .populate("taskId", "title status priority dueDate")
      .sort({ createdAt: -1 })
      .limit(100);

    return res.status(200).json({
      success: true,
      count: notifications.length,
      notifications,
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: "Khong the lay danh sach thong bao.",
      error: error.message,
    });
  }
};

exports.getUnreadCount = async (req, res) => {
  try {
    const unreadCount = await Notification.countDocuments({
      userId: req.user.id,
      isRead: false,
    });

    return res.status(200).json({
      success: true,
      unreadCount,
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: "Khong the dem thong bao chua doc.",
      error: error.message,
    });
  }
};

exports.markAsRead = async (req, res) => {
  try {
    const notification = await Notification.findOneAndUpdate(
      { _id: req.params.id, userId: req.user.id },
      { isRead: true },
      { new: true }
    );

    if (!notification) {
      return res.status(404).json({
        success: false,
        message: "Khong tim thay thong bao.",
      });
    }

    return res.status(200).json({
      success: true,
      message: "Da danh dau da doc.",
      notification,
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: "Khong the cap nhat thong bao.",
      error: error.message,
    });
  }
};

exports.markAllAsRead = async (req, res) => {
  try {
    await Notification.updateMany(
      { userId: req.user.id, isRead: false },
      { isRead: true }
    );

    return res.status(200).json({
      success: true,
      message: "Da danh dau tat ca thong bao la da doc.",
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: "Khong the danh dau tat ca da doc.",
      error: error.message,
    });
  }
};
