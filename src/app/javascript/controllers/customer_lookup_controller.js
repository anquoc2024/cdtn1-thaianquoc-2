import { Controller } from "@hotwired/stimulus"
import { api, ApiError } from "api/client"
import { escapeHtml, formatPhone, formatMonthYear, loadingHtml, errorHtml } from "api/ui"

// Màn hình 1 – Tra cứu khách hàng qua GET /api/customers?q= (UC01, UC08 · TD-26)
// Ba trạng thái: đang tải · không tìm thấy (UC08) / từ khóa sai · lỗi kết nối có nút Thử lại.
export default class extends Controller {
  static targets = ["input", "hint", "results"]
  static values  = { newRequestUrl: String }

  async search(event) {
    event?.preventDefault()
    const q = this.inputTarget.value.trim()
    if (!q) return

    history.replaceState(null, "", `${location.pathname}?q=${encodeURIComponent(q)}`)
    this.#setInputError(null)
    this.resultsTarget.innerHTML = loadingHtml("Đang tra cứu khách hàng…")

    try {
      const { data, meta } = await api.customers.search(q)
      this.resultsTarget.innerHTML = this.#render(data, meta, q)
    } catch (error) {
      if (error instanceof ApiError && error.status === 400) {
        this.resultsTarget.innerHTML = ""
        this.#setInputError(error.fieldErrors.q || error.message)
      } else {
        this.resultsTarget.innerHTML = errorHtml(error, "customer-lookup#search")
      }
    }
  }

  // ---------- Hiển thị ----------
  #render(customers, meta, q) {
    if (customers.length === 0) return this.#notFound(meta.tim_theo, q)
    if (customers.length === 1) return this.#card(customers[0])
    return this.#list(customers)
  }

  #card(c) {
    const history = c.so_yeu_cau > 0 ? `${c.so_yeu_cau} yêu cầu (gần nhất ${formatMonthYear(c.yeu_cau_gan_nhat)})`
                                     : "Chưa có yêu cầu nào"
    return `
      <section>
        <h3 class="case-title case-title--found">Tìm thấy khách hàng</h3>
        <div class="card customer-card">
          <div class="customer-card__head">
            <div class="avatar">${escapeHtml(this.#initials(c.name))}</div>
            <div class="customer-card__name"><b>${escapeHtml(c.name)}</b><br><span>Mã KH: ${escapeHtml(c.code)}</span></div>
            <span class="badge badge--success">✓ Đã xác định</span>
          </div>
          <dl class="info-list">
            <div class="info-list__row"><dt>Số điện thoại</dt><dd>${escapeHtml(formatPhone(c.phone))}</dd></div>
            <div class="info-list__row"><dt>Email</dt><dd>${escapeHtml(c.email || "—")}</dd></div>
            <div class="info-list__row"><dt>Địa chỉ</dt><dd>${escapeHtml(c.address || "—")}</dd></div>
            <div class="info-list__row"><dt>Số yêu cầu trước đây</dt><dd>${escapeHtml(history)}</dd></div>
          </dl>
          <div class="customer-card__actions">
            <a class="btn btn--primary" href="${this.#pickUrl(c)}">Chọn khách hàng &amp; tiếp tục →</a>
          </div>
        </div>
      </section>`
  }

  #list(customers) {
    const rows = customers.map((c) => `
      <div class="customer-list__row">
        <div class="avatar avatar--sm">${escapeHtml(this.#initials(c.name))}</div>
        <div class="customer-list__info"><b>${escapeHtml(c.name)}</b>
          <span>${escapeHtml(c.code)} · ${escapeHtml(formatPhone(c.phone))}</span></div>
        <a class="btn btn--primary customer-list__pick" href="${this.#pickUrl(c)}">Chọn →</a>
      </div>`).join("")
    return `
      <section class="customer-list-section">
        <h3 class="case-title case-title--found">Tìm thấy ${customers.length} khách hàng phù hợp – chọn đúng khách hàng</h3>
        <div class="card customer-list">${rows}</div>
      </section>`
  }

  // UC08 – không tìm thấy: không có nút tiếp tục (BR01, BR07)
  #notFound(mode, q) {
    const message = { phone: `Không tìm thấy khách hàng với số điện thoại ${formatPhone(q)}`,
                      code:  `Không tìm thấy khách hàng có mã ${q.toUpperCase()}` }[mode]
                    || `Không tìm thấy khách hàng có tên “${q}”`
    return `
      <section>
        <h3 class="case-title case-title--notfound">Không tìm thấy khách hàng (UC08)</h3>
        <div class="alert-notfound" role="alert">
          <div class="alert-notfound__icon">⚠&#xFE0E;</div>
          <div class="alert-notfound__body">
            <p><b>${escapeHtml(message)}</b></p>
            <p>Vui lòng kiểm tra lại thông tin. Hệ thống <b>không cho phép tiếp tục tạo yêu cầu</b> khi chưa xác định được khách hàng (BR01, BR07).</p>
          </div>
        </div>
      </section>`
  }

  #setInputError(message) {
    this.inputTarget.classList.toggle("input--error", Boolean(message))
    this.inputTarget.setAttribute("aria-invalid", Boolean(message))
    if (message) {
      this.hintTarget.className = "error-text"
      this.hintTarget.textContent = `⚠︎ ${message}`
    } else {
      this.hintTarget.className = "hint"
      this.hintTarget.textContent = this.hintTarget.dataset.defaultText
    }
  }

  #pickUrl(c) { return `${this.newRequestUrlValue}?customer_id=${encodeURIComponent(c.id)}` }

  #initials(name) {
    const words = String(name).trim().split(/\s+/)
    return words.slice(-2).map((w) => w[0]).join("").toUpperCase()
  }
}
