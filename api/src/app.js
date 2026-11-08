const express = require("express");
const cors = require("cors");

const authRoutes = require("./routes/authRoutes");
const userRoutes = require("./routes/userRoutes");
const taskRoutes = require("./routes/taskRoutes");
const notificationRoutes = require("./routes/notificationRoutes");
const statisticsRoutes = require("./routes/statisticsRoutes");
const emailLogRoutes = require("./routes/emailLogRoutes");
const errorMiddleware = require("./middleware/errorMiddleware");

const app = express();

app.use(cors());
app.use(express.json());

// API kiem tra server
app.get("/api/health", (req, res) => {
  res.status(200).json({
    success: true,
    message: "Task Manager API dang hoat dong!",
    timestamp: new Date().toISOString(),
  });
});

// 6.1. Xac thuc
app.use("/api/auth", authRoutes);

// 6.2. Nguoi dung
app.use("/api/users", userRoutes);

// 6.3, 6.4, 6.5, 6.8. Cong viec, Giao viec, Chia se, Email logs theo task
app.use("/api/tasks", taskRoutes);

// 6.6. Thong bao
app.use("/api/notifications", notificationRoutes);

// 6.7. Thong ke
app.use("/api/statistics", statisticsRoutes);

// 6.8. Retry email logs
app.use("/api/email-logs", emailLogRoutes);

// Xu ly API khong ton tai
app.use((req, res) => {
  res.status(404).json({
    success: false,
    message: "Khong tim thay API nay.",
  });
});

app.use(errorMiddleware);

module.exports = app;
