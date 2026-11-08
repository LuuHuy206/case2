function errorMiddleware(err, req, res, next) {
  console.error("API Error:", err.message);
  const statusCode = err.statusCode || 500;
  res.status(statusCode).json({
    success: false,
    message: err.message || "Loi he thong may chu.",
  });
}

module.exports = errorMiddleware;
