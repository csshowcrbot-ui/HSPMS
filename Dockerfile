FROM flexberry/mono-xsp:latest

WORKDIR /app

# 啟用 Mono IOMAP 機制：讓 Linux 自動相容 Windows 檔名大小寫與路徑斜線 (all = case + drive)
ENV MONO_IOMAP=all
ENV PORT=8080

# 複製預編譯好的 ASP.NET Web Forms 專案 (含 bin/ 目錄、前端 aspx 及 Web.config)
COPY . /app

# 1. 自動針對所有 .aspx 建立小寫別名連結 (避免 URL 大小寫不一致造成 404)
# 2. 建立 Uploads 目錄並賦予寫入權限
RUN for f in /app/*.aspx; do \
      filename=$(basename "$f"); \
      lowercased=$(echo "$filename" | tr '[:upper:]' '[:lower:]'); \
      if [ "$filename" != "$lowercased" ] && [ ! -e "/app/$lowercased" ]; then \
        ln -s "$filename" "/app/$lowercased"; \
      fi; \
    done && \
    mkdir -p /app/Uploads && chmod -R 777 /app/Uploads

EXPOSE 8080

CMD ["sh", "-c", "export MONO_IOMAP=all && xsp4 --port ${PORT:-8080} --address 0.0.0.0 --root /app --nonstop"]
