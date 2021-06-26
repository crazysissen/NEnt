using System;
using System.Diagnostics;

namespace NEnt
{
	class Cpu6502
	{
		public struct StatusFlag : uint8
		{
			public const StatusFlag C = (.)0x01; // Carry
			public const StatusFlag Z = (.)0x02; // Zero
			public const StatusFlag I = (.)0x04; // Disable interrupts
			public const StatusFlag D = (.)0x08; // Decimal mode - CURRENTLY NOT IMPLEMENTED
			public const StatusFlag B = (.)0x10; // Break
			public const StatusFlag U = (.)0x20; // - Unused
			public const StatusFlag V = (.)0x40; // Overflow
			public const StatusFlag N = (.)0x80; // Negative
		}

		public enum AddressingMode : uint8
		{
			IMP, IMM, ZP0, ZPX, ZPY, REL,
			ABS, ABX, ABY, IND, IZX, IZY
		}

		public struct Instruction
		{
			public this(String name, delegate uint8() operation, AddressingMode addrMode, uint8 cycles)
			{
				this.name = name;
				this.operation = operation;
				this.addrMode = addrMode;
				this.cycles = cycles;
			}

			public String name;
			public delegate uint8() operation;
			public AddressingMode addrMode;
			public uint8 cycles;
		}



		private EmuNES m_bus;

		// CPU Registers
		private uint8 m_x				= 0x00; // X register
		private uint8 m_y				= 0x00; // Y register
		private uint8 m_a				= 0x00; // Accumulator register
		private uint8 m_stackPtr		= 0x00; // Stack pointer
		private uint16 m_progCounter  = 0x0000; // Program counter
		private uint16 m_temp		  = 0x0000;
		private StatusFlag m_status 	= 0x00; // Status register

		// Internal helper values
		private uint8 m_fetched = 0x00;
		private uint8 m_cycles = 0x00;
		private uint8 m_opcode = 0x00;
		private uint16 m_addrAbs = 0x0000;
		private uint16 m_addrRel = 0x0000;
		private uint32 m_clockCount = 0x00000000;

		private Instruction[] m_lookup;
		private delegate uint8()[] m_addrLookup;


		// Constr/destr

		public this()
		{
			m_bus = null;

			FillLookup();
		}

		public ~this()
		{
			for (int i = 0; i <= 0xFF; ++i)
			{
				delete m_lookup[i].operation;
			}

			for (int i = 0; i < 0x0C; ++i) // 0x0C (12) is the number of addressing modes on the 6502
			{
				delete m_addrLookup[i];
			}

			delete m_lookup;
			delete m_addrLookup;
		}



		// Public functions

		public void Connect(EmuNES bus)
		{
			m_bus = bus;
		}

		public void Clock()
		{
			if (m_cycles == 0)
			{
				m_opcode = Read(m_progCounter);
				m_progCounter++;
	
				Instruction instr = m_lookup[m_opcode];
	
				m_cycles = instr.cycles;
	
				uint8 extraCycle = 0x01;
	
				extraCycle &= m_addrLookup[(uint8)instr.addrMode]();
				extraCycle &= instr.operation();
	
				m_cycles += extraCycle;
			}

			m_clockCount++;
			m_cycles--;
		}

		public void Reset()
		{
			// Hard-wired on the chip

			m_addrAbs = 0xFFFC;
			uint16 low = Read(m_addrAbs);
			uint16 high = Read(m_addrAbs + 1);

			m_progCounter = (high << 8) | low;

			m_a = 0;
			m_x = 0;
			m_y = 0;
			m_stackPtr = 0xFD;
			m_status = .U;

			m_addrAbs = 0x0000;
			m_addrRel = 0x0000;
			m_fetched = 0x00;

			m_cycles = 8;
		}

		public void InterruptReq()
		{
			// Do not interrupt if the disable interrupts flag is set
			if (GetFlag(.I) != 0)
			{
				return;
			}

			// Write the program counter to the stack
			Write(0x0100 + m_stackPtr, (uint8)((m_progCounter >> 8) & 0x00FF));
			m_stackPtr--;
			Write(0x0100 + m_stackPtr, (uint8)(m_progCounter & 0x00FF));
			m_stackPtr--;

			// Set status register and push to the stack
			SetFlag(.B, false);
			SetFlag(.U, true);
			SetFlag(.I, true);
			Write(0x0100 + m_stackPtr, (uint8)m_status);
			m_stackPtr--;

			// Read new program counter from fixed address
			m_addrAbs = 0xFFFE;
			uint16 low = Read(m_addrAbs);
			uint16 high = Read(m_addrAbs + 1);
			m_progCounter = (high << 8) | low;

			// Set cycles
			m_cycles = 7;
		}

