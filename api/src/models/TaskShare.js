const mongoose = require("mongoose");

const taskShareSchema = new mongoose.Schema(
  {
    taskId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Task",
      required: true,
      index: true,
    },
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
      index: true,
    },
    permission: {
      type: String,
      enum: ["viewer", "editor"],
      default: "viewer",
      required: true,
    },
    sharedBy: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
    },
  },
  {
    timestamps: { createdAt: true, updatedAt: false },
    collection: "task_shares",
  }
);

// Unique compound index cho taskId + userId de tranh ban ghi chia se trung nhau
taskShareSchema.index({ taskId: 1, userId: 1 }, { unique: true });

module.exports =
  mongoose.models.TaskShare || mongoose.model("TaskShare", taskShareSchema);
