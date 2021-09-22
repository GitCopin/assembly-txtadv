	%include "../common/macros.asm"
	
	global	main
	;; functions:
	;; string.asm
	extern str_len, str_copy, str_clear, str_comp, str_split_ptr, str_comp_ptr
	;; math.asm
	extern distance_i2ef
	;; functions.asm
	extern printi
	extern canonical_off, echo_off, canonical_on, echo_on
	;; variables
	
	section .data
	%include "data.asm"
	%include "world.asm"

loop:	db 0
	
	section .text
main:
	call build_world
	
	printsl story.chapter1,_buf

	printsl screen1,_buf 			;print screen1

	.main_loop:

	prints input_prompt,input_prompt.len 	;print input prompt
	
	mov rdi,user_in
	call str_clear
	call get_input

	;; split by spaces ' ' user_in location
	mov rdi,user_in				;memory location to read input into
	mov rsi,' '				;split char
	mov rdx,1
	mov rax,ptr_buffer_struct 		;return mem location with array of ptrs
	call str_split_ptr

	;; ///////////////////////////
	;; test for look
	mov rdi,action_strings.look
	mov rsi,[ptr_buffer_struct+0]
	call str_comp_ptr

	cmp rax,1
	je .look_match

	;; ///////////////////////////
	;; test for walk
	mov rdi,action_strings.walk
	mov rsi,[ptr_buffer_struct+0]
	call str_comp_ptr

	cmp rax,1
	je .walk_match

	;; ///////////////////////////
	;; test for sleep
	mov rdi,action_strings.sleep
	mov rsi,[ptr_buffer_struct+0]
	call str_comp_ptr
	
	cmp rax,1
	je .sleep_match

	;; ///////////////////////////
	;; test for state triggers
	GET_OBJ_FOR_PLAYER_INTERACTION
	GET_WORLD_OBJ_TRIG_QW trigger_str
	;mov rdi,obj_trigger_strings.open
	cmp rax,0
	je .no_match
	
	mov rdi,rax
	mov rsi,[ptr_buffer_struct+0]
	call str_comp_ptr
	
	cmp rax,1
	je .sleep_match
	
	;; ///////////////////////////
	;; handle unrecognized inputs
	jmp .no_match

	;; ////////////////////////////
	;; on look, test for direction
	;; test for 'down'
	.look_match:
	call get_look_direction_input
	GET_PLAYER_PROP look_dir,byte 				;get player direction
	;; TODO cleanup un-needed if_player_prop
	;; if player is looking north then jump to .look_direction
	IF_PLAYER_PROP look_dir,byte,dir.north,.look_direction 	
	IF_PLAYER_PROP look_dir,byte,dir.down,.look_down

	;; default to north
	jmp .look_direction

	;; ///////////////////////////
	.look_down:
	println match,2
	prints screen2,screen2_len
	jmp .main_loop

	;; //////////////
	.look_direction:

	;; ///////////////////////////////////////////////
	;; Print epilogue 'You look [direction] and see '
	;; Defined in ./data.asm

	;; 'You look '
	printsl DESC_STR(look)

	;; 'north', 'south', 'east', 'west'
	call print_look_direction
	
	;; ' and see '
	printsl DESC_STR(and_see)

	xor rcx,rcx
	mov [loop],byte cl			;mov 0 to loop mem location
	;; reset flag 'look'
	;; look flag used to store if something was seen or not.
	SAW 0					;macro defined in ./data.asm
	
	.look_direction_loop:
	xor rcx,rcx				;clear high bits
	mov cl,[loop]				;get current loop count from memory
	cmp cl,3				;RCX low byte.
	je .look_direction_loop_done

	SET_WORLD_OBJ_INDEX rcx			;set index for obj_array. macro defined in ./world.asm
	
	inc cl					;increment RCX byte and...
	mov [loop],cl				;...save to memory

	call obj_to_player_origin 		;function to translate object origin. returns EAX,ECX
	CALC_DISTANCE eax,ecx			;macro wrapper to calc distance. uses 32bit registers

	SET_WORLD_OBJ_PROP distance,dword eax 		;store distance of object
	
	call filter_obj_by_dir			;test if current object is not behind player direction.

	GET_WORLD_OBJ_PROP_B visible_to_player	       	;return in RAX
	cmp rax,SWO.nvis 				;0 = not visible
	je .look_direction_loop
	;; jump if al (distance) <= 4
	;cmp di,si
	GET_WORLD_OBJ_PROP_DW distance 			;get distance of obj
	cmp al,PLAYER.look_range
	jle .see_obj

	;jmp .look_direction_loop
		
	.look_direction_loop_done:

	;; test to see if we saw anything and jump.
	IF_SAW_SOMETHING .main_loop,.see_nothing 	;macro defined in ./data.asm.

	;; ///////////////////////
	;; Looked and saw nothing
	.see_nothing:
	;; 'nothing'
	printsl DESC_STR(nothing)
	jmp .main_loop

	;; /////////////////////////
	;; Looked and saw an object
	.see_obj:
	SAW 1			;macro defined in ./data.asm. something = 1

	PRINT_WORLD_OBJ_STR obj_string
	
	;; print space char
	printspc
	;; print distance for current seen object
	GET_WORLD_OBJ_PROP_DW distance 			;get distance of obj

	.debug_1:					;label for debug
	
	;; xor rdi,rdi
	;; movsxd rdi,eax
	;; call printi
	;; ;; ' meters '
	;; prints description_strings.meters_away,description_strings.meters_away_len

	;; 'on your left', 'ahead of you', etc.
	call print_pos_to_player

	;; print new line char
	printnl

	;; /////////////////////////////
	;; test within code
	call x_y_within
	cmp rax,1
	jne .not_within
	
	printsl DBG_STR(player_within)

	PRINT_WORLD_OBJ_STR obj_string
	printchar 10
	;; ////////////////////////////
	.not_within:
	
	jmp .look_direction_loop

	;; ///////////////////
	;; player walk action
	;; on walk, move player
	.walk_match:
	printsl DESC_STR(walk)

	call get_walk_direction_input
	GET_PLAYER_PROP walk_dir,byte 		;get player walk direction in RAX
	SET_PLAYER_PROP look_dir,byte,al 	;set look direction to walk direction
	
	push rdi
	push rsi
	xor rdi,rdi
	xor rsi,rsi

	mov dil,al				;direction to move
	mov si,word 1				;distance to move
	call player_move
	
	pop rsi
	pop rdi

	call print_look_direction
	printchar 10				;line break
	
	jmp .main_loop

	
	.no_match:
	prints no_match,no_match_len
	jmp .main_loop

	.sleep_match:
	prints screens.sleep,screens.sleep_len	
	exit 0
	
