import { Controller } from "@hotwired/stimulus"

// Màn hình 2 – cập nhật ngay khung "Tóm tắt yêu cầu", bộ đếm ký tự
// và hạn cam kết dự kiến khi nhân viên nhập liệu (chỉ để xem trước;
// hạn cam kết thật do server tính lúc lưu – SlaDeadlineCalculator).
export default class extends Controller {
  static targets = ["brand", "model", "category", "description", "counter",
                    "deviceOut", "categoryOut", "priorityOut", "dueOut"]

  connect() {
    this.refresh()
  }

  refresh() {
    this.counterTarget.textContent = `${this.descriptionTarget.value.length} / 1000 ký tự`

    const device = [this.brandTarget.value, this.modelTarget.value.trim()].filter(Boolean).join(" ")
    this.deviceOutTarget.textContent = device || "—"

    const category = this.categoryTarget.selectedOptions[0]
    this.categoryOutTarget.textContent = category && category.value ? category.text : "—"

    const priority = this.element.querySelector("input[name='warranty_request[priority_id]']:checked")
    if (priority) {
      const hours = Number(priority.dataset.slaHours)
      this.priorityOutTarget.textContent = `${priority.dataset.label} (${hours}h)`
      this.dueOutTarget.textContent = this.#format(new Date(Date.now() + hours * 3600 * 1000))
    } else {
      this.priorityOutTarget.textContent = "—"
      this.dueOutTarget.textContent = "—"
    }
  }

  #format(date) {
    const pad = (n) => String(n).padStart(2, "0")
    return `${pad(date.getDate())}/${pad(date.getMonth() + 1)}/${date.getFullYear()} · ` +
           `${pad(date.getHours())}:${pad(date.getMinutes())}`
  }
}
