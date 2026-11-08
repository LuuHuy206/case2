const express = require("express");
const authMiddleware = require("../middleware/authMiddleware");
const { validateObjectId } = require("../middleware/validateMiddleware");
const { searchUsers, getUserById } = require("../controllers/userController");

const router = express.Router();

router.use(authMiddleware);
router.get("/search", searchUsers);
router.get("/:id", validateObjectId("id"), getUserById);

module.exports = router;
