#include<stdio.h>
#include<math.h>
#include<signal.h>

/*
Title: Quadratic Roots
Author: Cody Somers
Date: Sept 8, 2022
Microcontroller: N/A
Description: Will take in three floating point numbers and print the roots of the quadratic equation to the terminal using the input values. 
*/

void solve(double a, double b, double c, double *root1, double *root2){

if (b*b - 4*a*c > 0){ // Determinant for real numbers.
*root1 = (-b + sqrt(b*b - 4*a*c)) / (2*a);
*root2 = (-b - sqrt(b*b - 4*a*c)) / (2*a);
printf("The roots are %.5g and %.5g \n", *root1,*root2);
}

if (b*b - 4*a*c == 0){ // Determinant for equal numbers 
*root1 = (-b) / (2*a);
printf("The root is %.5g \n", *root1);
}

if (b*b - 4*a*c < 0){ // Determinant for complex numbers.
*root1 = (-b) / (2*a);
*root2 = sqrt(-(b*b - 4*a*c)) / (2*a);
printf("The roots are %.5g + %.5gi and %.5g - %.5gi \n", *root1,*root2,*root1,*root2);
}
}

int main(void){
double a,b,c;
double root1,root2;

printf("For the equation ax^2 + bx + c \n");
printf("Enter a value for a:");
scanf("%lf", &a);

printf("Enter a value for b:");
scanf("%lf", &b);

printf("Enter a value for c:");
scanf("%lf", &c);

solve(a,b,c,&root1,&root2);

return 0;
}
