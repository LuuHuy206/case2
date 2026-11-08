const express = require("express");
const authMiddleware = require("../middleware/authMiddleware");
const { requireTaskAccess } = require("../middleware/permissionMiddleware");
const {
  getTaskShares,
  shareTask,
  updateSharePermission,
  revokeShare,
} = require("../controllers/taskShareController");

const router = express.Router({ mergeParams: true });

router.use(authMiddleware);
router.get("/", requireTaskAccess("view"), getTaskShares);
router.post("/", requireTaskAccess("owner"), shareTask);
router.patch("/:shareId", requireTaskAccess("owner"), updateSharePermission);
router.delete("/:shareId", requireTaskAccess("owner"), revokeShare);

module.exports = router;
