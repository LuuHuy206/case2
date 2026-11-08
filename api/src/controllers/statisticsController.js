const Task = require("../models/Task");
const TaskShare = require("../models/TaskShare");
const { getAccessibleTaskFilter } = require("../services/taskService");

exports.getTaskStatusStats = async (req, res) => {
  try {
    const filter = await getAccessibleTaskFilter(req.user.id, "all");
    const tasks = await Task.find(filter).select("status priority");

    let todo = 0;
    let inProgress = 0;
    let completed = 0;

    for (const t of tasks) {
      if (t.status === "completed") completed++;
      else if (t.status === "in_progress" || t.status === "in-progress")
        inProgress++;
      else todo++;
    }

    return res.status(200).json({
      success: true,
      statistics: {
        total: tasks.length,
        todo,
        in_progress: inProgress,
        completed,
      },
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: "Khong the thong ke cong viec theo trang thai.",
      error: error.message,
    });
  }
};

exports.getAssignmentStats = async (req, res) => {
  try {
    const userId = req.user.id;
    const [createdCount, assignedToMeCount, primaryCount, sharedWithMeCount] =
      await Promise.all([
        Task.countDocuments({ createdBy: userId }),
        Task.countDocuments({
          $or: [{ assigneeIds: userId }, { primaryAssigneeId: userId }],
        }),
        Task.countDocuments({ primaryAssigneeId: userId }),
        TaskShare.countDocuments({ userId }),
      ]);

    const delegatedCount = await Task.countDocuments({
      createdBy: userId,
      "assigneeIds.0": { $exists: true },
    });

    return res.status(200).json({
      success: true,
      statistics: {
        createdByMe: createdCount,
        delegatedByMe: delegatedCount,
        assignedToMe: assignedToMeCount,
        primaryAssigneeCount: primaryCount,
        sharedWithMe: sharedWithMeCount,
      },
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: "Khong the thong ke giao viec.",
      error: error.message,
    });
  }
};

exports.getDeadlineStats = async (req, res) => {
  try {
    const filter = await getAccessibleTaskFilter(req.user.id, "all");
    const now = new Date();
    const upcomingLimit = new Date(now.getTime() + 3 * 24 * 3600 * 1000); // 3 ngay toi

    const activeTasks = await Task.find({
      $and: [
        filter,
        { status: { $ne: "completed" } },
        { dueDate: { $ne: null } },
      ],
    })
      .populate("createdBy", "fullName email")
      .populate("primaryAssigneeId", "fullName email")
      .sort({ dueDate: 1 });

    const overdueTasks = [];
    const upcomingTasks = [];

    for (const t of activeTasks) {
      const due = new Date(t.dueDate);
      if (due < now) {
        overdueTasks.push(t);
      } else if (due <= upcomingLimit) {
        upcomingTasks.push(t);
      }
    }

    return res.status(200).json({
      success: true,
      statistics: {
        overdueCount: overdueTasks.length,
        upcomingCount: upcomingTasks.length,
        overdueTasks,
        upcomingTasks,
      },
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: "Khong the thong ke han hoan thanh.",
      error: error.message,
    });
  }
};
