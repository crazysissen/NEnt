using System;
using System.Diagnostics;
using SDL2;

namespace NEnt
{
	class Program
	{
		public static void Main(String[] args)
		{
			NEntCore core = scope NEntCore();

			core.Init(args);
			core.Run();
			core.DeInit();
		} 
	}
}
