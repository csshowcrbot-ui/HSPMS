FROM mono:6.12

# 設定環境變數與安裝 mono-xsp4 (ASP.NET Web Forms Server)
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y --no-install-recommends \
    mono-xsp4 \
    ca-certificates-mono \
    tzdata \
    && rm -rf /var/lib/apt/lists/*

ENV TZ=Asia/Taipei
WORKDIR /app

# 複製專案原始碼
COPY . .

# 還原 NuGet 套件並進行建置
RUN nuget restore HospitalParking.csproj -PackagesDirectory packages
RUN msbuild HospitalParking.csproj /p:Configuration=Release /p:Platform="AnyCPU" /p:OutputPath=/app/bin/

# 將相依 DLL 確保放入 bin/
RUN cp -rf packages/Npgsql.4.1.12/lib/net461/*.dll /app/bin/ 2>/dev/null || true
RUN cp -rf packages/Microsoft.Bcl.AsyncInterfaces.1.1.0/lib/net461/*.dll /app/bin/ 2>/dev/null || true
RUN cp -rf packages/System.Buffers.4.5.0/lib/netstandard2.0/*.dll /app/bin/ 2>/dev/null || true
RUN cp -rf packages/System.Memory.4.5.3/lib/netstandard2.0/*.dll /app/bin/ 2>/dev/null || true
RUN cp -rf packages/System.Numerics.Vectors.4.5.0/lib/net46/*.dll /app/bin/ 2>/dev/null || true
RUN cp -rf packages/System.Runtime.CompilerServices.Unsafe.4.6.0/lib/netstandard2.0/*.dll /app/bin/ 2>/dev/null || true
RUN cp -rf packages/System.Text.Encodings.Web.4.6.0/lib/netstandard2.0/*.dll /app/bin/ 2>/dev/null || true
RUN cp -rf packages/System.Text.Json.4.6.0/lib/net461/*.dll /app/bin/ 2>/dev/null || true
RUN cp -rf packages/System.Threading.Tasks.Extensions.4.5.3/lib/netstandard2.0/*.dll /app/bin/ 2>/dev/null || true
RUN cp -rf packages/System.ValueTuple.4.5.0/lib/net47/*.dll /app/bin/ 2>/dev/null || true

# 建立 Uploads 目錄與賦予權限
RUN mkdir -p /app/Uploads && chmod -R 777 /app/Uploads

# Railway 動態指定 PORT
ENV PORT=8080
EXPOSE 8080

CMD ["sh", "-c", "xsp4 --port ${PORT:-8080} --address 0.0.0.0 --root /app --nonstop"]
