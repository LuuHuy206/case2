const Task = require("../models/Task");
const TaskShare = require("../models/TaskShare");
const TaskActivity = require("../models/TaskActivity");
const Notification = require("../models/Notification");
const EmailLog = require("../models/EmailLog");
const User = require("../models/User");
const { normalizeStatus } = require("../validators/taskValidator");
const {
  logTaskActivity,
  getAccessibleTaskFilter,
} = require("../services/taskService");
const { notifyMultipleUsers } = require("../services/notificationService");
const { sendAndLogEmail } = require("../services/emailService");
const {
  taskUpdatedTemplate,
  taskCompletedTemplate,
} = require("../utils/emailTemplates");

const PRIORITY_RANK = { high: 3, medium: 2, low: 1 };

async function enrichTasksWithShareAndRole(tasks, userId) {
  const uid = String(userId);
  const taskIds = tasks.map((t) => t._id);
  const shares = await TaskShare.find({ taskId: { $in: taskIds } }).populate(
    "userId",
    "fullName email avatarUrl"
  );

  const shareMap = new Map();
  for (const s of shares) {
    const tid = String(s.taskId);
    if (!shareMap.has(tid)) shareMap.set(tid, []);
    shareMap.get(tid).push({
      id: s._id,
      _id: s._id,
      taskId: s.taskId,
      user: s.userId,
      userId: s.userId?._id || s.userId,
      permission: s.permission,
      createdAt: s.createdAt,
    });
  }

  return tasks.map((t) => {
    const obj = t.toObject ? t.toObject() : t;
    const creatorId = String(obj.createdBy?._id || obj.createdBy);
    const isOwner = creatorId === uid;
    const isAssignee =
      (obj.assigneeIds || []).some((a) => String(a?._id || a) === uid) ||
      (obj.primaryAssigneeId &&
        String(obj.primaryAssigneeId?._id || obj.primaryAssigneeId) === uid);
    const taskShares = shareMap.get(String(obj._id)) || [];
    const myShare = taskShares.find(
      (s) => String(s.user?._id || s.userId) === uid
    );

    let myRole = "viewer";
    let myPermission = "viewer";
    if (isOwner) {
      myRole = "owner";
      myPermission = "owner";
    } else if (isAssignee) {
      myRole = "assignee";
      myPermission = "editor";
    } else if (myShare) {
      myRole = `shared_${myShare.permission}`;
      myPermission = myShare.permission;
    }

    return {
      ...obj,
      shares: taskShares,
      myRole,
      myPermission,
      canEdit: isOwner || isAssignee || myPermission === "editor",
      canDelete: isOwner,
      canManageAccess: isOwner,
    };
  });
}

exports.createTask = async (req, res) => {
  try {
    const {
      title,
      description,
      status,
      priority,
      startDate,
      dueDate,
      assigneeIds,
      primaryAssigneeId,
    } = req.body;

    const normalizedStatus = normalizeStatus(status) || "todo";

    const task = await Task.create({
      title: title.trim(),
      description: description ? description.trim() : "",
      status: normalizedStatus,
      priority: priority || "medium",
      startDate: startDate || null,
      dueDate: dueDate || null,
      createdBy: req.user.id,
      assigneeIds: Array.isArray(assigneeIds) ? assigneeIds : [],
      primaryAssigneeId: primaryAssigneeId || null,
    });

    await logTaskActivity({
      taskId: task._id,
      userId: req.user.id,
      action: "create_task",
      details: { title: task.title, status: task.status, priority: task.priority },
    });

    const populated = await Task.findById(task._id)
      .populate("createdBy", "fullName email avatarUrl")
      .populate("assigneeIds", "fullName email avatarUrl")
      .populate("primaryAssigneeId", "fullName email avatarUrl");

    const [enriched] = await enrichTasksWithShareAndRole([populated], req.user.id);

    return res.status(201).json({
      success: true,
      message: "Tao cong viec thanh cong!",
      task: enriched,
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: "Khong the tao cong viec.",
      error: error.message,
    });
  }
};

