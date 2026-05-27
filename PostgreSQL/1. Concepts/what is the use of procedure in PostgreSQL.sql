what is the use of procedure in PostgreSQL?

In PostgreSQL, a **procedure** (introduced in PostgreSQL 11 with the `CALL` command) is a type of stored routine that primarily focuses on **transactional control** and performing operations that don't necessarily return a result set.

While often confused with **functions** (which use `SELECT` and `RETURNS` and are called via `SELECT` statements), procedures have distinct characteristics and use cases.

---

###  Procedures vs. Functions: Key Differences

Understanding the differences between procedures and functions is crucial for knowing when to use which:

| Feature           | PostgreSQL Function (`CREATE FUNCTION`)                                     | PostgreSQL Procedure (`CREATE PROCEDURE`)                                  |
| :---------------- | :-------------------------------------------------------------------------- | :------------------------------------------------------------------------- |
| **Transaction Control** | **Cannot** manage transactions (no `COMMIT`, `ROLLBACK`, `SAVEPOINT`). The entire function runs within a single transaction started by the caller. | **Can** manage transactions (supports `COMMIT`, `ROLLBACK`, `SAVEPOINT`). Each `COMMIT` or `ROLLBACK` ends the current transaction and starts a new one within the procedure. |
| **Return Value**  | **Must** return a value (or a table). Always has a `RETURNS` clause.         | **Does not** return a value (always `RETURNS VOID`). Output is via `RAISE NOTICE` or `OUT` parameters. |
| **Call Method**   | Called using a `SELECT` statement (e.g., `SELECT my_function(arg1)`).       | Called using the `CALL` statement (e.g., `CALL my_procedure(arg1)`).     |
| **Usage**         | Primarily for queries, calculations, data transformations, and returning results. | Primarily for executing complex logic, managing transactions, and performing data modifications/housekeeping. |
| **Data Modification** | Can perform DML (INSERT, UPDATE, DELETE) but within the calling transaction. | Can perform DML and DDL (CREATE, ALTER, DROP) statements.               |

---

###  Primary Use Cases for Procedures

Procedures are particularly useful for tasks that require explicit transaction management or involve complex multi-step operations that might need to be committed or rolled back mid-process.

1.  **Complex Batch Processing & ETL:**
    *   When you have a long-running process that involves multiple stages of data manipulation (e.g., extracting data, transforming it, loading it into different tables).
    *   You can commit changes after each stage within the procedure, preventing a single failure from rolling back the entire operation and making progress visible. This is especially useful for very large datasets where an all-or-nothing approach is too risky.

2.  **Database Housekeeping & Maintenance:**
    *   Performing tasks like archiving old data, purging logs, recalculating statistics, or reorganizing tables.
    *   These operations often involve multiple steps, and you might want to commit changes periodically to reduce the size of the active transaction log or to prevent holding locks for too long.

3.  **Multi-Step Data Migrations:**
    *   Migrating data between tables or schemas in stages, with explicit commit points to ensure data consistency at each step.

4.  **Error Handling with Rollback:**
    *   Procedures allow more granular error handling. You can define `EXCEPTION` blocks and decide to `ROLLBACK` only specific parts of the procedure's logic while allowing other parts to `COMMIT`.

5.  **Running DDL Operations with Transaction Control:**
    *   While DDL statements (like `CREATE TABLE`, `ALTER TABLE`) implicitly commit in functions, procedures can wrap DDL within explicit transactions, allowing for atomic DDL operations (though be aware that some DDLs still issue implicit commits and cannot be rolled back, like `CREATE INDEX CONCURRENTLY`).

---

###  Example: A Simple Procedure

Here's an example of a procedure that simulates a multi-step data processing task with explicit transaction control.

```sql
-- Create a log table for demonstration
CREATE TABLE process_log (
    log_id SERIAL PRIMARY KEY,
    message TEXT,
    log_time TIMESTAMP DEFAULT NOW()
);

-- Create a dummy data table
CREATE TABLE raw_data (
    id SERIAL PRIMARY KEY,
    value TEXT
);

-- Insert some raw data
INSERT INTO raw_data (value) VALUES ('data A'), ('data B'), ('data C');

-- Create the procedure
CREATE OR REPLACE PROCEDURE process_data_in_stages()
LANGUAGE plpgsql
AS $$
BEGIN
    -- Stage 1: Process some data and commit
    INSERT INTO process_log (message) VALUES ('Starting Stage 1: Processing raw data.');
    UPDATE raw_data SET value = UPPER(value) WHERE id = 1;
    INSERT INTO process_log (message) VALUES ('Stage 1 completed. Committing...');
    COMMIT; -- Explicit commit here

    -- Stage 2: Attempt another operation, potentially with an error
    INSERT INTO process_log (message) VALUES ('Starting Stage 2: Archiving data.');
    -- Simulate an error condition
    IF (SELECT COUNT(*) FROM raw_data) < 2 THEN
        RAISE EXCEPTION 'Not enough data for Stage 2 processing!';
    END IF;
    UPDATE raw_data SET value = 'ARCHIVED-' || value WHERE id = 2;
    INSERT INTO process_log (message) VALUES ('Stage 2 completed. Committing...');
    COMMIT; -- Explicit commit here

    -- Stage 3: Clean up or finalize
    INSERT INTO process_log (message) VALUES ('Starting Stage 3: Finalizing.');
    DELETE FROM raw_data WHERE id = 3;
    INSERT INTO process_log (message) VALUES ('Stage 3 completed. Committing...');
    COMMIT; -- Explicit commit here

EXCEPTION
    WHEN OTHERS THEN
        INSERT INTO process_log (message) VALUES ('Error in procedure: ' || SQLERRM || '. Rolling back stage.');
        ROLLBACK; -- Rollback current uncommitted transaction
        RAISE; -- Re-raise the exception to the caller
END;
$$;

-- How to call the procedure
CALL process_data_in_stages();

-- Check the log to see the commit points and messages
SELECT * FROM process_log ORDER BY log_id;

-- Check the raw_data table
SELECT * FROM raw_data;
```

In this example, if Stage 2 fails, only the uncommitted changes within Stage 2's transaction would be rolled back, while the changes from Stage 1 would remain committed. This fine-grained control is the primary benefit of using procedures in PostgreSQL.