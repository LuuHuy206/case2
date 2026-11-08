const EmailLog = require("../models/EmailLog");
const { createTransporter, getFromAddress } = require("../config/email");

/**
 * Gui email va ghi log vao collection email_logs.
 * Neu chua cau hinh SMTP trong .env, van luu ban ghi EmailLog de theo doi va cho phep retry sau.
 */
async function sendAndLogEmail({
  taskId = null,
  recipientEmail,
  eventType,
  subject,
  html,
}) {
  if (!recipientEmail) return null;

  // Chong gui trung trong vong 1 phut cung taskId + recipientEmail + eventType + subject
  const oneMinuteAgo = new Date(Date.now() - 60 * 1000);
  const duplicate = await EmailLog.findOne({
    taskId,
    recipientEmail: recipientEmail.toLowerCase().trim(),
    eventType,
    subject,
    status: "sent",
    createdAt: { $gte: oneMinuteAgo },
  });
  if (duplicate) {
    return duplicate;
  }

  const emailLog = await EmailLog.create({
    taskId,
    recipientEmail: recipientEmail.toLowerCase().trim(),
    eventType,
    subject,
    htmlBody: html || "",
    status: "pending",
    attempts: 1,
  });

  const transporter = createTransporter();
  if (!transporter) {
    emailLog.status = "failed";
    emailLog.errorMessage =
      "Chua cau hinh SMTP (SMTP_HOST, SMTP_USER, SMTP_PASS) trong file .env";
    await emailLog.save();
    return emailLog;
  }

  try {
    await transporter.sendMail({
      from: getFromAddress(),
      to: recipientEmail,
      subject,
      html,
    });

    emailLog.status = "sent";
    emailLog.sentAt = new Date();
    emailLog.errorMessage = "";
    await emailLog.save();
  } catch (error) {
    emailLog.status = "failed";
    emailLog.errorMessage = error.message || "Gui email that bai";
    await emailLog.save();
  }

  return emailLog;
}

async function retryEmailById(emailLogId) {
  const emailLog = await EmailLog.findById(emailLogId);
  if (!emailLog) {
    throw new Error("Khong tim thay ban ghi email log.");
  }

  if (emailLog.status === "sent") {
    return emailLog;
  }

  emailLog.attempts = (emailLog.attempts || 0) + 1;
  const transporter = createTransporter();

  if (!transporter) {
    emailLog.status = "failed";
    emailLog.errorMessage =
      "Chua cau hinh SMTP (SMTP_HOST, SMTP_USER, SMTP_PASS) trong file .env";
    await emailLog.save();
    return emailLog;
  }

  try {
    await transporter.sendMail({
      from: getFromAddress(),
      to: emailLog.recipientEmail,
      subject: emailLog.subject,
      html: emailLog.htmlBody || `<p>${emailLog.subject}</p>`,
    });
    emailLog.status = "sent";
    emailLog.sentAt = new Date();
    emailLog.errorMessage = "";
    await emailLog.save();
  } catch (error) {
    emailLog.status = "failed";
    emailLog.errorMessage = error.message || "Thu gui lai email that bai";
    await emailLog.save();
  }

  return emailLog;
}

module.exports = {
  sendAndLogEmail,
  retryEmailById,
};
