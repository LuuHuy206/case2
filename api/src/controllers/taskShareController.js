const TaskShare = require("../models/TaskShare");
const User = require("../models/User");
const { logTaskActivity } = require("../services/taskService");
const { createNotification } = require("../services/notificationService");
const { sendAndLogEmail } = require("../services/emailService");
const { taskSharedTemplate } = require("../utils/emailTemplates");

exports.getTaskShares = async (req, res) => {
  try {
    const shares = await TaskShare.find({ taskId: req.task._id })
      .populate("userId", "fullName email avatarUrl")
      .populate("sharedBy", "fullName email")
      .sort({ createdAt: -1 });

    return res.status(200).json({
      success: true,
      count: shares.length,
      shares: shares.map((s) => ({
        id: s._id,
        _id: s._id,
        taskId: s.taskId,
        user: s.userId,
        userId: s.userId?._id || s.userId,
        permission: s.permission,
        sharedBy: s.sharedBy,
        createdAt: s.createdAt,
      })),
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: "Khong the lay danh sach chia se.",
      error: error.message,
    });
  }
};

exports.shareTask = async (req, res) => {
  try {
    const task = req.task;
    const {
      userIds = [],
      emails = [],
      userId,
      email,
      permission = "viewer",
    } = req.body;

    if (!["viewer", "editor"].includes(permission)) {
      return res.status(400).json({
        success: false,
        message: "Quyen chia se phai la 'viewer' hoac 'editor'.",
      });
    }

    const idsToLookup = [...(Array.isArray(userIds) ? userIds : [])];
    if (userId) idsToLookup.push(userId);

    const emailsToLookup = [...(Array.isArray(emails) ? emails : [])];
    if (email) emailsToLookup.push(email);

    const targetUsers = [];
    if (idsToLookup.length > 0) {
      const byIds = await User.find({ _id: { $in: idsToLookup } });
      targetUsers.push(...byIds);
    }
    if (emailsToLookup.length > 0) {
      const norm = emailsToLookup.map((e) => String(e).trim().toLowerCase());
      const byEmails = await User.find({ email: { $in: norm } });
      targetUsers.push(...byEmails);
    }

    if (targetUsers.length === 0) {
      return res.status(400).json({
        success: false,
        message: "Khong tim thay nguoi dung de chia se.",
      });
    }

    const actor = await User.findById(req.user.id);
    const actorName = actor ? actor.fullName : req.user.email;

    const createdShares = [];
    for (const u of targetUsers) {
      if (String(u._id) === String(task.createdBy?._id || task.createdBy)) {
        continue;
      }

      const share = await TaskShare.findOneAndUpdate(
        { taskId: task._id, userId: u._id },
        {
          taskId: task._id,
          userId: u._id,
          permission,
          sharedBy: req.user.id,
        },
        { upsert: true, new: true, setDefaultsOnInsert: true }
      ).populate("userId", "fullName email avatarUrl");

      createdShares.push(share);

      await createNotification({
        userId: u._id,
        taskId: task._id,
        type: "task_shared",
        title: "Công việc được chia sẻ với bạn",
        message: `${actorName} đã chia sẻ công việc "${task.title}" với quyền ${
          permission === "editor" ? "Chỉnh sửa" : "Chỉ xem"
        }.`,
      });

      const tpl = taskSharedTemplate({
        recipientName: u.fullName,
        actorName,
        task,
        permission,
      });

      await sendAndLogEmail({
        taskId: task._id,
        recipientEmail: u.email,
        eventType: "task_shared",
        subject: tpl.subject,
        html: tpl.html,
      });
    }

    await logTaskActivity({
      taskId: task._id,
      userId: req.user.id,
      action: "share_task",
      details: {
        sharedWith: targetUsers.map((u) => u.email),
        permission,
      },
    });

    return res.status(200).json({
      success: true,
      message: "Chia se cong viec thanh cong!",
      shares: createdShares,
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: "Khong the chia se cong viec.",
      error: error.message,
    });
  }
};

exports.updateSharePermission = async (req, res) => {
  try {
    const { shareId } = req.params;
    const { permission } = req.body;

    if (!["viewer", "editor"].includes(permission)) {
      return res.status(400).json({
        success: false,
        message: "Quyen chia se phai la 'viewer' hoac 'editor'.",
      });
    }

    const share = await TaskShare.findOneAndUpdate(
      { _id: shareId, taskId: req.task._id },
      { permission },
      { new: true }
    ).populate("userId", "fullName email avatarUrl");

    if (!share) {
      return res.status(404).json({
        success: false,
        message: "Khong tim thay ban ghi chia se.",
      });
    }

    await logTaskActivity({
      taskId: req.task._id,
      userId: req.user.id,
      action: "update_share_permission",
      details: { shareId, permission },
    });

    return res.status(200).json({
      success: true,
      message: "Cap nhat quyen chia se thanh cong!",
      share,
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: "Khong the cap nhat quyen chia se.",
      error: error.message,
    });
  }
};

exports.revokeShare = async (req, res) => {
  try {
    const { shareId } = req.params;
    const deleted = await TaskShare.findOneAndDelete({
      _id: shareId,
      taskId: req.task._id,
    });

    if (!deleted) {
      return res.status(404).json({
        success: false,
        message: "Khong tim thay ban ghi chia se.",
      });
    }

    await logTaskActivity({
      taskId: req.task._id,
      userId: req.user.id,
      action: "revoke_share",
      details: { revokedUserId: deleted.userId },
    });

    return res.status(200).json({
      success: true,
      message: "Da thu hoi quyen chia se.",
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: "Khong the thu hoi quyen chia se.",
      error: error.message,
    });
  }
};