get_input:
	mov rax,0
	mov rdi,1
	mov rsi,user_in		;variable to store input into
	mov rdx,14		;length to store

	syscall
	ret

get_look_direction_input:
	%assign SC_match 1
	
	mov rdi,direction_strings.down
	mov rsi,[ptr_buffer_struct+input_2]
	call str_comp_ptr

	cmp rax,SC_match
	je .look_down

	;; test for 'north'
	mov rdi,direction_strings.north
	mov rsi,[ptr_buffer_struct+input_2]
	call str_comp_ptr

	cmp rax,SC_match
	je .look_north

	;; test for 'south'
	mov rdi,direction_strings.south
	mov rsi,[ptr_buffer_struct+input_2]
	call str_comp_ptr

	cmp rax,SC_match
	je .look_south

	;; test for 'east'
	mov rdi,direction_strings.east
	mov rsi,[ptr_buffer_struct+input_2]
	call str_comp_ptr

	cmp rax,SC_match
	je .look_east

	;; test for 'west'
	mov rdi,direction_strings.west
	mov rsi,[ptr_buffer_struct+input_2]
	call str_comp_ptr

	cmp rax,SC_match
	je .look_west

	;; handle unrecognized direction
	;; use .look_dir
	;; 
	ret
	jmp .look_north		;ignore

	.look_up:
	SET_PLAYER_PROP look_dir,byte,dir.up
	ret

	.look_down:
	SET_PLAYER_PROP look_dir,byte,dir.down
	ret
	
	.look_north:
	SET_PLAYER_PROP look_dir,byte,dir.north
	ret
	
	.look_south:
	SET_PLAYER_PROP look_dir,byte,dir.south
	ret

	.look_east:
	SET_PLAYER_PROP look_dir,byte,dir.east
	ret

	.look_west:
	SET_PLAYER_PROP look_dir,byte,dir.west
	ret	


