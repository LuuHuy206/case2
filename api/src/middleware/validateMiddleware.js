const mongoose = require("mongoose");

function validateObjectId(paramName = "id") {
  return (req, res, next) => {
    const val = req.params[paramName];
    if (val && !mongoose.Types.ObjectId.isValid(val)) {
      return res.status(400).json({
        success: false,
        message: `Tham so ${paramName} khong hop le.`,
      });
    }
    next();
  };
}

module.exports = {
  validateObjectId,
};