		public void InterrupReqNM()
		{
			// Write the program counter to the stack
			Write(0x0100 + m_stackPtr, (uint8)((m_progCounter >> 8) & 0x00FF));
			m_stackPtr--;
			Write(0x0100 + m_stackPtr, (uint8)(m_progCounter & 0x00FF));
			m_stackPtr--;

			// Set status register and push to the stack
			SetFlag(.B, false);
			SetFlag(.U, true);
			SetFlag(.I, true);
			Write(0x0100 + m_stackPtr, (uint8)m_status);
			m_stackPtr--;

			// Read new program counter from fixed address
			m_addrAbs = 0xFFFA;
			uint16 low = Read(m_addrAbs);
			uint16 high = Read(m_addrAbs + 1);
			m_progCounter = (high << 8) | low;

			// Set cycles
			m_cycles = 8;
		}

		public uint8 Fetch()
		{
			if (m_lookup[m_opcode].addrMode != .IMP)
			{
				m_fetched = Read(m_addrAbs);
			}

			return m_fetched;
		}



		// Private functions

		private uint8 Read(uint16 address)
		{
			return m_bus.Read(address, false);
		}

		private void Write(uint16 address, uint8 data)
		{
			m_bus.Write(address, data);
		}

		private uint8 GetFlag(StatusFlag flag)
		{
			return ((m_status & flag) > 0x00) ? 0x01 : 0x00;
		}

		private void SetFlag(StatusFlag flag, bool condition)
		{
			if (condition)
			{
				m_status |= flag;
			}
			else
			{
				m_status &= ~flag;
			}
		}


		// ----------------------------------------------------- Addressing modes

		public uint8 IMP()
		{
		 	m_fetched = m_a;
			return 0x00;
		}
		public uint8 IMM()
		{
			m_addrAbs = m_progCounter++;
			return 0x00;
		}
		public uint8 ZP0()
		{
			m_addrAbs = Read(m_progCounter);
			m_progCounter++;
			m_addrAbs &= 0x00FF;
			return 0x00;
		}
		public uint8 ZPX()
		{
			m_addrAbs = Read(m_progCounter) + m_x;
			m_progCounter++;
			m_addrAbs &= 0x00FF;
			return 0x00;
		}
		public uint8 ZPY()
		{
			m_addrAbs = Read(m_progCounter) + m_y;
			m_progCounter++;
			m_addrAbs &= 0x00FF;
			return 0x00;
		}
		public uint8 REL()
		{
			m_addrRel = Read(m_progCounter);
			m_progCounter++;

			if (m_addrRel & 0x80 != 0)
			{
				m_addrRel |= 0xFF00;
			}

			return 0;
		}
		public uint8 ABS() 
		{
			uint16 low = Read(m_progCounter);
			m_progCounter++;

			uint16 high = Read(m_progCounter);
			m_progCounter++;

			m_addrAbs = (high << 8) | low;

			return 0x00;
		}
		public uint8 ABX()
		{
			uint16 low = Read(m_progCounter);
			m_progCounter++;

			uint16 high = Read(m_progCounter);
			m_progCounter++;

			m_addrAbs = ((high << 8) | low) + m_x;

			return ((m_addrAbs & 0xFF00) != (high << 8)) ? 0x01 : 0x00; // Return 1 if address changes page index
		}
		public uint8 ABY() 
		{
			uint16 low = Read(m_progCounter);
			m_progCounter++;

			uint16 high = Read(m_progCounter);
			m_progCounter++;

			m_addrAbs = ((high << 8) | low) + m_y;

			return ((m_addrAbs & 0xFF00) != (high << 8)) ? 0x01 : 0x00; // Return 1 if address changes page index
		}
		public uint8 IND()
		{
			uint16 lowPtr = Read(m_progCounter);
			m_progCounter++;

			uint16 highPtr = Read(m_progCounter);
			m_progCounter++;

			uint16 ptr = (highPtr << 8) | lowPtr;

			// Bug
			if (lowPtr == 0x00FF)
			{
				m_addrAbs = ((uint16)Read(ptr & 0xFF00) << 8) | (uint16)Read(ptr);
			}
			// Normal Behavior
			else
			{
				m_addrAbs = ((uint16)Read(ptr + 1) << 8) | (uint16)Read(ptr);
			}

			return 0x00;
		}
		public uint8 IZX()
		{
			uint16 t = Read(m_progCounter);

			uint16 low = Read(t & 0x00FF);
			uint16 high = Read((t + 1) & 0x00FF);

			m_addrAbs = ((high << 8) | low) + m_y;

			return 0x00;
		}
		public uint8 IZY()
		{
			uint16 t = Read(m_progCounter);

			uint16 low = Read((t + (uint16)m_x) & 0x00FF);
			uint16 high = Read((t + (uint16)m_x + 1) & 0x00FF);

			m_addrAbs = (high << 8) | low;

			return ((m_addrAbs & 0xFF00) != (high << 8)) ? 0x01 : 0x00;
		}



		//  ----------------------------------------------------- Opcodes/CPU operations