get_walk_direction_input:
	%assign SC_match 1
	
	;; test for 'north'
	mov rdi,direction_strings.north
	mov rsi,[ptr_buffer_struct+input_2]
	call str_comp_ptr

	cmp rax,SC_match
	je .walk_north

	;; test for 'south'
	mov rdi,direction_strings.south
	mov rsi,[ptr_buffer_struct+input_2]
	call str_comp_ptr

	cmp rax,SC_match
	je .walk_south

	;; test for 'east'
	mov rdi,direction_strings.east
	mov rsi,[ptr_buffer_struct+input_2]
	call str_comp_ptr

	cmp rax,SC_match
	je .walk_east

	;; test for 'west'
	mov rdi,direction_strings.west
	mov rsi,[ptr_buffer_struct+input_2]
	call str_comp_ptr

	cmp rax,SC_match
	je .walk_west

	;; handle unrecognized direction
	;; use .walk_dir
	ret
	jmp .walk_north		;ignore

	.walk_up:
	SET_PLAYER_PROP walk_dir,byte,dir.up
	ret

	.walk_down:
	SET_PLAYER_PROP walk_dir,byte,dir.down
	ret
	
	.walk_north:
	SET_PLAYER_PROP walk_dir,byte,dir.north
	ret
	
	.walk_south:
	SET_PLAYER_PROP walk_dir,byte,dir.south
	ret

	.walk_east:
	SET_PLAYER_PROP walk_dir,byte,dir.east
	ret

	.walk_west:
	SET_PLAYER_PROP walk_dir,byte,dir.west
	ret	

	
	;; /////////////////////////////////////
	;; Print direction string from player look_dir
print_look_direction:
	GET_PLAYER_PROP look_dir,byte
	cmp rax,dir.north
	jne .print_south

	;; 'north'
	prints direction_strings.north,direction_strings.north_len
	jmp .done_printing_dir

	.print_south:
	cmp rax,dir.south
	jne .print_east

	;; 'south'
	prints direction_strings.south,direction_strings.south_len
	jmp .done_printing_dir

	.print_east:
	cmp rax,dir.east
	jne .print_west

	;; 'east'
	prints direction_strings.east,direction_strings.east_len
	jmp .done_printing_dir

	.print_west:
	cmp rax,dir.west
	jne .done_printing_dir

	;; 'west'
	prints direction_strings.west,direction_strings.west_len
	jmp .done_printing_dir
	
	.done_printing_dir:

	ret

x_y_within:
	push rcx		;preserve RCX and RDX
	push rdx

	;; test if player is within the obj in the x axis. returns 1(T) or 0(F).
	call x_within		
	xor rcx,rcx		;clear and mov x_within result (RAX) into RCX.
	mov rcx,rax
	;; test if player is within the obj in the y axis. returns 1(T) or 0(F).
	call y_within		
	xor rdx,rdx		;clear and mov y_within result (RAX) into RDX.
	mov rdx,rax

	xor rax,rax		;clear RAX for x_y_within result
	and ecx,edx		;AND to test for true for ECX (x_within) and EDX (y_within)
	cmp ecx,1
	;; IMPORTANT: cmp uses ZF flag. xor also uses ZF flag.
	;; so don't use xor after cmp.
	jne .ret		;if ECX (ECX AND EDX) != 1 return with 0 (false) in RAX

	xor rax,rax
	mov rax,1		;player within obj. set RAX to 1 (true)

	.ret:
	pop rdx			;restore RDX and RCX
	pop rcx
	ret
	
	;; ////////////////////////////////////////
	;; Test if x is within obj_x and obj_x + width:
	;; - Description
	;; ----------------------------------------
	;; In:          None
	;; Returns:     0 or 1 in EAX
	;; Modifies:    EAX
	;; Calls:       None
	;; Example:     x_within
