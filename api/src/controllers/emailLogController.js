const EmailLog = require("../models/EmailLog");
const { retryEmailById } = require("../services/emailService");
const { resolveTaskAccess } = require("../middleware/permissionMiddleware");

exports.getTaskEmailLogs = async (req, res) => {
  try {
    const logs = await EmailLog.find({ taskId: req.task._id }).sort({
      createdAt: -1,
    });

    return res.status(200).json({
      success: true,
      count: logs.length,
      emailLogs: logs,
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: "Khong the lay lich su gui email.",
      error: error.message,
    });
  }
};

exports.retryEmail = async (req, res) => {
  try {
    const log = await EmailLog.findById(req.params.id);
    if (!log) {
      return res.status(404).json({
        success: false,
        message: "Khong tim thay ban ghi email.",
      });
    }

    if (log.taskId) {
      const access = await resolveTaskAccess(log.taskId, req.user.id);
      if (!access.canEdit && !access.isOwner) {
        return res.status(403).json({
          success: false,
          message: "Ban khong co quyen thu gui lai email nay.",
        });
      }
    }

    const updatedLog = await retryEmailById(log._id);
    return res.status(200).json({
      success: true,
      message:
        updatedLog.status === "sent"
          ? "Thu gui lai email thanh cong!"
          : "Da thu gui lai email nhung chua thanh cong.",
      emailLog: updatedLog,
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: "Khong the thu gui lai email.",
      error: error.message,
    });
  }
};
