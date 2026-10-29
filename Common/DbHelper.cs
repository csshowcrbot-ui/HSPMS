using System;
using System.Configuration;
using System.Data;
using System.Data.Common;
using Npgsql;

namespace HospitalParking.Common
{
    /// <summary>
    /// PostgreSQL (Npgsql) 資料庫存取核心公用類別 (ADO.NET 參數化查詢封裝)
    /// </summary>
    public static class DbHelper
    {
        public static string ConnectionString
        {
            get
            {
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

        public static NpgsqlConnection GetConnection()
        {
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