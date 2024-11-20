.data

STRING_T01: .asciiz "\Starting Second task...\n"
STRING_T1: .asciiz "\nSecond Task - "

.text

task1:
	li $s0, 0
	la $a0, STRING_T01
	print_string
repeat_task1:
	la $a0, STRING_T1
	print_string
	
	move $a0, $s0
	print_int
	
	addi $s0, $s0, 1
	b repeat_task1
