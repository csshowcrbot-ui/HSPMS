using System;
using System.Configuration;
using System.Data;
using System.Data.Common;
using System.IO;
using Npgsql;

namespace HospitalParking.Common
{
    /// <summary>
    /// PostgreSQL (Npgsql) 資料庫存取核心公用類別 (ADO.NET 參數化查詢封裝)
    /// </summary>
    public static class DbHelper
    {
        private static bool _isInitialized = false;
        private static readonly object _initLock = new object();

        public static string ConnectionString
        {
            get
            {
                // 優先讀取 Railway 等雲端容器自動注入之 DATABASE_URL 環境變數
                string envDbUrl = Environment.GetEnvironmentVariable("DATABASE_URL");
                if (!string.IsNullOrWhiteSpace(envDbUrl))
                {
                    return FormatConnectionString(envDbUrl);
                }

                var connSetting = ConfigurationManager.ConnectionStrings["HospitalParkingDB"];
                string raw = connSetting != null && !string.IsNullOrWhiteSpace(connSetting.ConnectionString)
                    ? connSetting.ConnectionString
                    : "Host=postgres.railway.internal;Port=5432;Database=railway;Username=postgres;Password=iuPBfhRMHqoceSvHBuRPwlezdwgeucap;SSL Mode=Prefer;Trust Server Certificate=true;";

                return FormatConnectionString(raw);
            }
        }

        /// <summary>
        /// 智慧解析連線字串 (支援標準 postgresql:// URI 與 Key-Value 格式)
        /// </summary>
        public static string FormatConnectionString(string raw)
        {
            if (string.IsNullOrWhiteSpace(raw)) return raw;

            raw = raw.Trim();
            if (raw.StartsWith("postgresql://", StringComparison.OrdinalIgnoreCase) ||
                raw.StartsWith("postgres://", StringComparison.OrdinalIgnoreCase))
            {
                try
                {
                    var uri = new Uri(raw);
                    var builder = new NpgsqlConnectionStringBuilder
                    {
                        Host = uri.Host,
                        Port = uri.Port > 0 ? uri.Port : 5432,
                        Database = uri.AbsolutePath.TrimStart('/'),
                        SslMode = SslMode.Prefer,
                        TrustServerCertificate = true
                    };

                    if (!string.IsNullOrEmpty(uri.UserInfo))
                    {
                        var parts = uri.UserInfo.Split(':');
                        builder.Username = parts[0];
                        if (parts.Length > 1)
                        {
                            builder.Password = parts[1];
                        }
                    }
                    return builder.ConnectionString;
                }
                catch
                {
                    return raw;
                }
            }

            return raw;
        }

        /// <summary>
        /// 自動檢查並初始化資料庫 (若關鍵表格不存在，自動執行 init_database_pg.sql)
        /// </summary>
        public static void EnsureDatabaseInitialized()
        {
            if (_isInitialized) return;
            lock (_initLock)
            {
                if (_isInitialized) return;
                try
                {
                    using (var conn = new NpgsqlConnection(ConnectionString))
                    {
                        conn.Open();
                        // 檢查核心表格 parkingdepartments 是否已存在
                        using (var chkCmd = new NpgsqlCommand("SELECT to_regclass('public.parkingdepartments');", conn))
                        {
                            var result = chkCmd.ExecuteScalar();
                            if (result == null || result == DBNull.Value)
                            {
                                string baseDir = AppDomain.CurrentDomain.BaseDirectory;
                                string sqlPath = Path.Combine(baseDir, "init_database_pg.sql");
                                if (File.Exists(sqlPath))
                                {
                                    string fullSql = File.ReadAllText(sqlPath);
                                    using (var initCmd = new NpgsqlCommand(fullSql, conn))
                                    {
                                        initCmd.CommandTimeout = 120;
                                        initCmd.ExecuteNonQuery();
                                    }
                                }
                            }
                        }
                    }
                }
                catch (Exception)
                {
                    // 若失敗允許重試或由日誌查看
                }
                finally
                {
                    _isInitialized = true;
                }
            }
        }

        public static NpgsqlConnection GetConnection()
        {
            EnsureDatabaseInitialized();
            var conn = new NpgsqlConnection(ConnectionString);
            if (conn.State != ConnectionState.Open)
            {
                conn.Open();
            }
            return conn;
        }

        public static NpgsqlParameter CreateParameter(string parameterName, object value)
        {
            return new NpgsqlParameter(parameterName, value ?? DBNull.Value);
        }

        public static DataTable ExecuteDataTable(string sql, params NpgsqlParameter[] parameters)
        {
            var dt = new DataTable();
            using (var conn = GetConnection())
            using (var cmd = new NpgsqlCommand(sql, conn))
            {
                if (parameters != null && parameters.Length > 0)
                {
                    cmd.Parameters.AddRange(parameters);
                }
                using (var da = new NpgsqlDataAdapter(cmd))
                {
                    da.Fill(dt);
                }
            }
            return dt;
        }

        public static object ExecuteScalar(string sql, params NpgsqlParameter[] parameters)
        {
            using (var conn = GetConnection())
            using (var cmd = new NpgsqlCommand(sql, conn))
            {
                if (parameters != null && parameters.Length > 0)
                {
                    cmd.Parameters.AddRange(parameters);
                }
                return cmd.ExecuteScalar();
            }
        }

        public static int ExecuteNonQuery(string sql, params NpgsqlParameter[] parameters)
        {
            using (var conn = GetConnection())
            using (var cmd = new NpgsqlCommand(sql, conn))
            {
                if (parameters != null && parameters.Length > 0)
                {
                    cmd.Parameters.AddRange(parameters);
                }
                return cmd.ExecuteNonQuery();
            }
        }
    }
}
