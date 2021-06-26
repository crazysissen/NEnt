using SDL2;
using System;

namespace NEnt
{
	[CRepr]
	struct SDLVersion
	{
		public uint8 major;
		public uint8 minor;
		public uint8 patch;
	}

	public struct WinMSG : uint32
	{
		public const WinMSG Create = (.)0x0001;
		public const WinMSG Destroy = (.)0x0002;
		public const WinMSG Move = (.)0x0003;
		public const WinMSG Size = (.)0x0005;
		public const WinMSG SetFocus = (.)0x0007;
		public const WinMSG KillFocus = (.)0x0008; 
		public const WinMSG Close = (.)0x0010;
		public const WinMSG Quit = (.)0x0012;
		public const WinMSG SetCursor = (.)0x0020;

		public const WinMSG Input = (.)0x00ff;
		public const WinMSG KeyDown = (.)0x0100;
		public const WinMSG KeyUp = (.)0x0101;
		public const WinMSG Char = (.)0x0102;
		public const WinMSG SysKeyDown = (.)0x0104;
		public const WinMSG SysKeyUp = (.)0x0105;
		public const WinMSG SysKeyChar = (.)0x0106;

		public const WinMSG InitDialog = (.)0x0110;
		public const WinMSG Command = (.)0x0111;
		public const WinMSG SysCommand = (.)0x0112;
		public const WinMSG Timer = (.)0x0113;

		public const WinMSG InitMenu = (.)0x0116;
		public const WinMSG InitMenuPopup = (.)0x0117;
		public const WinMSG MenuSelect = (.)0x011f;
		public const WinMSG MenuChar = (.)0x0120;

	}
	
	[CRepr]
	struct SDLMessage
	{
		[CRepr]
		public struct MSG
		{
			

			public Windows.HWnd hWnd;
			public WinMSG msg;
			public NEntWin.WParam wParam;
			public NEntWin.LParam lParam;
			int32 dummy;
		}

		public SDLVersion version;
		public int32 subsystem;
		public MSG msg;
	}
}
