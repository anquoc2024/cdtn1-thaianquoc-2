# syntax=docker/dockerfile:1
# ============================================================
# Gói đóng gói BT3 (TP4) – image ứng dụng Smart CRM, luồng L2
# Build từ GỐC repo vì cần cả src/ (mã Rails) lẫn data/mau/ (dữ liệu mẫu):
#     cp .env.example .env
#     docker compose up -d --build
# (src/Dockerfile là bản Rails tự sinh cho Kamal – gói BT3 dùng tệp này.)
# ============================================================
ARG RUBY_VERSION=4.0.5
FROM docker.io/library/ruby:$RUBY_VERSION-slim AS base

WORKDIR /rails

# Thư viện chạy: curl (healthcheck), libpq (PostgreSQL), jemalloc (giảm bộ nhớ)
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y curl libjemalloc2 libvips postgresql-client && \
    ln -s /usr/lib/$(uname -m)-linux-gnu/libjemalloc.so.2 /usr/local/lib/libjemalloc.so && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

# Không cài nhóm gem development; nhóm test VẪN được cài để chạy bin/rails test trong container
ENV RAILS_ENV="production" \
    BUNDLE_DEPLOYMENT="1" \
    BUNDLE_PATH="/usr/local/bundle" \
    BUNDLE_WITHOUT="development" \
    LD_PRELOAD="/usr/local/lib/libjemalloc.so"

# ---------- Giai đoạn build: biên dịch gem, tài nguyên tĩnh (bỏ đi sau khi xong) ----------
FROM base AS build

RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y build-essential git libpq-dev libyaml-dev pkg-config && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

# 1. Tệp khóa trước → chỉ cài lại gem khi Gemfile.lock đổi (tận dụng cache)
COPY src/Gemfile src/Gemfile.lock src/.ruby-version ./
RUN bundle install && \
    rm -rf ~/.bundle/ "${BUNDLE_PATH}"/ruby/*/cache "${BUNDLE_PATH}"/ruby/*/bundler/gems/*/.git && \
    bundle exec bootsnap precompile -j 1 --gemfile

# 2. Mã nguồn sau
COPY src/ ./
RUN bundle exec bootsnap precompile -j 1 app/ lib/

# Biên dịch CSS/JS cho production – không cần khóa thật
RUN SECRET_KEY_BASE_DUMMY=1 ./bin/rails assets:precompile

# ---------- Image cuối: chỉ chứa thứ cần để chạy ----------
FROM base

# 3. Không chạy bằng root
RUN groupadd --system --gid 1000 rails && \
    useradd rails --uid 1000 --gid 1000 --create-home --shell /bin/bash

COPY --chown=rails:rails --from=build "${BUNDLE_PATH}" "${BUNDLE_PATH}"
COPY --chown=rails:rails --from=build /rails /rails
# Dữ liệu mẫu L2: ứng dụng đọc ở Rails.root.parent/data/mau = /data/mau
COPY --chown=rails:rails data/mau /data/mau

USER 1000:1000

# Lần chạy đầu: tạo CSDL, nạp bảng, chạy seed (tài khoản demo + dữ liệu mẫu) – xem bin/docker-entrypoint
ENTRYPOINT ["/rails/bin/docker-entrypoint"]

EXPOSE 3000
CMD ["./bin/rails", "server", "-b", "0.0.0.0", "-p", "3000"]
