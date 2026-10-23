import { Controller } from "@hotwired/stimulus"

// Nút con mắt trong ô mật khẩu: bấm để hiện / ẩn mật khẩu (màn hình đăng nhập)
export default class extends Controller {
  static targets = ["input", "icon"]

  toggle() {
    const show = this.inputTarget.type === "password"
    this.inputTarget.type = show ? "text" : "password"
    this.iconTarget.classList.toggle("ph-eye", !show)
    this.iconTarget.classList.toggle("ph-eye-slash", show)
  }
}
