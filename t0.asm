.data

STRING_T0A: .asciiz "\Starting First task...\n"
STRING_T0B:  .asciiz "\nFirst Task - "	

.text

task0:
	li $s0, 0
	la $a0, STRING_T0A
	print_string
repeat_task0:
	la $a0, STRING_T0B
	print_string
	
	move $a0, $s0
	print_int
	
	addi $s0, $s0, 1
	b repeat_task0