x_within:
	push rdi
	push rcx
	
	GET_PLAYER_PROP pos_x,dword 	;returns in EAX
	xor rdi,rdi
	mov rdi,rax			;mov player pos_x to RDI
	GET_WORLD_OBJ_PROP_DW pos_x	;returns in EAX
	xor rcx,rcx
	mov rcx,rax
	GET_WORLD_OBJ_PROP_DW width 	;returns in EAX (AL)
	;; RDI is player pos x
	;; RCX is obj pos x
	;; RAX is obj width

	;; less than x: outside bounds
	cmp edi,ecx
	jl .outside_bounds

	;; add width to get to maximum
	add ecx,eax
	cmp edi,ecx
	jge .outside_bounds
	
	xor rax,rax
	mov rax,1
	jmp .restore_regs
	
	.outside_bounds:
	xor rax,rax
	mov rax,0
	
	.restore_regs:
	pop rcx
	pop rdi
	ret

	;; ////////////////////////////////////////
	;; Test if y is within obj_y and obj_y + depth:
	;; - Description
	;; ----------------------------------------
	;; In:          None
	;; Returns:     0 or 1 in EAX
	;; Modifies:    EAX
	;; Calls:       None
	;; Example:     y_within
y_within:
	push rdi
	push rcx
	
	GET_PLAYER_PROP pos_y,dword 	;returns in EAX
	xor rdi,rdi
	mov rdi,rax			;mov player pos_x to RDI
	GET_WORLD_OBJ_PROP_DW pos_y	;returns in EAX
	xor rcx,rcx
	mov rcx,rax
	GET_WORLD_OBJ_PROP_DW depth 	;returns in EAX (AL)
	;; RDI is player pos y
	;; RCX is obj pos y
	;; RAX is obj depth

	;; less than y: outside bounds
	cmp edi,ecx
	jg .outside_bounds

	;; add depth to get to maximum
	sub ecx,eax
	cmp edi,ecx
	jle .outside_bounds
	
	xor rax,rax
	mov rax,1
	jmp .restore_regs
	
	.outside_bounds:
	xor rax,rax
	mov rax,0
	
	.restore_regs:
	pop rcx
	pop rdi
	ret

