# file t1.asm
.data
STRING_T01: .asciiz "\Starting Second task...\n"
STRING_T1: .asciiz "\nSecond Task - "
.text
t1:
	li $t0,0
	la $a0, STRING_T01
	li $v0, 4
	syscall
repeat1:
	la $a0, STRING_T1
	li $v0, 4
	syscall
	
	move $a0,$t0
	li $v0, 1
	syscall
	
	addi $t0,$t0,1
	b repeat1