exports.getTasks = async (req, res) => {
  try {
    const {
      scope = "all",
      status,
      priority,
      assigneeId,
      q,
      search,
      sortBy = "createdAt",
      order = "desc",
    } = req.query;

    const accessFilter = await getAccessibleTaskFilter(req.user.id, scope);
    const andConditions = [accessFilter];

    if (status) {
      const norm = normalizeStatus(status);
      if (norm === "in_progress") {
        andConditions.push({ status: { $in: ["in_progress", "in-progress"] } });
      } else {
        andConditions.push({ status: norm });
      }
    }

    if (priority) {
      andConditions.push({ priority });
    }

    if (assigneeId) {
      andConditions.push({
        $or: [{ assigneeIds: assigneeId }, { primaryAssigneeId: assigneeId }],
      });
    }

    const keyword = (q || search || "").trim();
    if (keyword) {
      andConditions.push({
        $or: [
          { title: { $regex: keyword, $options: "i" } },
          { description: { $regex: keyword, $options: "i" } },
        ],
      });
    }

    const query =
      andConditions.length === 1 ? andConditions[0] : { $and: andConditions };

    const sortDir = order === "asc" ? 1 : -1;
    let sortObj = { createdAt: -1 };
    if (sortBy === "dueDate") {
      sortObj = { dueDate: sortDir, createdAt: -1 };
    } else if (sortBy === "createdAt") {
      sortObj = { createdAt: sortDir };
    }

    let tasks = await Task.find(query)
      .populate("createdBy", "fullName email avatarUrl")
      .populate("assigneeIds", "fullName email avatarUrl")
      .populate("primaryAssigneeId", "fullName email avatarUrl")
      .sort(sortObj);

    if (sortBy === "priority") {
      tasks = tasks.sort((a, b) => {
        const diff =
          (PRIORITY_RANK[b.priority] || 0) - (PRIORITY_RANK[a.priority] || 0);
        return order === "asc" ? -diff : diff;
      });
    }

    const enriched = await enrichTasksWithShareAndRole(tasks, req.user.id);

    return res.status(200).json({
      success: true,
      count: enriched.length,
      tasks: enriched,
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: "Khong the lay danh sach cong viec.",
      error: error.message,
    });
  }
};

exports.getTaskById = async (req, res) => {
  try {
    const [enriched] = await enrichTasksWithShareAndRole(
      [req.task],
      req.user.id
    );
    return res.status(200).json({
      success: true,
      task: enriched,
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: "Khong the lay chi tiet cong viec.",
      error: error.message,
    });
  }
};

exports.updateTask = async (req, res) => {
  try {
    const task = req.task;
    const {
      title,
      description,
      status,
      priority,
      startDate,
      dueDate,
    } = req.body;

    const changes = {};
    const oldDueDate = task.dueDate ? new Date(task.dueDate).toISOString() : null;
    const oldStatus = task.status;

    if (title !== undefined) {
      changes.title = { from: task.title, to: title.trim() };
      task.title = title.trim();
    }
    if (description !== undefined) {
      task.description = description.trim();
    }
    if (status !== undefined) {
      const norm = normalizeStatus(status);
      changes.status = { from: task.status, to: norm };
      task.status = norm;
    }
    if (priority !== undefined) {
      changes.priority = { from: task.priority, to: priority };
      task.priority = priority;
    }
    if (startDate !== undefined) {
      task.startDate = startDate || null;
    }
    if (dueDate !== undefined) {
      task.dueDate = dueDate || null;
      task.reminderSentAt = null;
    }

    await task.save();

    await logTaskActivity({
      taskId: task._id,
      userId: req.user.id,
      action: "update_task",
      details: changes,
    });

    const newDueDate = task.dueDate ? new Date(task.dueDate).toISOString() : null;
    const dueDateChanged = dueDate !== undefined && oldDueDate !== newDueDate;
    const becameCompleted =
      oldStatus !== "completed" && task.status === "completed";

    // Tim danh sach thanh vien lien quan de thong bao & gui email
    const actor = await User.findById(req.user.id);
    const actorName = actor ? actor.fullName : req.user.email;

    const shares = await TaskShare.find({ taskId: task._id }).populate(
      "userId",
      "fullName email"
    );

    const relatedUsersMap = new Map();
    if (task.createdBy && task.createdBy._id) {
      relatedUsersMap.set(String(task.createdBy._id), task.createdBy);
    }
    for (const a of task.assigneeIds || []) {
      if (a && a._id) relatedUsersMap.set(String(a._id), a);
    }
    for (const s of shares) {
      if (s.userId && s.userId._id) {
        relatedUsersMap.set(String(s.userId._id), s.userId);
      }
    }

    if (becameCompleted) {
      await notifyMultipleUsers({
        userIds: Array.from(relatedUsersMap.keys()),
        excludeUserId: req.user.id,
        taskId: task._id,
        type: "task_completed",
        title: "Công việc đã hoàn thành",
        message: `${actorName} đã đánh dấu hoàn thành công việc "${task.title}".`,
      });

      for (const [uid, u] of relatedUsersMap.entries()) {
        if (uid !== String(req.user.id) && u.email) {
          const tpl = taskCompletedTemplate({
            recipientName: u.fullName,
            actorName,
            task,
          });
          await sendAndLogEmail({
            taskId: task._id,
            recipientEmail: u.email,
            eventType: "task_completed",
            subject: tpl.subject,
            html: tpl.html,
          });
        }
      }
    } else if (dueDateChanged || changes.priority || changes.title) {
      const changeNote = dueDateChanged
        ? "Hạn hoàn thành công việc đã được thay đổi."
        : "Thông tin quan trọng của công việc đã được cập nhật.";

      await notifyMultipleUsers({
        userIds: Array.from(relatedUsersMap.keys()),
        excludeUserId: req.user.id,
        taskId: task._id,
        type: "task_updated",
        title: "Cập nhật công việc",
        message: `${actorName} đã cập nhật công việc "${task.title}".`,
      });

      for (const [uid, u] of relatedUsersMap.entries()) {
        if (uid !== String(req.user.id) && u.email) {
          const tpl = taskUpdatedTemplate({
            recipientName: u.fullName,
            actorName,
            task,
            changeNote,
          });
          await sendAndLogEmail({
            taskId: task._id,
            recipientEmail: u.email,
            eventType: "task_updated",
            subject: tpl.subject,
            html: tpl.html,
          });
        }
      }
    }

    const populated = await Task.findById(task._id)
      .populate("createdBy", "fullName email avatarUrl")
      .populate("assigneeIds", "fullName email avatarUrl")
      .populate("primaryAssigneeId", "fullName email avatarUrl");

    const [enriched] = await enrichTasksWithShareAndRole(
      [populated],
      req.user.id
    );

    return res.status(200).json({
      success: true,
      message: "Cap nhat cong viec thanh cong!",
      task: enriched,
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: "Khong the cap nhat cong viec.",
      error: error.message,
    });
  }
};

