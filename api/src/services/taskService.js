const Task = require("../models/Task");
const TaskShare = require("../models/TaskShare");
const TaskActivity = require("../models/TaskActivity");
const User = require("../models/User");
const { createNotification } = require("./notificationService");
const { sendAndLogEmail } = require("./emailService");
const { deadlineReminderTemplate } = require("../utils/emailTemplates");

async function logTaskActivity({ taskId, userId, action, details = {} }) {
  if (!taskId || !userId) return null;
  return TaskActivity.create({
    taskId,
    userId,
    action,
    details,
  });
}

async function getAccessibleTaskFilter(userId, scope = "all") {
  const shares = await TaskShare.find({ userId }).select("taskId permission");
  const sharedTaskIds = shares.map((s) => s.taskId);

  if (scope === "created") {
    return { createdBy: userId };
  }
  if (scope === "assigned") {
    return {
      $or: [{ assigneeIds: userId }, { primaryAssigneeId: userId }],
    };
  }
  if (scope === "shared") {
    return { _id: { $in: sharedTaskIds } };
  }

  return {
    $or: [
      { createdBy: userId },
      { assigneeIds: userId },
      { primaryAssigneeId: userId },
      { _id: { $in: sharedTaskIds } },
    ],
  };
}

/**
 * Tac vu dinh ky kiem tra va gui thong bao + email nhac viec truoc han (VD: 24h)
 */
async function checkAndSendDeadlineReminders() {
  try {
    const reminderHours = Number(process.env.REMINDER_HOURS_BEFORE || 24);
    const now = new Date();
    const upcomingLimit = new Date(now.getTime() + reminderHours * 3600 * 1000);

    const tasks = await Task.find({
      status: { $ne: "completed" },
      dueDate: { $gt: now, $lte: upcomingLimit },
      reminderSentAt: null,
    })
      .populate("createdBy", "fullName email")
      .populate("assigneeIds", "fullName email")
      .populate("primaryAssigneeId", "fullName email");

    for (const task of tasks) {
      const recipientsMap = new Map();
      if (task.createdBy && task.createdBy.email) {
        recipientsMap.set(String(task.createdBy._id), task.createdBy);
      }
      for (const a of task.assigneeIds || []) {
        if (a && a.email) {
          recipientsMap.set(String(a._id), a);
        }
      }
      if (task.primaryAssigneeId && task.primaryAssigneeId.email) {
        recipientsMap.set(String(task.primaryAssigneeId._id), task.primaryAssigneeId);
      }

      for (const [uid, user] of recipientsMap.entries()) {
        await createNotification({
          userId: uid,
          taskId: task._id,
          type: "deadline_reminder",
          title: "Nhắc việc sắp đến hạn",
          message: `Công việc "${task.title}" sẽ đến hạn vào ${new Date(
            task.dueDate
          ).toLocaleString("vi-VN")}.`,
        });

        const tpl = deadlineReminderTemplate({
          recipientName: user.fullName,
          task,
        });
        await sendAndLogEmail({
          taskId: task._id,
          recipientEmail: user.email,
          eventType: "deadline_reminder",
          subject: tpl.subject,
          html: tpl.html,
        });
      }

      task.reminderSentAt = new Date();
      await task.save();
    }
  } catch (err) {
    console.error("Deadline reminder check error:", err.message);
  }
}

module.exports = {
  logTaskActivity,
  getAccessibleTaskFilter,
  checkAndSendDeadlineReminders,
};
