const mongoose = require("mongoose");
const Task = require("../models/Task");
const TaskShare = require("../models/TaskShare");

/**
 * Xac dinh quyen cua user tren 1 task:
 * - owner: nguoi tao (createdBy) -> full quyen (xem, sua, xoa, giao viec, chia se)
 * - assignee: nguoi duoc giao (assigneeIds / primaryAssigneeId) -> xem, cap nhat trang thai, sua noi dung
 * - editor: duoc chia se voi permission = 'editor' -> xem, sua thong tin va trang thai (khong duoc xoa hoac quan ly chia se)
 * - viewer: duoc chia se voi permission = 'viewer' -> chi xem
 */
async function resolveTaskAccess(taskId, userId) {
  if (!mongoose.Types.ObjectId.isValid(taskId)) {
    return { task: null, role: null, canView: false, canEdit: false, isOwner: false };
  }

  const task = await Task.findById(taskId)
    .populate("createdBy", "fullName email avatarUrl")
    .populate("assigneeIds", "fullName email avatarUrl")
    .populate("primaryAssigneeId", "fullName email avatarUrl");

  if (!task) {
    return { task: null, role: null, canView: false, canEdit: false, isOwner: false };
  }

  const uid = String(userId);
  const creatorId = String(task.createdBy?._id || task.createdBy);
  if (creatorId === uid) {
    return {
      task,
      role: "owner",
      permission: "owner",
      canView: true,
      canEdit: true,
      canUpdateStatus: true,
      canManage: true,
      isOwner: true,
    };
  }

  const isAssignee =
    (task.assigneeIds || []).some((a) => String(a?._id || a) === uid) ||
    (task.primaryAssigneeId && String(task.primaryAssigneeId?._id || task.primaryAssigneeId) === uid);

  const share = await TaskShare.findOne({ taskId: task._id, userId });

  if (share && share.permission === "editor") {
    return {
      task,
      role: isAssignee ? "assignee" : "shared_editor",
      permission: "editor",
      canView: true,
      canEdit: true,
      canUpdateStatus: true,
      canManage: false,
      isOwner: false,
    };
  }

  if (isAssignee) {
    return {
      task,
      role: "assignee",
      permission: "editor",
      canView: true,
      canEdit: true,
      canUpdateStatus: true,
      canManage: false,
      isOwner: false,
    };
  }

  if (share && share.permission === "viewer") {
    return {
      task,
      role: "shared_viewer",
      permission: "viewer",
      canView: true,
      canEdit: false,
      canUpdateStatus: false,
      canManage: false,
      isOwner: false,
    };
  }

  return {
    task,
    role: null,
    permission: null,
    canView: false,
    canEdit: false,
    canUpdateStatus: false,
    canManage: false,
    isOwner: false,
  };
}

function requireTaskAccess(requiredLevel = "view") {
  return async (req, res, next) => {
    try {
      const taskId = req.params.id || req.params.taskId;
      const access = await resolveTaskAccess(taskId, req.user.id);

      if (!access.task) {
        return res.status(404).json({
          success: false,
          message: "Khong tim thay cong viec.",
        });
      }

      if (!access.canView) {
        return res.status(403).json({
          success: false,
          message: "Ban khong co quyen truy cap cong viec nay.",
        });
      }

      if (requiredLevel === "edit" && !access.canEdit) {
        return res.status(403).json({
          success: false,
          message: "Ban chi co quyen xem (viewer), khong duoc chinh sua cong viec nay.",
        });
      }

      if (requiredLevel === "status" && !access.canUpdateStatus) {
        return res.status(403).json({
          success: false,
          message: "Ban chi co quyen xem (viewer), khong duoc doi trang thai cong viec.",
        });
      }

      if (requiredLevel === "owner" && !access.isOwner) {
        return res.status(403).json({
          success: false,
          message: "Chi nguoi tao cong viec moi co quyen thuc hien thao tac nay.",
        });
      }

      req.task = access.task;
      req.taskAccess = access;
      next();
    } catch (error) {
      next(error);
    }
  };
}

module.exports = {
  resolveTaskAccess,
  requireTaskAccess,
};
