`timescale 1ns / 1ps
/*
A Verilog implementation of the basic computer described in the book "Computer System Architecture - Morris Mano" (Chapter 5)

This code is a behavioural description of the hardware rather than a dataflow (RTL) description, the technique
for implementing the behavioural model of a simple processor was borrowed from the book "Verilog Digital System Design - Zainalabedin Navabi" (Chapter 10)

written by Farhad Modaresi
*/

// [dev] remove memory init and do another .sv file for the combinec computer
module basic_computer(clk); // [Dev] halted, ready, grant
	
	// mem_* signals are connected to memory
	
	// I/O
	input clk;
	reg [15:0] mem_write_bus;
	reg [15:0] mem_read_bus;
	reg [11:0] mem_address;
	reg mem_read, mem_write;
	
	// next_* are for values that will be loaded into the register at the next posedge clk
	
	// Behavioural register declerations
	reg [2:0] sc, next_sc;	// state regarding T0, T1, ... (sequence counter)
	reg [15:0] ac, next_ac, dr, next_dr, ir, next_ir, tr, next_tr; // 16bit registers
	reg [11:0] ar, next_ar, pc, next_pc; // 12 bit registers
	reg [7:0] inpr, next_inpr, outr, next_outr, decode_ir, next_decode_ir; // 8 bit registers
	reg i, next_i, s, next_s, e, next_e, r, next_r, ien, next_ien, fgi, next_fgi, fgo, next_fgo; // single bit registers
	
	// connect the memory 
	//memory mem1 (mem_read_bus, mem_write_bus, mem_read, mem_write, mem_address, clk);
	// new integrated memory
	reg [15:0] mem_array [255:0];	// 256 x 16 memory array
	
	initial begin							
		// $readmemh("memory_data.txt",mem_array,0,255);	// load memory from file
		mem_array[0] = 16'h2003; // 00 lda 003
		mem_array[1] = 16'h1003; // 01 add 003
		mem_array[2] = 16'h3004; // 10 sta 004
		mem_array[3] = 16'h0001; // 11 DATA 0001
	end
	
	always @(mem_write or mem_read) begin
		if (mem_write) begin
			#1 mem_array[mem_address] <= mem_write_bus;	// write to memory from the bus
		end else if (mem_read) begin
			mem_read_bus <= mem_array[mem_address];	// load memory into the bus
		end
	end
	
	// Register clocking
	// load registers at posedge clk
	always @(posedge clk) begin
		ac <= next_ac;
		dr <= next_dr;
		ir <= next_ir;
		tr <= next_tr;
		ar <= next_ar;
		pc <= next_pc;
		inpr <= next_inpr;
		outr <= next_outr;
		i <= next_i;
		s <= next_s;
		e <= next_e;
		r <= next_r;
		ien <= next_ien;
		fgi <= next_fgi;
		fgo <= next_fgo;
		decode_ir <= next_decode_ir;
	end
	
	// sequence counter (in a seperate block for readability)
	always @(posedge clk) begin
		if (next_sc == 3'b000)
			sc <= next_sc;
		else
			sc <= sc + 1;
	end
	
	//initializing signals
	initial begin
		sc <= 3'b000;
		next_sc <= 3'b000;
		r <= 1'b0;
		next_r <= 1'b0;
		ien <= 1'b0;
		next_ien <= 1'b0;
		pc <= 0;
		next_pc <= 0;
	end
	
	// main processor description based on the sequence counter state
	always @(sc) begin
	
		//initializers to move the contents of registers through register clocking and reset the signals for each clock
		//count the sequence
		next_sc <= sc + 1;
		//set the contents of next_* signals so they wouldn't erase the registers in register clocking
		next_ac <= ac;
		next_dr <= dr;
		next_ir <= ir;
		next_tr <= tr;
		next_ar <= ar;
		next_pc <= pc;
		next_inpr <= inpr;
		next_outr <= outr;
		next_i <= i;
		next_s <= s;
		next_e <= e;
		next_r <= r;
		next_ien <= ien;
		next_fgi <= fgi;
		next_fgo <= fgo;
		next_decode_ir <= decode_ir;
		// reset the signals
		mem_write_bus <= 16'bZZZZZZZZZZZZZZZZ;
		mem_read_bus <= 16'bZZZZZZZZZZZZZZZZ;
		mem_address <= 12'bZZZZZZZZZZZZ;
		mem_read <= 1'b0;
		mem_write <= 1'b0;
		
		//Sequence counter state description
		case (sc)
			// all the recieving registers should be of next_* type
			// all the possible paths should end with next_sc <= 3'b000;
			0: begin //T0
				if (r) begin // interrupt cycle
					next_tr <= pc;
					next_ar <= 12'b000000000000;
				end else if (!r) begin // instruction cycle
					next_ar <= pc;
				end
			end
			
			1: begin //T1
				if (r) begin // interrupt cycle
					next_pc <= 12'b000000000000;
					//M[AR] < TR
					mem_write <= 1'b1;
					mem_address <= ar;
					mem_write_bus <= tr;			
				end else if (!r) begin // instruction cycle
					next_pc <= pc + 1;
					//IR < M[AR]
					mem_read <= 1'b1;
					mem_address <= ar;
					#1 next_ir <= mem_read_bus;	
				end
			end
			
			2: begin //T2
				if (r) begin // interrupt cycle
					next_ien <= 1'b0;
					next_pc <= pc +1;
					next_sc <= 3'b000;
					next_r <= 1'b0;
				end else if (!r) begin // instruction cycle
					next_i <= ir[15];
					next_ar <= ir[11:0];
					next_decode_ir <= ir[14:12];
				end
			end
			
			3: begin //T3
				if (decode_ir == 7) begin // Register or I/O operation
					if (i == 0) begin // Register operation
						next_sc <= 0;
						case (ir)
						
							16'h7800: begin // CLA
								next_ac <= 0;
							end
							
							16'h7400: begin // CLE
								next_e <= 0;
							end
							
							16'h7200: begin // CM
								next_ac <= ~ac;
							end
							
							16'h7100: begin // CME
								next_e <= ~e;
							end
							
							16'h7080: begin // CIR
								next_sc <= 0;
							end
							
							16'h7040: begin // CIL
								next_sc <= 0;
							end
							
							16'h7020: begin // INC
								next_ac <= ac + 1;
							end
							
							16'h7010: begin // SPA
								if (ac[15] == 0) 
									next_pc <= pc + 1;
							end
							
							16'h7008: begin // SNA
								if (ac[15] == 1) 
									next_pc <= pc + 1;
							end
							
							16'h7004: begin // SZA
								if (ac == 0) 
									next_pc <= pc + 1;
							end
							
							16'h7002: begin // AZE
								if (e == 0) 
									next_pc <= pc + 1;
							end
							
							16'h7001: begin // HLT
								next_s <= 0;
							end
						endcase
					end else if (i != 0) begin // I/O operation
						next_sc <= 0;
						case (ir)
						
							16'hF800: begin // INP
								next_ac[7:0] <= inpr;
								next_fgi <= 0;
							end
							
							16'hF400: begin // OUT
								next_outr <= ac[7:0];
								next_fgo <= 0;
							end
							
							16'hF200: begin // SKI
								if (fgi) 
									next_pc <= pc + 1;
							end
							
							16'hF100: begin // SKO
								if (fgo) 
									next_pc <= pc + 1;
							end
							
							16'hF080: begin // ION
								next_ien <= 1;
							end
							
							16'hF040: begin // IOF
								next_ien <= 0;
							end
						endcase
					end
				end else if (decode_ir != 7) begin // Memory reference
					if (i != 0) begin // Indirect
						//AR < M[AR]
						mem_read <= 1'b1;
						mem_address <= ar;
						#1 next_ar <= mem_read_bus;
					end
					// remember if i==0 we don't have to do anything at T3
				end
			end
			
			4: begin //T4
			
				case (decode_ir)
					0: begin // AND
						//DR < M[AR]
						mem_read <= 1'b1;
						mem_address <= ar;
						#1 next_dr <= mem_read_bus;
					end
					
					1: begin // ADD
						//DR < M[AR]
						mem_read <= 1'b1;
						mem_address <= ar;
						#1 next_dr <= mem_read_bus;
					end
					
					2: begin // LDA
						//DR < M[AR]
						mem_read <= 1'b1;
						mem_address <= ar;
						#1 next_dr <= mem_read_bus;
					end
					
					3: begin // STA
						next_sc <= 0;
						//M[AR] < AC
						mem_write <= 1'b1;
						mem_address <= ar;
						mem_write_bus <= ac;
					end
					
					4: begin // BUN
						next_pc <= ar;
						next_sc <= 0;
					end
					
					5: begin // BSA
						next_ar <= ar + 1;
						//M[AR] < PC
						mem_write <= 1'b1;
						mem_address <= ar;
						mem_write_bus <= pc;
					end
					
					6: begin // ISZ
						//DR < M[AR]
						mem_read <= 1'b1;
						mem_address <= ar;
						#1 next_dr <= mem_read_bus;
					end					
				endcase
			end
			
			5: begin //T5
			
				case (decode_ir)
					0: begin // AND
						next_ac <= ac & dr;
						next_sc <= 0;
					end
					
					1: begin // ADD
						next_ac <= ac + dr;
						next_e <= ac % dr;
						next_sc <= 0;
					end
					
					2: begin // LDA
						next_ac <= dr;
						next_sc <= 0;
					end
					
					5: begin // BSA
						next_pc <= ar;
						next_sc <= 0;
					end
					
					6: begin // ISZ
						next_dr <= dr + 1;
					end					
				endcase
			end
			
			6: begin //T6
			
				if (decode_ir == 6) begin // ISZ
						next_sc <= 0;
						if (dr == 0) 
							next_pc <= pc + 1;
						//M[AR] < DR
						mem_write <= 1'b1;
						mem_address <= ar;
						mem_write_bus <= dr;
				end					
			end
		endcase
	end

endmodule

module basic_computer_test();
	logic clk;
	basic_computer u1 (clk);
	// Simulation
	always begin
			 #5 clk = 1;
			 #5 clk = 0;
	end
endmodule
