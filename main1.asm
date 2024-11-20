.include "definitions.asm"

.data

STRING_main1A: .asciiz "\Starting main1...\n"
STRING_main1B:  .asciiz "\nmain1 - "	

.text
	#jal prep_multi
	
	
	la $t0, PCB_BLOCKS
	sw $t0, RUNNING
	sw $zero, NEXT_PCB($t0) # RUNNING -> next = null
	#addi $t0, $t0, PCB_SIZE
	sw $t0, AVAILABLE # available = available -> next
	
	sw $zero, READY_HIGH
	sw $zero, READY_LOW
	sw $zero, LAST_READY_HIGH
	sw $zero, LAST_READY_LOW
	sw $zero, WAITING
	
	la $t0, IDLE_TASK_PCB
	sw $t0, IDLE_TASK
	la $t1, idle_task
	sw $t1, epc($t0)
	
	li $t1, 123456
	sw $t1, TICKS_TO_SWITCH($t0)
	
	la $a0, prep_multi_str
	print_string
	
	jal prep_multi
	
	jal start_multi
	
	la $a0, start_multi_str
	print_string

task_main1:
	li $s0, 1
	la $a0, STRING_main1A
	print_string
	repeat_main1:
		beq $s0, 100, main1_sleep
		la $a0, STRING_main1B
		print_string
		move $a0, $s0
		print_int
		addi $s0, $s0, 1
		
		b repeat_main1
	main1_sleep:
		li $a0, 3
		lw $t0, IDLE_TASK
		jal sleep
		li $s0, 1
		b repeat_main1
		
		
.include "interrupt.asm"
.include "main.asm"
