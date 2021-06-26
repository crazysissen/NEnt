using System;

namespace NEnt
{
	// This class fundamentally represents the NES 6502:s CPU bus

	class EmuNES : EmuMan
	{
		private const uint32 c_ramSize = 64 * 1024; // Amount of uint8:s in RAM

		private Cpu6502 m_cpu;
		private uint8[] m_ram;



		public this()
		{
			m_ram = scope uint8[c_ramSize];

			for (uint8 i in m_ram)
			{
				i = 1;
			}


			m_cpu = scope:: Cpu6502();
			m_cpu.Connect(this);
		}

		public ~this()
		{

		}

		public override void EmuInit()
		{

		}

		public override void Run(PixelKun pk, Rom rom)
		{

		}

		protected override void SetupMenus(MenuMain menu)
		{
			Menu mFile = menu.GetMenuItem<Menu>("File");
			mFile.AddCheckbox("Exit", true, new => ExitPress, null, true);
			mFile.AddSpace();
			mFile.AddCheckbox("Exit Again", true, new => ExitPress, null, false);

			Menu mSub = mFile.AddSubMenu("Indexers...");
			for(int i = 1; i < 6; ++i)
			{
				String s = scope String();
				s.AppendF("{} is the index", i);

				mSub.AddButtonIndexer(s, i, new => IndexButton);
			}

		}

		private void ExitPress(bool newState)
		{
			System.Console.WriteLine("ExitPress: {}", newState);
		}

		private void IndexButton(int index)
		{

		}



		public void Write(uint16 address, uint8 data)
		{
			// TODO

			if (address >= 0x0000 && address <= 0xFFFF)
			{
				m_ram[address] = data;
			}
		}

		public uint8 Read(uint16 address, bool readOnly = false)
		{
			if (address >= 0x0000 && address <= 0xFFFF)
			{
				return m_ram[address];
			}

			return 0x0000;
		}
	}
}