		public uint8 ADC()
		{
			Fetch();

			m_temp = (uint16)m_a + (uint16)m_fetched + (uint16)GetFlag(.C);

			SetFlag(.C, m_temp > 255);
			SetFlag(.Z, (m_temp & 0x00FF) == 0);
			SetFlag(.V, (~((uint16)m_a ^ (uint16)m_fetched) & ((uint16)m_a ^ (uint16)m_temp)) & 0x0080 != 0);
			SetFlag(.N, m_temp & 0x80 != 0);

			m_a = (uint8)(m_temp & 0x00FF);

			return 0x01;
		}
		public uint8 AND()
		{
			Fetch();
			m_a &= m_fetched;

			SetFlag(.Z, m_a == 0x00);
			SetFlag(.N, m_a & 0x80 != 0);

			return 0x01;
		}
		public uint8 ASL()
		{
			Fetch();

			m_temp = (uint16)m_fetched << 1;

			SetFlag(.C, (m_temp & 0xFF00) > 0x00);
			SetFlag(.Z, (m_temp % 0x00FF) == 0x00);
			SetFlag(.N, m_temp & 0x00 != 0);

			if(m_lookup[m_opcode].addrMode == .IMP)
			{
				m_a = (uint8)(m_temp & 0x00FF);
			}
			else
			{
				Write(m_addrAbs, (uint8)(m_temp & 0x00FF));
			}

			return 0;
		}
		public uint8 BCC() 
		{
			if (GetFlag(.C) == 0)
			{
				m_cycles++;
				m_addrAbs = m_progCounter + m_addrRel;

				if ((m_addrAbs & 0xFF00) != (m_progCounter & 0xFF00))
				{
					m_cycles++;
				}

				m_progCounter = m_addrAbs;
			}

			return 0x00;
		}
		public uint8 BCS()
		{
			if (GetFlag(.C) == 1)
			{
				m_cycles++;
				m_addrAbs = m_progCounter + m_addrRel;

				if ((m_addrAbs & 0xFF00) != (m_progCounter & 0xFF00))
				{
					m_cycles++;
				}

				m_progCounter = m_addrAbs;
			}

			return 0x00;
		}
		public uint8 BEQ() 
		{
			if (GetFlag(.Z) == 1)
			{
				m_cycles++;
				m_addrAbs = m_progCounter + m_addrRel;

				if ((m_addrAbs & 0xFF00) != (m_progCounter & 0xFF00))
				{
					m_cycles++;
				}

				m_progCounter = m_addrAbs;
			}

			return 0x00;
		}
		public uint8 BIT()
		{
			Fetch();

			m_temp = m_a & m_fetched;

			SetFlag(.Z, (m_temp & 0x00FF) == 0x0000);
			SetFlag(.N, m_fetched & (0x01 << 7) != 0);
			SetFlag(.V, m_fetched & (0x01 << 6) != 0);

			return 0x00;
		}
		public uint8 BMI()
		{
			if (GetFlag(.N) == 1)
			{
				m_cycles++;
				m_addrAbs = m_progCounter + m_addrRel;

				if ((m_addrAbs & 0xFF00) != (m_progCounter & 0xFF00))
				{
					m_cycles++;
				}

				m_progCounter = m_addrAbs;
			}

			return 0x00;
		}


		// ------------


		public uint8 BNE()
		{
			if (GetFlag(.Z) == 0)
			{
				m_cycles++;
				m_addrAbs = m_progCounter + m_addrRel;

				if ((m_addrAbs & 0xFF00) != (m_progCounter & 0xFF00))
				{
					m_cycles++;
				}

				m_progCounter = m_addrAbs;
			}

			return 0x00;
		}
		public uint8 BPL()
		{
			if (GetFlag(.N) == 0)
			{
				m_cycles++;
				m_addrAbs = m_progCounter + m_addrRel;

				if ((m_addrAbs & 0xFF00) != (m_progCounter & 0xFF00))
				{
					m_cycles++;
				}

				m_progCounter = m_addrAbs;
			}

			return 0x00;
		}
		public uint8 BRK()
		{
			m_progCounter++;

			SetFlag(.I, true);

			Write(0x0100 + m_stackPtr, (uint8)((m_progCounter >> 8) & 0x00FF));
			m_stackPtr--;
			Write(0x0100 + m_stackPtr, (uint8)(m_progCounter & 0x00FF));
			m_stackPtr--;

			SetFlag(.B, true);

			Write(0x0100 + m_stackPtr, (uint8)m_status);
			m_stackPtr--;

			SetFlag(.B, false);

			m_progCounter = (uint16)Read(0xFFFE) | ((uint16)Read(0xFFFF) << 8);

			return 0x00;
		}
		public uint8 BVC()
		{
			if (GetFlag(.V) == 0)
			{
				m_cycles++;
				m_addrAbs = m_progCounter + m_addrRel;

				if ((m_addrAbs & 0xFF00) != (m_progCounter & 0xFF00))
				{
					m_cycles++;
				}

				m_progCounter = m_addrAbs;
			}

			return 0x00;
		}
		public uint8 BVS()
		{			if (GetFlag(.V) == 1)
			{
				m_cycles++;
				m_addrAbs = m_progCounter + m_addrRel;

				if ((m_addrAbs & 0xFF00) != (m_progCounter & 0xFF00))
				{
					m_cycles++;
				}

				m_progCounter = m_addrAbs;
			}

			return 0x00;
		}
		public uint8 CLC()
		{
			SetFlag(.C, false);
			return 0x00;
		}
		public uint8 CLD() 
		{
			SetFlag(.D, false);
			return 0x00;
		}
		public uint8 CLI()
		{
			SetFlag(.I, false);
			return 0x00;
		}


