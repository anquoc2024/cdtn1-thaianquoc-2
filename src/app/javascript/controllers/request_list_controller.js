import { Controller } from "@hotwired/stimulus"
import { api } from "api/client"
import { escapeHtml, formatShortDateTime, loadingHtml, emptyHtml, errorHtml } from "api/ui"

// Màn hình 3 – Danh sách yêu cầu (UC07 · TD-26)
// Thẻ thống kê lấy từ GET /api/stats, bảng lấy từ GET /api/warranty_requests (lọc, sắp xếp, phân trang).
// Ba trạng thái: đang tải · rỗng (phân biệt "chưa có yêu cầu nào" và "bộ lọc không ra kết quả") · lỗi có nút Thử lại.
export default class extends Controller {
  static targets = ["form", "stats", "tbody", "footer", "state"]
  static values  = { detailUrl: String }

  SORT_LABELS = { newest: "mới tạo nhất", due_at: "hạn cam kết gần nhất" }
  FILTER_KEYS = ["q", "status", "issue_category_id", "priority_id", "from", "to"]

  connect() {
    this.load()
  }

  // Bấm "Lọc"
  filter(event) {
    event.preventDefault()
    this.#pushParams(this.#formParams())
    this.load()
  }

  // Bấm số trang (event delegation trên vùng phân trang)
  paginate(event) {
    const link = event.target.closest("a[data-page]")
    if (!link) return
    event.preventDefault()
    this.#pushParams({ ...this.#currentParams(), page: link.dataset.page })
    this.load()
  }

  clearFilters(event) {
    event?.preventDefault()
    this.formTarget.reset()
    this.formTarget.querySelectorAll("input, select").forEach((el) => { el.value = el.tagName === "SELECT" && el.name === "sort" ? "newest" : "" })
    this.#pushParams({})
    this.load()
  }

  async load() {
    const params = this.#currentParams()
    this.stateTarget.innerHTML = loadingHtml("Đang tải danh sách yêu cầu…")
    this.tbodyTarget.closest("table").classList.add("is-loading")

    try {
      const [list, stats] = await Promise.all([api.warrantyRequests.list(params), api.stats.show()])
      this.stateTarget.innerHTML = ""
      this.#renderStats(stats.data)
      this.#renderRows(list.data, params)
      this.#renderFooter(list.meta, params)
    } catch (error) {
      this.tbodyTarget.innerHTML = ""
      this.footerTarget.innerHTML = ""
      this.stateTarget.innerHTML = errorHtml(error, "request-list#load")
    } finally {
      this.tbodyTarget.closest("table").classList.remove("is-loading")
    }
  }

