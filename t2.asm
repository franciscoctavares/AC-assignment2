# file t2.asm
.data
STRING_T2A: .asciiz "\Starting Third task...\n"
STRING_T2B: .asciiz "\nThird Task - "
.text
task2: 
	li $t0,0
	la $a0, STRING_T2A
	li $v0, 4
	syscall
repeat_task2:
	la $a0, STRING_T2B
	li $v0, 4
	syscall
	
	move $a0,$t0
	li $v0, 1
	syscall
	
	addi $t0,$t0,1
	b repeat_task2
