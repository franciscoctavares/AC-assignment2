# a0 = integer to print
.macro print_int
	li $v0, 1
	syscall
.end_macro

.macro print_string
	li $v0, 4
	syscall
.end_macro

.macro new_line
	li $v0, 11
	li $a0, 10
	syscall
.end_macro

.macro print_pointer
	li $v0, 1
	syscall
.end_macro

.macro space
	li $v0, 11
	li $a0, ' '
	syscall
.end_macro
