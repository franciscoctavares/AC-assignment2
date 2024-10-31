# a0 = adress of string to be printed
.macro print_string
	li $v0, 4
	syscall
.end_macro

# a0 = integer to be printed
.macro print_int
	li $v0, 1
	syscall
.end_macro

# a0 = char to be printed
.macro print_char
	li $v0, 11
	syscall
.end_macro

.eqv at 0
.eqv v0 4
.eqv v1 8
.eqv a0 12
.eqv a1 16
.eqv a2 20
.eqv a3 24
.eqv t0 28
.eqv t1 32
.eqv t2 36
.eqv t3 40
.eqv t4 44
.eqv t5 48
.eqv t6 52
.eqv t7 56
.eqv s0 60
.eqv s1 64
.eqv s2 68
.eqv s3 72
.eqv s4 76
.eqv s5 80
.eqv s6 84
.eqv s7 88
.eqv t8 92
.eqv t9 96
.eqv k0 100
.eqv k1 104
.eqv gp 108
.eqv sp 112
.eqv fp 116
.eqv ra 120
.eqv hi 124
.eqv lo 128
.eqv epc 132
.eqv PROCESS_ID 136
.eqv NEXT_PCB 140