print_pos_to_player:

	push rax
	push rdi
	
	GET_PLAYER_PROP look_dir,byte
	cmp rax,dir.north
	jne .south

	;; ///////////////////////////
	;; looking north
	;; //////////////////////////
	
	GET_PLAYER_PROP pos_x,dword
	xor rdi,rdi
	mov rdi,rax
	GET_WORLD_OBJ_PROP_DW pos_x		;returns value in EAX. 
	;; ------------------------------------
	;; straight ahead of you (to the north)
	;; ------------------------------------
	;; use x_within
	push rax				;preserve obj pos_x (RAX)
	call x_within
	cmp eax,1
	pop rax
	;; obj.x != player.x
	jne .north_on_left			;not straight ahead

	;; print "straight ahead of you Xm "
	printsl VW_STR(straight_ahead)
	printspc
	GET_WORLD_OBJ_PROP_DW y_rel_to_player 	;return value in EAX.
	printint eax
	printsl DESC_STR(meters)
	printspc
	
	jmp .done_printing_pos
	;; --------------------------
	;; on your left (to the west)
	;; --------------------------
	.north_on_left:
	cmp eax,edi				;cmp obj pos_x(EAX) with player pos_x(EDI)
	;; if obj.x < player.x is false, jump to north_on_right.
	jg .north_on_right			;not on your left

	;; print "on your left Xm, ahead Xm "
	printsl VW_STR(left)
	printspc
	GET_WORLD_OBJ_PROP_DW x_rel_to_player 	;return value in EAX.
	;; EAX is negative so convert to positive number and add 1
	;; since NOT (-1) = 0 
	cmp eax,0
	jge .left_not_neg
	not eax
	add eax,1
	.left_not_neg:
	;; print x distance from player
	printint eax
	printsl DESC_STR(meters)
	;; test if player is within obj in the y axis.
	;; if obj is directly to the left of the player.
	push rax		;preserve x_rel_to_player (EAX)
	call y_within
	cmp eax,1
	pop rax
	je .is_directly_left	;obj is directly to the left of the player. skip 'ahead'

	;; print 'ahead Xm'
	printchar 44				;comma
	printspc
	printsl DIR_STR(ahead)
	printspc
	GET_WORLD_OBJ_PROP_DW y_rel_to_player 	;return value in EAX.
	printint eax
	printsl DESC_STR(meters)
	printspc

	.is_directly_left:
	
	jmp .done_printing_pos
	;; ---------------------------
	;; on your right (to the east)
	;; ---------------------------
	.north_on_right:
	cmp eax,edi
	;; if obj.x > player.x is false, jump...
	jl .north_ahead_left	;not on your right

	;; print "on your right Xm, ahead Xm "
	printsl VW_STR(right)
	printspc
	GET_WORLD_OBJ_PROP_DW x_rel_to_player 	;return value in EAX.
	;; if EAX is negative then convert to positive.
	cmp eax,0
	jge .right_not_neg
	not eax
	add eax,1
	.right_not_neg:

	printint eax
	printsl DESC_STR(meters)
	;; test if player is within obj in the y axis.
	;; if obj is directly to the right of the player.
	push rax		;preserve x_rel_to_player (EAX)
	call y_within
	cmp eax,1
	pop rax
	je .is_directly_right	;obj is directly to the right of the player. skip 'ahead'
	
	;; print 'ahead Xm'
	printchar 44				;comma
	printspc
	printsl DIR_STR(ahead)
	printspc
	GET_WORLD_OBJ_PROP_DW y_rel_to_player 	;return value in EAX.
	printint eax
	printsl DESC_STR(meters)
	printspc

	.is_directly_right:
	
	jmp .done_printing_pos
	;; -------------------------
	;; ahead to the left (north)
	.north_ahead_left:
	;; --------------------------
	;; ahead to the right (north)
	.north_ahead_right:
	
	.south:


	.done_printing_pos:
	pop rdi
	pop rax
	ret

	;; ////////////////////////////////////////
	;; Player object collision:
	;; - Detect collision between player and any object during player movement.
	;; ----------------------------------------
	;; In:          
	;; Returns:     RAX: 1 on collision otherwise 0
	;; Modifies:    
	;; Calls:       
	;; Example:     call player_collision

player_collision:



	ret
	
test_push:
	pop r9
	
	pop rax
	pop rbx
	pop rcx

	cmp rax,byte 1
	jne .fail
	cmp rbx,byte 2
	jne .fail
	cmp rcx,byte 3
	jne .fail
	mov rax,1

	push r9
	ret
	.fail:
	mov rax,0
	push r9
	ret
	
stack_test:
	prologb 16
	
	prints [rsp],14
	add rsp,8
	prints [rsp],14
	add rsp,8
	prints [rsp],14
	
	epilog
	ret

	;; ////////////////////////////////////////
	;; Build World function
	;; TODO: load data from file
	;; use 'iso-latin-1-unix' (C-x C-m f) coding for world file.
	;; also use (C-h v 'buffer-file-coding-system') to view encoding.
