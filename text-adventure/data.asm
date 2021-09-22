	;; /////////////////////////////
	;; Setup macros for data sizes.
	%assign _byte 1
	%assign _word 2
	%assign _dword 4
	%assign _qword 8
	%define true 1
	%define false 0

user_in:	db "1234567890 abcdefghijklmno ABCDEFGHIJK qwertyasdfzxcv",0
input_str:	db ".............",10

	;; [pppppppplpppppppplppppppppl]
ptr_buffer_struct:	times 90 db 0 ;{ptr (8 bytes), len (1 byte)} = 9 bytes * 10
input_prompt:
	db "..."
	.len: equ $ - input_prompt

input_1:	equ 0
input_2:	equ 9
input_3:	equ 18

char:
	.space: db " "	

	%define DBG_STR(x) debug_strings. %+ x
debug_strings:
	.player_within: db "you are within "
	.player_within_len: equ $ - .player_within
	
action_strings:
	.look: db "look",0
	.walk: db "walk",0
	.run: db "run",0
	.crouch: db "crouch",0
	.sleep: db "sleep",0

	%macro SAW 1
	push rax		;preserve rax
	;; set flag 'look' to 1 to signal that we saw something
	xor rax,rax		;clear rax
	mov al,%1		;set rax (al:8bit) to 1 or 0
	mov [flags.look],al	;store al (rax) into memory location flags.look. 
	pop rax
	%endmacro

	%macro IF_SAW_SOMETHING 2
	push rax
	xor rax,rax
	mov al,[flags.look]
	cmp al,0
	pop rax
	je %2
	jmp %1
	%endmacro
flags:
	.look: db 0

	;; /////////////////
	;; Direction macros
	%assign dir.north 1
	%assign dir.east 2
	%assign dir.south 3
	%assign dir.west 4
	%assign dir.up 5
	%assign dir.down 6

	%define VW_STR(x) view_strings. %+ x
	%define DIR_STR(x) direction_strings. %+ x
	%define DESC_STR(x) description_strings. %+ x
	
view_strings:
	.left: db "on your left",0
	.left_len: equ $ - .left
	.left_ahead: db "ahead and to your left",0
	.left_ahead_len: equ $ - .left_ahead
	.straight_ahead: db "straight ahead of you",0
	.straight_ahead_len: equ $ - .straight_ahead
	.right_ahead: db "ahead and to your right",0
	.right_ahead_len: equ $ - .right_ahead
	.right: db "on your right",0
	.right_len: equ $ - .right

direction_strings:
	.up: db "up",0		
	.down: db "down",0	
	.left: db "left",0	
	.right: db "right",0	
	.ahead: db "ahead",0
	.ahead_len: equ $ - .ahead
	.behind: db "behind",0	
	.forward: db "forward",0
	.backward: db "backward",0
	.north: db "north",0
	.north_len: equ $ - .north
	.south: db "south",0
	.south_len: equ $ - .south
	.east: db "east",0
	.east_len: equ $ - .east
	.west: db "west",0
	.west_len: equ $ - .west

description_strings:
	.nothing: db "nothing.",10
	.nothing_len: equ $ - .nothing

	.look: db "You look "
	.look_len: equ $ - .look
	.and_see: db " and see "
	.and_see_len: equ $ - .and_see
	.meters: db "dm"		;units in decimeters
	.meters_len: equ $ - .meters
	
	.look_down: db "You look down and see "
	.look_down_len: equ $ - .look_down
	.look_ahead: db "You look ahead and see "
	.look_ahead_len: equ $ - .look_ahead
	.walk: db "You start walking "
	.walk_len: equ $ - .walk
	
match:		db "OK",10
no_match:	db "That doesn't make sense.",10
no_match_len:	equ $ - no_match

story:
	.chapter1_file: db "chapter1.wrld",0
	.chapter1_buf: times 1000 db 0
	.chapter1_len: dd 0

screen1_file:		db "chapter1.story"
screen1_buf:		times 1000 db 0
screen1_len:		dd 0
screen1_file_pos:	dd 0
	
screen2:	db "You look down and see dirt and an assortment of grass.",10,"Among the grass is a rusted box about the size of a cell phone. ",10,"Dried mud covers the majority of it but it appears that there is a series of characters stamped on the bottom corner.",10
screen2_len:	equ $ - screen2

screens:
	.sleep: db "You decide to get some rest. You take off your backup and grab the thin waterproof sleeping pouch and settle down for a few hours rest.",10
	.sleep_len: equ $ - .sleep
	
	
