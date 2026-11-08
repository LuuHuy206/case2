const express = require("express");
const authMiddleware = require("../middleware/authMiddleware");
const { requireTaskAccess } = require("../middleware/permissionMiddleware");
const { validateObjectId } = require("../middleware/validateMiddleware");
const {
  validateCreateTask,
  validateUpdateTask,
} = require("../validators/taskValidator");
const {
  createTask,
  getTasks,
  getTaskById,
  updateTask,
  updateTaskStatus,
  deleteTask,
  getTaskActivities,
} = require("../controllers/taskController");
const { getTaskEmailLogs } = require("../controllers/emailLogController");
const assignmentRoutes = require("./assignmentRoutes");
const taskShareRoutes = require("./taskShareRoutes");

const router = express.Router();

router.use(authMiddleware);

router.get("/", getTasks);
router.post("/", validateCreateTask, createTask);
router.get("/:id", validateObjectId("id"), requireTaskAccess("view"), getTaskById);
router.put(
  "/:id",
  validateObjectId("id"),
  requireTaskAccess("edit"),
  validateUpdateTask,
  updateTask
);
router.delete("/:id", validateObjectId("id"), requireTaskAccess("owner"), deleteTask);
router.patch(
  "/:id/status",
  validateObjectId("id"),
  requireTaskAccess("status"),
  updateTaskStatus
);
router.get(
  "/:id/activities",
  validateObjectId("id"),
  requireTaskAccess("view"),
  getTaskActivities
);
router.get(
  "/:id/email-logs",
  validateObjectId("id"),
  requireTaskAccess("view"),
  getTaskEmailLogs
);

// Sub-routes cho giao viec & chia se
router.use("/:id/assignees", validateObjectId("id"), assignmentRoutes);
router.use("/:id/shares", validateObjectId("id"), taskShareRoutes);

module.exports = router;
