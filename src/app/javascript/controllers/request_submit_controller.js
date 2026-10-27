import { Controller } from "@hotwired/stimulus"
import { api, ApiError } from "api/client"
import { escapeHtml } from "api/ui"

// Màn hình 2 – Tạo yêu cầu bảo hành qua POST /api/warranty_requests (UC06 · TD-26)
// Ba trạng thái: đang gửi (nút khóa, "Đang tạo…") · lỗi từng trường (BR02–BR04) · mất kết nối có nút Thử lại.
// Thành công → mở Phiếu tiếp nhận của yêu cầu vừa tạo.
export default class extends Controller {
  static targets = ["submit", "banner"]
  static values  = { customerId: Number, detailUrl: String }

  async submit(event) {
    event?.preventDefault()
    if (!this.element.reportValidity()) return

    this.#clearErrors()
    this.#busy(true)
    try {
      const { data } = await api.warrantyRequests.create(this.#body())
      window.location.assign(`${this.detailUrlValue}/${encodeURIComponent(data.id)}`)
    } catch (error) {
      this.#busy(false)
      this.#showError(error)
    }
  }

  #body() {
    const body = { customer_id: this.customerIdValue }
    for (const [name, value] of new FormData(this.element)) {
      const match = name.match(/^warranty_request\[(.+)\]$/)
      if (match) body[match[1]] = value
    }
    return body
  }

  #showError(error) {
    const fields = error instanceof ApiError ? error.fieldErrors : {}
    Object.entries(fields).forEach(([field, reason]) => {
      const input = this.element.querySelector(`[name="warranty_request[${field}]"]`)
      const box = input?.closest(".field, fieldset")
      if (!input || !box) return
      if (input.type !== "radio") input.classList.add("input--error")
      box.insertAdjacentHTML("beforeend", `<p class="error-text" data-api-error>⚠︎ ${escapeHtml(reason)}</p>`)
    })

    const retry = error instanceof ApiError && error.isNetwork
      ? `<button type="button" class="btn btn--primary state__retry" data-action="request-submit#submit">
           <i class="ph ph-arrow-clockwise" aria-hidden="true"></i> Thử lại</button>`
      : ""
    this.bannerTarget.innerHTML = `<div class="form-errors" role="alert">
        <b>Chưa tạo được yêu cầu.</b> ${escapeHtml(error.message)} ${retry}</div>`
    this.bannerTarget.scrollIntoView({ behavior: "smooth", block: "center" })
  }

  #clearErrors() {
    this.bannerTarget.innerHTML = ""
    this.element.querySelectorAll("[data-api-error]").forEach((el) => el.remove())
    this.element.querySelectorAll(".input--error").forEach((el) => el.classList.remove("input--error"))
  }

  #busy(on) {
    this.submitTarget.disabled = on
    this.submitTarget.textContent = on ? "Đang tạo…" : "✓ Tạo yêu cầu bảo hành"
    this.element.setAttribute("aria-busy", on)
  }
}
