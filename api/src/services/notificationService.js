const Notification = require("../models/Notification");

async function createNotification({
  userId,
  taskId = null,
  type = "task_updated",
  title,
  message,
}) {
  if (!userId) return null;
  return Notification.create({
    userId,
    taskId,
    type,
    title,
    message,
    isRead: false,
  });
}

async function notifyMultipleUsers({
  userIds = [],
  excludeUserId = null,
  taskId = null,
  type = "task_updated",
  title,
  message,
}) {
  const uniqueIds = Array.from(
    new Set(
      userIds
        .filter(Boolean)
        .map((id) => String(id))
        .filter((id) => !excludeUserId || id !== String(excludeUserId))
    )
  );

  if (uniqueIds.length === 0) return [];

  const docs = uniqueIds.map((uid) => ({
    userId: uid,
    taskId,
    type,
    title,
    message,
    isRead: false,
  }));

  return Notification.insertMany(docs);
}

module.exports = {
  createNotification,
  notifyMultipleUsers,
};