		// ------------


		public uint8 CLV() 
		{
			SetFlag(.V, false);
			return 0x00;
		}
		public uint8 CMP()
		{
			Fetch();

			m_temp = (uint16)m_a - (uint16)m_fetched;

			SetFlag(.C, m_a >= m_fetched);
			SetFlag(.Z, (m_temp & 0x00FF) == 0);
			SetFlag(.N, m_temp & 0x0080 != 0);

			return 0x01;
		}
		public uint8 CPX() 
		{
			Fetch();

			m_temp = (uint16)m_x - (uint16)m_fetched;

			SetFlag(.C, m_a >= m_fetched);
			SetFlag(.Z, (m_temp & 0x00FF) == 0);
			SetFlag(.N, m_temp & 0x0080 != 0);

			return 0x00;
		}
		public uint8 CPY()
		{
			Fetch();

			m_temp = (uint16)m_y - (uint16)m_fetched;

			SetFlag(.C, m_a >= m_fetched);
			SetFlag(.Z, (m_temp & 0x00FF) == 0);
			SetFlag(.N, m_temp & 0x0080 != 0);

			return 0x00;
		}
		public uint8 DEC() 
		{
			Fetch();

			m_temp = m_fetched - 1;

			Write(m_addrAbs, (uint8)(m_temp & 0x00FF));

			SetFlag(.Z, (m_temp & 0x00FF) == 0);
			SetFlag(.N, m_temp & 0x0080 != 0);

			return 0x00;
		}
		public uint8 DEX() 
		{
			m_x--;

			SetFlag(.Z, m_x == 0);
			SetFlag(.N, m_x & 0x80 != 0);

			return 0x00;
		}
		public uint8 DEY() 
		{
			m_y--;

			SetFlag(.Z, m_y == 0);
			SetFlag(.N, m_y & 0x80 != 0);

			return 0x00;
		}
		public uint8 EOR() 
		{
			Fetch();

			m_a ^= m_fetched;

			SetFlag(.Z, m_a == 0x00);
			SetFlag(.N, m_a & 0x80 == 0);

			return 0x01;
		}


		// ------------


		public uint8 INC() 
		{
			Fetch();

			m_temp =m_fetched + 1;

			Write(m_addrAbs, (uint8)(m_temp & 0x00FF));
			SetFlag(.Z, (m_temp & 0x00FF) == 0);
			SetFlag(.N, m_temp & 0x0080 != 0);

			return 0x00;
		}
		public uint8 INX()
		{
			m_x++;

			SetFlag(.Z, m_x == 0);
			SetFlag(.N, m_x & 0x80 != 0);

			return 0x00;
		}
		public uint8 INY()
		{
			m_x++;

			SetFlag(.Z, m_x == 0);
			SetFlag(.N, m_x & 0x80 != 0);

			return 0x00;
		}
		public uint8 JMP() 
		{
			m_progCounter = m_addrAbs;

			return 0x00;
		}
		public uint8 JSR() 
		{
			m_progCounter--;

			Write(0x0100 + m_stackPtr, (uint8)((m_progCounter >> 8) & 0x00FF));
			m_stackPtr--;
			Write(0x0100 + m_stackPtr, (uint8)(m_progCounter & 0x00FF));
			m_stackPtr--;

			m_progCounter = m_addrAbs;

			return 0x00;
		}
		public uint8 LDA() 
		{
			Fetch();

			m_a = m_fetched;

			SetFlag(.Z, m_a == 0x00);
			SetFlag(.N, m_a & 0x80 != 0);

			return 1;
		}
		public uint8 LDX() 
		{
			Fetch();

			m_x = m_fetched;

			SetFlag(.Z, m_x == 0x00);
			SetFlag(.N, m_x & 0x80 != 0);

			return 1;
		}
		public uint8 LDY() 
		{
			Fetch();

			m_y = m_fetched;

			SetFlag(.Z, m_y == 0x00);
			SetFlag(.N, m_y & 0x80 != 0);

			return 1;
		}


		// ------------


