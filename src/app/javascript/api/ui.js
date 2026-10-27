// Hàm dựng HTML dùng chung cho các màn hình lấy dữ liệu qua API (TD-26).
// Mọi chuỗi từ API đều đi qua escapeHtml trước khi chèn vào trang (chống XSS).

export function escapeHtml(value) {
  return String(value ?? "")
    .replaceAll("&", "&amp;").replaceAll("<", "&lt;").replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;").replaceAll("'", "&#39;")
}

// "0905123456" → "0905 123 456"
export function formatPhone(phone) {
  const d = String(phone ?? "").replace(/\D/g, "")
  return d.length === 10 ? `${d.slice(0, 4)} ${d.slice(4, 7)} ${d.slice(7)}` : String(phone ?? "")
}

const pad = (n) => String(n).padStart(2, "0")

// ISO → "dd/mm HH:MM"
export function formatShortDateTime(iso) {
  if (!iso) return "—"
  const t = new Date(iso)
  return `${pad(t.getDate())}/${pad(t.getMonth() + 1)} ${pad(t.getHours())}:${pad(t.getMinutes())}`
}

// ISO → "mm/yyyy"
export function formatMonthYear(iso) {
  if (!iso) return ""
  const t = new Date(iso)
  return `${pad(t.getMonth() + 1)}/${t.getFullYear()}`
}

// ---------- Ba trạng thái dùng chung ----------
export function loadingHtml(text = "Đang tải dữ liệu…") {
  return `<div class="state state--loading" role="status" aria-live="polite">
            <span class="state__spinner" aria-hidden="true"></span><span>${escapeHtml(text)}</span>
          </div>`
}

export function emptyHtml(title, hint = "", actionHtml = "") {
  return `<div class="state state--empty" role="status">
            <i class="ph ph-tray state__icon" aria-hidden="true"></i>
            <div><b>${escapeHtml(title)}</b>${hint ? `<p>${escapeHtml(hint)}</p>` : ""}</div>${actionHtml}
          </div>`
}

// Lỗi kết nối / lỗi máy chủ – luôn có nút Thử lại gọi tới action của controller
export function errorHtml(error, retryAction) {
  return `<div class="state state--error" role="alert">
            <i class="ph ph-wifi-slash state__icon" aria-hidden="true"></i>
            <div><b>Không tải được dữ liệu</b><p>${escapeHtml(error.message)}</p></div>
            <button type="button" class="btn btn--primary state__retry" data-action="${retryAction}">
              <i class="ph ph-arrow-clockwise" aria-hidden="true"></i> Thử lại
            </button>
          </div>`
}
