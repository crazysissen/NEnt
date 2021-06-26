namespace NEnt
{
	abstract class EmuMan
	{

		public this()
		{

		}

		public ~this()
		{

		}

		public void BaseInit(PixelKun pk)
		{
			SetupMenus(pk.GetMenu());
		}

		public abstract void EmuInit();

		public abstract void Run(PixelKun pk, Rom rom);

		// --

		protected virtual void SetupMenus(MenuMain menu)
		{

		}
	}
}