build_world:
	LOAD_FILE screen1

	LOAD_FILE story.chapter1
	SET_READ_BUF story.chapter1
	
	BUILD_WORLD_INIT rdi
	
	READ_NEXT _dword
	BUILD_WORLD_OBJ rdi,pos_x,dword eax 	;set obj pos_x

	READ_NEXT _dword
	BUILD_WORLD_OBJ rdi,pos_y,dword eax 	;set obj pos_y

	READ_NEXT _dword
	BUILD_WORLD_OBJ rdi,width,dword eax 	;set obj width

	READ_NEXT _dword
	BUILD_WORLD_OBJ rdi,depth,dword eax 	;set obj depth

	READ_NEXT _dword
	BUILD_WORLD_OBJ rdi,height,dword eax 	;set obj height

	READ_NEXT _dword
	BUILD_WORLD_OBJ rdi,weight,dword eax 	;set obj weight

	READ_NEXT _byte
	.debug_0:
	cmp al,15		;is object a boulder (15)...
	jne .text_not_boulder
	BUILD_WORLD_OBJ_TEXT rdi,obj_strings.boulder_short
	.text_not_boulder:
	cmp al,20		;is object a bush (20)...
	jne .text_not_bush
	BUILD_WORLD_OBJ_TEXT rdi,obj_strings.bush_short
	.text_not_bush:

	READ_TEXT obj_strings.boulder_short
	END_READ
	
	;BUILD_WORLD_OBJ_POS rdi,5,5
	;BUILD_WORLD_OBJ_SIZE rdi,2,1,8,900
	;BUILD_WORLD_OBJ_TEXT rdi,obj_strings.boulder_short
	BUILD_WORLD_OBJ_PARENT rdi,0

	.debug_1:
	;; create a trigger that activates when 'open' is typed in
	SET_WORLD_OBJ_TRIG_QW trigger_str,obj_trigger_strings.open
	
	INC_WORLD_OBJ_INDEX rdi

	SET_OBJ_FOR_PLAYER_INTERACTION
	
	BUILD_WORLD_OBJ_POS rdi,1,3
	BUILD_WORLD_OBJ_SIZE rdi,2,2,4,900
	BUILD_WORLD_OBJ_TEXT rdi,obj_strings.bush_short
	BUILD_WORLD_OBJ_PARENT rdi,0
	
	;; create a trigger that activates when 'cut' is typed in
	SET_WORLD_OBJ_TRIG_QW trigger_str,obj_trigger_strings.cut
	
	INC_WORLD_OBJ_INDEX rdi

	BUILD_WORLD_OBJ_POS rdi,8,8
	.debug_2:
	BUILD_WORLD_OBJ_SIZE rdi,3,1,4,900
	BUILD_WORLD_OBJ_TEXT rdi,obj_strings.boulder_short
	BUILD_WORLD_OBJ_PARENT rdi,0

	BUILD_WORLD_PLAYER_POS 6,2
	
	ret
	
	;; ////////////////////////////////////////
	;; RDI: filter direction
	;;      1: North
	;;      2: East
	;;      3: South
	;;      4: West
	;;
	;; RAX: return 1 if visible, 0 if not.
