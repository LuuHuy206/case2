const express = require("express");
const authMiddleware = require("../middleware/authMiddleware");
const { retryEmail } = require("../controllers/emailLogController");

const router = express.Router();

router.use(authMiddleware);
router.post("/:id/retry", retryEmail);

module.exports = router;
