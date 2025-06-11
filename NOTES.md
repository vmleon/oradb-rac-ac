# Notes

- [DBA Stack Exchange Transparent Application Continuity + ONS + FAN](https://dba.stackexchange.com/questions/333887/oracle-19c-and-ons-and-fan-events)

## Privilege for RAC gv$instance

`SELECT_CATALOG_ROLE`: This predefined role grants `SELECT` privileges on all data dictionary views, including `gv$instance` and other `v$` and `gv$` views commonly needed for monitoring.

```sql
-- Grant only the specific view access
GRANT SELECT ON gv_$instance TO EXAMPLE_USER;
```

For comprehensive RAC monitoring

```sql
-- For comprehensive RAC monitoring
GRANT SELECT ON gv_$database TO EXAMPLE_USER;
GRANT SELECT ON gv_$session TO EXAMPLE_USER;
GRANT SELECT ON gv_$parameter TO EXAMPLE_USER;
GRANT SELECT ON dba_services TO EXAMPLE_USER;
```

Test with user:

```sql
-- Test as EXAMPLE_USER
SELECT inst_id, instance_name, status
FROM gv$instance
ORDER BY inst_id;
```