exports.updateTaskStatus = async (req, res) => {
  try {
    const task = req.task;
    const { status } = req.body;
    const norm = normalizeStatus(status);

    if (!norm || !["todo", "in_progress", "completed"].includes(norm)) {
      return res.status(400).json({
        success: false,
        message: "Trang thai khong hop le (todo, in_progress, completed).",
      });
    }

    const oldStatus = task.status;
    task.status = norm;
    await task.save();

    await logTaskActivity({
      taskId: task._id,
      userId: req.user.id,
      action: "change_status",
      details: { from: oldStatus, to: norm },
    });

    const actor = await User.findById(req.user.id);
    const actorName = actor ? actor.fullName : req.user.email;

    const recipientIds = [
      task.createdBy?._id || task.createdBy,
      ...(task.assigneeIds || []).map((a) => a?._id || a),
    ];

    await notifyMultipleUsers({
      userIds: recipientIds,
      excludeUserId: req.user.id,
      taskId: task._id,
      type: norm === "completed" ? "task_completed" : "task_status_changed",
      title:
        norm === "completed"
          ? "Công việc đã hoàn thành"
          : "Thay đổi trạng thái công việc",
      message: `${actorName} đã chuyển trạng thái "${task.title}" sang ${norm}.`,
    });

    if (norm === "completed" && oldStatus !== "completed") {
      const users = await User.find({ _id: { $in: recipientIds } });
      for (const u of users) {
        if (String(u._id) !== String(req.user.id) && u.email) {
          const tpl = taskCompletedTemplate({
            recipientName: u.fullName,
            actorName,
            task,
          });
          await sendAndLogEmail({
            taskId: task._id,
            recipientEmail: u.email,
            eventType: "task_completed",
            subject: tpl.subject,
            html: tpl.html,
          });
        }
      }
    }

    const [enriched] = await enrichTasksWithShareAndRole([task], req.user.id);

    return res.status(200).json({
      success: true,
      message: "Cap nhat trang thai thanh cong!",
      task: enriched,
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: "Khong the cap nhat trang thai.",
      error: error.message,
    });
  }
};

exports.deleteTask = async (req, res) => {
  try {
    const taskId = req.task._id;
    await Task.findByIdAndDelete(taskId);
    await TaskShare.deleteMany({ taskId });
    await Notification.deleteMany({ taskId });
    await TaskActivity.deleteMany({ taskId });
    await EmailLog.deleteMany({ taskId });

    return res.status(200).json({
      success: true,
      message: "Xoa cong viec thanh cong!",
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: "Khong the xoa cong viec.",
      error: error.message,
    });
  }
};

exports.getTaskActivities = async (req, res) => {
  try {
    const activities = await TaskActivity.find({ taskId: req.task._id })
      .populate("userId", "fullName email avatarUrl")
      .sort({ createdAt: -1 });

    return res.status(200).json({
      success: true,
      count: activities.length,
      activities,
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: "Khong the lay lich su hoat dong.",
      error: error.message,
    });
  }
};
