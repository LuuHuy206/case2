const VALID_STATUSES = ["todo", "in_progress", "in-progress", "completed"];
const VALID_PRIORITIES = ["low", "medium", "high"];

exports.normalizeStatus = (status) => {
  if (!status) return undefined;
  if (status === "in-progress") return "in_progress";
  return status;
};

exports.validateCreateTask = (req, res, next) => {
  const { title, status, priority, startDate, dueDate } = req.body;
  if (!title || String(title).trim() === "") {
    return res.status(400).json({
      success: false,
      message: "Ten cong viec la bat buoc.",
    });
  }
  if (status && !VALID_STATUSES.includes(status)) {
    return res.status(400).json({
      success: false,
      message: "Trang thai cong viec khong hop le.",
    });
  }
  if (priority && !VALID_PRIORITIES.includes(priority)) {
    return res.status(400).json({
      success: false,
      message: "Muc do uu tien khong hop le.",
    });
  }
  if (startDate && dueDate && new Date(startDate) > new Date(dueDate)) {
    return res.status(400).json({
      success: false,
      message: "Ngay bat dau khong duoc lon hon han hoan thanh.",
    });
  }
  next();
};

exports.validateUpdateTask = (req, res, next) => {
  const { title, status, priority } = req.body;
  if (title !== undefined && String(title).trim() === "") {
    return res.status(400).json({
      success: false,
      message: "Ten cong viec khong duoc de rong.",
    });
  }
  if (status !== undefined && !VALID_STATUSES.includes(status)) {
    return res.status(400).json({
      success: false,
      message: "Trang thai cong viec khong hop le.",
    });
  }
  if (priority !== undefined && !VALID_PRIORITIES.includes(priority)) {
    return res.status(400).json({
      success: false,
      message: "Muc do uu tien khong hop le.",
    });
  }
  next();
};
