const express = require("express");
const authMiddleware = require("../middleware/authMiddleware");
const {
  getTaskStatusStats,
  getAssignmentStats,
  getDeadlineStats,
} = require("../controllers/statisticsController");

const router = express.Router();

router.use(authMiddleware);
router.get("/tasks", getTaskStatusStats);
router.get("/assignments", getAssignmentStats);
router.get("/deadlines", getDeadlineStats);

module.exports = router;