filter_obj_by_dir:
	;xor rax,rax
	GET_PLAYER_PROP look_dir,byte
	SET_WORLD_OBJ_PROP visible_to_player,SWO.nvis
	
	cmp rax,dir.north
	je .north

	cmp rax,dir.south
	je .south

	cmp rax,dir.east
	je .east

	cmp rax,dir.west
	je .west

	SET_WORLD_OBJ_PROP visible_to_player,SWO.nvis
	ret
	
	.north:
	;; get player and obj y-positions into registers
	;;   edi and esi
	GET_PLAYER_PROP pos_y,dword
	xor rdi,rdi
	mov rdi,rax
	GET_WORLD_OBJ_PROP_DW pos_y	;returns value in eax. 
	; mov esi, dword [obj_array+OSO(pos_y)]

	;; North
	;; filter out objects that are not visible to the north (>) of player.
	;; compare if edi (player.y) is less than or equal to esi (obj.y)
	cmp edi,eax
	jle .is_visible

	ret

	.south:
	;; need to add obj depth to obj pos_y
	;; to see if the objs southern edge is visible
	;; even if the northern edge is behind the player.
	GET_PLAYER_PROP pos_y,dword 	;get player pos_y and store in RDI
	xor rdi,rdi
	mov rdi,rax
	GET_WORLD_OBJ_PROP_DW pos_y	;get obj pos_y and store in RCX
	xor rcx,rcx
	mov rcx,rax
	GET_WORLD_OBJ_PROP_DW depth	;get obj depth (RAX) and ADD to obj pos_y (RCX).
	add rax,rcx			;RAX = obj pos_y + depth
	
	cmp edi,eax
	jge .is_visible

	ret

	.east:
	;; need to add obj width to obj pos_x
	;; to see if the objs eastern edge is visible
	;; even if the western edge is behind the player.
	GET_PLAYER_PROP pos_x,dword 	;get player pos_x and store in RDI
	xor rdi,rdi
	mov rdi,rax
	GET_WORLD_OBJ_PROP_DW pos_x	;get obj pos_x and store in RCX
	xor rcx,rcx
	mov rcx,rax
	GET_WORLD_OBJ_PROP_DW width	;get obj width (RAX) and ADD to obj pos_x (RCX).
	add rax,rcx			;RAX = obj pos_x + width

	cmp edi,eax
	jge .is_visible

	ret

	.west:

	GET_PLAYER_PROP pos_x,dword
	xor rdi,rdi
	mov rdi,rax
	GET_WORLD_OBJ_PROP_DW pos_x	;returns value in eax. 

	cmp edi,eax
	jle .is_visible

	ret

	.is_visible:
	;xor rax,rax
	;mov rax,1
	SET_WORLD_OBJ_PROP visible_to_player,SWO.vis
	ret

	;; ////////////////////////////////////////
	;; Move player with direction and distance
	;; ----------------------------------------
	;; RDI: direction
	;; RSI: distance in decimeters (dm) 17dm = 1.7m
	;; ////////////////////////////////////////
player_move:
	push rax		;preserve RAX
	xor rax,rax

	cmp dil,dir.north
	je .north

	cmp dil,dir.south
	je .south

	cmp dil,dir.east
	je .east

	cmp dil,dir.west
	je .west

	ret
	
	.north:
	;mov ax,word [player_struct.pos_y] ;get player y position
	GET_PLAYER_PROP pos_y,dword
	add eax,esi
	SET_PLAYER_PROP pos_y,dword,eax
	;mov [player_struct.pos_y],ax
	pop rax			;restore RAX
	jmp .ret
	ret

	.south:
	GET_PLAYER_PROP pos_y,dword
	sub eax,esi
	SET_PLAYER_PROP pos_y,dword,eax
	pop rax			;restore RAX
	jmp .ret
	ret

	.east:
	GET_PLAYER_PROP pos_x,dword
	add eax,esi
	SET_PLAYER_PROP pos_x,dword,eax
	pop rax			;restore RAX
	jmp .ret
	ret

	.west:
	GET_PLAYER_PROP pos_x,dword
	sub eax,esi
	SET_PLAYER_PROP pos_x,dword,eax
	pop rax			;restore RAX
	jmp .ret
	ret

	.ret:
	;; do other stuff if needed before return.
	ret
	;; ////////////////////////////////////////
	;; Translate object:
	;; Translate object relative to player position
	;; to calculate distance from player.
	;; ----------------------------------------
	;; Updated:     11/30/2019
	;; In:          None
	;; Returns:     x1-x2 in EAX, y1-y2 in ECX
	;; Modifies:    EAX,ECX
	;; Calls:       None
	;; Example:     call translate_to_player