  // ---------- Thẻ thống kê: số + mốc so sánh ----------
  #renderStats(s) {
    const set = (key, value, ref) => {
      const card = this.statsTarget.querySelector(`[data-stat="${key}"]`)
      card.querySelector(".stat__value").textContent = value
      card.querySelector(".stat__ref").textContent = ref
    }
    set("today",   s.tiep_nhan_hom_nay.so, `hôm qua: ${s.tiep_nhan_hom_nay.moc.so}`)
    set("new",     s.moi_tiep_nhan.so,     `trên ${s.moi_tiep_nhan.moc.so} yêu cầu đang mở`)
    set("doing",   s.dang_xu_ly.so,        `trên ${s.dang_xu_ly.moc.so} yêu cầu đang mở`)
    set("overdue", s.qua_han.so,           `${s.qua_han.ty_le}% số đang mở · mục tiêu: ${s.qua_han.moc.so}`)
  }

  // ---------- Bảng ----------
  #renderRows(rows, params) {
    if (rows.length === 0) {
      const filtered = this.FILTER_KEYS.some((k) => params[k])
      this.tbodyTarget.innerHTML = `<tr class="table__empty"><td colspan="9">${
        filtered
          ? emptyHtml("Không có yêu cầu phù hợp với bộ lọc.", "Thử bỏ bớt điều kiện lọc.",
                      `<button type="button" class="btn" data-action="request-list#clearFilters">Xóa bộ lọc</button>`)
          : emptyHtml("Chưa có yêu cầu bảo hành nào.", "Yêu cầu mới tạo ở Màn hình 2 sẽ hiện ở đây.")
      }</td></tr>`
      return
    }

    this.tbodyTarget.innerHTML = rows.map((r) => {
      const url = `${this.detailUrlValue}/${encodeURIComponent(r.id)}`
      const due = r.overdue ? `<span class="due-overdue">${formatShortDateTime(r.due_at)} ⚠&#xFE0E;</span>`
                            : formatShortDateTime(r.due_at)
      return `<tr class="${r.overdue ? "is-overdue" : ""}">
        <td class="col-code"><a class="code-link" href="${url}">${escapeHtml(r.code)}</a></td>
        <td class="col-cust" title="${escapeHtml(r.customer_name)}">${escapeHtml(r.customer_name)}</td>
        <td class="col-phone">${escapeHtml(r.customer_phone)}</td>
        <td class="col-device" title="${escapeHtml(r.device)}">${escapeHtml(r.device)}</td>
        <td class="col-cat">${escapeHtml(r.issue_category)}</td>
        <td class="col-prio"><span class="badge badge--prio ${this.#priorityClass(r.sla_hours)}">${escapeHtml(r.priority)}</span></td>
        <td class="col-status"><span class="badge badge--status ${this.#statusClass(r)}">${escapeHtml(r.status_label)}</span></td>
        <td class="col-due">${due}</td>
        <td class="col-view"><a class="view-link" href="${url}" title="Xem chi tiết"><i class="ph ph-eye" aria-hidden="true"></i></a></td>
      </tr>`
    }).join("")
  }

  #renderFooter(meta, params) {
    const page = meta.trang, pages = meta.so_trang, total = meta.tong_so, per = meta.moi_trang
    const first = total === 0 ? 0 : (page - 1) * per + 1
    const last = Math.min(page * per, total)
    const sort = this.SORT_LABELS[params.sort] || this.SORT_LABELS.newest
    const filtered = this.FILTER_KEYS.some((k) => params[k])
    const link = (p, label, extra = "") => `<li><a href="?page=${p}" data-page="${p}" ${extra}>${label}</a></li>`
    const items = []
    items.push(page > 1 ? link(page - 1, "‹", 'aria-label="Trang trước"') : `<li><span class="is-disabled">‹</span></li>`)
    this.#pageWindow(page, pages).forEach((p) => {
      items.push(p === "gap" ? "<li><span>…</span></li>"
                             : link(p, p, p === page ? 'class="is-current" aria-current="page"' : ""))
    })
    items.push(page < pages ? link(page + 1, "›", 'aria-label="Trang sau"') : `<li><span class="is-disabled">›</span></li>`)

    this.footerTarget.innerHTML = `
      <span class="table-footer__info">Hiển thị ${first}–${last} trên ${total} yêu cầu · sắp xếp: ${sort}
        ${filtered ? `· <a href="#" class="table-footer__reset" data-action="request-list#clearFilters">Xóa bộ lọc</a>` : ""}
      </span>
      <ul class="pagination">${items.join("")}</ul>`
  }

  // [1, gap, 4, 5, 6, gap, 16] – giống PaginationHelper#page_window
  #pageWindow(current, total) {
    const pages = [...new Set([1, total, current - 1, current, current + 1])]
      .filter((p) => p >= 1 && p <= total).sort((a, b) => a - b)
    return pages.flatMap((p, i) => (i > 0 && p - pages[i - 1] > 1 ? ["gap", p] : [p]))
  }

  #priorityClass(hours) {
    if (hours <= 8) return "badge--urgent"
    if (hours <= 24) return "badge--high"
    if (hours <= 48) return "badge--medium"
    return "badge--low"
  }

  #statusClass(r) {
    if (r.overdue) return "badge--overdue"
    return { received: "badge--new", in_progress: "badge--doing", completed: "badge--done", cancelled: "badge--cancelled" }[r.status] || "badge--low"
  }

  // ---------- Tham số lọc giữ trên URL (chia sẻ / quay lại được) ----------
  #formParams() {
    const data = Object.fromEntries(new FormData(this.formTarget))
    return Object.fromEntries(Object.entries(data).filter(([, v]) => v !== ""))
  }

  #currentParams() {
    return Object.fromEntries(new URLSearchParams(location.search))
  }

  #pushParams(params) {
    const query = new URLSearchParams(params).toString()
    history.pushState(null, "", query ? `${location.pathname}?${query}` : location.pathname)
  }
}
