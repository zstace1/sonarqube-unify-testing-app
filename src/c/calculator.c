#include "calculator.h"
#include <stdio.h>
#include <stdlib.h>

/**
 * Add two integers
 */
int add(int a, int b) {
    return a + b;
}

/**
 * Subtract two integers
 */
int subtract(int a, int b) {
    return a - b;
}

/**
 * Multiply two integers
 */
int multiply(int a, int b) {
    return a * b;
}

/**
 * Divide two integers
 * Returns 0 if attempting to divide by zero
 */
int divide(int a, int b) {
    if (b == 0) {
        fprintf(stderr, "Error: Division by zero\n");
        return 0;
    }
    return a / b;
}

/**
 * Calculate power (base^exponent)
 */
int power(int base, int exponent) {
    if (exponent < 0) {
        return 0;
    }
    if (exponent == 0) {
        return 1;
    }

    int result = 1;
    for (int i = 0; i < exponent; i++) {
        result *= base;
    }
    return result;
}

/**
 * Calculate factorial
 */
int factorial(int n) {
    if (n < 0) {
        return -1;
    }
    if (n == 0 || n == 1) {
        return 1;
    }

    int result = 1;
    for (int i = 2; i <= n; i++) {
        result *= i;
    }
    return result;
}