obj_to_player_origin:	
	;; /////////////////////////////////
	;; calculate x1-x2, y1-y2 to get object relative to player position.
	xor rax,rax
	xor rcx,rcx
	
	;; ///////////////////////////////////////////////////
	;; X
	;; use obj pos_x if player pos_x < obj pos_x + width
	;; otherwise use obj pos_x + width
	;; ///////////////////////////////////////////////////

	;; get obj pos_x and mov to EDX
	;; get obj width and add obj pos_x (EDX) to it (EAX)
	GET_WORLD_OBJ_PROP_DW pos_x	;returns value in EAX. macro defined in world.asm
	xor rdx,rdx
	mov edx,eax			;pos_x now in EDX
	GET_WORLD_OBJ_PROP_DW width	;get obj width in EAX
	add eax,edx			;EAX now contains obj pos_x + width
	mov ecx,[player_struct.pos_x] 	;get player pos_x in ECX

	cmp ecx,eax			;compare player pos_x (ECX) with obj pos_x + width (EAX)
	;; if player pos_x (ECX) is less than the right side (pos_x + width) of object (EAX) then 
	;; calculate x_offset based on pos_x.
	jl .calc_x_width_offset		
	;; if player pos_x is greater than right side of object then 
	;; calculate x_offset based on pos_x + width.
	sub eax,ecx			;subtract EAX (obj pos_x + width) from ECX (player pos_x)
	push rax			;push x_rel_ to stack
	jmp .x_offset_done
	
	.calc_x_width_offset:
	sub ecx,edx			;subtract EDX (obj pos_x) from ECX (player pos_x)
	push rcx			;push x_rel_ to stack

	.x_offset_done:

	;; ///////////////////////////////////////////////////
	;; Y
	;; use obj pos_y if player pos_y < obj pos_y + depth
	;; otherwise use obj pos_y + depth
	;; ///////////////////////////////////////////////////
	
	GET_WORLD_OBJ_PROP_DW depth	;get obj depth in EAX
	xor rcx,rcx
	mov ecx,eax			;depth now in ECX
	GET_WORLD_OBJ_PROP_DW pos_y	;returns value in EAX.
	xor rdx,rdx
	mov edx,eax	      		;obj pos_y now in EDX
	sub eax,ecx			;EAX now contains obj pos_y - depth
	;; clear RCX and mov player pos_y to ECX
	xor rcx,rcx
	mov ecx,[player_struct.pos_y]

	;; if player pos_y (ECX) is less than or equal to obj pos_y - depth (EAX)
	;; then use obj pos_y - depth (EAX) for offset calculation
	cmp ecx,eax
	jle .calc_y_depth_offset
	sub ecx,edx			;subtract obj pos_y from player pos_y
	xor rax,rax
	mov eax,ecx			;mov y_rel to EAX
	jmp .y_offset_done
	
	.calc_y_depth_offset:
	sub eax,ecx

	.y_offset_done:

	pop rcx				;pop x_rel_
	
	SET_WORLD_OBJ_PROP x_rel_to_player, dword ecx
	SET_WORLD_OBJ_PROP y_rel_to_player, dword eax

	ret

	;; ////////////////////////////////////////
	;; Read File:
	;; - Read a file.
	;; ----------------------------------------
	;; In:          RAX: file name label, RDI: buffer
	;; Returns:     
	;; Modifies:    RAX
	;; Calls:       
	;; Example:     
read_file:
	push rdi
	push rsi
	push rdx
	push rcx

	;; preserve RDI, RSI since they are also inputs
	push rdi
	;; in RAX
	mov rdi,rax 			;file name location

	xor rax,rax
	mov rax,2			;sys_open (2)
	xor rsi,rsi			;flags (0)
	xor rdx,rdx			;mode (0)
	syscall				;returns file descriptor in RAX

	xor rcx,rcx
	mov rcx,rax			;mov file descriptor to RCX

	xor rax,rax			;sys_read (0)
	xor rdi,rdi
	mov rdi,rcx			;file descriptor from sys_open

	;; pop input RDI to RSI, buffer location
	pop rsi				;destination buffer location
	;; pop input RSI to RDX, buffer len
	mov rdx,READ_FILE_LEN		;default to read 2000 bytes
	syscall

	xor rax,rax
	mov rax,3			;sys_close (3)
	xor rdi,rdi
	mov rdi,rcx			;file descriptor
	syscall
	
	pop rcx
	pop rdx
	pop rsi
	pop rdi
	ret
