const express = require("express");
const {
  register,
  login,
  getProfile,
  updateProfile,
  changePassword,
} = require("../controllers/authController");
const authMiddleware = require("../middleware/authMiddleware");
const {
  validateRegister,
  validateLogin,
  validateChangePassword,
} = require("../validators/authValidator");

const router = express.Router();

router.post("/register", validateRegister, register);
router.post("/login", validateLogin, login);

// Ho tro ca /me (theo dac ta 6.1) va /profile (tuong thich nguoc Buoi 1)
router.get("/me", authMiddleware, getProfile);
router.get("/profile", authMiddleware, getProfile);
router.put("/me", authMiddleware, updateProfile);
router.put("/change-password", authMiddleware, validateChangePassword, changePassword);

module.exports = router;
