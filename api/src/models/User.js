const mongoose = require("mongoose");

const userSchema = new mongoose.Schema(
  {
    fullName: {
      type: String,
      required: [true, "Ho ten la bat buoc"],
      trim: true,
      maxlength: 100,
    },
    email: {
      type: String,
      required: [true, "Email la bat buoc"],
      unique: true,
      lowercase: true,
      trim: true,
      index: true,
    },
    password: {
      type: String,
      required: [true, "Mat khau la bat buoc"],
      minlength: 8,
      select: false,
    },
    passwordHash: {
      type: String,
      select: false,
    },
    avatarUrl: {
      type: String,
      default: "",
      trim: true,
    },
  },
  {
    timestamps: true,
  }
);

userSchema.pre("save", function (next) {
  if (this.password && !this.passwordHash) {
    this.passwordHash = this.password;
  } else if (this.passwordHash && !this.password) {
    this.password = this.passwordHash;
  }
  next();
});

module.exports = mongoose.models.User || mongoose.model("User", userSchema);