		public uint8 LSR() 
		{
			Fetch();

			SetFlag(.C, m_fetched & 0x0001 != 0);

			m_temp = m_fetched >> 1;

			SetFlag(.Z, (m_temp & 0x00FF) == 0);
			SetFlag(.N, m_temp & 0x0080 != 0);

			if (m_lookup[m_opcode].addrMode == .IMP)
			{
				m_a = (uint8)(m_temp & 0x00FF);
			}
			else
			{
				Write(m_addrAbs, (uint8)(m_temp & 0x00FF));
			}

			return 0x00;
		}
		public uint8 NOP() 
		{
			switch (m_opcode)
			{
			case 0x1C:
			case 0x3C:
			case 0x5C:
			case 0x7C:
			case 0xDC:
			case 0xFC:
				return 1;
			}

			return 0;
		}	
		public uint8 ORA() 
		{
			Fetch();

			m_a |= m_fetched;

			SetFlag(.Z, m_a == 0x00);
			SetFlag(.N, m_a & 0x80 != 0);

			return 0x01;
		}
		public uint8 PHA()
		{
			Write(0x0100 + m_stackPtr, m_a);
			m_stackPtr++;

			return 0x00;
		}
		public uint8 PHP() 
		{
			Write(0x0100 + m_stackPtr, (uint8)(m_status | .B | .U));
			m_stackPtr++;
			
			SetFlag(.B, false);
			SetFlag(.U, false);

			return 0x00;
		}
		public uint8 PLA() 
		{
			m_stackPtr++;
			m_a = Read(0x0100 + m_stackPtr);

			SetFlag(.Z, m_a == 0x00);
			SetFlag(.N, m_a & 0x80 != 0);

			return 0x00;
		}
		public uint8 PLP()
		{
			m_stackPtr++;
			m_status = (StatusFlag)Read(0x0100 + m_stackPtr);

			SetFlag(.U, true);

			return 0x00;
		}
		public uint8 ROL() 
		{
			Fetch();

			m_temp = (uint16)(m_fetched << 1) | GetFlag(.C);

			SetFlag(.C, m_temp & 0xFF00 != 0);
			SetFlag(.Z, (m_temp & 0x00FF) == 0);
			SetFlag(.N, m_temp & 0x0080 != 0);

			if (m_lookup[m_opcode].addrMode == .IMP)
			{
				m_a = (uint8)(m_temp & 0x00FF);
			}
			else
			{
				Write(m_addrAbs, (uint8)(m_temp & 0x00FF));
			}

			return 0x00;
		}


		// ------------


		public uint8 ROR() 
		{
			Fetch();

			m_temp = (uint16)(GetFlag(.C) << 7) | (m_fetched >> 1);

			SetFlag(.C, m_fetched & 0x01 != 0);
			SetFlag(.Z, (m_temp & 0x00FF) == 0);
			SetFlag(.N, m_temp & 0x0080 != 0);

			if (m_lookup[m_opcode].addrMode == .IMP)
			{
				m_a = (uint8)(m_temp & 0x00FF);
			}
			else
			{
				Write(m_addrAbs, (uint8)(m_temp & 0x00FF));
			}

			return 0x00;
		}
		public uint8 RTI() 
		{
			m_stackPtr++;
			m_status = (StatusFlag)Read(0x0100 + m_stackPtr);

			SetFlag(.B, false);
			SetFlag(.U, false);

			m_stackPtr++;
			m_progCounter = (uint16)Read(0x0100 + m_stackPtr);
			m_stackPtr++;
			m_progCounter |= (uint16)Read(0x0100 + m_stackPtr) << 8;

			return 0x00;
		}
		public uint8 RTS() 
		{
			m_stackPtr++;
			m_progCounter = (uint16)Read(0x0100 + m_stackPtr);
			m_stackPtr++;
			m_progCounter |= (uint16)Read(0x0100 + m_stackPtr) << 8;

			m_progCounter++;

			return 0x00;
		}
		public uint8 SBC()
		{
			Fetch();

			uint16 val = ((uint16)m_fetched) ^ 0x00FF;

			m_temp = (uint16)m_a + val + (uint16)GetFlag(.C);

			SetFlag(.C, m_temp & 0xFF00 != 0);
			SetFlag(.Z, (m_temp & 0x00FF) == 0);
			SetFlag(.V, (m_temp ^ (uint16)m_a) & (m_temp ^ val) & 0x0080 != 0);
			SetFlag(.N, m_temp & 0x0080 != 0);

			m_a = (uint8)(m_temp & 0x00FF);

			return 0x01;
		}
		public uint8 SEC() 
		{
			SetFlag(.C, true);
			return 0x00;
		}
		public uint8 SED() 
		{
			SetFlag(.D, true);
			return 0x00;
		}
		public uint8 SEI()
		{
			SetFlag(.I, true);
			return 0x00;
		}
		public uint8 STA() 
		{
			Write(m_addrAbs, m_a);
			return 0x00;
		}


		// ------------


