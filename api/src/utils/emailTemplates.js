function formatDate(dateVal) {
  if (!dateVal) return "Chưa thiết lập";
  const d = new Date(dateVal);
  if (isNaN(d.getTime())) return "Chưa thiết lập";
  return d.toLocaleDateString("vi-VN") + " " + d.toLocaleTimeString("vi-VN", { hour: "2-digit", minute: "2-digit" });
}

function wrapHtml(title, bodyHtml) {
  return `
    <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; border: 1px solid #e2e8f0; border-radius: 12px; overflow: hidden;">
      <div style="background: #3867F4; color: #ffffff; padding: 18px 24px;">
        <h2 style="margin: 0; font-size: 18px;">${title}</h2>
      </div>
      <div style="padding: 24px; color: #1e293b; line-height: 1.6;">
        ${bodyHtml}
      </div>
      <div style="background: #f8fafc; padding: 14px 24px; color: #64748b; font-size: 12px; text-align: center;">
        Email tự động từ Hệ thống Quản lý và Giao công việc nhóm (Task Manager)
      </div>
    </div>
  `;
}

exports.taskAssignedTemplate = ({ recipientName, actorName, task, isPrimary }) => {
  const roleLabel = isPrimary ? "Người phụ trách chính" : "Người thực hiện";
  const subject = `[Task Manager] Bạn được giao công việc mới: ${task.title}`;
  const html = wrapHtml(
    "Thông báo giao công việc mới",
    `<p>Xin chào <strong>${recipientName || "bạn"}</strong>,</p>
     <p><strong>${actorName}</strong> vừa giao công việc cho bạn với vai trò <strong>${roleLabel}</strong>:</p>
     <ul>
       <li><strong>Công việc:</strong> ${task.title}</li>
       <li><strong>Mô tả:</strong> ${task.description || "Không có mô tả"}</li>
       <li><strong>Mức độ ưu tiên:</strong> ${task.priority}</li>
       <li><strong>Hạn hoàn thành:</strong> ${formatDate(task.dueDate)}</li>
     </ul>
     <p>Vui lòng mở ứng dụng Task Manager để xem chi tiết và cập nhật tiến độ.</p>`
  );
  return { subject, html };
};

exports.taskSharedTemplate = ({ recipientName, actorName, task, permission }) => {
  const permLabel = permission === "editor" ? "Chỉnh sửa (Editor)" : "Chỉ xem (Viewer)";
  const subject = `[Task Manager] Công việc được chia sẻ với bạn: ${task.title}`;
  const html = wrapHtml(
    "Thông báo chia sẻ công việc",
    `<p>Xin chào <strong>${recipientName || "bạn"}</strong>,</p>
     <p><strong>${actorName}</strong> đã chia sẻ công việc <strong>${task.title}</strong> với bạn.</p>
     <ul>
       <li><strong>Quyền truy cập:</strong> ${permLabel}</li>
       <li><strong>Trạng thái hiện tại:</strong> ${task.status}</li>
       <li><strong>Hạn hoàn thành:</strong> ${formatDate(task.dueDate)}</li>
     </ul>
     <p>Bạn có thể truy cập ứng dụng Task Manager để theo dõi công việc này.</p>`
  );
  return { subject, html };
};

exports.taskUpdatedTemplate = ({ recipientName, actorName, task, changeNote }) => {
  const subject = `[Task Manager] Cập nhật quan trọng trong công việc: ${task.title}`;
  const html = wrapHtml(
    "Thông báo thay đổi thông tin / hạn hoàn thành",
    `<p>Xin chào <strong>${recipientName || "bạn"}</strong>,</p>
     <p><strong>${actorName}</strong> vừa cập nhật công việc <strong>${task.title}</strong>:</p>
     <p style="background: #f1f5f9; padding: 12px; border-radius: 8px;">${changeNote}</p>
     <ul>
       <li><strong>Trạng thái:</strong> ${task.status}</li>
       <li><strong>Ưu tiên:</strong> ${task.priority}</li>
       <li><strong>Hạn hoàn thành:</strong> ${formatDate(task.dueDate)}</li>
     </ul>`
  );
  return { subject, html };
};

exports.taskCompletedTemplate = ({ recipientName, actorName, task }) => {
  const subject = `[Task Manager] Công việc đã hoàn thành: ${task.title}`;
  const html = wrapHtml(
    "Công việc đã hoàn thành",
    `<p>Xin chào <strong>${recipientName || "bạn"}</strong>,</p>
     <p>Công việc <strong>${task.title}</strong> đã được đánh dấu <strong>Hoàn thành (Completed)</strong> bởi <strong>${actorName}</strong>.</p>
     <p>Cảm ơn sự đóng góp của các thành viên trong nhóm!</p>`
  );
  return { subject, html };
};

exports.deadlineReminderTemplate = ({ recipientName, task }) => {
  const subject = `[Task Manager] Nhắc hạn hoàn thành công việc: ${task.title}`;
  const html = wrapHtml(
    "Nhắc việc sắp đến hạn hoàn thành",
    `<p>Xin chào <strong>${recipientName || "bạn"}</strong>,</p>
     <p>Công việc <strong>${task.title}</strong> sắp đến hạn hoàn thành.</p>
     <ul>
       <li><strong>Hạn hoàn thành:</strong> ${formatDate(task.dueDate)}</li>
       <li><strong>Mức độ ưu tiên:</strong> ${task.priority}</li>
       <li><strong>Trạng thái:</strong> ${task.status}</li>
     </ul>
     <p>Vui lòng kiểm tra và hoàn tất công việc đúng tiến độ.</p>`
  );
  return { subject, html };
};
