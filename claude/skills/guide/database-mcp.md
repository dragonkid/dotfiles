# Database MCP Configuration Guide

Production-grade database MCP configuration patterns.

## Available MCP Servers

### 1. PostgreSQL MCP Server

**Package**: `@modelcontextprotocol/server-postgres`
**Features**: Read-only access, schema inspection, READ ONLY transactions

**Configuration**:
```json
{
  "mcpServers": {
    "postgres": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-postgres", "postgresql://localhost/mydb"]
    }
  }
}
```

### 2. MySQL MCP Server

**Package**: `@benborla29/mcp-server-mysql`
**Features**: Read-only by default, SSH tunnel support, SQL injection protection

**Configuration**:
```json
{
  "mcpServers": {
    "mysql": {
      "command": "npx",
      "args": ["-y", "@benborla29/mcp-server-mysql"],
      "env": {
        "MYSQL_HOST": "localhost",
        "MYSQL_USER": "readonly_user",
        "MYSQL_PASSWORD": "secure_password",
        "MYSQL_DATABASE": "mydb"
      }
    }
  }
}
```

### 3. ClickHouse MCP Servers

**Packages**: `fatwang2/clickhouse-mcp` (TypeScript), `cnych/clickhouse-mcp` (Python)
**Connection**: HTTP interface (http://host:8123)

### 4. Multi-Database: DBHub

**Package**: `bytebase/dbhub`
**Supports**: PostgreSQL, MySQL, MariaDB, SQL Server, SQLite
**Features**: Zero dependencies, read-only mode, SSH tunnel, SSL/TLS

## StarRocks Compatibility

**No dedicated server** - Try these in order:
1. MySQL MCP via `@benborla29/mcp-server-mysql` (port 9030)
2. PostgreSQL MCP via `@modelcontextprotocol/server-postgres`
3. DBHub via JDBC

## Security Patterns

### 1. Read-Only Mode
```json
{"env": {"DB_READ_ONLY": "true"}}
```

### 2. Dedicated Database User

**PostgreSQL/StarRocks**:
```sql
CREATE USER readonly_claude WITH PASSWORD 'secure_password';
GRANT SELECT ON ALL TABLES IN SCHEMA public TO readonly_claude;
```

**MySQL**:
```sql
CREATE USER 'readonly_claude'@'localhost' IDENTIFIED BY 'secure_password';
GRANT SELECT ON mydb.* TO 'readonly_claude'@'localhost';
```

### 3. Least Privilege Rules

- Never use root/admin credentials
- Limit to specific databases/tables
- Use IP whitelisting
- Store credentials in environment variables (.env + .gitignore)

### 4. SSL/TLS Encryption
```
postgresql://user:pass@host:5432/db?sslmode=require
mysql://user:pass@host:3306/db?ssl=true
```

### 5. Query Restrictions

- Set query timeout
- Limit returned rows (LIMIT 50)
- Use connection pooling
- Enable monitoring and logging

## Configuration Examples

### StarRocks (via MySQL protocol)

```json
{
  "mcpServers": {
    "starrocks": {
      "command": "npx",
      "args": ["-y", "@benborla29/mcp-server-mysql"],
      "env": {
        "MYSQL_HOST": "starrocks.example.com",
        "MYSQL_PORT": "9030",
        "MYSQL_USER": "readonly_claude",
        "MYSQL_PASSWORD": "secure_password",
        "MYSQL_DATABASE": "analytics"
      }
    }
  }
}
```

### ClickHouse

```json
{
  "mcpServers": {
    "clickhouse": {
      "command": "npx",
      "args": ["-y", "fatwang2/clickhouse-mcp"],
      "env": {
        "CLICKHOUSE_HOST": "localhost",
        "CLICKHOUSE_PORT": "8123",
        "CLICKHOUSE_USER": "readonly",
        "CLICKHOUSE_PASSWORD": "secure"
      }
    }
  }
}
```

### Lindorm (via MySQL protocol)

```json
{
  "mcpServers": {
    "lindorm": {
      "command": "npx",
      "args": ["-y", "@benborla29/mcp-server-mysql"],
      "env": {
        "MYSQL_HOST": "lindorm.example.com",
        "MYSQL_PORT": "3306",
        "MYSQL_USER": "readonly_claude",
        "MYSQL_PASSWORD": "secure_password",
        "MYSQL_DATABASE": "timeseries"
      }
    }
  }
}
```

## Verification Steps

### Test Connection

```bash
# MySQL
mysql -h localhost -u readonly_claude -p mydb

# PostgreSQL
psql "postgresql://readonly_claude@localhost/mydb"

# ClickHouse
curl "http://localhost:8123/?query=SELECT%201"
```

### Verify Permissions

```sql
SELECT current_user;
SHOW GRANTS FOR current_user;
INSERT INTO test_table VALUES (1); -- Should fail
```

### Test MCP Server

```
"Show me the schema of table users"
"Query the first 10 rows from analytics table"
```

## Context7 Workflow for Syntax Verification

When MCP not available or as alternative.

### Step 1: Identify Database System

From context clues:
- Connection strings (jdbc:mysql, starrocks://)
- Import statements (pymysql, starrocks-connector)
- Configuration files (application.properties, database.yml)

### Step 2: Query Context7 for Syntax Rules

**StarRocks**: `/websites/starrocks_io` or `/starrocks/starrocks`
```bash
context7 query: /websites/starrocks_io "VARCHAR data type syntax and constraints"
```
Key: VARCHAR(length) required, range 1-1048576 (v2.1+)

**ClickHouse**: `/clickhouse/clickhouse-docs`
```bash
context7 query: /clickhouse/clickhouse-docs "String type differences from VARCHAR"
```
Key: Use `String` type (no length specification)

**PostgreSQL/MySQL**: Use context7 to verify version-specific syntax

### Step 3: Apply Database-Specific Constraints

- StarRocks: `VARCHAR(100)` ✓
- ClickHouse: `String` ✓
- PostgreSQL: `VARCHAR(100)` or `TEXT` ✓

### Common Pitfalls

❌ Assuming all SQL databases support `VARCHAR(128)` syntax
❌ Using PostgreSQL SERIAL with non-PostgreSQL databases
❌ Mixing ClickHouse and StarRocks optimization patterns
❌ Loading wrong database docs (ClickHouse for StarRocks questions)

## Usage Strategy

1. **Development**: Use MCP servers for quick queries and schema exploration
2. **Production**: Dedicated read-only replica + strict permissions
3. **Alternative**: Use context7 + `/postgres-patterns` or `/clickhouse-io` skills
