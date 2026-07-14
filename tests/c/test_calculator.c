#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "../../src/c/calculator.h"

/* Simple test framework */
int tests_run = 0;
int tests_passed = 0;
int tests_failed = 0;

#define TEST(name) static void name()
#define RUN_TEST(test) do { \
    printf("Running: %s\n", #test); \
    test(); \
    tests_run++; \
} while (0)

#define ASSERT_EQUAL(expected, actual) do { \
    if ((expected) == (actual)) { \
        printf("  PASS: Expected %d, got %d\n", expected, actual); \
        tests_passed++; \
    } else { \
        printf("  FAIL: Expected %d, got %d\n", expected, actual); \
        tests_failed++; \
    } \
} while (0)

/* Test cases */
TEST(test_add_positive) {
    ASSERT_EQUAL(5, add(2, 3));
    ASSERT_EQUAL(100, add(50, 50));
}

TEST(test_add_negative) {
    ASSERT_EQUAL(-5, add(-2, -3));
    ASSERT_EQUAL(0, add(-10, 10));
}

TEST(test_subtract) {
    ASSERT_EQUAL(5, subtract(10, 5));
    ASSERT_EQUAL(-5, subtract(5, 10));
    ASSERT_EQUAL(0, subtract(10, 10));
}

TEST(test_multiply) {
    ASSERT_EQUAL(20, multiply(4, 5));
    ASSERT_EQUAL(0, multiply(0, 100));
    ASSERT_EQUAL(-20, multiply(-4, 5));
}

TEST(test_divide) {
    ASSERT_EQUAL(5, divide(20, 4));
    ASSERT_EQUAL(0, divide(10, 0));  // Division by zero returns 0
    ASSERT_EQUAL(-5, divide(-20, 4));
}

TEST(test_power) {
    ASSERT_EQUAL(8, power(2, 3));
    ASSERT_EQUAL(1, power(5, 0));
    ASSERT_EQUAL(0, power(5, -1));  // Negative exponent returns 0
    ASSERT_EQUAL(81, power(3, 4));
}

TEST(test_factorial) {
    ASSERT_EQUAL(1, factorial(0));
    ASSERT_EQUAL(1, factorial(1));
    ASSERT_EQUAL(120, factorial(5));
    ASSERT_EQUAL(720, factorial(6));
    ASSERT_EQUAL(-1, factorial(-5));  // Negative factorial returns -1
}

/* JUnit XML output generation */
void generate_junit_xml(const char *filename) {
    FILE *fp = fopen(filename, "w");
    if (!fp) {
        fprintf(stderr, "Cannot create JUnit XML file\n");
        return;
    }

    fprintf(fp, "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n");
    fprintf(fp, "<testsuites>\n");
    fprintf(fp, "  <testsuite name=\"CalculatorTests\" tests=\"%d\" failures=\"%d\" errors=\"0\" skipped=\"0\">\n",
            tests_run, tests_failed);

    // Summary of test results
    fprintf(fp, "    <testcase classname=\"CalculatorTests\" name=\"test_add_positive\" />\n");
    fprintf(fp, "    <testcase classname=\"CalculatorTests\" name=\"test_add_negative\" />\n");
    fprintf(fp, "    <testcase classname=\"CalculatorTests\" name=\"test_subtract\" />\n");
    fprintf(fp, "    <testcase classname=\"CalculatorTests\" name=\"test_multiply\" />\n");
    fprintf(fp, "    <testcase classname=\"CalculatorTests\" name=\"test_divide\" />\n");
    fprintf(fp, "    <testcase classname=\"CalculatorTests\" name=\"test_power\" />\n");
    fprintf(fp, "    <testcase classname=\"CalculatorTests\" name=\"test_factorial\" />\n");

    fprintf(fp, "  </testsuite>\n");
    fprintf(fp, "</testsuites>\n");

    fclose(fp);
    printf("\nJUnit XML report generated: %s\n", filename);
}

int main() {
    printf("=== Running C Calculator Tests ===\n\n");

    RUN_TEST(test_add_positive);
    RUN_TEST(test_add_negative);
    RUN_TEST(test_subtract);
    RUN_TEST(test_multiply);
    RUN_TEST(test_divide);
    RUN_TEST(test_power);
    RUN_TEST(test_factorial);

    printf("\n=== Test Summary ===\n");
    printf("Tests run: %d\n", tests_run);
    printf("Tests passed: %d\n", tests_passed);
    printf("Tests failed: %d\n", tests_failed);

    // Generate JUnit XML report
    generate_junit_xml("test-results/c-test-results.xml");

    return (tests_failed > 0) ? 1 : 0;
}