		public uint8 STX() 
		{
			Write(m_addrAbs, m_x);
			return 0x00;
		}
		public uint8 STY() 
		{
			Write(m_addrAbs, m_y);
			return 0x00;
		}
		public uint8 TAX() 
		{
			m_x = m_a;

			SetFlag(.Z, m_x == 0x00);
			SetFlag(.N, m_x & 0x80 != 0);

			return 0x00;
		}
		public uint8 TAY()
		{
			m_y = m_a;

			SetFlag(.Z, m_y == 0x00);
			SetFlag(.N, m_y & 0x80 != 0);

			return 0x00;
		}
		public uint8 TSX() 
		{
			m_x = m_stackPtr;

			SetFlag(.Z, m_x == 0x00);
			SetFlag(.N, m_x & 0x80 != 0);

			return 0x00;
		}
		public uint8 TXA() 
		{
			m_a = m_x;

			SetFlag(.Z, m_a == 0x00);
			SetFlag(.N, m_a & 0x80 != 0);

			return 0x00;
		}
		public uint8 TXS()
		{
			m_stackPtr = m_x;
			return 0x00;
		}
		public uint8 TYA()
		{
			m_a = m_y;

			SetFlag(.Z, m_a == 0x00);
			SetFlag(.N, m_a & 0x80 != 0);

			return 0x00;
		}

		uint8 XXX()
		{
			Debug.WriteLine("TRIED TO CALL INVALID OPCODE!");

			return 0x00;
		}



		// Holy crap

