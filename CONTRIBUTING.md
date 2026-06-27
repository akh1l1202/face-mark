# Contributing Guidelines

Thank you for your interest in contributing to **Facemark**! We welcome contributions from developers, designers, writers, and anyone looking to improve this touchless AI attendance system.

This document details the coding standards, branching model, pull request process, and development guidelines to help maintain quality and consistency across both the Flutter frontend and FastAPI backend.

---

## 🗺️ Git Branching Strategy

We follow a structured branching model to keep the code stable and track development updates smoothly:

1. **`main`**: The production-ready branch. Only fully tested, approved releases should be merged here.
2. **`dev`**: The integration branch. Day-to-day development features are merged here first before release.
3. **`feature/*`**: Individual features or improvements (e.g. `feature/anti-spoofing`, `feature/report-export`). Branch off `dev`.
4. **`bugfix/*`**: Bug fixes for issues found in the development branch. Branch off `dev`.
5. **`hotfix/*`**: Critical patches for issues discovered in production. Branch off `main` and merge back into both `main` and `dev`.

### Commits Convention
We follow the **Conventional Commits** standard:
* `feat`: A new feature (e.g. `feat: add face re-enrollment support`)
* `fix`: A bug fix (e.g. `fix: prevent duplicate attendance session`)
* `docs`: Documentation only changes (e.g. `docs: add contributing guidelines`)
* `style`: Changes that do not affect the meaning of the code (formatting, white-space, etc.)
* `refactor`: A code change that neither fixes a bug nor adds a feature
* `chore`: Maintenance tasks (dependencies updates, configuration adjustments, etc.)

---

## 🛠️ Local Development Setup

Refer to the main [README.md](README.md) for quick-start guides to launch the FastAPI backend server and Flutter client application locally.

---

## 🎨 Coding Standards & Style Guides

To keep the project clean, readable, and maintainable, please follow these style guides:

### 📱 Frontend (Dart / Flutter)
* **Formatting**: Always format your code using the Dart tool:
  ```bash
  flutter format .
  ```
* **Lints**: Ensure your code passes all lint checks configured in `frontend/analysis_options.yaml`:
  ```bash
  flutter analyze
  ```
* **Naming Conventions**:
  * Use `UpperCamelCase` for classes, mixins, extension names, and enum types.
  * Use `lowerCamelCase` for variables, properties, parameter names, and function names.
  * Use `snake_case` for file names and directory names.
* **Architecture**: Keep UI components isolated from API calls. Place network requests inside `frontend/lib/api_service.dart` and database/logic inside `frontend/lib/attendance_service.dart`.

### 🐍 Backend (Python / FastAPI)
* **Style Guide**: Adhere to PEP 8 standards. We recommend using tools like `black` or `ruff` for automated formatting.
* **Typing**: Use static type hints (`typing` module) for all function arguments and return signatures to leverage FastAPI's automatic validation.
* **Docstrings**: Document classes, routes, and utility functions using Google-style or Sphinx docstrings.
* **Database Updates**: Keep database actions isolated within `firebase_utils.py` and API route definitions inside `main.py`.

---

## 🚀 Pull Request Process

1. **Branch off `dev`** for any feature or bugfix.
2. **Implement your changes** and ensure all automated tests pass.
3. **Update documentation** (in the `docs/` folder) if your changes affect application behaviors, API endpoints, or database structures.
4. **Format & Analyze** your code using the formatting tools mentioned above.
5. **Open a Pull Request (PR)** against the `dev` branch.
   * Provide a clear description of the change, why it's needed, and what files were modified.
   * Reference any related open issues.
6. **Code Review**: At least one maintainer must review and approve your PR before it is merged.

---

## 🐛 Reporting Issues

If you find a bug, have a feature request, or see room for documentation improvement:
1. Check the existing Issues to make sure it hasn't already been reported.
2. If it hasn't, open a new issue.
3. Provide as much context as possible:
   * **Environment**: OS version, Flutter version, Python version.
   * **Steps to Reproduce**: Detailed list of steps to trigger the bug.
   * **Logs & Screenshots**: Console stack traces, API response errors, or UI screenshots.
