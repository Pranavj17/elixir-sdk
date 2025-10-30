# Contributing to Elixir MCP SDK

Thank you for your interest in contributing to the Elixir SDK for Model Context Protocol!

## Code of Conduct

This project follows the [Model Context Protocol Code of Conduct](https://github.com/modelcontextprotocol/.github/blob/main/CODE_OF_CONDUCT.md).

## How to Contribute

### Reporting Bugs

1. Check existing issues to avoid duplicates
2. Create a new issue with:
   - Clear description of the bug
   - Steps to reproduce
   - Expected vs actual behavior
   - Elixir version and OS details

### Suggesting Features

1. Open a discussion in GitHub Discussions
2. Explain the use case and benefits
3. Provide example code if possible

### Pull Requests

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes
4. Add tests for new functionality
5. Ensure all tests pass (`mix test`)
6. Format code (`mix format`)
7. Commit with clear messages
8. Push to your fork
9. Open a Pull Request

## Development Setup

### Prerequisites

- Elixir 1.18+ and Erlang 27+
- Git

### Setup

```bash
# Clone the repository
git clone https://github.com/Pranavj17/elixir-sdk.git
cd elixir-sdk

# Install dependencies
mix deps.get

# Compile
mix compile

# Run tests
mix test

# Format code
mix format
```

## Code Style

- Follow the [Elixir Style Guide](https://github.com/christopheradams/elixir_style_guide)
- Use `mix format` before committing
- Write clear, descriptive function names
- Add `@moduledoc` and `@doc` for all public functions
- Use typespecs for function signatures

## Testing

- Write tests for all new features
- Maintain or improve test coverage
- Tests should be in `test/` directory
- Use descriptive test names

```elixir
describe "MCP.Server.register_tool/5" do
  test "registers a tool successfully" do
    # Test implementation
  end

  test "returns error for invalid schema" do
    # Test implementation
  end
end
```

## Protocol Compliance

All changes must comply with the [MCP Specification version 2024-11-05](https://modelcontextprotocol.io).

### Key Requirements

1. **JSON-RPC 2.0**: All messages must follow JSON-RPC 2.0 format
2. **Message Types**: Support request, response, notification, and error
3. **Capabilities**: Tools, Resources, Prompts must match spec
4. **Transports**: stdio and HTTP must work correctly

## Documentation

- Update README.md for user-facing changes
- Update module documentation for API changes
- Add examples for new features
- Keep CHANGELOG.md updated

## Commit Messages

Follow the Conventional Commits format:

```
type(scope): description

[optional body]

[optional footer]
```

**Types:**
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes (formatting)
- `refactor`: Code refactoring
- `test`: Test changes
- `chore`: Build/tooling changes

**Examples:**
```
feat(tools): add support for streaming tool responses
fix(resources): handle URI template edge cases
docs(readme): add Phoenix integration example
```

## Release Process

(For maintainers)

1. Update version in `mix.exs`
2. Update `CHANGELOG.md`
3. Commit changes
4. Tag release: `git tag v0.2.0`
5. Push: `git push origin main --tags`
6. Publish to Hex: `mix hex.publish`

## Questions?

- Open a GitHub Discussion
- Check existing issues and PRs
- Review the README and documentation

## License

By contributing, you agree that your contributions will be licensed under the MIT License.

Thank you for helping make the Elixir MCP SDK better! 🎉