		private void FillLookup()
		{
			m_lookup = new 
			.(
				.("BRK", new => BRK, .IMM, 7),	.("ORA", new => ORA, .IZX, 6),	.("???", new => XXX, .IMP, 2),	.("???", new => XXX, .IMP, 8),	.("???", new => NOP, .IMP, 3),	.("ORA", new => ORA, .ZP0, 3),	.("ASL", new => ASL, .ZP0, 5),	.("???", new => XXX, .IMP, 5),	.("PHP", new => PHP, .IMP, 3),	.("ORA", new => ORA, .IMM, 2),	.("ASL", new => ASL, .IMP, 2),	.("???", new => XXX, .IMP, 2),	.("???", new => NOP, .IMP, 4),	.("ORA", new => ORA, .ABS, 4),	.("ASL", new => ASL, .ABS, 6),	.("???", new => XXX, .IMP, 6),
				.("BPL", new => BPL, .REL, 2),	.("ORA", new => ORA, .IZY, 5),	.("???", new => XXX, .IMP, 2),	.("???", new => XXX, .IMP, 8),	.("???", new => NOP, .IMP, 4),	.("ORA", new => ORA, .ZPX, 4),	.("ASL", new => ASL, .ZPX, 6),	.("???", new => XXX, .IMP, 6),	.("CLC", new => CLC, .IMP, 2),	.("ORA", new => ORA, .ABY, 4),	.("???", new => NOP, .IMP, 2),	.("???", new => XXX, .IMP, 7),	.("???", new => NOP, .IMP, 4),	.("ORA", new => ORA, .ABX, 4),	.("ASL", new => ASL, .ABX, 7),	.("???", new => XXX, .IMP, 7),
				.("JSR", new => JSR, .ABS, 6),	.("AND", new => AND, .IZX, 6),	.("???", new => XXX, .IMP, 2),	.("???", new => XXX, .IMP, 8),	.("BIT", new => BIT, .ZP0, 3),	.("AND", new => AND, .ZP0, 3),	.("ROL", new => ROL, .ZP0, 5),	.("???", new => XXX, .IMP, 5),	.("PLP", new => PLP, .IMP, 4),	.("AND", new => AND, .IMM, 2),	.("ROL", new => ROL, .IMP, 2),	.("???", new => XXX, .IMP, 2),	.("BIT", new => BIT, .ABS, 4),	.("AND", new => AND, .ABS, 4),	.("ROL", new => ROL, .ABS, 6),	.("???", new => XXX, .IMP, 6),
				.("BMI", new => BMI, .REL, 2),	.("AND", new => AND, .IZY, 5),	.("???", new => XXX, .IMP, 2),	.("???", new => XXX, .IMP, 8),	.("???", new => NOP, .IMP, 4),	.("AND", new => AND, .ZPX, 4),	.("ROL", new => ROL, .ZPX, 6),	.("???", new => XXX, .IMP, 6),	.("SEC", new => SEC, .IMP, 2),	.("AND", new => AND, .ABY, 4),	.("???", new => NOP, .IMP, 2),	.("???", new => XXX, .IMP, 7),	.("???", new => NOP, .IMP, 4),	.("AND", new => AND, .ABX, 4),	.("ROL", new => ROL, .ABX, 7),	.("???", new => XXX, .IMP, 7),
				.("RTI", new => RTI, .IMP, 6),	.("EOR", new => EOR, .IZX, 6),	.("???", new => XXX, .IMP, 2),	.("???", new => XXX, .IMP, 8),	.("???", new => NOP, .IMP, 3),	.("EOR", new => EOR, .ZP0, 3),	.("LSR", new => LSR, .ZP0, 5),	.("???", new => XXX, .IMP, 5),	.("PHA", new => PHA, .IMP, 3),	.("EOR", new => EOR, .IMM, 2),	.("LSR", new => LSR, .IMP, 2),	.("???", new => XXX, .IMP, 2),	.("JMP", new => JMP, .ABS, 3),	.("EOR", new => EOR, .ABS, 4),	.("LSR", new => LSR, .ABS, 6),	.("???", new => XXX, .IMP, 6),
				.("BVC", new => BVC, .REL, 2),	.("EOR", new => EOR, .IZY, 5),	.("???", new => XXX, .IMP, 2),	.("???", new => XXX, .IMP, 8),	.("???", new => NOP, .IMP, 4),	.("EOR", new => EOR, .ZPX, 4),	.("LSR", new => LSR, .ZPX, 6),	.("???", new => XXX, .IMP, 6),	.("CLI", new => CLI, .IMP, 2),	.("EOR", new => EOR, .ABY, 4),	.("???", new => NOP, .IMP, 2),	.("???", new => XXX, .IMP, 7),	.("???", new => NOP, .IMP, 4),	.("EOR", new => EOR, .ABX, 4),	.("LSR", new => LSR, .ABX, 7),	.("???", new => XXX, .IMP, 7),
				.("RTS", new => RTS, .IMP, 6),	.("ADC", new => ADC, .IZX, 6),	.("???", new => XXX, .IMP, 2),	.("???", new => XXX, .IMP, 8),	.("???", new => NOP, .IMP, 3),	.("ADC", new => ADC, .ZP0, 3),	.("ROR", new => ROR, .ZP0, 5),	.("???", new => XXX, .IMP, 5),	.("PLA", new => PLA, .IMP, 4),	.("ADC", new => ADC, .IMM, 2),	.("ROR", new => ROR, .IMP, 2),	.("???", new => XXX, .IMP, 2),	.("JMP", new => JMP, .IND, 5),	.("ADC", new => ADC, .ABS, 4),	.("ROR", new => ROR, .ABS, 6),	.("???", new => XXX, .IMP, 6),
				.("BVS", new => BVS, .REL, 2),	.("ADC", new => ADC, .IZY, 5),	.("???", new => XXX, .IMP, 2),	.("???", new => XXX, .IMP, 8),	.("???", new => NOP, .IMP, 4),	.("ADC", new => ADC, .ZPX, 4),	.("ROR", new => ROR, .ZPX, 6),	.("???", new => XXX, .IMP, 6),	.("SEI", new => SEI, .IMP, 2),	.("ADC", new => ADC, .ABY, 4),	.("???", new => NOP, .IMP, 2),	.("???", new => XXX, .IMP, 7),	.("???", new => NOP, .IMP, 4),	.("ADC", new => ADC, .ABX, 4),	.("ROR", new => ROR, .ABX, 7),	.("???", new => XXX, .IMP, 7),
				.("???", new => NOP, .IMP, 2),	.("STA", new => STA, .IZX, 6),	.("???", new => NOP, .IMP, 2),	.("???", new => XXX, .IMP, 6),	.("STY", new => STY, .ZP0, 3),	.("STA", new => STA, .ZP0, 3),	.("STX", new => STX, .ZP0, 3),	.("???", new => XXX, .IMP, 3),	.("DEY", new => DEY, .IMP, 2),	.("???", new => NOP, .IMP, 2),	.("TXA", new => TXA, .IMP, 2),	.("???", new => XXX, .IMP, 2),	.("STY", new => STY, .ABS, 4),	.("STA", new => STA, .ABS, 4),	.("STX", new => STX, .ABS, 4),	.("???", new => XXX, .IMP, 4),
				.("BCC", new => BCC, .REL, 2),	.("STA", new => STA, .IZY, 6),	.("???", new => XXX, .IMP, 2),	.("???", new => XXX, .IMP, 6),	.("STY", new => STY, .ZPX, 4),	.("STA", new => STA, .ZPX, 4),	.("STX", new => STX, .ZPY, 4),	.("???", new => XXX, .IMP, 4),	.("TYA", new => TYA, .IMP, 2),	.("STA", new => STA, .ABY, 5),	.("TXS", new => TXS, .IMP, 2),	.("???", new => XXX, .IMP, 5),	.("???", new => NOP, .IMP, 5),	.("STA", new => STA, .ABX, 5),	.("???", new => XXX, .IMP, 5),	.("???", new => XXX, .IMP, 5),
				.("LDY", new => LDY, .IMM, 2),	.("LDA", new => LDA, .IZX, 6),	.("LDX", new => LDX, .IMM, 2),	.("???", new => XXX, .IMP, 6),	.("LDY", new => LDY, .ZP0, 3),	.("LDA", new => LDA, .ZP0, 3),	.("LDX", new => LDX, .ZP0, 3),	.("???", new => XXX, .IMP, 3),	.("TAY", new => TAY, .IMP, 2),	.("LDA", new => LDA, .IMM, 2),	.("TAX", new => TAX, .IMP, 2),	.("???", new => XXX, .IMP, 2),	.("LDY", new => LDY, .ABS, 4),	.("LDA", new => LDA, .ABS, 4),	.("LDX", new => LDX, .ABS, 4),	.("???", new => XXX, .IMP, 4),
				.("BCS", new => BCS, .REL, 2),	.("LDA", new => LDA, .IZY, 5),	.("???", new => XXX, .IMP, 2),	.("???", new => XXX, .IMP, 5),	.("LDY", new => LDY, .ZPX, 4),	.("LDA", new => LDA, .ZPX, 4),	.("LDX", new => LDX, .ZPY, 4),	.("???", new => XXX, .IMP, 4),	.("CLV", new => CLV, .IMP, 2),	.("LDA", new => LDA, .ABY, 4),	.("TSX", new => TSX, .IMP, 2),	.("???", new => XXX, .IMP, 4),	.("LDY", new => LDY, .ABX, 4),	.("LDA", new => LDA, .ABX, 4),	.("LDX", new => LDX, .ABY, 4),	.("???", new => XXX, .IMP, 4),
				.("CPY", new => CPY, .IMM, 2),	.("CMP", new => CMP, .IZX, 6),	.("???", new => NOP, .IMP, 2),	.("???", new => XXX, .IMP, 8),	.("CPY", new => CPY, .ZP0, 3),	.("CMP", new => CMP, .ZP0, 3),	.("DEC", new => DEC, .ZP0, 5),	.("???", new => XXX, .IMP, 5),	.("INY", new => INY, .IMP, 2),	.("CMP", new => CMP, .IMM, 2),	.("DEX", new => DEX, .IMP, 2),	.("???", new => XXX, .IMP, 2),	.("CPY", new => CPY, .ABS, 4),	.("CMP", new => CMP, .ABS, 4),	.("DEC", new => DEC, .ABS, 6),	.("???", new => XXX, .IMP, 6),
				.("BNE", new => BNE, .REL, 2),	.("CMP", new => CMP, .IZY, 5),	.("???", new => XXX, .IMP, 2),	.("???", new => XXX, .IMP, 8),	.("???", new => NOP, .IMP, 4),	.("CMP", new => CMP, .ZPX, 4),	.("DEC", new => DEC, .ZPX, 6),	.("???", new => XXX, .IMP, 6),	.("CLD", new => CLD, .IMP, 2),	.("CMP", new => CMP, .ABY, 4),	.("NOP", new => NOP, .IMP, 2),	.("???", new => XXX, .IMP, 7),	.("???", new => NOP, .IMP, 4),	.("CMP", new => CMP, .ABX, 4),	.("DEC", new => DEC, .ABX, 7),	.("???", new => XXX, .IMP, 7),
				.("CPX", new => CPX, .IMM, 2),	.("SBC", new => SBC, .IZX, 6),	.("???", new => NOP, .IMP, 2),	.("???", new => XXX, .IMP, 8),	.("CPX", new => CPX, .ZP0, 3),	.("SBC", new => SBC, .ZP0, 3),	.("INC", new => INC, .ZP0, 5),	.("???", new => XXX, .IMP, 5),	.("INX", new => INX, .IMP, 2),	.("SBC", new => SBC, .IMM, 2),	.("NOP", new => NOP, .IMP, 2),	.("???", new => SBC, .IMP, 2),	.("CPX", new => CPX, .ABS, 4),	.("SBC", new => SBC, .ABS, 4),	.("INC", new => INC, .ABS, 6),	.("???", new => XXX, .IMP, 6),
				.("BEQ", new => BEQ, .REL, 2),	.("SBC", new => SBC, .IZY, 5),	.("???", new => XXX, .IMP, 2),	.("???", new => XXX, .IMP, 8),	.("???", new => NOP, .IMP, 4),	.("SBC", new => SBC, .ZPX, 4),	.("INC", new => INC, .ZPX, 6),	.("???", new => XXX, .IMP, 6),	.("SED", new => SED, .IMP, 2),	.("SBC", new => SBC, .ABY, 4),	.("NOP", new => NOP, .IMP, 2),	.("???", new => XXX, .IMP, 7),	.("???", new => NOP, .IMP, 4),	.("SBC", new => SBC, .ABX, 4),	.("INC", new => INC, .ABX, 7),	.("???", new => XXX, .IMP, 7),
			);

			m_addrLookup = new
			.(
				new => IMP, new => IMM, new => ZP0, new => ZPX, new => ZPY, new => REL,
				new => ABS, new => ABX, new => ABY, new => IND, new => IZX, new => IZY
			);
		}
	}
}
