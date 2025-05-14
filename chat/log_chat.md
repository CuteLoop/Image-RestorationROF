Great! To document the new **logging feature** for your ROF image restoration test suite, here’s a concise and professional section you can include in your project’s `README.md`, documentation, or a `tests/README.md` file.

---

## 📝 Logging Feature for Test Suite

### 📌 Overview

The ROF image restoration test suite now includes **automatic logging** for all tests, capturing both a complete history and the latest test run.

### ✅ What It Does

* Runs all unit and integration tests for the project
* Records pass/fail status for each test
* Logs output in two files:

  * `test/logs/test_log_YYYYMMDD_HHMMSS.txt` – archive of every test run
  * `test/logs/test_log_last.txt` – overwritten each time with most recent results

### 📁 Log Folder Structure

```
test/
├── logs/
│   ├── test_log_20240513_204913.txt   # ⬅️ full history
│   └── test_log_last.txt              # ⬅️ most recent run
```

### 🧪 How to Run All Tests

```matlab
run_all_tests
```

This command:

* Executes all registered tests
* Automatically saves logs to the appropriate files
* Outputs a summary at the end of the run

---

### 🧰 Optional: Add to Git Ignore

If you don’t want logs in version control:

Add this to `.gitignore`:

```
/test/logs/
```

---

### 🧠 Future Ideas

* Add runtime duration per test
* Add test regression detection (e.g., previously passing test now fails)
* Generate `logs/test_summary.csv` with pass/fail and timestamps

---

Would you like this as a `docs/testing.md` file or embedded in your `README.md` directly? I can format either version for you.
