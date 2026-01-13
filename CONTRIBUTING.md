# Contributing to ConfigForge

Thank you for your interest in contributing to ConfigForge.

## Getting Started

1. Fork the repository
2. Clone your fork locally
3. Ensure Lua 5.4 is installed
4. Create a feature branch: `git checkout -b feature/your-feature`

## Development

### Code Style

* Use standard Lua 5.4 syntax
* Format code consistently (2 spaces indentation)
* Keep functions focused and modular
* Add LuaDoc comments for public functions (`---`)
* Avoid global variables; use `local`

### Testing

Run the validation commands before submitting:

```bash
lua configforge.lua validate example.json
```

Ensure all basic commands (`convert`, `validate`, `diff`) work as expected.

### Commit Messages

* Use clear, descriptive commit messages
* Start with a verb (Add, Fix, Update, Remove)
* Keep the first line under 72 characters

## Pull Request Process

1. Ensure all functionality works
2. Update documentation (README) if needed
3. Submit PR against the `main` branch
4. Describe your changes in the PR description

## Reporting Issues

* Check existing issues before creating a new one
* Include Lua version and OS information
* Provide steps to reproduce the issue
* Include relevant error messages

## License

By contributing, you agree that your contributions will be licensed under the MIT License.
