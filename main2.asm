.include "definitions.asm"

.data

STRING_T3A: .asciiz "\Starting Custom task 1...\n"
STRING_T3B:  .asciiz "\nCustom Task 1 - "

.text
	jal prep_multi
	la $a0, prep_multi_str
	print_string
	
	la $a0, task4
	li $a1, 1
	jal newtask
	
	##### UNCOMMENT THESE 3 LINES WHEN TESTING
	#la $a0, mystery_task
	#li $a1
	#jal newtask
	
	jal start_multi
	la $a0, start_multi_str
	print_string

task3:
	li $s0, 0
	li $s1, 3
	la $a0, STRING_T3A
	print_string
repeat_task3:
	la $a0, STRING_T3B
	print_string
	
	move $a0, $s0
	print_int
	
	addi $s0, $s0, 1
	beq $s0, 10, t3_sleep
	b repeat_task3

# s1 holds the number of sleep ticks	
t3_sleep:
	li $s0, 0
	move $a0, $s1
	jal sleep
	addi $s1, $s1, -1
	bne $s1, 1, go_back
reset_ticks:
	li $s1, 3
go_back:
	b repeat_task3

.include "t4.asm"
.include "interrupt.asm"
.include "main.asm"