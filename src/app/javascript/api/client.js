// Lớp client DUY NHẤT để giao diện gọi API (BT2 – S4, TD-26).
// Mọi màn hình chỉ import từ đây, không gọi fetch trực tiếp.
//
//   – Gửi cookie đăng nhập + header X-Requested-With (API nhận phiên web, xem Api::BaseController)
//   – Timeout 8 giây; GET được thử lại tối đa 2 lần nữa (giãn cách 0,5 s → 1 s) khi mất mạng hoặc lỗi 5xx.
//     POST / PATCH / DELETE KHÔNG tự thử lại để tránh tạo trùng.
//   – Mọi lỗi được đổi thành ApiError có mã (error) và câu cho người đọc (message), theo định dạng lỗi chung.

const TIMEOUT_MS = 8000
const GET_RETRIES = 2

export class ApiError extends Error {
  constructor({ status, code, message, details = null }) {
    super(message)
    this.status = status          // 0 = không kết nối được máy chủ
    this.code = code              // ví dụ MAT_KET_NOI, DU_LIEU_KHONG_HOP_LE, KHONG_CO_QUYEN
    this.details = details        // chi_tiet từ API (ví dụ cac_truong)
  }

  get isNetwork() { return this.status === 0 || this.status >= 500 }

  // Lỗi theo từng trường: { serial_number: "đã thuộc khách hàng khác", ... }
  get fieldErrors() {
    const fields = this.details?.cac_truong || []
    return Object.fromEntries(fields.map((f) => [f.truong, f.ly_do]))
  }
}

const sleep = (ms) => new Promise((resolve) => setTimeout(resolve, ms))

function buildUrl(path, params) {
  const url = new URL(path, window.location.origin)
  Object.entries(params || {}).forEach(([key, value]) => {
    if (value !== undefined && value !== null && value !== "") url.searchParams.set(key, value)
  })
  return url
}

async function send(method, path, { params, body } = {}) {
  const controller = new AbortController()
  const timer = setTimeout(() => controller.abort(), TIMEOUT_MS)
  let response
  try {
    response = await fetch(buildUrl(path, params), {
      method,
      credentials: "same-origin",
      signal: controller.signal,
      headers: {
        "Accept": "application/json",
        "X-Requested-With": "XMLHttpRequest",
        ...(body ? { "Content-Type": "application/json" } : {})
      },
      body: body ? JSON.stringify(body) : undefined
    })
  } catch (_networkError) {
    throw new ApiError({
      status: 0, code: "MAT_KET_NOI",
      message: "Không kết nối được máy chủ. Kiểm tra mạng hoặc máy chủ rồi bấm Thử lại."
    })
  } finally {
    clearTimeout(timer)
  }

  if (response.status === 204) return null

  let json = null
  try { json = await response.json() } catch (_) { /* phản hồi không phải JSON, xử lý bên dưới */ }

  if (!response.ok) {
    throw new ApiError({
      status: response.status,
      code: json?.error || "LOI_KHONG_XAC_DINH",
      message: json?.message || `Máy chủ trả lỗi ${response.status}. Vui lòng thử lại.`,
      details: json?.chi_tiet || null
    })
  }
  return json
}

async function request(method, path, options = {}) {
  const attempts = method === "GET" ? GET_RETRIES + 1 : 1
  for (let attempt = 1; ; attempt++) {
    try {
      return await send(method, path, options)
    } catch (error) {
      if (!(error instanceof ApiError) || !error.isNetwork || attempt >= attempts) throw error
      await sleep(500 * attempt)
    }
  }
}

// ---------- Các hàm theo tài nguyên ----------
export const api = {
  customers: {
    search: (q)              => request("GET", "/api/customers", { params: { q } }),
    show:   (id)             => request("GET", `/api/customers/${id}`)
  },
  issueCategories: {
    list:   ()               => request("GET", "/api/issue_categories")
  },
  priorities: {
    list:   ()               => request("GET", "/api/priorities")
  },
  stats: {
    show:   ()               => request("GET", "/api/stats")
  },
  warrantyRequests: {
    list:   (params)         => request("GET", "/api/warranty_requests", { params }),
    show:   (id)             => request("GET", `/api/warranty_requests/${id}`),
    create: (body)           => request("POST", "/api/warranty_requests", { body }),
    updateStatus: (id, body) => request("PATCH", `/api/warranty_requests/${id}/status`, { body })
  }
}
