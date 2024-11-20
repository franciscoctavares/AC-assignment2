.data

STRING_T2A: .asciiz "\Starting Third task...\n"
STRING_T2B: .asciiz "\nThird Task - "

.text

task2: 
	li $s0, 0
	la $a0, STRING_T2A
	print_string
repeat_task2:
	la $a0, STRING_T2B
	print_string
	
	move $a0, $s0
	print_int
	
	addi $s0,$s0,1
	b repeat_task2
