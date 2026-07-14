#include <stdio.h>
#include <stdlib.h>
#include "calculator.h"

void print_menu() {
    printf("\n=== SDLC Metrics Demo Calculator ===\n");
    printf("1. Addition\n");
    printf("2. Subtraction\n");
    printf("3. Multiplication\n");
    printf("4. Division\n");
    printf("5. Power\n");
    printf("6. Factorial\n");
    printf("0. Exit\n");
    printf("Choose operation: ");
}

int main() {
    int choice;
    int a, b, result;

    printf("CloudBees Unify SDLC Metrics Demo Application\n");
    printf("Version: 1.0.0\n");

    while (1) {
        print_menu();

        if (scanf("%d", &choice) != 1) {
            printf("Invalid input\n");
            while (getchar() != '\n'); // Clear input buffer
            continue;
        }

        if (choice == 0) {
            printf("Exiting...\n");
            break;
        }

        switch (choice) {
            case 1:
                printf("Enter two numbers: ");
                scanf("%d %d", &a, &b);
                result = add(a, b);
                printf("Result: %d + %d = %d\n", a, b, result);
                break;

            case 2:
                printf("Enter two numbers: ");
                scanf("%d %d", &a, &b);
                result = subtract(a, b);
                printf("Result: %d - %d = %d\n", a, b, result);
                break;

            case 3:
                printf("Enter two numbers: ");
                scanf("%d %d", &a, &b);
                result = multiply(a, b);
                printf("Result: %d * %d = %d\n", a, b, result);
                break;

            case 4:
                printf("Enter two numbers: ");
                scanf("%d %d", &a, &b);
                result = divide(a, b);
                if (b != 0) {
                    printf("Result: %d / %d = %d\n", a, b, result);
                }
                break;

            case 5:
                printf("Enter base and exponent: ");
                scanf("%d %d", &a, &b);
                result = power(a, b);
                printf("Result: %d ^ %d = %d\n", a, b, result);
                break;

            case 6:
                printf("Enter number: ");
                scanf("%d", &a);
                result = factorial(a);
                if (result >= 0) {
                    printf("Result: %d! = %d\n", a, result);
                } else {
                    printf("Factorial of negative number is undefined\n");
                }
                break;

            default:
                printf("Invalid choice\n");
                break;
        }
    }

    return 0;
}
