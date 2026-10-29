FROM flexberry/mono-xsp:latest

WORKDIR /app

# 複製預編譯好的 ASP.NET Web Forms 專案 (含 bin/ 目錄、前端 aspx 及 Web.config)
COPY . /app

# 建立 Uploads 目錄並賦予權限
RUN mkdir -p /app/Uploads && chmod -R 777 /app/Uploads

# Railway 動態指定 PORT
ENV PORT=8080
EXPOSE 8080

CMD ["sh", "-c", "xsp4 --port ${PORT:-8080} --address 0.0.0.0 --root /app --nonstop"]
