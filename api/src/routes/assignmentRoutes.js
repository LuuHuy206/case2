const express = require("express");
const authMiddleware = require("../middleware/authMiddleware");
const { requireTaskAccess } = require("../middleware/permissionMiddleware");
const {
  getAssignees,
  assignTask,
  updateAssigneeRole,
  removeAssignee,
} = require("../controllers/assignmentController");

const router = express.Router({ mergeParams: true });

router.use(authMiddleware);
router.get("/", requireTaskAccess("view"), getAssignees);
router.post("/", requireTaskAccess("edit"), assignTask);
router.patch("/:userId", requireTaskAccess("edit"), updateAssigneeRole);
router.delete("/:userId", requireTaskAccess("owner"), removeAssignee);

module.exports = router;
