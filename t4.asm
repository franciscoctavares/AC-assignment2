.data

STRING_T4: .asciiz "\Going to fill the Bitmap Display...\n"
DISPLAY_ADDRESS: .word 0x10010000

.text

task4:
	li $s2, 2 # duration of sleep calls
	li $s0, 0
	li $s2, 0x10010000 # display address
	li $s1, 0x00FF0000 # red
	li $t0, 0
	li $t1, 0 # color counter
	la $a0, STRING_T4
	print_string
repeat_task4:
	sw $s1, ($s2)
	addi $s0, $s0, 4
	addi $t0, $t0, 16
	addi $s2, $s2, 4
	
	addi $t1, $t1, 1
	beq $t0, 1024, t4_sleep
	beq $t1, 5, switch_color
	b repeat_task4
	
t4_sleep:
	move $a0, $s2
	jal sleep
	b reset_display_address
exit:
	li $v0, 10
	syscall
	
switch_color:
	li $t1, 0
	beqz $s1, go_back_filling
	beq $s1, 0x00FF0000, to_green
	beq $s1, 0x0000FF00, to_blue
	beq $s1, 0x000000FF, to_red
	to_green:
		li $s1, 0x0000FF00 # green
		b go_back_filling
	to_blue:
		li $s1, 0x000000FF # blue
		b go_back_filling
	to_red:
		li $s1, 0x00FF0000 # green
	go_back_filling:
		b repeat_task4
		
reset_display_address:
	li $t0, 0
	li $s0, 0
	li $s2, 0x10010000 # resets the display adress
	bnez $s1, was_filling
	just_cleaned:
		li $s1, 0x00FF0000
		b done_reset
	was_filling:
		li $s1, 0 # sets the color to black, to cleanup the display
	done_reset:
		b repeat_task4