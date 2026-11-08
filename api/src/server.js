require("dotenv").config();

const app = require("./app");
const connectDatabase = require("./config/database");
const { checkAndSendDeadlineReminders } = require("./services/taskService");

const PORT = process.env.PORT || 3000;

async function startServer() {
  try {
    const connected = await connectDatabase();

    app.listen(PORT, "0.0.0.0", () => {
      console.log(`Task Manager API dang chay tai port ${PORT}`);
      console.log(`Kiem tra: http://localhost:${PORT}/api/health`);
    });

    if (connected) {
      // Kiem tra nhac viec truoc han dinh ky moi 15 phut
      setInterval(() => {
        checkAndSendDeadlineReminders();
      }, 15 * 60 * 1000);
    }
  } catch (error) {
    console.error("Khong the khoi dong server:", error.message);
    process.exit(1);
  }
}

startServer();
