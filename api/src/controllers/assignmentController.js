const Task = require("../models/Task");
const User = require("../models/User");
const { logTaskActivity } = require("../services/taskService");
const { createNotification } = require("../services/notificationService");
const { sendAndLogEmail } = require("../services/emailService");
const { taskAssignedTemplate } = require("../utils/emailTemplates");

exports.getAssignees = async (req, res) => {
  try {
    const task = await Task.findById(req.task._id)
      .populate("assigneeIds", "fullName email avatarUrl")
      .populate("primaryAssigneeId", "fullName email avatarUrl");

    return res.status(200).json({
      success: true,
      assignees: task.assigneeIds || [],
      primaryAssignee: task.primaryAssigneeId || null,
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: "Khong the lay danh sach nguoi duoc giao.",
      error: error.message,
    });
  }
};

exports.assignTask = async (req, res) => {
  try {
    const task = req.task;
    const { userIds = [], emails = [], primaryAssigneeId } = req.body;

    const targetUsers = [];
    if (Array.isArray(userIds) && userIds.length > 0) {
      const byIds = await User.find({ _id: { $in: userIds } });
      targetUsers.push(...byIds);
    }
    if (Array.isArray(emails) && emails.length > 0) {
      const normalized = emails.map((e) => String(e).trim().toLowerCase());
      const byEmails = await User.find({ email: { $in: normalized } });
      targetUsers.push(...byEmails);
    }

    if (targetUsers.length === 0) {
      return res.status(400).json({
        success: false,
        message: "Vui long chon it nhat mot nguoi phu trach hop le.",
      });
    }

    const existingIds = new Set(
      (task.assigneeIds || []).map((a) => String(a?._id || a))
    );
    const newlyAddedUsers = [];

    for (const u of targetUsers) {
      const uid = String(u._id);
      if (!existingIds.has(uid)) {
        existingIds.add(uid);
        newlyAddedUsers.push(u);
      }
    }

    task.assigneeIds = Array.from(existingIds);

    if (primaryAssigneeId) {
      if (!existingIds.has(String(primaryAssigneeId))) {
        task.assigneeIds.push(primaryAssigneeId);
      }
      task.primaryAssigneeId = primaryAssigneeId;
    } else if (!task.primaryAssigneeId && task.assigneeIds.length > 0) {
      task.primaryAssigneeId = task.assigneeIds[0];
    }

    await task.save();

    const actor = await User.findById(req.user.id);
    const actorName = actor ? actor.fullName : req.user.email;

    await logTaskActivity({
      taskId: task._id,
      userId: req.user.id,
      action: "assign_task",
      details: {
        assignedUserIds: targetUsers.map((u) => u._id),
        primaryAssigneeId: task.primaryAssigneeId,
      },
    });

    // Gui thong bao trong ung dung va email cho nguoi duoc giao
    const notifyTargets = newlyAddedUsers.length > 0 ? newlyAddedUsers : targetUsers;
    for (const recipient of notifyTargets) {
      const isPrimary =
        task.primaryAssigneeId &&
        String(task.primaryAssigneeId) === String(recipient._id);

      await createNotification({
        userId: recipient._id,
        taskId: task._id,
        type: "task_assigned",
        title: "Bạn được giao công việc mới",
        message: `${actorName} đã giao công việc "${task.title}" cho bạn${
          isPrimary ? " (Phụ trách chính)" : ""
        }.`,
      });

      const tpl = taskAssignedTemplate({
        recipientName: recipient.fullName,
        actorName,
        task,
        isPrimary,
      });

      await sendAndLogEmail({
        taskId: task._id,
        recipientEmail: recipient.email,
        eventType: "task_assigned",
        subject: tpl.subject,
        html: tpl.html,
      });
    }

    const populated = await Task.findById(task._id)
      .populate("createdBy", "fullName email avatarUrl")
      .populate("assigneeIds", "fullName email avatarUrl")
      .populate("primaryAssigneeId", "fullName email avatarUrl");

    return res.status(200).json({
      success: true,
      message: "Giao cong viec thanh cong!",
      task: populated,
      assignees: populated.assigneeIds,
      primaryAssignee: populated.primaryAssigneeId,
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: "Khong the giao cong viec.",
      error: error.message,
    });
  }
};

exports.updateAssigneeRole = async (req, res) => {
  try {
    const task = req.task;
    const { userId } = req.params;
    const { isPrimary = true } = req.body;

    const isAssigned = (task.assigneeIds || []).some(
      (a) => String(a?._id || a) === String(userId)
    );

    if (!isAssigned) {
      return res.status(404).json({
        success: false,
        message: "Nguoi dung nay chua nam trong danh sach duoc giao viec.",
      });
    }

    task.primaryAssigneeId = isPrimary ? userId : null;
    await task.save();

    await logTaskActivity({
      taskId: task._id,
      userId: req.user.id,
      action: "set_primary_assignee",
      details: { primaryAssigneeId: task.primaryAssigneeId },
    });

    const populated = await Task.findById(task._id)
      .populate("assigneeIds", "fullName email avatarUrl")
      .populate("primaryAssigneeId", "fullName email avatarUrl");

    return res.status(200).json({
      success: true,
      message: "Cap nhat nguoi phu trach chinh thanh cong!",
      assignees: populated.assigneeIds,
      primaryAssignee: populated.primaryAssigneeId,
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: "Khong the cap nhat vai tro nguoi phu trach.",
      error: error.message,
    });
  }
};

exports.removeAssignee = async (req, res) => {
  try {
    const task = req.task;
    const { userId } = req.params;

    task.assigneeIds = (task.assigneeIds || []).filter(
      (a) => String(a?._id || a) !== String(userId)
    );

    if (
      task.primaryAssigneeId &&
      String(task.primaryAssigneeId?._id || task.primaryAssigneeId) ===
        String(userId)
    ) {
      task.primaryAssigneeId =
        task.assigneeIds.length > 0 ? task.assigneeIds[0] : null;
    }

    await task.save();

    await logTaskActivity({
      taskId: task._id,
      userId: req.user.id,
      action: "remove_assignee",
      details: { removedUserId: userId },
    });

    const populated = await Task.findById(task._id)
      .populate("assigneeIds", "fullName email avatarUrl")
      .populate("primaryAssigneeId", "fullName email avatarUrl");

    return res.status(200).json({
      success: true,
      message: "Da huy giao viec cho nguoi dung.",
      assignees: populated.assigneeIds,
      primaryAssignee: populated.primaryAssigneeId,
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: "Khong the huy giao viec.",
      error: error.message,
    });
  }
};
