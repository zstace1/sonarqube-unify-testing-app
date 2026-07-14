# Contributing to SDLC Metrics Jenkins Demo

Thank you for your interest in improving this CloudBees Professional Services demo repository!

## Development Workflow

### Local Development

1. **Clone the repository:**
   ```bash
   git clone https://github.com/YOUR_ORG/sdlc-metrics-jenkins-demo.git
   cd sdlc-metrics-jenkins-demo
   ```

2. **Create a feature branch:**
   ```bash
   git checkout -b feature/your-feature-name
   ```

3. **Make your changes:**
   - Follow the existing code style
   - Add tests for new functionality
   - Update documentation as needed

4. **Test locally:**
   ```bash
   ./scripts/local-test.sh
   ```

5. **Commit your changes:**
   ```bash
   git add .
   git commit -m "Brief description of your changes"
   ```

6. **Push and create a pull request:**
   ```bash
   git push origin feature/your-feature-name
   ```

## Code Standards

### C Code
- Follow C11 standard
- Use meaningful variable and function names
- Add comments for complex logic
- Include header guards in `.h` files
- Keep functions focused and single-purpose

### Python Code
- Follow PEP 8 style guide
- Maximum line length: 120 characters
- Use type hints where applicable
- Write docstrings for all functions and classes
- Use meaningful variable names

### Tests
- All new code must include tests
- Aim for high test coverage
- Use descriptive test names: `test_function_name_expected_behavior`
- Include both positive and negative test cases

## Adding New Features

### Adding a New Calculator Function

**C Implementation:**
1. Add function signature to `src/c/calculator.h`
2. Implement function in `src/c/calculator.c`
3. Add test cases to `tests/c/test_calculator.c`
4. Run `make test` to verify

**Python Implementation:**
1. Add function to `src/python/app.py`
2. Add API endpoint if needed
3. Add test cases to `tests/python/test_app.py`
4. Run `pytest tests/python/` to verify

### Adding a New Security Scanner

1. Add a new stage to `Jenkinsfile`:
   ```groovy
   stage('Scanner Name') {
       steps {
           sh 'scanner-command --output report.sarif'
       }
       post {
           always {
               registerSecurityScan(
                   artifacts: "report.sarif",
                   format: "sarif",
                   scanner: "ScannerName",
                   archive: true
               )
           }
       }
   }
   ```

2. Update README with scanner documentation
3. Test in Jenkins environment

## Documentation Updates

When making changes, update:
- `README.md` - For user-facing changes
- `CONTRIBUTING.md` - For development process changes
- Code comments - For implementation details
- `Jenkinsfile` comments - For pipeline changes

## Testing Requirements

All contributions must pass:

1. **Local Tests:**
   - C unit tests (`make test`)
   - Python unit tests (`pytest tests/python/`)
   - Code quality checks (`flake8`)

2. **Jenkins Pipeline:**
   - All stages must complete successfully
   - No new vulnerabilities introduced
   - Test coverage maintained or improved

3. **Documentation:**
   - README updated for new features
   - Code comments added for complex logic
   - Jenkinsfile comments explain new stages

## Pull Request Process

1. **Update the README.md** with details of changes if applicable
2. **Ensure all tests pass** locally before submitting
3. **Add screenshots** if changing UI/output
4. **Reference any related issues** in the PR description
5. **Request review** from CloudBees PS team members

## Code Review Guidelines

Reviewers will check:
- Code follows established patterns
- Tests are comprehensive
- Documentation is updated
- No security vulnerabilities introduced
- CloudBees Unify integration points work correctly

## Questions?

For questions about contributing, contact the CloudBees Professional Services team.
